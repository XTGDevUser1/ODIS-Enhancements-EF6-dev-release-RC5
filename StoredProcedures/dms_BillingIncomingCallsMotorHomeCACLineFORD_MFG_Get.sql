IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get] 
 END 
 GO 
CREATE PROCEDURE [dbo].[dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	09/01/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where ClientID = 14
exec dbo.dms_BillingIncomingCallsMotorHomeCACLineFORD_MFG_Get @ProgramIDs, '12/01/2016', '12/31/2016', '1=1'

-- Queries to help in testing
select	*
from	dbo.vw_BillingPhoneCallMetricsIncomingCalls with (nolock)
where	ProgramID in (select ID from dbo.Program where ClientID = 14)
and		convert(date, startdatetimeADJ) >= '06/01/2013'
and		convert(date, startdatetimeADJ) <= '06/30/2013'

**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@RangeBeginDate as nvarchar(20),
		@RangeEndDate as nvarchar(20),
		@SQLString as nvarchar(max)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''
select	@RangeBeginDate = convert(nvarchar(20), @pRangeBeginDate, 101),
		@RangeEndDate = convert(nvarchar(20), @pRangeEndDate, 101)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get ProgramIDs from Programs Table variable
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if object_id('tempdb..#tmpPrograms', 'U') is not null drop table #tmpPrograms
create table #tmpPrograms
(ProgramID	int)
create unique clustered index inx_tmpPrograms1 on #tmpPrograms(ProgramID)
insert into #tmpPrograms
(ProgramID)
select	ProgramID 
from	@pProgramIDs


if @Debug = 1
begin

	select	* from #tmpPrograms
	
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- THIS IS THE SQL THAT DEFINES THE EVENT!
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Build temp
if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
select * into #tmpViewData from dbo.vw_BillingPhoneCallMetricsIncomingCalls where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingPhoneCallMetricsIncomingCalls v '
select	@SQLString = @SQLString + 'join #tmpPrograms pr on pr.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + ' and client = ''FORD'' ' -- FORD Client
select	@SQLString = @SQLString + ' and subclient = ''Motor Home CAC'' ' -- Sub Client  Motor Home CAC only
select	@SQLString = @SQLString + ' and origcallednumber in (''2164'', ''2220'', ''2170'') ' -- Line #
select	@SQLString = @SQLString + ' and convert(date, v.startdatetimeADJ) >= ''' + @RangeBeginDate + ''' ' -- Within the Range given
select	@SQLString = @SQLString + ' and convert(date, v.startdatetimeADJ) <= ''' + @RangeEndDate + ''' ' -- Within the Range given


-- Add additional Criteria
if @pEventFilter is not null
begin

	select	@SQLString = @SQLString + 'and ' + @pEventFilter

end


if @Debug = 1
begin

	select	'Programs', * from @pProgramIDs
	select	@pEventFilter as pEventFilter,
			@SQLString as SQLString
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Execute SQL String to shove data into temp
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exec(@SQLString)


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get results columns for detail
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		EntityID, -- EntityID
		EntityKey, -- EntityKey
		startdatetime as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData
GO

