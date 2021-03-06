
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




GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1431  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 
	DECLARE @Hold TABLE(ColumnName NVARCHAR(MAX),ColumnValue NVARCHAR(MAX),DataType NVARCHAR(MAX),Sequence INT,GroupName NVARCHAR(MAX),DefaultRows INT NULL) 
DECLARE @ProgramDataItemValues TABLE(Name NVARCHAR(MAX),Value NVARCHAR(MAX),ScreenName NVARCHAR(MAX))       

;WITH wProgDataItemValues
AS
(
SELECT ROW_NUMBER() OVER ( PARTITION BY EntityID, RecordID, ProgramDataItemID ORDER BY CreateDate DESC) AS RowNum,
              *
FROM   ProgramDataItemValueEntity 
WHERE  RecordId = (SELECT CaseID FROM ServiceRequest WHERE ID=@serviceRequestID)
)

INSERT INTO @ProgramDataItemValues
SELECT 
        PDI.Name,
        W.Value,
        PDI.ScreenName
FROM   ProgramDataItem PDI
JOIN   wProgDataItemValues W ON PDI.ID = W.ProgramDataItemID
WHERE  W.RowNum = 1



	DECLARE @DocHandle int    
	DECLARE @XmlDocument NVARCHAR(MAX)   
	DECLARE @ProductID INT
	SET @ProductID = NULL
	SELECT  @ProductID = PrimaryProductID FROM ServiceRequest WHERE ID = @serviceRequestID

-- Dates used while calculating member status
	DECLARE @now DATETIME, @minDate DATETIME
	SET @now = DATEADD(dd,DATEDIFF(dd,0,GETDATE()),0)
	SET @minDate = '1900-01-01'

	SET FMTONLY OFF    
-- Sanghi : ISNull is required because generating XML will ommit the columns.     
-- Two Blank Space is required.  
	DECLARE @tmpServiceLocationVendor TABLE
	(
		Line1 NVARCHAR(100) NULL,
		Line2 NVARCHAR(100) NULL,
		Line3 NVARCHAR(100) NULL,
		City NVARCHAR(100) NULL,
		StateProvince NVARCHAR(100) NULL,
		CountryCode NVARCHAR(100) NULL,
		PostalCode NVARCHAR(100) NULL,
		
		TalkedTo NVARCHAR(50) NULL,
		PhoneNumber NVARCHAR(100) NULL,
		VendorName NVARCHAR(100) NULL
	)
	INSERT INTO @tmpServiceLocationVendor	
	SELECT	TOP 1	AE.Line1, 
					AE.Line2, 
					AE.Line3, 
					AE.City, 
					AE.StateProvince, 
					AE.CountryCode, 
					AE.PostalCode,
					cl.TalkedTo,
					cl.PhoneNumber,
					V.Name As VendorName
		FROM	ContactLogLink cll
		JOIN	ContactLog cl on cl.ID = cll.ContactLogID
		JOIN	ContactLogLink cll2 on cll2.contactlogid = cl.id and cll2.entityid = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest') and cll2.RecordID = @serviceRequestID
		JOIN	VendorLocation VL ON cll.RecordID = VL.ID
		JOIN	Vendor V ON VL.VendorID = V.ID 	
		JOIN	AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		WHERE	cll.entityid = (SELECT ID FROM Entity WHERE name = 'VendorLocation')
		AND		cl.ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ServiceLocationSelection')
		ORDER BY cll.id DESC
	

  
	SET @XmlDocument = (SELECT TOP 1    

-- PROGRAM SECTION
--	1 AS Program_DefaultNumberOfRows   
	cl.Name + ' - ' + p.name as Program_ClientProgramName    
    ,(SELECT 'Case Number:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='CaseNumber') AS Program_CaseNumber
    ,(SELECT 'Agent Name:'+Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='AgentName') AS Program_AgentName
    ,(SELECT 'Claim Number:'+ Value FROM @ProgramDataItemValues WHERE ScreenName='StartCall' AND Name='ClaimNumber') AS Program_ClaimNumber
-- MEMBER SECTION
--	, 5 AS Member_DefaultNumberOfRows
-- KB : 6/7 : TFS # 1339 : Presenting Case.Contactfirstname and Case.ContactLastName as member name and the values from member as company_name when the values differ.	
	, COALESCE(c.ContactFirstName,'') + COALESCE(' ' + c.ContactLastName,'') AS Member_Name
	, CASE
		WHEN	c.ContactFirstName <> m.Firstname
		AND		c.ContactLastName <> m.LastName
		THEN
				REPLACE(RTRIM(    
				COALESCE(m.FirstName, '') +    
				COALESCE(m.MiddleName, '') +   
				COALESCE(m.Suffix, '') + 
				COALESCE(' ' + m.LastName, '') 
				), '  ', ' ')
		ELSE
				NULL
		END as Member_CompanyName
    , ISNULL(ms.MembershipNumber,' ') AS Member_MembershipNumber
    -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status       
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactPhoneTypeID),' ') as Member_CallbackPhoneTypeID    
    , ISNULL(c.ContactPhoneNumber,'') as Member_CallbackPhoneNumber    
    , ISNULL((SELECT NAME FROM PhoneType WHERE ID = c.ContactAltPhoneTypeID),' ') as Member_AltCallbackPhoneTypeID   
    , ISNULL(c.ContactAltPhoneNumber,'') as Member_AltCallbackPhoneNumber    
    , CONVERT(nvarchar(10),m.MemberSinceDate,101) as Member_MemberSinceDate
    , CONVERT(nvarchar(10),m.EffectiveDate,101) AS Member_EffectiveDate
    , CONVERT(nvarchar(10),m.ExpirationDate,101) AS Member_ExpirationDate
    , ISNULL(ae.Line1,'') AS Member_AddressLine1
    , ISNULL(ae.Line2,'') AS Member_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(ae.City, '') +
		COALESCE(', ' + ae.StateProvince, '') +
		COALESCE(' ' + ae.PostalCode, '') +
		COALESCE(' ' + ae.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS Member_AddressCityStateZip
	,'Client Ref #:' + ms.ClientReferenceNumber AS Member_ReceiptNumber
-- VEHICLE SECTION
--	, 3 AS Vehicle_DefalutNumberOfRows
	, ISNULL(RTRIM (
		COALESCE(c.VehicleYear + ' ', '') +    
		COALESCE(CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END+ ' ', '') +    
		COALESCE(CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END, '')
		), ' ') as Vehicle_YearMakeModel    
	, ISNULL(c.VehicleVIN,' ') as Vehicle_VIN    
	, ISNULL(RTRIM (
		COALESCE(c.VehicleColor + '  ' , '') +
		COALESCE(c.VehicleLicenseState + '-','') + 
		COALESCE(c.VehicleLicenseNumber, '')
		), ' ' ) AS Vehicle_Color_LicenseStateNumber
    ,ISNULL(
			COALESCE((SELECT Name FROM VehicleType WHERE ID = c.VehicleTypeID) + '-','') +
			COALESCE((SELECT Name FROM VehicleCategory WHERE ID = c.VehicleCategoryID),'') 
		,'') AS Vehicle_Type_Category
    ,ISNULL(C.[VehicleDescription],'') AS Vehicle_Description
    ,CASE WHEN C.[VehicleLength] IS NULL THEN '' ELSE CONVERT(NVARCHAR(50),C.[VehicleLength]) END AS Vehicle_Length  
-- SERVICE SECTION   
--	, 2 AS Service_DefaultNumberOfRows  
	, ISNULL(
		COALESCE(pc.Name, '') + 
		COALESCE('/' + CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' END, '')
		,' ') as Service_ProductCategoryTow    
	, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.CoverageLimit,0)) as Service_CoverageLimit  

-- LOCATION SECTION     
--	, 2 AS Location_DefaultNumberOfRows
	, ISNULL(sr.ServiceLocationAddress,' ') as Location_Address    
	, ISNULL(sr.ServiceLocationDescription,' ') as Location_Description  

-- DESTINATION SECTION     
--	, 2 AS Destination_DefaultNumberOfRows
	, ISNULL(sr.DestinationAddress,' ') as Destination_Address    
	, ISNULL(sr.DestinationDescription,' ') as Destination_Description 	
	, (SELECT VendorName FROM @tmpServiceLocationVendor ) AS Destination_VendorName
	, (SELECT PhoneNumber FROM @tmpServiceLocationVendor ) AS Destination_PhoneNumber
	, (SELECT TalkedTo FROM @tmpServiceLocationVendor ) AS Destination_TalkedTo
	, (SELECT ISNULL(Line1,'') FROM @tmpServiceLocationVendor ) AS Destination_AddressLine1
    , (SELECT ISNULL(Line2,'') FROM @tmpServiceLocationVendor) AS Destination_AddressLine2
    , (SELECT ISNULL(REPLACE(RTRIM(    
		COALESCE(City, '') +
		COALESCE(', ' + StateProvince, '') +
		COALESCE(' ' + PostalCode, '') +
		COALESCE(' ' + CountryCode, '') 
		), '  ', ' ')
		, ' ' ) FROM  @tmpServiceLocationVendor) AS Destination_AddressCityStateZip    
		
-- ISP SECTION
--	, 3 AS ISP_DefaultNumberOfRows
	--,CASE 
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
	--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
	--	WHEN vc.ID IS NOT NULL THEN 'Contracted' 
	--	ELSE 'Not Contracted'
	--	END as ISP_Contracted
	, CASE
		WHEN ContractedVendors.ContractID IS NOT NULL 
			AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ISP_Contracted
	, ISNULL(v.Name,' ') as ISP_VendorName    
	, ISNULL(v.VendorNumber, ' ') AS ISP_VendorNumber
	--, ISNULL(peISP.PhoneNumber,' ') as ISP_DispatchPhoneNumber 
	, (SELECT TOP 1 PhoneNumber
		FROM PhoneEntity 
		WHERE RecordID = vl.ID
		AND EntityID = (Select ID From Entity Where Name = 'VendorLocation')
		AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
		ORDER BY ID DESC
		) AS ISP_DispatchPhoneNumber
	, ISNULL(aeISP.Line1,'') AS ISP_AddressLine1
    , ISNULL(aeISP.Line2,'') AS ISP_AddressLine2
    , ISNULL(REPLACE(RTRIM(    
		COALESCE(aeISP.City, '') +
		COALESCE(', ' + aeISP.StateProvince, '') +
		COALESCE(' ' + aeISP.PostalCode, '') +
		COALESCE(' ' + aeISP.CountryCode, '') 
		), '  ', ' ')
		, ' ' ) AS ISP_AddressCityStateZip
	, COALESCE(ISNULL(po.PurchaseOrderNumber + '-', ' '),'') + ISNULL(pos.Name, ' ' ) AS ISP_PONumberStatus
--	, ISNULL(pos.Name, ' ' ) AS ISP_POStatus
	, COALESCE( '$' + CONVERT(NVARCHAR(10),po.PurchaseOrderAmount),'') 
		+ ' ' 
		+ ISNULL(CASE WHEN po.ID IS NOT NULL THEN PC.Name ELSE NULL END,'') AS ISP_POAmount_ProductCategory
	--, ISNULL(po.PurchaseOrderAmount, ' ' ) AS ISP_POAmount
	, 'Issued:' +
		REPLACE(CONVERT(VARCHAR(8), po.IssueDate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.IssueDate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.IssueDate, 9), 25, 2) AS ISP_IssuedDate  
	, 'ETA:' +
		REPLACE(CONVERT(VARCHAR(8), po.ETADate, 10), '-', '/') + ' - ' +  
		SUBSTRING(CONVERT(VARCHAR(20), po.ETADate, 9), 13, 8) + ' ' +  
		SUBSTRING(CONVERT(VARCHAR(30), po.ETADate, 9), 25, 2) AS ISP_ETADate  

-- SERVICE REQUEST SECTION 
--	, 2 AS SR_DefaultNumberOfRows
	--Sanghi 03 - July - 2013 Updated Below Line.
	, CAST(CAST(ISNULL(sr.ID, ' ') AS NVARCHAR(MAX)) + ' - ' + ISNULL(srs.Name, ' ') AS NVARCHAR(MAX))  AS SR_Info 
	--, ISNULL(sr.ID,' ') as SR_ServiceRequestID      
	--,(ISNULL(srs.Name,'')) + CASE WHEN na.Name IS NULL THEN '' ELSE ' - ' + (ISNULL(na.Name,'')) END AS SR_ServiceRequestStatus
	--, ISNULL('Closed Loop: ' + cls.Name, ' ') as SR_ClosedLoopStatus
	, ISNULL(sr.CreateBy,' ') + ' ' + 
		    REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2
			) AS SR_CreateInfo
	--, ISNULL(sr.CreateBy,' ')as SR_CreatedBy   
	--, REPLACE(CONVERT(VARCHAR(8), sr.CreateDate, 10), '-', '/') + ' - ' +  
	--	SUBSTRING(CONVERT(VARCHAR(20), sr.CreateDate, 9), 13, 8) + ' ' +  
	--	SUBSTRING(CONVERT(VARCHAR(30), sr.CreateDate, 9), 25, 2) AS SR_CreateDate
	--, ISNULL(NextAction.Name, ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionInfo  
	, ISNULL(NextAction.Name + ' - ', ' ') + ISNULL(u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionName_AssignedTo
	, ISNULL( 	
			REPLACE(
			CONVERT(VARCHAR(8), sr.NextActionScheduledDate, 10), '-', '/') + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(20), sr.NextActionScheduledDate, 9), 13, 8) + ' ' +  
			SUBSTRING(CONVERT(VARCHAR(30), sr.NextActionScheduledDate, 9), 25, 2
			) 
			, ' ') AS SR_NextActionScheduledDate
	--, ISNULL('AssignedTo: ' + u.FirstName, ' ') + ' ' + ISNULL(u.LastName,' ') AS SR_NextActionAssignedTo  

	FROM		ServiceRequest sr      
	JOIN		[Case] c on c.ID = sr.CaseID    
	LEFT JOIN	PhoneType ptContact on ptContact.ID = c.ContactPhoneTypeID    
	JOIN		Program p on p.ID = c.ProgramID    
	JOIN		Client cl on cl.ID = p.ClientID    
	JOIN		Member m on m.ID = c.MemberID    
	JOIN		Membership ms on ms.ID = m.MembershipID    
	LEFT JOIN	AddressEntity ae ON ae.EntityID = (select ID from Entity where Name = 'Membership')    
	AND			ae.RecordID = ms.ID    
	AND			ae.AddressTypeID = (select ID from AddressType where Name = 'Home')    
	LEFT JOIN	Country country on country.ID = ae.CountryID     
	LEFT JOIN	PhoneEntity peMbr ON peMbr.EntityID = (select ID from Entity where Name = 'Membership')     
	AND			peMbr.RecordID = ms.ID    
	AND			peMbr.PhoneTypeID = (select ID from PhoneType where Name = 'Home')    
	LEFT JOIN	PhoneType ptMbr on ptMbr.ID = peMbr.PhoneTypeID    
	LEFT JOIN	ProductCategory pc on pc.ID = sr.ProductCategoryID    
	LEFT JOIN	(  
				SELECT TOP 1 *  
				FROM PurchaseOrder wPO   
				WHERE wPO.ServiceRequestID = @serviceRequestID  
				AND wPO.IsActive = 1
				AND wPO.PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
				ORDER BY wPO.IssueDate DESC  
				) po on po.ServiceRequestID = sr.ID  
	LEFT JOIN	PurchaseOrderStatus pos on pos.ID = po.PurchaseOrderStatusID  
	LEFT JOIN	VendorLocation vl on vl.ID = po.VendorLocationID    
	LEFT JOIN	Vendor v on v.ID = vl.VendorID 
	LEFT JOIN	[Contract] vc on vc.VendorID = v.ID and vc.IsActive = 1 and vc.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
	LEFT OUTER JOIN (
				SELECT DISTINCT vr.VendorID, vr.ProductID
				FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
				) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
	LEFT OUTER JOIN (
				SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
				FROM dbo.fnGetContractedVendors() cv
				) ContractedVendors ON v.ID = ContractedVendors.VendorID
	--LEFT JOIN	PhoneEntity peISP on peISP.EntityID = (select ID from Entity where Name = 'VendorLocation')     
	--AND			peISP.RecordID = vl.ID    
	--AND			peISP.PhoneTypeID = (select ID from PhoneType where Name = 'Dispatch')  
	--LEFT JOIN	PhoneType ptISP on ptISP.ID = peISP.PhoneTypeID    
	--LEFT JOIN (
	--			SELECT TOP 1 ph.RecordID, ph.PhoneNumber
	--			FROM PhoneEntity ph 
	--			WHERE EntityID = (Select ID From Entity Where Name = 'VendorLocation')
	--			AND PhoneTypeID = (Select ID From PhoneType Where Name = 'Dispatch')
	--			ORDER BY ID 
	--		   )  peISP ON peISP.RecordID = vl.ID
	LEFT JOIN	AddressEntity aeISP ON aeISP.EntityID = (select ID from Entity where Name = 'VendorLocation')    
	AND			aeISP.RecordID = vl.ID    
	AND			aeISP.AddressTypeID = (select ID from AddressType where Name = 'Business')    
 -- CR # 524  
	LEFT JOIN	ServiceRequestStatus srs ON srs.ID=sr.ServiceRequestStatusID  
	LEFT JOIN	NextAction na ON na.ID=sr.NextActionID  
	LEFT JOIN	ClosedLoopStatus cls ON cls.ID=sr.ClosedLoopStatusID 
 -- End : CR # 524  
 	LEFT JOIN	VendorLocation VLD ON VLD.ID = sr.DestinationVendorLocationID
	LEFT JOIN	PhoneEntity peDestination ON peDestination.RecordID = VLD.ID AND peDestination.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
	LEFT JOIN	NextAction NextAction on NextAction.ID = sr.NextActionID
	LEFT JOIN	[User] u on u.ID = sr.NextActionAssignedToUserID

	WHERE		sr.ID = @ServiceRequestID    
	FOR XML PATH)    
    

EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument    
SELECT * INTO #Temp FROM OPENXML (@DocHandle, '/row',2)      
INSERT INTO @Hold    
SELECT T1.localName ,T2.text,'String',ROW_NUMBER() OVER(ORDER BY T1.ID),'',NULL FROM #Temp T1     
INNER JOIN #Temp T2 ON T1.id = T2.parentid    
WHERE T1.id > 0    
    
    
DROP TABLE #Temp    
    -- Group Values Based on Sequence Number    
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 5 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 2 WHERE CHARINDEX('Service_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Location', DefaultRows = 2 WHERE CHARINDEX('Location_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Destination', DefaultRows = 2 WHERE CHARINDEX('Destination_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'ISP', DefaultRows = 10 WHERE CHARINDEX('ISP_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Program', DefaultRows = 1 WHERE CHARINDEX('Program_',ColumnName) > 0   
 UPDATE  @Hold SET GroupName = 'Service Request', DefaultRows = 2 WHERE CHARINDEX('SR_',ColumnName) > 0   
     
 --CR # 524   
      
-- UPDATE @Hold SET GroupName ='Service Request' where ColumnName in ('ServiceRequestID','ServiceRequestStatus','NextAction',  
--'ClosedLoopStatus',  
--'CreateDate','CreatedBy','SR_NextAction','SR_NextActionAssignedTo')  
 -- End : CR # 524  
   
 UPDATE @Hold SET DataType = 'Phone' WHERE CHARINDEX('PhoneNumber',ColumnName) > 0    
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0    

 DELETE FROM @Hold WHERE ColumnValue IS NULL

 DECLARE @DefaultRows INT
 SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Member_AltCallbackPhoneNumber')
 IF @DefaultRows IS NOT NULL
 BEGIN
 SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Member_%' AND Sequence <= @DefaultRows)
 -- Re Setting values 
 UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Member' 
 END
 -- Update Label fields
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Member Since: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_MemberSinceDate')
 WHERE ColumnName = 'Member_MemberSinceDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Effective: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_EffectiveDate')
 WHERE ColumnName = 'Member_EffectiveDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Expiration: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Member_ExpirationDate')
 WHERE ColumnName = 'Member_ExpirationDate'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'PO: ' + ColumnValue FROM @Hold WHERE ColumnName = 'ISP_PONumberStatus')
 WHERE ColumnName = 'ISP_PONumberStatus'
 
 UPDATE @Hold
 SET ColumnValue = (SELECT 'Length: ' + ColumnValue FROM @Hold WHERE ColumnName = 'Vehicle_Length')
 WHERE ColumnName = 'Vehicle_Length'
 
 
 SELECT * FROM @Hold WHERE ColumnValue IS NOT NULL ORDER BY Sequence ASC 
 
	
END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Communication_Fax_Update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Communication_Fax_Update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Communication_Fax_Update] 'kbanda'
 CREATE PROCEDURE [dbo].[dms_Communication_Fax_Update](@userName NVARCHAR(50) = NULL)
 AS
 BEGIN
 
DECLARE @tmpRecordstoUpdate TABLE
(
CommunicationLogID INT NOT NULL,
ContactLogID INT NOT NULL,
[Status] nvarchar(255) NULL,
FaxResult nvarchar(2000) NULL,
FaxInfo nvarchar(2000)NULL,
sRank INT NOT NULL,
CommunicationLogCreateBy NVARCHAR(100) NULL
)
 
	
    -- To Update the Records in Batch
	--WITH wResult AS(
	INSERT INTO @tmpRecordstoUpdate
	SELECT	CL.ID,
			CL.ContactLogID,
			CL.[Status],
			FR.[result] AS FaxResult,
			FR.[info] AS FaxInfo,
			ROW_NUMBER() OVER(PARTITION BY FR.Billing_Code ORDER BY FR.[Date] DESC) AS 'SRank',
			CL.CreateBy
			FROM CommunicationLog CL
			 INNER JOIN FaxResult FR ON
			 FR.[billing_code] <> '' AND 
			 FR.[billing_code] = CL.ID
			 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
			 AND [Status] = 'PENDING'

	UPDATE CommunicationLog 
	SET [Status] = T.FaxResult,
		Comments = T.FaxInfo,
		ModifyDate = getdate(),
		ModifyBy = @username 
	FROM CommunicationLog 
	JOIN @tmpRecordstoUpdate T on T.CommunicationLogID = CommunicationLog.ID
	WHERE T.sRank = 1
				 
	--UPDATE wResult SET wResult.[Status] = wResult.FaxResult,
	--				   wResult.Comments = wResult.[FaxInfo],
	--				   wResult.ModifyDate = getdate(),
	--				   wResult.ModifyBy = @userName 
	--				   WHERE SRank = 1
					   
	-- Create New Records in Batch if Contact Log ID is not NULL				   
	--;WITH wResultInsert AS(
	--SELECT CL.*,FR.[result] AS FaxResult,FR.[info] AS FaxInfo FROM CommunicationLog CL
	--		 INNER JOIN FaxResult FR ON
	--		 FR.[billing_code] = CL.ID
	--		 WHERE ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
	--		 AND
	--		 [Status] IN ('SUCCESS','FAILURE')
	--		 AND ContactLogID IS NOT NULL)
	INSERT INTO ContactLogAction(ContactActionID,ContactLogID,Comments,CreateDate,CreateBy)
		   SELECT DISTINCT
		     Case FaxResult 
				WHEN 'SUCCESS' THEN (SELECT ID FROM ContactAction WHERE Name = 'Sent')
				ELSE (SELECT ID FROM ContactAction WHERE Name = 'SendFailure')
			END as ContactActionID,
		   [ContactLogID],FaxInfo,GETDATE(),@userName
		   FROM @tmpRecordstoUpdate
		   WHERE sRank = 1

	-- KB: Notifications
	-- For every communicationlog record whose status was set to FAIL, create eventlog records with event
	DECLARE @eventIDForSendPOFaxFailed INT,
			@eventDescriptionForSendPOFaxFailed NVARCHAR(255),
			@poEntityID INT,
			@contactLogActionEntityID INT,
			@idx INT = 1,
			@maxRows INT,
			@eventLogID INT,
			@sendFailureContactActionID INT

	SELECT	@eventIDForSendPOFaxFailed = ID, @eventDescriptionForSendPOFaxFailed = [Description] FROM [Event] WITH (NOLOCK) WHERE Name = 'SendPOFaxFailed'
	SELECT	@poEntityID = ID FROM Entity WHERE Name = 'PurchaseOrder'
	SELECT	@contactLogActionEntityID = ID FROM Entity WHERE Name = 'ContactLogAction'
	SELECT	@sendFailureContactActionID = ID FROM ContactAction WHERE Name = 'SendFailure'

	CREATE TABLE #tmpCommunicationLogFaxFailed
	(
		RowNum INT IDENTITY(1,1) NOT NULL,
		CommunicationLogID INT NOT NULL,
		ContactLogID INT NOT NULL,
		PurchaseOrderID INT NULL,
		PurchaseOrderNumber NVARCHAR(50) NULL,
		ServiceRequestNumber INT NULL,
		FailureReason NVARCHAR(MAX) NULL,
		CommunicationLogCreateBy NVARCHAR(100) NULL
	)

	INSERT INTO #tmpCommunicationLogFaxFailed 
	SELECT	T.CommunicationLogID,
			T.ContactLogID,
			CLL.RecordID,
			PO.PurchaseOrderNumber,
			PO.ServiceRequestID,
			T.FaxInfo,
			T.CommunicationLogCreateBy
	FROM	@tmpRecordstoUpdate T
	LEFT JOIN	ContactLogLink CLL ON T.ContactLogID = CLL.ContactLogID AND CLL.EntityID = @poEntityID
	LEFT JOIN	PurchaseOrder PO ON PO.ID = CLL.RecordID
	WHERE	T.FaxResult = 'FAILURE'
	AND		T.sRank = 1

	SELECT @maxRows = MAX(RowNum) FROM #tmpCommunicationLogFaxFailed


	--DEBUG: SELECT * FROM #tmpCommunicationLogFaxFailed

	DECLARE @purchaseOrderID INT,
			@serviceRequestID INT,
			@purchaseOrderNumber NVARCHAR(50),
			@contactLogID INT,
			@failureReason NVARCHAR(MAX),
			@commLogCreateBy NVARCHAR(100)

	WHILE ( @idx <= @maxRows )
	BEGIN
		
		SELECT	@contactLogID		= T.ContactLogID,
				@failureReason		= T.FailureReason,
				@purchaseOrderID	= T.PurchaseOrderID,
				@purchaseOrderNumber = T.PurchaseOrderNumber,
				@serviceRequestID	= T.ServiceRequestNumber,
				@commLogCreateBy	= T.CommunicationLogCreateBy
		FROM	#tmpCommunicationLogFaxFailed T WHERE T.RowNum = @idx

		-- For each communication log record related to fax failure, log an event and create link records - one per 
		INSERT INTO EventLog (	EventID,
								Source,
								Description,
								Data,
								NotificationQueueDate,
								CreateDate,
								CreateBy)
		SELECT	@eventIDForSendPOFaxFailed,
				'Communication Service',
				@eventDescriptionForSendPOFaxFailed,
				'<MessageData><PONumber>' + @purchaseOrderNumber + 
							'</PONumber><ServiceRequest>' + CONVERT(NVARCHAR(50),@serviceRequestID) + 
							'</ServiceRequest><FaxFailureReason>' + @failureReason + 
							'</FaxFailureReason><CreateByUser>' +  @commLogCreateBy +
							'</CreateByUser></MessageData>',
				NULL,
				GETDATE(),
				'system'
		

		SET @eventLogID = SCOPE_IDENTITY()

		--DEBUG: SELECT @eventLogID AS EventLogID

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@poEntityID,
				@purchaseOrderID

		;WITH wContactLogActions
		AS
		(
			SELECT	ROW_NUMBER() OVER ( PARTITION BY CLA.ContactActionID ORDER BY CLA.CreateDate DESC) As RowNum,
					CLA.ID As ContactLogActionID,
					CLA.ContactLogID
			FROM	ContactLogAction CLA 			
			WHERE	CLA.ContactLogID = @contactLogID
			AND		CLA.ContactActionID = @sendFailureContactActionID
		)

		INSERT INTO EventLogLink ( EventLogID, EntityID, RecordID)
		SELECT	@eventLogID,
				@contactLogActionEntityID,
				W.ContactLogActionID
		FROM	wContactLogActions W 
		WHERE	W.RowNum = 1


		SET @idx = @idx + 1
	END



	DROP TABLE #tmpCommunicationLogFaxFailed
END



GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_CurrentUser_For_Event_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_CurrentUser_For_Event_Get] 'kbanda'
CREATE PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get](
	@eventLogID INT,
	@eventSubscriptionID INT
)
AS
BEGIN
 
	/*
		Assumption : This stored procedure would be executed for DesktopNotifications.
		Logic : 
		If the event is SendPOFaxFailure - Determine the current user as follows:
			1.	Parse EL.Data and pull out <ServiceRequest><SR.ID>  </ServiceRequest>
			2.	Join to Case from that SR.ID and get Case.AssignedToUserID
			3.	Insert one CommunicatinQueue record
			4.	If this value is blank try next one
			iv.	If no current user assigned
			1.	Parse EL.Data and pull out <CreateByUser><username></CreateByUser>
			2.	Check to see if that <username> is online
			3.	If online then Insert one CommunicatinQueue record for that user
			v.	If still no user found or online, then check the Service Request and if the NextAction fields are blank.  If blank then:
			1.	Update the associated ServiceRequest next action fields.  These will be displayed on the Queue prompting someone to take action and re-send the PO
			a.	Set ServiceRequest.NextActionID = Re-send PO
			b.	Set ServiceRequest.NextActionAssignedToUserID = ‘Agent User’

		If the event is ManualNotification, determine the curren user(s) as follows: 
			1. Get the associated EventLogLinkRecords.
			2. For each of the link records:
				2.1 If the related entity on the link record is a user and the user is online, add the user details to the list.
				
		If the event is not SendPOFaxFailure - CurrentUser = ServiceRequest.Case.AssignedToUserID.
	*/

	DECLARE @eventName NVARCHAR(255),
			@eventData XML,
			@PONumber NVARCHAR(100),
			@ServiceRequest INT,
			@FaxFailureReason NVARCHAR(MAX),
			@CreateByUser NVARCHAR(50),

			@assignedToUserIDOnCase INT,
			@nextActionIDOnSR INT,
			@nextActionAssignedToOnSR INT,
			@resendPONextActionID INT,
			@agentUserID INT

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	
	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	
	SELECT	@agentUserID = U.ID
	FROM	[User] U WITH (NOLOCK) 
	JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	WHERE	AU.UserName = 'Agent'
	AND		A.ApplicationName = 'DMS'

	SELECT	@eventData = EL.Data
	FROM	EventLog EL WITH (NOLOCK)
	JOIN	Event E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	EL.ID = @eventLogID

	SELECT	@eventName = E.Name
	FROM	EventSubscription ES WITH (NOLOCK) 
	JOIN	Event E WITH (NOLOCK) ON ES.EventID = E.ID
	WHERE	ES.ID = @eventSubscriptionID
	

	SELECT	@PONumber = (SELECT  T.c.value('.','NVARCHAR(100)') FROM @eventData.nodes('/MessageData/PONumber') T(c)),
			@ServiceRequest = (SELECT  T.c.value('.','INT') FROM @eventData.nodes('/MessageData/ServiceRequest') T(c)),
			@FaxFailureReason = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventData.nodes('/MessageData/FaxFailureReason') T(c)),
			@CreateByUser = (SELECT  T.c.value('.','NVARCHAR(50)') FROM @eventData.nodes('/MessageData/CreateByUser') T(c))
		
	SELECT	@assignedToUserIDOnCase = C.AssignedToUserID
		FROM	[Case] C WITH (NOLOCK)
		JOIN	[ServiceRequest] SR WITH (NOLOCK) ON SR.CaseID = C.ID
		WHERE	SR.ID = @ServiceRequest

	IF (@eventName = 'SendPOFaxFailed')
	BEGIN	
				
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN
			-- Return the user details.
			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.UserName
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	U.ID = @assignedToUserIDOnCase

		END
		ELSE 
		BEGIN
			
			IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			BEGIN
				
				INSERT INTO @tmpCurrentUser
				SELECT	AU.UserId,
						AU.UserName
				FROM	aspnet_Users AU WITH (NOLOCK) 
				JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
				WHERE	AU.UserName = @CreateByUser
				AND		A.ApplicationName = 'DMS'
				
			END
			ELSE
			BEGIN

				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							NextActionAssignedToUserID = @agentUserID
					WHERE	ID = @ServiceRequest

				END
			END				
		END	
	END
	
	ELSE IF (@eventName = 'ManualNotification')
	BEGIN
		
		DECLARE @userEntityID INT

		SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')
		;WITH wUsersFromEventLogLinks
		AS
		(
			SELECT	AU.UserId,
					AU.UserName,
					[dbo].[fnIsUserConnected](AU.UserName) IsConnected				
			FROM	EventLogLink ELL WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON ELL.RecordID = U.ID AND ELL.EntityID = @userEntityID
			JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	ELL.EventLogID = @eventLogID
		)

		INSERT INTO @tmpCurrentUser (UserId, UserName)
		SELECT	W.UserId, W.UserName
		FROM	wUsersFromEventLogLinks W
		WHERE	ISNULL(W.IsConnected,0) = 1


	END	
	ELSE
	BEGIN
		
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN

			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.Username
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON AU.UserId = U.aspnet_UserID
			JOIN	[aspnet_Applications] A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
			WHERE	A.ApplicationName = 'DMS'
			AND		U.ID = @assignedToUserIDOnCase

		END
			
	END	


	SELECT UserId, Username from @tmpCurrentUser

END

GO


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ManualNotification_Event_Log]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ManualNotification_Event_Log] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_ManualNotification_Event_Log] 'SSMS','SSMS','Manual notification','kbanda',1,'AE05306D-492D-4944-B8BA-8E90BE11F393,BEB5FA18-50CE-499D-BB62-FFB9585242AB'
CREATE PROCEDURE [dbo].[dms_ManualNotification_Event_Log](
	@eventSource NVARCHAR(255) = NULL,
	@sessionID NVARCHAR(255) = NULL,
	@message NVARCHAR(MAX) = NULL,
	@createBy NVARCHAR(50) = NULL,
	@recipientTypeID INT = NULL,
	@toUserOrRoleIDs NVARCHAR(MAX) = NULL -- CSV of ASPNET_UserIds / RoleIds
)
AS
BEGIN
 
	DECLARE @tmpUsers TABLE
	(
		ID INT IDENTITY(1,1),
		UserID INT NULL,
		aspnet_UserID UNIQUEIDENTIFIER NULL
	)

	DECLARE @eventLogID INT,
			@idx INT = 1,
			@maxRows INT = 0,
			@userEntityID INT

	SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')

	IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	BEGIN
		
		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_Users AU WITH (NOLOCK) ON T.item = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId
		

	END
	ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role'))
	BEGIN

		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_UsersInRoles UIR WITH (NOLOCK) ON T.item = UIR.RoleId
		JOIN	aspnet_Users AU WITH (NOLOCK) ON UIR.UserId = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId

	END


	INSERT INTO EventLog (	EventID,
							SessionID,
							[Source],
							[Description],
							Data,
							NotificationQueueDate,
							CreateDate,
							CreateBy
						)
	SELECT	(SELECT ID FROM [Event] WHERE Name = 'ManualNotification'),
			@sessionID,
			@eventSource,
			@message,
			'<MessageData><SentFrom>' + @createBy + '</SentFrom><MessageText>' + @message + '</MessageText></MessageData>',
			NULL,
			GETDATE(),
			@createBy

	SET @eventLogID = SCOPE_IDENTITY()
	SELECT @maxRows = MAX(ID) FROM @tmpUsers

	-- Create EventLogLinks
	WHILE (@idx <= @maxRows)
	BEGIN

		INSERT INTO EventLogLink(	EntityID,
									EventLogID,
									RecordID
								)
		SELECT	@userEntityID,
				@eventLogID,
				T.UserID
		FROM	@tmpUsers T WHERE T.ID = @idx

		SET @idx = @idx + 1

	END

END

GO


GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ProgramManagement_DeleteProgramConfiguration]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ProgramManagement_DeleteProgramConfiguration]
GO


CREATE PROC dms_ProgramManagement_DeleteProgramConfiguration(@programConfigurationId INT = NULL)  
AS  
BEGIN 

DELETE FROM ProgramConfiguration
WHERE ID=@programConfigurationId

END
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ProgramManagement_DeleteVehcileType]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ProgramManagement_DeleteVehcileType]
GO


CREATE PROC dms_ProgramManagement_DeleteVehcileType(@programVehicleTypeId INT = NULL)  
AS  
BEGIN 

DELETE FROM ProgramVehicleType
WHERE ID=@programVehicleTypeId

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Program_Management_List_Get @whereClauseXML='<ROW><Filter ClientID="1" ProgramID="5" Name="tes" NameOperator="Conains"></Filter></ROW>'
 CREATE PROCEDURE [dbo].[dms_Program_Management_List_Get]( 
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

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
Number=""
Name=""
NameOperator=""
ClientID=""
ProgramID=""
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
Number NVARCHAR(50) NULL,
Name NVARCHAR(50) NULL,
NameOperator NVARCHAR(50) NULL,
ClientID int NULL,
ProgramID INT NULL
)

INSERT INTO @tmpForWhereClause
SELECT  
	T.c.value('@Number','NVARCHAR(50)'),
	T.c.value('@Name','NVARCHAR(100)'),
	T.c.value('@NameOperator','NVARCHAR(50)'),
	T.c.value('@ClientID','INT'),
	T.c.value('@ProgramID','INT')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @Number			NVARCHAR(50)= NULL,
@Name			NVARCHAR(100)= NULL,
@NameOperator	NVARCHAR(50)= NULL,
@ClientID		INT= NULL,
@ProgramID		INT= NULL

SELECT 
		@Number					= Number				
		,@NameOperator			= NameOperator				
		,@ClientID				= ClientID			
		,@ProgramID			    = ProgramID
		,@Name		            = Name
			
FROM @tmpForWhereClause

DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 

DECLARE @FinalResults_Temp TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 



--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults_Temp
SELECT
CASE
WHEN PP.ID IS NULL THEN P.ID
ELSE PP.ID
END AS Sort
, C.ID AS ClientID
, C.Name AS ClientName
, PP.ID AS ParentProgramID
, PP.Name AS ParentName
, P.ID AS ProgramID
, P.Code AS ProgramCode
, P.Name AS ProgramName
, P.Description AS ProgramDescription
, P.IsActive AS ProgramIsActive
, P.IsAudited AS IsAudited
, P.IsClosedLoopAutomated AS IsClosedLoopAutomated
, P.IsGroup AS IsGroup
--, *
FROM Program P (NOLOCK)
JOIN Client C (NOLOCK) ON C.ID = P.ClientID
LEFT JOIN Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
WHERE C.Name <> 'ARS'
ORDER BY C.Name, Sort, PP.ID, P.ID

PRINT @NameOperator
PRINT 'nAME:'+@Name
INSERT INTO @FinalResults
SELECT 
	T.Sort,
	T.ClientID,
	T.ClientName,
	T.ParentProgramID,
	T.ParentName,
	T.ProgramID,
	T.ProgramCode,
	T.ProgramName,
	T.ProgramDescription,
	T.ProgramIsActive,
	T.IsAudited,
	T.IsClosedLoopAutomated,
	T.IsGroup
FROM @FinalResults_Temp T
WHERE 
(ISNULL(LEN(@Number),0) = 0 OR (@Number = CONVERT(NVARCHAR(100),T.ProgramID)  ))
AND (ISNULL(@ClientID,0) = 0 OR @ClientID = 0 OR (T.ClientID = @ClientID  ))
AND (ISNULL(@ProgramID,0) = 0 OR @ProgramID = 0 OR (T.ParentProgramID = @ProgramID  ))
AND	(ISNULL(LEN(@Name),0) = 0 OR  (
									(@NameOperator = 'Is equal to' AND @Name = T.ProgramName)
									OR
									(@NameOperator = 'Begins with' AND T.ProgramName LIKE  @Name + '%')
									OR
									(@NameOperator = 'Ends with' AND T.ProgramName LIKE  '%' + @Name)
									OR
									(@NameOperator = 'Contains' AND T.ProgramName LIKE  '%' + @Name + '%')
								))
 ORDER BY 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'ASC'
	 THEN T.Sort END ASC, 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'DESC'
	 THEN T.Sort END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'ASC'
	 THEN T.ParentProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'DESC'
	 THEN T.ParentProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'ASC'
	 THEN T.ParentName END ASC, 
	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'DESC'
	 THEN T.ParentName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'ASC'
	 THEN T.ProgramCode END ASC, 
	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'DESC'
	 THEN T.ProgramCode END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'ASC'
	 THEN T.ProgramDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'DESC'
	 THEN T.ProgramDescription END DESC ,

	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'ASC'
	 THEN T.ProgramIsActive END ASC, 
	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'DESC'
	 THEN T.ProgramIsActive END DESC ,

	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'ASC'
	 THEN T.IsAudited END ASC, 
	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'DESC'
	 THEN T.IsAudited END DESC ,

	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'ASC'
	 THEN T.IsClosedLoopAutomated END ASC, 
	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'DESC'
	 THEN T.IsClosedLoopAutomated END DESC ,

	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'ASC'
	 THEN T.IsGroup END ASC, 
	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'DESC'
	 THEN T.IsGroup END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM @FinalResults
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

SELECT @count AS TotalRows, * FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Users_Or_Roles_For_Notification_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Users_Or_Roles_For_Notification_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dms_Users_Or_Roles_For_Notification_Get] 2
 CREATE PROCEDURE [dbo].[dms_Users_Or_Roles_For_Notification_Get](
 @recipientTypeID INT = NULL
 )
 AS
 BEGIN
 DECLARE @ApplicationID UNIQUEIDENTIFIER
 SET @ApplicationID = (SELECT ApplicationId FROM aspnet_Applications where ApplicationName='DMS')
 
	 IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	 BEGIN
	 
		;WITH wUsers
		AS
		(
			SELECT	U.UserId AS ID,
					U.UserName AS Name,
					[dbo].[fnIsUserConnected](U.UserName) AS IsConnected
			FROM aspnet_Users U WITH (NOLOCK)
			WHERE U.ApplicationId = @ApplicationID		
		)
		
		SELECT	W.ID,
				W.Name
		FROM	wUsers W 
		WHERE	W.IsConnected = 1
	 
	 END
	 ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role') )
	 BEGIN
		
		SELECT	R.RoleId AS ID,
				R.RoleName AS Name		
		FROM	aspnet_Roles R WITH (NOLOCK)
		WHERE	R.ApplicationId = @ApplicationID
		 
	 END
 END
GO
