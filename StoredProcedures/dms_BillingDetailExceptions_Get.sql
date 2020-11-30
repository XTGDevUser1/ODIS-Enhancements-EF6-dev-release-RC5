/*******************
* Operator Enums 
*  Conditions Enum :
* -1 - No filter
*  0 - Null
*  1 - Not Null
*  2 - Equals
*  3 - NotEquals
*  ---- for strings ---
*  4 - StartsWith
*  5 - EndsWith
*  6 - Contains
*  ---- for int, decimal, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingDetailExceptions_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingDetailExceptions_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
CREATE PROCEDURE [dbo].[dms_BillingDetailExceptions_Get]  
@pUserName as nvarchar(50) = null,  
@pScheduleTypeID as int = null,  
@pScheduleDateTypeID as int,   
@pScheduleRangeTypeID as int,  
@pInvoicesXML as XML -- Eg: <Records><BillingDefinitionInvoiceID>1</BillingDefinitionInvoiceID><BillingDefinitionInvoiceID>2</BillingDefinitionInvoiceID></Records>

AS  
/********************************************************************  
 **  
 ** dms_BillingDetailExceptions_Get  
 **  
 ** Date  Added By Description  
 ** ---------- ---------- ----------------------------------------  
 ** 10/10/13 MJKrzysiak Created  
 **   
 ** 04/27/14 MJKrzysiak ^1 Changed validation to use VendorInvoice
 **						PaymentAmount instead of Amount on ESP over $200
 **  
 **********************************************************************/  
  
/**  
  
declare @Invoices as BillingDefinitionInvoiceTableType  
insert into @Invoices (BillingDefinitionInvoiceID)  
select distinct BillingDefinitionInvoiceID from dbo.BillingInvoiceDetail  
  
exec dbo.dms_BillingDetailExceptions_Get 'mjk_testing', 1, 1, 1, @Invoices  
  
/***  
--- Clear Exceptions  
if (select @@ServerName) = 'TRAVERSE\TEST'   
begin    
  truncate table BillingInvoiceDetailException   
  
 update BillingInvoiceDetail  
 set  InvoiceDetailDispositionID = (select ID from BillingInvoiceDetailDisposition where Name = 'REFRESH'),  
   InvoiceDetailStatusID = (select ID from BillingInvoiceDetailStatus where Name = 'READY')  
 where InvoiceDetailStatusID = (select ID from BillingInvoiceDetailStatus where Name = 'EXCEPTION')  
end  
***/  
  
**/  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  
DECLARE @pInvoices as BillingDefinitionInvoiceTableType

INSERT INTO @pInvoices
SELECT  
		T.c.value('.','int')
FROM	@pInvoicesXML.nodes('/Records/BillingDefinitionInvoiceID') T(c)

-- Declare local variables  
declare @Debug as int,  
  @ProgramName as nvarchar(50),  
  @Now as datetime,  
  @ScheduleDateOPEN as date,  
  @ScheduleRangeEndOPEN as date,  
    
  @InvoiceCount as int,  
    
  @UserName as nvarchar(50),  
  
  @BillingCode_EntityID_SR as int,  
  @BillingCode_EntityID_PO as int,  
  @BillingCode_EntityID_VI as int,  
  @BillingCode_EntityID_CL as int,  
  
  @BillingCode_DetailStatus_PENDING as int,  
  @BillingCode_DetailStatus_READY as int,  
  @BillingCode_DetailStatus_ONHOLD as int,  
  @BillingCode_DetailStatus_EXCEPTION as int,  
  @BillingCode_DetailStatus_DELETED as int,  
    
  @BillingCode_DetailDisposition_LOCKED as int,  
  
  @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO as int,  
  @BillingCode_DetailExceptionType_NO_MBRSHP_NUM as int,  
  @BillingCode_DetailExceptionType_NO_VIN as int,  
  @BillingCode_DetailExceptionType_NO_MILEAGE as int,  
  @BillingCode_DetailExceptionType_GOA_REDISPATCH as int,  
  @BillingCode_DetailExceptionType_GOA_ISP_CANC as int,  
  @BillingCode_DetailExceptionType_MILEAGE_OVER_60K as int,  
  @BillingCode_DetailExceptionType_AMT_OVER_$200 as int,  
  @BillingCode_DetailExceptionType_AMT_OVER_$100 as int,  
  @BillingCode_DetailExceptionType_AMT_OVER_$125 as int,  
  @BillingCode_DetailExceptionType_GOA as int,  
  @BillingCode_DetailExceptionType_PO_OVER_90_DAYS as int,  
  
  @BillingCode_DetailExceptionSeverity_WARNING as int,  
  @BillingCode_DetailExceptionSeverity_ERROR as int,  
    
  @BillingCode_DetailExceptionStatus_EXCEPTION as int,  
  @BillingCode_DetailExceptionStatus_RESOLVED as int  
    
  
-- Initialize Local Variables  
select @Debug = 0  
select @Now = getdate()  
select @ProgramName = object_name(@@procid)  
  
-- Capture Billing Codes to use  
set @BillingCode_EntityID_SR = (select ID from Entity where Name = 'ServiceRequest')  
set @BillingCode_EntityID_PO = (select ID from Entity where Name = 'PurchaseOrder')  
set @BillingCode_EntityID_VI = (select ID from Entity where Name = 'VendorInvoice')  
set @BillingCode_EntityID_CL = (select ID from Entity where Name = 'Claim')  
  
set @BillingCode_DetailStatus_READY = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'READY')  
set @BillingCode_DetailStatus_PENDING = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'PENDING')  
set @BillingCode_DetailStatus_ONHOLD = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'ONHOLD')  
set @BillingCode_DetailStatus_EXCEPTION = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'EXCEPTION')  
set @BillingCode_DetailStatus_DELETED = (select ID from dbo.BillingInvoiceDetailStatus where Name = 'DELETED')  
  
set @BillingCode_DetailDisposition_LOCKED = (select ID from dbo.BillingInvoiceDetailDisposition where Name = 'LOCKED')  
  
set @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'ZERO_DOLLAR_PO')  
set @BillingCode_DetailExceptionType_NO_MBRSHP_NUM = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'NO_MBRSHP_NUM')  
set @BillingCode_DetailExceptionType_NO_VIN = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'NO_VIN')  
set @BillingCode_DetailExceptionType_NO_MILEAGE = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'NO_MILEAGE')  
set @BillingCode_DetailExceptionType_GOA_REDISPATCH = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'GOA_REDISPATCH')  
set @BillingCode_DetailExceptionType_GOA_ISP_CANC = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'GOA_ISP_CANC')  
set @BillingCode_DetailExceptionType_MILEAGE_OVER_60K = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'MILEAGE_OVER_60K')  
set @BillingCode_DetailExceptionType_AMT_OVER_$200 = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'AMT_OVER_$200')  
set @BillingCode_DetailExceptionType_GOA = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'GOA')  
set @BillingCode_DetailExceptionType_PO_OVER_90_DAYS = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'PO_OVER_90_DAYS')  
set @BillingCode_DetailExceptionType_AMT_OVER_$100 = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'AMT_OVER_$100')  
set @BillingCode_DetailExceptionType_AMT_OVER_$125 = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'AMT_OVER_$125')  
  
set @BillingCode_DetailExceptionSeverity_WARNING = (select ID from dbo.BillingInvoiceDetailExceptionSeverity where Name = 'WARNING')  
set @BillingCode_DetailExceptionSeverity_ERROR = (select ID from dbo.BillingInvoiceDetailExceptionSeverity where Name = 'ERROR')  
  
set @BillingCode_DetailExceptionStatus_EXCEPTION = (select ID from dbo.BillingInvoiceDetailExceptionStatus where Name = 'EXCEPTION')  
set @BillingCode_DetailExceptionStatus_RESOLVED = (select ID from dbo.BillingInvoiceDetailExceptionStatus where Name = 'RESOLVED')  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Capture the user name.  If null, then get from the  
-- ProgramName  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if @pUserName is null  
begin  
  select @UserName = @ProgramName  
end  
else  
begin  
  select @UserName = @pUserName  
end  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Capture the Open Schedule for the Schedule Type Passed in  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if object_id('tempdb..#tmpOpenSchedule', 'U') is not null drop table #tmpOpenSchedule  
create table #tmpOpenSchedule  
(BillingScheduleID  int,  
 ScheduleTypeID   int,  
 ScheduleDateTypeID  int,  
 ScheduleRangeTypeID int)  
  
create index inx_tmpOpenSchedule1 on #tmpOpenSchedule (BillingScheduleID)  
create index inx_tmpOpenSchedule2 on #tmpOpenSchedule (ScheduleTypeID, ScheduleDateTypeID, ScheduleRangeTypeID)  
  
insert into #tmpOpenSchedule  
(BillingScheduleID,  
 ScheduleTypeID,  
 ScheduleDateTypeID,  
 ScheduleRangeTypeID)  
select top 1   
  bs.ID,  
  bs.ScheduleTypeID,  
  bs.ScheduleDateTypeID,  
  bs.ScheduleRangeTypeID 
 from dbo.BillingSchedule bs   
 join dbo.BillingScheduleType bst on bst.ID = bs.ScheduleTypeID  
 join dbo.BillingScheduleStatus bss on bss.ID = bs.ScheduleStatusID  
 where bss.Name IN ('OPEN','PENDING')  
 and bs.ScheduleTypeID = @pScheduleTypeID  
 and bs.ScheduleDateTypeID = @pScheduleDateTypeID  
 and bs.ScheduleRangeTypeID = @pScheduleRangeTypeID  
 order by  
  bs.ScheduleDate desc  
  
  
if @Debug = 1  
begin  
 select '#tmpOpenSchedule', * from #tmpOpenSchedule  
end  
  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Capture Invoice Definition IDs from Invoices Table   
-- parameter...if null passed in to the Invoices parameter, then  
-- get all that are associated to "OPEN" schedule, of the given  
-- Schedule Type  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if object_id('tempdb..#tmpInvoices', 'U') is not null drop table #tmpInvoices  
create table #tmpInvoices  
(RowID       int     identity,  
 BillingDefinitionInvoiceID  int)  
   
create index inx_tmpInvoices1 on #tmpInvoices(RowID)  
create index inx_tmpInvoices2 on #tmpInvoices (BillingDefinitionInvoiceID)  
  
select @InvoiceCount = isnull(count(*), 0) from @pInvoices  
if @InvoiceCount = 0 -- Get them all in open schedule  
begin  
  
 insert into #tmpInvoices  
 (BillingDefinitionInvoiceID)  
 select bdi.ID -- BillingDefinitionInvoiceID  
 from dbo.BillingDefinitionInvoice bdi with (nolock)  
 join #tmpOpenSchedule O on O.ScheduleTypeID = bdi.ScheduleTypeID -- Open Schedule  
    and O.ScheduleDateTypeID = bdi.ScheduleDateTypeID  
    and O.ScheduleRangeTypeID = bdi.ScheduleRangeTypeID  
 where 1=1  
 and  bdi.IsActive = 1 -- Invoice Def Must be Active  
  
end  
else  
begin  
 insert into #tmpInvoices  
 (BillingDefinitionInvoiceID)  
 select bdi.ID -- BillingDefinitionInvoiceID  
 from @pInvoices i  
 join dbo.BillingDefinitionInvoice bdi with (nolock) on bdi.ID = i.BillingDefinitionInvoiceID  
end  
  
if @Debug = 1  
begin  
 select '#tmpInvoices', * from #tmpInvoices  
end  
  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Find Existing Exceptions that no longer meet Exception business rules  
-- Update these to READY  
-- Get into a temp so we can look in debug  
-- Process the Update  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
create table #tmpExistingExceptionsNoLonger  
(BillingInvoiceDetailID  int,  
 BillingInvoiceDetailExceptionID int)  
  
create index inx_tmpExistingExceptions1 on #tmpExistingExceptionsNoLonger (BillingInvoiceDetailID)  
  
insert into #tmpExistingExceptionsNoLonger  
(BillingInvoiceDetailID,  
 BillingInvoiceDetailExceptionID)  
select bid.ID,  
  bidx.ID  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
Join BillingDefinitionInvoiceLine bdil with (nolock) on bil.BillingDefinitionInvoiceLineID = bdil.ID
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
join BillingInvoiceDetailException bidx with (nolock) on bidx.BillingInvoiceDetailID = bid.ID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List      
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID = @BillingCode_DetailStatus_EXCEPTION -- Detail Status is Exception  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  bidx.InvoiceDetailExceptionStatusID = @BillingCode_DetailExceptionStatus_EXCEPTION -- Is Exception  
--- Exception Criteria  
---------------------------------------------------------------------------  
and  (  
  ---------------- Zero Dollar PO : ALL ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO -- Zero Dollar PO Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and pov.PurchaseOrderAmount <> 0.00) -- No longer Zero Dollar : PO Entity  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO -- Zero Dollar PO Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and viv.PurchaseOrderAmount <> 0.00) -- No longer Zero Dollar : VI Entity  
   or  
  ---------------- No MembershipNumber : ALL but Atwood, PDG, PCG/TravelGuard, Coach-Net, Sea Tow, Select Hagerty Programs ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford','Newell','Novum','RentalCover.com','EFG Companies'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and srv.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford','Newell','Novum','RentalCover.com','EFG Companies'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and pov.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford','Newell','Novum','RentalCover.com','EFG Companies'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and viv.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford','Newell','Novum','RentalCover.com','EFG Companies'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and clv.MembershipNumber is not null) -- Now has MembershipNumber  
   or  
  ---------------- No VIN : FORD ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN -- No VIN Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and srv.MemberID IS NOT NULL   ---- Exclude Non-Member calls
   --and bdil.[Description] <> 'Call Transfer - To Agero'
   and srv.VIN is not null) -- Now has VIN  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN --  No VIN Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pov.VIN is not null) -- Now has VIN  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN --  No VIN Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and viv.VIN is not null) -- Now has VIN  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN --  No VIN Exception : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and clv.VIN is not null) -- Now has VIN  
   or  
  ---------------- No Mileage : FORD ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE -- No Mileage Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and srv.MemberID IS NOT NULL   ---- Exclude Non-Member calls
   --and bdil.[Description] <> 'Call Transfer - To Agero'
   and isnull(srv.VehicleCurrentMileage, 0) > 0) -- Now has Mileage  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE --  No Mileage Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and isnull(pov.VehicleCurrentMileage, 0) > 0) -- Now has Mileage  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE --  No Mileage Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and isnull(viv.VehicleCurrentMileage, 0) > 0) -- Now has Mileage  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE --  No Mileage Exception : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and isnull(clv.VehicleCurrentMileage, 0) > 0) -- Now has Mileage  
  or  
  ---------------- Mileage Over 60K : FORD exclude ESP & Direct Tow ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_MILEAGE_OVER_60K -- Over 60K Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')
   and pr.ID not in (select ID from Program with (nolock) where Code in ('FORDESP_MFG', 'FORDTOW'))  
   and isnull(srv.VehicleCurrentMileage, 0) <= 60000) -- Now under 60K  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_MILEAGE_OVER_60K --  Over 60K Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')
   and pr.ID not in (select ID from Program with (nolock) where Code in ('FORDESP_MFG', 'FORDTOW')) 
   and isnull(pov.VehicleCurrentMileage, 0) <= 60000) -- Now under 60K  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_MILEAGE_OVER_60K --  Over 60K Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')
   and pr.ID not in (select ID from Program with (nolock) where Code in ('FORDESP_MFG', 'FORDTOW'))  
   and isnull(viv.VehicleCurrentMileage, 0) <= 60000) -- Now under 60K  
  or  
  ---------------- Amount over $200 : FORDESP ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $200 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
   and isnull(pov.PurchaseOrderAmount, 0) <= 200) -- Now $200 or less
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $200 Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
--   and isnull(viv.PurchaseOrderAmount, 0) <= 200) -- Now $200 or less
   and isnull(viv.PaymentAmount, 0) <= 200) -- Now $200 or less  ^1 Changed to PaymentAmount
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $200 Excpetion : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
   and isnull(clv.PaymentAmount, 0) <= 200) -- Now $200 or less  
  or  
  ---------------- Amount over $100 : NMC ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100 --  Amount Over $100 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'NMC')  
   and pr.ID in (select ID from Program with (nolock) where Name IN ('NMCA','Security Shield','Security Roadside','Small Group'))     
   and isnull(pov.PurchaseOrderAmount, 0) <= 100) -- Now $100 or less
   or
  ---------------- Amount over $125 : NMC ASSOC (SafeDriver) ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$125 --  Amount Over $125 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   --and cl.ID in (select ID from Client with (nolock) where Name = 'NMC')  
   and pr.ID in (select ID from Program with (nolock) where Name IN ('Association'))     
   and isnull(pov.PurchaseOrderAmount, 0) <= 125) -- Now $125 or less
   or
  ---------------- Amount over $100 : EFG ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100 --  Amount Over $100 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'EFG Companies')  
   and isnull(pov.PurchaseOrderAmount, 0) <= 100) -- Now $100 or less
   or
  ---------------- GOA - : ALL ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_GOA_REDISPATCH -- GOA : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and pov.GOAReason is null) -- No longer GOA  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_GOA_REDISPATCH -- GOA : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and viv.ServiceCode is null) -- No longer GOA  
  ) 
  
  
if @Debug = 1  
begin  
 select '#tmpExistingExceptionsNoLonger', * from #tmpExistingExceptionsNoLonger  
end  
else  
begin  
  
 -- Update the Exception Status to READY  
 update BillingInvoiceDetailException  
 set  InvoiceDetailExceptionStatusID = @BillingCode_DetailExceptionStatus_RESOLVED,  
   ExceptionAuthorizationDate = @Now,  
   ModifyDate = @Now,  
   ModifyBy = @ProgramName  
 from BillingInvoiceDetailException bidx  
 join #tmpExistingExceptionsNoLonger tmp on tmp.BillingInvoiceDetailExceptionID = bidx.ID  
  
 -- Update the Detail Status to PENDING  
 update BillingInvoiceDetail  
 set  InvoiceDetailStatusID = @BillingCode_DetailStatus_PENDING,  
   ModifyDate = @Now,  
   ModifyBy = @ProgramName  
 from BillingInvoiceDetail bid  
 join #tmpExistingExceptionsNoLonger tmp on tmp.BillingInvoiceDetailID = bid.ID  
 where not exists  
 -- Do not update the detail on those that have another PENDING exception other than the type at hand  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID <> @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO  
   and InvoiceDetailExceptionStatusID = @BillingCode_DetailExceptionStatus_EXCEPTION)  
  
end  
  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Create Exceptions  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
create table #tmpExceptions  
(BillingInvoiceDetailID int,  
 InvoiceDetailExceptionTypeID int,  
 InvoiceDetailExceptionStatusID int,  
 InvoiceDetailExceptionSeverityID int,  
 InvoiceDetailExceptionComment nvarchar(max),  
 ExceptionAuthorization nvarchar(100),  
 ExceptionAuthorizationDate datetime,  
 Sequence int,  
 IsActive bit,  
 CreateDate datetime,  
 CreateBy nvarchar(50),  
 ModifyDate datetime,  
 ModifyBy nvarchar(50)  
 )  
  
create index inx_tmpExceptions1 on #tmpExceptions (BillingInvoiceDetailID)  
  
------------------------------------  
-- Zero Dollar PO : ALL  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI) -- PO, VI Entities Only  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO  
    and pov.PurchaseOrderAmount = 0.00 -- Zero Dollar  
    and pov.IsMemberPay = 0) -- Is not Member Pay  
  or  
   (viv.EntityID = @BillingCode_EntityID_VI -- VI  
    and viv.PurchaseOrderAmount = 0.00 -- Zero Dollar  
    and viv.IsMemberPay = 0) -- Is not Member Pay  
   )    
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_ZERO_DOLLAR_PO)  
  
  
------------------------------------  
-- No Membership Number : ALL but Atwood, PDG,Travel Guard, and others
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_NO_MBRSHP_NUM, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities Only  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked
and		cl.ID in (select ID from Client with (nolock) where Name not in 
	('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow', 'Coach-Net','Ford','Newell','Novum','RentalCover.com','EFG Companies'))
and bid.ProgramID Not IN (Select ID from Program Where Name IN 
	('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
-------- Exception Criteria  
and  (  
   (srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR and srv.MembershipNumber is null)  
   or  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and pov.MembershipNumber is null)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and viv.MembershipNumber is null)  
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and clv.MembershipNumber is null)  
  )  
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM)  
  
  
------------------------------------  
-- No VIN : FORD  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_NO_VIN, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
and  srv.MemberID IS NOT NULL   ---- Exclude Non-Member calls
-------- Exception Criteria  
and  (  
   (srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR and srv.VIN is null)  
   or  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and pov.VIN is null)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and viv.VIN is null)  
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and clv.VIN is null)  
  )  
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN)  
  
  
------------------------------------  
-- No Mileage : FORD  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_NO_MILEAGE, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
and  srv.MemberID IS NOT NULL   ---- Exclude Non-Member calls
-------- Exception Criteria  
and  (  
   (srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR and isnull(srv.VehicleCurrentMileage, 0) <= 0)  
   or  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.VehicleCurrentMileage, 0) <= 0)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.VehicleCurrentMileage, 0) <= 0)  
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and isnull(clv.VehicleCurrentMileage, 0) <= 0)  
  )  
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MILEAGE)  
  
  
------------------------------------  
-- Mileage Over 60K : FORD exclude ESP & Direct Tow
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_MILEAGE_OVER_60K, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders srv with (nolock) on srv.ServiceRequestID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_SR, @BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
and  pr.ID not in (select ID from Program with (nolock) where Code in ('FORDESP_MFG', 'FORDTOW'))
-------- Exception Criteria  
and  (  
   (srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR and isnull(srv.VehicleCurrentMileage, 0) > 60000)  
   or  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.VehicleCurrentMileage, 0) > 60000)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.VehicleCurrentMileage, 0) > 60000)  
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and isnull(clv.VehicleCurrentMileage, 0) > 60000)  
  )  
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_MILEAGE_OVER_60K)  
  
  
------------------------------------  
-- Amount Over $200 : FORD ESP  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_AMT_OVER_$200, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
left outer join vw_BillingClaims clv with (nolock) on clv.ClaimID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'Claim')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and  cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
and  pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.PurchaseOrderAmount, 0) > 200)  
   or  
--   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.PurchaseOrderAmount, 0) > 100)  
   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.PaymentAmount, 0) > 200)  -- ^1 Changed to PaymentAmount
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and isnull(clv.PaymentAmount, 0) > 200)  
  )  
and  not exists     -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200)  
  
  
------------------------------------  
-- Amount Over $100 : NMC  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_AMT_OVER_$100, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and cl.ID in (select ID from Client with (nolock) where Name = 'NMC')  
and pr.ID in (select ID from Program with (nolock) where Name IN ('NMCA','Security Shield','Security Roadside','Small Group'))     
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.PurchaseOrderAmount, 0) > 100)  
  )  
and  not exists     -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100)  
  
  
------------------------------------  
-- Amount Over $100 : EFG  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_AMT_OVER_$100, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
and cl.ID in (select ID from Client with (nolock) where Name = 'EFG Companies')  
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.PurchaseOrderAmount, 0) > 100)  
  )  
and  not exists     -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100)  
  
  
  
------------------------------------  
-- Amount Over $125 : NMC Association (Safedriver)  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_AMT_OVER_$125, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI, @BillingCode_EntityID_CL) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
--and cl.ID in (select ID from Client with (nolock) where Name = 'NMC')  
and pr.ID in (select ID from Program with (nolock) where Name IN ('Association'))     
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.PurchaseOrderAmount, 0) > 125)  
  )  
and  not exists     -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$125)  
  
  
  
------------------------------------  
-- GOA : ALL  
-- Exclude Member Cancel GOAs for Internal Clients - CNET, PMC, NMC, Safe Driver, Atlantic Internet, Ford 
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_GOA, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
left outer join vw_BillingVendorInvoices viv with (nolock) on viv.VendorInvoiceID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'VendorInvoice')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO, @BillingCode_EntityID_VI) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
-------- Exception Criteria  
and  (  
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and pov.GOAReason is not null)  
   or  
   (viv.EntityID = @BillingCode_EntityID_VI and viv.GOAReason is not null)  
  )  

---- Exclude Member Cancel GOAs for Internal Clients - CNET, PMC, NMC, Safe Driver, Ford, Atlantic Internet  
and NOT (pr.ClientID IN (SELECT ID FROM Client WHERE Name in 
			('Coach-Net', 'National Motor Club', 'Pinnacle Motor Club', 'Safe Driver', 'Ford', 'Atlantic Internet')) 
		AND (ISNULL(pov.GOAReason,'') = 'Member Cancel' OR ISNULL(viv.GOAReason,'') = 'Member Cancel')
		)

---- Exclude GOAs for Newell  
and NOT (pr.ClientID IN (SELECT ID FROM Client WHERE Name in 
			('Newell')) 
		)

---- Exclude those that already have an Exception of this type  
and  not exists   
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_GOA)  
  

------------------------------------  
-- ALL: POs older than 90 days  
------------------------------------  
insert into #tmpExceptions  
(BillingInvoiceDetailID,  
 InvoiceDetailExceptionTypeID,  
 InvoiceDetailExceptionStatusID,  
 InvoiceDetailExceptionSeverityID,  
 InvoiceDetailExceptionComment,  
 ExceptionAuthorization,  
 ExceptionAuthorizationDate,  
 Sequence,  
 IsActive,  
 CreateDate,  
 CreateBy,  
 ModifyDate,  
 ModifyBy  
 )  
select bid.ID,-- BillingInvoiceDetailID  
  @BillingCode_DetailExceptionType_PO_OVER_90_DAYS, -- InvoiceDetailExceptionTypeID  
  @BillingCode_DetailExceptionStatus_EXCEPTION, -- InvoiceDetailExceptionStatusID  
  @BillingCode_DetailExceptionSeverity_WARNING, -- InvoiceDetailExceptionSeverityID  
  null, -- InvoiceDetailExceptionComment  
  null, -- ExceptionAuthorization  
  null, -- ExceptionAuthorizationDate  
  null, -- Sequence  
  1, -- IsActive  
  @Now, -- CreateDate  
  @ProgramName, -- CreateBy  
  null, -- ModifyDate  
  null -- ModifyBy  
from BillingInvoiceDetail bid with (nolock)  
join BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
join BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID  
join Client cl with (nolock) on cl.ID = bi.ClientID  
join Program pr with (nolock) on pr.ID = bid.ProgramID  
left outer join vw_BillingServiceRequestsPurchaseOrders pov with (nolock) on pov.PurchaseOrderID = bid.EntityKey  
  and bid.EntityID = (select ID from Entity where Name = 'PurchaseOrder')  
join #tmpInvoices i on i.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID -- In Invoice List     
join #tmpOpenSchedule O on O.BillingScheduleID = bid.BillingScheduleID -- In Open Schedule  
Join BillingSchedule bs on bs.ID = bid.BillingScheduleID
where 1=1  
and  bid.EntityID in (@BillingCode_EntityID_PO) -- Entities  
and  bid.InvoiceDetailStatusID in (@BillingCode_DetailStatus_PENDING, @BillingCode_DetailStatus_READY)  -- Detail Status is READY or PENDING  
and  bid.InvoiceDetailDispositionID <> @BillingCode_DetailDisposition_LOCKED -- Not Locked  
-------- Exception Criteria  
and  bid.EntityDate < DATEADD(dd, -90, bs.ScheduleRangeBegin)

  
  
if @Debug = 1  
begin  
 select '#tmpExceptions', b.Name, *   
 from #tmpExceptions t  
 join BillingInvoiceDetailExceptionType b on b.ID = t.InvoiceDetailExceptionTypeID  
 order by b.Name  
end  
else  
begin  
  
 -- Create the Exception  
 insert into dbo.BillingInvoiceDetailException  
 (BillingInvoiceDetailID,  
  InvoiceDetailExceptionTypeID,  
  InvoiceDetailExceptionStatusID,  
  InvoiceDetailExceptionSeverityID,  
  InvoiceDetailExceptionComment,  
  ExceptionAuthorization,  
  ExceptionAuthorizationDate,  
  Sequence,  
  IsActive,  
  CreateDate,  
  CreateBy,  
  ModifyDate,  
  ModifyBy  
  )  
 select BillingInvoiceDetailID,  
   InvoiceDetailExceptionTypeID,  
   InvoiceDetailExceptionStatusID,  
   InvoiceDetailExceptionSeverityID,  
   InvoiceDetailExceptionComment,  
   ExceptionAuthorization,  
   ExceptionAuthorizationDate,  
   Sequence,  
   IsActive,  
   CreateDate,  
   CreateBy,  
   ModifyDate,  
   ModifyBy  
 from #tmpExceptions  
  
 -- Set the Detail Status to EXCEPTION  
 update BillingInvoiceDetail  
 set  InvoiceDetailStatusID = @BillingCode_DetailStatus_EXCEPTION,  
   ModifyDate = @Now,  
   ModifyBy = @ProgramName  
 from BillingInvoiceDetail bid  
 join #tmpExceptions tmp on tmp.BillingInvoiceDetailID = bid.ID  
  
end  
  



