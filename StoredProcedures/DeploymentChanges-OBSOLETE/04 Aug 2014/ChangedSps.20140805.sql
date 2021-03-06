/****** Object:  StoredProcedure [dbo].[dms_BillingClaimsProcessed_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingClaimsProcessed_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingClaimsProcessed_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingClaimsProcessed_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingClaimsProcessed_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	09/13/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**

-- For Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'FORDESP_MFG')
exec dbo.dms_BillingClaimsProcessed_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
select	distinct ProgramID 
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
select * into #tmpViewData from dbo.vw_BillingClaims where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingClaims v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
--select	@SQLString = @SQLString + ' and v.ReceivedDate>= ''' + @RangeBeginDate + ''' '
select	@SQLString = @SQLString + ' and v.ReceivedDate<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and v.FeeAccountingInvoiceBatchID is null ' -- Not Invoiced

 
-- Add additional Criteria
if @pEventFilter is not null
begin

	select	@SQLString = @SQLString + 'and ' + @pEventFilter

end


if @Debug = 1
begin

	select	'Programs', * from @pProgramIDs
	select	@pRangeBeginDate as pRangeBeginDate,
			@pRangeEndDate as pRangeEndDate,
			@RangeBeginDate as RangeBeginDate,
			@RangeEndDate as RangeEndDate,
			@pEventFilter as pEventFilter,
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
		EntityID,
		EntityKey,
		ReceivedDate as EntityDate,
		cast(1 as int)as BaseQuantity,
		PaymentAmount as BaseAmount,
		cast(null as float) as BasePercentage,
		null as ServiceCode,
		null as BillingCode
from	#tmpViewData
GO


GO

/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramDataItemsForProgram]    Script Date: 11/02/2012 13:23:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fnc_GetProgramDataItemsForProgram] (@ProgramID int, @ScreenName nvarchar(50))
RETURNS @ProgramDataItemsForProgramByScreen TABLE
   (
    ProgramDataItemID     int
   )
AS
BEGIN
  	--Get all program data items starting at child level and working up the parent hierarchy
 
		--;WITH wProgramDataItems
		--AS
		--(
		--	SELECT DISTINCT PDI.ID AS [ProgramDataItemID],
		--    PDI.ProgramID,
		--    PDI.Name,
		--    P.ParentProgramID,
		--	0 as Iteration,
		--    PDI.Sequence 
		--	FROM ProgramDataItem PDI
		--	JOIN Program P ON P.ID = PDI.ProgramID 
		--	WHERE ProgramID = 
		--	(SELECT TOP 1 PDI.ProgramID 
		--							FROM ProgramDataItem PDI
		--							JOIN fnc_GetProgramsandParents(@ProgramID) fnc ON fnc.ProgramID = PDI.ProgramID
		--							ORDER BY fnc.Sequence)
		--	AND ScreenName = @ScreenName 
		--	AND PDI.IsActive = 1
			
		--	UNION ALL
			
		--	SELECT PDI.ID as [ProgramDataItemID],
		--	PDI.ProgramID,
		--	PDI.Name,
		--	P.ParentProgramID,
		--	wP.Iteration + 1,
		--	PDI.Sequence
		--	FROM ProgramDataItem PDI
		--	JOIN wProgramDataItems wP ON PDI.ProgramID = wP.ParentProgramID  
		--	JOIN Program P ON P.ID = PDI.ProgramID 	
		--	WHERE PDI.ScreenName = @ScreenName AND P.IsActive = 1 AND PDI.IsActive = 1
		--	AND PDI.Name <> wP.Name --Do not get items already defined at previous level
		--)

		;WITH wProgramDataItems
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY PDI.Name ORDER BY PP.Sequence) AS RowNum,
					PDI.ID AS [ProgramDataItemID],
		    PDI.ProgramID,
		    PDI.Name,		    			
		    PP.Sequence 	
			FROM fnc_GetProgramsandParents(@ProgramID) PP
			JOIN ProgramDataItem PDI WITH (NOLOCK) ON PP.ProgramID = PDI.ProgramID
			WHERE	PDI.ScreenName = @screenName 
			AND PDI.IsActive = 1			
		)

		INSERT @ProgramDataItemsForProgramByScreen 
		SELECT ProgramDataItemID from wProgramDataItems p
		ORDER BY Sequence 

RETURN 

END
GO
