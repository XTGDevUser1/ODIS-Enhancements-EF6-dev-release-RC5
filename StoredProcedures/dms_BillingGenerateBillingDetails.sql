
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
 ** CHANGE LOG:
 ** ^1	02/09/14	MJKrzysiak	Added Code Throughout to support IsEditable
 **								functionality.
 ** ^2	02/14/14	MJKrzysiak	Added PENDING to the open schedule logic
 **
 ** ^3	02/24/14	MJKrzysiak	Added code throughout to support IsEdited
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
		@IsEditable as bit,
		@IsEdited as bit

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
 ScheduleRangeEnd			datetime)

create index inx_tmpDefOpenSchedules1 on #tmpDefOpenSchedules (BillingDefinitionInvoiceID)

insert into #tmpDefOpenSchedules
(BillingDefinitionInvoiceID,
 BillingScheduleID,
 ScheduleTypeID,
 ScheduleDateTypeID,
 ScheduleRangeTypeID,
 ScheduleDate, 
 ScheduleRangeBegin,
 ScheduleRangeEnd)
select	bdi.ID, -- BillingDefinitionInvoiceID
		bs.ID, -- BillingScheduleID
		bs.ScheduleTypeID,
		bs.ScheduleDateTypeID,
		bs.ScheduleRangeTypeID,
		bs.ScheduleDate,
		bs.ScheduleRangeBegin,
		bs.ScheduleRangeEnd
from	dbo.BillingSchedule bs
join	dbo.BillingScheduleStatus bss on bss.ID = bs.ScheduleStatusID
join	dbo.BillingDefinitionInvoice bdi on bdi.ScheduleTypeID = bs.ScheduleTypeID
		and bdi.ScheduleDateTypeID = bs.ScheduleDateTypeID
		and bdi.ScheduleRangeTypeID = bs.ScheduleRangeTypeID
join
		(select	distinct BillingDefinitionInvoiceID
		 from	#tmpBillingEvents) D on D.BillingDefinitionInvoiceID = bdi.ID
where	bss.Name in ('OPEN', 'PENDING') -- ^ 2


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
 IsEditable								bit,
 IsEdited								bit
)

CREATE NONCLUSTERED INDEX [idx_tmpInvoiceDetail] ON #tmpInvoiceDetail 
(
	[BillingDefinitionInvoiceID] ASC,
	[BillingDefinitionInvoiceLineID] ASC,
	[BillingDefinitionEventID] ASC,
	[BillingScheduleID] ASC,
	[ProgramID] ASC,
	[EntityID] ASC,
	[EntityKey] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]


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
	 IsEditable,
	 IsEdited)
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
			@IsEditable, -- IsEditable
			0 -- IsEdited
			
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
 EntityKey nvarchar(50))

insert into #tmpDeletes
(BillingDefinitionInvoiceID,
 BillingDefinitionInvoiceLineID,
 BillingDefinitionEventID,
 BillingScheduleID,
 ProgramID,
 EntityID,
 EntityKey)
select	BillingDefinitionInvoiceID,
		BillingDefinitionInvoiceLineID,
		BillingDefinitionEventID,
		BillingScheduleID,
		ProgramID,
		EntityID,
		EntityKey
from	dbo.BillingInvoiceDetail bid
where	exists -- Within the Invoice Definition and Schedule 
	(select 1
	 from	#tmpDefOpenSchedules tmp
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
					IsEditable,
					IsEdited

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
 IsEditable,
 IsEdited
)

ON 
	(target.BillingDefinitionInvoiceID = source.BillingDefinitionInvoiceID
	and		target.BillingDefinitionInvoiceLineID = source.BillingDefinitionInvoiceLineID
	and		target.BillingDefinitionEventID = source.BillingDefinitionEventID
	and		target.BillingScheduleID = source.BillingScheduleID
	and		target.ProgramID = source.ProgramID
	and		target.EntityID = source.EntityID
	and		target.EntityKey = source.EntityKey)

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
		Quantity = 
					(case
					 when target.IsEdited = 1 then target.Quantity
					 else source.Quantity
					 end), -- ^3 Do not update if IsEdited = 1...set to itself

		EventAmount = 
					(case
					 when target.ISEdited = 1 then target.EventAmount
					 else source.EventAmount
					 end), -- ^3 Do not update if IsEdited =1...set to itself

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
		 IsEditable,
		 IsEdited
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
		source.IsEditable,
		source.IsEdited
);

end
GO

