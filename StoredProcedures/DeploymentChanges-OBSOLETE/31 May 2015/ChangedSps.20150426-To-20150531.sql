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
 **						PaymentAmount instead of Amount on ESP over $100
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
set @BillingCode_DetailExceptionType_AMT_OVER_$200 = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'AMT_OVER_$100')  
set @BillingCode_DetailExceptionType_GOA = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'GOA')  
set @BillingCode_DetailExceptionType_PO_OVER_90_DAYS = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'PO_OVER_90_DAYS')  
  
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
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and srv.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and pov.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and viv.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in 
		('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow','Coach-Net','Ford'))
   and bid.ProgramID Not IN (Select ID from Program Where Name IN 
		('Hagerty Special Programs','Hagerty - Member Assist','Hagerty - Secondary Tow','Hagerty - Non Standard'))
   and clv.MembershipNumber is not null) -- Now has MembershipNumber  
   or  
  ---------------- No VIN : FORD ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_VIN -- No VIN Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
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
  ---------------- Amount over $100 : FORDESP ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $100 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
   and isnull(pov.PurchaseOrderAmount, 0) <= 200) -- Now $200 or less
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $100 Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
--   and isnull(viv.PurchaseOrderAmount, 0) <= 200) -- Now $200 or less
   and isnull(viv.PaymentAmount, 0) <= 200) -- Now $200 or less  ^1 Changed to PaymentAmount
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$200 --  Amount Over $100 Excpetion : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
   and isnull(clv.PaymentAmount, 0) <= 200) -- Now $200 or less  
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
	('Atwood', 'Professional Dispatch Group', 'Travel Guard', 'SeaTow', 'Coach-Net','Ford'))
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
-- Amount Over $100 : FORD ESP  
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
  


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_CCImport_CreditCardChargedTransactions]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CCImport_CreditCardChargedTransactions] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 CREATE PROCEDURE [dbo].[dms_CCImport_CreditCardChargedTransactions] ( 
   @processGUID UNIQUEIDENTIFIER = NULL
 ) 
 
AS
BEGIN

	DECLARE @Results AS TABLE(TotalRecordCount INT,
							  TotalRecordsIgnored INT,
							  TotalCreditCardAdded INT,
							  TotalTransactionAdded INT,
							  TotalErrorRecords INT)
							  
	-- Helpers
	DECLARE @TotalRecordCount INT	= 0
	DECLARE @TotalRecordsIgnored INT = 0
	DECLARE @TotalCreditCardAdded INT = 0
	DECLARE @TotalTransactionAdded INT = 0
	DECLARE @TotalErrorRecords INT	= 0	 			  

	-- Step 1 : Insert Records INTO Temporary Credit Card
	DECLARE @startROWParent INT 
	DECLARE @totalRowsParent INT
	
	DECLARE @purchaseOrderNumber NVARCHAR(50) 
	DECLARE @creditCardNumber NVARCHAR(50)
	DECLARE @chargedDate DATE
	DECLARE @chargedAmount MONEY
	DECLARE @transactionDate DATE
	DECLARE @TemporaryCreditCardPostedStatusID int
	
	DECLARE @ParentRecordID INT = NULL
	DECLARE @ChildRecordID INT = NULL
	DECLARE @newRecordID INT
	
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import_ChargedTransactions 
												 WHERE ProcessIdentifier = @processGUID)
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import_ChargedTransactions 
												 WHERE ProcessIdentifier = @processGUID)
	SET @TemporaryCreditCardPostedStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name = 'Posted')
	
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN	
		
		SELECT @creditCardNumber    = FINVirtualCardNumber_C_CreditCardNumber,
			   @purchaseOrderNumber = FINCFFData02_C_OriginalReferencePurchaseOrderNumber,
			   @chargedDate			= FINPostingDate_ChargeDate,
			   @chargedAmount		= FINTransactionAmount_ChargeAmount,
			   @transactionDate		= FINTransactionDate_C_IssueDate_TransactionDate
		FROM TemporaryCreditCard_Import_ChargedTransactions
		WHERE RecordID = @startROWParent
		
		SET @ParentRecordID =   (SELECT tcc.ID
								 FROM TemporaryCreditCard tcc
								 --- Get Last Issue matching the last 6 digits of the CC
								 JOIN (
									SELECT right(CreditCardNumber, 6) Last6OfCC, MAX(IssueDate) MaxIssueDate
									FROM TemporaryCreditCard
									GROUP BY right(CreditCardNumber, 6)
									) LastIssueEntry ON LastIssueEntry.Last6OfCC = right(tcc.CreditCardNumber, 6) 
										AND LastIssueEntry.MaxIssueDate = tcc.IssueDate
								 WHERE right(tcc.CreditCardNumber, 6) = right(@creditCardNumber,6)
								 ---- Removed this condition since the PO number does not always make it into the Charge transaction
								 --AND ltrim(rtrim(isnull(tcc.OriginalReferencePurchaseOrderNumber,''))) = ltrim(rtrim(isnull(@purchaseOrderNumber,'')))
								 AND Cast(Convert(varchar, tcc.IssueDate,101) as datetime) <= @chargedDate
								 ---- The last 6 digits of the CC can be same for different CCs, so don't look back too far for this matching Issue
								 --AND tcc.IssueDate >= DATEADD(dd, -60, GetDate())
								 AND tcc.TemporaryCreditCardStatusID <> @TemporaryCreditCardPostedStatusID  -- Don't post charges after Posted
								 )
			 
	    IF (@ParentRecordID IS NULL)
			  BEGIN
					UPDATE TemporaryCreditCard_Import_ChargedTransactions 
					SET ExceptionMessage = 'No matching TemporaryCreditCard for input charge transaction'
					WHERE RecordID = @startROWParent
			  END
		ELSE
			 BEGIN
					UPDATE TemporaryCreditCard_Import_ChargedTransactions 
					SET TemporaryCreditCardID = @ParentRecordID WHERE RecordID = @startROWParent
					
					SET    @ChildRecordID = (SELECT tccd.ID
						   FROM TemporaryCreditCard tcc
						   JOIN TemporaryCreditCardDetail tccd
						   ON tcc.ID = tccd.TemporaryCreditCardID
						   WHERE right(isnull(tcc.CreditCardNumber,''), 5) = 
						   right(isnull(@creditCardNumber,''), 5)
						   AND tccd.TransactionDate = @transactionDate
						   AND tccd.ChargeDate = @chargedDate
						   AND tccd.TransactionType = 'Charge'
						   AND ltrim(rtrim(isnull(tcc.OriginalReferencePurchaseOrderNumber,''))) 
						   = ltrim(rtrim(isnull(@purchaseOrderNumber,'')))
						   AND tccd.ChargeAmount = @chargedAmount)
					
					IF(@ChildRecordID IS NULL)
					BEGIN
						 INSERT INTO TemporaryCreditCardDetail(TemporaryCreditCardID,
															   TransactionSequence,
															   TransactionDate,
															   TransactionType,
															   TransactionBy,
															   RequestedAmount,
															   ApprovedAmount,
															   AvailableBalance,
															   ChargeDate,
															   ChargeAmount,
															   ChargeDescription,
															   CreateDate,
															   CreateBy,
															   ModifyDate,
															   ModifyBy)
						 SELECT @ParentRecordID,
								TransactionSequence,
								FINTransactionDate_C_IssueDate_TransactionDate,
								TransactionType,
								TransactionBy,
								RequestedAmount,
								ApprovedAmount,
								AvailableBalance,
								FINPostingDate_ChargeDate,
								FINTransactionAmount_ChargeAmount,
								FINTransactionDescription_ChargeDescription,
								CreateDate,
								CreatedBy,
								ModifyDate,
								ModifiedBy
						 FROM TemporaryCreditCard_Import_ChargedTransactions
						 WHERE RecordID = @startROWParent
						 
						 SET @newRecordID = SCOPE_IDENTITY()
						 
						 UPDATE TemporaryCreditCard_Import_ChargedTransactions
						 SET TemporaryCreditCardDetailsID = @newRecordID
						 WHERE RecordID = @startROWParent
					END

			 END
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 3 Update Counts
	SET @TotalRecordCount = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions WHERE 
							 ProcessIdentifier = @processGUID)
	
							  
	SET @TotalTransactionAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions
							     WHERE TemporaryCreditCardDetailsID IS NOT NULL AND ProcessIdentifier = @processGUID)
			
	SET @TotalErrorRecords = (SELECT COUNT(*) FROM TemporaryCreditCard_Import_ChargedTransactions
							     WHERE TemporaryCreditCardID IS NULL AND ProcessIdentifier = @processGUID)				     
							   
	
	-- Step 4 Insert Counts
	INSERT INTO @Results(TotalRecordCount,
						 TotalRecordsIgnored,
						 TotalCreditCardAdded,
						 TotalTransactionAdded,
						 TotalErrorRecords)
	VALUES(@TotalRecordCount,@TotalRecordsIgnored,@TotalCreditCardAdded,@TotalTransactionAdded,
	@TotalErrorRecords)
	
	-- Step 5 Show Results
	SELECT * FROM @Results
END

GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_UpdateTempCreditCardDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
GO

--EXEC dms_CCImport_UpdateTempCreditCardDetails
CREATE PROC [dbo].[dms_CCImport_UpdateTempCreditCardDetails]
AS
BEGIN

BEGIN TRY
 

CREATE TABLE #TempCardsNotPosted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL)

DECLARE @postedStatus INT
DECLARE @startROWParent INT 
DECLARE @totalRowsParent INT,
		@creditcardNumber INT,
		@totalApprovedAmount money,
		@totalChargedAmount money,
		@maxLastChargeDate datetime

SET @postedStatus = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Posted')

INSERT INTO #TempCardsNotPosted
SELECT DISTINCT TCCD.TemporaryCreditCardID FROM
TemporaryCreditCardDetail TCCD
JOIN TemporaryCreditCard TCC ON TCC.ID = TCCD.TemporaryCreditCardID
WHERE TCC.TemporaryCreditCardStatusID NOT IN (SELECT ID FROM TemporaryCreditCardStatus WHERE Name IN ('Cancelled','Posted'))
--AND TCC.IssueDate > DATEADD(mm, -180, GETDATE())

SET @startROWParent =  (SELECT MIN([RowNum]) FROM #TempCardsNotPosted)
SET @totalRowsParent = (SELECT MAX([RowNum]) FROM #TempCardsNotPosted)

WHILE(@startROWParent <= @totalRowsParent)  
BEGIN

SET @creditcardNumber = (SELECT ID FROM #TempCardsNotPosted WHERE [RowNum] = @startROWParent)
SET @maxLastChargeDate = (SELECT MAX(ChargeDate) FROM TemporaryCreditCardDetail WHERE TemporaryCreditCardID =  @creditcardNumber)

UPDATE TemporaryCreditCard
SET LastChargedDate = @maxLastChargeDate
WHERE ID =  @creditcardNumber

IF((SELECT Count(*) FROM TemporaryCreditCardDetail 
   WHERE TransactionType='Cancel' AND TemporaryCreditCardID = @creditcardNumber) > 0)
 BEGIN
	UPDATE TemporaryCreditCard 
	SET IssueStatus = 'Cancel'
	WHERE ID = @creditcardNumber
 END
 
 SET @totalApprovedAmount = (SELECT TOP 1 ApprovedAmount FROM TemporaryCreditCardDetail
							 WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Approve'
							 AND TransactionSequence IS NOT NULL
							 ORDER BY TransactionSequence DESC)
SET @totalChargedAmount = (SELECT SUM(ChargeAmount) FROM TemporaryCreditCardDetail
						   WHERE TemporaryCreditCardID = @creditcardNumber AND TransactionType='Charge')

UPDATE TemporaryCreditCard
SET ApprovedAmount = @totalApprovedAmount,
	TotalChargedAmount = @totalChargedAmount
WHERE ID = @creditcardNumber
						 
SET @startROWParent = @startROWParent + 1

END

DROP TABLE #TempCardsNotPosted



END TRY
BEGIN CATCH
		
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

    -- Use RAISERROR inside the CATCH block to return error
    -- information about the original error that caused
    -- execution to jump to the CATCH block.
    RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
	
END CATCH

END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ClientBillableEventProcessing_Details]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ClientBillableEventProcessing_Details] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
-- EXEC dms_ClientBillableEventProcessing_Details 1
CREATE PROC dms_ClientBillableEventProcessing_Details(@pBillingInvoiceDetail INT = NULL)
AS
BEGIN
SELECT	
		--Billable Event Section
		BID.ID as BillingInvoiceDetailID,
		BIDs.[ID] DetailsStatusID,
		BIDs.[Description] as DetailStatus,
		BIDd.ID as DispositionID,
		BIDd.[Description] as Disposition,
		BID.EntityKey,
		e.Name as EntityType,
		BID.EntityDate,
		BID.ServiceCode,
		BID.Quantity,
		BID.EventAmount,
		pro.Id as ProgramID,
		pro.Description as Program,
		'' MembershipNumber,
		'' MemberName,
		BID.InvoiceDetailStatusAuthorization + ' ' + BID.InvoiceDetailStatusAuthorizationDate as AuthorizedBy,
		
		--Invoice Information Section
		bis.[Description] as InvoiceStatus,
		bis.ID InvoiceStatusID,
		bis.Name InvoiceStatusName,
		bi.InvoiceNumber,
		bi.InvoiceDate,
		cl.Name as ClientName,
		bst.Name as BillingSchedule,
		bdi.Name as InvoiceName,
		bdil.Name as LineName,
		pr.Name as ProductName,
		bdile.Name as EventName,
		bdil.[Description] as EventDescription,
		BID.RateTypeName as Rate,
		pr.AccountingSystemGLCode as GLCode,	
		
		--Adjustment Section
		BID.IsAdjustable as Adjustable,
		BID.AdjustmentAmount,
		
		bar.ID AdjustmentReasonID,
		bar.[Description] as AdjustmentReason,
		BID.AdjustmentReasonOther,
		BID.AdjustmentComment,
		BID.AdjustedBy,
		BID.AdjustmentDate,
		
		-- Other Information
		BID.IsExcludable as Excludable,
		ber.ID as ExcludeReasonID, 
		ber.[Description] as ExcludeReason,
		BID.ExcludeReasonOther,
		BID.ExcludeComment,
		BID.ExcludedBy,
		BID.ExcludeDate,
		
		-- Audit Section
		BID.CreateBy,
		BID.CreateDate,
		BID.ModifyBy,
		BID.ModifyDate,
		
		--Newly Added
		BID.IsAdjusted,
		BID.IsExcluded,
		
		--TOP Headers
		bi.[Description] AS InvoiceDescription,
		bil.[Description] AS LineDescription,
		BID.IsEditable AS IsQuantityAndAmountEditable,

		-- TFS 612
		BID.InternalComment,
		BID.ClientNote

FROM	dbo.BillingInvoiceDetail BID with (nolock)
left join	dbo.BillingDefinitionInvoice bdi with (nolock) on bdi.ID = BID.BillingDefinitionInvoiceID
left join	dbo.BillingDefinitionInvoiceLine bdil with (nolock) on bdil.ID = BID.BillingDefinitionInvoiceLineID
left join	dbo.BillingDefinitionInvoiceLineEvent bdile with (nolock) on bdile.BillingDefinitionInvoiceLineID = bdil.ID
		and bdile.BillingDefinitionInvoiceLineID = BID.BillingDefinitionInvoiceLineID
		and bdile.BillingDefinitionEventID = BID.BillingDefinitionEventID
left join	dbo.BillingDefinitionEvent bde with (nolock) on bde.ID = BID.BillingDefinitionEventID
left join	dbo.BillingSchedule bs with (nolock) on bs.ID = BID.BillingScheduleID
left join	dbo.Product pr with (nolock) on pr.ID = BID.ProductID
left join	dbo.Program pro with (nolock) on pro.ID = BID.ProgramID
left join	dbo.Client cl with (nolock) on cl.ID = bdi.ClientID
left join	dbo.BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left join	dbo.BillingInvoiceDetailStatus BIDs with (nolock) on BIDs.ID = BID.InvoiceDetailStatusID
left join	dbo.BillingInvoiceDetailDisposition BIDd with (nolock) on BIDd.ID = BID.InvoiceDetailDispositionID
left join	dbo.BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join dbo.Entity e with (nolock) on e.ID = BID.EntityID
left outer join	dbo.BillingAdjustmentReason bar on bar.ID = BID.AdjustmentReasonID
left outer join	dbo.BillingExcludeReason ber on ber.ID = BID.ExcludeReasonID
left outer join dbo.BillingInvoiceLine bil with (nolock) on bil.ID = BID.BillingInvoiceLineID
left outer join dbo.BillingInvoice bi with (nolock) on bi.ID = bil.BillingInvoiceID
left outer join dbo.BillingInvoiceStatus bis with(nolock) on bis.ID = bi.InvoiceStatusID

WHERE	BID.ID = @pBillingInvoiceDetail

END

GO
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
 WHERE id = object_id(N'[dbo].[dms_Client_Invoice_Event_Processing_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Invoice_Event_Processing_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Client_Invoice_Event_Processing_List_Get @billingInvoiceLineID =120
 CREATE PROCEDURE [dbo].[dms_Client_Invoice_Event_Processing_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @billingInvoiceLineID INT 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingInvoiceDetailIDOperator="-1" 
BillingTypeOperator="-1" 
InvoiceDefinitionOperator="-1" 
LineSequenceOperator="-1" 
LineNameOperator="-1" 
ServiceCodeOperator="-1" 
BillingDetailNameOperator="-1" 
QuantityOperator="-1" 
DetailStatusOperator="-1" 
DetailDispositionOperator="-1" 
AdjustmentReasonOperator="-1" 
AdjustmentDateOperator="-1" 
AdjustedByOperator="-1" 
SourceRecordNumberOperator="-1" 
BillingInvoiceScheduleTypeIDOperator="-1" 
EventAmountOperator="-1" 
RateTypeNameOperator="-1" 
ExcludedReasonOperator="-1" 
ExcludeDateOperator="-1" 
ExcludedByOperator="-1" 
EntityOperator="-1" 
ClientOperator="-1" 
InternalCommentOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingInvoiceDetailIDOperator INT NOT NULL,
BillingInvoiceDetailIDValue int NULL,
BillingTypeOperator INT NOT NULL,
BillingTypeValue nvarchar(100) NULL,
InvoiceDefinitionOperator INT NOT NULL,
InvoiceDefinitionValue nvarchar(100) NULL,
LineSequenceOperator INT NOT NULL,
LineSequenceValue int NULL,
LineNameOperator INT NOT NULL,
LineNameValue nvarchar(100) NULL,
ServiceCodeOperator INT NOT NULL,
ServiceCodeValue nvarchar(100) NULL,
BillingDetailNameOperator INT NOT NULL,
BillingDetailNameValue nvarchar(100) NULL,
QuantityOperator INT NOT NULL,
QuantityValue int NULL,
DetailStatusOperator INT NOT NULL,
DetailStatusValue nvarchar(100) NULL,
DetailDispositionOperator INT NOT NULL,
DetailDispositionValue nvarchar(100) NULL,
AdjustmentReasonOperator INT NOT NULL,
AdjustmentReasonValue nvarchar(100) NULL,
AdjustmentDateOperator INT NOT NULL,
AdjustmentDateValue datetime NULL,
AdjustedByOperator INT NOT NULL,
AdjustedByValue nvarchar(100) NULL,
SourceRecordNumberOperator INT NOT NULL,
SourceRecordNumberValue nvarchar(100) NULL,
BillingInvoiceScheduleTypeIDOperator INT NOT NULL,
BillingInvoiceScheduleTypeIDValue int NULL,
EventAmountOperator INT NOT NULL,
EventAmountValue money NULL,
RateTypeNameOperator INT NOT NULL,
RateTypeNameValue nvarchar(100) NULL,
ExcludedReasonOperator INT NOT NULL,
ExcludedReasonValue nvarchar(100) NULL,
ExcludeDateOperator INT NOT NULL,
ExcludeDateValue datetime NULL,
ExcludedByOperator INT NOT NULL,
ExcludedByValue nvarchar(100) NULL,
EntityOperator INT NOT NULL,
EntityValue nvarchar(100) NULL,
ClientOperator INT NOT NULL,
ClientValue nvarchar(100) NULL,
InternalCommentOperator INT NOT NULL,
InternalCommentValue nvarchar(max) NULL
)

CREATE TABLE #FinalResults_filtered( 
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100) NULL,
	Entity NVARCHAR(50) NULL,
	IsAdjusted BIT NULL,
	IsExcluded BIT NULL  ,
	InternalComment nvarchar(max)  NULL ,
	ExceptionMessage nvarchar(max)  NULL 
) 
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100)  NULL ,
	Entity nvarchar(100)  NULL ,
	InternalComment nvarchar(max)  NULL ,
	ExceptionMessage nvarchar(max)  NULL 
)  

CREATE TABLE #tmpFinalResults( 
	
	BillingInvoiceDetailID int  NULL ,
	BillingType nvarchar(100)  NULL ,
	InvoiceDefinition nvarchar(100)  NULL ,
	Client nvarchar(100)  NULL ,
	LineSequence int  NULL ,
	LineName nvarchar(100)  NULL ,
	ServiceCode nvarchar(100)  NULL ,
	BillingDetailName nvarchar(100)  NULL ,
	Quantity int  NULL ,
	DetailStatus nvarchar(100)  NULL ,
	DetailDisposition nvarchar(100)  NULL ,
	AdjustmentReason nvarchar(100)  NULL ,
	AdjustmentDate datetime  NULL ,
	AdjustedBy nvarchar(100)  NULL ,
	SourceRecordNumber nvarchar(100)  NULL ,
	BillingInvoiceScheduleTypeID int  NULL ,
	EventAmount money  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	ExcludedReason nvarchar(100)  NULL ,
	ExcludeDate datetime  NULL ,
	ExcludedBy nvarchar(100) NULL,
	Entity NVARCHAR(50) NULL,
	IsAdjusted BIT NULL,
	IsExcluded BIT NULL  ,
	InternalComment nvarchar(max)  NULL ,
	ExceptionMessage nvarchar(max)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingInvoiceDetailIDOperator','INT'),-1),
	T.c.value('@BillingInvoiceDetailIDValue','int') ,
	ISNULL(T.c.value('@BillingTypeOperator','INT'),-1),
	T.c.value('@BillingTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceDefinitionOperator','INT'),-1),
	T.c.value('@InvoiceDefinitionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LineSequenceOperator','INT'),-1),
	T.c.value('@LineSequenceValue','int') ,
	ISNULL(T.c.value('@LineNameOperator','INT'),-1),
	T.c.value('@LineNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceCodeOperator','INT'),-1),
	T.c.value('@ServiceCodeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@BillingDetailNameOperator','INT'),-1),
	T.c.value('@BillingDetailNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@QuantityOperator','INT'),-1),
	T.c.value('@QuantityValue','int') ,
	ISNULL(T.c.value('@DetailStatusOperator','INT'),-1),
	T.c.value('@DetailStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DetailDispositionOperator','INT'),-1),
	T.c.value('@DetailDispositionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AdjustmentReasonOperator','INT'),-1),
	T.c.value('@AdjustmentReasonValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AdjustmentDateOperator','INT'),-1),
	T.c.value('@AdjustmentDateValue','datetime') ,
	ISNULL(T.c.value('@AdjustedByOperator','INT'),-1),
	T.c.value('@AdjustedByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SourceRecordNumberOperator','INT'),-1),
	T.c.value('@SourceRecordNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@BillingInvoiceScheduleTypeIDOperator','INT'),-1),
	T.c.value('@BillingInvoiceScheduleTypeIDValue','int') ,
	ISNULL(T.c.value('@EventAmountOperator','INT'),-1),
	T.c.value('@EventAmountValue','money') ,
	ISNULL(T.c.value('@RateTypeNameOperator','INT'),-1),
	T.c.value('@RateTypeNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ExcludedReasonOperator','INT'),-1),
	T.c.value('@ExcludedReasonValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ExcludeDateOperator','INT'),-1),
	T.c.value('@ExcludeDateValue','datetime') ,
	ISNULL(T.c.value('@ExcludedByOperator','INT'),-1),
	T.c.value('@ExcludedByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@EntityOperator','INT'),-1),
	T.c.value('@EntityValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ClientOperator','INT'),-1),
	T.c.value('@ClientValue','nvarchar(100)')  ,
	ISNULL(T.c.value('@InternalCommentOperator','INT'),-1),
	T.c.value('@InternalCommentValue','nvarchar(max)')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
select	bd.ID as BillingInvoiceDetailID,
		bt.Name as BillingType,
		bdi.[Name] as InvoiceDefinition,
		cl.Name as Client,
		bdil.Sequence as LineSequence,
		bdil.Name as LineName,
		bd.ServiceCode,
		bd.Name as BillingDetailName,
		bd.Quantity,
		bids.Name as DetailStatus,
		bidd.Name as DetailDisposition,
		bar.[Description] as AdjustmentReason,
		bd.AdjustmentDate,
		bd.AdjustedBy,
		bd.EntityKey AS SourceRecordNumber,
		--case 
		--when (select Name from Entity with (nolock) where ID = EntityID) = 'PurchaseOrder' then po.PurchaseOrderNumber
		--else EntityKey
		--end as SourceRecordNumber ,
		bt.ID as BillingInvoiceScheduleTypeID,
		bd.EventAmount,
		bd.RateTypeName,  
		ber.Description as ExcludedReason,
		bd.ExcludeDate,
		bd.ExcludedBy,
		(select Name from Entity with (nolock) where ID = EntityID) as Entity,
		bd.IsAdjusted,
		bd.IsExcluded,
		bd.InternalComment,
		--[dbo].[fnConcatenate](bide.InvoiceDetailExceptionComment) AS ExceptionMessage
		'' AS ExceptionMessage
from BillingInvoiceDetail bd
left outer join BillingDefinitionInvoice bdi with (nolock) on bdi.ID = bd.BillingDefinitionInvoiceID
left outer join BillingDefinitionInvoiceLine bdil with (nolock) on bdil.ID = bd.BillingDefinitionInvoiceLineID
left outer join BillingDefinitionEvent bde with (nolock) on bde.ID = bd.BillingDefinitionEventID
left outer join Client cl with (nolock) on cl.ID = bdi.ClientID
left outer join BillingSchedule bs with (nolock) on bs.ID = bd.BillingScheduleID
left outer join BillingScheduleType bt with (nolock) on bt.ID = bs.ScheduleTypeID
left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bd.InvoiceDetailStatusID
left outer join BillingInvoiceDetailDisposition bidd with (nolock) on bidd.ID = bd.InvoiceDetailDispositionID
left outer join BillingAdjustmentReason bar with (nolock) on bar.ID = bd.AdjustmentReasonID
left outer join BillingExcludeReason ber with (nolock) on ber.ID = bd.ExcludeReasonID
--left outer join BillingInvoiceDetailException bide with (nolock) on bide.BillingInvoiceDetailID = bd.ID
--left outer join PurchaseOrder po with (nolock) on po.ID = bd.EntityKey and EntityID = (select ID from Entity with (nolock) where Name = 'PurchaseOrder')
where bd.BillingInvoiceLineID=@billingInvoiceLineID
--AND bd.AccountingInvoiceBatchID is null
INSERT INTO #FinalResults_filtered
SELECT 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	T.AdjustmentReason ,
	T.AdjustmentDate ,
	T.AdjustedBy ,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	T.ExcludedReason ,
	T.ExcludeDate,
	T.ExcludedBy,
	T.Entity,
	T.IsAdjusted,
	T.IsExcluded,
	T.InternalComment,
	[dbo].[fnConcatenate](bidet.[Description]) AS ExceptionMessage
FROM #tmpFinalResults T
left outer join BillingInvoiceDetailException bide with (nolock) on bide.BillingInvoiceDetailID = T.BillingInvoiceDetailID
left outer join BillingInvoiceDetailExceptionType bidet with(nolock) on bide.InvoiceDetailExceptionTypeID = bidet.ID 
GROUP BY 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	T.AdjustmentReason ,
	T.AdjustmentDate ,
	T.AdjustedBy ,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	T.ExcludedReason ,
	T.ExcludeDate,
	T.ExcludedBy,
	T.Entity,
	T.IsAdjusted,
	T.IsExcluded,
	T.InternalComment
	
INSERT INTO #FinalResults
SELECT 
	T.BillingInvoiceDetailID,
	T.BillingType,
	T.InvoiceDefinition,
	T.Client,
	T.LineSequence,
	T.LineName,
	T.ServiceCode,
	T.BillingDetailName,
	T.Quantity,
	T.DetailStatus,
	T.DetailDisposition,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustmentReason ELSE NULL END AS AdjustmentReason,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustmentDate ELSE NULL END AS AdjustmentDate,
	CASE WHEN ISNULL(T.IsAdjusted,0) = 1 THEN T.AdjustedBy ELSE NULL END AS AdjustedBy,
	T.SourceRecordNumber,
	T.BillingInvoiceScheduleTypeID,
	T.EventAmount,
	T.RateTypeName,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludedReason ELSE NULL END AS ExcludedReason,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludeDate ELSE NULL END AS ExcludeDate,
	CASE WHEN ISNULL(T.IsExcluded,0) = 1 THEN T.ExcludedBy ELSE NULL END AS ExcludedBy,
	T.Entity,
	T.InternalComment,
	T.ExceptionMessage
	
FROM #FinalResults_filtered T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingInvoiceDetailIDOperator = -1 ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 0 AND T.BillingInvoiceDetailID IS NULL ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 1 AND T.BillingInvoiceDetailID IS NOT NULL ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 2 AND T.BillingInvoiceDetailID = TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 3 AND T.BillingInvoiceDetailID <> TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 7 AND T.BillingInvoiceDetailID > TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 8 AND T.BillingInvoiceDetailID >= TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 9 AND T.BillingInvoiceDetailID < TMP.BillingInvoiceDetailIDValue ) 
 OR 
	 ( TMP.BillingInvoiceDetailIDOperator = 10 AND T.BillingInvoiceDetailID <= TMP.BillingInvoiceDetailIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.BillingTypeOperator = -1 ) 
 OR 
	 ( TMP.BillingTypeOperator = 0 AND T.BillingType IS NULL ) 
 OR 
	 ( TMP.BillingTypeOperator = 1 AND T.BillingType IS NOT NULL ) 
 OR 
	 ( TMP.BillingTypeOperator = 2 AND T.BillingType = TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 3 AND T.BillingType <> TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 4 AND T.BillingType LIKE TMP.BillingTypeValue + '%') 
 OR 
	 ( TMP.BillingTypeOperator = 5 AND T.BillingType LIKE '%' + TMP.BillingTypeValue ) 
 OR 
	 ( TMP.BillingTypeOperator = 6 AND T.BillingType LIKE '%' + TMP.BillingTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoiceDefinitionOperator = -1 ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 0 AND T.InvoiceDefinition IS NULL ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 1 AND T.InvoiceDefinition IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 2 AND T.InvoiceDefinition = TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 3 AND T.InvoiceDefinition <> TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 4 AND T.InvoiceDefinition LIKE TMP.InvoiceDefinitionValue + '%') 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 5 AND T.InvoiceDefinition LIKE '%' + TMP.InvoiceDefinitionValue ) 
 OR 
	 ( TMP.InvoiceDefinitionOperator = 6 AND T.InvoiceDefinition LIKE '%' + TMP.InvoiceDefinitionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LineSequenceOperator = -1 ) 
 OR 
	 ( TMP.LineSequenceOperator = 0 AND T.LineSequence IS NULL ) 
 OR 
	 ( TMP.LineSequenceOperator = 1 AND T.LineSequence IS NOT NULL ) 
 OR 
	 ( TMP.LineSequenceOperator = 2 AND T.LineSequence = TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 3 AND T.LineSequence <> TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 7 AND T.LineSequence > TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 8 AND T.LineSequence >= TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 9 AND T.LineSequence < TMP.LineSequenceValue ) 
 OR 
	 ( TMP.LineSequenceOperator = 10 AND T.LineSequence <= TMP.LineSequenceValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LineNameOperator = -1 ) 
 OR 
	 ( TMP.LineNameOperator = 0 AND T.LineName IS NULL ) 
 OR 
	 ( TMP.LineNameOperator = 1 AND T.LineName IS NOT NULL ) 
 OR 
	 ( TMP.LineNameOperator = 2 AND T.LineName = TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 3 AND T.LineName <> TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 4 AND T.LineName LIKE TMP.LineNameValue + '%') 
 OR 
	 ( TMP.LineNameOperator = 5 AND T.LineName LIKE '%' + TMP.LineNameValue ) 
 OR 
	 ( TMP.LineNameOperator = 6 AND T.LineName LIKE '%' + TMP.LineNameValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.InternalCommentOperator = -1 ) 
 OR 
	 ( TMP.InternalCommentOperator = 0 AND T.InternalComment IS NULL ) 
 OR 
	 ( TMP.InternalCommentOperator = 1 AND T.InternalComment IS NOT NULL ) 
 OR 
	 ( TMP.InternalCommentOperator = 2 AND T.InternalComment = TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 3 AND T.InternalComment <> TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 4 AND T.InternalComment LIKE TMP.InternalCommentValue + '%') 
 OR 
	 ( TMP.InternalCommentOperator = 5 AND T.InternalComment LIKE '%' + TMP.InternalCommentValue ) 
 OR 
	 ( TMP.InternalCommentOperator = 6 AND T.InternalComment LIKE '%' + TMP.InternalCommentValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceCodeOperator = -1 ) 
 OR 
	 ( TMP.ServiceCodeOperator = 0 AND T.ServiceCode IS NULL ) 
 OR 
	 ( TMP.ServiceCodeOperator = 1 AND T.ServiceCode IS NOT NULL ) 
 OR 
	 ( TMP.ServiceCodeOperator = 2 AND T.ServiceCode = TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 3 AND T.ServiceCode <> TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 4 AND T.ServiceCode LIKE TMP.ServiceCodeValue + '%') 
 OR 
	 ( TMP.ServiceCodeOperator = 5 AND T.ServiceCode LIKE '%' + TMP.ServiceCodeValue ) 
 OR 
	 ( TMP.ServiceCodeOperator = 6 AND T.ServiceCode LIKE '%' + TMP.ServiceCodeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.BillingDetailNameOperator = -1 ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 0 AND T.BillingDetailName IS NULL ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 1 AND T.BillingDetailName IS NOT NULL ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 2 AND T.BillingDetailName = TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 3 AND T.BillingDetailName <> TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 4 AND T.BillingDetailName LIKE TMP.BillingDetailNameValue + '%') 
 OR 
	 ( TMP.BillingDetailNameOperator = 5 AND T.BillingDetailName LIKE '%' + TMP.BillingDetailNameValue ) 
 OR 
	 ( TMP.BillingDetailNameOperator = 6 AND T.BillingDetailName LIKE '%' + TMP.BillingDetailNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.QuantityOperator = -1 ) 
 OR 
	 ( TMP.QuantityOperator = 0 AND T.Quantity IS NULL ) 
 OR 
	 ( TMP.QuantityOperator = 1 AND T.Quantity IS NOT NULL ) 
 OR 
	 ( TMP.QuantityOperator = 2 AND T.Quantity = TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 3 AND T.Quantity <> TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 7 AND T.Quantity > TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 8 AND T.Quantity >= TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 9 AND T.Quantity < TMP.QuantityValue ) 
 OR 
	 ( TMP.QuantityOperator = 10 AND T.Quantity <= TMP.QuantityValue ) 

 ) 

 AND 

 ( 
	 ( TMP.DetailStatusOperator = -1 ) 
 OR 
	 ( TMP.DetailStatusOperator = 0 AND T.DetailStatus IS NULL ) 
 OR 
	 ( TMP.DetailStatusOperator = 1 AND T.DetailStatus IS NOT NULL ) 
 OR 
	 ( TMP.DetailStatusOperator = 2 AND T.DetailStatus = TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 3 AND T.DetailStatus <> TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 4 AND T.DetailStatus LIKE TMP.DetailStatusValue + '%') 
 OR 
	 ( TMP.DetailStatusOperator = 5 AND T.DetailStatus LIKE '%' + TMP.DetailStatusValue ) 
 OR 
	 ( TMP.DetailStatusOperator = 6 AND T.DetailStatus LIKE '%' + TMP.DetailStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DetailDispositionOperator = -1 ) 
 OR 
	 ( TMP.DetailDispositionOperator = 0 AND T.DetailDisposition IS NULL ) 
 OR 
	 ( TMP.DetailDispositionOperator = 1 AND T.DetailDisposition IS NOT NULL ) 
 OR 
	 ( TMP.DetailDispositionOperator = 2 AND T.DetailDisposition = TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 3 AND T.DetailDisposition <> TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 4 AND T.DetailDisposition LIKE TMP.DetailDispositionValue + '%') 
 OR 
	 ( TMP.DetailDispositionOperator = 5 AND T.DetailDisposition LIKE '%' + TMP.DetailDispositionValue ) 
 OR 
	 ( TMP.DetailDispositionOperator = 6 AND T.DetailDisposition LIKE '%' + TMP.DetailDispositionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AdjustmentReasonOperator = -1 ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 0 AND T.AdjustmentReason IS NULL ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 1 AND T.AdjustmentReason IS NOT NULL ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 2 AND T.AdjustmentReason = TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 3 AND T.AdjustmentReason <> TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 4 AND T.AdjustmentReason LIKE TMP.AdjustmentReasonValue + '%') 
 OR 
	 ( TMP.AdjustmentReasonOperator = 5 AND T.AdjustmentReason LIKE '%' + TMP.AdjustmentReasonValue ) 
 OR 
	 ( TMP.AdjustmentReasonOperator = 6 AND T.AdjustmentReason LIKE '%' + TMP.AdjustmentReasonValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AdjustmentDateOperator = -1 ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 0 AND T.AdjustmentDate IS NULL ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 1 AND T.AdjustmentDate IS NOT NULL ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 2 AND T.AdjustmentDate = TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 3 AND T.AdjustmentDate <> TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 7 AND T.AdjustmentDate > TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 8 AND T.AdjustmentDate >= TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 9 AND T.AdjustmentDate < TMP.AdjustmentDateValue ) 
 OR 
	 ( TMP.AdjustmentDateOperator = 10 AND T.AdjustmentDate <= TMP.AdjustmentDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.AdjustedByOperator = -1 ) 
 OR 
	 ( TMP.AdjustedByOperator = 0 AND T.AdjustedBy IS NULL ) 
 OR 
	 ( TMP.AdjustedByOperator = 1 AND T.AdjustedBy IS NOT NULL ) 
 OR 
	 ( TMP.AdjustedByOperator = 2 AND T.AdjustedBy = TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 3 AND T.AdjustedBy <> TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 4 AND T.AdjustedBy LIKE TMP.AdjustedByValue + '%') 
 OR 
	 ( TMP.AdjustedByOperator = 5 AND T.AdjustedBy LIKE '%' + TMP.AdjustedByValue ) 
 OR 
	 ( TMP.AdjustedByOperator = 6 AND T.AdjustedBy LIKE '%' + TMP.AdjustedByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SourceRecordNumberOperator = -1 ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 0 AND T.SourceRecordNumber IS NULL ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 1 AND T.SourceRecordNumber IS NOT NULL ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 2 AND T.SourceRecordNumber = TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 3 AND T.SourceRecordNumber <> TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 4 AND T.SourceRecordNumber LIKE TMP.SourceRecordNumberValue + '%') 
 OR 
	 ( TMP.SourceRecordNumberOperator = 5 AND T.SourceRecordNumber LIKE '%' + TMP.SourceRecordNumberValue ) 
 OR 
	 ( TMP.SourceRecordNumberOperator = 6 AND T.SourceRecordNumber LIKE '%' + TMP.SourceRecordNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = -1 ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 0 AND T.BillingInvoiceScheduleTypeID IS NULL ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 1 AND T.BillingInvoiceScheduleTypeID IS NOT NULL ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 2 AND T.BillingInvoiceScheduleTypeID = TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 3 AND T.BillingInvoiceScheduleTypeID <> TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 7 AND T.BillingInvoiceScheduleTypeID > TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 8 AND T.BillingInvoiceScheduleTypeID >= TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 9 AND T.BillingInvoiceScheduleTypeID < TMP.BillingInvoiceScheduleTypeIDValue ) 
 OR 
	 ( TMP.BillingInvoiceScheduleTypeIDOperator = 10 AND T.BillingInvoiceScheduleTypeID <= TMP.BillingInvoiceScheduleTypeIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EventAmountOperator = -1 ) 
 OR 
	 ( TMP.EventAmountOperator = 0 AND T.EventAmount IS NULL ) 
 OR 
	 ( TMP.EventAmountOperator = 1 AND T.EventAmount IS NOT NULL ) 
 OR 
	 ( TMP.EventAmountOperator = 2 AND T.EventAmount = TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 3 AND T.EventAmount <> TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 7 AND T.EventAmount > TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 8 AND T.EventAmount >= TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 9 AND T.EventAmount < TMP.EventAmountValue ) 
 OR 
	 ( TMP.EventAmountOperator = 10 AND T.EventAmount <= TMP.EventAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RateTypeNameOperator = -1 ) 
 OR 
	 ( TMP.RateTypeNameOperator = 0 AND T.RateTypeName IS NULL ) 
 OR 
	 ( TMP.RateTypeNameOperator = 1 AND T.RateTypeName IS NOT NULL ) 
 OR 
	 ( TMP.RateTypeNameOperator = 2 AND T.RateTypeName = TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 3 AND T.RateTypeName <> TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 4 AND T.RateTypeName LIKE TMP.RateTypeNameValue + '%') 
 OR 
	 ( TMP.RateTypeNameOperator = 5 AND T.RateTypeName LIKE '%' + TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 6 AND T.RateTypeName LIKE '%' + TMP.RateTypeNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ExcludedReasonOperator = -1 ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 0 AND T.ExcludedReason IS NULL ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 1 AND T.ExcludedReason IS NOT NULL ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 2 AND T.ExcludedReason = TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 3 AND T.ExcludedReason <> TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 4 AND T.ExcludedReason LIKE TMP.ExcludedReasonValue + '%') 
 OR 
	 ( TMP.ExcludedReasonOperator = 5 AND T.ExcludedReason LIKE '%' + TMP.ExcludedReasonValue ) 
 OR 
	 ( TMP.ExcludedReasonOperator = 6 AND T.ExcludedReason LIKE '%' + TMP.ExcludedReasonValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ExcludeDateOperator = -1 ) 
 OR 
	 ( TMP.ExcludeDateOperator = 0 AND T.ExcludeDate IS NULL ) 
 OR 
	 ( TMP.ExcludeDateOperator = 1 AND T.ExcludeDate IS NOT NULL ) 
 OR 
	 ( TMP.ExcludeDateOperator = 2 AND T.ExcludeDate = TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 3 AND T.ExcludeDate <> TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 7 AND T.ExcludeDate > TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 8 AND T.ExcludeDate >= TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 9 AND T.ExcludeDate < TMP.ExcludeDateValue ) 
 OR 
	 ( TMP.ExcludeDateOperator = 10 AND T.ExcludeDate <= TMP.ExcludeDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ExcludedByOperator = -1 ) 
 OR 
	 ( TMP.ExcludedByOperator = 0 AND T.ExcludedBy IS NULL ) 
 OR 
	 ( TMP.ExcludedByOperator = 1 AND T.ExcludedBy IS NOT NULL ) 
 OR 
	 ( TMP.ExcludedByOperator = 2 AND T.ExcludedBy = TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 3 AND T.ExcludedBy <> TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 4 AND T.ExcludedBy LIKE TMP.ExcludedByValue + '%') 
 OR 
	 ( TMP.ExcludedByOperator = 5 AND T.ExcludedBy LIKE '%' + TMP.ExcludedByValue ) 
 OR 
	 ( TMP.ExcludedByOperator = 6 AND T.ExcludedBy LIKE '%' + TMP.ExcludedByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.EntityOperator = -1 ) 
 OR 
	 ( TMP.EntityOperator = 0 AND T.Entity IS NULL ) 
 OR 
	 ( TMP.EntityOperator = 1 AND T.Entity IS NOT NULL ) 
 OR 
	 ( TMP.EntityOperator = 2 AND T.Entity = TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 3 AND T.Entity <> TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 4 AND T.Entity LIKE TMP.EntityValue + '%') 
 OR 
	 ( TMP.EntityOperator = 5 AND T.Entity LIKE '%' + TMP.EntityValue ) 
 OR 
	 ( TMP.EntityOperator = 6 AND T.Entity LIKE '%' + TMP.EntityValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ClientOperator = -1 ) 
 OR 
	 ( TMP.ClientOperator = 0 AND T.Client IS NULL ) 
 OR 
	 ( TMP.ClientOperator = 1 AND T.Client IS NOT NULL ) 
 OR 
	 ( TMP.ClientOperator = 2 AND T.Client = TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 3 AND T.Client <> TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 4 AND T.Client LIKE TMP.ClientValue + '%') 
 OR 
	 ( TMP.ClientOperator = 5 AND T.Client LIKE '%' + TMP.ClientValue ) 
 OR 
	 ( TMP.ClientOperator = 6 AND T.Client LIKE '%' + TMP.ClientValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingInvoiceDetailID' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceDetailID END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceDetailID' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceDetailID END DESC ,

	 CASE WHEN @sortColumn = 'BillingType' AND @sortOrder = 'ASC'
	 THEN T.BillingType END ASC, 
	 CASE WHEN @sortColumn = 'BillingType' AND @sortOrder = 'DESC'
	 THEN T.BillingType END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDefinition' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDefinition END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDefinition' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDefinition END DESC ,

	 CASE WHEN @sortColumn = 'LineSequence' AND @sortOrder = 'ASC'
	 THEN T.LineSequence END ASC, 
	 CASE WHEN @sortColumn = 'LineSequence' AND @sortOrder = 'DESC'
	 THEN T.LineSequence END DESC ,

	 CASE WHEN @sortColumn = 'LineName' AND @sortOrder = 'ASC'
	 THEN T.LineName END ASC, 
	 CASE WHEN @sortColumn = 'LineName' AND @sortOrder = 'DESC'
	 THEN T.LineName END DESC ,

	 CASE WHEN @sortColumn = 'ServiceCode' AND @sortOrder = 'ASC'
	 THEN T.ServiceCode END ASC, 
	 CASE WHEN @sortColumn = 'ServiceCode' AND @sortOrder = 'DESC'
	 THEN T.ServiceCode END DESC ,

	 CASE WHEN @sortColumn = 'BillingDetailName' AND @sortOrder = 'ASC'
	 THEN T.BillingDetailName END ASC, 
	 CASE WHEN @sortColumn = 'BillingDetailName' AND @sortOrder = 'DESC'
	 THEN T.BillingDetailName END DESC ,

	 CASE WHEN @sortColumn = 'Quantity' AND @sortOrder = 'ASC'
	 THEN T.Quantity END ASC, 
	 CASE WHEN @sortColumn = 'Quantity' AND @sortOrder = 'DESC'
	 THEN T.Quantity END DESC ,

	 CASE WHEN @sortColumn = 'DetailStatus' AND @sortOrder = 'ASC'
	 THEN T.DetailStatus END ASC, 
	 CASE WHEN @sortColumn = 'DetailStatus' AND @sortOrder = 'DESC'
	 THEN T.DetailStatus END DESC ,

	 CASE WHEN @sortColumn = 'DetailDisposition' AND @sortOrder = 'ASC'
	 THEN T.DetailDisposition END ASC, 
	 CASE WHEN @sortColumn = 'DetailDisposition' AND @sortOrder = 'DESC'
	 THEN T.DetailDisposition END DESC ,

	 CASE WHEN @sortColumn = 'AdjustmentReason' AND @sortOrder = 'ASC'
	 THEN T.AdjustmentReason END ASC, 
	 CASE WHEN @sortColumn = 'AdjustmentReason' AND @sortOrder = 'DESC'
	 THEN T.AdjustmentReason END DESC ,

	 CASE WHEN @sortColumn = 'AdjustmentDate' AND @sortOrder = 'ASC'
	 THEN T.AdjustmentDate END ASC, 
	 CASE WHEN @sortColumn = 'AdjustmentDate' AND @sortOrder = 'DESC'
	 THEN T.AdjustmentDate END DESC ,

	 CASE WHEN @sortColumn = 'AdjustedBy' AND @sortOrder = 'ASC'
	 THEN T.AdjustedBy END ASC, 
	 CASE WHEN @sortColumn = 'AdjustedBy' AND @sortOrder = 'DESC'
	 THEN T.AdjustedBy END DESC ,

	 CASE WHEN @sortColumn = 'SourceRecordNumber' AND @sortOrder = 'ASC'
	 THEN T.SourceRecordNumber END ASC, 
	 CASE WHEN @sortColumn = 'SourceRecordNumber' AND @sortOrder = 'DESC'
	 THEN T.SourceRecordNumber END DESC ,

	 CASE WHEN @sortColumn = 'BillingInvoiceScheduleTypeID' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceScheduleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceScheduleTypeID' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceScheduleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'EventAmount' AND @sortOrder = 'ASC'
	 THEN T.EventAmount END ASC, 
	 CASE WHEN @sortColumn = 'EventAmount' AND @sortOrder = 'DESC'
	 THEN T.EventAmount END DESC ,

	 CASE WHEN @sortColumn = 'RateTypeName' AND @sortOrder = 'ASC'
	 THEN T.RateTypeName END ASC, 
	 CASE WHEN @sortColumn = 'RateTypeName' AND @sortOrder = 'DESC'
	 THEN T.RateTypeName END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedReason' AND @sortOrder = 'ASC'
	 THEN T.ExcludedReason END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedReason' AND @sortOrder = 'DESC'
	 THEN T.ExcludedReason END DESC ,

	 CASE WHEN @sortColumn = 'ExcludeDate' AND @sortOrder = 'ASC'
	 THEN T.ExcludeDate END ASC, 
	 CASE WHEN @sortColumn = 'ExcludeDate' AND @sortOrder = 'DESC'
	 THEN T.ExcludeDate END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedBy' AND @sortOrder = 'ASC'
	 THEN T.ExcludedBy END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedBy' AND @sortOrder = 'DESC'
	 THEN T.ExcludedBy END DESC ,

	 CASE WHEN @sortColumn = 'Entity' AND @sortOrder = 'ASC'
	 THEN T.Entity END ASC, 
	 CASE WHEN @sortColumn = 'Entity' AND @sortOrder = 'DESC'
	 THEN T.Entity END DESC ,

	 CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'ASC'
	 THEN T.Client END ASC, 
	 CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'DESC'
	 THEN T.Client END DESC ,

	 CASE WHEN @sortColumn = 'InternalComment' AND @sortOrder = 'ASC'
	 THEN T.InternalComment END ASC, 
	 CASE WHEN @sortColumn = 'InternalComment' AND @sortOrder = 'DESC'
	 THEN T.InternalComment END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
DROP TABLE #FinalResults_filtered
END
GO
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
 WHERE id = object_id(N'[dbo].[dms_Duplicate_Vendors_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Duplicate_Vendors_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXCE dms_Duplicate_Vendors_Get @vendorID=338
 --EXEC [dbo].[dms_Duplicate_Vendors_Get] @vendorID=338  
 CREATE PROCEDURE [dbo].[dms_Duplicate_Vendors_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @vendorID INT = NULL 	
 
 ) 
 AS 
 BEGIN 
 DECLARE
	@ID INT = NULL
 , @Address1 NVARCHAR(100) = NULL
 , @City NVARCHAR(100) = NULL
 , @OfficePhone NVARCHAR(100) = NULL
 , @DispatchPhone NVARCHAR(100) = NULL
 , @FaxPhone NVARCHAR (100) = NULL  
 , @VendorName NVARCHAR(100) = NULL
	SET FMTONLY OFF;
 	SET NOCOUNT ON
 
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
VendorLocationIDOperator="-1" 
SequenceOperator="-1" 
NameOperator="-1" 
VendorStatusOperator="-1" 
ContractStautsOperator="-1" 
Address1Operator="-1" 
StateCountryCityZipOperator="-1" 
DisptchTypeOperator="-1" 
DispatchNumberOperator="-1" 
OfficeTypeOperator="-1" 
OfficeNumberOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
VendorLocationIDOperator INT NOT NULL,
VendorLocationIDValue int NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
VendorStatusOperator INT NOT NULL,
VendorStatusValue nvarchar(100) NULL,
ContractStautsOperator INT NOT NULL,
ContractStautsValue nvarchar(100) NULL,
Address1Operator INT NOT NULL,
Address1Value nvarchar(100) NULL,
StateCountryCityZipOperator INT NOT NULL,
StateCountryCityZipValue nvarchar(100) NULL,
DisptchTypeOperator INT NOT NULL,
DisptchTypeValue int NULL,
DispatchNumberOperator INT NOT NULL,
DispatchNumberValue nvarchar(100) NULL,
OfficeTypeOperator INT NOT NULL,
OfficeTypeValue int NULL,
OfficeNumberOperator INT NOT NULL,
OfficeNumberValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	VendorLocationID int  NULL ,
	Sequence int  NULL ,
	VendorNumber nvarchar(100)  NULL ,
	Name nvarchar(255)  NULL ,
	VendorStatus nvarchar(100)  NULL ,
	ContractStauts nvarchar(100)  NULL ,
	Address1 nvarchar(100)  NULL ,
	StateCountryCityZip nvarchar(100)  NULL ,
	DisptchType int  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	OfficeType int  NULL ,
	OfficeNumber nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	VendorLocationID int  NULL ,
	Sequence int  NULL ,
	VendorNumber nvarchar(100)  NULL ,
	Name nvarchar(255)  NULL ,
	VendorStatus nvarchar(100)  NULL ,
	ContractStauts nvarchar(100)  NULL ,
	Address1 nvarchar(100)  NULL ,
	StateCountryCityZip nvarchar(100)  NULL ,
	DisptchType int  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	OfficeType int  NULL ,
	OfficeNumber nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@VendorLocationIDOperator','INT'),-1),
	T.c.value('@VendorLocationIDValue','int') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VendorStatusOperator','INT'),-1),
	T.c.value('@VendorStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ContractStautsOperator','INT'),-1),
	T.c.value('@ContractStautsValue','nvarchar(100)') ,
	ISNULL(T.c.value('@Address1Operator','INT'),-1),
	T.c.value('@Address1Value','nvarchar(100)') ,
	ISNULL(T.c.value('@StateCountryCityZipOperator','INT'),-1),
	T.c.value('@StateCountryCityZipValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DisptchTypeOperator','INT'),-1),
	T.c.value('@DisptchTypeValue','int') ,
	ISNULL(T.c.value('@DispatchNumberOperator','INT'),-1),
	T.c.value('@DispatchNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@OfficeTypeOperator','INT'),-1),
	T.c.value('@OfficeTypeValue','int') ,
	ISNULL(T.c.value('@OfficeNumberOperator','INT'),-1),
	T.c.value('@OfficeNumberValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


SELECT 
 @ID = v.ID,
 @Address1 = ae.Line1 ,
 @City = ae.City,
 @OfficePhone = peOfc.PhoneNumber,
 @DispatchPhone = pe24.PhoneNumber,
 @FaxPhone = peFax.PhoneNumber
 FROM VendorLocation vl    
INNER JOIN Vendor v on v.ID = vl.VendorID    
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')     
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')    
Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')    
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'Vendor') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')    
LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1    
 Where v.ID=@vendorID
 
INSERT INTO #tmpFinalResults
SELECT DISTINCT     
  v.ID    
 ,vl.ID  AS VendorLocationID   
 ,vl.Sequence    
 ,v.VendorNumber     
 ,v.Name     
 ,CASE --WHEN v.IsDoNotUse = 1 THEN 'Do Not Use'    
  WHEN v.IsActive = 0 THEN 'Inactive'    
  ELSE 'Active'    
  END  AS VendorStatus
 ,CASE     
  WHEN c.ID IS NOT NULL THEN 'Contracted'     
  ELSE 'Not Contracted'    
  END  AS ContractStauts
 ,ae.Line1 as Address1    
 --,ae.Line2 as Address2    
 ,REPLACE(RTRIM(    
   COALESCE(ae.City, '') +    
   COALESCE(', ' + ae.StateProvince,'') +     
   COALESCE(' ' + LTRIM(ae.PostalCode), '') +     
   COALESCE(' ' + ae.CountryCode, '')     
   ), ' ', ' ')     AS StateCountryCityZip 
 , pe24.PhoneTypeID  AS DisptchType
 , pe24.PhoneNumber  AS DispatchNumber  
 , peOfc.PhoneTypeID  AS OfficeType   
 , peOfc.PhoneNumber  AS OfficeNumber
FROM VendorLocation vl    
INNER JOIN Vendor v on v.ID = vl.VendorID    
LEFT OUTER JOIN AddressEntity ae on ae.RecordID = vl.ID and ae.EntityID = (Select ID From Entity Where Name = 'VendorLocation')     
LEFT OUTER JOIN PhoneEntity pe24 on pe24.RecordID = vl.ID and pe24.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and pe24.PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')    
--Left Outer Join PhoneEntity peFax on peFax.RecordID = vl.ID and peFax.EntityID = (Select ID From Entity Where Name = 'VendorLocation') and peFax.PhoneTypeID = (Select ID From PhoneType Where Name = 'Fax')    
LEFT OUTER JOIN PhoneEntity peOfc on peOfc.RecordID = v.ID and peOfc.EntityID = (Select ID From Entity Where Name = 'Vendor') and peOfc.PhoneTypeID = (Select ID From PhoneType Where Name = 'Office')    
LEFT OUTER JOIN [Contract] c on c.VendorID = v.ID and c.IsActive = 1    

WHERE     
(v.VendorNumber IS NULL OR v.VendorNumber NOT LIKE '9X%' ) --KB: VendorNumber will be NULL for newly added vendors and these are getting excluded from the possible duplicates  
AND  
-- TP: Matching either phone number across both phone types is valid for this search;   
--     grouped OR condition -- A match on either phone number is valid  
(ISNULL(pe24.PhoneNumber,'') IN (@DispatchPhone, @OfficePhone, @FaxPhone)  
 OR  
 ISNULL(peOfc.PhoneNumber,'') IN (@DispatchPhone, @OfficePhone, @FaxPhone)  
 OR
 (ae.Line1 LIKE '%' + @Address1 + '%')
 AND
 (ae.City LIKE '%' + @City  + '%') 
 AND 
 (v.Name LIKE @VendorName)
)  
AND v.ID <> @ID

INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.VendorLocationID,
	T.Sequence,
	T.VendorNumber,
	T.Name,
	T.VendorStatus,
	T.ContractStauts,
	T.Address1,
	T.StateCountryCityZip,
	T.DisptchType,
	T.DispatchNumber,
	T.OfficeType,
	T.OfficeNumber
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.IDOperator = -1 ) 
 OR 
	 ( TMP.IDOperator = 0 AND T.ID IS NULL ) 
 OR 
	 ( TMP.IDOperator = 1 AND T.ID IS NOT NULL ) 
 OR 
	 ( TMP.IDOperator = 2 AND T.ID = TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 3 AND T.ID <> TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 7 AND T.ID > TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 8 AND T.ID >= TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 9 AND T.ID < TMP.IDValue ) 
 OR 
	 ( TMP.IDOperator = 10 AND T.ID <= TMP.IDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.VendorLocationIDOperator = -1 ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 0 AND T.VendorLocationID IS NULL ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 1 AND T.VendorLocationID IS NOT NULL ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 2 AND T.VendorLocationID = TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 3 AND T.VendorLocationID <> TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 7 AND T.VendorLocationID > TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 8 AND T.VendorLocationID >= TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 9 AND T.VendorLocationID < TMP.VendorLocationIDValue ) 
 OR 
	 ( TMP.VendorLocationIDOperator = 10 AND T.VendorLocationID <= TMP.VendorLocationIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.SequenceOperator = -1 ) 
 OR 
	 ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL ) 
 OR 
	 ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL ) 
 OR 
	 ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue ) 

 ) 

 AND 

 ( 
	 ( TMP.NameOperator = -1 ) 
 OR 
	 ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
	 ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
	 ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
	 ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VendorStatusOperator = -1 ) 
 OR 
	 ( TMP.VendorStatusOperator = 0 AND T.VendorStatus IS NULL ) 
 OR 
	 ( TMP.VendorStatusOperator = 1 AND T.VendorStatus IS NOT NULL ) 
 OR 
	 ( TMP.VendorStatusOperator = 2 AND T.VendorStatus = TMP.VendorStatusValue ) 
 OR 
	 ( TMP.VendorStatusOperator = 3 AND T.VendorStatus <> TMP.VendorStatusValue ) 
 OR 
	 ( TMP.VendorStatusOperator = 4 AND T.VendorStatus LIKE TMP.VendorStatusValue + '%') 
 OR 
	 ( TMP.VendorStatusOperator = 5 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue ) 
 OR 
	 ( TMP.VendorStatusOperator = 6 AND T.VendorStatus LIKE '%' + TMP.VendorStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ContractStautsOperator = -1 ) 
 OR 
	 ( TMP.ContractStautsOperator = 0 AND T.ContractStauts IS NULL ) 
 OR 
	 ( TMP.ContractStautsOperator = 1 AND T.ContractStauts IS NOT NULL ) 
 OR 
	 ( TMP.ContractStautsOperator = 2 AND T.ContractStauts = TMP.ContractStautsValue ) 
 OR 
	 ( TMP.ContractStautsOperator = 3 AND T.ContractStauts <> TMP.ContractStautsValue ) 
 OR 
	 ( TMP.ContractStautsOperator = 4 AND T.ContractStauts LIKE TMP.ContractStautsValue + '%') 
 OR 
	 ( TMP.ContractStautsOperator = 5 AND T.ContractStauts LIKE '%' + TMP.ContractStautsValue ) 
 OR 
	 ( TMP.ContractStautsOperator = 6 AND T.ContractStauts LIKE '%' + TMP.ContractStautsValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.Address1Operator = -1 ) 
 OR 
	 ( TMP.Address1Operator = 0 AND T.Address1 IS NULL ) 
 OR 
	 ( TMP.Address1Operator = 1 AND T.Address1 IS NOT NULL ) 
 OR 
	 ( TMP.Address1Operator = 2 AND T.Address1 = TMP.Address1Value ) 
 OR 
	 ( TMP.Address1Operator = 3 AND T.Address1 <> TMP.Address1Value ) 
 OR 
	 ( TMP.Address1Operator = 4 AND T.Address1 LIKE TMP.Address1Value + '%') 
 OR 
	 ( TMP.Address1Operator = 5 AND T.Address1 LIKE '%' + TMP.Address1Value ) 
 OR 
	 ( TMP.Address1Operator = 6 AND T.Address1 LIKE '%' + TMP.Address1Value + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StateCountryCityZipOperator = -1 ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 0 AND T.StateCountryCityZip IS NULL ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 1 AND T.StateCountryCityZip IS NOT NULL ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 2 AND T.StateCountryCityZip = TMP.StateCountryCityZipValue ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 3 AND T.StateCountryCityZip <> TMP.StateCountryCityZipValue ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 4 AND T.StateCountryCityZip LIKE TMP.StateCountryCityZipValue + '%') 
 OR 
	 ( TMP.StateCountryCityZipOperator = 5 AND T.StateCountryCityZip LIKE '%' + TMP.StateCountryCityZipValue ) 
 OR 
	 ( TMP.StateCountryCityZipOperator = 6 AND T.StateCountryCityZip LIKE '%' + TMP.StateCountryCityZipValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DisptchTypeOperator = -1 ) 
 OR 
	 ( TMP.DisptchTypeOperator = 0 AND T.DisptchType IS NULL ) 
 OR 
	 ( TMP.DisptchTypeOperator = 1 AND T.DisptchType IS NOT NULL ) 
 OR 
	 ( TMP.DisptchTypeOperator = 2 AND T.DisptchType = TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 3 AND T.DisptchType <> TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 7 AND T.DisptchType > TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 8 AND T.DisptchType >= TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 9 AND T.DisptchType < TMP.DisptchTypeValue ) 
 OR 
	 ( TMP.DisptchTypeOperator = 10 AND T.DisptchType <= TMP.DisptchTypeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.DispatchNumberOperator = -1 ) 
 OR 
	 ( TMP.DispatchNumberOperator = 0 AND T.DispatchNumber IS NULL ) 
 OR 
	 ( TMP.DispatchNumberOperator = 1 AND T.DispatchNumber IS NOT NULL ) 
 OR 
	 ( TMP.DispatchNumberOperator = 2 AND T.DispatchNumber = TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 3 AND T.DispatchNumber <> TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 4 AND T.DispatchNumber LIKE TMP.DispatchNumberValue + '%') 
 OR 
	 ( TMP.DispatchNumberOperator = 5 AND T.DispatchNumber LIKE '%' + TMP.DispatchNumberValue ) 
 OR 
	 ( TMP.DispatchNumberOperator = 6 AND T.DispatchNumber LIKE '%' + TMP.DispatchNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.OfficeTypeOperator = -1 ) 
 OR 
	 ( TMP.OfficeTypeOperator = 0 AND T.OfficeType IS NULL ) 
 OR 
	 ( TMP.OfficeTypeOperator = 1 AND T.OfficeType IS NOT NULL ) 
 OR 
	 ( TMP.OfficeTypeOperator = 2 AND T.OfficeType = TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 3 AND T.OfficeType <> TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 7 AND T.OfficeType > TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 8 AND T.OfficeType >= TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 9 AND T.OfficeType < TMP.OfficeTypeValue ) 
 OR 
	 ( TMP.OfficeTypeOperator = 10 AND T.OfficeType <= TMP.OfficeTypeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.OfficeNumberOperator = -1 ) 
 OR 
	 ( TMP.OfficeNumberOperator = 0 AND T.OfficeNumber IS NULL ) 
 OR 
	 ( TMP.OfficeNumberOperator = 1 AND T.OfficeNumber IS NOT NULL ) 
 OR 
	 ( TMP.OfficeNumberOperator = 2 AND T.OfficeNumber = TMP.OfficeNumberValue ) 
 OR 
	 ( TMP.OfficeNumberOperator = 3 AND T.OfficeNumber <> TMP.OfficeNumberValue ) 
 OR 
	 ( TMP.OfficeNumberOperator = 4 AND T.OfficeNumber LIKE TMP.OfficeNumberValue + '%') 
 OR 
	 ( TMP.OfficeNumberOperator = 5 AND T.OfficeNumber LIKE '%' + TMP.OfficeNumberValue ) 
 OR 
	 ( TMP.OfficeNumberOperator = 6 AND T.OfficeNumber LIKE '%' + TMP.OfficeNumberValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'ASC'
	 THEN T.VendorLocationID END ASC, 
	 CASE WHEN @sortColumn = 'VendorLocationID' AND @sortOrder = 'DESC'
	 THEN T.VendorLocationID END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'
	 THEN T.VendorNumber END ASC, 
	 CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'
	 THEN T.VendorNumber END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'ASC'
	 THEN T.VendorStatus END ASC, 
	 CASE WHEN @sortColumn = 'VendorStatus' AND @sortOrder = 'DESC'
	 THEN T.VendorStatus END DESC ,

	 CASE WHEN @sortColumn = 'ContractStauts' AND @sortOrder = 'ASC'
	 THEN T.ContractStauts END ASC, 
	 CASE WHEN @sortColumn = 'ContractStauts' AND @sortOrder = 'DESC'
	 THEN T.ContractStauts END DESC ,

	 CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'ASC'
	 THEN T.Address1 END ASC, 
	 CASE WHEN @sortColumn = 'Address1' AND @sortOrder = 'DESC'
	 THEN T.Address1 END DESC ,

	 CASE WHEN @sortColumn = 'StateCountryCityZip' AND @sortOrder = 'ASC'
	 THEN T.StateCountryCityZip END ASC, 
	 CASE WHEN @sortColumn = 'StateCountryCityZip' AND @sortOrder = 'DESC'
	 THEN T.StateCountryCityZip END DESC ,

	 CASE WHEN @sortColumn = 'DisptchType' AND @sortOrder = 'ASC'
	 THEN T.DisptchType END ASC, 
	 CASE WHEN @sortColumn = 'DisptchType' AND @sortOrder = 'DESC'
	 THEN T.DisptchType END DESC ,

	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'ASC'
	 THEN T.DispatchNumber END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'DESC'
	 THEN T.DispatchNumber END DESC ,

	 CASE WHEN @sortColumn = 'OfficeType' AND @sortOrder = 'ASC'
	 THEN T.OfficeType END ASC, 
	 CASE WHEN @sortColumn = 'OfficeType' AND @sortOrder = 'DESC'
	 THEN T.OfficeType END DESC ,

	 CASE WHEN @sortColumn = 'OfficeNumber' AND @sortOrder = 'ASC'
	 THEN T.OfficeNumber END ASC, 
	 CASE WHEN @sortColumn = 'OfficeNumber' AND @sortOrder = 'DESC'
	 THEN T.OfficeNumber END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResults
SET @endInd = @startInd + @pageSize - 1
IF @startInd  > @count   
BEGIN   
	DECLARE @numOfPages INT    
	SET @numOfPages = @count / @pageSize   
	IF @count % @pageSize > 1   
	BEGIN   
		SET @numOfPages = @numOfPages + 1   
	END   
	SET @startInd = ((@numOfPages - 1) * @pageSize) + 1   
	SET @endInd = @numOfPages * @pageSize   
END

SELECT @count AS TotalRows, * FROM #FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
DROP TABLE #tmpFinalResults
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_IsPreferredVendorsByProduct]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_IsPreferredVendorsByProduct] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 	

CREATE PROC dms_IsPreferredVendorsByProduct(@VendorID INT = NULL,@ProductID INT  =  NULL)
AS
BEGIN

	DECLARE @IsPreferred AS BIT
	SET @IsPreferred = ISNULL((SELECT 1 From [dbo].[fnGetPreferredVendorsByProduct]() Where VendorID = @VendorID AND ProductID = @ProductID),0) 
	
	DECLARE  @Result AS TABLE(IsPreferred BIT NOT NULL)
	INSERT INTO @Result VALUES(@IsPreferred)
	SELECT * FROM @Result

END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ISPSelection_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ISPSelection_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO   
-- EXEC [dbo].[dms_ISPSelection_get]  1414,null,1,1,200,0.2,0.4,0.4,0,'Location',NULL
-- EXEC [dbo].[dms_ISPSelection_get]  44022,5,1,1,50,0.4,0.1,0.5,0,'Location'
/* Debug */
--DECLARE 
--    @ServiceRequestID int  = 44022 
--    ,@ActualServiceMiles decimal(10,2)  = 5 
--    ,@VehicleTypeID int  = 1 
--    ,@VehicleCategoryID int  = 1 
--    ,@SearchRadiusMiles int  = 50 
--    ,@AdminWeight decimal(5,2)  = .1 
--    ,@PerformWeight decimal(5,2) = .2  
--    ,@CostWeight decimal(5,2)  = .7 
--    ,@IncludeDoNotUse bit  = 0 
--    ,@SearchFrom nvarchar(50) = 'Location'
--    ,@productIDs NVARCHAR(MAX) = NULL 
      
CREATE PROCEDURE [dbo].[dms_ISPSelection_get]  
      @ServiceRequestID int  = NULL 
      ,@ActualServiceMiles decimal(10,2)  = NULL 
      ,@VehicleTypeID int  = NULL 
      ,@VehicleCategoryID int  = NULL 
      ,@SearchRadiusMiles int  = NULL 
      ,@AdminWeight decimal(5,2)  = NULL 
      ,@PerformWeight decimal(5,2) = NULL  
      ,@CostWeight decimal(5,2)  = NULL 
      ,@IncludeDoNotUse bit  = NULL 
      ,@SearchFrom nvarchar(50) = NULL
      ,@productIDs NVARCHAR(MAX) = NULL -- comma separated list of product IDs.
AS  
BEGIN    
  
/* Variable Declarations */  
DECLARE       
      @ServiceLocationLatitude decimal(10,7)   
    ,@ServiceLocationLongitude decimal(10,7)    
    ,@ServiceLocationStateProvince nvarchar(2)  
    ,@ServiceLocationCountryCode nvarchar(10)   
    ,@ServiceLocationPostalCode nvarchar(20)
    ,@DestinationLocationLatitude decimal(10,7)    
    ,@DestinationLocationLongitude decimal(10,7)  
    ,@PrimaryProductID int   
    ,@SecondaryProductID int  
    ,@ProductCategoryID int  
    ,@SecondaryProductCategoryID int  
    ,@MembershipID int  
    ,@ProgramID INT  
    ,@pcAdminWeight decimal(5,2)  = NULL   
      ,@pcPerformWeight decimal(5,2) = NULL    
      ,@pcCostWeight decimal(5,2)  = NULL   
      ,@IsTireDelivery bit  
      ,@LogISPSelection bit  
      ,@LogISPSelectionFinal bit  
  
/* Set Logging On/Off */  
SET @LogISPSelection = 0  
SET @LogISPSelectionFinal = 1  
  
/* Hard-coded radius for Do-Not-Use vendor selection - Should be added to ApplicationConfiguration */  
DECLARE @DNUSearchRadiusMiles int    
SET @DNUSearchRadiusMiles = 50    
  
/* Get Current Time for log inserts */  
DECLARE @now DATETIME = GETDATE()  
  
  
/* Work table declarations *******************************************************/  
SET FMTONLY OFF  
DECLARE @ISPSelection TABLE (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NOT NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[BusinessHours] [nvarchar](100) NOT NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NOT NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NOT NULL,
[IsPreferred] [int] NULL
)   
  
DECLARE @ISPSelectionFinalResults TABLE (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NOT NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR : 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[BusinessHours] [nvarchar](100) NOT NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NOT NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NOT NULL,  
[AllServices] [NVARCHAR](MAX) NULL,  
[ProductSearchRadiusMiles] [int] NULL,  
[IsInProductSearchRadius] [bit] NULL,
[IsPreferred] [int] NULL  
)  
  
CREATE TABLE #ISPDoNotUse (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NULL,  
[Address1] [nvarchar](100) NULL,  
[Address2] [nvarchar](100) NULL,  
[City] [nvarchar](100) NULL,  
[StateProvince] [nvarchar](10) NULL,  
[PostalCode] [nvarchar](20) NULL,  
[CountryCode] [nvarchar](2) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[FaxPhoneNumber] [nvarchar](50) NULL,   
[OfficePhoneNumber] [nvarchar](50) NULL,  
[CellPhoneNumber] [nvarchar](50) NULL, -- CR: 1226  
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NULL,  
[BusinessHours] [nvarchar](100) NULL,  
[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[ProductID] [int] NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[EnrouteMiles] [float] NULL,  
[EnrouteTimeMinutes] [int] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ServiceTimeMinutes] [int] NULL,  
[ReturnMiles] [float] NULL,  
[ReturnTimeMinutes] [int] NULL,  
[EstimatedHours] [float] NULL,  
[BaseRate] [money] NULL,  
[HourlyRate] [money] NULL,  
[EnrouteRate] [money] NULL,  
[EnrouteFreeMiles] [int] NULL,  
[ServiceRate] [money] NULL,  
[ServiceFreeMiles] [int] NULL,  
[EstimatedPrice] [float] NULL,  
[WiseScore] [float] NULL,  
[CallStatus] [varchar](9) NULL,  
[RejectReason] [nvarchar](255) NULL,  
[RejectComment] [nvarchar](max) NULL,  
[IsPossibleCallback] [bit] NULL  
)   
  
CREATE TABLE #IspDetail (  
[VendorID] [int] NOT NULL,  
[VendorLocationID] [int] NOT NULL,  
[VendorLocationVirtualID] [int] NULL,  
[Latitude] [decimal](10, 7) NULL,  
[Longitude] [decimal](10, 7) NULL,  
[VendorName] [nvarchar](255) NULL,  
[VendorNumber] [nvarchar](50) NULL,  
[Source] [varchar](8) NOT NULL,  
[ContractStatus] [nvarchar](50) NULL,  
[DispatchPhoneNumber] [nvarchar](50) NULL,  
[AlternateDispatchPhoneNumber] [nvarchar](50) NULL, -- TFS: 105
[AdministrativeRating] [int] NULL,  
[InsuranceStatus] [varchar](11) NOT NULL,  
[IsOpen24Hours] [bit] NULL,  
[BusinessHours] [nvarchar](100) NULL,  
--[PaymentTypes] [nvarchar] (100) NULL,    
[Comment] [nvarchar](2000) NULL,  
[EnrouteMiles] [float] NULL,  
[ServiceMiles] [decimal](10, 2) NULL,  
[ReturnMiles] [float] NULL,  
[ProductID] [int] NOT NULL,  
[ProductName] [nvarchar](50) NULL,  
[ProductRating] [decimal](5, 2) NULL,  
[RateTypeID] [int] NULL,  
[RatePrice] [money] NULL,  
[RateQuantity] [int] NULL,  
[RateTypeName] [nvarchar](50) NULL,  
[RateUnitOfMeasure] [nvarchar](50) NULL,  
[RateUnitOfMeasureSource] [nvarchar](50) NULL,  
[IsProductMatch] [int] NOT NULL,
[IsPreferred] [int] NULL  
)   
  
-- Get service information from ServiceRequest  
SELECT         
      @ServiceLocationLatitude = SR.ServiceLocationLatitude,  
    @ServiceLocationLongitude = SR.ServiceLocationLongitude,  
    @ServiceLocationStateProvince = SR.ServiceLocationStateProvince,  
    @ServiceLocationCountryCode = SR.ServiceLocationCountryCode,  
    @ServiceLocationPostalCode = SR.ServiceLocationPostalCode,
    @DestinationLocationLatitude = SR.DestinationLatitude,  
    @DestinationLocationLongitude = SR.DestinationLongitude,  
    @PrimaryProductID = SR.PrimaryProductID,  
    @SecondaryProductID = SR.SecondaryProductID,  
    @ProductCategoryID = SR.ProductCategoryID,  
   @MembershipID = m.MembershipID,  
    @ProgramID = c.ProgramID  
FROM  ServiceRequest SR  
JOIN [Case] c ON SR.CaseID = c.ID  
JOIN Member m ON c.MemberID = m.ID  
WHERE SR.ID = @ServiceRequestID  
  
SET @SecondaryProductCategoryID = (SELECT ProductCategoryID FROM Product WHERE ID = @SecondaryProductID)  
  
-- Additional condition needed to include tire stores if tire service and tire delivery selected  
SET @IsTireDelivery = ISNULL((SELECT 1 FROM ServiceRequestDetail WHERE @ProductCategoryID = 2 AND ServiceRequestID = @ServiceRequestID AND ProductCategoryQuestionID = 203 AND Answer = 'Tire Delivery'),0)  
  
-- Set program specific ISP scoring weights */  
DECLARE @ProgramConfig TABLE (  
      Name NVARCHAR(50) NULL,  
      Value NVARCHAR(255) NULL  
)  
  
;WITH wProgramConfig   
AS  
(     SELECT ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS RowNum,  
                  PP.Sequence,  
                  PC.Name,      
                  PC.Value      
      FROM fnc_GetProgramsandParents(@ProgramID) PP  
      JOIN ProgramConfiguration PC ON PP.ProgramID = PC.ProgramID AND PC.IsActive = 1  
      WHERE PC.ConfigurationTypeID = 5   
      AND         PC.ConfigurationCategoryID = 3  
)  
  
INSERT INTO @ProgramConfig  
SELECT      W.Name,  
            W.Value  
FROM  wProgramConfig W  
WHERE W.RowNum = 1  
  
SET @pcAdminWeight = NULL  
SET @pcPerformWeight = NULL  
SET @pcCostWeight = NULL  
SELECT @pcAdminWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultAdminWeighting'  
SELECT @pcPerformWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultPerformanceWeighting'  
SELECT @pcCostWeight = CONVERT(DECIMAL(5,2),Value) FROM @ProgramConfig WHERE Name = 'DefaultCostWeighting'  
  
-- DEBUG : SELECT @pcAdminWeight AS AdminWeight, @pcCostWeight AS CostWeight, @pcPerformWeight AS PerfWeight  
-- If one the values is not defined, then use the values from ApplicationConfiguration.  
-- In other words, if all the three values are found, then override the ones from the app config.  
IF @pcAdminWeight IS NOT NULL AND @pcCostWeight IS NOT NULL AND @pcPerformWeight IS NOT NULL  
BEGIN  
      PRINT 'Using the values from ProgramConfig'  
        
      SET @AdminWeight = @pcAdminWeight  
      SET @CostWeight = @pcCostWeight  
      SET @PerformWeight = @pcPerformWeight  
END  
    
/* Get geography values for service location and towing destination */    
DECLARE @ServiceLocation as geography    
      ,@DestinationLocation as geography    
IF (@ServiceLocationLatitude IS NOT NULL AND @ServiceLocationLongitude IS NOT NULL)  
BEGIN  
    SET @ServiceLocation = geography::Point(@ServiceLocationLatitude, @ServiceLocationLongitude, 4326)    
END  
IF (@DestinationLocationLatitude IS NOT NULL AND @DestinationLocationLongitude IS NOT NULL)  
BEGIN  
    SET @DestinationLocation = geography::Point(@DestinationLocationLatitude, @DestinationLocationLongitude, 4326)    
END  
    
/* Set Service Miles based on service and destination locations - same for all vendors */    
DECLARE @ServiceMiles decimal(10,2)    
IF @ActualServiceMiles IS NOT NULL    
SET @ServiceMiles = @ActualServiceMiles    
ELSE    
SET @ServiceMiles = ROUND(@DestinationLocation.STDistance(@ServiceLocation)/1609.344,0)    
  
/* Get Market product rates according to market location */  
CREATE TABLE #MarketRates (  
[ProductID] [int] NULL,  
[RateTypeID] [int] NULL,  
[Name] [nvarchar](50) NULL,  
[Price] [money] NULL,  
[Quantity] [int] NULL  
)  
  
INSERT INTO #MarketRates  
SELECT ProductID, RateTypeID, Name, RatePrice, RateQuantity  
FROM dbo.fnGetDefaultProductRatesByMarketLocation(@ServiceLocation, @ServiceLocationCountryCode, @ServiceLocationStateProvince)  
  
CREATE CLUSTERED INDEX IDX_MarketRates ON #MarketRates(ProductID, RateTypeID)  
  
/* Get ISP Search Radius increment (bands) based on service and location (metro or rural) */  
DECLARE @IsMetroLocation bit  
DECLARE @ProductSearchRadiusMiles int  
  
/* Determine if service location is within a Metro Market Location radius */  
SET @IsMetroLocation = ISNULL(  
      (SELECT TOP 1 1   
      FROM MarketLocation ml  
      WHERE ml.MarketLocationTypeID = (SELECT ID FROM MarketLocationType WHERE Name = 'Metro')  
      And ml.IsActive = 'TRUE'  
      and ml.GeographyLocation.STDistance(@ServiceLocation) <= ml.RadiusMiles * 1609.344)  
      ,0)  
  
SELECT @ProductSearchRadiusMiles = CASE WHEN @IsMetroLocation = 1 THEN MetroRadius ELSE RuralRadius END   
FROM ProductISPSelectionRadius r  
WHERE ProductID = @PrimaryProductID   
  
IF @ProductSearchRadiusMiles IS NULL   
      SET @ProductSearchRadiusMiles = @SearchRadiusMiles  
  
  
/* Get reference type IDs */    
DECLARE     
            @VendorEntityID int    
            ,@VendorLocationEntityID int    
            ,@ServiceRequestEntityID int    
            ,@BusinessAddressTypeID int    
            ,@DispatchPhoneTypeID int  
			,@AltDispatchPhoneTypeID int 
            ,@FaxPhoneTypeID int  
            ,@OfficePhoneTypeID int    
            ,@CellPhoneTypeID int -- CR : 1226  
            ,@PrimaryServiceProductSubTypeID int    
            ,@ActiveVendorStatusID int  
            ,@DoNotUseVendorStatusID int  
            ,@ActiveVendorLocationStatusID int  
SET @VendorEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'Vendor')    
SET @VendorLocationEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'VendorLocation')    
SET @ServiceRequestEntityID = (SELECT ID FROM dbo.Entity WHERE Name = 'ServiceRequest')    
SET @BusinessAddressTypeID = (SELECT ID FROM dbo.AddressType WHERE Name = 'Business')    
SET @DispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Dispatch') 
SET @AltDispatchPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'AlternateDispatch') -- TFS : 105   
SET @FaxPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Fax')    
SET @OfficePhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Office')    
SET @CellPhoneTypeID = (SELECT ID FROM dbo.PhoneType WHERE Name = 'Cell')  -- CR: 1226  
SET @PrimaryServiceProductSubTypeID = (Select ID From dbo.ProductSubType Where Name = 'PrimaryService')    
SET @ActiveVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'Active')    
SET @DoNotUseVendorStatusID = (SELECT ID FROM dbo.VendorStatus WHERE Name = 'DoNotUse')    
SET @ActiveVendorLocationStatusID = (SELECT ID FROM dbo.VendorLocationStatus WHERE Name = 'Active')    
  
    
/* Get list of ALL vendors within the Search Radius of the service location */  
SELECT V.ID VendorID  
      ,vl.ID VendorLocationID  
      ,NULL AS VendorLocationVirtualID  
      ,vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance  
      ,vl.GeographyLocation  
      ,vl.Latitude  
      ,vl.Longitude  
INTO #tmpVendorLocation  
FROM VendorLocation vl  
JOIN Vendor V ON vl.VendorID = V.ID  
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID  
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
AND vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344    
--If using zip codes, only include if zip code is serviced by the vendor location
AND (
	ISNULL(vl.IsUsingZipCodes,0) = 0
	OR
	@ServiceLocationPostalCode IS NULL
	OR
	@ServiceLocationPostalCode = 'null' --Work around for ODIS bug, TFS #456
	OR
	EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
			WHERE vlZip.VendorLocationID = vl.ID AND vlZip.PostalCode = @ServiceLocationPostalCode)
	)
  
-- Include search of related Vendor Location virtual mapping points   
INSERT INTO #tmpVendorLocation  
SELECT V.ID VendorID  
      ,vl.ID VendorLocationID  
      ,vlv.ID VendorLocationVirtualID  
      ,vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) Distance  
      ,vlv.GeographyLocation  
      ,vlv.Latitude  
      ,vlv.Longitude  
FROM VendorLocation vl  
JOIN Vendor V ON vl.VendorID = V.ID  
JOIN VendorLocationVirtual vlv on vlv.VendorLocationID = vl.ID --AND vlv.IsActive = 1  
WHERE V.IsActive = 1 AND V.VendorStatusID = @ActiveVendorStatusID  
AND vl.IsActive = 1 AND vl.VendorLocationStatusID = @ActiveVendorLocationStatusID  
AND vlv.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @SearchRadiusMiles * 1609.344    
--If using zip codes, only include if zip code is serviced by the vendor location
AND (
	ISNULL(vl.IsUsingZipCodes,0) = 0
	--OR --Check for at least one zip code if vendor location configured to use zip codes
	--(ISNULL(vl.IsUsingZipCodes,0) = 1 AND NOT EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
	--		WHERE vlZip.VendorLocationID = vl.ID))
	OR
	EXISTS(SELECT * FROM VendorLocationPostalCode vlzip
			WHERE vlZip.VendorLocationID = vl.ID AND vlZip.PostalCode = @ServiceLocationPostalCode)
	)
  
/* Index physical locations */  
CREATE NONCLUSTERED INDEX [IDX_tmpVendors_VendorLocationID] ON #tmpVendorLocation  
([VendorLocationID] ASC)  
WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]  
  
/* Reduce list to only the closest location if the vendor has multiple physical or virtual locations within the Search Radius */  
DELETE #tmpVendorLocation   
FROM #tmpVendorLocation vl1  
WHERE NOT EXISTS (  
      SELECT *  
      FROM #tmpVendorLocation vl2  
      JOIN (  
            SELECT VendorID, MIN(Distance) Distance  
            FROM #tmpVendorLocation   
            GROUP BY VendorID  
            ) ClosestLocation   
            ON ClosestLocation.VendorID = vl2.VendorID and ClosestLocation.Distance = vl2.Distance  
      WHERE vl1.VendorLocationID = vl2.VendorLocationID AND  
            vl1.Distance = vl2.Distance  
      )  

  
/* For the vendor locations within the Search Radius determine vendors that can provide the desired service */  
INSERT INTO #IspDetail   
SELECT     
            v.ID VendorID    
            ,vl.ID VendorLocationID   
            ,tvl.VendorLocationVirtualID   
            ,CASE WHEN tvl.VendorLocationVirtualID IS NOT NULL THEN tvl.Latitude ELSE vl.Latitude END Latitude    
            ,CASE WHEN tvl.VendorLocationVirtualID IS NOT NULL THEN tvl.Longitude ELSE vl.Longitude END Longitude    
            ,v.Name + CASE WHEN PreferredVendors.VendorID IS NOT NULL THEN ' (P)' ELSE '' END VendorName
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet' ELSE '' END AS [Source]  
			,CAST(CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted'     
            ELSE NULL    
            END AS nvarchar(50)) AS ContractStatus 
            ---- Have to check the if the selected product is a contract rate since the vendor can be contracted but not have a rate set for the service (bad data)    
            --,CAST(CASE WHEN VendorLocationRates.Price IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL THEN 'Contracted'     
            --ELSE NULL    
            --END AS nvarchar(50)) AS ContractStatus    
            --,ph.PhoneNumber DispatchPhoneNumber   
		   ,(SELECT Top 1 PhoneNumber  
			FROM dbo.[PhoneEntity]   
			WHERE RecordID = vl.ID   
			AND EntityID = @VendorLocationEntityID  
			AND PhoneTypeID = @DispatchPhoneTypeID  
			ORDER BY ID DESC   
			 ) AS DispatchPhoneNumber
			 ,(SELECT Top 1 PhoneNumber  
			FROM dbo.[PhoneEntity]   
			WHERE RecordID = vl.ID   
			AND EntityID = @VendorLocationEntityID  
			AND PhoneTypeID = @AltDispatchPhoneTypeID  
			ORDER BY ID DESC   
			 ) AS AlternateDispatchPhoneNumber  -- TFS : 105
            ,v.AdministrativeRating   
            -- Ignore time while comparing dates here  
            ,CASE WHEN v.InsuranceExpirationDate >= DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0) THEN 'Insured'   
            ELSE 'Not Insured' END InsuranceStatus    
            ,vl.[IsOpen24Hours]    
            ,vl.BusinessHours    
            ,vl.DispatchNote AS Comment    
            ,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles    
            ,@ServiceMiles as ServiceMiles    
            ,ROUND(tvl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' OR @ProductCategoryID <> 1 THEN @ServiceLocation ELSE @DestinationLocation END)/1609.344,1) ReturnMiles    
            ,vlp.ProductID    
            ,p.Name ProductName    
            ,vlp.Rating ProductRating    
            ,prt.RateTypeID     
            ,COALESCE(VendorLocationRates.Price, DefaultVendorRates.Price, MarketRates.Price, 0) AS RatePrice  
            ,COALESCE(VendorLocationRates.Quantity, DefaultVendorRates.Quantity, MarketRates.Quantity, 0) AS RateQuantity  
            --,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Price    
            --            WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Price    
            --            ELSE MarketRates.Price     
            --END AS RatePrice    
            --,CASE WHEN VendorLocationRates.Price IS NOT NULL THEN VendorLocationRates.Quantity    
            --            WHEN DefaultVendorRates.Price IS NOT NULL THEN DefaultVendorRates.Quantity    
            --            ELSE MarketRates.Quantity     
            --END AS RateQuantity    
            , rt.Name RateTypeName    
            , rt.UnitOfMeasure RateUnitOfMeasure    
            , rt.UnitOfMeasureSource RateUnitOfMeasureSource    
            ,CASE WHEN p.ID = ISNULL(@PrimaryProductID,0) THEN 1   
                        ELSE 0   
            END IsProductMatch
            ,Case WHEN PreferredVendors.VendorID IS NOT NULL THEN 1 ELSE 0 END IsPreferred
FROM  #tmpVendorLocation tvl  
JOIN  dbo.VendorLocation vl on tvl.VendorLocationID = vl.ID   
JOIN  dbo.Vendor v  ON vl.VendorID = v.ID    
JOIN  dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1  
JOIN  dbo.Product p ON p.ID = vlp.ProductID    
JOIN  dbo.ProductRateType prt ON prt.ProductID = p.ID AND   prt.IsOptional = 0   
JOIN  dbo.RateType rt ON prt.RateTypeID = rt.ID    
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON
	v.ID = ContractedVendors.VendorID    
LEFT OUTER JOIN dbo.fnGetPreferredVendorsByProduct() PreferredVendors ON
	v.ID = PreferredVendors.VendorID AND p.ID = PreferredVendors.ProductID
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRates ON   
      v.ID = VendorLocationRates.VendorID AND   
      p.ID = VendorLocationRates.ProductID AND   
      prt.RateTypeID = VendorLocationRates.RateTypeID AND  
      VendorLocationRates.VendorLocationID = vl.ID   
LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() DefaultVendorRates ON   
      v.ID = DefaultVendorRates.VendorID AND   
      p.ID = DefaultVendorRates.ProductID AND   
      prt.RateTypeID = DefaultVendorRates.RateTypeID AND  
      DeFaultVendorRates.VendorLocationID IS NULL  
LEFT OUTER JOIN #MarketRates MarketRates ON p.ID = MarketRates.ProductID And MarketRates.RateTypeID = prt.RateTypeID 
	--TP: Added condition to prevent backfill of market rates for missing contracted vendor rates 
	AND NOT EXISTS (
		Select * 
		From [dbo].[fnGetCurrentProductRatesByVendorLocation]() r2 
		Where r2.VendorID = v.ID 
			and r2.ProductID = p.ID 
			and r2.RateName IN ('Base','Hourly')
			and r2.Price <> 0) 
    
WHERE   
(VendorLocationRates.RateTypeID IS NOT NULL OR DefaultVendorRates.Price IS NOT NULL OR MarketRates.Price IS NOT NULL)    
AND           
      (  
            (   vlp.ProductID = @PrimaryProductID  
                  AND  
                -- Additional condition to include tire stores if tire service and tire delivery selected  
                  (   
                    @IsTireDelivery = 0  
                    OR  
                    --If Tire delivery then Tire Repair must also have Tire Store Attributes  
                    (@IsTireDelivery = 1    
                              AND EXISTS (  
                              SELECT * FROM VendorLocationProduct vlp1   
                              JOIN Product p1 ON vlp1.ProductID = p1.ID and p1.ProductCategoryID = 2 and p1.ProductSubTypeID = 10  
                              WHERE vlp1.VendorLocationID = vl.ID)  
                    )   
                  )   
            --Additional condition for Mobile Mechanic service  
                  OR  
        (@ProductCategoryID = 8 AND vlp.ProductID IN (SELECT ID FROM Product WHERE ProductCategoryID = 8))  
  
            )  
      AND   
            -- Code to require towing service for possible tow  
            ( @SecondaryProductID IS NULL   
            OR EXISTS (SELECT * FROM VendorLocationProduct vlp2 WHERE vlp2.VendorLocationID = vl.ID and vlp2.ProductID = @SecondaryProductID)  
            )  
      )  
  
  
-- Remove duplicate results for vendorlocations that are caused by multiple product matches   
-- TP: 4/21 Removed previous record deletion logic that was no longer needed and added this logic to fix issue with mobile mechanic vendors appearing multiple times  
DELETE ISPDetail1  
FROM #IspDetail ISPDetail1   
WHERE NOT EXISTS (  
      SELECT *  
      FROM   
            (    
            Select VendorLocationID, Min(ProductID) MinProductID  
            FROM #IspDetail  
            Group by VendorLocationID   
            ) ISPDetail2   
      WHERE ISPDetail1.VendorLocationID = ISPDetail2.VendorLocationID   
            AND ISPDetail1.ProductID  = ISPDetail2.MinProductID  
      )   
  
    
 -- Select list of 'Do Not Use' vendors within the 'Do Not Use' search radius of the service location   
INSERT INTO #ISPDoNotUse   
SELECT      v.ID VendorID    
            ,vl.ID VendorLocationID   
            ,NULL   
            ,vl.Latitude    
            ,vl.Longitude    
            ,v.Name VendorName    
            ,v.VendorNumber    
            ,CASE WHEN v.VendorNumber IS NULL THEN 'Internet'   
                        ELSE 'Database'   
            END AS [Source]    
            ,'Not Contracted' AS ContractStatus    
            ,addr.Line1 Address1    
            ,addr.Line2 Address2    
            ,addr.City    
            ,addr.StateProvince    
            ,addr.PostalCode    
            ,addr.CountryCode    
            ,ph.PhoneNumber DispatchPhoneNumber 
			,aph.PhoneNumber AlternateDispatchPhoneNumber -- TFS : 105   
            ,'' AS FaxPhoneNumber    
            ,'' AS OfficePhoneNumber   
            ,'' AS CellPhoneNumber  -- CR : 1226  
            ,0 AS AdministrativeRating    
            ,'' AS InsuranceStatus    
            ,'' AS BusinessHours    
            ,'' AS PaymentTypes  
            ,'' AS Comment    
            ,0 AS ProductID    
            ,'' AS ProductName    
            ,NULL AS ProductRating    
            ,ROUND(vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)/1609.344,1) EnrouteMiles    
            ,NULL AS EnrouteTimeMinutes  
            ,NULL AS ServiceMiles    
            ,NULL AS ServiceTimeMinutes  
            ,NULL AS ReturnMiles    
            ,NULL AS ReturnTimeMinutes  
            ,NULL AS EstimatedHours    
            ,NULL AS BaseRate  
            ,NULL AS HourlyRate  
            ,NULL AS EnrouteRate  
            ,NULL AS EnrouteFreeMiles  
            ,NULL AS ServiceRate  
            ,NULL AS ServiceFreeMiles  
            ,NULL AS EstimatedPrice    
            ,-99999 AS WiseScore    
            ,'DoNotUse' AS CallStatus    
            ,'' AS RejectReason    
            ,'' AS RejectComment    
            ,0 AS IsPossibleCallback    
FROM  dbo.VendorLocation vl     
JOIN  dbo.Vendor v ON vl.VendorID = v.ID     
JOIN  dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = vl.ID AND addr.AddressTypeID = @BusinessAddressTypeID    
-- TP - Eliminate join duplication due to multiple dispatch numbers  
JOIN (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @DispatchPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) ph ON ph.RecordID = vl.ID  
 LEFT JOIN (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @AltDispatchPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) aph ON aph.RecordID = vl.ID     
WHERE v.IsActive = 'TRUE'    
AND         v.VendorStatusID = @DoNotUseVendorStatusID  
AND         vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END) <= @DNUSearchRadiusMiles * 1609.344    
AND         @IncludeDoNotUse = 'TRUE'    
ORDER BY vl.GeographyLocation.STDistance(CASE WHEN ISNULL(@SearchFrom, '') = 'Destination' THEN @DestinationLocation ELSE @ServiceLocation END)    
  
-- DEBUG : SELECT * FROM #IspDetail  
  
-- Create ISP Selection data set from ISP Details, adding additional data items and related contact logs   
INSERT INTO @ISPSelection   
SELECT      ISP.VendorID    
            ,ISP.VendorLocationID    
            ,ISP.VendorLocationVirtualID  
            ,ISP.Latitude    
            ,ISP.Longitude    
            ,ISP.VendorName + CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN ' (virtual)' ELSE '' END AS VendorName  
            ,ISP.VendorNumber    
            ,ISP.[Source]    
            ,ISNULL(MAX(ISP.ContractStatus), 'Not Contracted') ContractStatus    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationAddress ELSE addr.Line1 END Address1    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN NULL ELSE addr.Line2 END Address2    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationCity ELSE addr.City END City    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationStateProvince ELSE addr.StateProvince END StateProvince    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationPostalCode ELSE addr.PostalCode END PostalCode    
            ,CASE WHEN ISP.VendorLocationVirtualID IS NOT NULL THEN vlv.LocationCountryCode ELSE addr.CountryCode END CountryCode    
            ,ISP.DispatchPhoneNumber
			,ISP.AlternateDispatchPhoneNumber -- TFS: 105   
            ,FaxPh.PhoneNumber FaxPhoneNumber  
            ,ph.PhoneNumber OfficePhoneNumber  
            ,cph.PhoneNumber CellPhoneNumber --  CR : 1226  
            ,ISP.AdministrativeRating    
            ,ISP.InsuranceStatus    
            ,CASE WHEN ISP.[IsOpen24Hours] = 1 THEN '24/7'   
            ELSE ISNULL(ISP.BusinessHours,'') END AS BusinessHours    
            ,PaymentTypes.List AS PaymentTypes  
            ,ISP.Comment    
            ,ISP.ProductID    
            ,ISP.ProductName    
            ,ISP.ProductRating    
            ,ISP.EnrouteMiles    
            ,(ISP.EnrouteMiles/40)*60 AS EnrouteTimeMinutes  
            ,ISP.ServiceMiles    
            ,(ISP.ServiceMiles/40)*60 AS ServiceTimeMinutes  
            ,ISP.ReturnMiles    
            ,(ISP.ReturnMiles/40)*60 AS ReturnTimeMinutes  
            ,MAX(1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2)) AS EstimatedHours    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Base' THEN ISP.RatePrice ELSE 0 END) AS BaseRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Hourly' THEN ISP.RatePrice ELSE 0 END) AS HourlyRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Enroute' THEN ISP.RatePrice ELSE 0 END) AS EnrouteRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'EnrouteFree' THEN ISP.RateQuantity ELSE 0 END) AS EnrouteFreeMiles    
            ,SUM(CASE WHEN ISP.RateTypeName = 'Service' THEN ISP.RatePrice ELSE 0 END) AS ServiceRate    
            ,SUM(CASE WHEN ISP.RateTypeName = 'ServiceFree' THEN ISP.RateQuantity ELSE 0 END) AS ServiceFreeMiles    
            ,ROUND(SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END)
    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END),2) EstimatedPrice    
            ,ROUND((AdministrativeRating*@AdminWeight)+(ProductRating*@PerformWeight)-    
                        (SUM(CASE     
                                    WHEN ISP.RateUnitOfMeasure = 'Each' THEN ISP.RatePrice     
                                    WHEN ISP.RateUnitOfMeasure = 'Hour' THEN ISP.RatePrice * (1.5 + ROUND((ISP.EnrouteMiles + ISP.ServiceMiles + ISP.ReturnMiles)/40,2))    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity = 0 THEN ISP.RatePrice * ISP.EnrouteMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity = 0 THEN ISP.RatePrice * ISP.ServiceMiles    
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Enroute' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.EnrouteMiles THEN ISP.EnrouteMiles ELSE ISP.RateQuantity END) 
   
                                    WHEN ISP.RateUnitOfMeasure = 'Mile' and ISP.RateUnitOfMeasureSource = 'Service' and RateQuantity <> 0 THEN ISP.RatePrice * (CASE WHEN ISP.RateQuantity > ISP.ServiceMiles THEN ISP.ServiceMiles ELSE ISP.RateQuantity END) 
   
                                    ELSE 0   
                              END) * @CostWeight),2) as WiseScore    
            ,CASE WHEN ContactLogAction.VendorLocationID IS NULL THEN 'NotCalled'    
                        WHEN ISNULL(ContactLogAction.Name,'') = '' THEN 'Called'    
                        WHEN ISNULL(ContactLogAction.Name,'') = 'Accepted' THEN 'Accepted'    
                        ELSE 'Rejected'   
            END AS CallStatus    
            ,ContactLogAction.[Description] RejectReason    
            ,ContactLogAction.[Comments] RejectComment    
            ,ISNULL(ContactLogAction.IsPossibleCallback,0) AS IsPossibleCallback    
            ,MAX(ISP.IsPreferred) IsPreferred
FROM  #IspDetail ISP    
LEFT OUTER JOIN  dbo.[VendorLocationVirtual] vlv ON vlv.ID = ISP.VendorLocationVirtualID  
LEFT OUTER JOIN  dbo.[AddressEntity] addr ON addr.EntityID = @VendorLocationEntityID AND addr.RecordID = ISP.VendorLocationID AND addr.AddressTypeID = @BusinessAddressTypeID    
-- TP - Eliminate join duplication due to multiple Fax numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @FaxPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) Faxph ON Faxph.RecordID = ISP.VendorLocationID     
-- TP - Eliminate join duplication due to multiple Office numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @OfficePhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) ph ON ph.RecordID = ISP.VendorLocationID     
-- TP - Eliminate join duplication due to multiple Cell numbers  
LEFT OUTER JOIN  (  
 SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
 FROM dbo.[PhoneEntity]   
 WHERE EntityID = @VendorLocationEntityID  
 AND PhoneTypeID = @CellPhoneTypeID  
 GROUP BY EntityID, RecordID  
 ) cph ON cph.RecordID = ISP.VendorLocationID     
-- Get last ContactLog result for the current sevice request for the ISP  
LEFT OUTER JOIN (    
                              SELECT      LastISPContactLog.VendorLocationID    
                                          ,LastContactLogAction.Name    
                                          ,LastContactLogAction.[Description]    
                                          ,cl.Comments    
                                          ,ISNULL(cl.IsPossibleCallback,0) IsPossibleCallback    
                              FROM  dbo.ContactLog cl    
                              JOIN (  
                                          SELECT      ISPcll.RecordID VendorLocationID, MAX(cl.ID) ID   
                                          FROM  dbo.ContactLog cl    
                                          JOIN  dbo.ContactLogLink SRcll ON SRcll.ContactLogID = cl.ID AND SRcll.EntityID = @ServiceRequestEntityID AND SRcll.RecordID = @ServiceRequestID     
                                          JOIN dbo.ContactLogLink ISPcll ON ISPcll.ContactLogID = cl.ID AND ISPcll.EntityID = @VendorLocationEntityID    
                                          JOIN dbo.ContactLogReason clr ON clr.ContactLogID = cl.ID    
                                          JOIN dbo.ContactReason cr ON cr.ID = clr.ContactReasonID    
                                          WHERE cr.Name = 'ISP selection'    
                                          GROUP BY ISPcll.RecordID  
                                    ) LastISPContactLog ON LastISPContactLog.ID = cl.ID  
                              LEFT OUTER JOIN (    
                                          SELECT      cla.ContactLogID  
                                                      ,ca.Name  
                                                      ,ca.[Description]  
                                                      ,cla.Comments    
                                          FROM  dbo.ContactLogAction cla    
                                          JOIN  dbo.ContactAction ca ON ca.ID = cla.ContactActionID    
                                          JOIN  (    
                                                            SELECT      cla1.ContactLogID, MAX(cla1.ID) ID    
                                                            FROM      dbo.ContactLogAction cla1    
                                                            GROUP BY cla1.ContactLogID    
                                                      ) MaxContactLogAction ON MaxContactLogAction.ContactLogID = cla.ContactLogID AND MaxContactLogAction.ID = cla.ID    
                                    ) LastContactLogAction ON LastContactLogAction.ContactLogID = cl.ID   
                        ) ContactLogAction ON ContactLogAction.VendorLocationID = ISP.VendorLocationID    
-- Get Payment Types accepted by this vendor                        
LEFT OUTER JOIN (    
      SELECT  
         pt1.VendorLocationID,  
         List = stuff((SELECT ( ', ' + [Description] )  
                    FROM (Select vlpt.VendorLocationID, pt.Name, pt.Sequence, pt.[Description]   
                              From VendorLocationPaymentType vlpt  
                              Join PaymentType pt on vlpt.PaymentTypeID = pt.ID  
                              ) pt2  
                    WHERE pt1.VendorLocationID = pt2.VendorLocationID  
                    ORDER BY VendorLocationID, pt2.Sequence  
                        FOR XML PATH( '' )  
                  ), 1, 1, '' )  
                  FROM   
                        (Select vlpt.VendorLocationID, pt.Name  
                        From VendorLocationPaymentType vlpt  
                        Join #IspDetail ISP on ISP.VendorLocationID = vlpt.VendorLocationID  
                        Join PaymentType pt on vlpt.PaymentTypeID = pt.ID  
                        ) pt1  
      GROUP BY pt1.VendorLocationID  
      ) PaymentTypes ON PaymentTypes.VendorLocationID = ISP.VendorLocationID  
GROUP BY    
                  ISP.VendorID    
                  ,ISP.VendorLocationID    
                  ,ISP.VendorLocationVirtualID  
                  ,ISP.Latitude    
                  ,ISP.Longitude    
                  ,ISP.VendorName    
                  ,ISP.VendorNumber    
                  ,ISP.[Source]    
                  ,addr.Line1     
                  ,addr.Line2     
                  ,addr.City    
                  ,addr.StateProvince    
                  ,addr.PostalCode    
                  ,addr.CountryCode    
                  ,vlv.LocationAddress  
                  ,vlv.LocationCity    
                  ,vlv.LocationStateProvince    
                  ,vlv.LocationPostalCode    
                  ,vlv.LocationCountryCode    
                  ,ISP.DispatchPhoneNumber 
				  ,ISP.AlternateDispatchPhoneNumber   -- TFS: 105
                  ,Faxph.PhoneNumber  
                  ,ph.PhoneNumber   
                  ,cph.PhoneNumber   
                  ,ISP.AdministrativeRating    
                  ,ISP.InsuranceStatus    
                  ,ISP.[IsOpen24Hours]    
                  ,ISP.BusinessHours    
                  ,ISP.Comment    
                  ,ISP.ProductID    
                  ,ISP.ProductName    
                  ,ISP.ProductRating    
                  ,ISP.EnrouteMiles    
                  ,ISP.ServiceMiles    
                  ,ISP.ReturnMiles    
                  ,ISP.IsProductMatch    
                  ,ContactLogAction.VendorLocationID    
                  ,ContactLogAction.[Description]     
                  ,ContactLogAction.Comments     
                  ,ISNULL(ContactLogAction.Name ,'')  
                  ,ContactLogAction.IsPossibleCallback    
                  ,PaymentTypes.List  
ORDER BY   
                  WiseScore DESC  
                  ,EstimatedPrice  
                  ,EnrouteMiles  
                  ,ProductRating DESC    
   
 -- Log ISP SELECTION Results (first resultset).  
INSERT INTO ISPSelectionLog  
            ([VendorID]  
           ,[VendorLocationID]  
           ,[VendorLocationVirtualID]  
           ,[SelectionOrder]  
           ,[ServiceRadiusMiles]  
           ,[Latitude]  
           ,[Longitude]  
           ,[VendorName]  
           ,[VendorNumber]  
           ,[Source]  
           ,[ContractStatus]  
           ,[Address1]  
           ,[Address2]  
           ,[City]  
           ,[StateProvince]  
           ,[PostalCode]  
           ,[CountryCode]  
           ,[DispatchPhoneNumber]
		   ,[AlternateDispatchPhoneNumber] -- TFS: 105  
           ,[FaxPhoneNumber]  
           ,[OfficePhoneNumber]  
           ,[CellPhoneNumber]  
           ,[AdministrativeRating]  
           ,[InsuranceStatus]  
           ,[BusinessHours]  
           ,[PaymentTypes]  
           ,[Comment]  
           ,[ProductID]  
           ,[ProductName]  
           ,[ProductRating]  
           ,[EnrouteMiles]  
           ,[EnrouteTimeMinutes]  
           ,[ServiceMiles]  
           ,[ServiceTimeMinutes]  
           ,[ReturnMiles]  
           ,[ReturnTimeMinutes]  
           ,[EstimatedHours]  
           ,[BaseRate]  
           ,[HourlyRate]  
           ,[EnrouteRate]  
           ,[EnrouteFreeMiles]  
           ,[ServiceRate]  
           ,[ServiceFreeMiles]  
           ,[EstimatedPrice]  
           ,[WiseScore]  
           ,[CallStatus]  
           ,[RejectReason]  
           ,[RejectComment]  
           ,[IsPossibleCallback]  
           ,[ProductSearchRadiusMiles]  
           ,[IsInProductSearchRadius]  
           ,[ServiceRequestID]  
           ,[LogTime]  
           ,[Resultset])  
SELECT   
            VendorID    
            ,VendorLocationID    
            ,VendorLocationVirtualID  
            ,row_number() OVER(ORDER BY WiseScore DESC  
                  ,EstimatedPrice  
                  ,EnrouteMiles  
                  ,ProductRating DESC) AS SelectionOrder  
            ,@ProductSearchRadiusMiles  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber   
			,AlternateDispatchPhoneNumber -- TFS: 105 
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
			,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,NULL AS IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION'    
 FROM @ISPSelection   
 WHERE @LogISPSelection = 1  
  
   
-- Combine ISP Selection and ISP Do Not use results     
-- Collect products in a separate query   
INSERT INTO @ISPSelectionFinalResults    
SELECT      TOP 50    
            I.VendorID    
            ,I.VendorLocationID    
            ,VendorLocationVirtualID  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber  
			,AlternateDispatchPhoneNumber -- TFS: 105  
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,'' AS [AllServices]  
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,CASE WHEN (I.EnrouteMiles <= @ProductSearchRadiusMiles) OR Top3Contracted.VendorLocationID IS NOT NULL THEN 1 ELSE 0 END AS IsInProductSearchRadius   
            ,IsPreferred
FROM  @ISPSelection I  
-- Identify top 3 contracted vendors  
LEFT OUTER JOIN (  
      SELECT TOP 3 VendorLocationID  
      FROM @ISPSelection  
      WHERE ContractStatus = 'Contracted'  
      ORDER BY EnrouteMiles ASC, WiseScore DESC  
      ) Top3Contracted ON Top3Contracted.VendorLocationID = I.VendorLocationID  
-- Apply product availability filtering (@ProductIDs list)  
WHERE EXISTS      (  
                              SELECT      *  
                              FROM  VendorLocation vl  
                              JOIN  VendorLocationProduct vlp   
                              ON          vlp.VendorLocationID = vl.ID  
                              JOIN  Product p on p.ID = vlp.ProductID   
                              WHERE vl.ID = I.VendorLocationID  
                              AND         (     ISNULL(@productIDs,'') = ''   
                                                OR    
                                                p.ID IN (SELECT item from [dbo].[fnSplitString](@productIDs,','))  
                                          )  
                        )  
  
ORDER BY IsPreferred DESC, WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
  
/* Add 'Do Not Use' vendors to the results (if selected above) */  
INSERT INTO @ISPSelectionFinalResults  
SELECT      TOP 100    
            I.VendorID    
            ,VendorLocationID    
            ,VendorLocationVirtualID  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber  
			,AlternateDispatchPhoneNumber -- TFS: 105  
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceMiles  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            , '' AS [AllServices]   
            ,@ProductSearchRadiusMiles AS ProductSearchRadiusMiles  
            ,0 AS IsInProductSearchRadius  
            ,0 AS IsPreferred
FROM  #ISPDoNotUse I  
ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
   
-- Get all the products for the vendors collected in the above query.  
;WITH wVLP  
AS  
(  
      SELECT      vl.VendorID,  
                  vl.ID,   
                  [dbo].[fnConcatenate](p.Name) AS AllServices  
      FROM  VendorLocation vl  
      JOIN  VendorLocationProduct vlp on vlp.VendorLocationID = vl.ID  
      JOIN  Product p on p.ID = vlp.ProductID  
      JOIN  @ISPSelectionFinalResults ISP ON vl.ID = ISP.VendorLocationID AND vl.VendorID = ISP.VendorID  
      WHERE vlp.IsActive = 1  
      GROUP BY vl.VendorID,vl.ID  
)  
  
 -- Include 'All Services' provided by the selected ISPs in the results  
UPDATE      @ISPSelectionFinalResults  
SET         AllServices = W.AllServices  
FROM  wVLP W,  
            @ISPSelectionFinalResults ISP  
WHERE W.VendorID = ISP.VendorID  
AND         W.ID = VendorLocationID  
  
-- Remove Black Listed vendors from the result for this member  
DELETE FROM @ISPSelectionFinalResults  
WHERE VendorID IN (  
                                    SELECT VendorID  
                                    FROM MembershipBlackListVendor  
                                    WHERE MembershipID = @MembershipID  
                              )  
  
/* Insert reults into ISP Selection log */  
INSERT INTO ISPSelectionLog  
            ([VendorID]  
           ,[VendorLocationID]  
           ,[VendorLocationVirtualID]  
           ,[SelectionOrder]  
           ,[ServiceRadiusMiles]  
           ,[Latitude]  
           ,[Longitude]  
           ,[VendorName]  
           ,[VendorNumber]  
           ,[Source]  
           ,[ContractStatus]  
           ,[Address1]  
           ,[Address2]  
           ,[City]  
           ,[StateProvince]  
           ,[PostalCode]  
           ,[CountryCode]  
           ,[DispatchPhoneNumber]
		   ,[AlternateDispatchPhoneNumber] -- TFS: 105  
           ,[FaxPhoneNumber]  
           ,[OfficePhoneNumber]  
           ,[CellPhoneNumber]  
           ,[AdministrativeRating]  
           ,[InsuranceStatus]  
           ,[BusinessHours]  
           ,[PaymentTypes]  
           ,[Comment]  
           ,[ProductID]  
           ,[ProductName]  
           ,[ProductRating]  
           ,[EnrouteMiles]  
           ,[EnrouteTimeMinutes]  
           ,[ServiceMiles]  
           ,[ServiceTimeMinutes]  
           ,[ReturnMiles]  
           ,[ReturnTimeMinutes]  
           ,[EstimatedHours]  
           ,[BaseRate]  
           ,[HourlyRate]  
           ,[EnrouteRate]  
           ,[EnrouteFreeMiles]  
           ,[ServiceRate]  
           ,[ServiceFreeMiles]  
           ,[EstimatedPrice]  
           ,[WiseScore]  
           ,[CallStatus]  
           ,[RejectReason]  
           ,[RejectComment]  
           ,[IsPossibleCallback]  
           ,[ProductSearchRadiusMiles]  
           ,[IsInProductSearchRadius]  
           ,[ServiceRequestID]  
           ,[LogTime]  
           ,[Resultset])  
SELECT ISP.VendorID    
            ,ISP.VendorLocationID   
            ,ISP.VendorLocationVirtualID   
            ,row_number() OVER(ORDER BY   
                  ISP.IsInProductSearchRadius DESC,  
                  ISP.WiseScore DESC,   
    ISP.EstimatedPrice,   
                  ISP.EnrouteMiles,   
                  ISP.ProductRating DESC) AS SelectionOrder  
            ,@ProductSearchRadiusMiles  
            ,Latitude    
            ,Longitude    
            ,VendorName    
            ,VendorNumber    
            ,[Source]    
            ,ContractStatus    
            ,Address1    
            ,Address2    
            ,City    
            ,StateProvince    
            ,PostalCode    
            ,CountryCode    
            ,DispatchPhoneNumber
			,AlternateDispatchPhoneNumber -- TFS: 105    
            ,FaxPhoneNumber  
            ,OfficePhoneNumber    
            ,CellPhoneNumber  
            ,AdministrativeRating    
            ,InsuranceStatus    
            ,BusinessHours    
            ,PaymentTypes  
            ,Comment    
            ,ProductID    
            ,ProductName    
            ,ProductRating    
            ,EnrouteMiles    
            ,EnrouteTimeMinutes  
            ,ServiceMiles  
            ,ServiceTimeMinutes  
            ,ReturnMiles    
            ,ReturnTimeMinutes  
            ,EstimatedHours    
            ,BaseRate  
            ,HourlyRate  
            ,EnrouteRate  
            ,EnrouteFreeMiles  
            ,ServiceRate  
            ,ServiceFreeMiles  
            ,EstimatedPrice    
            ,WiseScore    
            ,CallStatus    
            ,RejectReason    
            ,RejectComment    
            ,IsPossibleCallback  
            ,ProductSearchRadiusMiles  
            ,IsInProductSearchRadius  
            ,@ServiceRequestID  
            ,@now  
            ,'ISPSELECTION_FINAL'    
FROM @ISPSelectionFinalResults ISP  
WHERE @LogISPSelectionFinal = 1  
ORDER BY   
	  ISP.IsPreferred DESC,   
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
/* Return results */  
SELECT      ISP.*   
FROM  @ISPSelectionFinalResults ISP  
ORDER BY      
	  ISP.IsPreferred DESC,
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
DROP TABLE #IspDoNotUse  
DROP TABLE #IspDetail  
DROP TABLE #tmpVendorLocation  
DROP TABLE #MarketRates  
  
END  

GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_PO_Issue_Hagerty_EventMail_Tag_Get] 310520
 CREATE PROCEDURE [dbo].[dms_PO_Issue_Hagerty_EventMail_Tag_Get]( 
  @POID Int = NULL  
 ) 
 AS 
 BEGIN 

	DECLARE @Result TABLE(ColumnName NVARCHAR(MAX),
						  ColumnValue NVARCHAR(MAX)) 

	DECLARE @XmlString AS XML

	SET @XmlString = (
	SELECT m.ID AS MemberId
	
	, ISNULL(ms.MembershipNumber,'') AS MemberNumber
	
	, ISNULL(m.FirstName,'') + ' ' + ISNULL(m.LastName,'') AS MemberName

	, ISNULL(c.VehicleYear + ' ' + CASE WHEN c.VehicleMake = 'Other' THEN c.VehicleMakeOther ELSE c.VehicleMake END + ' ' + CASE WHEN c.VehicleModel = 'Other' THEN c.VehicleModelOther ELSE c.VehicleModel END,' ') AS MemberVehicleDesc -- coalesce 

	, ISNULL(c.ContactPhoneNumber,' ') AS MemberCallback 

	, sr.ID AS SRNumber

	, CONVERT (VARCHAR(20),sr.CreateDate,100) + ' CST' AS SRCallDateTime 

	, ISNULL(pc.Name,'  ') AS SRType

	, ISNULL(sr.ServiceLocationAddress,' ') AS SRLocation

	, ISNULL(sr.DestinationAddress,' ') AS SRDestination

	, ISNULL(po.PurchaseOrderNumber,' ') AS PONumber

	, CONVERT(VARCHAR(20),po.IssueDate,100) + ' CST' AS POIssueDateTime

	, ISNULL(v.Name,' ') AS POVendor

	, CONVERT(VARCHAR(20),ISNULL(po.ETAMinutes,' ')) + ' minutes' AS SRETA
	
	, ISNULL(m.ClientMemberType, ' ') AS ClientMemberType
	 
	, ISNULL(cl.Name,' ') AS Client
	
	, '888-310-8020' AS DispatchPhone
	
	, ISNULL(p.Name,' ')  AS ProgramName
	
	,ISNULL(p.Code,' ') AS ProgramCode
	
	FROM PurchaseOrder po (NOLOCK)

	JOIN ServiceRequest sr (NOLOCK) ON sr.ID = po.ServiceRequestID

	LEFT JOIN ProductCategory pc (NOLOCK) ON pc.ID = sr.ProductCategoryID

	JOIN [Case] c (NOLOCK) ON c.ID = sr.CaseID

	JOIN Member m (NOLOCK) ON m.ID = c.MemberID

	JOIN Membership ms (NOLOCK) ON ms.ID = m.MembershipID

	JOIN VendorLocation vl (NOLOCK) ON vl.ID = po.VendorLocationID

	JOIN Vendor v (NOLOCK) ON v.ID = vl.VendorID
	
	JOIN Program p (NOLOCK) ON c.ProgramID = p.ID
	
	JOIN Client cl (NOLOCK) ON cl.ID = p.ClientID
	WHERE po.ID = @POID FOR XML AUTO)

	INSERT INTO @Result(ColumnName,ColumnValue)
    SELECT CAST(x.v.query('local-name(.)') AS NVARCHAR(MAX)) As AttributeName,
			    x.v.value('.','NVARCHAR(MAX)') AttributeValue
    FROM @XmlString.nodes('//@*') x(v)
    ORDER BY AttributeName

	SELECT * FROM @Result

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_programdataitems_for_program_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_programdataitems_for_program_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_programdataitems_for_program_get] 3,'RepairContactLog'
 
CREATE PROCEDURE [dbo].[dms_programdataitems_for_program_get]( 
	@ProgramID int = NULL,   
	@screenName NVARCHAR(100) = NULL
) 
AS
BEGIN
	DECLARE @Questions TABLE(
	  QuestionID int, 
	  QuestionText nvarchar(4000),
	  ControlType nvarchar(50),
	  DataType nvarchar(50),
	  IsRequired bit,
	  MaxLength INT,
	  SubQuestionID INT,
	  RelatedAnswer NVARCHAR(MAX),
	  Sequence int
	 ) 

	INSERT INTO @Questions
	SELECT	   
		   PDI.ID,
		   PDI.Label,
		   CT.Name,
		   DT.Name,
		   PDI.IsRequired,
		   PDI.MaxLength,
		   PDL.ProgramDataItemID,              
		   PDV.Value,
		   PDI.Sequence
	FROM	ProgramDataItem PDI 
	LEFT JOIN DataType DT ON DT.ID = PDI.DataTypeID
	LEFT JOIN ControlType CT ON CT.ID = PDI.ControlTypeID
	LEFT JOIN ProgramDataItemLink PDL ON PDL.ParentProgramDataItemID = PDI.ID
	LEFT JOIN ProgramDataItemValue PDV ON PDL.ProgramDataItemValueID = PDV.ID 
	WHERE  PDI.ScreenName = @screenName
	AND		PDI.ProgramID = @ProgramID
	ORDER BY PDI.Sequence

	SELECT * FROM @Questions

END
GO
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_programdataitem_answers_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_programdataitem_answers_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_programdataitem_answers_get] 81,'RepairContactLog'
 
CREATE PROCEDURE [dbo].[dms_programdataitem_answers_get]( 
	@ProgramID int = NULL,   
	@screenName NVARCHAR(100) = NULL
) 
AS
BEGIN
	
	SELECT  PDI.ID As ProgramDataItemID,
			PDIV.ID As ProgramDataItemValueID,
			PDIV.Value,
			PDIV.Sequence
	FROM	ProgramDataItemValue PDIV
	JOIN	ProgramDataItem PDI ON PDIV.ProgramDataItemID = PDI.ID
	WHERE	PDI.ScreenName = @screenName
	AND		PDI.ProgramID = @ProgramID
	ORDER BY PDIV.Sequence

END
GO
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Rate_Schedules_For_Report_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Rate_Schedules_For_Report_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_Rate_Schedules_For_Report_Get] 2195
 CREATE PROCEDURE [dbo].[dms_Rate_Schedules_For_Report_Get](
 @rateScheduleID INT
 )
 AS
 BEGIN
 
	SELECT 
                  @RateScheduleID AS RateScheduleID
                  ,p.ID AS ProductID
                  ,CASE 
                        WHEN p.Name = 'Mobile Mechanic' THEN 'Auto'
                        WHEN p.Name = 'Locksmith' THEN p.Name + ' *** Certified Only ***'
                        WHEN CHARINDEX(' - LD', p.Name) > 0 THEN REPLACE(p.Name, ' - LD', '')
                        WHEN CHARINDEX(' - MD', p.Name) > 0 THEN REPLACE(p.Name, ' - MD', '')
                        WHEN CHARINDEX(' - HD', p.Name) > 0 THEN REPLACE(p.Name, ' - HD', '')
                        WHEN CHARINDEX('Mobile Mechanic - ', p.Name) > 0 THEN REPLACE(p.Name, 'Mobile Mechanic - ', '')
                        ELSE p.Name 
                        END AS ProductName
                  ,CASE COALESCE(vc.Name, pc.Name)
                        WHEN 'LightDuty' THEN 1
                        WHEN 'MediumDuty' THEN 2
                        WHEN 'HeavyDuty' THEN 3
                        WHEN 'Lockout' THEN 4
                        WHEN 'Home Locksmith' THEN 4
                        WHEN 'Mobile' THEN 5
                        ELSE 99
                        END AS ProductGroup
                  ,vc.Name VehicleCategory
                  ,pc.Name ProductCategory
                  ,pc.Sequence ProductCategorySequence
                  ,MAX(CASE WHEN rt.Name IN ('Base', 'Hourly') AND ISNULL(VendorDefaultRates.Price,0.00) <> 0.00 THEN 1 ELSE 0 END) AS ProductIndicator
                  ,SUM(CASE WHEN rt.Name = 'Base' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS BaseRate
                  ,SUM(CASE WHEN rt.Name = 'Enroute' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS EnrouteRate
                  ,SUM(CASE WHEN rt.Name = 'EnrouteFree' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Quantity  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS EnrouteFreeMiles
                  ,SUM(CASE WHEN rt.Name = 'Service' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS ServiceRate
                  ,SUM(CASE WHEN rt.Name = 'ServiceFree' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Quantity  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS ServiceFreeMiles
                  ,SUM(CASE WHEN rt.Name = 'Hourly' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS HourlyRate
                  ,SUM(CASE WHEN rt.Name = 'GoneOnArrival' THEN 
                        (CASE WHEN VendorDefaultRates.Price IS NOT NULL THEN VendorDefaultRates.Price  
                        ELSE 0.00   
                        END) 
                        ELSE 0 END) AS GOARate
      FROM dbo.Product p 
      JOIN dbo.ProductRateType prt ON prt.ProductID = p.ID --AND prt.RateTypeID = VendorDefaultRates.RateTypeID
      JOIN dbo.RateType rt ON prt.RateTypeID = rt.ID 
      JOIN dbo.ProductCategory pc ON p.ProductCategoryID = pc.ID
      LEFT OUTER JOIN dbo.VehicleCategory vc ON p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN dbo.fnGetAllProductRatesByVendorLocation() VendorDefaultRates  
            ON VendorDefaultRates.ContractRateScheduleID = @rateScheduleID 
            AND p.ID = VendorDefaultRates.ProductID  
            AND rt.ID = VendorDefaultRates.RateTypeID
      WHERE 
            p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')
            AND (
				 (p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name IN ('PrimaryService','SecondaryService')))
				 OR 
				 (p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name = 'AdditionalService')
				  AND p.Name IN ('Tow - Drop Drive Line','Tow - Dollies'))
				)
			AND p.Name NOT IN ('Tow - LD - White Glove')
            AND p.IsShowOnPO = 1 
      GROUP BY 
            p.ID   
            ,p.Name
            ,vc.Name 
            --,vc.Sequence 
            ,pc.Name 
            ,pc.Sequence 
      ORDER BY 
        CASE COALESCE(vc.Name, pc.Name)
            WHEN 'LightDuty' THEN 1
            WHEN 'MediumDuty' THEN 2
            WHEN 'HeavyDuty' THEN 3
            WHEN 'Lockout' THEN 4
            WHEN 'Home Locksmith' THEN 4
            WHEN 'Mobile' THEN 5
            ELSE 99
            END
            ,pc.Sequence
            ,p.Name


 END

GO
/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestAgentTime_Update]    Script Date: 04/21/2015 14:13:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ServiceRequestAgentTime_Update]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ServiceRequestAgentTime_Update]
GO

/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestAgentTime_Update]    Script Date: 04/21/2015 14:13:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- EXEC [dbo].[dms_ServiceRequestAgentTime_Update]


CREATE PROCEDURE [dbo].[dms_ServiceRequestAgentTime_Update] (
	@StartDate datetime = NULL,
	@EndDate datetime = NULL
)
AS
BEGIN


	--DECLARE @StartDate Datetime = '1/16/2015'
	--DECLARE @EndDate Datetime = '1/17/2015'
	
	IF @StartDate IS NULL 
		SET @StartDate = Convert(datetime, Convert(varchar, DATEADD(dd,-1,GetDate()),101))
		
	IF @EndDate IS NULL
		SET @EndDate = Convert(datetime, Convert(varchar, DATEADD(dd,1,GetDate()),101))	
	
	DECLARE @srEntityID INT,
			@CaseEntityID INT,
			@VendorLocationEntityID INT,
			@SRCompleteID int,
			@SRCancelledID int,
			@EnterDispatchTabEventID int
	SELECT @srEntityID = ID FROM Entity WHERE Name = 'ServiceRequest'
	SELECT @CaseEntityID = ID FROM Entity WHERE Name = 'Case'
	SELECT @VendorLocationEntityID = ID FROM Entity WHERE Name = 'VendorLocation'
	SELECT @SRCompleteID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Complete')
	SELECT @SRCancelledID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Cancelled')
	SELECT @EnterDispatchTabEventID = (SELECT ID from [Event] where name = 'EnterDispatchTab')
	
	Declare @ContactCategoryID_VendorSelection int,
		@ContactActionID_Negotiate int,
		@ContactCategoryID_ServiceLocationSelection int
	Set @ContactCategoryID_VendorSelection = (Select ID From ContactCategory Where Name = 'VendorSelection')
	Set @ContactActionID_Negotiate = (Select ID From ContactAction Where Name = 'Negotiate')
	Set @ContactCategoryID_ServiceLocationSelection = (Select ID From ContactCategory Where Name = 'ServiceLocationSelection')

	DECLARE @TimeTypeFrontEnd int,
			@TimeTypeBackEnd int,
			@TimeTypeTech int
	SELECT @TimeTypeFrontEnd = (SELECT ID FROM TimeType WHERE NAME = 'FrontEnd')
	SELECT @TimeTypeBackEnd = (SELECT ID FROM TimeType WHERE NAME = 'BackEnd')
	SELECT @TimeTypeTech = (SELECT ID FROM TimeType WHERE NAME = 'Tech')

	DECLARE @TechLeadTimeLimitSeconds int
	SET @TechLeadTimeLimitSeconds = 43200  --(12 hrs in seconds)
	
		/* Tech Users list */
	DECLARE @TechUsers Table (Username nvarchar(50))
	INSERT INTO @TechUsers (Username) VALUES ('lwendt')
	INSERT INTO @TechUsers (Username) VALUES ('kcarichner')
	INSERT INTO @TechUsers (Username) VALUES ('kgold')
	INSERT INTO @TechUsers (Username) VALUES ('lpintado')
	INSERT INTO @TechUsers (Username) VALUES ('ilewis')
	INSERT INTO @TechUsers (Username) VALUES ('ecausley')
	INSERT INTO @TechUsers (Username) VALUES ('kgriffis')
	INSERT INTO @TechUsers (Username) VALUES ('pscammel')
	INSERT INTO @TechUsers (Username) VALUES ('jenglish')
	INSERT INTO @TechUsers (Username) VALUES ('pwilliams')
	INSERT INTO @TechUsers (Username) VALUES ('doliver')

	/*
	Select u.UserName
	From aspnet_Users u
	Join aspnet_Applications app on app.ApplicationId = u.ApplicationId
	Join aspnet_UsersInRoles uir on u.UserId = uir.UserId
	Join aspnet_Roles r on r.RoleId = uir.RoleId
	Where app.ApplicationName = 'DMS'
	and r.RoleName like '%tech%'
	*/


	IF OBJECT_ID('tempdb..#tmpClickToCallEvents') IS NOT NULL
		Drop table #tmpClickToCallEvents
	IF OBJECT_ID('tempdb..#tmpSREvents') IS NOT NULL
		Drop table #tmpSREvents
	IF OBJECT_ID('tempdb..#tmpSRTime') IS NOT NULL
		Drop table #tmpSRTime
	IF OBJECT_ID('tempdb..#tmpSRTimeDispatch') IS NOT NULL
		Drop table #tmpSRTimeDispatch
	IF OBJECT_ID('tempdb..#tmpSRTTech') IS NOT NULL
		Drop table #tmpSRTTech


	Select el.CreateDate, el.CreateBy
	Into #tmpClickToCallEvents
	From EventLog el (NOLOCK)
	Join [Event] e (NOLOCK) on e.ID = el.EventID
	where e.Name = 'ClickToCall'
	and el.CreateDate  BETWEEN @StartDate AND @EndDate

	Create Index IDX_tmpClickToCallEvents ON #tmpClickToCallEvents(CreateDate, CreateBy)

	---- Get all completed and cancelled service requests within the date range
	;WITH wSRs
	AS
	(
	SELECT     
		c.ID CaseID
		,c.ProgramID
		,sr.id ServiceRequestID
		,pc.name AS ProductCategoryName
	FROM  ServiceRequest sr (NOLOCK)
	JOIN  [Case] c (NOLOCK) ON c.ID = sr.CaseID
	JOIN  Program p (NOLOCK) ON p.ID = c.ProgramID
	JOIN  Client cl (NOLOCK) ON cl.ID = p.ClientID
	LEFT JOIN   ProductCategory pc (NOLOCK) ON pc.ID = sr.ProductCategoryID
	WHERE 
	(sr.ServiceRequestStatusID = @SRCompleteID OR sr.ServiceRequestStatusID = @SRCancelledID)
	AND sr.CreateDate BETWEEN @StartDate AND @EndDate 
	)


	---- SR Events - Attempting to get call center events only
	SELECT      W.CaseID
				,W.ProgramID
				,W.ServiceRequestID 
				,el.ID EventLogID
				,CAST(NULL as int) MatchEventLogID
				,Case WHEN el.CreateDate < '3/1/2015' AND e.Name IN ('LeaveFinishTab','SaveFinishTab') THEN 'Close'
					WHEN e.Name = 'SaveFinishTab' THEN 'Close'  
					Else 'Open' END ActionType
				--,Case WHEN e.Name = 'SaveFinishTab' THEN 'Close' Else 'Open' END ActionType
				,e.Name EventName
				,el.SessionID
				,el.CreateBy
				,el.CreateDate
				,0 IsInboundCall
				,0 IsBeginMatchedToEnd
				,CASE WHEN e.Name IN ('StartServiceRequest','OpenActiveRequest','CreateServiceRequestForInfoCall') THEN 1 ELSE 0 END IsCheckForInboundCall
				,CAST(NULL as int) InboundCallID
	INTO #tmpSREvents
	FROM  wSRs W (NOLOCK)
	JOIN  EventLogLink ell (NOLOCK) ON (ell.EntityID = @srEntityID AND ell.RecordID = W.ServiceRequestID) 
	JOIN  EventLog el (NOLOCK) ON (el.ID = ell.EventLogID) 
	JOIN [Event] e (NOLOCK) ON e.ID = el.EventID 
		AND  (e.Name IN (
			'StartServiceRequest','OpenServiceRequest','CreateServiceRequestForInfoCall' --,'ManagerOverrideOpenCase'
			,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','SaveFinishTab')
			OR
			-- ODIS Release on 3/1 introduced SaveFinishTab which is more reliable
			(el.CreateDate < '3/1/2015' AND e.Name = 'LeaveFinishTab'))
		--,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','LeaveFinishTab','SaveFinishTab')
	WHERE 
	(
	el.CreateBy IN (SELECT Username FROM @TechUsers)
	OR 
	NOT EXISTS (SELECT * FROM aspnet_Users au (NOLOCK)
	   JOIN aspnet_Applications a (NOLOCK) ON a.ApplicationId = au.ApplicationId AND a.ApplicationName = 'DMS'
	   JOIN aspnet_UsersInRoles uir (NOLOCK) ON uir.UserId = au.UserId
	   JOIN aspnet_Roles r (NOLOCK) ON r.RoleId = uir.RoleId
	   WHERE au.Username = el.CreateBy
	   AND r.RoleName IN (
			'VendorMgr'
			,'VendorRep'
			,'ClientRelationsMgr'
			,'ClientRelations'
			,'DispatchAdmin'
			,'ClaimsMgr'
			,'Claims'
			,'Accounting'
			,'InvoiceEntry'
			,'SysAdmin'
			,'AccountingMgr')
	  )
	)
	
	/*  TOOK OUT CASE EVENTS GOING FORWARD DUE TO CODE FIX
	---- Case Events - Attempting to get call center events only
	---- Most events are related to just the SR, but some are linked to Case
	UNION
	SELECT      W.CaseID
				,W.ProgramID
				,W.ServiceRequestID 
				,el.ID EventLogID
				,CAST(NULL as int) MatchEventLogID
				,Case WHEN e.Name IN ('LeaveFinishTab','SaveFinishTab') THEN 'Close' Else 'Open' END ActionType
				--,Case WHEN e.Name = 'SaveFinishTab' THEN 'Close' Else 'Open' END ActionType
				,e.Name EventName
				,el.SessionID
				,el.CreateBy
				,el.CreateDate
				,0 IsInboundCall
				,0 IsBeginMatchedToEnd
				,CASE WHEN e.Name IN ('StartServiceRequest','OpenActiveRequest') THEN 1 ELSE 0 END IsCheckForInboundCall
				,CAST(NULL as int) InboundCallID
	FROM  wSRs W (NOLOCK)
	JOIN  EventLogLink ell (NOLOCK) ON (ell.EntityID = @CaseEntityID AND ell.RecordID = W.CaseID)
	JOIN  EventLog el (NOLOCK) ON (el.ID = ell.EventLogID) 
	JOIN [Event] e (NOLOCK) ON e.ID = el.EventID 
		AND  (e.Name IN (
			'StartServiceRequest','OpenServiceRequest','CreateServiceRequestForInfoCall' --,'ManagerOverrideOpenCase'
			,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','SaveFinishTab')
			OR
			-- ODIS Release on 3/1 introduced SaveFinishTab which is more reliable
			(el.CreateDate < '3/1/2015' AND e.Name = 'LeaveFinishTab'))
		--,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','LeaveFinishTab','SaveFinishTab')
	WHERE 
	(
	el.CreateBy IN (SELECT Username FROM @TechUsers)
	OR 
	NOT EXISTS (SELECT * FROM aspnet_Users au (NOLOCK)
	   JOIN aspnet_Applications a (NOLOCK) ON a.ApplicationId = au.ApplicationId AND a.ApplicationName = 'DMS'
	   JOIN aspnet_UsersInRoles uir (NOLOCK) ON uir.UserId = au.UserId
	   JOIN aspnet_Roles r (NOLOCK) ON r.RoleId = uir.RoleId
	   WHERE au.Username = el.CreateBy
	   AND r.RoleName IN (
			'VendorMgr'
			,'VendorRep'
			,'ClientRelationsMgr'
			,'ClientRelations'
			,'DispatchAdmin'
			,'ClaimsMgr'
			,'Claims'
			,'Accounting'
			,'InvoiceEntry'
			,'SysAdmin'
			,'AccountingMgr')
	  )
	)
	*/
	
	ORDER BY ServiceRequestID, CreateDate

	CREATE NONCLUSTERED INDEX IDX_tmpSREvents ON #tmpSREvents (ServiceRequestID, ActionType, CreateDate)
	CREATE NONCLUSTERED INDEX IDX_tmpSREvents_EventLogID ON #tmpSREvents (EventLogID)


	---- Adjust the OPEN event to the related Inbound call 
	Update sre1 SET InboundCallID = InBoundCallMatch.InboundCallID
	From #tmpSREvents sre1
	Join (
		Select sre.EventLogID, MAX(ic.ID) InboundCallID
		FROM #tmpSREvents sre
		Join InboundCall ic (NOLOCK) on ic.CaseID = sre.CaseID and ic.CreateBy = sre.CreateBy and ic.CreateDate < sre.CreateDate and DATEDIFF(mi, ic.CreateDate, sre.CreateDate) < 20
		Where sre.IsCheckForInboundCall = 1
		Group By sre.EventLogID
		) InBoundCallMatch ON sre1.EventLogID = InBoundCallMatch.EventLogID

	Update sre SET CreateDate = ic.CreateDate, IsInboundCall = 1	
	From #tmpSREvents sre
	Join InboundCall ic on ic.ID = sre.InboundCallID


	---- Link Open to Close
	UPDATE sre1 
	SET MatchEventLogID = 
			(SELECT MIN(sre2.EventLogID) 
			FROM #tmpSREvents sre2 
			WHERE sre2.ServiceRequestID = sre1.ServiceRequestID 
			AND sre2.CreateBy = sre1.CreateBy
			AND sre2.EventLogID > sre1.EventLogID) 
	From #tmpSREvents sre1 
	WHERE sre1.ActionType = 'OPEN' 

	-- Set IsBeginMatchedToEnd if the identified event was a Close event
	-- Need to insure that the agent did not drop out without saving and then got back in
	UPDATE sre1
	SET IsBeginMatchedToEnd = 1
	From #tmpSREvents sre1 
	JOIN #tmpSREvents sre2 ON sre2.EventLogID = sre1.MatchEventLogID AND sre2.ActionType = 'CLOSE'
	WHERE sre1.ActionType = 'OPEN'
	AND sre1.MatchEventLogID IS NOT NULL

	-- If the matched event for the same person was not a close, then clear the match and let the next step simply pair the event with the next access (below)
	UPDATE sre1
	SET MatchEventLogID = NULL, IsBeginMatchedToEnd = 0
	From #tmpSREvents sre1 
	JOIN #tmpSREvents sre2 ON sre2.EventLogID = sre1.MatchEventLogID AND sre2.ActionType <> 'CLOSE'
	WHERE sre1.ActionType = 'OPEN'
	AND sre1.MatchEventLogID IS NOT NULL


	---- Flatten out events and add TimeType based on distinct user list
	SELECT 
		sre1.ProgramID
		,sre1.ServiceRequestID
		,sre1.EventLogID BeginEventLogID
		,sre1.CreateDate BeginDate
		,sre1.CreateBy BeginUser
		,sre2.EventLogID EndEventLogID
		,sre2.CreateDate EndDate
		,sre2.CreateBy EndUser
		,CASE WHEN sre2.CreateDate IS NOT NULL THEN DATEDIFF(ss, sre1.CreateDate, sre2.CreateDate) ELSE 0 END EventSeconds
		,NULL as TechLeadTimeSeconds
		,Case WHEN sre1.CreateBy IN (SELECT Username FROM @TechUsers) THEN @TimeTypeTech ELSE @TimeTypeBackEnd END TimeTypeID
		,sre1.IsInboundCall
		--,Case WHEN sre1.CreateBy IN (SELECT Username FROM @TechUsers) THEN 1 ELSE 0 END IsTech
		,sre1.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	Into #tmpSRTime
	From #tmpSREvents sre1
	Left Outer Join #tmpSREvents sre2 on sre1.MatchEventLogID = sre2.EventLogID
	Where sre1.ActionType = 'OPEN'
	
	CREATE NONCLUSTERED INDEX IDX_tmpSRTime_SRID ON #tmpSRTime (ServiceRequestID)

		
	--update all the first entries for each SR as FrontEnd time type
	--make sure that first entry is in the temp table, may not be if adding to prior days entries
	UPDATE SRT
	SET SRT.TimeTypeID = @TimeTypeFrontEnd
	FROM #tmpSRTime SRT
	JOIN ServiceRequest SR (nolock) on SR.ID = SRT.ServiceRequestID
	WHERE 
	SRT.BeginDate <= SR.CreateDate
	AND SRT.BeginEventLogID = (SELECT Top 1 (BeginEventlogID) FROM #tmpSRTime tSRT where tSRT.ServiceRequestID = SRT.ServiceRequestID Order by BeginDate, EndDate)

	
	--Search for first time entry for each SR.  Within that timeframe search for 'EnterDispatchTab' event
	--and create new record to split the time between FrontEnd and Dispatch. If 'EnterDispatchTab' event not
	--found then don't need to split
	SELECT SRT.ProgramID
	,SRT.ServiceRequestID
		,SRT.BeginEventLogID 
		,SRT.BeginDate 
		,SRT.BeginUser 
		,SRT.EndEventLogID
		,SRT.EndDate
		,SRT.EndUser
		,EL.ID DispatchEventLogID
		,EL.CreateDate DispatchDate
		,EL.CreateBy DispatchUser
		,SRT.EventSeconds
		,NULL as TechLeadTimeSeconds
		,SRT.TimeTypeID
		,SRT.IsInboundCall
		,SRT.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	INTO #tmpSRTimeDispatch 
	FROM #tmpSRTime SRT 
	JOIN EventLogLink ell (NOLOCK) ON (ell.EntityID = @srEntityID AND ell.RecordID = SRT.ServiceRequestID) 
	JOIN  EventLog el (NOLOCK) ON 
	(el.ID = ell.EventLogID AND el.CreateBy = SRT.BeginUser AND el.createdate between SRT.BeginDate and SRT.EndDate
	and el.createdate = (SELECT Min(CreateDate) from EventLog el2 (NOLOCK)
	JOIN EventLogLink ell2 (NOLOCK) on ell2.EntityID = @srEntityID AND ell2.RecordID = SRT.ServiceREquestID 
	WHERE el2.ID = ell2.EventLogID and el2.CreateBy = SRT.BeginUser AND el.createdate between SRT.BeginDate and SRT.EndDate
	AND el2.EventID = @EnterDispatchTabEventID))
	JOIN [Event] e (NOLOCK) ON E.ID = el.EventID and el.EventID = @EnterDispatchTabEventID
	WHERE SRT.TimeTypeID = @TimeTypeFrontEnd 
	AND SRT.EndEventLogID <> EL.ID
	
	--Update first record of SR to end when EnterDispatchTab Event occurred; recalc EventSeconds
	UPDATE SRT
	SET SRT.EndEventLogID = SRTD.DispatchEventLogID,
	SRT.EndUser = SRTD.DispatchUser,
	SRT.EndDate = SRTD.DispatchDate,
	SRT.EventSeconds = CASE WHEN SRTD.DispatchDate IS NOT NULL THEN DATEDIFF(ss, SRT.BeginDate, SRTD.DispatchDate) ELSE 0 END 
	FROM #tmpSRTime SRT
	JOIN #tmpSRTimeDispatch SRTD ON SRTD.ServiceRequestID = SRT.ServiceRequestID AND SRTD.BeginEventLogID = SRT.BeginEventLogID
	
	
    --Insert new record for each dispatch event found, set type to BackEnd, calc EventSeconds
    INSERT INTO #tmpSRTime
    SELECT 
		SRTD.ProgramID
		,SRTD.ServiceRequestID
		,SRTD.DispatchEventLogID BeginEventLogID
		,SRTD.DispatchDate BeginDate
		,SRTD.DispatchUser BeginUser
		,SRTD.EndEventLogID
		,SRTD.EndDate
		,SRTD.EndUser
		,CASE WHEN SRTD.EndDate IS NOT NULL THEN DATEDIFF(ss, SRTD.DispatchDate, SRTD.EndDate) ELSE 0 END EventSeconds
		,NULL as TechLeadTimeSeconds
		,@TimeTypeBackEnd TimeTypeID
		,SRTD.IsInboundCall
		,SRTD.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	From #tmpSRTimeDispatch SRTD
		
	
	--Find every timetype = 'Tech', find prior record and calc difference between prior event end time
	--and tech record begin time.  If greater than 12 hours then TechLeadTimeSeconds = 0.  If prior record 
	--timetype = 'Tech' then TechLeadTimeSeconds = 0, else calc TechLeadTimeSeconds
	SELECT 
		SRT.ServiceRequestID ServiceRequestID
		,SRT.BeginEventLogID BeginEventLogID
		,SRT.BeginDate BeginDate
		,SRT.BeginUser BeginUser
		,SRT.EndEventLogID EndEventLogID
		,SRT.EndDate EndDate
		,SRT.EndUser EndUser
		,(SELECT MAX(SRTemp.EndDate) FROM #tmpSRTime SRTemp WHERE
			SRTemp.ServiceRequestID = SRT.ServiceRequestID 
			AND SRTemp.EndDate is not null 
			AND SRTemp.EndDate <= SRT.BeginDate
			AND SRTemp.TimeTypeID <> @TimeTypeTech) as PriorEventEndDate
	INTO #tmpSRTTech
	FROM #tmpSRTime SRT
	WHERE SRT.TimeTypeID = @TimeTypeTech
	AND SRT.EndDate is not null
	AND SRT.TechLeadTimeSeconds is null
	AND (SELECT Top 1 TimeTypeID FROM #tmpSRTime SRTemp WHERE
			SRTemp.ServiceRequestID = SRT.ServiceRequestID 
			AND SRTemp.EndDate is not null 
			AND SRTemp.EndDate <= SRT.BeginDate
			ORDER BY SRTemp.EndDate DESC) <> @TimeTypeTech
	
	
	
	UPDATE SRT
	SET TechLeadTimeSeconds = CASE WHEN SRTTech.PriorEventEndDate is not null AND (DATEDIFF(ss, ISNULL(SRTTech.PriorEventEndDate,'1/1/1900'), SRTTech.BeginDate)) < @TechLeadTimeLimitSeconds 
								THEN DATEDIFF(ss, SRTTech.PriorEventEndDate, SRTTech.BeginDate) 
								ELSE 0 END
	FROM #tmpSRTime SRT
	JOIN #tmpSRTTech SRTTech on SRTTech.ServiceRequestID = SRT.ServiceRequestID and SRTTech.BeginEventLogID = SRT.BeginEventLogID
	
	
	
	--Update counts
	UPDATE SRT
	SET IssuedPOCount = (SELECT Count(*) 
			FROM PurchaseOrder PO (NOLOCK)
			WHERE PO.ServiceRequestID = SRT.ServiceRequestID 
			AND PO.IsActive = 1 
			AND PO.PurchaseOrderNumber IS NOT NULL 
			AND PO.CreateDate between SRT.BeginDate and SRT.EndDate
			) 
		, DispatchISPCallCount = (Select Count(*) 
			From (
				Select sr.ID ServiceRequestID, cll_ISP.RecordID, cl.CreateBy, MAX(cl.CreateDate) CreateDate
				From ServiceRequest SR (NOLOCK) 
				Join ContactLogLink cll (NOLOCK) on cll.EntityID = @srEntityID and cll.RecordID = sr.ID 
				Join ContactLog cl (NOLOCK) on cl.ID = cll.ContactLogID
				Left Outer Join ContactLogLink cll_ISP (NOLOCK) on cll_ISP.ContactLogID =cl.ID and cll_ISP.EntityID = @VendorLocationEntityID 
				Join ContactLogAction cla (NOLOCK) on cla.ContactLogID = cl.ID
				Join ContactAction ca (NOLOCK) on ca.ID = cla.ContactActionID
				Join ContactCategory cc (NOLOCK) on cc.ID = cl.ContactCategoryID
				Join ContactType ct (NOLOCK) on ct.ID = cl.ContactTypeID
				Where sr.ID = SRT.ServiceRequestID
				and cl.ContactCategoryID = @ContactCategoryID_VendorSelection
				and cla.ContactActionID <> @ContactActionID_Negotiate
				Group By sr.ID, cll_ISP.RecordID, cl.CreateBy
				--Order by sr.ID, cl.ID
				) X
			Where X.ServiceRequestID = SRT.ServiceRequestID AND
				X.CreateDate BETWEEN SRT.BeginDate and SRT.EndDate
			) 
		,ServiceFacilityCallCount = (Select Count(*) 
			From (
				Select sr.ID ServiceRequestID, cll_ISP.RecordID, cl.CreateBy, MAX(cl.CreateDate) CreateDate
				From ServiceRequest SR (NOLOCK) 
				Join ContactLogLink cll (NOLOCK) on cll.EntityID = @srEntityID and cll.RecordID = sr.ID 
				Join ContactLog cl	(NOLOCK) on cl.ID = cll.ContactLogID
				Left Outer Join ContactLogLink cll_ISP (NOLOCK) on cll_ISP.ContactLogID =cl.ID and cll_ISP.EntityID = @VendorLocationEntityID 
				Join ContactLogAction cla (NOLOCK) on cla.ContactLogID = cl.ID
				Join ContactAction ca (NOLOCK) on ca.ID = cla.ContactActionID
				Join ContactCategory cc (NOLOCK) on cc.ID = cl.ContactCategoryID
				Join ContactType ct (NOLOCK) on ct.ID = cl.ContactTypeID
				Where sr.ID = SRT.ServiceRequestID
				and cl.ContactCategoryID = @ContactCategoryID_ServiceLocationSelection
				and cll_ISP.RecordID IS NOT NULL
				Group By sr.ID, cll_ISP.RecordID, cl.CreateBy
				--Order by sr.ID, cl.ID
				) X
			Where X.ServiceRequestID = SRT.ServiceRequestID AND
				X.CreateDate BETWEEN SRT.BeginDate and SRT.EndDate
			)
		,ClicktoCallcount = ISNULL((Select Count(*) ClickToCallCount
			From #tmpClickToCallEvents ctc 
			Where ctc.CreateBy = SRT.BeginUser and ctc.CreateDate between SRT.BeginDate and SRT.EndDate
			),0) 
		FROM #tmpSRTime SRT
	
	
		
	INSERT INTO dbo.ServiceRequestAgentTime
		([ProgramID]
		,[ServiceRequestID]
		,[BeginEventLogID]
		,[BeginDate]
		,[BeginUser]
		,[EndEventLogID]
		,[EndDate]
		,[EndUser]
		,[EventSeconds]
		,[TechLeadTimeSeconds]
		,[TimeTypeID]
		,[IsInboundCall]
		,[IsBeginMatchedToEnd]
		,[IssuedPOCount]
		,[DispatchISPCallCount]
		,[ServiceFacilityCallCount]
		,[ClickToCallCount])
	Select 
		[ProgramID]
		,[ServiceRequestID]
		,[BeginEventLogID]
		,[BeginDate]
		,[BeginUser]
		,[EndEventLogID]
		,[EndDate]
		,[EndUser]
		,[EventSeconds]
		,[TechLeadTimeSeconds]
		,[TimeTypeID]
		,[IsInboundCall]
		,[IsBeginMatchedToEnd]
		,[IssuedPOCount]
		,[DispatchISPCallCount]
		,[ServiceFacilityCallCount]
		,[ClickToCallCount]
	From #tmpSRTime tmpSrt
	WHERE NOT EXISTS (
		SELECT *
		FROM ServiceRequestAgentTime srt
		WHERE srt.ServiceRequestID = tmpSrt.ServiceRequestID
		AND srt.BeginEventLogID = tmpSrt.BeginEventLogID
		)
	ORDER BY tmpSRT.BeginDate
		
	--Select 
		--[ProgramID] = tmpSRT.ProgramID
		--,[ServiceRequestID] = tmpSrt.ServiceRequestID,
	UPDATE srt SET
		[BeginEventLogID] = tmpSrt.BeginEventLogID
		,[BeginDate] = tmpSrt.BeginDate
		,[BeginUser] = tmpSrt.BeginUser
		,[EndEventLogID] = tmpSrt.EndEventLogID
		,[EndDate] = tmpSrt.EndDate
		,[EndUser] = tmpSrt.EndUser
		,[EventSeconds] = tmpSrt.EventSeconds
		,[IsInboundCall] = tmpSrt.IsInboundCall
		,[TechLeadTimeSeconds] = tmpSrt.TechLeadTimeSeconds
		,[TimeTypeID] = tmpSrt.TimeTypeID
		,[IsBeginMatchedToEnd] = tmpSrt.IsBeginMatchedToEnd
		,[IssuedPOCount] = tmpSrt.IssuedPOCount
		,[DispatchISPCallCount] = tmpSrt.DispatchISPCallCount
		,[ServiceFacilityCallCount] = tmpSrt.ServiceFacilityCallCount
		,[ClickToCallCount] = tmpSrt.ClickToCallCount
	FROM #tmpSRTime tmpSRT
	JOIN ServiceRequestAgentTime srt on srt.ServiceRequestID = tmpSrt.ServiceRequestID AND srt.BeginEventLogID = tmpSrt.BeginEventLogID
		and srt.AccountingInvoiceBatchID IS NULL

END
GO



GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_ServiceTech_RepairLocationDetails]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_ServiceTech_RepairLocationDetails] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 

CREATE PROC dms_ServiceTech_RepairLocationDetails(@ServiceRequestID AS INT = NULL)
AS
BEGIN

DECLARE @Result AS TABLE(
		
		ServiceRequestID INT NOT NULL,
		VendorLocationID INT NULL,
	
		VendorNumber		  NVARCHAR(MAX),
		VendorName			  NVARCHAR(MAX),
		VendorAddressLine1    NVARCHAR(MAX),
		VendorCity			  NVARCHAR(MAX),
		VendorStateProvince   NVARCHAR(MAX),
		VendorPostalCode      NVARCHAR(MAX),
		VendorCountryCode     NVARCHAR(MAX),
		VendorDispatchNumber  NVARCHAR(MAX),
		
		SRDestinationDescription    NVARCHAR(MAX),
		SRDestinationAddress    NVARCHAR(MAX),
		SRDestinationCity    NVARCHAR(MAX),
		SRDestinationStateProvince    NVARCHAR(MAX),
		SRDestinationPostalCode    NVARCHAR(MAX),
		SRDestinationCountryCode    NVARCHAR(MAX)
)

IF EXISTS (SELECT * FROM ServiceRequest SR WITH(NOLOCK) WHERE SR.ID = @ServiceRequestID AND SR.DestinationVendorLocationID IS NOT NULL)
BEGIN
	  DECLARE @DestinationVendorLocationID AS INT
	  SET     @DestinationVendorLocationID = (SELECT SR.DestinationVendorLocationID FROM ServiceRequest SR WITH(NOLOCK) WHERE SR.ID = @ServiceRequestID)
	  
	  INSERT INTO @Result(ServiceRequestID,VendorLocationID,VendorNumber,VendorName,VendorAddressLine1,VendorCity,VendorStateProvince,VendorPostalCode,VendorCountryCode,VendorDispatchNumber)
	  SELECT  @ServiceRequestID,
			  @DestinationVendorLocationID	
			, v.VendorNumber AS VendorNumber
			, v.Name AS VendorName
			, ae.Line1 AS Line1
			, ae.City AS City
			, ae.StateProvince AS StateProvince
			, ae.PostalCode AS PostalCode
			, ae.CountryCode AS CountryCode
			, ped.PhoneNumber AS DispatchNumber
	  FROM	VendorLocation vl (NOLOCK)
	  JOIN	Vendor v (NOLOCK) ON v.ID = vl.VendorID
	  JOIN	AddressEntity ae (NOLOCK) ON ae.RecordID = vl.ID AND ae.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	  LEFT JOIN PhoneEntity ped (NOLOCK) ON ped.RecordID = vl.ID AND ped.EntityID  = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND ped.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
	  WHERE	vl.ID = @DestinationVendorLocationID
END
	
ELSE
	 INSERT INTO @Result(ServiceRequestID,SRDestinationDescription,SRDestinationAddress,SRDestinationCity,SRDestinationStateProvince,SRDestinationPostalCode,SRDestinationCountryCode)
	 SELECT	  @ServiceRequestID
			, sr.DestinationDescription 
			, sr.DestinationAddress
			, sr.DestinationCity
			, sr.DestinationStateProvince
			, sr.DestinationPostalCode
			, sr.DestinationCountryCode
	FROM	ServiceRequest sr (NOLOCK)
	WHERE	sr.ID = @ServiceRequestID
BEGIN

SELECT * FROM @Result
	
END

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_service_tech_callHistory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_service_tech_callHistory]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

--EXEC [dms_service_tech_callHistory] 1533
CREATE PROC [dbo].[dms_service_tech_callHistory](@ServiceRequestID AS INT = NULL)  
AS  
BEGIN  
SET FMTONLY  OFF

;with wprogramDynamicValues AS(
SELECT PDI.Label,
	   PDIVE.Value,
	   PDIVE.RecordID AS 'ContactLogID'
	   FROM ProgramDataItem PDI
JOIN ProgramDataItemValueEntity PDIVE 
ON PDI.ID = PDIVE.ProgramDataItemID
WHERE PDIVE.Value IS NOT NULL AND PDIVE.Value != ''
AND PDIVE.EntityID = (SELECT ID FROM Entity WHERE Name = 'ContactLog')
) 
SELECT ContactLogID,
	    STUFF((SELECT '|' + CAST(Label AS VARCHAR(MAX))
	    FROM wprogramDynamicValues T1
	    WHERE T1.ContactLogID = T2.ContactLogID
	    FOR  XML path('')),1,1,'' ) as [Question],
	    STUFF((SELECT '|' + CAST(Value AS VARCHAR(MAX))
	    FROM wprogramDynamicValues T1
	    WHERE T1.ContactLogID = T2.ContactLogID
	    FOR  XML path('')),1,1,'' ) as [Answer] 
	    INTO #CustomProgramDynamicValues
	    FROM wprogramDynamicValues T2
	    GROUP BY ContactLogID

SELECT	CC.[Description] AS ContactCategory  
		, CL.Company AS CompanyName  
		, CL.PhoneNumber AS PhoneNumber  
		, CL.TalkedTo AS TalkedTo
		,  cl.CreateDate
		, cl.CreateBy
		, cr.Name AS ContactReason
		, ca.Name AS ContactAction
		, ISNULL(CPDV.Question,'') AS Question
		, ISNULL(CPDV.Answer,'') AS Answer
		, cl.Comments		
FROM	ContactLog cl (NOLOCK)
JOIN	ContactCategory cc (NOLOCK) ON cc.ID = cl.ContactCategoryID
JOIN	ContactLogLink cll (NOLOCK) ON cll.ContactLogID = cl.ID 
LEFT JOIN	ContactLogReason clr (NOLOCK) ON clr.ContactLogID = cl.ID 
LEFT JOIN	ContactReason cr (NOLOCK) ON cr.ID = clr.ContactReasonID
LEFT JOIN	ContactLogAction cla (NOLOCK) ON cla.ContactLogID = cl.ID 
LEFT JOIN	ContactAction ca (NOLOCK) ON ca.ID = cla.ContactActionID
LEFT JOIN	#CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID
WHERE	cll.RecordID = @ServiceRequestID AND cll.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
AND		cc.Name IN ('ServiceLocationSelection','ContactServiceLocation')
ORDER BY cl.CreateDate DESC

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_Vendor_Services_List_Get @VendorID=1
CREATE PROCEDURE [dbo].[dms_Vendor_Portal_Services_List_Get] @VendorID INT
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
DECLARE @FinalResults AS TABLE(
      SortOrder INT NULL,
      ServiceGroup NVARCHAR(255) NULL,
      ServiceName nvarchar(100)  NULL ,
      ProductID int  NULL ,
      VehicleCategorySequence int  NULL ,
      ProductCategory nvarchar(100)  NULL ,
      IsAvailByVendor bit default 0
) 

INSERT INTO @FinalResults (SortOrder, ServiceGroup,ServiceName,ProductID,VehicleCategorySequence,ProductCategory)
      SELECT 
                   CASE WHEN vc.name is NULL THEN 2 
                              ELSE 1 
                   END AS SortOrder
                  ,CASE WHEN vc.name is NULL THEN 'Other' 
                              ELSE vc.name 
                   END AS ServiceGroup
                  ,REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
                  --,ISNULL(vc.Name,'') + CASE WHEN ISNULL(vc.Name,'') <> '' THEN ' - ' ELSE '' END  + REPLACE(REPLACE(REPLACE(p.Name,' - LD',''), ' - MD', ''), ' - HD', '') AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory                  
      FROM Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Service'
      AND pst.Name IN ('PrimaryService', 'SecondaryService')
      AND p.Name Not in ('Concierge', 'Information', 'Tech')
      AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee','Tow - LD - Lamborghini','Tow - LD - White Glove')

      UNION
      SELECT 
                  3 AS SortOrder
                  ,'Additional' AS ServiceGroup
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM  Product p
      JOIN ProductCategory pc on p.productCategoryid = pc.id
      JOIN ProductType pt on p.ProductTypeID = pt.ID
      JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      WHERE pt.Name = 'Service'
      AND pst.Name IN ('AdditionalService')
      AND p.Name Not in ('Concierge', 'Information', 'Tech')
      AND p.Name Not in ('Misc Charge', 'Fuel Surcharge', 'Impound Release Fee', 'Tire Materials','Diagnostics','Storage Fee - Auto','Storage Fee - RV') 
      
      --UNION
      --SELECT 
      --            4 AS SortOrder
      --            ,'ISP Selection' AS ServiceGroup
      --            ,p.Name AS ServiceName
      --            ,p.ID AS ProductID
      --            ,vc.Sequence VehicleCategorySequence
      --            ,pc.Name ProductCategory
      --FROM  Product p
      --JOIN ProductCategory pc on p.productCategoryid = pc.id
      --JOIN ProductType pt on p.ProductTypeID = pt.ID
      --JOIN ProductSubType pst on p.ProductSubTypeID = pst.id
      --LEFT OUTER JOIN VehicleCategory vc on p.VehicleCategoryID = vc.ID
      --LEFT OUTER JOIN VehicleType vt on p.VehicleTypeID = vt.ID
      --WHERE pt.Name = 'Attribute'
      --AND pst.Name = 'Ranking'
      --AND pc.Name = 'ISPSelection'
      
      UNION ALL
      
      SELECT 
                  5 AS SortOrder
                  ,pst.Name AS ServiceGroup 
                  ,p.Name AS ServiceName
                  ,p.ID AS ProductID
                  ,vc.Sequence VehicleCategorySequence
                  ,pc.Name ProductCategory
      FROM Product p
      Join ProductCategory pc on p.productCategoryid = pc.id
      Join ProductType pt on p.ProductTypeID = pt.ID
      Join ProductSubType pst on p.ProductSubTypeID = pst.id
      Left Outer Join VehicleCategory vc on p.VehicleCategoryID = vc.ID
      Left Outer Join VehicleType vt on p.VehicleTypeID = vt.ID
      Where pt.Name = 'Attribute'
      and pc.Name = 'Repair'
      --and pst.Name NOT IN ('Client')
      ORDER BY SortOrder, VehicleCategorySequence, ProductCategory
      

UPDATE @FinalResults SET IsAvailByVendor = 1 FROM  @FinalResults T
LEFT JOIN VendorProduct VP ON VP.ProductID = T.ProductID
WHERE VP.VendorID=@VendorID
      
SELECT * FROM @FinalResults

END
GO

GO
-- Select * From [dbo].[fnGetPreferredVendorsByProduct]() Where VendorID = 4360   
CREATE FUNCTION [dbo].[fnGetPreferredVendorsByProduct] ()  
RETURNS TABLE   
AS  
RETURN   
(  
	Select v.ID VendorID, Preferred.ProductID  
	From vendor v
	Join VendorProduct vp on vp.VendorID = v.ID
	Join Product p on p.ID = vp.ProductID
	Join ProductCategory pc on pc.ID = p.ProductCategoryID
	Join ProductType pt on pt.ID = p.ProductTypeID
	Join ProductSubType pst on pst.ID = p.ProductSubTypeID
	Join (
		Select p.ID ProductID
			--, pc.Name, p.Name,
			,Case 
				 When pc.Name In ('Tow','Winch') And vc.Name = 'HeavyDuty'  Then 'Preferred - HD Tow'
				 When pc.Name In ('Tow','Winch') And vc.Name = 'MediumDuty' Then 'Preferred - MD Tow'
				 When pc.Name In ('Tow','Winch') And vc.Name = 'LightDuty'  Then 'Preferred - LD Tow'
				 When vc.Name = 'HeavyDuty'  Then 'Preferred - HD Service Call'
				 When vc.Name = 'MediumDuty' Then 'Preferred - MD Service Call'
				 Else 'Preferred - LD Service Call'
				 End PreferredCategory
			--,p.Name, pst.Name, pc.Name, vc.Name, p.*
		From Product p
		Join ProductCategory pc on pc.ID = p.ProductCategoryID
		Join ProductType pt on pt.ID = p.ProductTypeID
		Join ProductSubType pst on pst.ID = p.ProductSubTypeID
		Left Outer Join VehicleCategory vc on vc.ID = p.VehicleCategoryID
		Where pst.Name IN ('PrimaryService','SecondaryService')
		and pc.Name not in ('Mobile','Home Locksmith')
		and p.IsShowOnPO = 1
		) Preferred on Preferred.PreferredCategory = p.Name
	Where pc.Name = 'ISPSelection'
	and pt.Name = 'Attribute'
	and pst.Name = 'Ranking'
)  





GO
ALTER TRIGGER ProgramDataItemValueEntity_Trigger_After_Insert ON [dbo].[ProgramDataItemValueEntity] 
FOR INSERT
AS
	
	DECLARE @EntityName NVARCHAR(200);
	DECLARE @ScreenName NVARCHAR(200);
	DECLARE @FieldName NVARCHAR(200);
	DECLARE @Message NVARCHAR(MAX);
	DECLARE @ProgramID INT;

	DECLARE @EntityID INT;
	DECLARE @RecordID INT;
	DECLARE @ProgramDataItemID INT;
	DECLARE @Value NVARCHAR(MAX)
	
	

	SELECT @EntityID		  = currentRecord.EntityID FROM inserted currentRecord;	
	SELECT @RecordID		  = currentRecord.RecordID FROM inserted currentRecord;	
	SELECT @ProgramDataItemID = currentRecord.ProgramDataItemID FROM inserted currentRecord;	
	SELECT @Value			  = currentRecord.Value FROM inserted currentRecord;


	SELECT @EntityName = E.Name FROM Entity E WHERE E.ID = @EntityID
	SELECT @ScreenName = PDI.ScreenName,
		   @FieldName  = PDI.Name,
		   @ProgramID = PDI.ProgramID	 
	FROM   ProgramDataItem PDI WHERE PDI.ID = @ProgramDataItemID


	SET	   @Message = 'Executing Trigger AFTER INSERT ON ProgramDataItemValueEntity - Entity ID : ' + CAST(@EntityID AS NVARCHAR(100)) +  ' Record ID : ' + CAST(@RecordID AS NVARCHAR(100)) + ' Program Data Item : ' + CAST(@ProgramDataItemID AS NVARCHAR(100));
	INSERT INTO [Log]([Date],[Thread],[Level],[Logger],[Message]) VALUES(GETDATE(),0,'INFO','Trigger',@Message)
		
   -- BEGIN ACTUAL LOGIC

    IF @EntityName = 'Member' AND @ScreenName = 'RegisterMember' AND @FieldName = 'ClientReferenceNumber'
	BEGIN
		 -- UPDATE Client Reference Number Always
		 UPDATE Membership SET ClientReferenceNumber = @Value WHERE ID = (SELECT MembershipID FROM Member WHERE ID = @RecordID)

		 -- UPDATE Membership Number Based on Configuration
		 DECLARE	    @dms_programconfiguration_for_program_get AS TABLE(Name NVARCHAR(MAX),
															   Value NVARCHAR(MAX),
															   ControlType NVARCHAR(MAX),
															   DataType NVARCHAR(MAX),
															   Sequence INT)
		INSERT INTO @dms_programconfiguration_for_program_get EXEC dms_programconfiguration_for_program_get @ProgramID,'Application', 'Rule' 

		IF EXISTS (SELECT * FROM @dms_programconfiguration_for_program_get WHERE Name = 'InsertMembershipNumber' AND LOWER(Value) = 'yes')
		BEGIN
			 IF(LEN(@Value) > 0)
			 BEGIN
				UPDATE Membership SET MembershipNumber = @Value WHERE ID = (SELECT MembershipID FROM Member WHERE ID = @RecordID)
			 END
		END
	
	END
	

   -- END LOGIC
	INSERT INTO [Log]([Date],[Thread],[Level],[Logger],[Message]) VALUES(GETDATE(),0,'INFO','Trigger','Trigger Execution Completed')
	
GO



GO
