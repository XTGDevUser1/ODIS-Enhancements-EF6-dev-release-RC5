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
 WHERE id = object_id(N'[dbo].[dms_BillingGenerateInvoices]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingGenerateInvoices] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROCEDURE [dbo].[dms_BillingGenerateInvoices]  
@pUserName as nvarchar(50) = null,  
@pRefreshDetail as bit = 1,  
@pScheduleTypeID as int = null,  
@pScheduleDateTypeID as int,   
@pScheduleRangeTypeID as int,  
@pInvoicesXML as XML -- Eg: <Records><BillingDefinitionInvoiceID>1</BillingDefinitionInvoiceID><BillingDefinitionInvoiceID>2</BillingDefinitionInvoiceID></Records>

AS  
/********************************************************************  
 **  
 ** dms_BillingGenerateInvoices  
 **  
 ** Date		Added By	Description  
 ** ---------- ----------	----------------------------------------  
 ** 05/30/13	MJKrzysiak	Created  
 **   
 ** CHANGE LOG:
 **	#	Date		Added By	Description  
 **	---	---------- ----------	----------------------------------------  
 ** ^1	12/30/13	MJKrzysiak	Added code to override the Cost on an invoice line when the RateType
 **								is PercentageEach.  Put a null value in.
 **								MAS90 only reports the cost as a $$$...these are
 **								represented in the setup as a %, so does not look right.  Solution
 **								per K Wheeler in acct is to exclude the pct from the cost on the
 **								invoice line.
 **
 ** ^2	12/30/13	MJKrzysiak	Refresh only active invoices (IsActive = 1).
 **
 ** ^3	12/30/13	MJKrzysiak	Do not create inactive invoices lines (IsActive = 0).
 **
 ** ^4	12/30/13	MJKrzysiak	Do not create invoices lines with no details.
 **  
 ** ^5	12/30/13	MJKrzysiak	Do not create invoices with no details.
 **
 **	^6	02/04/14	MJKrzysiak	Change the GenWhen scope for SCHED_END_JAN
 **								to grab these config'ed items on or after
 ** ^7	02/14/14	MJKrzysiak	Added code to handle a PENDING schedule 
 **								along with an OPEN schedule
 **
 **********************************************************************/
  
/**  
  
declare @Invoices as BillingDefinitionInvoiceTableType  
insert into @Invoices (BillingDefinitionInvoiceID)  
select distinct BillingDefinitionInvoiceID from dbo.BillingInvoiceDetailEventQueue where QueueStatus = 'Finalized'  
  
exec dbo.dms_BillingGenerateInvoices @Invoices  
  
exec dbo.dms_BillingGenerateInvoices 1   
  
  
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
  @ProcessDate as date,  
  @ScheduleDateOPEN as date,
  @ScheduleRangeEndOPEN as date,  
  @ScheduleDatePENDING as date,
  @ScheduleRangeEndPENDING as date,  
    
  @InvoiceCount as int,  
  @NumOfInvoicesToCreate as int,  
  @InvoiceRowToCreate as int,  
  @BillingDefinitionInvoiceID as int,  
  @BillingInvoiceID as int,  
  @ScheduleRangeTypeID as int,  
  @ScheduleRangeName as nvarchar(50),  
  @NumOfLinesToCreate as int,  
  @InvoiceLineRowToCreate as int,  
  @BillingDefinitionInvoiceLineID as int,  
  @BillingInvoiceLineID as int,  
    
  @NumOfEventsToCreate as int,  
  @BillingDefinitionEventID as int,  
  @BillingInvoiceDetailEventID as int,  
    
  @InvoiceDate as date,  
  @UserName as nvarchar(50),  
  @BillingCode_DetailStatus_PENDING as int,  
  @BillingCode_DetailStatus_READY as int,  
  @BillingCode_DetailStatus_ONHOLD as int,  
  @BillingCode_DetailStatus_EXCEPTION as int,  
  @BillingCode_DetailStatus_DELETED as int,  
  
  @BillingCode_LineStatus_READY as int,  
  @BillingCode_LineStatus_PENDING as int,  
    
  @BillingCode_InvoiceStatus_READY as int,  
  @BillingCode_InvoiceStatus_PENDING as int,
  @InvoiceLineDetailCount as int,
  @InvoiceDetailCount as int
  
  
-- Initialize Local Variables  
select	@Debug = 0
select	@Now = getdate()  
select	@InvoiceDate = convert(date, @Now)  
select	@ProgramName = object_name(@@procid)  
select	@InvoiceRowToCreate = 1,
		@InvoiceLineRowToCreate = 1,
		@InvoiceLineDetailCount = 0,
		@InvoiceDetailCount = 0

    
-- Capture Billing Codes to use  
select @BillingCode_DetailStatus_READY = ID from dbo.BillingInvoiceDetailStatus where Name = 'READY'  
select @BillingCode_DetailStatus_PENDING = ID from dbo.BillingInvoiceDetailStatus where Name = 'PENDING'  
select @BillingCode_DetailStatus_ONHOLD = ID from dbo.BillingInvoiceDetailStatus where Name = 'ONHOLD'  
select @BillingCode_DetailStatus_EXCEPTION = ID from dbo.BillingInvoiceDetailStatus where Name = 'EXCEPTION'  
select @BillingCode_DetailStatus_DELETED = ID from dbo.BillingInvoiceDetailStatus where Name = 'DELETED'  
  
select @BillingCode_LineStatus_READY = ID from dbo.BillingInvoiceLineStatus where Name = 'READY'  
select @BillingCode_LineStatus_PENDING = ID from dbo.BillingInvoiceLineStatus where Name = 'PENDING'   
  
select @BillingCode_InvoiceStatus_READY = ID from dbo.BillingInvoiceStatus where Name = 'READY'  
select @BillingCode_InvoiceStatus_PENDING = ID from dbo.BillingInvoiceStatus where Name = 'PENDING'   
  
select @ScheduleDateOPEN = (select ScheduleDate from BillingSchedule where ScheduleStatusID = (select ID from BillingScheduleStatus where Name = 'OPEN') and ScheduleTypeID = @pScheduleTypeID)  
select @ScheduleRangeEndOPEN = (select ScheduleRangeEnd from BillingSchedule where ScheduleStatusID = (select ID from BillingScheduleStatus where Name = 'OPEN') and ScheduleTypeID = @pScheduleTypeID)  
  
select @ScheduleDatePENDING = (select ScheduleDate from BillingSchedule where ScheduleStatusID = (select ID from BillingScheduleStatus where Name = 'PENDING') and ScheduleTypeID = @pScheduleTypeID)  
select @ScheduleRangeEndPENDING = (select ScheduleRangeEnd from BillingSchedule where ScheduleStatusID = (select ID from BillingScheduleStatus where Name = 'PENDING') and ScheduleTypeID = @pScheduleTypeID)  

  
select @ProcessDate = convert(date, @Now)  
  
--select @ProcessDate = '07/01/2013' -----  <<<<<<<<<<<<<<<<<   THIS IS FOR TESTING...WE ARE FORCING THE PROCESS DATE TO GET ALL TRANS   
         -----  <<<<<<<<<<<<<<<<<   CHANGE IN PROD !!!!!!!!!  


if @Debug = 1
begin
	select @pInvoicesXML as pInvoicesXML
	select 'Invoices to Process', * from @pInvoices
end

  
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
-- where bss.Name = 'OPEN'  
 where bss.Name in ('OPEN', 'PENDING') 
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
 BillingDefinitionInvoiceID int)
   
create index inx_tmpInvoices1 on #tmpInvoices(RowID)  
create index inx_tmpInvoices2 on #tmpInvoices (BillingDefinitionInvoiceID)  
  

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
  where 1=1
  and  bdi.IsActive = 1 -- ^2 : Invoice Def Must be Active
end  
  
if @Debug = 1  
begin  
 select '#tmpInvoices', * from #tmpInvoices  
end  


-- Get invoice to create count
select @NumOfInvoicesToCreate = count(*) from #tmpInvoices
  

if @Debug = 1  
begin  
 select @NumOfInvoicesToCreate as NumOfInvoicesToCreate
end  

 
 
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Establish the GenWhen Scope of this run.  See GenWhen lookup table.  Identifies  
-- which events should be picked up relative when this thing runs  
-- Join up to this below to only include these GenWhens  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if object_id('tempdb..#tmpGenWhenScope', 'U') is not null drop table #tmpGenWhenScope  
create table #tmpGenWhenScope  
(EventGenWhenID  int,  
 GenWhenName  nvarchar(50))  
  
-- ALWAYS - Include these in every run  
insert into #tmpGenWhenScope  
(EventGenWhenID,  
 GenWhenName)  
 values(  
(select ID from BillingInvoiceLineEventGenWhen with (nolock) where Name = 'ALWAYS'),  -- EventGenWhenID  
 'ALWAYS')  -- GenWhenName  
  
-- SCHED_END - Include these if this is being processed on the Schedule End Date  
if (@ProcessDate = @ScheduleDateOPEN) or (@ProcessDate = @ScheduleDatePENDING)  -- ^7
begin  
 insert into #tmpGenWhenScope  
 (EventGenWhenID,  
  GenWhenName)  
  values(  
 (select ID from BillingInvoiceLineEventGenWhen with (nolock) where Name = 'SCHED_END'),  -- EventGenWhenID  
  'SCHED_END')  -- GenWhenName  
end  
  
-- SCHED_END_JAN - Include these if this is being processed on or after the Schedule End Date  
--     -- and its JAN  
--if @ProcessDate = @ScheduleDateOPEN and Month(@ScheduleRangeEndOPEN) = 1  
if (@ProcessDate >= @ScheduleDateOPEN and Month(@ScheduleRangeEndOPEN) = 1)  -- ^ 6 On or After
or (@ProcessDate >= @ScheduleDatePENDING and Month(@ScheduleRangeEndPENDING) = 1)  -- ^ 7
begin  
 insert into #tmpGenWhenScope  
 (EventGenWhenID,  
  GenWhenName)  
  values(  
 (select ID from BillingInvoiceLineEventGenWhen with (nolock) where Name = 'SCHED_END_JAN'),  -- EventGenWhenID  
  'SCHED_END_JAN')  -- GenWhenName  
end  
  
if @Debug = 1  
begin  
 select '#tmpGenWhenScope', * from #tmpGenWhenScope  
end  





-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- First Refresh Details if parm says to  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if @pRefreshDetail = 1  
begin  
  
 declare @BillingEvents as BillingDefinitionInvoiceLineEventsTableType  
  
 -- Get the Billing Events to Process  
 -- Look at GenWhen logic above  
 -------------------------------------  
 insert into @BillingEvents  
 (BillingDefinitionInvoiceID,  
  BillingDefinitionInvoiceLineID,  
  BillingDefinitionInvoiceLineEventID)  
 select distinct  
   bdi.ID, -- BillingDefinitionInvoiceID  
   bdil.ID, -- BillingDefinitionInvoiceLineID  
   bdile.ID  
 from dbo.BillingDefinitionInvoice bdi  
 join dbo.BillingDefinitionInvoiceLine bdil on bdil.BillingDefinitionInvoiceID = bdi.ID  
 join dbo.BillingDefinitionInvoiceLineEvent bdile on bdile.BillingDefinitionInvoiceLineID = bdil.ID  
 join dbo.BillingDefinitionInvoiceLineEventProgram bdilep on bdilep.BillingDefinitionInvoiceLineEventID = bdile.ID  
 join dbo.BillingDefinitionEvent bde on bde.ID = bdile.BillingDefinitionEventID  
 join dbo.Program pr on pr.ID = bdilep.ProgramID  
 join dbo.Product prd on prd.ID = bdil.ProductID  
 join #tmpInvoices i on i.BillingDefinitionInvoiceID = bdi.ID -- In Invoice List      
 join #tmpOpenSchedule O on O.ScheduleTypeID = bdi.ScheduleTypeID -- In Open Schedule  
   and O.ScheduleDateTypeID = bdi.ScheduleDateTypeID  
   and O.ScheduleRangeTypeID = bdi.ScheduleRangeTypeID   
 join #tmpGenWhenScope gw on gw.EventGenWhenID = bdile.EventGenWhenID -- In Gen When Scope...see above  
 where 1=1  
 and  bdi.IsActive = 1 -- Invoice Def Must be Active  
 and  bdil.IsActive = 1 -- Invoice Line Def Must be Active  
 and  bdile.IsActive = 1 -- Invoice Line Event Must be Active  
 and  bdilep.IsActive = 1 -- Invoice Line Event Program Must be Active  

	if @Debug = 1  
	begin  
	 select 'BillingEvents', * from @BillingEvents
	end  

 exec dbo.dms_BillingGenerateBillingDetails @UserName, @BillingEvents  
  
end  
  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Get all keys  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
if object_id('tempdb..#tmpBDLines', 'U') is not null drop table #tmpBDLines  
create table #tmpBDLines  
(RowID        int    identity,  
 BillingDefinitionInvoiceID   int,  
 BillingDefinitionInvoiceLineID  int)
  
 create index inx_tmpBDLines1 on #tmpBDLines (BillingDefinitionInvoiceLineID)
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Build invoice data...Cycle thru:  
-- BillingInvoice  
-- BillingInvoiceLine  
-- BillingInvoiceDetail  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
  
-- BillingInvoice variables  
declare @ClientID      int,  
  @BillingScheduleID    int,  
  @Name_bi      nvarchar(50),  
  @Description_bi     nvarchar(255),  
  @AccountingSystemCustomerNumber nvarchar(7),  
  @AccountingSystemAddressCode nvarchar(4),  
  @POPrefix      nvarchar(15),  
  @PONumber      nvarchar(15),  
  @InvoiceTypeID     int,  
  @InvoiceTemplateID    int,  
  @ScheduleDate_bi    datetime,  
  @ScheduleRangeTypeID_bi    int,  
  @ScheduleRangeBegin_bi   datetime,  
  @ScheduleRangeEnd_bi   datetime,  
  @InvoiceStatusID    int,  
  @InvoiceReferenceNumber   nvarchar(50),  
  @InvoiceNumber     nvarchar(7),  
  @Sequence_bi     int,  
  @IsActive_bi     bit,  
  @CanAddLines     bit  
  
-- BillingInvoiceLine variables  
declare @ProductID      int,  
  @RateTypeID      int,  
  @Name_bil      nvarchar(50),  
  @Description_bil    nvarchar(255),  
  @Comment      nvarchar(30),  
  @AccountingSystemGLCode   nvarchar(50),  
  @LineQuantity     int,  
  @LineCost      money,  
  @LineAmount      money,  
  @InvoiceLineStatusID   int,  
  @AccountingSystemItemCode  nvarchar(14),  
  @Sequence_bil     int,  
  @IsActive_bil     bit  
    
-- BillingInvoiceDetail variables  
declare @ProgramID_bdile    int,  
  @Name_bdile      nvarchar(50),  
  @Description_bdile    nvarchar(255),  
  @Sequence_bdile     int,  
  @IsActive_bdile     bit  
 
  
-- Cycle thru  
-------------------------------  
while @InvoiceRowToCreate<=@NumOfInvoicesToCreate  
begin -- <Invoice  
  
 -- Get the Invoice Definition ID  
 select @BillingDefinitionInvoiceID = BillingDefinitionInvoiceID  
 from #tmpInvoices  
 where RowID = @InvoiceRowToCreate  
  
 if @Debug = 0  
 begin  
  
  -- First Delete data  
  -------------------------------  
  -- BillingInvoiceLine  
  delete dbo.BillingInvoiceLine  
  from dbo.BillingInvoiceLine bil  
  join BillingInvoice bi on bi.ID = bil.BillingInvoiceID  
  join BillingDefinitionInvoice bdi on bdi.ID = bi.BillingDefinitionInvoiceID  
  join #tmpOpenSchedule O on O.BillingScheduleID = bi.BillingScheduleID -- In Open Schedule  
  where BillingDefinitionInvoiceID = @BillingDefinitionInvoiceID -- Invoice definition from parameter  
  
  -- BillingInvoice  
  delete dbo.BillingInvoice  
  from BillingInvoice bi  
  join BillingDefinitionInvoice bdi on bdi.ID = bi.BillingDefinitionInvoiceID  
  join #tmpOpenSchedule O on O.BillingScheduleID = bi.BillingScheduleID -- In Open Schedule  
  where BillingDefinitionInvoiceID = @BillingDefinitionInvoiceID -- Invoice definition from parameter  
  
 end  
  
  
 -- BillingInvoice  
 ------------------------------------  
 -- Get  
 select @ClientID = bdi.ClientID,  
   @BillingScheduleID = O.BillingScheduleID,  
   @Name_bi = bdi.Name,  
   @Description_bi = bdi.[Description],  
   @POPrefix =  bdi.POPrefix,  
   @AccountingSystemCustomerNumber = bdi.AccountingSystemCustomerNumber,  
   @AccountingSystemAddressCode = bdi.AccountingSystemAddressCode,  
   @PONumber =  bdi.PONumber,  
   @InvoiceTypeID =  bdi.InvoiceTypeID,  
   @InvoiceTemplateID =  bdi.InvoiceTemplateID,  
   @ScheduleDate_bi =  bs.ScheduleDate,  
   @ScheduleRangeTypeID_bi =  bs.ScheduleRangeTypeID,  
   @ScheduleRangeBegin_bi =  bs.ScheduleRangeBegin,  
   @ScheduleRangeEnd_bi =  bs.ScheduleRangeEnd,  
   @InvoiceStatusID =  bdi.DefaultInvoiceStatusID, -- InvoiceStatusID, set to Default  
   @InvoiceReferenceNumber = null, -- Set Later  
   @InvoiceNumber =  null, -- Set later  
   @Sequence_bi =  bdi.Sequence,  
   @IsActive_bi =  bdi.IsActive,  
   @CanAddLines = bdi.CanAddLines  
 from dbo.BillingDefinitionInvoice bdi with (nolock)  
 join #tmpOpenSchedule O on O.ScheduleTypeID = bdi.ScheduleTypeID -- Open Schedule  
   and O.ScheduleDateTypeID = bdi.ScheduleDateTypeID  
   and O.ScheduleRangeTypeID = bdi.ScheduleRangeTypeID  
 join dbo.BillingSchedule bs with (nolock) on bs.ID = O.BillingScheduleID  
 join dbo.BillingInvoiceType bty with (nolock) on bty.ID = bdi.InvoiceTypeID  
 join dbo.BillingInvoiceTemplate bte with (nolock) on bte.ID = bdi.InvoiceTemplateID  
 join dbo.BillingScheduleRangeType bsrt with (nolock) on bsrt.ID = bs.ScheduleRangeTypeID   
 where 1=1  
 and  bdi.ID = @BillingDefinitionInvoiceID  
  
  
 if @Debug = 1  
 begin  
   
  select 'InvoiceData >>>',  
    @ClientID as ClientID,  
    @BillingScheduleID as BillingScheduleID,  
    @Name_bi as Name_bi,  
    @Description_bi as Description_bi,  
    @AccountingSystemAddressCode as AccountingSystemAddressCode,  
    @POPrefix as POPrefix,  
    @PONumber as PONumber,  
    @InvoiceTypeID as InvoiceTypeName,  
    @InvoiceTemplateID as InvoiceTemplateName,  
    @InvoiceDate as InvoiceDate,  
    @ScheduleDate_bi as ScheduleDate_bi,  
    @ScheduleRangeTypeID_bi as ScheduleRange_bi,  
    @ScheduleRangeBegin_bi as ScheduleRangeBegin_bi,  
    @ScheduleRangeEnd_bi as ScheduleRangeEnd_bi,  
    @InvoiceStatusID as InvoiceStatusID,  
    @InvoiceReferenceNumber as InvoiceReferenceNumber,  
    @InvoiceNumber as InvoiceNumber,  
    @Sequence_bi as Sequence_bi,  
    @IsActive_bi as IsActive_bi,  
    @CanAddLines as CanAddLines  
 end  
 else  
 begin  
   
  -- Insert  
  insert into dbo.BillingInvoice  
  (ClientID,  
   BillingScheduleID,  
   Name,  
   [Description],  
   AccountingSystemCustomerNumber,  
   AccountingSystemAddressCode,  
   POPrefix,  
   PONumber,  
   InvoiceTypeID,  
   InvoiceTemplateID,  
   InvoiceDate,  
   ScheduleDate,  
   ScheduleRangeTypeID,  
   ScheduleRangeBegin,  
   ScheduleRangeEnd,  
   InvoiceStatusID,  
   InvoiceReferenceNumber,  
   InvoiceNumber,  
   CanAddLines,  
   BillingDefinitionInvoiceID,  
   Sequence,  
   IsActive,  
   CreateDate,  
   CreateBy,  
   ModifyDate,  
   ModifyBy  
  )  
  select @ClientID, -- ClientID  
    @BillingScheduleID, -- BillingScheduleID  
    @Name_bi, -- Name  
    @Description_bi, -- [Description]  
    @AccountingSystemCustomerNumber,  
    @AccountingSystemAddressCode, -- AccountingSystemAddressCode  
    @POPrefix, -- POPrefix  
    @PONumber, -- PONumber  
    @InvoiceTypeID, -- InvoiceTypeName  
    @InvoiceTemplateID, -- InvoiceTemplateName  
    @InvoiceDate, -- InvoiceDate  
    @ScheduleDate_bi, -- ScheduleDate  
    @ScheduleRangeTypeID_bi, -- ScheduleRange  
    @ScheduleRangeBegin_bi, -- ScheduleRangeBegin  
    @ScheduleRangeEnd_bi, -- ScheduleRangeEnd  
    @InvoiceStatusID, -- InvoiceStatusID  
    @InvoiceReferenceNumber, -- InvoiceReferenceNumber  
    @InvoiceNumber, -- InvoiceNumber  
    @CanAddLines, -- CanAddLines  
    @BillingDefinitionInvoiceID, -- BillingDefinitionInvoiceID  
    @Sequence_bi, -- Sequence  
    @IsActive_bi, -- IsActive  
    @Now, -- CreateDate  
    @ProgramName, -- CreateBy  
    null, -- ModifyDate  
    null -- ModifyBy  
    
  select @BillingInvoiceID = @@identity  
    
 end  
  
 -- BillingInvoiceLine  
 ------------------------------------  
 -- Get distinct lines to create for the invoice
 -- ^3 : Exclude those lines that are IsActive = 0
 insert into #tmpBDLines  
 (BillingDefinitionInvoiceID,  
  BillingDefinitionInvoiceLineID)  
 select distinct  
   bid.BillingDefinitionInvoiceID,  
   bid.BillingDefinitionInvoiceLineID
 from dbo.BillingInvoiceDetail bid with (nolock)  
 join dbo.BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID
 join dbo.BillingDefinitionInvoiceLine bdil with (nolock) on bdil.ID = bid.BillingDefinitionInvoiceLineID -- ^3
 where	1=1
 and	bid.BillingDefinitionInvoiceID = @BillingDefinitionInvoiceID -- Invoice in cycle  
 and	bdil.IsActive = 1 -- ^3 Exclude those lines that are IsActive = 0
 
 
 if @Debug = 1  
 begin  
   
  select '#tmpBDLines', * from #tmpBDLines  
 end  


 -- Get a count of the Lines to create
 select @NumOfLinesToCreate = count(*) from #tmpBDLines
  
  
 while @InvoiceLineRowToCreate<=@NumOfLinesToCreate  
 begin -- <Line  
   
 -- Get  
 select @ProductID = bdil.ProductID,  
   @RateTypeID = bdil.RateTypeID,  
   @Name_bil = bdil.Name,  
   @Description_bil = bdil.[Description],  
   @Comment = bdil.Comment,  
   @AccountingSystemGLCode = pr.AccountingSystemGLCode,    
   @Sequence_bil = bdil.Sequence,  
   @IsActive_bil = bdil.IsActive,  
   @BillingDefinitionInvoiceLineID = bdil.ID,  
   @AccountingSystemItemCode = pr.AccountingSystemItemCode,  
   @InvoiceLineStatusID = bdil.DefaultInvoiceLineStatusID  
 from dbo.BillingDefinitionInvoiceLine bdil  
 join dbo.Product pr on pr.ID = bdil.ProductID  
 join #tmpBDLines t on t.BillingDefinitionInvoiceID = bdil.BillingDefinitionInvoiceID  
 and  t.BillingDefinitionInvoiceLineID = bdil.ID  
 where t.RowID = @InvoiceLineRowToCreate   
   
 if @Debug = 1  
 begin  
   
  select   
    'LineData >>>',  
    @ProductID as ProductID,  
    @RateTypeID as RateTypeID,  
    @Name_bil as Name,  
    @Description_bil as [Description],  
    @Comment as Comment,  
    @AccountingSystemGLCode as AccountingSystemGLCode,  
    @AccountingSystemItemCode as AccountingSystemItemCode,  
    @Sequence_bil as Sequence,  
    @IsActive_bil as IsActive,  
    @BillingDefinitionInvoiceLineID as BillingDefinitionInvoiceLineID,  
    @AccountingSystemItemCode as AccountingSystemItemCode   
 end  
 else  
 begin  
    
  -- Insert  
  insert into dbo.BillingInvoiceLine  
  (BillingInvoiceID,  
   ProductID,  
   RateTypeID,  
   Name,  
   [Description],  
   Comment,  
   AccountingSystemGLCode,  
   LineQuantity,  
   LineCost,  
   LineAmount,  
   InvoiceLineStatusID,  
   BillingDefinitionInvoiceLineID,  
   AccountingSystemItemCode,  
   Sequence,  
   IsActive,  
   CreateDate,  
   CreateBy,  
   ModifyDate,  
   ModifyBy  
  )  
  select @BillingInvoiceID, -- BillingInvoiceID  
    @ProductID, -- ProductID  
    @RateTypeID, -- RateTypeID  
    @Name_bil, -- Name  
    @Description_bil, -- [Description]  
    @Comment,  
    @AccountingSystemGLCode,  
    ----------- Line Quantity ---------------  
    isnull(  
     (select sum(Quantity)  
      from dbo.BillingInvoiceDetail with (nolock)  
      where BillingDefinitionInvoiceLineID = @BillingDefinitionInvoiceLineID  
      and BillingScheduleID = @BillingScheduleID -- In Cycle  
      and InvoiceDetailStatusID = @BillingCode_DetailStatus_READY  -- READY only  
--      and ExcludeDate is null) -- and Not Excluded  
      and  isnull(IsExcluded, 0) = 0) -- 10/28/2013 : MJK use the IsExcluded bit
     , 0),  
  
    ----------- Line Cost --------------- 

    (select case
			 when rt.Name = 'PercentageEach' then null    -- ^1 : When PercentageEach, put in null
			 else bdil.Rate
			end
     from	dbo.BillingDefinitionInvoiceLine bdil with (nolock)
     left outer join dbo.RateType rt with (nolock) on rt.ID = bdil.RateTypeID
     where bdil.ID = @BillingDefinitionInvoiceLineID),
  
    ----------- Line Amount ---------------  
    isnull(  
    (select sum(case  
--        when AdjustmentDate is not null then AdjustmentAmount -- Adjusted  -- 10/28/2013 : MJK use the IsAdjusted bit
		when IsAdjusted = 1 then AdjustmentAmount
        else EventAmount -- Not Adjusted  
       end)  
     from dbo.BillingInvoiceDetail with (nolock)  
     where BillingDefinitionInvoiceLineID = @BillingDefinitionInvoiceLineID  
     and BillingScheduleID = @BillingScheduleID -- In Cycle  
     and InvoiceDetailStatusID = @BillingCode_DetailStatus_READY  -- READY only  
--     and ExcludeDate is null -- 10/28/2013 : MJK use the IsExcluded bit
	 and isnull(IsExcluded, 0) = 0
	 ) -- not Excluded  
     , 0.00  
    ),  
      
    @InvoiceLineStatusID, -- CREATE as default  
    @BillingDefinitionInvoiceLineID,  
    @AccountingSystemItemCode,  
    @Sequence_bil,  
    @IsActive_bil,  
    @Now, -- CreateDate  
    @ProgramName, -- CreateBy  
    null, -- ModifyDate  
    null -- ModifyBy  
  
  select @BillingInvoiceLineID = @@identity  
    
 end   
  
  -- Set the BillingInvoiceLineID on the Detail Record   
  -- Links the line and detail  
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
  update dbo.BillingInvoiceDetail  
  set  BillingInvoiceLineID = @BillingInvoiceLineID  
  from dbo.BillingInvoiceDetail with (nolock)  
  where BillingDefinitionInvoiceID = @BillingDefinitionInvoiceID -- Invoice in cycle  
  and  BillingDefinitionInvoiceLineID = @BillingDefinitionInvoiceLineID -- Line  
  and  BillingScheduleID = @BillingScheduleID -- In Cycle  
  
  -- Establish the Line Status  
  -- Lines are not READY if there are any PENDINGs  
  -- or EXCEPTIONs - Set these to PENDING else READY  
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
  update dbo.BillingInvoiceLine  
  set  InvoiceLineStatusID = case  
          when MakePENDING > 0 then @BillingCode_LineStatus_PENDING  
          else @BillingCode_LineStatus_READY  
          end  
  from dbo.BillingInvoiceLine bil with (nolock)  
  join  
  
   (select BillingInvoiceLineID,  
     sum(case  
       when InvoiceDetailStatusID in   
        (@BillingCode_DetailStatus_PENDING,  
         @BillingCode_DetailStatus_EXCEPTION)  
       then 1  
      else 0  
      end) as MakePENDING  
    from dbo.BillingInvoiceDetail bid with (nolock)  
    join dbo.BillingInvoiceLine bil with (nolock) on bil.ID = bid.BillingInvoiceLineID  
    where bil.BillingInvoiceID = @BillingInvoiceID -- This invoice  
    and bil.ID = @BillingInvoiceLineID -- This Line  
    group by  
    BillingInvoiceLineID) as MP on MP.BillingInvoiceLineID = bil.ID  
  
  
  -- ^4 - Do not Create Lines that have no details
  -- 1. Get the detail count for the line
  -- 2. If there are no details, then delete the line
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  select	@InvoiceLineDetailCount = count(*)
  from		BillingInvoiceDetail
  where		BillingInvoiceLineID = @BillingInvoiceLineID
    
  print 'BillingInvoiceLineID: ' + convert(nvarchar(10), @BillingInvoiceLineID)  
  print 'InvoiceLineDetailCount: ' + convert(nvarchar(10), @InvoiceLineDetailCount)  
  print 'Will Invoice Line be created: ' + case when @InvoiceLineDetailCount = 0 then 'NO' else 'YES' end
  print ' '
  print ' '  
  
  -- Process Delete
  if @InvoiceLineDetailCount = 0
  begin
  
	delete	BillingInvoiceLine
	where	ID = @BillingInvoiceLineID	
  
  end
  
  
  -- Set the Count back to zero
  select	@InvoiceLineDetailCount = 0
  
  -- Increment Counter  
  select @InvoiceRowToCreate = @InvoiceRowToCreate + 1  
  
  -- Increment Counter  
  select @InvoiceLineRowToCreate = @InvoiceLineRowToCreate + 1   
   
 end --<Line  
  
  
 -- Establish the Invoice Status  
 -- Invoices are not READY if there are any PENDING  
 -- Lines.  Else READY  
 -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  
 update dbo.BillingInvoice  
 set  InvoiceStatusID = case  
        when MakePENDING > 0 then @BillingCode_InvoiceStatus_PENDING  
        else @BillingCode_InvoiceStatus_READY  
        end  
 from dbo.BillingInvoice bi with (nolock)  
 join  
  
  (select BillingInvoiceID,  
    sum(case  
      when InvoiceLineStatusID = @BillingCode_LineStatus_PENDING   
      then 1  
     else 0  
     end) as MakePENDING  
   from dbo.BillingInvoiceLine with (nolock)  
   where BillingInvoiceID = @BillingInvoiceID  
   group by  
   BillingInvoiceID) as MP on MP.BillingInvoiceID = bi.ID  
  
  
  -- ^5 - Do not Create Invoices that have no details
  -- 1. Get the detail count for the Invoice
  -- 2. If there are no details, then delete the Invoice
  -- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  select	@InvoiceDetailCount = count(*)
  from		BillingInvoiceDetail bid
  join		BillingInvoiceLine bil on bil.ID = bid.BillingInvoiceLineID
  join		BillingInvoice bi on bi.ID = bil.BillingInvoiceID
  where		BillingInvoiceID = @BillingInvoiceID
  
  
  print 'BillingInvoiceID: ' + convert(nvarchar(10), @BillingInvoiceID)  
  print 'InvoiceDetailCount: ' + convert(nvarchar(10), @InvoiceDetailCount)  
  print 'Will Invoice Line be created: ' + case when @InvoiceDetailCount = 0 then 'NO' else 'YES' end
  print ' '
  print ' '

  -- Process Delete
  if @InvoiceDetailCount = 0
  begin
  
	delete	BillingInvoice
	where	ID = @BillingInvoiceID	
  
  end
  
  
  -- Set the Count back to zero
  select	@InvoiceDetailCount = 0

  
 -- Increment Counter  
 select @InvoiceRowToCreate = @InvoiceRowToCreate + 1  
  
  
end -- <Invoice  
  
  
  
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
-- Process Exceptions  
--   
--   
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -   
  
print 'Processing Exceptions'  
  
exec dbo.dms_BillingDetailExceptions_Get @pUserName, @pScheduleTypeID, @pScheduleDateTypeID, @pScheduleRangeTypeID, @pInvoicesXML
GO

