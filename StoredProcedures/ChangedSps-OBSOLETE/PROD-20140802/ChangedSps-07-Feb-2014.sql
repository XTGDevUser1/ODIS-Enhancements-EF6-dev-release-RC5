
/****** Object:  StoredProcedure [dbo].[dms_BillingGenerateBillingDetails]    Script Date: 10/23/2013 04:40:25 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_BillingGenerateBillingDetails]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_BillingGenerateBillingDetails]
GO

/****** Object:  StoredProcedure [dbo].[dms_BillingGenerateBillingDetails]    Script Date: 10/23/2013 04:40:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[dms_BillingGenerateBillingDetails]
@pUserName as nvarchar(50),
@pBillingEvents as BillingDefinitionInvoiceLineEventsTableType READONLY
AS
/********************************************************************
 **
 **	dms_BillingGenerateBillingDetails
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/16/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**


**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@ProgramName as nvarchar(50),
		@Now as datetime,
		@RowToProcess as int,
		@NumRowsToProcess as int,
		@BillingDefinitionInvoiceID as int,
		@BillingDefinitionInvoiceLineID as int,
		@BillingDefinitionEventID as int,
		@BillingScheduleID as int,
		@Name as nvarchar(50),
		@Description as nvarchar(255),
		@ProductID as int,
		@AccountingSystemItemCode as nvarchar(14),
		@AccountingSystemGLCode	as nvarchar(50),
		@RateTypeName as nvarchar(50),
		@Rate as money,
		@FixedQuantity as int,
		@EventFilter as nvarchar(2000),
		@DBObject as nvarchar(255),
		@DefaultInvoiceDetailStatusID		int,
		@IsAdjustable						bit,
		@IsExcludable						bit,
		@ScheduleDate as datetime,
		@ScheduleRangeBeginDate as datetime,
		@ScheduleRangeEndDate as datetime,
		@SQLString as nvarchar(max),
		@BillingEventPrograms as BillingDefinitionProgramsTableType,
		@ParmDefinition as nvarchar(2000),
		@ReviewRequired as bit,
		@AmountIsAdjustable as bit,
		@BillingCode_DetailDisposition_REFRESH as int,
		@BillingCode_DetailDisposition_LOCKED as int,
		@BillingCode_DetailStatus_DELETE as int,
		@BillingCode_DetailStatus_POSTED as int,
		@BillingDefinitionInvoiceLineSequence as int,
		@UserName as nvarchar(50),
		@IsAdjusted as bit,
		@IsExcluded as bit,
		@IsEditable as bit
		

-- Initialize Local Variables
select	@Debug = 0
select	@Now = getdate()
select	@ProgramName = object_name(@@procid)
select	@RowToProcess = 1
select	@NumRowsToProcess = 0
select	@SQLString = ' '
select	@ParmDefinition = ' '


-- Capture Billing Codes to use
select	@BillingCode_DetailDisposition_REFRESH = ID from dbo.BillingInvoiceDetailDisposition where Name = 'REFRESH'
select	@BillingCode_DetailDisposition_LOCKED = ID from dbo.BillingInvoiceDetailDisposition where Name = 'LOCKED'
select	@BillingCode_DetailStatus_DELETE = ID from dbo.BillingInvoiceDetailStatus where Name = 'DELETED'
select	@BillingCode_DetailStatus_POSTED = ID from dbo.BillingInvoiceDetailStatus where Name = 'POSTED'


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Capture the user name.  If null, then get from the
-- ProgramName
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
if @pUserName is null
begin
		select @UserName = @ProgramName
end
else
begin
		select @UserName = @pUserName
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Capture the Columns from Billing Events Table parameter
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -(
if object_id('tempdb..#tmpBillingEvents', 'U') is not null drop table #tmpBillingEvents
create table #tmpBillingEvents
(BillingDefinitionInvoiceID int null,
 BillingDefinitionInvoiceLineID int null,
 BillingDefinitionInvoiceLineEventID int null
)

insert into #tmpBillingEvents
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionInvoiceLineEventID)
select	BillingDefinitionInvoiceID,
		BillingDefinitionInvoiceLineID,
		BillingDefinitionInvoiceLineEventID
from	@pBillingEvents

if @Debug = 1
begin

select	@BillingCode_DetailStatus_DELETE as '@BillingCode_DetailStatus_DELETE',
		@BillingCode_DetailDisposition_REFRESH as '@BillingCode_DetailDisposition_REFRESH'

 select '#tmpBillingEvents', * from #tmpBillingEvents

end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Capture the Open Schedule for the Definitions passed in 
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
if object_id('tempdb..#tmpDefOpenSchedules', 'U') is not null drop table #tmpDefOpenSchedules
create table #tmpDefOpenSchedules
(BillingDefinitionInvoiceID	int,
 BillingScheduleID			int,
 ScheduleTypeID				int,
 ScheduleDateTypeID			int,
 ScheduleRangeTypeID		int,
 ScheduleDate				datetime, 
 ScheduleRangeBegin			datetime,
 ScheduleRangeEnd			datetime,
 IsEditable					bit)

create index inx_tmpDefOpenSchedules1 on #tmpDefOpenSchedules (BillingDefinitionInvoiceID)

insert into #tmpDefOpenSchedules
(BillingDefinitionInvoiceID,
 BillingScheduleID,
 ScheduleTypeID,
 ScheduleDateTypeID,
 ScheduleRangeTypeID,
 ScheduleDate, 
 ScheduleRangeBegin,
 ScheduleRangeEnd,
 IsEditable)
select	bdi.ID, -- BillingDefinitionInvoiceID
		bs.ID, -- BillingScheduleID
		bs.ScheduleTypeID,
		bs.ScheduleDateTypeID,
		bs.ScheduleRangeTypeID,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bdile.IsEditable
from	dbo.BillingSchedule bs
join	dbo.BillingScheduleStatus bss on bss.ID = bs.ScheduleStatusID
join	dbo.BillingDefinitionInvoice bdi on bdi.ScheduleTypeID = bs.ScheduleTypeID
		and bdi.ScheduleDateTypeID = bs.ScheduleDateTypeID
		and bdi.ScheduleRangeTypeID = bs.ScheduleRangeTypeID
join
		(select	distinct BillingDefinitionInvoiceID
		 from	#tmpBillingEvents) D on D.BillingDefinitionInvoiceID = bdi.ID
left join	dbo.BillingDefinitionInvoiceLine bdil with (nolock) on bdil.BillingDefinitionInvoiceID = bdi.ID
		 
left join	dbo.BillingDefinitionInvoiceLineEvent bdile with (nolock) on 
		 bdile.BillingDefinitionInvoiceLineID = bdil.ID
		 
where	bss.Name = 'OPEN'


if @Debug = 1
begin
 select '#tmpDefOpenSchedules', * from #tmpDefOpenSchedules
end



-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get Billing Invoice Meta data...this identifys the
-- breadth of how many invoice/line/details to create
-- This meta data temp table contains those elements
-- that will be taken from the definitions
-- and pushed over to the invoice detail table
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpBillingInvoiceMeta', 'U') is not null drop table #tmpBillingInvoiceMeta
create table #tmpBillingInvoiceMeta
(RowID								int					identity,
 BillingDefinitionInvoiceID			int,
 BillingDefinitionInvoiceLineID		int,
 BillingDefinitionEventID			int,
 BillingScheduleID					int,
 Name								nvarchar(50),
 [Description]						nvarchar(255),
 ProductID							int,
 AccountingSystemItemCode			nvarchar(14),
 AccountingSystemGLCode				nvarchar(50),
 RateTypeName						nvarchar(50),
 Rate								money,
 FixedQuantity						int,
 EventFilter						nvarchar(2000),
 DBObject							nvarchar(255),
 DefaultInvoiceDetailStatusID		int,
 IsAdjustable						bit,
 IsExcludable						bit,
 ScheduleDate						datetime,
 ScheduleRangeBeginDate				datetime,
 ScheduleRangeEndDate				datetime,
 BillingDefinitionInvoiceLineSequence		int,
 IsEditable							bit
)

insert into #tmpBillingInvoiceMeta
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionEventID,
 BillingScheduleID,
 Name,
 [Description],
 ProductID,
 AccountingSystemItemCode,
 AccountingSystemGLCode,
 RateTypeName,
 Rate,
 FixedQuantity,
 EventFilter,
 DBObject,
 DefaultInvoiceDetailStatusID,
 IsAdjustable,
 IsExcludable,
 ScheduleDate,
 ScheduleRangeBeginDate,
 ScheduleRangeEndDate,
 BillingDefinitionInvoiceLineSequence,
 IsEditable)
select	bdi.ID, -- BillingDefinitionInvoiceID
		bdil.ID, -- BillingDefinitionInvoiceLineID
		bde.ID, -- BillingDefinitionEventID
		O.BillingScheduleID, -- BillingScheduleID
		bdile.Name,
		bdile.[Description],
		bdil.ProductID,
		pr.AccountingSystemItemCode,
		pr.AccountingSystemGLCode,
		rt.Name, -- RateTypeName
		bdil.Rate,
		bdil.FixedQuantity,
		bdile.EventFilter,
		bde.DBObject,
		bdile.DefaultInvoiceDetailStatusID,
		bdile.IsAdjustable,
		bdile.IsExcludable,
		O.ScheduleDate, 
		O.ScheduleRangeBegin,
		O.ScheduleRangeEnd,
		bdil.Sequence, -- BillingDefinitionInvoiceLineSequence
		bdile.IsEditable
from	dbo.BillingDefinitionInvoice bdi
join	dbo.BillingDefinitionInvoiceLine bdil on bdil.BillingDefinitionInvoiceID = bdi.ID
join	dbo.BillingDefinitionInvoiceLineEvent bdile on bdile.BillingDefinitionInvoiceLineID = bdil.ID
join	dbo.BillingDefinitionEvent bde on bde.ID = bdile.BillingDefinitionEventID
join	dbo.RateType rt on rt.ID = bdil.RateTypeID
join	dbo.Product pr on pr.ID = bdil.ProductID
join	#tmpDefOpenSchedules O on O.BillingDefinitionInvoiceID = bdi.ID
		and O.ScheduleTypeID = bdi.ScheduleTypeID
		and	O.ScheduleDateTypeID = bdi.ScheduleDateTypeID
		and O.ScheduleRangeTypeID = bdi.ScheduleRangeTypeID
join	#tmpBillingEvents t on t.BillingDefinitionInvoiceID = bdi.ID -- Get the Programs to load
		and t.BillingDefinitionInvoiceLineID = bdil.ID
		and t.BillingDefinitionInvoiceLineEventID = bdile.ID
order by
		bdi.ID,
		bdil.Sequence


if @Debug = 1
begin
 select '#tmpBillingInvoiceMeta', * from #tmpBillingInvoiceMeta
end



-- Set the Number of Rows to Process
select	@NumRowsToProcess = count(*) from #tmpBillingInvoiceMeta

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Cycle thru the invoice Meta and 
-- Create Invoice Detail Data
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpEventData', 'U') is not null drop table #tmpEventData
create table #tmpEventData
(ProgramID									int,
 EntityID									int,
 EntityKey									nvarchar(50),
 EntityDate									datetime,
 BaseQuantity								int,
 BaseAmount									money,
 BasePercentage								float,
 ---
 ServiceCode								nvarchar(50),
 BillingCode								nvarchar(50)
 )


if object_id('tempdb..#tmpInvoiceDetail', 'U') is not null drop table #tmpInvoiceDetail
create table #tmpInvoiceDetail
(RowID									int			identity,
 BillingDefinitionInvoiceID				int,
 BillingDefinitionInvoiceLineID			int,
 BillingDefinitionEventID				int,
 BillingScheduleID						int,
 ProgramID								int,
 EntityID								int,
 EntityKey								nvarchar(50),
 EntityDate								datetime,
 Name									nvarchar(50),
 [Description]							nvarchar(255),
 ---
 ServiceCode							nvarchar(50),
 BillingCode							nvarchar(50),
 ProductID								int,
 AccountingSystemItemCode				nvarchar(14),
 AccountingSystemGLCode					nvarchar(50),
 RateTypeName							nvarchar(50),
 Quantity								int,
 EventAmount							money,
 
 -- Status Cols
 InvoiceDetailStatusID					int, -- BillingInvoiceDetailStatus
 InvoiceDetailStatusAuthorization		nvarchar(100),
 InvoiceDetailStatusAuthorizationDate	datetime,

-- Disposition Cols
 InvoiceDetailDispositionID				nvarchar(50), -- BillingInvoiceDetailDisposition

 -- Adjustment Cols
 IsAdjustable							bit,
 AdjustmentReasonID						int, -- BillingAdjustmentReason
 AdjustmentReasonOther					nvarchar(50),
 AdjustmentComment						nvarchar(max),
 AdjustedBy								nvarchar(50),
 AdjustmentDate							datetime,
 AdjustmentAmount						money,
 AdjustmentAuthorization				nvarchar(100),
 AdjustmentAuthorizationDate			datetime,
 
 -- Exclude From Invoice Cols
 IsExcludable							bit,
 ExcludeReasonID						int, -- BillingExcludeReason
 ExcludeReasonOther						nvarchar(50),
 ExcludeComment							nvarchar(max),
 ExcludedBy								nvarchar(50),
 ExcludeDate							datetime,
 ExcludeAuthorization					nvarchar(100),
 ExcludeAuthorizationDate				datetime,


 BillingInvoiceLineID					int, -- brought over when invoice finalized
 
 Sequence								int,
 IsActive								bit,
 CreateDate								datetime,
 CreateBy								nvarchar(50),
 ModifyDate								datetime,
 ModifyBy								nvarchar(50),
 
 BaseQuantity							int,
 BaseAmount								money,
 BasePercentage							money,
 Rate									money,

 IsAdjusted								bit,
 IsExcluded								bit,
 IsEditable								bit
)


while @RowToProcess <= @NumRowsToProcess
begin

	print 'Start Cycle Here'
	print ' '

	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- Capture Programs that are associated to
	-- the  Billing Event Line
	-- Put into a Table parameter...these will be passed to
	-- the Event DBObject
	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	delete	@BillingEventPrograms
	insert into @BillingEventPrograms
	(ProgramID)
	select	bdilep.ProgramID
	from	#tmpBillingInvoiceMeta t
	join	BillingDefinitionInvoiceLineEvent bdile on bdile.BillingDefinitionInvoiceLineID = t.BillingDefinitionInvoiceLineID
	and		bdile.BillingDefinitionEventID = t.BillingDefinitionEventID
	join	BillingDefinitionInvoiceLineEventProgram bdilep on bdilep.BillingDefinitionInvoiceLineEventID = bdile.ID
	where	RowID = @RowToProcess

	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- Get all other data elements from the meta data and
	-- save into local variables
	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	select	@BillingDefinitionInvoiceID = BillingDefinitionInvoiceID,
			@BillingDefinitionInvoiceLineID = BillingDefinitionInvoiceLineID,
			@BillingDefinitionEventID = BillingDefinitionEventID,
			@BillingScheduleID = BillingScheduleID,
			@Name = Name,
			@Description = [Description],
			@ProductID = ProductID,
			@AccountingSystemItemCode = AccountingSystemItemCode,
			@AccountingSystemGLCode	= AccountingSystemGLCode,
			@RateTypeName = RateTypeName,
			@Rate = Rate,
			@FixedQuantity = FixedQuantity,
			@EventFilter = EventFilter,
			@DBObject = DBObject,
			@DefaultInvoiceDetailStatusID = DefaultInvoiceDetailStatusID,
			@IsAdjustable = IsAdjustable,
			@IsExcludable = IsExcludable,
			@ScheduleRangeBeginDate = ScheduleRangeBeginDate,
			@ScheduleRangeEndDate = ScheduleRangeEndDate,
			@BillingDefinitionInvoiceLineSequence = BillingDefinitionInvoiceLineSequence,
			@IsEditable = IsEditable
	from	#tmpBillingInvoiceMeta
	where	RowID = @RowToProcess


	if @Debug = 1
	begin
		select	'MetaData:',
				@BillingDefinitionInvoiceID as BillingDefinitionInvoiceID,
				@BillingDefinitionInvoiceLineID as BillingDefinitionInvoiceLineID,
				@BillingDefinitionEventID as BillingDefinitionEventID,
				@BillingScheduleID as BillingScheduleID,
				@Name as Name,
				@Description as [Description],
				@RateTypeName as RateTypeName,
				@Rate as Rate,
				@FixedQuantity as FixedQuantity,
				@ProductID as ProductID,
				@AccountingSystemItemCode as AccountingSystemItemCode,
				@AccountingSystemGLCode	as AccountingSystemGLCode,
				@EventFilter as EventFilter,
				@DBObject as DBObject,
				@DefaultInvoiceDetailStatusID as DefaultInvoiceDetailStatusID,
				@IsAdjustable as IsAdjustable,
				@IsExcludable as IsExcludable,
				@ScheduleDate as ScheduleDate,
				@ScheduleRangeBeginDate as ScheduleRangeBeginDate,
				@ScheduleRangeEndDate as ScheduleRangeEndDate,
				@BillingDefinitionInvoiceLineSequence as BillingDefinitionInvoiceLineSequence,
				@IsEditable as IsEditable

		select '@BillingEventPrograms', * from @BillingEventPrograms
		
	end


	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	-- Execute the Event DBObject to get events
	-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	-- Create the SQL String that we will exec to get the detailed events
	select	@SQLString = @SQLString + N'insert into #tmpEventData '
	select	@SQLString = @SQLString + N'(ProgramID, '
	select	@SQLString = @SQLString + N'EntityID, '
	select	@SQLString = @SQLString + N'EntityKey, '
	select	@SQLString = @SQLString + N'EntityDate, '
	select	@SQLString = @SQLString + N'BaseQuantity, '
	select	@SQLString = @SQLString + N'BaseAmount, '
	select	@SQLString = @SQLString + N'BasePercentage, '
	select	@SQLString = @SQLString + N'ServiceCode, '
	select	@SQLString = @SQLString + N'BillingCode) '
	select	@SQLString = @SQLString + N'exec ' + @DBObject + ' @BillingEventPrograms, @ScheduleRangeBeginDate, @ScheduleRangeEndDate, @EventFilter'

	select @ParmDefinition = @ParmDefinition + N'@DBObject as nvarchar(255), '
	select @ParmDefinition = @ParmDefinition + N'@BillingEventPrograms as BillingDefinitionProgramsTableType READONLY, '
	select @ParmDefinition = @ParmDefinition + N'@ScheduleRangeBeginDate as datetime,   '
	select @ParmDefinition = @ParmDefinition + N'@ScheduleRangeEndDate as datetime,  '
	select @ParmDefinition = @ParmDefinition + N'@EventFilter as nvarchar(2000)'


	if @Debug = 1
	begin
		
		select	@SQLString as '@SQLString'

	end
	
	print @DBObject
	print ' '
	print 'String Build Execute Next statement'
	print ' '
	
	-- Get data
	exec sp_executesql @SQLString, @ParmDefinition, @DBObject, @BillingEventPrograms, @ScheduleRangeBeginDate, @ScheduleRangeEndDate, @EventFilter
	select	@SQLString = ' '
	select	@ParmDefinition = ' '
	
	print 'Execute just happened'
	print ' '
	

	if @Debug = 1
	begin
	
		select	'#tmpEventData', * from #tmpEventData

	end		

	-- Insert into temp formatted for the Detail Table
	insert into #tmpInvoiceDetail
	(BillingDefinitionInvoiceID,
	 BillingDefinitionInvoiceLineID,
	 BillingDefinitionEventID,
	 BillingScheduleID,
	 ProgramID,
	 EntityID,
	 EntityKey,
	 EntityDate,
	 Name,
	 [Description],
	 ---
	 ServiceCode,
	 BillingCode,
	 ProductID,
	 AccountingSystemItemCode,
	 AccountingSystemGLCode,
	 RateTypeName,
	 Quantity,
	 EventAmount,
	 InvoiceDetailStatusID,
	 InvoiceDetailStatusAuthorization,
	 InvoiceDetailStatusAuthorizationDate,
	 InvoiceDetailDispositionID,
	 IsAdjustable,
	 AdjustmentReasonID,
	 AdjustmentReasonOther,
	 AdjustmentComment,
	 AdjustedBy,
	 AdjustmentDate,
	 AdjustmentAmount,
	 AdjustmentAuthorization,
	 AdjustmentAuthorizationDate,
	 IsExcludable,
	 ExcludeReasonID,
	 ExcludeReasonOther,
	 ExcludeComment,
	 ExcludedBy,
	 ExcludeDate,
	 ExcludeAuthorization,
	 ExcludeAuthorizationDate,
	 BillingInvoiceLineID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy,
	 
	 BaseQuantity,
	 BaseAmount,
	 BasePercentage,
	 Rate,
	 IsAdjusted,
	 IsExcluded,
	 IsEditable)
	select	@BillingDefinitionInvoiceID, -- BillingDefinitionInvoiceID
			@BillingDefinitionInvoiceLineID, -- BillingDefinitionInvoiceLineID
			@BillingDefinitionEventID, -- BillingDefinitionEventID
			@BillingScheduleID, -- BillingScheduleID
			ProgramID, -- ProgramID
			EntityID, -- EntityID
			EntityKey, -- EntityKey
			EntityDate, -- EntityDate
			@Name, -- Name
			@Description, -- [Description] -- from the BillingEvent proc
			---
			ServiceCode,
			BillingCode,
			@ProductID,
			@AccountingSystemItemCode,
			@AccountingSystemGLCode,
			@RateTypeName,
			case
			 when @RateTypeName = 'AmountFixed' then @FixedQuantity
			 else BaseQuantity
			end, -- Quantity
			BaseAmount, -- EventAmount

			@DefaultInvoiceDetailStatusID, -- InvoiceDetailStatusID
			null,	-- InvoiceDetailStatusAuthorization
			null,	-- InvoiceDetailStatusAuthorizationDate
			@BillingCode_DetailDisposition_REFRESH, -- InvoiceDetailDispositionID : REFRESH << Default to REFRESH
			@IsAdjustable, -- IsAdjustable
			null, -- AdjustmentReasonID
			null, -- AdjustmentReasonOther
			null, -- AdjustmentComment
			null, -- AdjustedBy
			null, -- AdjustmentDate
			null, -- AdjustmentAmount
			null, -- AdjustmentAuthorization
			null, -- AdjustmentAuthorizationDate
			@IsExcludable, -- IsExcludable
			null, -- ExcludeReasonID
			null, -- ExcludeReasonOther
			null, -- ExcludeComment
			null, -- ExcludedBy
			null, -- ExcludeDate
			null, -- ExcludeAuthorization
			null, -- ExcludeAuthorizationDate

			null, -- BillingInvoiceLineID

			@BillingDefinitionInvoiceLineSequence, -- Sequence
			1, -- IsActive

			@Now, -- CreateDate
			@UserName, -- CreateBy
			null, -- ModifyDate
			null, -- ModifyBy
			case
			 when @RateTypeName = 'AmountFixed' then @FixedQuantity
			 else BaseQuantity
			end, -- BaseQuantity
			BaseAmount,
			BasePercentage,
			@Rate, -- Rate
			0, -- IsAdjusted,
			0, -- IsExcluded,
			@IsEditable -- IsEditable
			
	from	#tmpEventData

-- select 'TEST>>>', @FixedQuantity as FixedQuantity

	
	-- Price the records
	update	#tmpInvoiceDetail
	set		EventAmount = dbo.fnc_BillingCalcPriceUsingRateType
			(RateTypeName, 
			 BaseQuantity,
			 case
			  when RateTypeName = 'AmountPassThru' then BaseAmount
			  when RateTypeName = 'PercentageEach' then BaseAmount
			  when RateTypeName = 'AmountFixed' then Rate
			  else Rate
			 end,
			 case
			  when RateTypeName = 'PercentageEach' then Rate
			  else BasePercentage
			 end)


	-- Clear out table in prep for next cycle
	truncate table #tmpEventData
	--delete @BillingEventPrograms
	

	-- Increment counter
	select	@RowToProcess = @RowToProcess + 1
	
	print 'Increment here'
	print ' '

end

print 'Processing Deletes '
print ' '

-- select 'TEST>>>>', * from #tmpInvoiceDetail

-- First see if records no longer exist...capture these as DELETES
if object_id('tempdb..#tmpDeletes', 'U') is not null drop table #tmpDeletes
create table #tmpDeletes
(BillingDefinitionInvoiceID	int,
 BillingDefinitionInvoiceLineID int,
 BillingDefinitionEventID int,
 BillingScheduleID int,
 ProgramID int,
 EntityID int,
 EntityKey nvarchar(50),
 IsEditable bit)

insert into #tmpDeletes
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionEventID,
 BillingScheduleID,
 ProgramID,
 EntityID,
 EntityKey,
 IsEditable)
select	BillingDefinitionInvoiceID,
		BillingDefinitionInvoiceLineID,
		BillingDefinitionEventID,
		BillingScheduleID,
		ProgramID,
		EntityID,
		EntityKey,
		IsEditable
from	dbo.BillingInvoiceDetail bid
where	exists -- Within the Invoice Definition and Schedule 
	(select 1
	 from	#tmpInvoiceDetail tmp
	 where	tmp.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID
	 and	tmp.BillingScheduleID = bid.BillingScheduleID)
and not exists -- But not found
	(select 1
	 from	#tmpInvoiceDetail tmp
	 where	tmp.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID
	 and	tmp.BillingDefinitionInvoiceLineID = bid.BillingDefinitionInvoiceLineID
	 and	tmp.BillingDefinitionEventID = bid.BillingDefinitionEventID
	 and	tmp.BillingScheduleID = bid.BillingScheduleID
	 and	tmp.ProgramID = bid.ProgramID
	 and	tmp.EntityID = bid.EntityID
	 and	tmp.EntityKey = bid.EntityKey)
and	InvoiceDetailDispositionID = @BillingCode_DetailDisposition_REFRESH -- is in REFRESH
and InvoiceDetailStatusID <> @BillingCode_DetailStatus_POSTED -- is Not POSTED


if isnull(@Debug, 1) <> 0
begin

	select '#tmpInvoiceDetail', * from #tmpInvoiceDetail
	select '#tmpDeletes', * from #tmpDeletes
	
end
else
begin

	-- Process Deletes by updating the Status to DELETED
	update	dbo.BillingInvoiceDetail
	set		InvoiceDetailStatusID = @BillingCode_DetailStatus_DELETE -- Change Status to Deleted
	from	dbo.BillingInvoiceDetail bid
	join	#tmpDeletes tmp on tmp.BillingDefinitionInvoiceID = bid.BillingDefinitionInvoiceID
	and		tmp.BillingDefinitionInvoiceLineID = bid.BillingDefinitionInvoiceLineID
	and		tmp.BillingDefinitionEventID = bid.BillingDefinitionEventID
	and		tmp.BillingScheduleID = bid.BillingScheduleID
	and		tmp.ProgramID = bid.ProgramID
	and		tmp.EntityID = bid.EntityID
	and		tmp.EntityKey = bid.EntityKey

print 'Deletes Completed'
print ' '

	-- Create Billing Invoice Detail Events
	-- MERGE...If new, then insert,  If not, then check the QueueDisposition:
	-- when 'Refresh' then update, if 'Lock' ignore 

MERGE	dbo.BillingInvoiceDetail as target
USING
		(	select	BillingDefinitionInvoiceID,
					BillingDefinitionInvoiceLineID,
					BillingDefinitionEventID,
					BillingScheduleID,
					ProgramID,
					EntityID,
					EntityKey,
					EntityDate,
					Name,
					[Description],
					---
					ServiceCode,
					BillingCode,
					ProductID,
					AccountingSystemItemCode,
					AccountingSystemGLCode,
					RateTypeName,
					Quantity,
					EventAmount,

					InvoiceDetailStatusID,
					InvoiceDetailStatusAuthorization,
					InvoiceDetailStatusAuthorizationDate,
					InvoiceDetailDispositionID,

					IsAdjustable,
					AdjustmentReasonID,
					AdjustmentReasonOther,
					AdjustmentComment,
					AdjustedBy,
					AdjustmentDate,
					AdjustmentAmount,
					AdjustmentAuthorization,
					AdjustmentAuthorizationDate,
					IsExcludable,
					ExcludeReasonID,
					ExcludeReasonOther,
					ExcludeComment,
					ExcludedBy,
					ExcludeDate,
					ExcludeAuthorization,
					ExcludeAuthorizationDate,

					BillingInvoiceLineID,
					 
					Sequence,
					IsActive,
					CreateDate,
					CreateBy,
					ModifyDate,
					ModifyBy,
					IsAdjusted,
					IsExcluded,
					IsEditable

	from	#tmpInvoiceDetail)
AS SOURCE
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionEventID,
 BillingScheduleID,
 ProgramID,
 EntityID,
 EntityKey,
 EntityDate,
 Name,
 [Description],
 ---
 ServiceCode,
 BillingCode,
 ProductID,
 AccountingSystemItemCode,
 AccountingSystemGLCode,
 RateTypeName,
 Quantity,
 EventAmount,
 InvoiceDetailStatusID,
 InvoiceDetailStatusAuthorization,
 InvoiceDetailStatusAuthorizationDate,
 InvoiceDetailDispositionID,
 IsAdjustable,
 AdjustmentReasonID,
 AdjustmentReasonOther,
 AdjustmentComment,
 AdjustedBy,
 AdjustmentDate,
 AdjustmentAmount,
 AdjustmentAuthorization,
 AdjustmentAuthorizationDate,
 IsExcludable,
 ExcludeReasonID,
 ExcludeReasonOther,
 ExcludeComment,
 ExcludedBy,
 ExcludeDate,
 ExcludeAuthorization,
 ExcludeAuthorizationDate,
 BillingInvoiceLineID,
 Sequence,
 IsActive,
 CreateDate,
 CreateBy,
 ModifyDate,
 ModifyBy,
 IsAdjusted,
 IsExcluded,
 IsEditable
)

ON 
	(target.BillingDefinitionInvoiceID = source.BillingDefinitionInvoiceID
	and		target.BillingDefinitionInvoiceLineID = source.BillingDefinitionInvoiceLineID
	and		target.BillingDefinitionEventID = source.BillingDefinitionEventID
	and		target.BillingScheduleID = source.BillingScheduleID
	and		target.ProgramID = source.ProgramID
	and		target.EntityID = source.EntityID
	and		target.EntityKey = source.EntityKey
	and		target.ISEditable = source.IsEditable)

WHEN MATCHED and target.InvoiceDetailDispositionID = @BillingCode_DetailDisposition_REFRESH THEN 
UPDATE
SET		EntityDate = source.EntityDate,
		Name = source.Name,
		[Description] = source.[Description],
		---
		ServiceCode = source.ServiceCode,
		BillingCode = source.BillingCode,
		ProductID = source.ProductID,
		AccountingSystemItemCode = source.AccountingSystemItemCode,
		AccountingSystemGLCode = source.AccountingSystemGLCode,
		RateTypeName = source.RateTypeName,
		Quantity = source.Quantity,
		EventAmount = source.EventAmount,
		Sequence = source.Sequence,
		ModifyDate = @Now,
		ModifyBy = @UserName

WHEN NOT MATCHED THEN	
INSERT	(BillingDefinitionInvoiceID,
		 BillingDefinitionInvoiceLineID,
		 BillingDefinitionEventID,
		 BillingScheduleID,
		 ProgramID,
		 EntityID,
		 EntityKey,
		 EntityDate,
		 Name,
		 [Description],
		 ---
		 ServiceCode,
		 BillingCode,
		 ProductID,
		 AccountingSystemItemCode,
		 AccountingSystemGLCode,
		 RateTypeName,
		 Quantity,
		 EventAmount,
		 InvoiceDetailStatusID,
		 InvoiceDetailStatusAuthorization,
		 InvoiceDetailStatusAuthorizationDate,
		 InvoiceDetailDispositionID,
		 IsAdjustable,
		 AdjustmentReasonID,
		 AdjustmentReasonOther,
		 AdjustmentComment,
		 AdjustedBy,
		 AdjustmentDate,
		 AdjustmentAmount,
		 AdjustmentAuthorization,
		 AdjustmentAuthorizationDate,
		 IsExcludable,
		 ExcludeReasonID,
		 ExcludeReasonOther,
		 ExcludeComment,
		 ExcludedBy,
		 ExcludeDate,
		 ExcludeAuthorization,
		 ExcludeAuthorizationDate,
		 BillingInvoiceLineID,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy,
		 IsAdjusted,
		 IsExcluded,
		 IsEditable
)
VALUES (source.BillingDefinitionInvoiceID,
		source.BillingDefinitionInvoiceLineID,
		source.BillingDefinitionEventID,
		source.BillingScheduleID,
		source.ProgramID,
		source.EntityID,
		source.EntityKey,
		source.EntityDate,
		source.Name,
		source.[Description],
		---
		source.ServiceCode,
		source.BillingCode,
		source.ProductID,
		source.AccountingSystemItemCode,
		source.AccountingSystemGLCode,
		source.RateTypeName,
		source.Quantity,
		source.EventAmount,
		source.InvoiceDetailStatusID,
		source.InvoiceDetailStatusAuthorization,
		source.InvoiceDetailStatusAuthorizationDate,
		source.InvoiceDetailDispositionID,
		source.IsAdjustable,
		source.AdjustmentReasonID,
		source.AdjustmentReasonOther,
		source.AdjustmentComment,
		source.AdjustedBy,
		source.AdjustmentDate,
		source.AdjustmentAmount,
		source.AdjustmentAuthorization,
		source.AdjustmentAuthorizationDate,
		source.IsExcludable,
		source.ExcludeReasonID,
		source.ExcludeReasonOther,
		source.ExcludeComment,
		source.ExcludedBy,
		source.ExcludeDate,
		source.ExcludeAuthorization,
		source.ExcludeAuthorizationDate,
		source.BillingInvoiceLineID,
		source.Sequence,
		source.IsActive,
		source.CreateDate,
		source.CreateBy,
		source.ModifyDate,
		source.ModifyBy,
		source.IsAdjusted,
		source.IsExcluded,
		source.IsEditable
);

end






GO



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
	
	DECLARE @ParentRecordID INT = NULL
	DECLARE @ChildRecordID INT = NULL
	
	DECLARE @newRecordID INT
	
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import_ChargedTransactions 
												 WHERE ProcessIdentifier = @processGUID)
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import_ChargedTransactions 
												 WHERE ProcessIdentifier = @processGUID)
	
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
								 WHERE right(tcc.CreditCardNumber, 5) = right(@creditCardNumber,5)
								 AND ltrim(rtrim(isnull(tcc.OriginalReferencePurchaseOrderNumber,''))) = ltrim									 (rtrim(isnull(@purchaseOrderNumber,'')))
								 AND Cast(Convert(varchar, tcc.IssueDate,101) as datetime) <= @chargedDate)
			 
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
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_CCImport_CreditCardIssueTransactions]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_CCImport_CreditCardIssueTransactions]
GO
CREATE PROC [dbo].dms_CCImport_CreditCardIssueTransactions(@processGUID UNIQUEIDENTIFIER = NULL)
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
	DECLARE @creditCardIssueNumber NVARCHAR(50) 
	DECLARE @creditCardNumber NVARCHAR(50)
	DECLARE @transactionSequence INT
	DECLARE @tempLookUpID INT
	DECLARE @newRecordID INT
	
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN
		SELECT  @creditCardIssueNumber = IMP.PurchaseID_CreditCardIssueNumber,
				@creditCardNumber = IMP.CPN_PAN_CreditCardNumber
		FROM TemporaryCreditCard_Import IMP
		WHERE RecordID = @startROWParent
		
		IF(NOT EXISTS(SELECT * FROM TemporaryCreditCard TCC WHERE 
														TCC.CreditCardIssueNumber = @creditCardIssueNumber AND 
														TCC.CreditCardNumber = @creditCardNumber))
		BEGIN
			INSERT INTO TemporaryCreditCard(CreditCardIssueNumber,			
								CreditCardNumber,			
								PurchaseOrderID,									
								VendorInvoiceID,				
								IssueDate,					
								IssueBy,
								IssueStatus,					
								ReferencePurchaseOrderNumber,				 
								OriginalReferencePurchaseOrderNumber,					 
								ReferenceVendorNumber,
								ApprovedAmount,					
								TotalChargedAmount,
								TemporaryCreditCardStatusID,									
								ExceptionMessage,				
								Note,						
								CreateDate,
								CreateBy,						
								ModifyDate,					
								ModifyBy) 
					SELECT PurchaseID_CreditCardIssueNumber,
						   CPN_PAN_CreditCardNumber,
						   PurchaseOrderID,
						   VendorInvoiceID,
						   CREATE_DATE_IssueDate_TransactionDate,
						   USER_NAME_IssueBy_TransactionBy,
						   IssueStatus,
						   CDF_PO_ReferencePurchaseOrderNumber,
						   CDF_PO_OriginalReferencePurchaseOrderNumber,
						   CDF_ISP_Vendor_ReferenceVendorNumber,
						   ApprovedAmount,
						   TotalChargeAmount,
						   TemporaryCreditCardStatusID,
						   ExceptionMessage,
						   Note,
						   CreateDate,
						   CreateBy,
						   ModifyDate,
						   ModifyBy
					FROM TemporaryCreditCard_Import S1 WHERE S1.RecordID = @startROWParent
				
			SET @newRecordID = SCOPE_IDENTITY()	
			
			UPDATE TemporaryCreditCard_Import SET TemporaryCreditCardID = @newRecordID
			WHERE RecordID = @startROWParent
		END
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 2 : Insert Records Into Temporary Credit Card Details
	SET @startROWParent =  (SELECT MIN(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
	
	SET @totalRowsParent = (SELECT MAX(RecordID) FROM TemporaryCreditCard_Import 
												 WHERE ProcessIdentifier = @processGUID)
												 
	WHILE(@startROWParent <= @totalRowsParent)  
	BEGIN
		SELECT  @creditCardIssueNumber = IMP.PurchaseID_CreditCardIssueNumber,
				@creditCardNumber = IMP.CPN_PAN_CreditCardNumber,
				@transactionSequence = IMP.HISTORY_ID_TransactionSequence
		FROM TemporaryCreditCard_Import IMP
		WHERE RecordID = @startROWParent
		
		IF(NOT EXISTS(SELECT tcc.ID, tccd.ID
					FROM TemporaryCreditCard tcc
					JOIN TemporaryCreditCardDetail tccd
						ON tcc.ID = tccd.TemporaryCreditCardID
					WHERE tcc.CreditCardIssueNumber = @creditCardIssueNumber
					AND tcc.CreditCardNumber = @creditCardNumber
					AND tccd.TransactionSequence = @transactionSequence
					))
					
		BEGIN
		SET @tempLookUpID = (SELECT tcc.ID FROM TemporaryCreditCard tcc
							   WHERE tcc.CreditCardIssueNumber = @creditCardIssueNumber
							   AND tcc.CreditCardNumber = @creditCardNumber)
							   
		INSERT INTO TemporaryCreditCardDetail(  TemporaryCreditCardID,
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
		SELECT @tempLookUpID, 
			   HISTORY_ID_TransactionSequence,
			   CREATE_DATE_IssueDate_TransactionDate,
			   ACTION_TYPE_TransactionType,
			   USER_NAME_IssueBy_TransactionBy,
			   REQUESTED_AMOUNT_RequestedAmount,
			   APPROVED_AMOUNT_ApprovedAmount,
			   AVAILABLE_BALANCE_AvailableBalance,
			   ChargeDate,
			   ChargeAmount,
			   ChargeDescription,
			   CreateDate,
			   CreateBy,
			   ModifyDate,
			   ModifyBy
		FROM TemporaryCreditCard_Import WHERE RecordID = @startROWParent
		
		SET @newRecordID = SCOPE_IDENTITY()
		UPDATE TemporaryCreditCard_Import SET TemporaryCreditCardDetailsID = @newRecordID
		WHERE RecordID = @startROWParent  
		
		END
		SET @startROWParent = @startROWParent + 1
	END
	
	-- Step 3 Update Counts
	SET @TotalRecordCount = (SELECT COUNT(*) FROM TemporaryCreditCard_Import WHERE 
							 ProcessIdentifier = @processGUID)
	
	SET @TotalRecordsIgnored = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							   WHERE TemporaryCreditCardDetailsID IS NULL AND ProcessIdentifier = @processGUID
							   AND TemporaryCreditCardID IS NULL
							   ) 
							  
	
	SET @TotalCreditCardAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							     WHERE TemporaryCreditCardID IS NOT NULL AND ProcessIdentifier = @processGUID)
							     
	SET @TotalTransactionAdded = (SELECT COUNT(*) FROM TemporaryCreditCard_Import
							     WHERE TemporaryCreditCardDetailsID IS NOT NULL AND ProcessIdentifier = @processGUID)
							   
	
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
		@totalApprovedAmount INT,
		@totalChargedAmount INT

SET @postedStatus = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Posted')

INSERT INTO #TempCardsNotPosted
SELECT DISTINCT TCCD.TemporaryCreditCardID FROM
TemporaryCreditCardDetail TCCD
JOIN TemporaryCreditCard TCC ON TCC.ID = TCCD.TemporaryCreditCardID
WHERE TCC.TemporaryCreditCardStatusID != @postedStatus

SET @startROWParent =  (SELECT MIN([RowNum]) FROM #TempCardsNotPosted)
SET @totalRowsParent = (SELECT MAX([RowNum]) FROM #TempCardsNotPosted)

WHILE(@startROWParent <= @totalRowsParent)  
BEGIN

SET @creditcardNumber = (SELECT ID FROM #TempCardsNotPosted WHERE [RowNum] = @startROWParent)

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
		BID.IsEditable AS IsQuantityAndAmountEditable  

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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Client_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Batch_Payment_Runs_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Client_Batch_Payment_Runs_List_Get] @BatchID=147
 CREATE PROCEDURE [dbo].[dms_Client_Batch_Payment_Runs_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @BatchID INT = NULL 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
InvoiceNumberOperator="-1" 
DateOperator="-1" 
NameOperator="-1" 
DescriptionOperator="-1" 
LinesOperator="-1" 
AmountOperator="-1" 
CustomerNumberOperator="-1" 
AddressCodeOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
DateOperator INT NOT NULL,
DateValue datetime NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
DescriptionOperator INT NOT NULL,
DescriptionValue nvarchar(100) NULL,
LinesOperator INT NOT NULL,
LinesValue int NULL,
AmountOperator INT NOT NULL,
AmountValue money NULL,
CustomerNumberOperator INT NOT NULL,
CustomerNumberValue nvarchar(100) NULL,
AddressCodeOperator INT NOT NULL,
AddressCodeValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	Date datetime  NULL ,
	Name nvarchar(100)  NULL ,
	Description nvarchar(100)  NULL ,
	Lines int  NULL ,
	Amount money  NULL ,
	CustomerNumber nvarchar(100)  NULL ,
	AddressCode nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	Date datetime  NULL ,
	Name nvarchar(100)  NULL ,
	Description nvarchar(100)  NULL ,
	Lines int  NULL ,
	Amount money  NULL ,
	CustomerNumber nvarchar(100)  NULL ,
	AddressCode nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DateOperator','INT'),-1),
	T.c.value('@DateValue','datetime') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DescriptionOperator','INT'),-1),
	T.c.value('@DescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LinesOperator','INT'),-1),
	T.c.value('@LinesValue','int') ,
	ISNULL(T.c.value('@AmountOperator','INT'),-1),
	T.c.value('@AmountValue','money') ,
	ISNULL(T.c.value('@CustomerNumberOperator','INT'),-1),
	T.c.value('@CustomerNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AddressCodeOperator','INT'),-1),
	T.c.value('@AddressCodeValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT BI.ID
, BI.InvoiceNumber AS InvoiceNumber
, BI.InvoiceDate AS [Date]
, BI.Name AS Name
, BI.Description AS [Description]
, COUNT(BIL.ID) AS Lines
, SUM(BIL.LineAmount) AS Amount
, BI.AccountingSystemCustomerNumber AS CustomerNumber
, BI.AccountingSystemAddressCode AS AddressCode
FROM BillingInvoice BI
LEFT JOIN BillingInvoiceLine BIL WITH(NOLOCK) ON BIL.BillingInvoiceID = BI.ID
WHERE BI.AccountingInvoiceBatchID = @BatchID
GROUP BY
BI.ID
, BI.InvoiceNumber
, BI.InvoiceDate
, BI.Name
, BI.[Description]
, BI.AccountingSystemCustomerNumber
, BI.AccountingSystemAddressCode

INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.InvoiceNumber,
	T.Date,
	T.Name,
	T.Description,
	T.Lines,
	T.Amount,
	T.CustomerNumber,
	T.AddressCode
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
	 ( TMP.InvoiceNumberOperator = -1 ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 0 AND T.InvoiceNumber IS NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 1 AND T.InvoiceNumber IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 2 AND T.InvoiceNumber = TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 3 AND T.InvoiceNumber <> TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 4 AND T.InvoiceNumber LIKE TMP.InvoiceNumberValue + '%') 
 OR 
	 ( TMP.InvoiceNumberOperator = 5 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 6 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DateOperator = -1 ) 
 OR 
	 ( TMP.DateOperator = 0 AND T.Date IS NULL ) 
 OR 
	 ( TMP.DateOperator = 1 AND T.Date IS NOT NULL ) 
 OR 
	 ( TMP.DateOperator = 2 AND T.Date = TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 3 AND T.Date <> TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 7 AND T.Date > TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 8 AND T.Date >= TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 9 AND T.Date < TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 10 AND T.Date <= TMP.DateValue ) 

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
	 ( TMP.DescriptionOperator = -1 ) 
 OR 
	 ( TMP.DescriptionOperator = 0 AND T.Description IS NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 1 AND T.Description IS NOT NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 2 AND T.Description = TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 3 AND T.Description <> TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 4 AND T.Description LIKE TMP.DescriptionValue + '%') 
 OR 
	 ( TMP.DescriptionOperator = 5 AND T.Description LIKE '%' + TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 6 AND T.Description LIKE '%' + TMP.DescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LinesOperator = -1 ) 
 OR 
	 ( TMP.LinesOperator = 0 AND T.Lines IS NULL ) 
 OR 
	 ( TMP.LinesOperator = 1 AND T.Lines IS NOT NULL ) 
 OR 
	 ( TMP.LinesOperator = 2 AND T.Lines = TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 3 AND T.Lines <> TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 7 AND T.Lines > TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 8 AND T.Lines >= TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 9 AND T.Lines < TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 10 AND T.Lines <= TMP.LinesValue ) 

 ) 

 AND 

 ( 
	 ( TMP.AmountOperator = -1 ) 
 OR 
	 ( TMP.AmountOperator = 0 AND T.Amount IS NULL ) 
 OR 
	 ( TMP.AmountOperator = 1 AND T.Amount IS NOT NULL ) 
 OR 
	 ( TMP.AmountOperator = 2 AND T.Amount = TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 3 AND T.Amount <> TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 7 AND T.Amount > TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 8 AND T.Amount >= TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 9 AND T.Amount < TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 10 AND T.Amount <= TMP.AmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CustomerNumberOperator = -1 ) 
 OR 
	 ( TMP.CustomerNumberOperator = 0 AND T.CustomerNumber IS NULL ) 
 OR 
	 ( TMP.CustomerNumberOperator = 1 AND T.CustomerNumber IS NOT NULL ) 
 OR 
	 ( TMP.CustomerNumberOperator = 2 AND T.CustomerNumber = TMP.CustomerNumberValue ) 
 OR 
	 ( TMP.CustomerNumberOperator = 3 AND T.CustomerNumber <> TMP.CustomerNumberValue ) 
 OR 
	 ( TMP.CustomerNumberOperator = 4 AND T.CustomerNumber LIKE TMP.CustomerNumberValue + '%') 
 OR 
	 ( TMP.CustomerNumberOperator = 5 AND T.CustomerNumber LIKE '%' + TMP.CustomerNumberValue ) 
 OR 
	 ( TMP.CustomerNumberOperator = 6 AND T.CustomerNumber LIKE '%' + TMP.CustomerNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AddressCodeOperator = -1 ) 
 OR 
	 ( TMP.AddressCodeOperator = 0 AND T.AddressCode IS NULL ) 
 OR 
	 ( TMP.AddressCodeOperator = 1 AND T.AddressCode IS NOT NULL ) 
 OR 
	 ( TMP.AddressCodeOperator = 2 AND T.AddressCode = TMP.AddressCodeValue ) 
 OR 
	 ( TMP.AddressCodeOperator = 3 AND T.AddressCode <> TMP.AddressCodeValue ) 
 OR 
	 ( TMP.AddressCodeOperator = 4 AND T.AddressCode LIKE TMP.AddressCodeValue + '%') 
 OR 
	 ( TMP.AddressCodeOperator = 5 AND T.AddressCode LIKE '%' + TMP.AddressCodeValue ) 
 OR 
	 ( TMP.AddressCodeOperator = 6 AND T.AddressCode LIKE '%' + TMP.AddressCodeValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'ASC'
	 THEN T.Date END ASC, 
	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'DESC'
	 THEN T.Date END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'Lines' AND @sortOrder = 'ASC'
	 THEN T.Lines END ASC, 
	 CASE WHEN @sortColumn = 'Lines' AND @sortOrder = 'DESC'
	 THEN T.Lines END DESC ,

	 CASE WHEN @sortColumn = 'Amount' AND @sortOrder = 'ASC'
	 THEN T.Amount END ASC, 
	 CASE WHEN @sortColumn = 'Amount' AND @sortOrder = 'DESC'
	 THEN T.Amount END DESC ,

	 CASE WHEN @sortColumn = 'CustomerNumber' AND @sortOrder = 'ASC'
	 THEN T.CustomerNumber END ASC, 
	 CASE WHEN @sortColumn = 'CustomerNumber' AND @sortOrder = 'DESC'
	 THEN T.CustomerNumber END DESC ,

	 CASE WHEN @sortColumn = 'AddressCode' AND @sortOrder = 'ASC'
	 THEN T.AddressCode END ASC, 
	 CASE WHEN @sortColumn = 'AddressCode' AND @sortOrder = 'DESC'
	 THEN T.AddressCode END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Client_ClosePeriod]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_ClosePeriod] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_ClosePeriod]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingScheduleIDOperator="-1" 
ScheduleNameOperator="-1" 
ScheduleDateOperator="-1" 
ScheduleRangeBeginOperator="-1" 
ScheduleRangeEndOperator="-1" 
ScheduleTypeOperator="-1" 
ScheduleRangeTypeOperator="-1" 
ScheduleDateTypeOperator="-1" 
ScheduleStatusOperator="-1" 
TotalInvoiceCountOperator="-1" 
PostedInvoiceCountOperator="-1" 
CanBeClosedOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingScheduleIDOperator INT NOT NULL,
BillingScheduleIDValue int NULL,
ScheduleNameOperator INT NOT NULL,
ScheduleNameValue nvarchar(100) NULL,
ScheduleDateOperator INT NOT NULL,
ScheduleDateValue datetime NULL,
ScheduleRangeBeginOperator INT NOT NULL,
ScheduleRangeBeginValue datetime NULL,
ScheduleRangeEndOperator INT NOT NULL,
ScheduleRangeEndValue datetime NULL,
ScheduleTypeOperator INT NOT NULL,
ScheduleTypeValue nvarchar(100) NULL,
ScheduleRangeTypeOperator INT NOT NULL,
ScheduleRangeTypeValue nvarchar(100) NULL,
ScheduleDateTypeOperator INT NOT NULL,
ScheduleDateTypeValue nvarchar(100) NULL,
ScheduleStatusOperator INT NOT NULL,
ScheduleStatusValue nvarchar(100) NULL,
TotalInvoiceCountOperator INT NOT NULL,
TotalInvoiceCountValue int NULL,
PostedInvoiceCountOperator INT NOT NULL,
PostedInvoiceCountValue int NULL,
CanBeClosedOperator INT NOT NULL,
CanBeClosedValue INT NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(100)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	ScheduleType nvarchar(100)  NULL ,
	ScheduleRangeType nvarchar(100)  NULL ,
	ScheduleDateType nvarchar(100)  NULL ,
	ScheduleStatus nvarchar(100)  NULL ,
	TotalInvoiceCount int  NULL ,
	PostedInvoiceCount int  NULL ,
	CanBeClosed INT  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(100)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	ScheduleType nvarchar(100)  NULL ,
	ScheduleRangeType nvarchar(100)  NULL ,
	ScheduleDateType nvarchar(100)  NULL ,
	ScheduleStatus nvarchar(100)  NULL ,
	TotalInvoiceCount int  NULL ,
	PostedInvoiceCount int  NULL ,
	CanBeClosed INT  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingScheduleIDOperator','INT'),-1),
	T.c.value('@BillingScheduleIDValue','int') ,
	ISNULL(T.c.value('@ScheduleNameOperator','INT'),-1),
	T.c.value('@ScheduleNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateOperator','INT'),-1),
	T.c.value('@ScheduleDateValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeBeginOperator','INT'),-1),
	T.c.value('@ScheduleRangeBeginValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeEndOperator','INT'),-1),
	T.c.value('@ScheduleRangeEndValue','datetime') ,
	ISNULL(T.c.value('@ScheduleTypeOperator','INT'),-1),
	T.c.value('@ScheduleTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleRangeTypeOperator','INT'),-1),
	T.c.value('@ScheduleRangeTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateTypeOperator','INT'),-1),
	T.c.value('@ScheduleDateTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleStatusOperator','INT'),-1),
	T.c.value('@ScheduleStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@TotalInvoiceCountOperator','INT'),-1),
	T.c.value('@TotalInvoiceCountValue','int') ,
	ISNULL(T.c.value('@PostedInvoiceCountOperator','INT'),-1),
	T.c.value('@PostedInvoiceCountValue','int') ,
	ISNULL(T.c.value('@CanBeClosedOperator','INT'),-1),
	T.c.value('@CanBeClosedValue','INT') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @QueryResult
SELECT	bs.ID as BillingScheduleID,
		bs.Name as ScheduleName,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bst.[Description] as ScheduleType,
		bsrt.[Description] as ScheduleRangeType,
		bsdt.[Description] as ScheduleDateType,
		bss.[Description] as ScheduleStatus,
		tt.TotalInvoiceCount,
		pp.PostedInvoiceCount,
		case
		 when tt.TotalInvoiceCount = pp.PostedInvoiceCount then 1
		 else 0
		end as CanBeClosed
from	BillingSchedule bs with (nolock)
left outer join	BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join	BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left outer join	BillingScheduleRangeType bsrt with (nolock) on bsrt.ID = bs.ScheduleRangeTypeID
left outer join	BillingScheduleDateType bsdt with (nolock) on bsdt.ID = bs.ScheduleDateTypeID
left outer join
	(select	BillingScheduleID,
			count(*) as TotalInvoiceCount
	 from	BillingInvoice bi with (nolock)
	 where	1=1
	 group by
			BillingScheduleID) tt on tt.BillingScheduleID = bs.ID
left outer join
	(select	BillingScheduleID,
			count(*) as PostedInvoiceCount
	 from	BillingInvoice bi with (nolock)
	 where	1=1
	 and	InvoiceStatusID = (select ID from BillingInvoiceStatus with (nolock) where Name = 'POSTED')
	 group by
			BillingScheduleID) pp on pp.BillingScheduleID = bs.ID
where	1=1
and		bss.Name = 'OPEN' -- Must be Open
and		bs.ScheduleDate < getdate() -- Must be after the schedule date

INSERT INTO #FinalResults
SELECT 
	T.BillingScheduleID,
	T.ScheduleName,
	T.ScheduleDate,
	T.ScheduleRangeBegin,
	T.ScheduleRangeEnd,
	T.ScheduleType,
	T.ScheduleRangeType,
	T.ScheduleDateType,
	T.ScheduleStatus,
	T.TotalInvoiceCount,
	T.PostedInvoiceCount,
	T.CanBeClosed
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingScheduleIDOperator = -1 ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 0 AND T.BillingScheduleID IS NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 1 AND T.BillingScheduleID IS NOT NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 2 AND T.BillingScheduleID = TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 3 AND T.BillingScheduleID <> TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 7 AND T.BillingScheduleID > TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 8 AND T.BillingScheduleID >= TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 9 AND T.BillingScheduleID < TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 10 AND T.BillingScheduleID <= TMP.BillingScheduleIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleNameOperator = -1 ) 
 OR 
	 ( TMP.ScheduleNameOperator = 0 AND T.ScheduleName IS NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 1 AND T.ScheduleName IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 2 AND T.ScheduleName = TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 3 AND T.ScheduleName <> TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 4 AND T.ScheduleName LIKE TMP.ScheduleNameValue + '%') 
 OR 
	 ( TMP.ScheduleNameOperator = 5 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 6 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateOperator = 0 AND T.ScheduleDate IS NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 1 AND T.ScheduleDate IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 2 AND T.ScheduleDate = TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 3 AND T.ScheduleDate <> TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 7 AND T.ScheduleDate > TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 8 AND T.ScheduleDate >= TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 9 AND T.ScheduleDate < TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 10 AND T.ScheduleDate <= TMP.ScheduleDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeBeginOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 0 AND T.ScheduleRangeBegin IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 1 AND T.ScheduleRangeBegin IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 2 AND T.ScheduleRangeBegin = TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 3 AND T.ScheduleRangeBegin <> TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 7 AND T.ScheduleRangeBegin > TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 8 AND T.ScheduleRangeBegin >= TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 9 AND T.ScheduleRangeBegin < TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 10 AND T.ScheduleRangeBegin <= TMP.ScheduleRangeBeginValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeEndOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 0 AND T.ScheduleRangeEnd IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 1 AND T.ScheduleRangeEnd IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 2 AND T.ScheduleRangeEnd = TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 3 AND T.ScheduleRangeEnd <> TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 7 AND T.ScheduleRangeEnd > TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 8 AND T.ScheduleRangeEnd >= TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 9 AND T.ScheduleRangeEnd < TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 10 AND T.ScheduleRangeEnd <= TMP.ScheduleRangeEndValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 0 AND T.ScheduleType IS NULL ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 1 AND T.ScheduleType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 2 AND T.ScheduleType = TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 3 AND T.ScheduleType <> TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 4 AND T.ScheduleType LIKE TMP.ScheduleTypeValue + '%') 
 OR 
	 ( TMP.ScheduleTypeOperator = 5 AND T.ScheduleType LIKE '%' + TMP.ScheduleTypeValue ) 
 OR 
	 ( TMP.ScheduleTypeOperator = 6 AND T.ScheduleType LIKE '%' + TMP.ScheduleTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 0 AND T.ScheduleRangeType IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 1 AND T.ScheduleRangeType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 2 AND T.ScheduleRangeType = TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 3 AND T.ScheduleRangeType <> TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 4 AND T.ScheduleRangeType LIKE TMP.ScheduleRangeTypeValue + '%') 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 5 AND T.ScheduleRangeType LIKE '%' + TMP.ScheduleRangeTypeValue ) 
 OR 
	 ( TMP.ScheduleRangeTypeOperator = 6 AND T.ScheduleRangeType LIKE '%' + TMP.ScheduleRangeTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateTypeOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 0 AND T.ScheduleDateType IS NULL ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 1 AND T.ScheduleDateType IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 2 AND T.ScheduleDateType = TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 3 AND T.ScheduleDateType <> TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 4 AND T.ScheduleDateType LIKE TMP.ScheduleDateTypeValue + '%') 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 5 AND T.ScheduleDateType LIKE '%' + TMP.ScheduleDateTypeValue ) 
 OR 
	 ( TMP.ScheduleDateTypeOperator = 6 AND T.ScheduleDateType LIKE '%' + TMP.ScheduleDateTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleStatusOperator = -1 ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 0 AND T.ScheduleStatus IS NULL ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 1 AND T.ScheduleStatus IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 2 AND T.ScheduleStatus = TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 3 AND T.ScheduleStatus <> TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 4 AND T.ScheduleStatus LIKE TMP.ScheduleStatusValue + '%') 
 OR 
	 ( TMP.ScheduleStatusOperator = 5 AND T.ScheduleStatus LIKE '%' + TMP.ScheduleStatusValue ) 
 OR 
	 ( TMP.ScheduleStatusOperator = 6 AND T.ScheduleStatus LIKE '%' + TMP.ScheduleStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.TotalInvoiceCountOperator = -1 ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 0 AND T.TotalInvoiceCount IS NULL ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 1 AND T.TotalInvoiceCount IS NOT NULL ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 2 AND T.TotalInvoiceCount = TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 3 AND T.TotalInvoiceCount <> TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 7 AND T.TotalInvoiceCount > TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 8 AND T.TotalInvoiceCount >= TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 9 AND T.TotalInvoiceCount < TMP.TotalInvoiceCountValue ) 
 OR 
	 ( TMP.TotalInvoiceCountOperator = 10 AND T.TotalInvoiceCount <= TMP.TotalInvoiceCountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PostedInvoiceCountOperator = -1 ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 0 AND T.PostedInvoiceCount IS NULL ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 1 AND T.PostedInvoiceCount IS NOT NULL ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 2 AND T.PostedInvoiceCount = TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 3 AND T.PostedInvoiceCount <> TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 7 AND T.PostedInvoiceCount > TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 8 AND T.PostedInvoiceCount >= TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 9 AND T.PostedInvoiceCount < TMP.PostedInvoiceCountValue ) 
 OR 
	 ( TMP.PostedInvoiceCountOperator = 10 AND T.PostedInvoiceCount <= TMP.PostedInvoiceCountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CanBeClosedOperator = -1 ) 
 OR 
	 ( TMP.CanBeClosedOperator = 0 AND T.CanBeClosed IS NULL ) 
 OR 
	 ( TMP.CanBeClosedOperator = 1 AND T.CanBeClosed IS NOT NULL ) 
 OR 
	 ( TMP.CanBeClosedOperator = 2 AND T.CanBeClosed = TMP.CanBeClosedValue ) 
 OR 
	 ( TMP.CanBeClosedOperator = 3 AND T.CanBeClosed <> TMP.CanBeClosedValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'ASC'
	 THEN T.ScheduleName END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'DESC'
	 THEN T.ScheduleName END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDate END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDate END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeBegin END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeBegin END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeEnd END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeEnd END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDateType' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDateType END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDateType' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDateType END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleStatus' AND @sortOrder = 'ASC'
	 THEN T.ScheduleStatus END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleStatus' AND @sortOrder = 'DESC'
	 THEN T.ScheduleStatus END DESC ,

	 CASE WHEN @sortColumn = 'TotalInvoiceCount' AND @sortOrder = 'ASC'
	 THEN T.TotalInvoiceCount END ASC, 
	 CASE WHEN @sortColumn = 'TotalInvoiceCount' AND @sortOrder = 'DESC'
	 THEN T.TotalInvoiceCount END DESC ,

	 CASE WHEN @sortColumn = 'PostedInvoiceCount' AND @sortOrder = 'ASC'
	 THEN T.PostedInvoiceCount END ASC, 
	 CASE WHEN @sortColumn = 'PostedInvoiceCount' AND @sortOrder = 'DESC'
	 THEN T.PostedInvoiceCount END DESC ,

	 CASE WHEN @sortColumn = 'CanBeClosed' AND @sortOrder = 'ASC'
	 THEN T.CanBeClosed END ASC, 
	 CASE WHEN @sortColumn = 'CanBeClosed' AND @sortOrder = 'DESC'
	 THEN T.CanBeClosed END DESC 


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
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_ClosePeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_ClosePeriodProcess] 
END 
GO
-- EXCE dms_Client_ClosePeriodProcess @billingSchedules = '1,2',@userName = 'demoUser',@sessionID = 'XX12',@pageReference = 'Test'
CREATE PROC [dbo].[dms_Client_ClosePeriodProcess](@billingSchedules NVARCHAR(MAX),@userName NVARCHAR(100),@sessionID NVARCHAR(MAX),@pageReference NVARCHAR(MAX))
AS
BEGIN
	
	DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
	INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
	DECLARE @scheduleID AS INT
	DECLARE @ProcessingCounter AS INT = 1
	DECLARE @TotalRows AS INT
	SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
	DECLARE @entityID AS INT 
	DECLARE @eventID AS INT
	SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingSchedule'
	SELECT  @eventID =  ID FROM Event WHERE Name = 'ClosePeriod'

	WHILE @ProcessingCounter <= @TotalRows
	BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
			
			-- Write Process Logic for Schedule ID

			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		 @scheduleID,
								 NULL,					NULL,						@userName,			GETDATE())
			
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			
			SET @ProcessingCounter = @ProcessingCounter + 1
	END
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
 WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriod]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_OpenPeriod] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_OpenPeriod]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
BillingScheduleIDOperator="-1" 
ScheduleNameOperator="-1" 
ScheduleDateOperator="-1" 
ScheduleRangeBeginOperator="-1" 
ScheduleRangeEndOperator="-1" 
StatusOperator="-1" 
InvoicesToBeCreatedCountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BillingScheduleIDOperator INT NOT NULL,
BillingScheduleIDValue int NULL,
ScheduleNameOperator INT NOT NULL,
ScheduleNameValue nvarchar(100) NULL,
ScheduleDateOperator INT NOT NULL,
ScheduleDateValue datetime NULL,
ScheduleRangeBeginOperator INT NOT NULL,
ScheduleRangeBeginValue datetime NULL,
ScheduleRangeEndOperator INT NOT NULL,
ScheduleRangeEndValue datetime NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
InvoicesToBeCreatedCountOperator INT NOT NULL,
InvoicesToBeCreatedCountValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(100)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(100)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

DECLARE @QueryResult AS TABLE( 
	BillingScheduleID int  NULL ,
	ScheduleName nvarchar(100)  NULL ,
	ScheduleDate datetime  NULL ,
	ScheduleRangeBegin datetime  NULL ,
	ScheduleRangeEnd datetime  NULL ,
	Status nvarchar(100)  NULL ,
	InvoicesToBeCreatedCount int  NULL 
) 

INSERT INTO @QueryResult
SELECT	bs.ID as BillingScheduleID,
		bs.Name as ScheduleName,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd,
		bss.Name as [Status],
		tt.InvoicesToBeCreatedCount
FROM	BillingSchedule bs with (nolock)
left outer join	BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID
left outer join	BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID
left outer join	BillingScheduleRangeType bsrt with (nolock) on bsrt.ID = bs.ScheduleRangeTypeID
left outer join	BillingScheduleDateType bsdt with (nolock) on bsdt.ID = bs.ScheduleDateTypeID
left outer join
	(SELECT bs.ID AS BillingScheduleID, 
			count(*) InvoicesToBeCreatedCount
	from	BillingSchedule bs
	join	BillingDefinitionInvoice bdi on bdi.ScheduleTypeID = bs.ScheduleTypeID
	and		bdi.ScheduleDateTypeID = bs.ScheduleDateTypeID
	and		bdi.ScheduleRangeTypeID = bs.ScheduleRangeTypeID
	and		bdi.IsActive = 1
	group by
			bs.ID
	)tt on tt.BillingScheduleID = bs.ID
WHERE bss.Name = 'PENDING' 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@BillingScheduleIDOperator','INT'),-1),
	T.c.value('@BillingScheduleIDValue','int') ,
	ISNULL(T.c.value('@ScheduleNameOperator','INT'),-1),
	T.c.value('@ScheduleNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ScheduleDateOperator','INT'),-1),
	T.c.value('@ScheduleDateValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeBeginOperator','INT'),-1),
	T.c.value('@ScheduleRangeBeginValue','datetime') ,
	ISNULL(T.c.value('@ScheduleRangeEndOperator','INT'),-1),
	T.c.value('@ScheduleRangeEndValue','datetime') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoicesToBeCreatedCountOperator','INT'),-1),
	T.c.value('@InvoicesToBeCreatedCountValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.BillingScheduleID,
	T.ScheduleName,
	T.ScheduleDate,
	T.ScheduleRangeBegin,
	T.ScheduleRangeEnd,
	T.Status,
	T.InvoicesToBeCreatedCount
FROM @QueryResult T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.BillingScheduleIDOperator = -1 ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 0 AND T.BillingScheduleID IS NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 1 AND T.BillingScheduleID IS NOT NULL ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 2 AND T.BillingScheduleID = TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 3 AND T.BillingScheduleID <> TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 7 AND T.BillingScheduleID > TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 8 AND T.BillingScheduleID >= TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 9 AND T.BillingScheduleID < TMP.BillingScheduleIDValue ) 
 OR 
	 ( TMP.BillingScheduleIDOperator = 10 AND T.BillingScheduleID <= TMP.BillingScheduleIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleNameOperator = -1 ) 
 OR 
	 ( TMP.ScheduleNameOperator = 0 AND T.ScheduleName IS NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 1 AND T.ScheduleName IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleNameOperator = 2 AND T.ScheduleName = TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 3 AND T.ScheduleName <> TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 4 AND T.ScheduleName LIKE TMP.ScheduleNameValue + '%') 
 OR 
	 ( TMP.ScheduleNameOperator = 5 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue ) 
 OR 
	 ( TMP.ScheduleNameOperator = 6 AND T.ScheduleName LIKE '%' + TMP.ScheduleNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ScheduleDateOperator = -1 ) 
 OR 
	 ( TMP.ScheduleDateOperator = 0 AND T.ScheduleDate IS NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 1 AND T.ScheduleDate IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleDateOperator = 2 AND T.ScheduleDate = TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 3 AND T.ScheduleDate <> TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 7 AND T.ScheduleDate > TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 8 AND T.ScheduleDate >= TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 9 AND T.ScheduleDate < TMP.ScheduleDateValue ) 
 OR 
	 ( TMP.ScheduleDateOperator = 10 AND T.ScheduleDate <= TMP.ScheduleDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeBeginOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 0 AND T.ScheduleRangeBegin IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 1 AND T.ScheduleRangeBegin IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 2 AND T.ScheduleRangeBegin = TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 3 AND T.ScheduleRangeBegin <> TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 7 AND T.ScheduleRangeBegin > TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 8 AND T.ScheduleRangeBegin >= TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 9 AND T.ScheduleRangeBegin < TMP.ScheduleRangeBeginValue ) 
 OR 
	 ( TMP.ScheduleRangeBeginOperator = 10 AND T.ScheduleRangeBegin <= TMP.ScheduleRangeBeginValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ScheduleRangeEndOperator = -1 ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 0 AND T.ScheduleRangeEnd IS NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 1 AND T.ScheduleRangeEnd IS NOT NULL ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 2 AND T.ScheduleRangeEnd = TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 3 AND T.ScheduleRangeEnd <> TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 7 AND T.ScheduleRangeEnd > TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 8 AND T.ScheduleRangeEnd >= TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 9 AND T.ScheduleRangeEnd < TMP.ScheduleRangeEndValue ) 
 OR 
	 ( TMP.ScheduleRangeEndOperator = 10 AND T.ScheduleRangeEnd <= TMP.ScheduleRangeEndValue ) 

 ) 

 AND 

 ( 
	 ( TMP.StatusOperator = -1 ) 
 OR 
	 ( TMP.StatusOperator = 0 AND T.Status IS NULL ) 
 OR 
	 ( TMP.StatusOperator = 1 AND T.Status IS NOT NULL ) 
 OR 
	 ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 3 AND T.Status <> TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 4 AND T.Status LIKE TMP.StatusValue + '%') 
 OR 
	 ( TMP.StatusOperator = 5 AND T.Status LIKE '%' + TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 6 AND T.Status LIKE '%' + TMP.StatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoicesToBeCreatedCountOperator = -1 ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 0 AND T.InvoicesToBeCreatedCount IS NULL ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 1 AND T.InvoicesToBeCreatedCount IS NOT NULL ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 2 AND T.InvoicesToBeCreatedCount = TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 3 AND T.InvoicesToBeCreatedCount <> TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 7 AND T.InvoicesToBeCreatedCount > TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 8 AND T.InvoicesToBeCreatedCount >= TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 9 AND T.InvoicesToBeCreatedCount < TMP.InvoicesToBeCreatedCountValue ) 
 OR 
	 ( TMP.InvoicesToBeCreatedCountOperator = 10 AND T.InvoicesToBeCreatedCount <= TMP.InvoicesToBeCreatedCountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'ASC'
	 THEN T.ScheduleName END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleName' AND @sortOrder = 'DESC'
	 THEN T.ScheduleName END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDate END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDate' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDate END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeBegin END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeBegin' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeBegin END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeEnd END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeEnd' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeEnd END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'InvoicesToBeCreatedCount' AND @sortOrder = 'ASC'
	 THEN T.InvoicesToBeCreatedCount END ASC, 
	 CASE WHEN @sortColumn = 'InvoicesToBeCreatedCount' AND @sortOrder = 'DESC'
	 THEN T.InvoicesToBeCreatedCount END DESC 


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
END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess] 
END 
GO
-- EXCE dms_Client_OpenPeriodProcess @billingSchedules = '1,2',@userName = 'demoUser',@sessionID = 'XX12',@pageReference = 'Test'
CREATE PROC [dbo].[dms_Client_OpenPeriodProcess](@billingSchedules NVARCHAR(MAX),@userName NVARCHAR(100),@sessionID NVARCHAR(MAX),@pageReference NVARCHAR(MAX))
AS
BEGIN
	
	DECLARE @BillingScheduleID AS TABLE(RecordID INT IDENTITY(1,1), BillingScheduleID INT)
	INSERT INTO @BillingScheduleID(BillingScheduleID) SELECT item FROM dbo.fnSplitString(@billingSchedules,',')
	DECLARE @scheduleID AS INT
	DECLARE @ProcessingCounter AS INT = 1
	DECLARE @TotalRows AS INT
	SELECT  @TotalRows = MAX(RecordID) FROM @BillingScheduleID
	
	DECLARE @entityID AS INT 
	DECLARE @eventID AS INT
	SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingInvoice'
	SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'

	WHILE @ProcessingCounter <= @TotalRows
	BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleID WHERE RecordID = @ProcessingCounter)
			
			-- Write Process Logic for Schedule ID

			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		 @scheduleID,
								 NULL,					NULL,						@userName,			GETDATE())
			
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(SCOPE_IDENTITY(),@entityID,@scheduleID)
			
			SET @ProcessingCounter = @ProcessingCounter + 1
	END
END


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_servicerequest_history_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_servicerequest_history_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="ServiceRequest" IDValue="1234" NameType="" NameValue="" LastName="" FilterType = "StartsWith" FromDate = "" ToDate = "" Preset ="" Clients ="1" Programs ="" ServiceRequestStatuses = "" ServiceTypes ="" IsGOA = "" IsRedispatched = "" IsPossibleTow ="" VehicleType ="1" VehicleYear ="2012" VehicleMake = "" VehicleModel = "" PaymentByCheque = "" PaymentByCard = "" MemberPaid ="" POStatuses =""/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = NULL, @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Service Request" IDValue="2"/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'

CREATE PROCEDURE [dbo].[dms_servicerequest_history_list]( 
	@whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10   
 , @sortColumn nvarchar(100)  = 'RequestNumber'   
 , @sortOrder nvarchar(100) = 'ASC'
 , @userID UNIQUEIDENTIFIER = NULL
) 
AS
BEGIN
	
	SET FMTONLY OFF;
	-- Temporary tables to hold the results until the final resultset.
	CREATE TABLE #Raw	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		FirstName NVARCHAR(50)  NULL ,    
		LastName NVARCHAR(50)  NULL ,  
		MiddleName NVARCHAR(50)  NULL ,  
		Suffix NVARCHAR(50)  NULL ,    
		Prefix NVARCHAR(50)  NULL ,
		MemberNumber NVARCHAR(50) NULL, 
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Filtered	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		FirstName NVARCHAR(50)  NULL ,    
		LastName NVARCHAR(50)  NULL ,  
		MiddleName NVARCHAR(50)  NULL ,  
		Suffix NVARCHAR(50)  NULL ,    
		Prefix NVARCHAR(50)  NULL , 
		MemberNumber NVARCHAR(50) NULL,
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Formatted	
	(
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		MemberName NVARCHAR(255)  NULL ,
		MemberNumber NVARCHAR(50) NULL,    		
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,		
		VehicleModel NVARCHAR(255) NULL,		
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #Sorted
	(
		RowNum INT NOT NULL IDENTITY(1,1),
		RequestNumber INT NOT NULL,
		CaseID INT NOT NULL,
		ProgramID INT NULL,
		Program NVARCHAR(50) NULL,
		ClientID INT NULL,
		Client NVARCHAR(50) NULL,
		MemberName NVARCHAR(255)  NULL , 
		MemberNumber NVARCHAR(50) NULL,   		
		CreateDate DATETIME NULL,
		POCreateBy NVARCHAR(50) NULL,
		POModifyBy NVARCHAR(50) NULL,
		SRCreateBy NVARCHAR(50) NULL,
		SRModifyBy NVARCHAR(50) NULL,
		VIN NVARCHAR(50) NULL,
		VehicleTypeID INT NULL,
		VehicleType NVARCHAR(50) NULL,
		ServiceTypeID INT NULL, 
		ServiceType nvarchar(100) NULL,		 
		StatusID INT NULL,
		[Status] NVARCHAR(100) NULL,
		PriorityID INT NULL,
		[Priority] NVARCHAR(100) NULL,
		ISPName NVARCHAR(255) NULL,
		VendorNumber NVARCHAR(50) NULL,
		PONumber NVARCHAR(50) NULL,
		PurchaseOrderStatusID INT NULL,
		PurchaseOrderStatus NVARCHAR(50) NULL, 
		PurchaseOrderAmount money NULL,
		AssignedToUserID INT NULL,
		NextActionAssignedToUserID INT NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow BIT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		PaymentByCard BIT NULL
	)
	
	CREATE TABLE #tmpVehicle
	(
		VIN NVARCHAR(50) NULL,
		MemberID INT NULL,
		MembershipID INT NULL
	)
	
	DECLARE @totalRows INT = 0

	DECLARE @tmpWhereClause TABLE
	(	
		IDType NVARCHAR(255) NULL,
		IDValue NVARCHAR(255) NULL,
		NameType NVARCHAR(255) NULL,
		NameValue NVARCHAR(255) NULL,
		LastName NVARCHAR(255) NULL, -- If name type = Member, then firstname goes into namevalue and last name goes into this field.
		FilterType NVARCHAR(100) NULL,
		FromDate DATETIME NULL,
		ToDate DATETIME NULL,
		Preset NVARCHAR(100) NULL,
		Clients NVARCHAR(MAX) NULL,
		Programs NVARCHAR(MAX) NULL,
		ServiceRequestStatuses NVARCHAR(MAX) NULL,
		ServiceTypes NVARCHAR(MAX) NULL,
		IsGOA BIT NULL,
		IsRedispatched BIT NULL,
		IsPossibleTow  BIT NULL,		
		VehicleType INT NULL,
		VehicleYear INT NULL,
		VehicleMake NVARCHAR(255) NULL,
		VehicleMakeOther NVARCHAR(255) NULL,
		VehicleModel NVARCHAR(255) NULL,
		VehicleModelOther NVARCHAR(255) NULL,
		PaymentByCheque BIT NULL,
		PaymentByCard BIT NULL,
		MemberPaid BIT NULL,
		POStatuses NVARCHAR(MAX) NULL
	)
	
	DECLARE @IDType NVARCHAR(255) ,
			@IDValue NVARCHAR(255) ,
			@NameType NVARCHAR(255) ,
			@NameValue NVARCHAR(255) ,
			@LastName NVARCHAR(255) , 
			@FilterType NVARCHAR(100) ,
			@FromDate DATETIME ,
			@ToDate DATETIME ,
			@Preset NVARCHAR(100) ,
			@Clients NVARCHAR(MAX) ,
			@Programs NVARCHAR(MAX) ,
			@ServiceRequestStatuses NVARCHAR(MAX) ,
			@ServiceTypes NVARCHAR(MAX) ,
			@IsGOA BIT ,
			@IsRedispatched BIT ,
			@IsPossibleTow  BIT ,		
			@VehicleType INT ,
			@VehicleYear INT ,
			@VehicleMake NVARCHAR(255) ,
			@VehicleMakeOther NVARCHAR(255) ,
			@VehicleModel NVARCHAR(255) ,
			@VehicleModelOther NVARCHAR(255) ,
			@PaymentByCheque BIT ,
			@PaymentByCard BIT ,
			@MemberPaid BIT ,
			@POStatuses NVARCHAR(MAX) 
	
	DECLARE @idoc int
	EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML 
	
	INSERT INTO @tmpWhereClause  
	SELECT	IDType,
			IDValue,
			NameType,
			NameValue,
			LastName,
			FilterType,
			FromDate,
			ToDate,
			Preset,
			Clients,
			Programs,
			ServiceRequestStatuses,
			ServiceTypes,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleType,
			VehicleYear,
			VehicleMake,
			VehicleMakeOther,
			VehicleModel,
			VehicleModelOther,
			PaymentByCheque,
			PaymentByCard,
			MemberPaid,
			POStatuses
	FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH ( 
	
			IDType NVARCHAR(255) ,
			IDValue NVARCHAR(255) ,
			NameType NVARCHAR(255) ,
			NameValue NVARCHAR(255) ,
			LastName NVARCHAR(255) ,
			FilterType NVARCHAR(100) ,
			FromDate DATETIME ,
			ToDate DATETIME ,
			Preset NVARCHAR(100) ,
			Clients NVARCHAR(MAX) ,
			Programs NVARCHAR(MAX) ,
			ServiceRequestStatuses NVARCHAR(MAX) ,
			ServiceTypes NVARCHAR(MAX) ,
			IsGOA BIT,
			IsRedispatched BIT,
			IsPossibleTow BIT,			
			VehicleType INT ,
			VehicleYear INT ,
			VehicleMake NVARCHAR(255) ,
			VehicleMakeOther NVARCHAR(255) ,
			VehicleModel NVARCHAR(255) ,
			VehicleModelOther NVARCHAR(255) ,
			PaymentByCheque BIT ,
			PaymentByCard BIT ,
			MemberPaid BIT ,
			POStatuses NVARCHAR(MAX) 	
	)
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	
	DECLARE @strClients NVARCHAR(MAX)
	DECLARE @tmpClients TABLE
	(
		ID INT NOT NULL
	)	
	DECLARE @strPrograms NVARCHAR(MAX)
	DECLARE @tmpPrograms TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strServiceRequestStatuses NVARCHAR(MAX)
	DECLARE @tmpServiceRequestStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	DECLARE @strServiceTypes NVARCHAR(MAX)
	DECLARE @tmpServiceTypes TABLE
	(
		ID INT NOT NULL
	)
	DECLARE @strPOStatuses NVARCHAR(MAX)
	DECLARE @tmpPOStatuses TABLE
	(
		ID INT NOT NULL
	)
	
	-- Extract some of the values into separate tables for ease of processing.
	SELECT	@strClients = Clients,
			@strPOStatuses = POStatuses,
			@strPrograms = Programs,
			@strServiceRequestStatuses = ServiceRequestStatuses,
			@strServiceTypes = ServiceTypes			
	FROM	@tmpWhereClause
	
	-- Clients
	INSERT INTO @tmpClients
	SELECT item FROM fnSplitString(@strClients,',')
	
	-- Programs
	INSERT INTO @tmpPrograms
	SELECT item FROM fnSplitString(@strPrograms,',')
	
	-- POStatuses
	INSERT INTO @tmpPOStatuses
	SELECT item FROM fnSplitString(@strPOStatuses,',')
	
	-- Service request statuses
	INSERT INTO @tmpServiceRequestStatuses
	SELECT item FROM fnSplitString(@strServiceRequestStatuses,',')
	
	-- Service types
	INSERT INTO @tmpServiceTypes
	SELECT item FROM fnSplitString(@strServiceTypes,',')
	
	
	SELECT	@IDType = T.IDType,			
			@IDValue = T.IDValue,
			@NameType = T.NameType,
			@NameValue = T.NameValue,
			@LastName = T.LastName, 
			@FilterType = T.FilterType,
			@FromDate = T.FromDate,
			@ToDate = T.ToDate,
			@Preset = T.Preset,
			@IsGOA = T.IsGOA,
			@IsRedispatched = T.IsRedispatched,
			@IsPossibleTow  = T.IsPossibleTow,		
			@VehicleType = T.VehicleType,
			@VehicleYear = T.VehicleYear,
			@VehicleMake = T.VehicleMake,
			@VehicleMakeOther = T.VehicleMakeOther,
			@VehicleModel = T.VehicleModel,
			@VehicleModelOther = T.VehicleModelOther,
			@PaymentByCheque = T.PaymentByCheque,
			@PaymentByCard = T.PaymentByCard ,
			@MemberPaid = T.MemberPaid
	FROM	@tmpWhereClause T
	
	DECLARE @vinParam NVARCHAR(50) = NULL
	SELECT	@vinParam = IDValue 
	FROM	@tmpWhereClause
	WHERE	IDType = 'VIN'
	
	--IF ISNULL(@vinParam,'') <> ''
	--BEGIN
	
	--	INSERT INTO #tmpVehicle
	--	SELECT	V.VIN,
	--			V.MemberID,
	--			V.MembershipID
	--	FROM	Vehicle V WITH (NOLOCK)
	--	WHERE	V.VIN = @vinParam
	--	--V.VIN LIKE '%' + @vinParam + '%'
		
	--END
	
	INSERT INTO #Filtered
	SELECT  
			--DISTINCT  
			SR.ID AS [RequestNumber],  
			SR.CaseID AS [Case],
			P.ProgramID,
			P.ProgramName AS [Program],
			CL.ID AS ClientID,
			CL.Name AS [Client], 			
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,   
			MS.MembershipNumber AS MemberNumber,  			
			SR.CreateDate,
			PO.CreateBy,
			PO.ModifyBy,
			SR.CreateBy,
			SR.ModifyBy,
			--TV.VIN,
			C.VehicleVIN AS VIN, -- KB: VIN Issue
			VT.ID As VehicleTypeID,
			VT.Name AS VehicleType,						
			PC.ID AS [ServiceTypeID],
			PC.Name AS [ServiceType],			  
			SRS.ID AS [StatusID],
			CASE ISNULL(SR.IsRedispatched,0) WHEN 1 THEN SRS.Name + '^' ELSE SRS.Name END AS [Status],
			SR.ServiceRequestPriorityID AS [PriorityID],  
			SRP.Name AS [Priority],			
			V.Name AS [ISPName], 
			V.VendorNumber, 
			PO.PurchaseOrderNumber AS [PONumber], 
			POS.ID AS PurchaseOrderStatusID,
			POS.Name AS PurchaseOrderStatus,
			PO.PurchaseOrderAmount,			   
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,			
			PO.IsGOA,
			SR.IsRedispatched,
			SR.IsPossibleTow,
			C.VehicleYear,
			C.VehicleMake,
			C.VehicleMakeOther,
			C.VehicleModel,
			C.VehicleModelOther,
			PO.IsPayByCompanyCreditCard
			
	FROM	ServiceRequest SR WITH (NOLOCK)	
	--LEFT JOIN	@tmpWhereClause TMP ON 1=1	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C WITH (NOLOCK) on C.ID = SR.CaseID
	JOIN	dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	LEFT JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID   
	LEFT JOIN [VehicleType] VT WITH (NOLOCK) ON VT.ID = C.VehicleTypeID
	LEFT JOIN (  
			SELECT ROW_NUMBER() OVER (PARTITION BY ServiceRequestID ORDER BY CreateDate DESC) AS RowNum,  
			ID,  
			PurchaseOrderNumber, 
			PurchaseOrderStatusID, 
			ServiceRequestID,  
			VendorLocationID,
			PurchaseOrderAmount,
			TPO.IsGOA,
			TPO.IsPayByCompanyCreditCard,
			TPO.CreateBy,
			TPO.ModifyBy			   
			FROM PurchaseOrder TPO WITH (NOLOCK)
			--LEFT JOIN	 @tmpWhereClause TMP   ON 1=1
			WHERE ( (@IDType IS NULL) OR (@IDType <> 'Purchase Order') OR (@IDType = 'Purchase Order' AND PurchaseOrderNumber = @IDValue))
	) PO ON SR.ID = PO.ServiceRequestID AND PO.RowNum = 1  
	
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON PO.PurchaseOrderStatusID = POS.ID
	LEFT JOIN	[NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN	[VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN	[Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID
	--LEFT JOIN	#tmpVehicle TV ON (TV.MemberID IS NULL OR TV.MemberID = M.ID) 
	
	-- DEBUG:
	--SELECT * FROM @tmpWhereClause
	--SELECT * FROM #Raw
	
	-- Apply filter on the #Raw
	--INSERT INTO #Filtered 
	--		(
	--		RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		VehicleType,
	--		ServiceTypeID,
	--		ServiceType,
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus,
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		IsGOA,
	--		IsRedispatched,
	--		IsPossibleTow,
	--		VehicleYear,
	--		VehicleMake,
	--		VehicleMakeOther,
	--		VehicleModel,
	--		VehicleModelOther,
	--		PaymentByCard
	--		)
				
	--SELECT	RequestNumber,
	--		CaseID,
	--		ProgramID,
	--		Program,
	--		ClientID,
	--		Client,
	--		FirstName,
	--		R.LastName,
	--		MiddleName,
	--		Suffix,
	--		Prefix,
	--		MemberNumber,
	--		CreateDate,
	--		POCreateBy,
	--		POModifyBy,
	--		SRCreateBy,
	--		SRModifyBy,
	--		VIN,
	--		VehicleTypeID,
	--		R.VehicleType,
	--		ServiceTypeID, 
	--		ServiceType,		 
	--		StatusID,
	--		[Status],
	--		PriorityID,
	--		[Priority],
	--		ISPName,
	--		VendorNumber,
	--		PONumber,
	--		PurchaseOrderStatusID,
	--		PurchaseOrderStatus, 
	--		PurchaseOrderAmount,
	--		AssignedToUserID,
	--		NextActionAssignedToUserID,
	--		R.IsGOA,
	--		R.IsRedispatched,
	--		R.IsPossibleTow,
	--		R.VehicleYear,
	--		R.VehicleMake,
	--		R.VehicleMakeOther,
	--		R.VehicleModel,
	--		R.VehicleModelOther,
	--		R.PaymentByCard	
	--FROM	#Raw R
	--LEFT JOIN	@tmpWhereClause T ON 1=1
	WHERE	
	(
	
		-- IDs
		(
			(@IDType IS NULL)
			OR
			(@IDType = 'Purchase Order' AND PO.PurchaseOrderNumber = CONVERT(NVARCHAR(50),@IDValue))
			OR
			(@IDType = 'Service Request' AND @IDValue = CONVERT(NVARCHAR(50),SR.ID))
			OR
			(@IDType = 'ISP' AND V.VendorNumber =  CONVERT(NVARCHAR(50),@IDValue) )
			OR
			(@IDType = 'Member' AND MS.MembershipNumber = CONVERT(NVARCHAR(50),@IDValue))			 
			OR
			(@IDType = 'VIN' AND C.VehicleVIN = CONVERT(NVARCHAR(50),@IDValue))
		)
	
		AND
		-- Names
		(
				(@FilterType IS NULL)
				OR
				(@FilterType = 'Is equal to' 
					AND (
							(@NameType = 'ISP' AND V.Name = @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName = @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName = @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy = @NameValue 
																				OR 
																				SR.ModifyBy = @NameValue 
																				OR 
																				PO.CreateBy = @NameValue 
																				OR 
																				PO.ModifyBy = @NameValue 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Starts with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  @NameValue + '%'
																				OR 
																				PO.CreateBy LIKE  @NameValue + '%'
																				OR 
																				PO.ModifyBy LIKE  @NameValue + '%'
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Contains' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue + '%')
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue + '%'))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName + '%'))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue + '%' 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue + '%' 
																			)) )
											
											)
							)		
						)
				)
				OR
				(@FilterType = 'Ends with' 
					AND (
							(@NameType = 'ISP' AND V.Name LIKE  '%' + @NameValue)
							OR
							(@NameType = 'Member' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL AND M.FirstName LIKE  '%' + @NameValue))
												AND
												(@LastName IS NULL OR (@LastName IS NOT NULL AND M.LastName LIKE  '%' + @LastName))
											)
										)
							OR
							(@NameType = 'User' AND 
											(
												(@NameValue IS NULL OR (@NameValue IS NOT NULL 
																			AND 
																			(	SR.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				SR.ModifyBy LIKE  '%' + @NameValue 
																				OR 
																				PO.CreateBy LIKE  '%' + @NameValue 
																				OR 
																				PO.ModifyBy LIKE  '%' + @NameValue 
																			)) )
											
											)
							)		
						)
				)
			
		)
	
		AND
		-- Date Range
		(
				(@Preset IS NOT NULL AND	(
											(@Preset = 'Last 7 days' AND DATEDIFF(WK,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 30 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 1)
											OR
											(@Preset = 'Last 90 days' AND DATEDIFF(M,SR.CreateDate,GETDATE()) <= 3)
											)
				)
				OR
				(
					(@Preset IS NULL AND	(	( @FromDate IS NULL OR (@FromDate IS NOT NULL AND SR.CreateDate >= @FromDate))
											AND
												( @ToDate IS NULL OR (@ToDate IS NOT NULL AND SR.CreateDate <= @ToDate))
											)
					)
				)
		)
		AND
		-- Clients
		(
				(	ISNULL(@strClients,'') = '' OR ( CL.ID IN (SELECT ID FROM @tmpClients) ))
		)
		AND
		-- Programs
		(
				(	ISNULL(@strPrograms,'') = '' OR ( P.ProgramID IN (SELECT ID FROM @tmpPrograms) ))
		)
		AND
		-- SR Statuses
		(
				(	ISNULL(@strServiceRequestStatuses,'') = '' OR ( SRS.ID IN (SELECT ID FROM @tmpServiceRequestStatuses) ))
		)
		AND
		-- Service types
		(
				(	ISNULL(@strServiceTypes,'') = '' OR ( PC.ID IN (SELECT ID FROM @tmpServiceTypes) ))
		)
		AND
		-- Special flags
		(
				( @IsGOA IS NULL OR (PO.IsGOA = @IsGOA))
				AND
				( @IsPossibleTow IS NULL OR (SR.IsPossibleTow = @IsPossibleTow))
				AND
				( @IsRedispatched IS NULL OR (SR.IsRedispatched = @IsRedispatched))
		)
		AND
		-- Vehicle
		(
				(@VehicleType IS NULL OR (C.VehicleTypeID = @VehicleType))
				AND
				(@VehicleYear IS NULL OR (C.VehicleYear = @VehicleYear))
				AND
				(@VehicleMake IS NULL OR ( (C.VehicleMake = @VehicleMake) OR (@VehicleMake = 'Other' AND C.VehicleMake = 'Other' AND C.VehicleMakeOther = @VehicleMakeOther ) ) )
				AND
				(@VehicleModel IS NULL OR ( (C.VehicleModel = @VehicleModel) OR (@VehicleModel = 'Other' AND C.VehicleModel = 'Other' AND C.VehicleModelOther = @VehicleModelOther) ) )
		)
		AND
		-- Payment Type
		(
				( @PaymentByCheque IS NULL OR ( @PaymentByCheque = 1 AND PO.IsPayByCompanyCreditCard = 0 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @PaymentByCard IS NULL OR ( @PaymentByCard = 1 AND PO.IsPayByCompanyCreditCard = 1 AND PO.PurchaseOrderAmount > 0 ) )
				AND
				( @MemberPaid IS NULL OR ( @MemberPaid = 1 AND POS.Name = 'Issue-Paid' AND PO.PurchaseOrderAmount > 0 ))
		)
		AND
		-- PurchaseOrder status
		(
				(	ISNULL(@strPOStatuses,'') = '' OR ( PO.PurchaseOrderStatusID IN (SELECT ID FROM @tmpPOStatuses) ))
		)
	)
	
	-- DEBUG:
	--SELECT 'Filtered', * FROM #Filtered
	
	-- Format the data [ Member name, vehiclemake, model, etc]
	INSERT INTO #Formatted 
			(
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard
			)
				
	SELECT	RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			REPLACE(RTRIM( 
				COALESCE(FirstName, '') + 
				COALESCE(' ' + left(MiddleName,1), '') + 
				COALESCE(' ' + LastName, '') +
				COALESCE(' ' + Suffix, '')
				), ' ', ' ') AS MemberName, 
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			CASE WHEN VehicleMake = 'Other' THEN VehicleMakeOther ELSE VehicleMake END AS VehicleMake,
			CASE WHEN VehicleModel = 'Other' THEN VehicleModelOther ELSE VehicleModel END AS VehicleModel,			
			PaymentByCard	
	FROM	#Filtered R
	
	
	
	-- Apply sorting
	INSERT INTO #Sorted 
			(
			RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName,
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,			
			VehicleModel,			
			PaymentByCard
			)
				
	SELECT	RequestNumber,
			CaseID,
			ProgramID,
			Program,
			ClientID,
			Client,
			MemberName, 
			MemberNumber,
			CreateDate,
			POCreateBy,
			POModifyBy,
			SRCreateBy,
			SRModifyBy,
			VIN,
			VehicleTypeID,
			VehicleType,
			ServiceTypeID,
			ServiceType,
			StatusID,
			[Status],
			PriorityID,
			[Priority],
			ISPName,
			VendorNumber,
			PONumber,
			PurchaseOrderStatusID,
			PurchaseOrderStatus,
			PurchaseOrderAmount,
			AssignedToUserID,
			NextActionAssignedToUserID,
			IsGOA,
			IsRedispatched,
			IsPossibleTow,
			VehicleYear,
			VehicleMake,
			VehicleModel,			
			PaymentByCard	
	FROM	#Formatted F
	ORDER BY     
		CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'    
		THEN F.RequestNumber END ASC,     
		CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'    
		THEN F.RequestNumber END DESC ,
		
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'    
		THEN F.Program END ASC,     
		CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'    
		THEN F.Program END DESC ,
		
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'    
		THEN F.CreateDate END ASC,     
		CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'    
		THEN F.CreateDate END DESC ,
		
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'    
		THEN F.MemberName END ASC,     
		CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'    
		THEN F.MemberName END DESC ,
		
		CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'    
		THEN F.VehicleType END ASC,     
		CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'    
		THEN F.VehicleType END DESC ,
		
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'    
		THEN F.ServiceType END ASC,     
		CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'    
		THEN F.ServiceType END DESC ,
		
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'    
		THEN F.[Status] END ASC,     
		CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'    
		THEN F.[Status] END DESC ,
		
		CASE WHEN @sortColumn = 'ISP' AND @sortOrder = 'ASC'    
		THEN F.[ISPName] END ASC,     
		CASE WHEN @sortColumn = 'ISP' AND @sortOrder = 'DESC'    
		THEN F.ISPName END DESC ,
		
		CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
		THEN F.PONumber END ASC,     
		CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
		THEN F.PONumber END DESC ,
		
		CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderStatus END ASC,     
		CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderStatus END DESC ,
		
		CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'    
		THEN F.PurchaseOrderAmount END ASC,     
		CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'    
		THEN F.PurchaseOrderAmount END DESC
		
	
	 
	SET @totalRows = 0  
	SELECT @totalRows = MAX(RowNum) FROM #Sorted  
	SET @endInd = @startInd + @pageSize - 1  
	IF @startInd > @totalRows  
	BEGIN  
	 DECLARE @numOfPages INT  
	 SET @numOfPages = @totalRows / @pageSize  
	IF @totalRows % @pageSize > 1  
	BEGIN  
	 SET @numOfPages = @numOfPages + 1  
	END  
	 SET @startInd = ((@numOfPages - 1) * @pageSize) + 1  
	 SET @endInd = @numOfPages * @pageSize  
	END  
	
	-- Take the required set (say 10 out of "n").	
	SELECT @totalRows AS TotalRows, * FROM #Sorted F WHERE F.RowNum BETWEEN @startInd AND @endInd
	
	DROP TABLE #Raw
	DROP TABLE #Filtered
	DROP TABLE #Formatted
	DROP TABLE #Sorted

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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_List]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'CreateDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
      SET FMTONLY OFF;
     SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
      SET @whereClauseXML = '<ROW><Filter 

></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BatchStatusID int NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)
CREATE TABLE #FinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,    
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL
) 

CREATE TABLE #tmpFinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,     
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL
) 

INSERT INTO #tmpForWhereClause
SELECT 
      T.c.value('@BatchStatusID','int') ,
      T.c.value('@FromDate','datetime') ,
      T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @batchStatusID NVARCHAR(100) = NULL,
            @fromDate DATETIME = NULL,
            @toDate DATETIME = NULL
            
SELECT      @batchStatusID = BatchStatusID, 
            @fromDate = FromDate,
            @toDate = ToDate
FROM  #tmpForWhereClause
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT      B.ID
            , BT.[Description] AS BatchType
            , B.BatchStatusID
            , BS.Name AS BatchStatus
            , B.TotalCount AS TotalCount
            , B.TotalAmount AS TotalAmount
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy 
           
FROM  Batch B
JOIN  BatchType BT ON BT.ID = B.BatchTypeID
JOIN  BatchStatus BS ON BS.ID = B.BatchStatusID
WHERE B.BatchTypeID = (SELECT ID FROM BatchType WHERE Name = 'TemporaryCCPost')
AND         (@batchStatusID IS NULL OR @batchStatusID = B.BatchStatusID)
AND         (@fromDate IS NULL OR B.CreateDate > @fromDate)
AND         (@toDate IS NULL OR B.CreateDate < @toDate)
GROUP BY    B.ID
            , BT.[Description] 
            , B.BatchStatusID
            , BS.Name  
            , B.TotalCount
            , B.TotalAmount         
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy
ORDER BY B.CreateDate DESC



INSERT INTO #FinalResults
SELECT 
      T.ID,
      T.BatchType,
      T.BatchStatusID,
      T.BatchStatus,
      T.TotalCount,
      T.TotalAmount,    
      T.CreateDate,
      T.CreateBy,
      T.ModifyDate,
      T.ModifyBy    
      
FROM #tmpFinalResults T

ORDER BY 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
      THEN T.ID END ASC, 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
      THEN T.ID END DESC ,

      CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'ASC'
      THEN T.BatchType END ASC, 
       CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'DESC'
      THEN T.BatchType END DESC ,

      CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'ASC'
      THEN T.BatchStatusID END ASC, 
       CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'DESC'
      THEN T.BatchStatusID END DESC ,

      CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'ASC'
      THEN T.BatchStatus END ASC, 
       CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'DESC'
      THEN T.BatchStatus END DESC ,

      CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'ASC'
      THEN T.TotalCount END ASC, 
       CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'DESC'
      THEN T.TotalCount END DESC ,

      CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'ASC'
      THEN T.TotalAmount END ASC, 
       CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'DESC'
      THEN T.TotalAmount END DESC ,     

      CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
      THEN T.CreateDate END ASC, 
       CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
      THEN T.CreateDate END DESC ,

      CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
      THEN T.CreateBy END ASC, 
       CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
      THEN T.CreateBy END DESC ,

      CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
      THEN T.ModifyDate END ASC, 
       CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
      THEN T.ModifyDate END DESC ,

      CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
      THEN T.ModifyBy END ASC, 
       CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
      THEN T.ModifyBy END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @BatchID INT = NULL  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
TemporaryCCIDOperator="-1" 
TemporaryCCNumberOperator="-1" 
CCIssueDateOperator="-1" 
CCIssueByOperator="-1" 
CCApproveOperator="-1" 
CCChargeOperator="-1" 
POIDOperator="-1" 
PONumberOperator="-1" 
POAmountOperator="-1" 
InvoiceIDOperator="-1" 
InvoiceNumberOperator="-1" 
InvoiceAmountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
TemporaryCCIDOperator INT NOT NULL,
TemporaryCCIDValue int NULL,
TemporaryCCNumberOperator INT NOT NULL,
TemporaryCCNumberValue nvarchar(100) NULL,
CCIssueDateOperator INT NOT NULL,
CCIssueDateValue datetime NULL,
CCIssueByOperator INT NOT NULL,
CCIssueByValue nvarchar(100) NULL,
CCApproveOperator INT NOT NULL,
CCApproveValue money NULL,
CCChargeOperator INT NOT NULL,
CCChargeValue money NULL,
POIDOperator INT NOT NULL,
POIDValue int NULL,
PONumberOperator INT NOT NULL,
PONumberValue nvarchar(100) NULL,
POAmountOperator INT NOT NULL,
POAmountValue money NULL,
InvoiceIDOperator INT NOT NULL,
InvoiceIDValue int NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
InvoiceAmountOperator INT NOT NULL,
InvoiceAmountValue money NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@TemporaryCCIDOperator','INT'),-1),
	T.c.value('@TemporaryCCIDValue','int') ,
	ISNULL(T.c.value('@TemporaryCCNumberOperator','INT'),-1),
	T.c.value('@TemporaryCCNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCIssueDateOperator','INT'),-1),
	T.c.value('@CCIssueDateValue','datetime') ,
	ISNULL(T.c.value('@CCIssueByOperator','INT'),-1),
	T.c.value('@CCIssueByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCApproveOperator','INT'),-1),
	T.c.value('@CCApproveValue','money') ,
	ISNULL(T.c.value('@CCChargeOperator','INT'),-1),
	T.c.value('@CCChargeValue','money') ,
	ISNULL(T.c.value('@POIDOperator','INT'),-1),
	T.c.value('@POIDValue','int') ,
	ISNULL(T.c.value('@PONumberOperator','INT'),-1),
	T.c.value('@PONumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POAmountOperator','INT'),-1),
	T.c.value('@POAmountValue','money') ,
	ISNULL(T.c.value('@InvoiceIDOperator','INT'),-1),
	T.c.value('@InvoiceIDValue','int') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceAmountOperator','INT'),-1),
	T.c.value('@InvoiceAmountValue','money') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT 
  TCC.ID AS TemporaryCCID
, TCC.CreditCardNumber AS TemporaryCCNumber
, TCC.IssueDate AS CCIssueDate
, TCC.IssueBy AS CCIssueBy
, TCC.ApprovedAmount AS CCApprove
, TCC.TotalChargedAmount AS CCCharge
, PO.ID AS POID
, PO.PurchaseOrderNumber AS PONumber
, PO.PurchaseOrderAmount AS POAmount 
, VI.ID AS InvoiceID
, VI.InvoiceNumber AS InvoiceNumber
, VI.InvoiceAmount AS InvoiceAmount
FROM	TemporaryCreditCard TCC
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN   VendorInvoice VI ON VI.PurchaseOrderID = PO.ID
WHERE TCC.PostingBatchID = @BatchID

INSERT INTO #FinalResults
SELECT 
	T.TemporaryCCID,
	T.TemporaryCCNumber,
	T.CCIssueDate,
	T.CCIssueBy,
	T.CCApprove,
	T.CCCharge,
	T.POID,
	T.PONumber,
	T.POAmount,
	T.InvoiceID,
	T.InvoiceNumber,
	T.InvoiceAmount
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.TemporaryCCIDOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 0 AND T.TemporaryCCID IS NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 1 AND T.TemporaryCCID IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 2 AND T.TemporaryCCID = TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 3 AND T.TemporaryCCID <> TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 7 AND T.TemporaryCCID > TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 8 AND T.TemporaryCCID >= TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 9 AND T.TemporaryCCID < TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 10 AND T.TemporaryCCID <= TMP.TemporaryCCIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.TemporaryCCNumberOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 0 AND T.TemporaryCCNumber IS NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 1 AND T.TemporaryCCNumber IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 2 AND T.TemporaryCCNumber = TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 3 AND T.TemporaryCCNumber <> TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 4 AND T.TemporaryCCNumber LIKE TMP.TemporaryCCNumberValue + '%') 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 5 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 6 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCIssueDateOperator = -1 ) 
 OR 
	 ( TMP.CCIssueDateOperator = 0 AND T.CCIssueDate IS NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 1 AND T.CCIssueDate IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 2 AND T.CCIssueDate = TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 3 AND T.CCIssueDate <> TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 7 AND T.CCIssueDate > TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 8 AND T.CCIssueDate >= TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 9 AND T.CCIssueDate < TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 10 AND T.CCIssueDate <= TMP.CCIssueDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCIssueByOperator = -1 ) 
 OR 
	 ( TMP.CCIssueByOperator = 0 AND T.CCIssueBy IS NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 1 AND T.CCIssueBy IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 2 AND T.CCIssueBy = TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 3 AND T.CCIssueBy <> TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 4 AND T.CCIssueBy LIKE TMP.CCIssueByValue + '%') 
 OR 
	 ( TMP.CCIssueByOperator = 5 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 6 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCApproveOperator = -1 ) 
 OR 
	 ( TMP.CCApproveOperator = 0 AND T.CCApprove IS NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 1 AND T.CCApprove IS NOT NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 2 AND T.CCApprove = TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 3 AND T.CCApprove <> TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 7 AND T.CCApprove > TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 8 AND T.CCApprove >= TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 9 AND T.CCApprove < TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 10 AND T.CCApprove <= TMP.CCApproveValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCChargeOperator = -1 ) 
 OR 
	 ( TMP.CCChargeOperator = 0 AND T.CCCharge IS NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 1 AND T.CCCharge IS NOT NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 2 AND T.CCCharge = TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 3 AND T.CCCharge <> TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 7 AND T.CCCharge > TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 8 AND T.CCCharge >= TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 9 AND T.CCCharge < TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 10 AND T.CCCharge <= TMP.CCChargeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.POIDOperator = -1 ) 
 OR 
	 ( TMP.POIDOperator = 0 AND T.POID IS NULL ) 
 OR 
	 ( TMP.POIDOperator = 1 AND T.POID IS NOT NULL ) 
 OR 
	 ( TMP.POIDOperator = 2 AND T.POID = TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 3 AND T.POID <> TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 7 AND T.POID > TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 8 AND T.POID >= TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 9 AND T.POID < TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 10 AND T.POID <= TMP.POIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PONumberOperator = -1 ) 
 OR 
	 ( TMP.PONumberOperator = 0 AND T.PONumber IS NULL ) 
 OR 
	 ( TMP.PONumberOperator = 1 AND T.PONumber IS NOT NULL ) 
 OR 
	 ( TMP.PONumberOperator = 2 AND T.PONumber = TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 3 AND T.PONumber <> TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 4 AND T.PONumber LIKE TMP.PONumberValue + '%') 
 OR 
	 ( TMP.PONumberOperator = 5 AND T.PONumber LIKE '%' + TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 6 AND T.PONumber LIKE '%' + TMP.PONumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POAmountOperator = -1 ) 
 OR 
	 ( TMP.POAmountOperator = 0 AND T.POAmount IS NULL ) 
 OR 
	 ( TMP.POAmountOperator = 1 AND T.POAmount IS NOT NULL ) 
 OR 
	 ( TMP.POAmountOperator = 2 AND T.POAmount = TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 3 AND T.POAmount <> TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 7 AND T.POAmount > TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 8 AND T.POAmount >= TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 9 AND T.POAmount < TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 10 AND T.POAmount <= TMP.POAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceIDOperator = -1 ) 
 OR 
	 ( TMP.InvoiceIDOperator = 0 AND T.InvoiceID IS NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 1 AND T.InvoiceID IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 2 AND T.InvoiceID = TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 3 AND T.InvoiceID <> TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 7 AND T.InvoiceID > TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 8 AND T.InvoiceID >= TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 9 AND T.InvoiceID < TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 10 AND T.InvoiceID <= TMP.InvoiceIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceNumberOperator = -1 ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 0 AND T.InvoiceNumber IS NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 1 AND T.InvoiceNumber IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 2 AND T.InvoiceNumber = TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 3 AND T.InvoiceNumber <> TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 4 AND T.InvoiceNumber LIKE TMP.InvoiceNumberValue + '%') 
 OR 
	 ( TMP.InvoiceNumberOperator = 5 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue ) 
 OR 
	 ( TMP.InvoiceNumberOperator = 6 AND T.InvoiceNumber LIKE '%' + TMP.InvoiceNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.InvoiceAmountOperator = -1 ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 0 AND T.InvoiceAmount IS NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 1 AND T.InvoiceAmount IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 2 AND T.InvoiceAmount = TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 3 AND T.InvoiceAmount <> TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 7 AND T.InvoiceAmount > TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 8 AND T.InvoiceAmount >= TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 9 AND T.InvoiceAmount < TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 10 AND T.InvoiceAmount <= TMP.InvoiceAmountValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCID END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCID END DESC ,

	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCNumber END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCNumber END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'
	 THEN T.CCIssueDate END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'
	 THEN T.CCIssueDate END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'ASC'
	 THEN T.CCIssueBy END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'DESC'
	 THEN T.CCIssueBy END DESC ,

	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'
	 THEN T.CCApprove END ASC, 
	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'
	 THEN T.CCApprove END DESC ,

	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'
	 THEN T.CCCharge END ASC, 
	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'
	 THEN T.CCCharge END DESC ,

	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'ASC'
	 THEN T.POID END ASC, 
	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'DESC'
	 THEN T.POID END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'
	 THEN T.POAmount END ASC, 
	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'
	 THEN T.POAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Card_Details_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Card_Details_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_Temporary_CC_Card_Details_Get 1
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Card_Details_Get] ( 
   @TempCCID Int = null 
 ) 
 AS 
 BEGIN 
  
SET NOCOUNT ON

SELECT	TCC.ID
		, TCC.CreditCardNumber AS TempCC
		, TCC.TotalChargedAmount AS CCCharge
		, TCC.IssueStatus AS IssueStatus
		, TCCS.Name AS MatchStatus
		, TCC.ExceptionMessage AS ExceptionMessage
		, TCC.OriginalReferencePurchaseOrderNumber AS CCOrigPO
		, TCC.ReferencePurchaseOrderNumber AS CCRefPO
		, TCC.Note
FROM	TemporaryCreditCard TCC
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
WHERE	TCC.ID = @TempCCID


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
 WHERE id = object_id(N'[dbo].[dms_Vendor_CCProcessingDetail_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_CCProcessingDetail_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Vendor_CCProcessingDetail_List_Get @TemporaryCreditCardId=1
 CREATE PROCEDURE [dbo].[dms_Vendor_CCProcessingDetail_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @TemporaryCreditCardId INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
TransactionDateOperator="-1" 
TransactionByOperator="-1" 
TransactionTypeOperator="-1" 
RequestedAmountOperator="-1"
ApprovedAmountOperator="-1" 
ChargeAmountOperator="-1" 
ChargeDescriptionOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
TransactionDateOperator INT NOT NULL,
TransactionDateValue datetime NULL,
TransactionByOperator INT NOT NULL,
TransactionByValue nvarchar(100) NULL,
TransactionTypeOperator INT NOT NULL,
TransactionTypeValue nvarchar(20) NULL,
RequestedAmountOperator INT NOT NULL,
RequestedAmountValue money NULL,
ApprovedAmountOperator INT NOT NULL,
ApprovedAmountValue money NULL,
ChargeAmountOperator INT NOT NULL,
ChargeAmountValue money NULL,
ChargeDescriptionOperator INT NOT NULL,
ChargeDescriptionValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	TransactionDate datetime  NULL ,
	TransactionBy nvarchar(100)  NULL ,
	TransactionType nvarchar(20)  NULL ,
	RequestedAmount money  NULL ,
	ApprovedAmount money  NULL ,
	ChargeAmount money  NULL ,
	ChargeDescription nvarchar(100)  NULL
	
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	TransactionDate datetime  NULL ,
	TransactionBy nvarchar(100)  NULL ,
	TransactionType nvarchar(20)  NULL ,
	RequestedAmount money  NULL ,
	ApprovedAmount money  NULL ,
	ChargeAmount money  NULL ,
	ChargeDescription nvarchar(100)  NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@TransactionDateOperator','INT'),-1),
	T.c.value('@TransactionDateValue','datetime') ,
	ISNULL(T.c.value('@TransactionByOperator','INT'),-1),
	T.c.value('@TransactionByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@TransactionTypeOperator','INT'),-1),
	T.c.value('@TransactionTypeValue','nvarchar(20)') ,
	ISNULL(T.c.value('@RequestedAmountOperator','INT'),-1),
	T.c.value('@RequestedAmountValue','money') ,
	ISNULL(T.c.value('@ApprovedAmountOperator','INT'),-1),
	T.c.value('@ApprovedAmountValue','money') ,
	ISNULL(T.c.value('@ChargeAmountOperator','INT'),-1),
	T.c.value('@ChargeAmountValue','money') ,
	ISNULL(T.c.value('@ChargeDescriptionOperator','INT'),-1),
	T.c.value('@ChargeDescriptionValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT	TCCD.ID
		, CASE
			WHEN TCCD.TransactionType = 'Charge' THEN TCCD.ChargeDate
			ELSE TCCD.TransactionDate
		  END AS [Date]
		, TCCD.TransactionBy AS [User]
		, TCCD.TransactionType AS [Action]
		, TCCD.RequestedAmount AS [Requested]
		, TCCD.ApprovedAmount AS [Approved]
		, TCCD.ChargeAmount AS [Charge]
		, TCCD.ChargeDescription AS [ChargeDescription]
FROM	TemporaryCreditCardDetail TCCD
WHERE	TCCD.TemporaryCreditCardID = @TemporaryCreditCardId



INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.TransactionDate,
	T.TransactionBy,
	T.TransactionType,
	T.RequestedAmount,
	T.ApprovedAmount,
	T.ChargeAmount,
	T.ChargeDescription
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.TransactionDateOperator = -1 ) 
 OR 
	 ( TMP.TransactionDateOperator = 0 AND T.TransactionDate IS NULL ) 
 OR 
	 ( TMP.TransactionDateOperator = 1 AND T.TransactionDate IS NOT NULL ) 
 OR 
	 ( TMP.TransactionDateOperator = 2 AND T.TransactionDate = TMP.TransactionDateValue ) 
 OR 
	 ( TMP.TransactionDateOperator = 3 AND T.TransactionDate <> TMP.TransactionDateValue ) 
 OR 
	 ( TMP.TransactionDateOperator = 7 AND T.TransactionDate > TMP.TransactionDateValue ) 
 OR 
	 ( TMP.TransactionDateOperator = 8 AND T.TransactionDate >= TMP.TransactionDateValue ) 
 OR 
	 ( TMP.TransactionDateOperator = 9 AND T.TransactionDate < TMP.TransactionDateValue ) 
 OR 
	 ( TMP.TransactionDateOperator = 10 AND T.TransactionDate <= TMP.TransactionDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.TransactionByOperator = -1 ) 
 OR 
	 ( TMP.TransactionByOperator = 0 AND T.TransactionBy IS NULL ) 
 OR 
	 ( TMP.TransactionByOperator = 1 AND T.TransactionBy IS NOT NULL ) 
 OR 
	 ( TMP.TransactionByOperator = 2 AND T.TransactionBy = TMP.TransactionByValue ) 
 OR 
	 ( TMP.TransactionByOperator = 3 AND T.TransactionBy <> TMP.TransactionByValue ) 
 OR 
	 ( TMP.TransactionByOperator = 4 AND T.TransactionBy LIKE TMP.TransactionByValue + '%') 
 OR 
	 ( TMP.TransactionByOperator = 5 AND T.TransactionBy LIKE '%' + TMP.TransactionByValue ) 
 OR 
	 ( TMP.TransactionByOperator = 6 AND T.TransactionBy LIKE '%' + TMP.TransactionByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.TransactionTypeOperator = -1 ) 
 OR 
	 ( TMP.TransactionTypeOperator = 0 AND T.TransactionType IS NULL ) 
 OR 
	 ( TMP.TransactionTypeOperator = 1 AND T.TransactionType IS NOT NULL ) 
 OR 
	 ( TMP.TransactionTypeOperator = 2 AND T.TransactionType = TMP.TransactionTypeValue ) 
 OR 
	 ( TMP.TransactionTypeOperator = 3 AND T.TransactionType <> TMP.TransactionTypeValue ) 
 OR 
	 ( TMP.TransactionTypeOperator = 4 AND T.TransactionType LIKE TMP.TransactionTypeValue + '%') 
 OR 
	 ( TMP.TransactionTypeOperator = 5 AND T.TransactionType LIKE '%' + TMP.TransactionTypeValue ) 
 OR 
	 ( TMP.TransactionTypeOperator = 6 AND T.TransactionType LIKE '%' + TMP.TransactionTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ApprovedAmountOperator = -1 ) 
 OR 
	 ( TMP.ApprovedAmountOperator = 0 AND T.ApprovedAmount IS NULL ) 
 OR 
	 ( TMP.ApprovedAmountOperator = 1 AND T.ApprovedAmount IS NOT NULL ) 
 OR 
	 ( TMP.ApprovedAmountOperator = 2 AND T.ApprovedAmount = TMP.ApprovedAmountValue ) 
 OR 
	 ( TMP.ApprovedAmountOperator = 3 AND T.ApprovedAmount <> TMP.ApprovedAmountValue ) 
 OR 
	 ( TMP.ApprovedAmountOperator = 7 AND T.ApprovedAmount > TMP.ApprovedAmountValue ) 
 OR 
	 ( TMP.ApprovedAmountOperator = 8 AND T.ApprovedAmount >= TMP.ApprovedAmountValue ) 
 OR 
	 ( TMP.ApprovedAmountOperator = 9 AND T.ApprovedAmount < TMP.ApprovedAmountValue ) 
 OR 
	 ( TMP.ApprovedAmountOperator = 10 AND T.ApprovedAmount <= TMP.ApprovedAmountValue ) 
 ) 

 AND 

 ( 
	 ( TMP.RequestedAmountOperator = -1 ) 
 OR 
	 ( TMP.RequestedAmountOperator = 0 AND T.RequestedAmount IS NULL ) 
 OR 
	 ( TMP.RequestedAmountOperator = 1 AND T.RequestedAmount IS NOT NULL ) 
 OR 
	 ( TMP.RequestedAmountOperator = 2 AND T.RequestedAmount = TMP.RequestedAmountValue ) 
 OR 
	 ( TMP.RequestedAmountOperator = 3 AND T.RequestedAmount <> TMP.RequestedAmountValue ) 
 OR 
	 ( TMP.RequestedAmountOperator = 7 AND T.RequestedAmount > TMP.RequestedAmountValue ) 
 OR 
	 ( TMP.RequestedAmountOperator = 8 AND T.RequestedAmount >= TMP.RequestedAmountValue ) 
 OR 
	 ( TMP.RequestedAmountOperator = 9 AND T.RequestedAmount < TMP.RequestedAmountValue ) 
 OR 
	 ( TMP.RequestedAmountOperator = 10 AND T.RequestedAmount <= TMP.RequestedAmountValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ChargeAmountOperator = -1 ) 
 OR 
	 ( TMP.ChargeAmountOperator = 0 AND T.ChargeAmount IS NULL ) 
 OR 
	 ( TMP.ChargeAmountOperator = 1 AND T.ChargeAmount IS NOT NULL ) 
 OR 
	 ( TMP.ChargeAmountOperator = 2 AND T.ChargeAmount = TMP.ChargeAmountValue ) 
 OR 
	 ( TMP.ChargeAmountOperator = 3 AND T.ChargeAmount <> TMP.ChargeAmountValue ) 
 OR 
	 ( TMP.ChargeAmountOperator = 7 AND T.ChargeAmount > TMP.ChargeAmountValue ) 
 OR 
	 ( TMP.ChargeAmountOperator = 8 AND T.ChargeAmount >= TMP.ChargeAmountValue ) 
 OR 
	 ( TMP.ChargeAmountOperator = 9 AND T.ChargeAmount < TMP.ChargeAmountValue ) 
 OR 
	 ( TMP.ChargeAmountOperator = 10 AND T.ChargeAmount <= TMP.ChargeAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ChargeDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ChargeDescriptionOperator = 0 AND T.ChargeDescription IS NULL ) 
 OR 
	 ( TMP.ChargeDescriptionOperator = 1 AND T.ChargeDescription IS NOT NULL ) 
 OR 
	 ( TMP.ChargeDescriptionOperator = 2 AND T.ChargeDescription = TMP.ChargeDescriptionValue ) 
 OR 
	 ( TMP.ChargeDescriptionOperator = 3 AND T.ChargeDescription <> TMP.ChargeDescriptionValue ) 
 OR 
	 ( TMP.ChargeDescriptionOperator = 4 AND T.ChargeDescription LIKE TMP.ChargeDescriptionValue + '%') 
 OR 
	 ( TMP.ChargeDescriptionOperator = 5 AND T.ChargeDescription LIKE '%' + TMP.ChargeDescriptionValue ) 
 OR 
	 ( TMP.ChargeDescriptionOperator = 6 AND T.ChargeDescription LIKE '%' + TMP.ChargeDescriptionValue + '%' )
 ) 

 
 AND 
 1 = 1 
 ) 
 
 ORDER BY 
	 CASE WHEN @sortColumn = 'TransactionDate' AND @sortOrder = 'ASC'
	 THEN T.TransactionDate END ASC, 
	 CASE WHEN @sortColumn = 'TransactionDate' AND @sortOrder = 'DESC'
	 THEN T.TransactionDate END DESC ,

	 CASE WHEN @sortColumn = 'TransactionBy' AND @sortOrder = 'ASC'
	 THEN T.TransactionBy END ASC, 
	 CASE WHEN @sortColumn = 'TransactionBy' AND @sortOrder = 'DESC'
	 THEN T.TransactionBy END DESC ,

	 CASE WHEN @sortColumn = 'TransactionType' AND @sortOrder = 'ASC'
	 THEN T.TransactionType END ASC, 
	 CASE WHEN @sortColumn = 'TransactionType' AND @sortOrder = 'DESC'
	 THEN T.TransactionType END DESC ,

	 CASE WHEN @sortColumn = 'RequestedAmount' AND @sortOrder = 'ASC'
	 THEN T.RequestedAmount END ASC, 
	 CASE WHEN @sortColumn = 'RequestedAmount' AND @sortOrder = 'DESC'
	 THEN T.RequestedAmount END DESC ,

	 CASE WHEN @sortColumn = 'ApprovedAmount' AND @sortOrder = 'ASC'
	 THEN T.ApprovedAmount END ASC, 
	 CASE WHEN @sortColumn = 'ApprovedAmount' AND @sortOrder = 'DESC'
	 THEN T.ApprovedAmount END DESC ,

	 CASE WHEN @sortColumn = 'ChargeAmount' AND @sortOrder = 'ASC'
	 THEN T.ChargeAmount END ASC, 
	 CASE WHEN @sortColumn = 'ChargeAmount' AND @sortOrder = 'DESC'
	 THEN T.ChargeAmount END DESC ,

	 CASE WHEN @sortColumn = 'ChargeDescription' AND @sortOrder = 'ASC'
	 THEN T.ChargeDescription END ASC, 
	 CASE WHEN @sortColumn = 'ChargeDescription' AND @sortOrder = 'DESC'
	 THEN T.ChargeDescription END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Vendor_CCProcessing_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_CCProcessing_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_Vendor_CCProcessing_List_Get] @whereClauseXML = '<ROW><Filter IDType="Vendor" IDValue="TX100532" NameValue="" NameOperator="" InvoiceStatuses="" POStatuses="" FromDate="" ToDate="" ExportType="" ToBePaidFromDate="" ToBePaidToDate=""/></ROW>'  
CREATE PROCEDURE [dbo].[dms_Vendor_CCProcessing_List_Get](     
   @whereClauseXML XML = NULL     
 , @startInd Int = 1     
 , @endInd BIGINT = 5000     
 , @pageSize int = 10000      
 , @sortColumn nvarchar(100)  = ''     
 , @sortOrder nvarchar(100) = 'ASC'     
      
 )     
 AS     
 BEGIN     
 
 SET FMTONLY OFF    
  SET NOCOUNT ON    
    
IF @whereClauseXML IS NULL     
BEGIN    
 SET @whereClauseXML = '<ROW><Filter     
NameOperator="-1"    
 ></Filter></ROW>'    
END    
    
    
CREATE TABLE #tmpForWhereClause    
(    
 IDType NVARCHAR(50) NULL,    
 IDValue NVARCHAR(100) NULL,    
 CCMatchStatuses NVARCHAR(MAX) NULL,    
 POPayStatuses NVARCHAR(MAX) NULL,    
 CCFromDate DATETIME NULL,    
 CCToDate DATETIME NULL,    
 POFromDate DATETIME NULL,    
 POToDate DATETIME NULL,
 PostingBatchID INT NULL
     
)    
    
 CREATE TABLE #FinalResults_Filtered(      
 ID int  NULL ,    
 CCRefPO nvarchar(50)  NULL ,    
 TempCC nvarchar(50) NULL,    
 CCIssueDate datetime  NULL ,    
 CCApprove money  NULL ,    
 CCCharge money  NULL ,    
 CCIssueStatus nvarchar(50)  NULL ,    
 CCMatchStatus nvarchar(50)  NULL ,    
 CCOrigPO nvarchar(50)  NULL ,    
 PONumber nvarchar(50)  NULL ,    
 PODate datetime  NULL ,    
 POPayStatus nvarchar(50)  NULL ,    
 POCC nvarchar(50)  NULL ,    
 POAmount money  NULL ,    
 InvoiceAmount money  NULL ,    
 Note nvarchar(1000)  NULL ,    
 ExceptionMessage nvarchar(200)  NULL ,    
 POId int  NULL  ,
 CreditCardIssueNumber nvarchar(50) NULL 
)     
    
 CREATE TABLE #FinalResults_Sorted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL ,    
 CCRefPO nvarchar(50)  NULL ,    
 TempCC nvarchar(50) NULL,    
 CCIssueDate datetime  NULL ,    
 CCApprove money  NULL ,    
 CCCharge money  NULL ,    
 CCIssueStatus nvarchar(50)  NULL ,    
 CCMatchStatus nvarchar(50)  NULL ,    
 CCOrigPO nvarchar(50)  NULL ,    
 PONumber nvarchar(50)  NULL ,    
 PODate datetime  NULL ,    
 POPayStatus nvarchar(50)  NULL ,    
 POCC nvarchar(50)  NULL ,    
 POAmount money  NULL ,    
 InvoiceAmount money  NULL ,    
 Note nvarchar(1000)  NULL ,    
 ExceptionMessage nvarchar(200)  NULL ,    
 POId int  NULL   ,
 CreditCardIssueNumber nvarchar(50) NULL
)     

DECLARE @matchedCount BIGINT      
DECLARE @exceptionCount BIGINT      
DECLARE @postedCount BIGINT    
DECLARE @cancelledCount BIGINT 
DECLARE @unmatchedCount BIGINT 
 
SET @matchedCount = 0      
SET @exceptionCount = 0      
SET @postedCount = 0
SET @cancelledCount = 0
SET @unmatchedCount = 0    
  
  
INSERT INTO #tmpForWhereClause    
SELECT      
 T.c.value('@IDType','NVARCHAR(50)') ,    
 T.c.value('@IDValue','NVARCHAR(100)'),     
 T.c.value('@CCMatchStatuses','nvarchar(MAX)') ,    
 T.c.value('@POPayStatuses','nvarchar(MAX)') , 
 T.c.value('@CCFromDate','datetime') ,    
 T.c.value('@CCToDate','datetime') ,    
 T.c.value('@POFromDate','datetime') ,
T.c.value('@POToDate','datetime') ,    
 T.c.value('@PostingBatchID','INT')     

FROM @whereClauseXML.nodes('/ROW/Filter') T(c)    
    
    
DECLARE @idType NVARCHAR(50) = NULL,    
  @idValue NVARCHAR(100) = NULL,    
  @CCMatchStatuses NVARCHAR(MAX) = NULL,    
  @POPayStatuses NVARCHAR(MAX) = NULL,    
  @CCFromDate DATETIME = NULL,    
  @CCToDate DATETIME = NULL, 
  @POFromDate DATETIME = NULL,    
  @POToDate DATETIME = NULL,
  @PostingBatchID INT = NULL   
      
SELECT @idType = IDType,    
  @idValue = IDValue,    
  @CCMatchStatuses = CCMatchStatuses,    
  @POPayStatuses = POPayStatuses,    
  @CCFromDate = CCFromDate,    
  @CCToDate = CASE WHEN CCToDate = '1900-01-01' THEN NULL ELSE CCToDate END,  
  @POFromDate = POFromDate,
  @POToDate = CASE WHEN POToDate = '1900-01-01' THEN NULL ELSE POToDate END,  
  @PostingBatchID = PostingBatchID 
FROM #tmpForWhereClause    

INSERT INTO #FinalResults_Filtered 
SELECT	TCC.ID,
		TCC.ReferencePurchaseOrderNumber
		, TCC.CreditCardNumber
		, TCC.IssueDate
		, TCC.ApprovedAmount
		, TCC.TotalChargedAmount
		, TCC.IssueStatus
		, TCCS.Name AS CCMatchStatus
		, TCC.OriginalReferencePurchaseOrderNumber
		, PO.PurchaseOrderNumber
		, PO.IssueDate
		, PSC.Name
		, PO.CompanyCreditCardNumber
		, PO.PurchaseOrderAmount
		, CASE
			WHEN TCCS.Name = 'Posted'  THEN ''--TCC.InvoiceAmount
			WHEN TCCS.Name = 'Matched' THEN TCC.TotalChargedAmount
			ELSE ''
		  END AS InvoiceAmount
		, TCC.Note
		,TCC.ExceptionMessage
		,PO.ID
		,TCC.CreditCardIssueNumber 
FROM	TemporaryCreditCard TCC
LEFT JOIN	TemporaryCreditCardStatus TCCS ON TCCS.ID = TCC.TemporaryCreditCardStatusID
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN	PurchaseOrderPayStatusCode PSC ON PSC.ID = PO.PayStatusCodeID
WHERE
 ( ISNULL(@idType,'') = ''    
   OR    
   (@idType = 'CCMatchPO' AND TCC.ReferencePurchaseOrderNumber = @idValue )    
   OR    
   (@idType = 'Last5ofTempCC' AND RIGHT(TCC.CreditCardNumber,5) = @idValue )    
    
  )    
 AND  (    
   ( ISNULL(@CCMatchStatuses,'') = '')    
   OR    
   ( TCC.TemporaryCreditCardStatusID IN (    
           SELECT item FROM fnSplitString(@CCMatchStatuses,',')    
   ))    
  )    
  AND  (    
   ( ISNULL(@POPayStatuses,'') = '')    
   OR    
   ( PO.PayStatusCodeID IN (    
           SELECT item FROM fnSplitString(@POPayStatuses,',')    
   ))    
  )     
  AND  (    
       
   ( @CCFromDate IS NULL OR (@CCFromDate IS NOT NULL AND TCC.IssueDate >= @CCFromDate))    
    AND    
   ( @CCToDate IS NULL OR (@CCToDate IS NOT NULL AND TCC.IssueDate < DATEADD(DD,1,@CCToDate)))    
  )
  AND  (    
       
   ( @POFromDate IS NULL OR (@POFromDate IS NOT NULL AND PO.IssueDate >= @POFromDate))    
    AND    
   ( @POToDate IS NULL OR (@POToDate IS NOT NULL AND PO.IssueDate < DATEADD(DD,1,@POToDate)))    
  )
  AND ( ISNULL(@PostingBatchID,0) = 0 OR TCC.PostingBatchID = @PostingBatchID )
  
INSERT INTO #FinalResults_Sorted    
SELECT     
 T.ID,    
 T.CCRefPO,    
 T.TempCC,    
 T.CCIssueDate,    
 T.CCApprove,    
 T.CCCharge,    
 T.CCIssueStatus,    
 T.CCMatchStatus,    
 T.CCOrigPO,    
 T.PONumber,    
 T.PODate,    
 T.POPayStatus,    
 T.POCC,    
 T.POAmount,    
 T.InvoiceAmount,    
 T.Note,    
 T.ExceptionMessage,    
 T.POId,
 T.CreditCardIssueNumber
FROM #FinalResults_Filtered T    


 ORDER BY     
  CASE WHEN @sortColumn = 'CCRefPO' AND @sortOrder = 'ASC'    
  THEN T.CCRefPO END ASC,     
  CASE WHEN @sortColumn = 'CCRefPO' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC ,    
    
  CASE WHEN @sortColumn = 'TempCC' AND @sortOrder = 'ASC'    
  THEN T.TempCC END ASC,     
  CASE WHEN @sortColumn = 'TempCC' AND @sortOrder = 'DESC'    
  THEN T.TempCC END DESC ,    
     
 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'    
  THEN T.CCIssueDate END ASC,     
  CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'    
  THEN T.CCIssueDate END DESC ,    
    
  CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'    
  THEN T.CCApprove END ASC,     
  CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'    
  THEN T.CCApprove END DESC ,    
    
  CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'    
  THEN T.CCCharge END ASC,     
  CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'    
  THEN T.CCCharge END DESC ,    
    
  CASE WHEN @sortColumn = 'CCIssueStatus' AND @sortOrder = 'ASC'    
  THEN T.CCIssueStatus END ASC,     
  CASE WHEN @sortColumn = 'CCIssueStatus' AND @sortOrder = 'DESC'    
  THEN T.CCIssueStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'CCMatchStatus' AND @sortOrder = 'ASC'    
  THEN T.CCMatchStatus END ASC,     
  CASE WHEN @sortColumn = 'CCMatchStatus' AND @sortOrder = 'DESC'    
  THEN T.CCMatchStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'CCOrigPO' AND @sortOrder = 'ASC'    
  THEN T.CCOrigPO END ASC,     
  CASE WHEN @sortColumn = 'CCOrigPO' AND @sortOrder = 'DESC'    
  THEN T.CCOrigPO END DESC ,    
    
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'    
  THEN T.PONumber END ASC,     
  CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'    
  THEN T.PONumber END DESC ,    
    
  CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'ASC'    
  THEN T.PODate END ASC,     
  CASE WHEN @sortColumn = 'PODate' AND @sortOrder = 'DESC'    
  THEN T.PODate END DESC ,    
    
  CASE WHEN @sortColumn = 'POPayStatus' AND @sortOrder = 'ASC'    
  THEN T.POPayStatus END ASC,     
  CASE WHEN @sortColumn = 'POPayStatus' AND @sortOrder = 'DESC'    
  THEN T.POPayStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'POCC' AND @sortOrder = 'ASC'    
  THEN T.POCC END ASC,     
  CASE WHEN @sortColumn = 'POCC' AND @sortOrder = 'DESC'    
  THEN T.POCC END DESC ,    
    
  CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'    
  THEN T.POAmount END ASC,     
  CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'    
  THEN T.POAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'    
  THEN T.InvoiceAmount END ASC,     
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'    
  THEN T.InvoiceAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'Note' AND @sortOrder = 'ASC'    
  THEN T.Note END ASC,     
  CASE WHEN @sortColumn = 'Note' AND @sortOrder = 'DESC'    
  THEN T.Note END DESC    ,    
    
  CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'    
  THEN T.CreditCardIssueNumber END ASC,     
  CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'    
  THEN T.CreditCardIssueNumber END DESC    
 --CreditCardIssueNumber
    
SELECT @matchedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus = 'Matched'      
SELECT @exceptionCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus = 'Exception'      
SELECT @cancelledCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Cancelled'    
SELECT @postedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Posted' 
SELECT @unmatchedCount = COUNT(*) FROM #FinalResults_Sorted WHERE CCMatchStatus= 'Unmatched'    
   
    
DECLARE @count INT       
SET @count = 0       
SELECT @count = MAX(RowNum) FROM #FinalResults_Sorted    
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
    
SELECT   
   @count AS TotalRows  
 , *  
 , @matchedCount AS MatchedCount   
 , @exceptionCount AS ExceptionCount  
 , @postedCount AS PostedCount  
 , @cancelledCount AS CancellledCount
 , @unmatchedCount AS UnMatchedCount
 
FROM #FinalResults_Sorted WHERE RowNum BETWEEN @startInd AND @endInd    
    
DROP TABLE #tmpForWhereClause    
DROP TABLE #FinalResults_Filtered    
DROP TABLE #FinalResults_Sorted  

    
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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Invoices_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Invoices_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_Vendor_Invoices_List_Get] @whereClauseXML = '<ROW><Filter IDType="Vendor" IDValue="TX100532" NameValue="" NameOperator="" InvoiceStatuses="" POStatuses="" FromDate="" ToDate="" ExportType="" ToBePaidFromDate="" ToBePaidToDate=""/></ROW>'  
CREATE PROCEDURE [dbo].[dms_Vendor_Invoices_List_Get](     
   @whereClauseXML XML = NULL     
 , @startInd Int = 1     
 , @endInd BIGINT = 5000     
 , @pageSize int = 10000      
 , @sortColumn nvarchar(100)  = ''     
 , @sortOrder nvarchar(100) = 'ASC'     
      
 )     
 AS     
 BEGIN     
 
 SET FMTONLY OFF    
  SET NOCOUNT ON    
    
IF @whereClauseXML IS NULL     
BEGIN    
 SET @whereClauseXML = '<ROW><Filter     
NameOperator="-1"    
 ></Filter></ROW>'    
END    
    
    
CREATE TABLE #tmpForWhereClause    
(    
 IDType NVARCHAR(50) NULL,    
 IDValue NVARCHAR(100) NULL,    
 NameOperator INT NULL,    
 NameValue NVARCHAR(100) NULL,    
 InvoiceStatuses NVARCHAR(MAX) NULL,    
 POStatuses NVARCHAR(MAX) NULL,    
 PayStatusCodes NVARCHAR(MAX) NULL, 
 ExceptionTypes NVARCHAR(MAX) NULL, 
 FromDate DATETIME NULL,    
 ToDate DATETIME NULL,    
 ToBePaidFromDate DATETIME NULL,    
 ToBePaidToDate DATETIME NULL,
 ExportType INT NULL ,  
 filterValue nvarchar(100) NULL      
)    
    
 CREATE TABLE #FinalResults_Filtered(      
 ID int  NULL ,    
 VendorNumber nvarchar(100)  NULL ,    
 VendorName nvarchar(100) NULL,    
 PurchaseOrderNumber nvarchar(100)  NULL ,    
 POStatus nvarchar(100)  NULL ,    
 IssueDate datetime  NULL ,    
 PurchaseOrderAmount money  NULL ,    
 InvoiceNumber nvarchar(100)  NULL ,    
 ReceivedDate datetime  NULL ,    
 InvoiceDate datetime  NULL ,    
 InvoiceAmount money  NULL ,    
 InvoiceStatus nvarchar(100)  NULL ,    
 ToBePaidDate datetime  NULL ,    
 ExportDate datetime  NULL ,    
 PaymentDate datetime  NULL ,    
 PaymentAmount money  NULL ,    
 PaymentType nvarchar(100)  NULL ,    
 PaymentNumber nvarchar(100)  NULL ,    
 CheckClearedDate datetime  NULL ,    
 VendorID int NULL  ,  
 VendorInvoiceException nvarchar(max) NULL ,
RecieveMethod  nvarchar(225) NULL
)     
    
 CREATE TABLE #FinalResults_Sorted (     
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
 ID int  NULL ,    
 VendorNumber nvarchar(100)  NULL ,    
 VendorName nvarchar(100) NULL,    
 PurchaseOrderNumber nvarchar(100)  NULL ,    
 POStatus nvarchar(100)  NULL ,    
 IssueDate datetime  NULL ,    
 PurchaseOrderAmount money  NULL ,    
 InvoiceNumber nvarchar(100)  NULL ,    
 ReceivedDate datetime  NULL ,    
 InvoiceDate datetime  NULL ,    
 InvoiceAmount money  NULL ,    
 InvoiceStatus nvarchar(100)  NULL ,    
 ToBePaidDate datetime  NULL ,    
 ExportDate datetime  NULL ,    
 PaymentDate datetime  NULL ,    
 PaymentAmount money  NULL ,    
 PaymentType nvarchar(100)  NULL ,    
 PaymentNumber nvarchar(100)  NULL ,    
 CheckClearedDate datetime  NULL ,    
 VendorID int NULL ,  
 VendorInvoiceException nvarchar(max) NULL  ,
RecieveMethod  nvarchar(225) NULL
)     

DECLARE @receivedCount BIGINT      
DECLARE @readyForPaymentCount BIGINT      
DECLARE @exceptionCount BIGINT    
DECLARE @paidCount BIGINT    
DECLARE @cancelledCount BIGINT      
SET @receivedCount = 0      
SET @readyForPaymentCount = 0      
SET @exceptionCount = 0    
SET @paidCount = 0    
SET @cancelledCount = 0    
  
INSERT INTO #tmpForWhereClause    
SELECT      
 T.c.value('@IDType','NVARCHAR(50)') ,    
 T.c.value('@IDValue','NVARCHAR(100)'),     
 ISNULL(T.c.value('@NameOperator','INT'),-1),    
 T.c.value('@NameValue','nvarchar(100)') ,    
 T.c.value('@InvoiceStatuses','nvarchar(MAX)') ,    
 T.c.value('@POStatuses','nvarchar(MAX)') ,    
 T.c.value('@PayStatusCodes','nvarchar(MAX)') ,  
 T.c.value('@ExceptionTypes','nvarchar(MAX)') , 
 T.c.value('@FromDate','datetime') ,    
 T.c.value('@ToDate','datetime') ,
 T.c.value('@ToBePaidFromDate','datetime') ,    
 T.c.value('@ToBePaidToDate','datetime') ,    
 T.c.value('@ExportType','INT') ,  
 T.c.value('@filterValue','NVARCHAR(100)') 

FROM @whereClauseXML.nodes('/ROW/Filter') T(c)    
    
    
DECLARE @idType NVARCHAR(50) = NULL,    
  @idValue NVARCHAR(100) = NULL,    
  @nameOperator INT = NULL,    
  @nameValue NVARCHAR(100) = NULL,    
  @invoiceStatuses NVARCHAR(MAX) = NULL,    
  @payStatusCodes NVARCHAR(MAX) = NULL,
  @exceptionTypes NVARCHAR(MAX) = NULL,
  @poStatuses NVARCHAR(MAX) = NULL,    
  @fromDate DATETIME = NULL,    
  @toDate DATETIME = NULL, 
  @toBePaidFromDate DATETIME = NULL,    
  @toBePaidToDate DATETIME = NULL,
  @exportType INT = NULL  ,  
  @filterValue NVARCHAR(100) = NULL  
      
SELECT @idType = IDType,    
  @idValue = IDValue,    
  @nameOperator = NameOperator,    
  @nameValue = NameValue,    
  @invoiceStatuses = InvoiceStatuses,    
  @poStatuses = POStatuses,    
  @payStatusCodes = PayStatusCodes,
  @exceptionTypes = ExceptionTypes,
  @fromDate = FromDate,    
  @toDate = CASE WHEN ToDate = '1900-01-01' THEN NULL ELSE ToDate END,  
  @toBePaidFromDate = ToBePaidFromDate,
  @toBePaidToDate = CASE WHEN ToBePaidToDate = '1900-01-01' THEN NULL ELSE ToBePaidToDate END,  
  @exportType = ExportType ,   
  @filterValue=filterValue  
FROM #tmpForWhereClause    

INSERT INTO #FinalResults_Filtered    
SELECT VI.ID    
  , V.VendorNumber    
  , V.Name AS VendorName    
  , PO.PurchaseOrderNumber    
  , POS.Name AS POStatus    
  , PO.IssueDate    
  , PO.PurchaseOrderAmount    
  , VI.InvoiceNumber    
  , VI.ReceivedDate    
  , VI.InvoiceDate    
  , VI.InvoiceAmount    
  , VIS.Name AS InvoiceStatus    
  , VI.ToBePaidDate    
  , VI.ExportDate    
  , VI.PaymentDate    
  , VI.PaymentAmount    
  --, PT.Name AS PaymentType    
  , CASE    
   WHEN VIS.Name = 'Paid' THEN PT.NAME    
   WHEN ISNULL(VIS.Name,'') <> 'Paid' AND ISNULL(ACH.ID,'') <> '' AND ISNULL(V.IsLevyActive,'') <> 1 THEN 'ACH'    
   ELSE 'Check'    
    END AS PaymentType    
  , VI.PaymentNumber     
  , VI.CheckClearedDate    
  , V.ID AS VendorID    
  , NULL AS VendorInvoiceException
  --, VIE.[Description] AS VendorInvoiceException
  , CM.Name  
FROM VendorInvoice VI    
JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID    
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID    
JOIN Vendor V ON V.ID = VI.VendorID    
JOIN PurchaseOrder PO ON PO.ID = VI.PurchaseOrderID    
JOIN PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID    
LEFT JOIN VendorACH ACH ON ACH.VendorID = V.ID AND ACH.ACHStatusID = (SELECT ID FROM ACHStatus WHERE Name = 'Valid') AND ISNULL(ACH.IsActive,0) = 1
LEFT JOIN VendorInvoiceException VIE ON VIE.VendorInvoiceID = VI.ID  
LEFT JOIN Batch B ON VI.ExportBatchID = B.ID
LEFT JOIN ContactMethod CM ON CM.ID=VI.ReceiveContactMethodID
WHERE VI.IsActive = 1    
AND  ( ISNULL(@idType,'') = ''    
   OR    
   (@idType = 'Vendor' AND V.VendorNumber = @idValue )    
   OR    
   (@idType = 'PO' AND PO.PurchaseOrderNumber = @idValue )    
   OR    
   (@idType = 'Invoice' AND VI.InvoiceNumber = @idValue )    
  )    
AND  (    
   ( @nameOperator = -1 )     
    OR     
   ( @nameOperator = 0 AND ISNULL(@nameValue,'') = '' )     
    OR     
   ( @nameOperator = 1 AND @nameValue IS NOT NULL )     
    OR     
   ( @nameOperator = 2 AND V.Name = @nameValue )     
    OR     
   ( @nameOperator = 3 AND V.Name <> @nameValue )     
    OR     
   ( @nameOperator = 4 AND V.Name LIKE @nameValue + '%')     
    OR     
   ( @nameOperator = 5 AND V.Name LIKE '%' + @nameValue )     
    OR     
   ( @nameOperator = 6 AND V.Name LIKE '%' + @nameValue + '%')     
  )  
AND  (    
   ( ISNULL(@invoiceStatuses,'') = '')    
   OR    
   ( VI.VendorInvoiceStatusID IN (    
           SELECT item FROM fnSplitString(@invoiceStatuses,',')    
           ))    
  )    
AND  (    
   ( ISNULL(@poStatuses,'') = '')    
   OR    
   ( PO.PurchaseOrderStatusID IN (    
           SELECT item FROM fnSplitString(@poStatuses,',')    
           ))    
  )    
  AND  (    
   ( ISNULL(@payStatusCodes,'') = '')    
   OR    
   ( PO.PayStatusCodeID IN (    
           SELECT item FROM fnSplitString(@payStatusCodes,',')    
           ))    
  ) 
   AND  (    
   ( ISNULL(@exceptionTypes,'') = '')    
   OR    
   ( VIE.[Description] IN (    
           SELECT item FROM fnSplitString(@exceptionTypes,',')    
           ))    
  ) 
AND  (    
       
   ( @fromDate IS NULL OR (@fromDate IS NOT NULL AND VI.InvoiceDate >= @fromDate))    
    AND    
   ( @toDate IS NULL OR (@toDate IS NOT NULL AND VI.InvoiceDate < DATEADD(DD,1,@toDate)))    
  )
  AND  (    
       
   ( @toBePaidFromDate IS NULL OR (@toBePaidFromDate IS NOT NULL AND VI.ToBePaidDate >= @toBePaidFromDate))    
    AND    
   ( @toBePaidToDate IS NULL OR (@toBePaidToDate IS NOT NULL AND VI.ToBePaidDate < DATEADD(DD,1,@toBePaidToDate)))    
  )    
AND  (    
   ( @filterValue IS NULL OR @filterValue = '')    
   OR    
   ( VIS.Name IN (    
           SELECT item FROM fnSplitString(@filterValue,',')    
           ))    
  )   
 AND ( ISNULL(@exportType,0) = 0 OR B.ID = @exportType )
    
--------------------- BEGIN -----------------------------    
----   Create a temp variable or a CTE with the actual SQL search query ----------    
----   and use that CTE in the place of <table> in the following SQL statements ---    
--------------------- END -----------------------------    

;WITH wExceptions
AS
(
      SELECT      V.VendorInvoiceID,
                  [dbo].[fnConcatenate](V.Description) AS ExceptionMessages
      FROM  VendorInvoiceException V
      JOIN  #FinalResults_Filtered F ON V.VendorInvoiceID = F.ID
      GROUP BY V.VendorInvoiceID
                  
)
--SELECT * FROM wExceptions

INSERT INTO #FinalResults_Sorted    
SELECT     
 T.ID,    
 T.VendorNumber,    
 T.VendorName,    
 T.PurchaseOrderNumber,    
 T.POStatus,    
 T.IssueDate,    
 T.PurchaseOrderAmount,    
 T.InvoiceNumber,    
 T.ReceivedDate,    
 T.InvoiceDate,    
 T.InvoiceAmount,    
 T.InvoiceStatus,    
 T.ToBePaidDate,    
 T.ExportDate,    
 T.PaymentDate,    
 T.PaymentAmount,    
 T.PaymentType,    
 T.PaymentNumber,    
 T.CheckClearedDate,    
 T.VendorID ,  
 W.ExceptionMessages AS VendorInvoiceException,
T.RecieveMethod
FROM #FinalResults_Filtered T    
LEFT OUTER JOIN wExceptions W ON T.ID = W.VendorInvoiceID

 ORDER BY     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC ,    
    
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'    
  THEN T.VendorNumber END ASC,     
  CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'    
  THEN T.VendorNumber END DESC ,    
     
 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'    
  THEN T.VendorName END ASC,     
  CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'    
  THEN T.VendorName END DESC ,    
    
  CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderNumber END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'ASC'    
  THEN T.POStatus END ASC,     
  CASE WHEN @sortColumn = 'POStatus' AND @sortOrder = 'DESC'    
  THEN T.POStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'    
  THEN T.IssueDate END ASC,     
  CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'    
  THEN T.IssueDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'ASC'    
  THEN T.PurchaseOrderAmount END ASC,     
  CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'DESC'    
  THEN T.PurchaseOrderAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'    
  THEN T.InvoiceNumber END ASC,     
  CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'    
  THEN T.InvoiceNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'ASC'    
  THEN T.ReceivedDate END ASC,     
  CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'DESC'    
  THEN T.ReceivedDate END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'    
  THEN T.InvoiceDate END ASC,     
  CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'    
  THEN T.InvoiceDate END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'    
  THEN T.InvoiceAmount END ASC,     
  CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'    
  THEN T.InvoiceAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'    
  THEN T.InvoiceStatus END ASC,     
  CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'    
  THEN T.InvoiceStatus END DESC ,    
    
  CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'ASC'    
  THEN T.ToBePaidDate END ASC,     
  CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'DESC'    
  THEN T.ToBePaidDate END DESC ,    
    
  CASE WHEN @sortColumn = 'ExportDate' AND @sortOrder = 'ASC'    
  THEN T.ExportDate END ASC,     
  CASE WHEN @sortColumn = 'ExportDate' AND @sortOrder = 'DESC'    
  THEN T.ExportDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'    
  THEN T.PaymentDate END ASC,     
  CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'    
  THEN T.PaymentDate END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'    
  THEN T.PaymentAmount END ASC,     
  CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'    
  THEN T.PaymentAmount END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'    
  THEN T.PaymentType END ASC,     
  CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'    
  THEN T.PaymentType END DESC ,    
    
  CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'    
  THEN T.PaymentNumber END ASC,     
  CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'    
  THEN T.PaymentNumber END DESC ,    
    
  CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'    
  THEN T.CheckClearedDate END ASC,     
  CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'    
  THEN T.CheckClearedDate END DESC ,    
      
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC     ,    
      
  CASE WHEN @sortColumn = 'RecieveMethod' AND @sortOrder = 'ASC'    
  THEN T.RecieveMethod END ASC,     
  CASE WHEN @sortColumn = 'RecieveMethod' AND @sortOrder = 'DESC'    
  THEN T.RecieveMethod END DESC     
 
    
SELECT @receivedCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus = 'Received'      
SELECT @readyForPaymentCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus = 'ReadyForPayment'      
SELECT @exceptionCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Exception'    
SELECT @paidCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Paid'    
SELECT @cancelledCount = COUNT(*) FROM #FinalResults_Sorted WHERE InvoiceStatus= 'Cancelled'    
    
DECLARE @count INT       
SET @count = 0       
SELECT @count = MAX(RowNum) FROM #FinalResults_Sorted    
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
    
SELECT   
   @count AS TotalRows  
 , *  
 , @receivedCount AS RecivedCount   
 , @readyForPaymentCount AS ReadyForPaymentCount  
 , @exceptionCount AS ExceptionCount  
 , @paidCount AS PaidCount  
 , @cancelledCount AS CancelledCount  
FROM #FinalResults_Sorted WHERE RowNum BETWEEN @startInd AND @endInd    
    
DROP TABLE #tmpForWhereClause    
DROP TABLE #FinalResults_Filtered    
DROP TABLE #FinalResults_Sorted  

    
END

GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Details_Get @VendorInvoiceID=14329
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Details_Get( 
	@VendorInvoiceID INT =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
    SELECT VI.ID
	, VI.VendorInvoiceStatusID
	, VIS.Name AS VendorInvoiceStatus
	, PO.PurchaseOrderNumber
	, V.VendorNumber
	, VI.InvoiceNumber
	, VI.InvoiceAmount
	, VI.InvoiceDate
	, VI.ReceivedDate
	, VI.ReceiveContactMethodID
	, VI.ActualETAMinutes
	, VI.Last8OfVIN
	, VI.VehicleMileage
	, VI.ToBePaidDate
	, VI.ExportDate
	, VI.ExportBatchID
	, VI.BillingBusinessName
	, VI.BillingContactName
	, VI.BillingAddressLine1
	, VI.BillingAddressLine2
	, VI.BillingAddressLine3
	, VI.BillingAddressCity
	, VI.BillingAddressStateProvince
	, VI.BillingAddressPostalCode
	, VI.BillingAddressCountryCode
	, PT.Name AS PaymentType
	, VI.PaymentDate AS PaymentDate
	, VI.PaymentAmount
	, VI.PaymentNumber
	, VI.CheckClearedDate AS CheckClearedDate
	, SS.Name AS SourceSystem
	, VI.CreateBy
	, VI.CreateDate
	, VI.ModifyBy
	, VI.ModifyDate
	, VI.VendorInvoicePaymentDifferenceReasonCodeID
	, V.ID AS VendorID
FROM VendorInvoice VI
JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID
JOIN Vendor V ON V.ID = VI.VendorID
JOIN PurchaseOrder PO ON PO.ID = VI.PurchaseOrderID
JOIN PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
LEFT JOIN SourceSystem SS ON SS.ID = VI.SourceSystemID
WHERE VI.ID = @VendorInvoiceID
END
GO

GO
-- Get Vendor Billing with logic added to check for Alternate
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get @VendorLocationID=356, @POID=619
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get( 
	@VendorLocationID INT =NULL
	, @POID INT = NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
SELECT V.ID
	, CASE
		WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'
		ELSE 'Contracted'
		END AS 'ContractStatus'
	, V.Name
	, V.VendorNumber
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine1
		ELSE AE.Line1
		END AS Line1
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine2
		ELSE AE.Line2
	END AS Line2
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine3
		ELSE AE.Line3
	END AS Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		WHEN ISNULL(VI.ID,'') <> '' THEN
		ISNULL(REPLACE(RTRIM(
			COALESCE(VI.BillingAddressCity, '') +
			COALESCE(', ' + VI.BillingAddressStateProvince, '') +
			COALESCE(' ' + VI.BillingAddressPostalCode, '') +
			COALESCE(' ' + VI.BillingAddressCountryCode, '')
		), ' ', ' ')
	,'')
	ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, ISNULL(REPLACE(RTRIM(
		COALESCE(V.TaxSSN,'')+
		COALESCE(V.TaxEIN,'')
		), ' ', ' ')
	,'') AS TaxID
	, PE.PhoneNumber
	, V.Email
	, (V.ContactFirstName + ' ' + V.ContactLastName) AS ContactName
	, VI.ID AS VendorInvoiceID
FROM Vendor V
JOIN VendorLocation VL ON VL.VendorID = V.ID
LEFT JOIN Contract C ON C.VendorID = V.ID
AND C.IsActive = 1
LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
AND C.IsActive = 1
LEFT JOIN AddressEntity AE ON AE.RecordID = V.ID
AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
AND AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN PhoneEntity PE ON PE.RecordID = V.ID
AND PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN VendorInvoice VI ON VI.PurchaseOrderID = @POID
WHERE VL.ID = @VendorLocationID
END
GO
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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Summary_LocationRates]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Summary_LocationRates] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Vendor_Summary_LocationRates]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT = NULL
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
LocationAddressOperator="-1" 
StatusOperator="-1" 
DispatchNumberOperator="-1" 
FaxNumberOperator="-1" 
CellNumberOperator="-1" 
IsDispatchNoteOperator="-1" 
DispatchNoteOperator="-1" 
LatitudeOperator="-1" 
LongitudeOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
LocationAddressOperator INT NOT NULL,
LocationAddressValue nvarchar(100) NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
DispatchNumberOperator INT NOT NULL,
DispatchNumberValue nvarchar(100) NULL,
FaxNumberOperator INT NOT NULL,
FaxNumberValue nvarchar(100) NULL,
CellNumberOperator INT NOT NULL,
CellNumberValue nvarchar(100) NULL,
IsDispatchNoteOperator INT NOT NULL,
IsDispatchNoteValue nvarchar(100) NULL,
DispatchNoteOperator INT NOT NULL,
DispatchNoteValue nvarchar(100) NULL,
LatitudeOperator INT NOT NULL,
LatitudeValue decimal NULL,
LongitudeOperator INT NOT NULL,
LongitudeValue decimal NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorID int  NULL ,
	VendorLocationID int  NULL ,
	LocationAddress nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	FaxNumber nvarchar(100)  NULL ,
	CellNumber nvarchar(100)  NULL ,
	IsDispatchNote nvarchar(100)  NULL ,
	DispatchNote nvarchar(100)  NULL ,
	Latitude decimal(10,7)  NULL ,
	Longitude decimal(10,7)  NULL 
) 

DECLARE @Query AS TABLE( 
	VendorID int  NULL ,
	VendorLocationID int  NULL ,
	LocationAddress nvarchar(100)  NULL ,
	Status nvarchar(100)  NULL ,
	DispatchNumber nvarchar(100)  NULL ,
	FaxNumber nvarchar(100)  NULL ,
	CellNumber nvarchar(100)  NULL ,
	IsDispatchNote nvarchar(100)  NULL ,
	DispatchNote nvarchar(100)  NULL ,
	Latitude decimal(10,7)  NULL ,
	Longitude decimal(10,7)  NULL 
) 
INSERT INTO @Query
SELECT	VL.VendorID,
		VL.ID VendorLocationID,
		ISNULL(REPLACE(RTRIM(
		COALESCE(AE.Line1, '') + 
		COALESCE(' ' + AE.Line2, '') + 
		COALESCE(' ' + AE.Line3, '') + 
		COALESCE(', ' + AE.City, '') +
		COALESCE(RTRIM(', ' + AE.StateProvince), '') + 
		COALESCE(' ' + AE.PostalCode, '') +	
		COALESCE(' ' + AE.CountryCode, '') 
		), '  ', ' ')
		,'') AS LocationAddress
		, VLS.Description AS Status
		, PE.PhoneNumber AS DispatchNumber
		, PEF.PhoneNumber AS FaxNumber
		, PEC.PhoneNumber AS CellNumber
		, CASE
			WHEN ISNULL(VL.DispatchNote,'')='' THEN 'No'
			ELSE 'Yes'
		  END AS IsDispatchNote
		, VL.DispatchNote
		, VL.Latitude AS Latitude
		, VL.Longitude AS Longitude
FROM	VendorLocation VL
JOIN	VendorLocationStatus VLS ON VLS.ID = VL.VendorLocationStatusID
LEFT JOIN AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
LEFT JOIN PhoneEntity PE ON PE.RecordID = VL.ID AND PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch') 
LEFT JOIN PhoneEntity PEF ON PEF.RecordID = VL.ID AND PEF.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PEF.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax') 
LEFT JOIN PhoneEntity PEC ON PEC.RecordID = VL.ID AND PEC.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') 
		AND PEC.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Cell') 
WHERE	VL.VendorID = @VendorID

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@LocationAddressOperator','INT'),-1),
	T.c.value('@LocationAddressValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DispatchNumberOperator','INT'),-1),
	T.c.value('@DispatchNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@FaxNumberOperator','INT'),-1),
	T.c.value('@FaxNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CellNumberOperator','INT'),-1),
	T.c.value('@CellNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsDispatchNoteOperator','INT'),-1),
	T.c.value('@IsDispatchNoteValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DispatchNoteOperator','INT'),-1),
	T.c.value('@DispatchNoteValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LatitudeOperator','INT'),-1),
	T.c.value('@LatitudeValue','decimal') ,
	ISNULL(T.c.value('@LongitudeOperator','INT'),-1),
	T.c.value('@LongitudeValue','decimal') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.VendorID,
	T.VendorLocationID,
	T.LocationAddress,
	T.Status,
	T.DispatchNumber,
	T.FaxNumber,
	T.CellNumber,
	T.IsDispatchNote,
	T.DispatchNote,
	T.Latitude,
	T.Longitude
FROM @Query T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.LocationAddressOperator = -1 ) 
 OR 
	 ( TMP.LocationAddressOperator = 0 AND T.LocationAddress IS NULL ) 
 OR 
	 ( TMP.LocationAddressOperator = 1 AND T.LocationAddress IS NOT NULL ) 
 OR 
	 ( TMP.LocationAddressOperator = 2 AND T.LocationAddress = TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 3 AND T.LocationAddress <> TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 4 AND T.LocationAddress LIKE TMP.LocationAddressValue + '%') 
 OR 
	 ( TMP.LocationAddressOperator = 5 AND T.LocationAddress LIKE '%' + TMP.LocationAddressValue ) 
 OR 
	 ( TMP.LocationAddressOperator = 6 AND T.LocationAddress LIKE '%' + TMP.LocationAddressValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StatusOperator = -1 ) 
 OR 
	 ( TMP.StatusOperator = 0 AND T.Status IS NULL ) 
 OR 
	 ( TMP.StatusOperator = 1 AND T.Status IS NOT NULL ) 
 OR 
	 ( TMP.StatusOperator = 2 AND T.Status = TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 3 AND T.Status <> TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 4 AND T.Status LIKE TMP.StatusValue + '%') 
 OR 
	 ( TMP.StatusOperator = 5 AND T.Status LIKE '%' + TMP.StatusValue ) 
 OR 
	 ( TMP.StatusOperator = 6 AND T.Status LIKE '%' + TMP.StatusValue + '%' ) 
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
	 ( TMP.FaxNumberOperator = -1 ) 
 OR 
	 ( TMP.FaxNumberOperator = 0 AND T.FaxNumber IS NULL ) 
 OR 
	 ( TMP.FaxNumberOperator = 1 AND T.FaxNumber IS NOT NULL ) 
 OR 
	 ( TMP.FaxNumberOperator = 2 AND T.FaxNumber = TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 3 AND T.FaxNumber <> TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 4 AND T.FaxNumber LIKE TMP.FaxNumberValue + '%') 
 OR 
	 ( TMP.FaxNumberOperator = 5 AND T.FaxNumber LIKE '%' + TMP.FaxNumberValue ) 
 OR 
	 ( TMP.FaxNumberOperator = 6 AND T.FaxNumber LIKE '%' + TMP.FaxNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CellNumberOperator = -1 ) 
 OR 
	 ( TMP.CellNumberOperator = 0 AND T.CellNumber IS NULL ) 
 OR 
	 ( TMP.CellNumberOperator = 1 AND T.CellNumber IS NOT NULL ) 
 OR 
	 ( TMP.CellNumberOperator = 2 AND T.CellNumber = TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 3 AND T.CellNumber <> TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 4 AND T.CellNumber LIKE TMP.CellNumberValue + '%') 
 OR 
	 ( TMP.CellNumberOperator = 5 AND T.CellNumber LIKE '%' + TMP.CellNumberValue ) 
 OR 
	 ( TMP.CellNumberOperator = 6 AND T.CellNumber LIKE '%' + TMP.CellNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsDispatchNoteOperator = -1 ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 0 AND T.IsDispatchNote IS NULL ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 1 AND T.IsDispatchNote IS NOT NULL ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 2 AND T.IsDispatchNote = TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 3 AND T.IsDispatchNote <> TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 4 AND T.IsDispatchNote LIKE TMP.IsDispatchNoteValue + '%') 
 OR 
	 ( TMP.IsDispatchNoteOperator = 5 AND T.IsDispatchNote LIKE '%' + TMP.IsDispatchNoteValue ) 
 OR 
	 ( TMP.IsDispatchNoteOperator = 6 AND T.IsDispatchNote LIKE '%' + TMP.IsDispatchNoteValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DispatchNoteOperator = -1 ) 
 OR 
	 ( TMP.DispatchNoteOperator = 0 AND T.DispatchNote IS NULL ) 
 OR 
	 ( TMP.DispatchNoteOperator = 1 AND T.DispatchNote IS NOT NULL ) 
 OR 
	 ( TMP.DispatchNoteOperator = 2 AND T.DispatchNote = TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 3 AND T.DispatchNote <> TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 4 AND T.DispatchNote LIKE TMP.DispatchNoteValue + '%') 
 OR 
	 ( TMP.DispatchNoteOperator = 5 AND T.DispatchNote LIKE '%' + TMP.DispatchNoteValue ) 
 OR 
	 ( TMP.DispatchNoteOperator = 6 AND T.DispatchNote LIKE '%' + TMP.DispatchNoteValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LatitudeOperator = -1 ) 
 OR 
	 ( TMP.LatitudeOperator = 0 AND T.Latitude IS NULL ) 
 OR 
	 ( TMP.LatitudeOperator = 1 AND T.Latitude IS NOT NULL ) 
 OR 
	 ( TMP.LatitudeOperator = 2 AND T.Latitude = TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 3 AND T.Latitude <> TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 7 AND T.Latitude > TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 8 AND T.Latitude >= TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 9 AND T.Latitude < TMP.LatitudeValue ) 
 OR 
	 ( TMP.LatitudeOperator = 10 AND T.Latitude <= TMP.LatitudeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LongitudeOperator = -1 ) 
 OR 
	 ( TMP.LongitudeOperator = 0 AND T.Longitude IS NULL ) 
 OR 
	 ( TMP.LongitudeOperator = 1 AND T.Longitude IS NOT NULL ) 
 OR 
	 ( TMP.LongitudeOperator = 2 AND T.Longitude = TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 3 AND T.Longitude <> TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 7 AND T.Longitude > TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 8 AND T.Longitude >= TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 9 AND T.Longitude < TMP.LongitudeValue ) 
 OR 
	 ( TMP.LongitudeOperator = 10 AND T.Longitude <= TMP.LongitudeValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'LocationAddress' AND @sortOrder = 'ASC'
	 THEN T.LocationAddress END ASC, 
	 CASE WHEN @sortColumn = 'LocationAddress' AND @sortOrder = 'DESC'
	 THEN T.LocationAddress END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'ASC'
	 THEN T.DispatchNumber END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNumber' AND @sortOrder = 'DESC'
	 THEN T.DispatchNumber END DESC ,

	 CASE WHEN @sortColumn = 'FaxNumber' AND @sortOrder = 'ASC'
	 THEN T.FaxNumber END ASC, 
	 CASE WHEN @sortColumn = 'FaxNumber' AND @sortOrder = 'DESC'
	 THEN T.FaxNumber END DESC ,

	 CASE WHEN @sortColumn = 'CellNumber' AND @sortOrder = 'ASC'
	 THEN T.CellNumber END ASC, 
	 CASE WHEN @sortColumn = 'CellNumber' AND @sortOrder = 'DESC'
	 THEN T.CellNumber END DESC ,

	 CASE WHEN @sortColumn = 'IsDispatchNote' AND @sortOrder = 'ASC'
	 THEN T.IsDispatchNote END ASC, 
	 CASE WHEN @sortColumn = 'IsDispatchNote' AND @sortOrder = 'DESC'
	 THEN T.IsDispatchNote END DESC ,

	 CASE WHEN @sortColumn = 'DispatchNote' AND @sortOrder = 'ASC'
	 THEN T.DispatchNote END ASC, 
	 CASE WHEN @sortColumn = 'DispatchNote' AND @sortOrder = 'DESC'
	 THEN T.DispatchNote END DESC ,

	 CASE WHEN @sortColumn = 'LatitudeText' AND @sortOrder = 'ASC'
	 THEN T.Latitude END ASC, 
	 CASE WHEN @sortColumn = 'LatitudeText' AND @sortOrder = 'DESC'
	 THEN T.Latitude END DESC ,

	 CASE WHEN @sortColumn = 'LongitudeText' AND @sortOrder = 'ASC'
	 THEN T.Longitude END ASC, 
	 CASE WHEN @sortColumn = 'LongitudeText' AND @sortOrder = 'DESC'
	 THEN T.Longitude END DESC 


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

SELECT @count AS TotalRows,
	   FR.[RowNum],
	   FR.VendorID,
	   FR.VendorLocationID,
	   FR.LocationAddress,
	   FR.[Status],
	   FR.DispatchNumber,
	   FR.FaxNumber,
	   FR.CellNumber,
	   FR.IsDispatchNote,
 	   FR.DispatchNote,
	   FR.Latitude,
	   FR.Longitude,
	   CONVERT(NVARCHAR(MAX),FR.Latitude) LatitudeText,
	   CONVERT(NVARCHAR(MAX),FR.Longitude) LongitudeText
FROM #FinalResults FR 
WHERE FR.RowNum BETWEEN @startInd AND @endInd

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_batch_details_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_batch_details_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_batch_details_update] @invoicesXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@batchID = 999, @currentUser='kbanda'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_batch_details_update](
	@invoicesXML XML,
	@batchID BIGINT,
	@currentUser NVARCHAR(50),
	@eventSource NVARCHAR(MAX),
	@eventName NVARCHAR(100) = 'PostTempCC',
	@eventDetails NVARCHAR(MAX),
	@entityName NVARCHAR(50) = 'VendorInvoice',
	@sessionID NVARCHAR(MAX) = NULL
 )
 AS
 BEGIN
 
	DECLARE @now DATETIME = GETDATE()
	
	DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	TemporaryCreditCard VI
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @invoicesXML.nodes('/Tempcc/ID') T(c)
			) T ON VI.ID = T.ID
	
	DECLARE @tempccEventID INT, 
			@vendorInvoiceEntityID INT,
			@totalAmount money,
			@batchStatusId INT
			
	SELECT @tempccEventID = ID FROM Event WHERE Name = @eventName
	SELECT @vendorInvoiceEntityID = ID FROM Entity WHERE Name = @entityName
	
	
	
	-- Event Logs.
	DECLARE @maxRows INT, @index INT = 1
	SELECT @maxRows = COUNT(*) FROM @invoicesFromDB
	
	WHILE ( @index <= @maxRows)
	BEGIN
		
		INSERT INTO EventLog
		SELECT	@tempccEventID,
				@sessionID,
				@eventSource,
				@eventDetails,
				NULL,
				NULL,
				GETDATE(),
				@currentUser
				
		INSERT INTO EventLogLink
		SELECT	SCOPE_IDENTITY(),
				@vendorInvoiceEntityID,
				(SELECT InvoiceID FROM @invoicesFromDB WHERE ID = @index)			
	
		SET @index = @index + 1
	END
    
    SELECT @batchStatusId = ID FROM BatchStatus WHERE Name = 'Success'
    
    SELECT	@totalAmount = SUM(ISNULL(C.TotalChargedAmount,0))
		FROM	TemporaryCreditCard C
		JOIN	@invoicesFromDB I ON C.ID = I.InvoiceID
		
    UPDATE	Batch
	SET	BatchStatusID = @batchStatusID,				
	ModifyBy = @currentUser,
	ModifyDate = @now,
	TotalCount = (SELECT Count(*) FROM @invoicesFromDB),
	TotalAmount = @totalAmount
	WHERE	ID = @batchID
	
    
    
	
	SELECT @totalAmount AS TotalAmount
	
 END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_tempcc_match_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_tempcc_match_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vendor_tempcc_match_update] @tempccIdXML = '<Tempcc><ID>1</ID><ID>2</ID><ID>3</ID><ID>4</ID></Tempcc>',@currentUser = 'demouser'
 CREATE PROCEDURE [dbo].[dms_vendor_tempcc_match_update](
	@tempccIdXML XML,
	@currentUser NVARCHAR(50)
 )
 AS
 BEGIN
 
    SET FMTONLY OFF
	SET NOCOUNT ON
	
	DECLARE @now DATETIME = GETDATE()
	
	
	
	DECLARE @Matched INT =0,
		@MatchedAmount money =0,
		@Posted INT=0,
		@PostedAmount money=0,
		@Cancelled INT=0,
		@CancelledAmount money=0,
		@Exception INT=0,
		@ExceptionAmount money=0,
		@MatchedIds nvarchar(max)=''
		
	DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	TemporaryCreditCard  VI WITH (NOLOCK)
	JOIN	(
				SELECT  T.c.value('.','INT') AS ID
				FROM @tempccIdXML.nodes('/Tempcc/ID') T(c)
			) T ON VI.ID = T.ID
	
	DECLARE @maxRows INT, @index INT = 1,@tempCCId INT = 0,
			@exceptionMessage NVARCHAR(500) = '',@tempccNumber NVARCHAR(50)=NULL,@totalChargedAmount money=0,
			@referencePONumber NVARCHAR(50)='',@ccMatchCount INT =0,@poMatchCount INT = 0
			
	SELECT @maxRows = COUNT(*) FROM @invoicesFromDB
	
	WHILE ( @index <= @maxRows)
	BEGIN
		SET @exceptionMessage = ''
		SET @tempCCId = (SELECT InvoiceID FROM @invoicesFromDB WHERE ID=@index)
		SET @tempccNumber = (SELECT RIGHT((ltrim(rtrim(isnull(CreditCardNumber,'')))),5) FROM TemporaryCreditCard WITH (NOLOCK) WHERE ID = @tempCCId)
		SET @totalChargedAmount = (SELECT ISNULL(TotalChargedAmount,0) FROM TemporaryCreditCard WITH (NOLOCK) WHERE ID = @tempCCId)
		SET @referencePONumber = (SELECT ReferencePurchaseOrderNumber FROM TemporaryCreditCard WITH (NOLOCK) WHERE ID = @tempCCId)
		
		--Process posted status.Ignore processing other blocks
		IF((SELECT Count(TC.ID) FROM TemporaryCreditCard TC
		   JOIN TemporaryCreditCardStatus TCS ON TCS.ID = TC.TemporaryCreditCardStatusID
		   WHERE TC.ID = @tempCCId AND (TCS.Name = 'Posted' OR TC.PostingBatchID is not null) ) > 0)
		BEGIN
			SET @Posted = @Posted + 1
			SET @PostedAmount = @PostedAmount + @totalChargedAmount
		END
		--Process cancelled status
		ELSE IF((SELECT Count(ID) FROM TemporaryCreditCard WITH (NOLOCK) WHERE ID = @tempCCId AND IssueStatus='Cancel') > 0)
		BEGIN
			IF((SELECT Count(TC.ID) FROM TemporaryCreditCard TC WITH (NOLOCK)
			   JOIN PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderNumber = TC.ReferencePurchaseOrderNumber
			   WHERE TC.ID = @tempCCId) = 0)
			BEGIN
			
				UPDATE TemporaryCreditCard
				SET TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Cancelled'),
					ModifyBy = @currentUser,
					ModifyDate = @now,
					ExceptionMessage = NULL
				WHERE ID = @tempCCId
				
				SET @Cancelled = @Cancelled + 1
				SET @CancelledAmount = @CancelledAmount + @totalChargedAmount
				
			END
			
		END
		--Process exact match
		ELSE IF((SELECT Count(*) FROM
				(
				SELECT TOP 1 PO.PurchaseOrderAmount,
					   RIGHT((ltrim(rtrim(isnull(PO.CompanyCreditCardNumber,'')))),5) POCCNumber
				FROM PurchaseOrder PO WITH (NOLOCK)
			    WHERE PO.PurchaseOrderNumber = @referencePONumber
				)TP WHERE TP.PurchaseOrderAmount >= @totalChargedAmount AND @tempccNumber != '' AND TP.POCCNumber = @tempccNumber)
				> 0)
		BEGIN
			    UPDATE TemporaryCreditCard
				SET TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Matched'),
				    ModifyBy = @currentUser,
					ModifyDate = @now,
					ExceptionMessage = NULL
				WHERE ID = @tempCCId
				
				
		END
		--Process exceptions
		ELSE
		BEGIN
			--Check cancelled po exist
			IF((SELECT Count(TC.ID) FROM TemporaryCreditCard TC WITH (NOLOCK)
			   JOIN PurchaseOrder PO ON PO.PurchaseOrderNumber = TC.ReferencePurchaseOrderNumber
			   WHERE TC.ID = @tempCCId AND TC.IssueStatus = 'Cancel') > 0)
			BEGIN
				SET @exceptionMessage = @exceptionMessage + 'PO matches cancelled CC' + ','
				
			END
			
			--Check charge amount greater than po amount
			IF((SELECT Count(TC.ID) FROM TemporaryCreditCard TC WITH (NOLOCK)
			   JOIN PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderNumber = TC.ReferencePurchaseOrderNumber
			   WHERE TC.ID = @tempCCId AND PO.PurchaseOrderAmount < @totalChargedAmount) > 0)
			BEGIN
				SET @exceptionMessage = @exceptionMessage + 'Charge amount exceeds PO amount' + ','
				
			END
			
			--Check pomismatch
			SET @ccMatchCount = (SELECT Count(PO.ID)
								 FROM PurchaseOrder PO WITH (NOLOCK)
								 WHERE RIGHT((ltrim(rtrim(isnull(PO.CompanyCreditCardNumber,'')))),5) = @tempccNumber)
			
			IF(@ccMatchCount > 0)
			BEGIN
				IF((SELECT Count(*) FROM
									(
									 SELECT PO.PurchaseOrderNumber
									 FROM PurchaseOrder PO WITH (NOLOCK)
									 WHERE RIGHT((ltrim(rtrim(isnull(PO.CompanyCreditCardNumber,'')))),5) = @tempccNumber
									)TP WHERE TP.PurchaseOrderNumber = @referencePONumber) = 0)
				
				BEGIN
					SET @exceptionMessage = @exceptionMessage + 'PO# Mismatch' + ','
					
				END
				
			END	
			
			--Check cc mismatch				
			SET @poMatchCount = (SELECT COUNT(PO.ID)
								FROM PurchaseOrder PO WITH (NOLOCK)
								WHERE PO.PurchaseOrderNumber = @referencePONumber)	
			
			IF(@poMatchCount > 0)
			BEGIN
				IF((SELECT Count(*) FROM
									(
									SELECT PO.PurchaseOrderAmount,
										   RIGHT((ltrim(rtrim(isnull(PO.CompanyCreditCardNumber,'')))),5) POCCNumber
									FROM PurchaseOrder PO WITH (NOLOCK)
									WHERE PO.PurchaseOrderNumber = @referencePONumber
									)TP WHERE @tempccNumber != '' AND TP.POCCNumber = @tempccNumber) = 0)
				BEGIN
					SET @exceptionMessage = @exceptionMessage + 'CC# Mismatch' + ','
					
				END
			END
			
			--Check if both po and cc does not match
			IF(@ccMatchCount = 0 AND @poMatchCount = 0)
			BEGIN
				SET @exceptionMessage = @exceptionMessage + 'No matching PO# or CC#' + ','
			END
			
			--Update exception and amount
			IF(@exceptionMessage != '')
			BEGIN
				IF((charindex(',', reverse(@exceptionMessage))) = 1)
				BEGIN
					SET @exceptionMessage = SUBSTRING(@exceptionMessage,1,LEN(@exceptionMessage)-1)
				END
				
				UPDATE TemporaryCreditCard
				SET TemporaryCreditCardStatusID = (SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Exception'),
				    ExceptionMessage = @exceptionMessage,
				    ModifyBy = @currentUser,
					ModifyDate = @now
				WHERE ID = @tempCCId
				
				SET @Exception = @Exception + 1
				SET @ExceptionAmount = @ExceptionAmount + @totalChargedAmount
			END
		END
		
		IF((SELECT Count(ID) FROM TemporaryCreditCard
			WHERE TemporaryCreditCardStatusID=(SELECT ID FROM TemporaryCreditCardStatus WHERE Name='Matched') AND ID=@tempCCId)
			>0)
		BEGIN
			SET @Matched = @Matched + 1
			SET @MatchedAmount = @MatchedAmount + @totalChargedAmount
				
			SET @MatchedIds = @MatchedIds + CONVERT(nvarchar(20),@tempCCId) + ','
		END
		
	    SET @index = @index + 1
	END
	
	IF((charindex(',', reverse(@MatchedIds))) = 1)
	BEGIN
		SET @MatchedIds = SUBSTRING(@MatchedIds,1,LEN(@MatchedIds)-1)
	END
	
	SELECT @Matched 'MatchedCount',
		   @MatchedAmount 'MatchedAmount',
		   @Posted 'PostedCount',
		   @PostedAmount 'PostedAmount',
		   @Cancelled 'CancelledCount',
		   @CancelledAmount 'CancelledAmount',
		   @Exception 'ExceptionCount',
		   @ExceptionAmount 'ExceptionAmount',
		   @MatchedIds 'MatchedIds'
END
GO
