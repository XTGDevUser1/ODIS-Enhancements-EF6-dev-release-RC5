USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceDetail]    Script Date: 04/18/2016 11:14:44 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[report].[BillingClientInvoiceDetail]') AND type in (N'P', N'PC'))
DROP PROCEDURE [report].[BillingClientInvoiceDetail]
GO

USE [DMS]
GO

/****** Object:  StoredProcedure [report].[BillingClientInvoiceDetail]    Script Date: 04/18/2016 11:14:44 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [report].[BillingClientInvoiceDetail]
	@ClientID int,
	@InvoiceDate date,
	@InvoiceID int = NULL,
	@InvoiceLineID int = NULL,
	@PassThruOnly bit = NULL
AS
BEGIN

	--Declare @ClientID int, @InvoiceID int, @InvoiceDate date, @InvoiceLineID int, @PassThruOnly bit
	--SET @ClientID = 45
	--SET @InvoiceDate = '4/1/2015'
	--SET @InvoiceID = 4928
	--SET @InvoiceLineID = 15635
	--SET @PassThruOnly = 1

	DECLARE @Invoices table (BillingInvoiceID int)

	INSERT INTO @Invoices (BillingInvoiceID)
	Select bi.ID BillingInvoiceID
	from BillingInvoice bi with (nolock)
	Where bi.ClientID = @ClientID
	and bi.ScheduleRangeBegin = @InvoiceDate
	and (@InvoiceID IS NULL OR bi.ID = @InvoiceID)


	SELECT 
		bi.ClientID
		,client.Name ClientName
		,bi.ID InvoiceID
		,bi.[Description] Invoice
		,bil.ID InvoiceLineID
		,bil.[Description] InvoiceLine
		
		,bid.EntityID
		,bid.EntityKey
		
		,CONVERT(nvarchar(50), 
			CASE WHEN e.Name = 'Claim' THEN cl.ClaimDate
			  WHEN e.Name = 'VendorInvoice' THEN VendorInvoicePO.IssueDate
			  WHEN e.Name = 'PurchaseOrder' THEN po.IssueDate
			  WHEN e.Name = 'ServiceRequest' THEN sr.CreateDate
			  ELSE bid.EntityDate 
			  END, 101) ItemDate
		,CASE WHEN e.Name = 'Claim' THEN 'Claim: ' + clType.[Description]
			  WHEN e.Name = 'VendorInvoice' THEN 'Paid ISP Invoice'
			  WHEN e.Name = 'PurchaseOrder' THEN 'Incurred Purchase Order'
			  WHEN e.Name = 'ServiceRequest' THEN 'Service Request'
			  WHEN e.Name = 'MemberCounts' THEN 'Registration'
			  ELSE e.Name 
			  END ItemType
		,bid.Quantity
		,CASE WHEN bid.IsExcluded = 1 THEN 0.00
			  WHEN bid.IsAdjusted = 1 THEN bid.AdjustmentAmount
			  ELSE bid.EventAmount
			  END InvoicedAmount
		---- Member / Person	  
		,COALESCE(ms.MembershipNumber,ms.ClientReferenceNumber) CustomerNumber
		,dbo.fnc_ProperCase(
			RTRIM(CASE WHEN c.ContactLastName IS NOT NULL THEN ISNULL(c.ContactFirstName + ' ', '') + c.ContactLastName
					   WHEN cl.ContactName IS NOT NULL THEN cl.ContactName
					   WHEN mbr.LastName IS NOT NULL THEN ISNULL(mbr.FirstName + ' ', '') + mbr.LastName
					   ELSE '' End)) CustomerName

		---- Vehicle
		,UPPER(CASE WHEN c.VehicleID IS NOT NULL THEN c.VehicleVIN 
			  WHEN cl.VehicleID IS NOT NULL THEN cl.VehicleVIN
			  ELSE (SELECT TOP 1 veh.VIN FROM Vehicle veh WHERE veh.MembershipID = ms.ID)
			  END) VehicleVIN	

		--,CASE WHEN c.VehicleID IS NOT NULL THEN c.VehicleYear 
		--	  WHEN cl.VehicleYear IS NOT NULL THEN cl.VehicleYear
		--	  ELSE (SELECT TOP 1 veh.[Year] FROM Vehicle veh WHERE veh.MembershipID = ms.ID)
		--	  END VehicleYear	
		--,CASE WHEN c.VehicleID IS NOT NULL THEN c.VehicleMake 
		--	  WHEN cl.VehicleMake IS NOT NULL THEN cl.VehicleMake
		--	  ELSE NULL
		--	  END VehicleMake	
		--,CASE WHEN c.VehicleID IS NOT NULL THEN c.VehicleModel 
		--	  WHEN cl.VehicleModel IS NOT NULL THEN cl.VehicleModel
		--	  ELSE NULL
		--	  END VehicleModel	

		,RTRIM(CASE WHEN c.VehicleID IS NOT NULL THEN c.VehicleYear 
			  WHEN cl.VehicleYear IS NOT NULL THEN cl.VehicleYear
			  ELSE ISNULL((SELECT TOP 1 veh.[Year] FROM Vehicle veh WHERE veh.MembershipID = ms.ID),'')
			  END) +	
		 RTRIM(CASE WHEN c.VehicleID IS NOT NULL THEN ' ' + CASE WHEN c.VehicleMake = 'Other' THEN c.VehicleMakeOther ELSE c.VehicleMake END 
			  WHEN cl.VehicleMake IS NOT NULL THEN ' ' + cl.VehicleMake
			  ELSE ISNULL(' ' + (SELECT TOP 1 veh.Make FROM Vehicle veh WHERE veh.MembershipID = ms.ID),'')
			  END) + 
		 RTRIM(CASE WHEN c.VehicleID IS NOT NULL THEN ' ' + CASE WHEN c.VehicleModel = 'Other' THEN c.VehicleModelOther ELSE c.VehicleModel END 
			  WHEN cl.VehicleModel IS NOT NULL THEN ' ' + cl.VehicleModel
			  ELSE ISNULL(' ' + (SELECT TOP 1 veh.Model FROM Vehicle veh WHERE veh.MembershipID = ms.ID),'')
			  END) VehicleDescription	

		,CASE WHEN clProdCat.Name IS NOT NULL THEN clProdCat.Name
			  WHEN bid.ServiceCode IS NOT NULL THEN bid.ServiceCode + 
				(CASE WHEN COALESCE(sr.ServiceLocationCity, sr.ServiceLocationStateProvince, sr.ServiceLocationPostalCode) IS NOT NULL THEN '; ' ELSE '' END) +
				(CASE WHEN sr.ServiceLocationCity IS NOT NULL THEN sr.ServiceLocationCity ELSE '' END) +
				(CASE WHEN sr.ServiceLocationStateProvince IS NOT NULL THEN ', ' + sr.ServiceLocationStateProvince ELSE '' END) +
				(CASE WHEN sr.ServiceLocationPostalCode IS NOT NULL THEN ', ' + sr.ServiceLocationPostalCode ELSE '' END) 
			  ELSE 'N/A'
			  END ServiceDescription
			  
		---- Billing Item Reference
		,CASE WHEN e.Name = 'PurchaseOrder'  THEN 'PO: '  + po.PurchaseOrderNumber
			  WHEN e.Name = 'VendorInvoice'  THEN 'PO: ' + VendorInvoicePO.PurchaseOrderNumber --+ '   ' + 'Vendor Inv: ' + bid.EntityKey
			  --WHEN e.Name = 'VendorInvoice'  THEN 'PO: ' + VendorInvoicePO.PurchaseOrderNumber + '   ' + 'Vendor Inv: ' + bid.EntityKey
			  WHEN e.Name = 'MemberCounts' THEN 'MBR: ' + (CASE WHEN ms.MembershipNumber IS NULL THEN 'No Number' ELSE ms.MembershipNumber END)
			  WHEN e.Name IN ('ServiceRequest','ServiceRequestAgentTime') THEN 'SR: ' + CONVERT(nvarchar(50),sr.ID)
			  WHEN e.Name IN ('BillingPhoneSwitchCallDetail','BillingPhoneCallMetricsIncomingCalls') THEN 'CALL: ' + CONVERT(nvarchar(50), bid.EntityKey) 
			  WHEN e.Name = 'BillingProgram' THEN ''
		 ELSE e.Name + ': ' + bid.EntityKey
		 END ItemReference
		 ,ISNULL(c.ReferenceNumber,'') ClientReferenceNumber
	FROM @Invoices Invoices
	JOIN BillingInvoice bi with (nolock) on Invoices.BillingInvoiceID = bi.ID
	JOIN Client client with (nolock) on client.ID = bi.ClientID
	JOIN BillingInvoiceLine bil with (nolock) on bi.ID = bil.BillingInvoiceID
	JOIN BillingInvoiceDetail bid with (nolock) on bil.ID = bid.BillingInvoiceLineID
	JOIN BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID
	JOIN Entity e with (nolock) on e.ID = bid.EntityID

	---- Purchase Order Entity
	LEFT OUTER JOIN PurchaseOrder PO on PO.ID = (CASE WHEN e.Name = 'PurchaseOrder' THEN bid.EntityKey ELSE NULL END)
	---- Vendor Invoice Entity
	LEFT OUTER JOIN VendorInvoice vi on vi.ID = (CASE WHEN e.Name = 'VendorInvoice' THEN bid.EntityKey ELSE NULL END)
	LEFT OUTER JOIN PurchaseOrder VendorInvoicePO on VendorInvoicePO.ID = vi.PurchaseOrderID
	---- Claim Entity
	LEFT OUTER JOIN Claim cl on cl.ID = (CASE WHEN e.Name = 'Claim' THEN bid.EntityKey ELSE NULL END)
	LEFT OUTER JOIN ClaimType clType on clType.ID = cl.ClaimTypeID
	LEFT OUTER JOIN ProductCategory clProdCat on clProdCat.ID = cl.ServiceProductCategoryID
	---- Member Entity (count)
	LEFT OUTER JOIN DMS_Reporting.MemberCounts.DMSMemberCounts mbrCount on mbrCount.ID = (CASE WHEN e.Name = 'MemberCounts' THEN bid.EntityKey ELSE NULL END)
	---- Service Request Agent Time
	LEFT OUTER JOIN ServiceRequestAgentTime srt on srt.ID = (CASE WHEN e.Name = 'ServiceRequestAgentTime' THEN bid.EntityKey ELSE NULL END)
	
	---- Case / SR
	LEFT OUTER JOIN ServiceRequest sr on sr.ID = COALESCE(po.ServiceRequestID, VendorInvoicePO.ServiceRequestID, srt.ServiceRequestID,(CASE WHEN e.Name = 'ServiceRequest' THEN bid.EntityKey ELSE NULL END))
	LEFT OUTER JOIN [Case] c on c.ID = sr.CaseID

	---- Membership / Member
	LEFT OUTER JOIN Member mbr on mbr.ID = COALESCE(c.MemberID, cl.MemberID, mbrCount.MemberID)
	LEFT OUTER JOIN Membership ms on ms.ID = mbr.MembershipID

	Where (@InvoiceLineID IS NULL OR @InvoiceLineID = bil.ID)
	AND bid.IsExcluded = 0											---- EXCLUDE excluded items
	AND	bids.Name not in ('DELETED')									---- EXCLUDE detail items with 'Deleted' status
	AND (ISNULL(@PassThruOnly,0) = 0 OR bil.ProductID IN (217,221,225,246))	---- ONLY INCLUDE PASS-THRU ITEMS (if indicated)

	ORDER BY client.Name, bi.[Description], bil.[Description], ItemType, bid.EntityDate

END

GO

