IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingAdministationFeeFlat_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingAdministationFeeFlat_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROCEDURE [dbo].[dms_BillingAdministationFeeFlat_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingAdministationFeeFlat_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	08/31/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**
-- HRZCARD for testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) select ID from dbo.Program where code = 'HRZCARD'
exec dbo.dms_BillingAdministationFeeFlat_Get @ProgramIDs, '04/01/2013', '04/30/2013', '1=1'


**/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare local variables
declare	@Debug as int,
		@SQLString as nvarchar(max),
		@RangeBeginDate_CHAR as nvarchar(20),
		@RangeEndDate_CHAR as nvarchar(20)


-- Initialize Local Variables
select	@Debug = 0
select	@SQLString = ''


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

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
-- Get an Admin Fee
-- Include: BaseQuantity = 1
--			BaseAmount = null
--			BasePercentage = null	
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		(select ID from dbo.Entity with (nolock) where Name = 'BillingProgram') as EntityID,
		ProgramID as EntityKey,
		@pRangeEndDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpPrograms
GO

