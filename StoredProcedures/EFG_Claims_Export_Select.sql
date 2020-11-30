IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[EFG_Claims_Export_Select]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[EFG_Claims_Export_Select]
GO

-- [dbo].[EFG_Claims_Export_Select] '7/17/2016'

CREATE PROCEDURE [dbo].[EFG_Claims_Export_Select] 
	@ClaimDate datetime
AS


	--DECLARE @ClaimDate datetime = '1/6/2017'
	--SET @ClaimDate = '9/17/2016'
	
	DECLARE @BeginDate datetime
		,@EndDate datetime
		,@PurchaseOrderEntityID int
		,@DispatchFee nvarchar(50)
	SET @BeginDate = DATEADD(m,DATEDIFF(m,0,@ClaimDate)-1,0) -- PreviousMonthStart
	SET @EndDate = DATEADD(ms,-2,DATEADD(month, DATEDIFF(month, 0, @ClaimDate), 0)) -- PreviousMonthEnd
	SET @PurchaseOrderEntityID = (Select ID From Entity where Name = 'PurchaseOrder')
	SET @DispatchFee = (Select Rate From vw_BillingInvoiceDefinitions bd where bd.Client = 'EFG Companies' and Product = 'Dispatch Fee')
	
	SELECT DISTINCT UPPER(LTRIM(RTRIM(v.ClientVendorKey))) as AccountCode,
		sr.MemberID as MemberID,
		ISNULL(UPPER(LTRIM(RTRIM(po.ProductID))),'') as ServiceCategoryName,
		UPPER(LTRIM(RTRIM(po.ProductName))) as ServiceCode,
		UPPER(LTRIM(RTRIM(sr.ServiceRequestStatusName))) as ServiceStatus,
		sr.VehicleCurrentMileage as Odometer,
		po.PurchaseOrderNumber as ClaimNumber,
		CONVERT(varchar(10), po.IssueDate, 101 )  as ClaimReportedDate,
		m.ClientMemberKey,
		UPPER(LTRIM(RTRIM(sr.ContactFirstName))) as ContactFirstName,
		UPPER(LTRIM(RTRIM(sr.ContactLastName))) as ContactLastName,
		LEFT(sr.ContactPhoneNumber,12) as ContactPhoneNumber,
		UPPER(LTRIM(RTRIM(sr.VehicleVIN))) as VehicleVIN,
		sr.VehicleYear,
		CASE WHEN UPPER(LTRIM(RTRIM(sr.VehicleMake))) = 'OTHER' THEN UPPER(LTRIM(RTRIM(sr.VehicleMakeOther)))
			ELSE UPPER(LTRIM(RTRIM(sr.VehicleMake)))
		END as VehicleMake,
		CASE WHEN UPPER(LTRIM(RTRIM(sr.VehicleModel))) = 'OTHER' THEN UPPER(LTRIM(RTRIM(sr.VehicleModelOther )))
			ELSE UPPER(LTRIM(RTRIM(sr.VehicleModel)))
		END as VehicleModel,

		CASE WHEN bid_passthru.IsBilled = 1 THEN bid_passthru.ItemAmount ELSE 0.00 END AS ClaimAmount,

		CONVERT(VARCHAR(10), po.IssueDate, 101) as ClaimPaidDate,
				
		----CASE WHEN (Select TOP 1 (PO.PayStatusCodeName)
		----From vw_PurchaseOrders PO
		----WHERE 
		----PO.ServiceRequestID = sr.ServiceRequestID 
		----AND	PO.PurchaseOrderStatusName in ('Issued','Issued-Paid')
		----ORDER BY PO.IssueDate) = 'PaidByMember' THEN 'Y' ELSE 'N' END as PaidByMember,

		----add dispatch fee		
		CAST( (CASE WHEN bid.IsBilled = 1 THEN @DispatchFee ELSE '0' END) as decimal(18,2)) as DispatchFee,
		sr.ServiceRequestID

	from [vw_BillingInvoiceDetails] bid
	Join vw_PurchaseOrders po on po.PurchaseOrderID = bid.EntityRecordID AND bid.EntityID = @PurchaseOrderEntityID
	Join vw_ServiceRequests sr on sr.ServiceRequestID = po.ServiceRequestID
	Left Join vw_BillingInvoiceDetails bid_passthru on bid.EntityRecordID = bid_passthru.EntityRecordID and bid_passthru.ClientID = bid.ClientID and bid_passthru.Product = 'Billable Purchase Orders'
	Left Join Member m (nolock) on m.ID = sr.MemberID
	Left Join Vendor v (nolock) on v.ID = m.SellerVendorID
	where bid.client = 'Efg Companies' 
	and bid.Product = 'Dispatch Fee' 
	and bid.InvoiceRangeBegin = @BeginDate
	and (bid.IsBilled = 1 or bid_passthru.IsBilled = 1)
	
	Order By ClaimPaidDate
GO

