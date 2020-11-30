IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_TemporaryDataFixes]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_TemporaryDataFixes]
GO

CREATE Procedure [dbo].[dms_TemporaryDataFixes]
AS
BEGIN
/*** Temporarily correct data issues caused by existing bugs ***/


/*** BUG - Bug was introduced with TFS 610; On the Member Registration screen the ProgramDataItem 'Policy Number' is no longer propagating to the Membership.ClientReferenceNumber field  ***/
----Select m.ID, c.ID, pd.*, ms.*
--Update ms set ms.ClientReferenceNumber = pd.Value
--From [case] c
--Join Member m on m.id = c.memberid
--join Membership ms on ms.ID = m.MembershipID
--Join ProgramDataItemValueEntity pd on pd.EntityID = 5 and pd.RecordID = m.ID
--Join ProgramDataItem pdi on pdi.ID = pd.ProgramDataItemID and pdi.ScreenName = 'RegisterMember'
--Where 1=1
--and c.CreateDate > '5/1/2015'
--and ms.MembershipNumber is null and ms.ClientReferenceNumber is null


/*** BUG - The DestinationVendorLocationID is not getting set on the SR when an ODIS service location is used as the towing destination ***/
--Select sr.CreateDate,sr.ID,sr.DestinationVendorLocationID, sr.DestinationAddress, ae.Line1, cll_vl.*,sr.DestinationLatitude, sr.DestinationLongitude, vl.Latitude, vl.Longitude
Update sr Set DestinationVendorLocationID = vl.ID
from ServiceRequest sr
Join [Case] c on c.id = sr.CaseID
Join ContactLogLink cll on cll.EntityID = (Select ID From Entity Where Name = 'ServiceRequest') and cll.RecordID = sr.ID
Join ContactLog cl on cl.ID = cll.ContactLogID
Join ContactLogReason clr on clr.ContactLogID = cl.ID 
Join ContactReason cr on clr.ContactReasonID = cr.ID and cr.ContactCategoryID = (Select ID from ContactCategory Where Name = 'ServiceLocationSelection')
Join ContactType ct on ct.ID = cl.ContactTypeID and ct.Name = 'Vendor'
Join ContactLogAction cla on cla.ContactLogID = cl.ID
Join ContactAction ca on ca.ID = cla.ContactActionID and ca.Name in ('Location Selected','Used Location','Set Appointment')
Join ContactLogLink cll_vl on cll_vl.ContactLogID = cl.ID and cll_vl.EntityID = (Select ID From Entity Where Name = 'VendorLocation') --and cll.RecordID = sr.DestinationVendorLocationID
Join VendorLocation vl on vl.ID = cll_vl.RecordID
Join AddressEntity ae on ae.EntityID = 18 and ae.RecordID = vl.ID and ae.AddressTypeID = (Select ID from AddressType where Name = 'Business')
Where 1=1
and sr.DestinationVendorLocationID is null
and ae.Line1 = SUBSTRING(sr.DestinationAddress,1,LEN(ae.Line1))

/*** Data load error - loading invalid unicode character in Address line2  ***/
--Select ae.Line2, m.*
Update ae Set Line2 = NULL
From Member m
JOin Membership ms on ms.ID = m.MembershipID
Left Join [Case] c on c.MemberID = m.ID
Left Join ServiceRequest sr on sr.CaseID = c.ID
Join AddressEntity ae on ae.EntityID = 5 and ae.RecordID = m.ID
where m.ProgramID = 449
and ae.Line2 LIKE '%[^0-9a-zA-Z'' -]%' COLLATE SQL_Latin1_General_Cp850_BIN



/*** Set SourceSystemID on Case until ODIS updated to do this upon Case creation ***/
--Update c Set SourceSystemID = 11
--from vw_ServiceRequests sr
--join [case] c on c.id = sr.caseid
--join (
--	Select CaseID, Min(ic.ProgramID) ProgramID, MAX(MobileID) MobileID
--	From inboundcall ic 
--	Where MobileID IS NOT NULL
--	Group By CaseID
--	) IC on IC.CaseID = c.ID
--Where c.SourceSystemID is null

--Update [Case] Set SourceSystemID = 3 Where SourceSystemID IS NULL



/*** Vendor Portal error - Prompt to sign for new contract and rates creates contract, but does not create rates from the existing rate schedule  ***/
--DECLARE @vendorContracts TABLE
--(
--	RowNum INT IDENTITY(1,1),
--	ContractID INT NOT NULL
--)

--INSERT INTO @vendorContracts
--SELECT	C.ID
--FROM	[Contract] C WITH (NOLOCK)
--LEFT JOIN [ContractRateSchedule] CRS WITH (NOLOCK) ON C.ID = CRS.ContractID
--WHERE	VendorTermsAgreementID = 2
--AND		CRS.ID IS NULL
--and c.VendorApplicationID is NULL
--and c.SourceSystemID = 6

--DECLARE @idx INT = 1,
--		@max INT = (SELECT MAX(RowNum) FROM @vendorContracts),
--		@currentContractID INT = 0

--WHILE (@idx <= @max)
--BEGIN
	
--	SET @currentContractID = (SELECT ContractID FROM @vendorContracts WHERE RowNum = @idx)
--	EXEC [dbo].[dms_Insert_RateScheduleAndRates_For_Contract]  @currentContractID
--	PRINT 'Processed ContractID ' + CONVERT(NVARCHAR(50),@currentContractID)

--	SET @idx = @idx + 1

--END

/*** Bug is removing or not setting the AccountingInvoiceBatchID from previously billed items ***/
declare  
  @BillingScheduleID as int, 
  @BillingCode_EntityID_SR as int,  
  @BillingCode_EntityID_PO as int,  
  @BillingCode_EntityID_VI as int,  
  @BillingCode_EntityID_CL as int,
  @BillingCode_EntityID_SRT as int

set @BillingCode_EntityID_SR = (select ID from Entity where Name = 'ServiceRequest')  
set @BillingCode_EntityID_PO = (select ID from Entity where Name = 'PurchaseOrder')  
set @BillingCode_EntityID_VI = (select ID from Entity where Name = 'VendorInvoice')  
set @BillingCode_EntityID_CL = (select ID from Entity where Name = 'Claim')  
set @BillingCode_EntityID_SRT = (select ID from Entity where Name = 'ServiceRequestAgentTime')  

--Select *
Update srt Set AccountingInvoiceBatchID = bid.AccountingInvoiceBatchID
From BillingInvoiceDetail bid
Join ServiceRequestAgentTime srt on srt.ID = bid.EntityKey
Where bid.EntityID = @BillingCode_EntityID_SRT
and bid.AccountingInvoiceBatchID is not null
and srt.AccountingInvoiceBatchID is null


--Select *
Update sr Set AccountingInvoiceBatchID = bid.AccountingInvoiceBatchID
From BillingInvoiceDetail bid
Join ServiceRequest sr on sr.ID = bid.EntityKey
Where bid.EntityID = @BillingCode_EntityID_SR
and bid.AccountingInvoiceBatchID is not null
and sr.AccountingInvoiceBatchID is null

--Select *
Update po Set AccountingInvoiceBatchID = bid.AccountingInvoiceBatchID
From BillingInvoiceDetail bid
Join PurchaseOrder po on po.ID = bid.EntityKey
Where bid.EntityID = @BillingCode_EntityID_PO
and bid.AccountingInvoiceBatchID is not null
and po.AccountingInvoiceBatchID is null

--Select po.PurchaseOrderNumber,*
Update vi Set AccountingInvoiceBatchID = bid.AccountingInvoiceBatchID
From BillingInvoiceDetail bid
Join VendorInvoice vi on vi.ID = bid.EntityKey
Join PurchaseOrder po on po.ID = vi.PurchaseOrderID
Where bid.EntityID = @BillingCode_EntityID_VI
and bid.AccountingInvoiceBatchID is not null
and vi.AccountingInvoiceBatchID is null


END
GO

