/****** Object:  StoredProcedure [dbo].[dms_BillingActiveMembersAtPreviousYearEnd_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingActiveMembersAtPreviousYearEnd_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingActiveMembersAtPreviousYearEnd_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingActiveMembersAtPreviousYearEnd_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingActiveMembersAtPreviousYearEnd_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	08/30/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- HRZCARD for testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where code = 'HRZCARD'
exec dbo.dms_BillingActiveMembersAtPreviousYearEnd_Get @ProgramIDs, '04/01/2013', '04/30/2013', '1=1'

-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where clientid = 14
exec dbo.dms_BillingActiveMembersAtPreviousYearEnd_Get @ProgramIDs, '06/01/2013', '06/30/2013', 'VINModelYear=''2012'''

-- FORD for Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where Code = 'FORDESP_MFG'
exec dbo.dms_BillingActiveMembersAtPreviousYearEnd_Get @ProgramIDs, '04/01/2013', '04/30/2013', '1=1'


-- Queries to help in testing
select	mbr.*
from	Member mbr
join	Program pr on pr.ID = mbr.ProgramID
where	pr.Code = 'HRZCARD'
order by
		mbr.ExpirationDate desc



**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@SQLString as nvarchar(max),
		@RangeBeginDate_CHAR as nvarchar(20),
		@RangeEndDate_CHAR as nvarchar(20),
		@PreviousYearEndDate_CHAR as nvarchar(20)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''
select	@RangeBeginDate_CHAR = convert(nvarchar(20), @pRangeBeginDate),
		@RangeEndDate_CHAR = convert(nvarchar(20), @pRangeEndDate)

select	@PreviousYearEndDate_CHAR = '12/31/' + convert(nchar(4), year(@pRangeEndDate) - 1)


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

	select	@PreviousYearEndDate_CHAR as PreviousYearEndDate_CHAR
	select	convert(nvarchar(20), @pRangeEndDate, 101) as BillingMonth
	select	* from #tmpPrograms
	
end


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- THIS IS THE SQL THAT DEFINES THE EVENT!
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- Build temp
if object_id('tempdb..#tmpViewData', 'U') is not null drop table #tmpViewData
select * into #tmpViewData from dbo.vw_BillingMembers where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingMembers v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + ' and convert(date, v.DMSMemberCreateDate) < = ''' + @PreviousYearEndDate_CHAR + ''' ' -- Created before the CutOffDate
select	@SQLString = @SQLString + ' and v.ExpirationDate > ''' + @PreviousYearEndDate_CHAR + ''' ' -- Expiration Date in the Future
select	@SQLString = @SQLString + ' and isnull(v.EndDate, ''12/31/2099'') >= '' ' + @PreviousYearEndDate_CHAR + '''' -- End Date from Mbr Count table after in the Future


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
-- Get results columns for Detail
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	distinct
		ProgramID,
		EntityID,
		EntityKey,
		ExpirationDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpViewData
GO
