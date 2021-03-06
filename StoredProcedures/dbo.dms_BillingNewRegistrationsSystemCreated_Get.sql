/****** Object:  StoredProcedure [dbo].[dms_BillingNewRegistrationsSystemCreated_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingNewRegistrationsSystemCreated_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingNewRegistrationsSystemCreated_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingNewRegistrationsSystemCreated_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingNewRegistrationsSystemCreated_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	07/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- LamBo for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOHPN'
--insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'LAMBOCPO'
exec dbo.dms_BillingNewRegistrationsSystemCreated_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'

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
select *, cast(0 as int) as RowRank into #tmpViewData from dbo.vw_BillingMembers where 1=0

-- Build SQL String for Select
-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select * from '
select	@SQLString = @SQLString + '(select v.*, '
select	@SQLString = @SQLString + 'RANK() OVER (PARTITION BY MembershipNumber ORDER BY DMSMEmberCreateDate, DMSMemberCountsID desc) AS RowRank '
select	@SQLString = @SQLString + 'from dbo.vw_BillingMembers v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + 'and v.DMSMemberCreateDate>= ''' + @RangeBeginDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and v.DMSMemberCreateDate<= ''' + @RangeEndDate + '''' -- Within the Range given
select	@SQLString = @SQLString + 'and IsMbrManuallyCreated = ''0'' ' -- Member Created By the System
select	@SQLString = @SQLString + ') as DTL '
select	@SQLString = @SQLString + 'where 1=1 '

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
select	distinct
		ProgramID,
		EntityID,
		EntityKey,
		DMSMemberCreateDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData
GO
