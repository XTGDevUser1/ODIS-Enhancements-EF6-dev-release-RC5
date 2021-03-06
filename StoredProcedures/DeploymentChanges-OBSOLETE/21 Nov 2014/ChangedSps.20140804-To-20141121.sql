/****** Object:  StoredProcedure [dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingClaimsProcessedMotorhomeReimbursement_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingClaimsProcessedMotorhomeReimbursement_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingClaimsProcessedMotorhomeReimbursement_Get]
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
insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where ClientID = 14)
exec dbo.dms_BillingClaimsProcessedMotorhomeReimbursement_Get @ProgramIDs, NULL, '08/30/2014', '1=1'


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
select	@SQLString = @SQLString + ' and v.ClaimTypeID in ' -- RS Reimb
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimType '
select	@SQLString = @SQLString + ' where name = ''MotorhomeReimbursement'') ' 
select	@SQLString = @SQLString + ' and v.ClaimStatusID in ' -- Only bill once the claim reaches a final status
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimStatus '
select	@SQLString = @SQLString + ' where name IN (''Paid'',''Denied'')) ' 

 
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
/****** Object:  StoredProcedure [dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingClaimsProcessedRoadsideReimbursement_Get
 **
 **	Date		Added By	Description
 **	----------	----------	----------------------------------------
 **	11/06/13	MJKrzysiak	Created
 **	
 **
 **********************************************************************/

/**

-- For Testing
declare @ProgramIDs as BillingDefinitionProgramsTableType
insert into @ProgramIDs(ProgramID) (select ID from dbo.Program where Code = 'FORDESP_MFG')
exec dbo.dms_BillingClaimsProcessedRoadsideReimbursement_Get @ProgramIDs, '06/01/2013', '06/30/2013', '1=1'


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
select * into #tmpViewData from dbo.vw_BillingClaims where 1=0

-- Build SQL String for Select
select	@SQLString = @SQLString + 'insert into #tmpViewData '
select	@SQLString = @SQLString + 'select v.* from dbo.vw_BillingClaims v '
select	@SQLString = @SQLString + 'join #tmpPrograms p on p.ProgramID = v.ProgramID '
select	@SQLString = @SQLString + 'where 1=1 '
select	@SQLString = @SQLString + ' and convert(date, v.ReceivedDate)<= ''' + @RangeEndDate + ''' '
select	@SQLString = @SQLString + ' and v.FeeAccountingInvoiceBatchID is null ' -- Not Invoiced
select	@SQLString = @SQLString + ' and v.ClaimTypeID in ' -- RS Reimb
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimType '
select	@SQLString = @SQLString + ' where name = ''RoadsideReimbursement'') ' 
select	@SQLString = @SQLString + ' and v.ClaimStatusID in ' -- Only bill once the claim reaches a final status
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimStatus '
select	@SQLString = @SQLString + ' where name IN (''Paid'',''Denied'')) ' 

 
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
select	@SQLString = @SQLString + ' and v.ClaimStatusID in ' -- Only bill once the claim reaches a final status
select	@SQLString = @SQLString + ' (select ID from dbo.ClaimStatus '
select	@SQLString = @SQLString + ' where name IN (''Paid'',''Denied'')) ' 

 
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
/****** Object:  StoredProcedure [dbo].[dms_BillingFixedAmountQuantityAndRate_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_BillingFixedAmountQuantityAndRate_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingFixedAmountQuantityAndRate_Get] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_BillingFixedAmountQuantityAndRate_Get]
@pProgramIDs as BillingDefinitionProgramsTableType READONLY,
@pRangeBeginDate as datetime,
@pRangeEndDate as datetime,
@pEventFilter as nvarchar(2000)=null
as
/********************************************************************
 **
 **	dms_BillingFixedAmountQuantityAndRate_Get
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
exec dbo.dms_BillingFixedAmountQuantityAndRate_Get @ProgramIDs, '04/01/2013', '04/30/2013', '1=1'


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
-- Fixed Amount
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
select	ProgramID,
		(select ID from dbo.Entity with (nolock) where Name = 'BillingProgram') as EntityID,
		 ProgramID as EntityKey,
		@pRangeEndDate as EntityDate,
		cast(null as int)as BaseQuantity,
		cast(null as float) as BaseAmount,
		cast(null as float) as BasePercentage,
		cast(null as nvarchar(50)) as ServiceCode,
		cast(null as nvarchar(50)) as BillingCode
from	#tmpPrograms

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
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetDefaultProductRatesByMarketLocation]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetDefaultProductRatesByMarketLocation]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO 

-- =============================================
-- Description:	Returns default product rates by location
-- =============================================
CREATE FUNCTION [dbo].[fnGetDefaultProductRatesByMarketLocation] 
(
	@ServiceLocationGeography geography
	,@ServiceCountryCode nvarchar(50)
	,@ServiceStateProvince nvarchar(50)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT prt.ProductID, prt.RateTypeID, rt.Name
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN MetroRate.RatePrice * 1.10
			WHEN StateRate.RatePrice IS NOT NULL THEN StateRate.RatePrice * 1.10
			ELSE ISNULL(GlobalDefaultRate.RatePrice,0)
			END AS RatePrice
		,CASE WHEN MetroRate.RatePrice IS NOT NULL THEN ISNULL(MetroRate.RateQuantity,0)
			WHEN StateRate.RatePrice IS NOT NULL THEN ISNULL(StateRate.RateQuantity,0)
			ELSE ISNULL(GlobalDefaultRate.RateQuantity ,0)
			END AS RateQuantity
	FROM ProductRateType prt
	JOIN RateType rt on rt.ID = prt.RateTypeID
	Left Outer Join (
		Select mlpr1.ProductID, mlpr1.RateTypeID, mlpr1.Price AS RatePrice, mlpr1.Quantity AS RateQuantity
		From dbo.MarketLocation ml1
		Left Outer Join dbo.MarketLocationProductRate mlpr1 On ml1.ID = mlpr1.MarketLocationID 
		--Left Outer Join dbo.RateType rt1 On cpr1.RateTypeID = rt1.ID
		Where ml1.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'GlobalDefault')
		) GlobalDefaultRate
		ON GlobalDefaultRate.ProductID = prt.ProductID AND GlobalDefaultRate.RateTypeID = prt.RateTypeID
	Left Outer Join (
		Select mlpr2.ProductID, mlpr2.RateTypeID, mlpr2.Price RatePrice, mlpr2.Quantity RateQuantity
		From dbo.MarketLocation ml2
		Left Outer Join dbo.MarketLocationProductRate mlpr2 On ml2.ID = mlpr2.MarketLocationID 
		--Left Outer Join dbo.RateType rt2 On cpr2.RateTypeID = rt2.ID
		Where ml2.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'Metro')
			And ml2.IsActive = 'TRUE'
			and ml2.GeographyLocation.STDistance(@ServiceLocationGeography) <= ml2.RadiusMiles * 1609.344
			-- TP: Added condition below to use the closest metro area if within the radius of more than one
			and ml2.GeographyLocation.STDistance(@ServiceLocationGeography) =
				(SELECT MIN(GeographyLocation.STDistance(@ServiceLocationGeography))
				 FROM dbo.MarketLocation)

		) MetroRate 
		ON MetroRate.ProductID = prt.ProductID AND MetroRate.RateTypeID = prt.RateTypeID
	Left Outer Join
		(
		Select mlpr3.ProductID,mlpr3.RateTypeID, mlpr3.Price RatePrice, mlpr3.Quantity RateQuantity
		From dbo.MarketLocation ml3
		Left Outer Join dbo.MarketLocationProductRate mlpr3 On ml3.ID = mlpr3.MarketLocationID 
		--Left Outer Join dbo.RateType rt3 On cpr3.RateTypeID = rt3.ID
		Where ml3.MarketLocationTypeID = (Select ID From MarketLocationType Where Name = 'State')
		And ml3.IsActive = 'TRUE'
		And ml3.Name = (@ServiceCountryCode + N'_' + @ServiceStateProvince)
		) StateRate 
		ON StateRate.ProductID = prt.ProductID AND StateRate.RateTypeID = prt.RateTypeID
	WHERE 
	prt.IsOptional = 'FALSE'
	AND rt.Name NOT IN ('EnrouteFree','ServiceFree')
)

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

WhereClauseXML : 

'<ROW><Filter 
CheckNumber=""
CheckDateFrom=""
CheckDateTo=""
AmountFrom=""
AmountTo=""
CreateBy=""
CreateDateFrom=""
CreateDateTo=""
 ></Filter></ROW>'
 
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ACES_Payment_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ACES_Payment_List_Get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_ACES_Payment_List_Get
 CREATE PROCEDURE [dbo].[dms_ACES_Payment_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'RecievedDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
CheckNumber NVARCHAR(100) NULL,
CheckDateFrom DATETIME NULL,
CheckDateTo DATETIME NULL,
AmountFrom MONEY NULL,
AmountTo MONEY NULL,
CreateBy NVARCHAR(50) NULL,
CreateDateFrom DATETIME NULL,
CreateDateTo DATETIME NULL
)

 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PaymentType nvarchar(100)  NULL ,
	CheckNumber nvarchar(100)  NULL ,
	CheckDate datetime  NULL ,
	TotalAmount money  NULL ,
	RecievedDate datetime  NULL ,
	Comment nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	CreateDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL,
	PaymentBalance money NULL
) 



INSERT INTO #tmpForWhereClause
SELECT  
	T.c.value('@CheckNumber','NVARCHAR(50)'),
	T.c.value('@CheckDateFrom','DATETIME') ,
	T.c.value('@CheckDateTo','DATETIME'),
	T.c.value('@AmountFrom','MONEY') ,
	T.c.value('@AmountTo','MONEY'),
	T.c.value('@CreateBy','NVARCHAR(50)') ,
	T.c.value('@CreateDateFrom','DATETIME'),
	T.c.value('@CreateDateTo','DATETIME')	
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT		CP.ID
			,PT.Name AS PaymentType
			, CP.CheckNumber
			, CP.CheckDate  
			, CP.TotalAmount 
			, CP.RecievedDate
			, CP.Comment
			, CP.CreateBy
			, CP.CreateDate
			, CP.ModifyBy
			, CP.ModifyDate
			,(SELECT TOP 1 PaymentBalance FROM Client WITH(NOLOCK) WHERE Name='Ford') PaymentBalance
FROM		ClientPayment CP WITH(NOLOCK)
LEFT JOIN	PaymentType PT WITH(NOLOCK) ON PT.ID = CP.PaymentTypeID
LEFT JOIN	#tmpForWhereClause T ON 1=1
WHERE	CP.IsActive=1
AND		( T.AmountFrom IS NULL OR CP.TotalAmount >= T.AmountFrom)
AND		(T.AmountTo IS NULL OR CP.TotalAmount <= T.AmountTo)
AND		(LEN(ISNULL(T.CheckNumber,'')) = 0 OR CP.CheckNumber = T.CheckNumber)
AND		(T.CheckDateFrom IS NULL OR CP.CheckDate >= T.CheckDateFrom)
AND		(T.CheckDateTo IS NULL OR CP.CheckDate <= DATEADD(DD,1,T.CheckDateTo))
AND		(LEN(ISNULL(T.CreateBy,'')) = 0 OR CP.CreateBy = T.CreateBy)
AND		(T.CreateDateFrom IS NULL OR CP.CreateDate >= T.CreateDateFrom)
AND		(T.CreateDateTo IS NULL OR CP.CreateDate <= DATEADD(DD,1,T.CreateDateTo))		 
ORDER BY
	CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'
    THEN PT.Name END ASC, 
    CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'
    THEN PT.Name END DESC ,

	CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'ASC'
    THEN CP.CheckNumber END ASC, 
    CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'DESC'
    THEN CP.CheckNumber END DESC ,

	CASE WHEN @sortColumn = 'CheckDate' AND @sortOrder = 'ASC'
    THEN CP.CheckDate END ASC, 
    CASE WHEN @sortColumn = 'CheckDate' AND @sortOrder = 'DESC'
    THEN CP.CheckDate END DESC ,

	CASE WHEN @sortColumn = 'TotalAmountRequired' AND @sortOrder = 'ASC'
    THEN CP.TotalAmount END ASC, 
    CASE WHEN @sortColumn = 'TotalAmountRequired' AND @sortOrder = 'DESC'
    THEN CP.TotalAmount END DESC ,

	CASE WHEN @sortColumn = 'RecievedDate' AND @sortOrder = 'ASC'
    THEN CP.RecievedDate END ASC, 
    CASE WHEN @sortColumn = 'RecievedDate' AND @sortOrder = 'DESC'
    THEN CP.RecievedDate END DESC ,

	CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'ASC'
    THEN CP.Comment END ASC, 
    CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'DESC'
    THEN CP.Comment END DESC ,

	CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
    THEN CP.CreateBy END ASC, 
    CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
    THEN CP.CreateBy END DESC ,

	CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
    THEN CP.CreateDate END ASC, 
    CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
    THEN CP.CreateDate END DESC 



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
  @BillingCode_DetailExceptionType_AMT_OVER_$100 as int,  
  @BillingCode_DetailExceptionType_GOA as int,  
  
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
set @BillingCode_DetailExceptionType_AMT_OVER_$100 = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'AMT_OVER_$100')  
set @BillingCode_DetailExceptionType_GOA = (select ID from dbo.BillingInvoiceDetailExceptionType where Name = 'GOA')  
  
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
  ---------------- No MembershipNumber : ALL but Atwood, PDG, PCG/TravelGuard ----------------  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : SR Entity  
   and srv.EntityID_ServiceRequest = @BillingCode_EntityID_SR -- SR Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in ('Atwood', 'Professional Dispatch Group', 
					'Travel Guard', 'SeaTow'))
   and srv.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in ('Atwood', 'Professional Dispatch Group', 
					'Travel Guard', 'SeaTow'))
   and pov.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in ('Atwood', 'Professional Dispatch Group', 
					'Travel Guard', 'SeaTow'))
   and viv.MembershipNumber is not null) -- Now has MembershipNumber  
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_NO_MBRSHP_NUM -- No MembershipNumber Exception : CL Entity  
   and clv.EntityID = @BillingCode_EntityID_CL -- CL Entity  
   and cl.ID in (select ID from Client with (nolock) where Name not in ('Atwood', 'Professional Dispatch Group', 
					'Travel Guard', 'SeaTow'))
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
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100 --  Amount Over $100 Exception : PO Entity  
   and pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO -- PO Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
   and isnull(pov.PurchaseOrderAmount, 0) <= 200) -- Now $200 or less
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100 --  Amount Over $100 Exception : VI Entity  
   and viv.EntityID = @BillingCode_EntityID_VI -- VI Entity  
   and cl.ID in (select ID from Client with (nolock) where Name = 'Ford')  
   and pr.ID in (select ID from Program with (nolock) where Code = 'FORDESP_MFG')     
--   and isnull(viv.PurchaseOrderAmount, 0) <= 200) -- Now $200 or less
   and isnull(viv.PaymentAmount, 0) <= 200) -- Now $200 or less  ^1 Changed to PaymentAmount
  or  
  (bidx.InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100 --  Amount Over $100 Excpetion : CL Entity  
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
and		cl.ID in (select ID from Client with (nolock) where Name not in ('Atwood', 'Professional Dispatch Group', 
				'Travel Guard', 'SeaTow'))
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
  @BillingCode_DetailExceptionType_AMT_OVER_$100, -- InvoiceDetailExceptionTypeID  
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
   (pov.EntityID_PurchaseOrder = @BillingCode_EntityID_PO and isnull(pov.PurchaseOrderAmount, 0) > 100)  
   or  
--   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.PurchaseOrderAmount, 0) > 100)  
   (viv.EntityID = @BillingCode_EntityID_VI and isnull(viv.PaymentAmount, 0) > 100)  -- ^1 Changed to PaymentAmount
   or  
   (clv.EntityID = @BillingCode_EntityID_CL and isnull(clv.PaymentAmount, 0) > 100)  
  )  
and  not exists     -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_AMT_OVER_$100)  
  
  
------------------------------------  
-- GOA : ALL  
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
and  not exists   
  -- Exclude those that already have an Exception of this type  
  (select 1  
   from BillingInvoiceDetailException bidx  
   where bidx.BillingInvoiceDetailID = bid.ID  
   and InvoiceDetailExceptionTypeID = @BillingCode_DetailExceptionType_GOA)  
  
  
  
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
 WHERE id = object_id(N'[dbo].[dms_BillingManageInvoicesList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_BillingManageInvoicesList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_BillingManageInvoicesList @pMode= 'OPEN',@pageSize=12
 CREATE PROCEDURE [dbo].[dms_BillingManageInvoicesList](   
   @whereClauseXML XML = NULL 
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 1   
 , @sortColumn nvarchar(100)  = 'ID'   
 , @sortOrder nvarchar(100) = 'DESC'   
 , @pMode nvarchar(50)='OPEN'
 )   
 AS   
 BEGIN     
 SET FMTONLY OFF;    
  SET NOCOUNT ON    
 
 DECLARE @tmpForWhereClause TABLE
(
ScheduleDateFrom DATETIME NULL,
ScheduleDateTo DATETIME NULL,
ClientID INT NULL,
BillingDefinitionInvoiceID INT NULL,
LineStatuses NVARCHAR(MAX) NULL,
InvoiceStatuses NVARCHAR(MAX) NULL,
BillingDefinitionInvoiceLines NVARCHAR(MAX) NULL
)
 
  CREATE TABLE #tmpFinalResults(     
     [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
     ID INT NULL,    
       
     InvoiceDescription nvarchar(255) NULL,    
     BillingScheduleID int NULL,    
     BillingSchedule nvarchar(50) NULL,    
     BillingScheduleTypeID nvarchar(50) NULL,    
     BillingScheduleType nvarchar(50) NULL,    
     ScheduleDate DATETIME NULL,    
     ScheduleRangeBegin DATETIME NULL,    
     ScheduleRangeEnd DATETIME NULL,    
     InvoiceNumber nvarchar(7) NULL,    
     InvoiceDate DATETIME NULL,    
     InvoiceStatusID int NULL,    
     InvoiceStatus nvarchar(50) NULL,  
     TotalDetailCount int NULL,    
     TotalDetailAmount money NULL,    
     ReadyToBillCount int NULL,    
     ReadyToBillAmount money NULL,    
     PendingCount int NULL,    
     PendingAmount money NULL,         
     ExcludedCount int NULL,    
     ExceptionAmount money NULL,         
     ExceptionCount int NULL,    
     ExcludedAmount money NULL,         
     OnHoldCount int NULL,    
     OnHoldAmount money NULL,         
     PostedCount int NULL,    
     PostedAmount money NULL,    
     BillingDefinitionInvoiceID int NULL,    
     ClientID int NULL,    
     InvoiceName nvarchar(50) NULL,    
     PONumber nvarchar(100) NULL,    
     AccountingSystemCustomerNumber nvarchar(7) NULL,    
     ClientName nvarchar(50) NULL,  
     CanAddLines BIT NULL  ,  
     BilingScheduleStatus nvarchar(100) NULL ,  
     ScheduleDateTypeID  INT NULL,  
     ScheduleRangeTypeID INT NULL  ,
     AccountingSystemAddressCode NVARCHAR(100) NULL
  )    
      
  CREATE TABLE #FinalResults(     
     [RowNum] [bigint] NOT NULL IDENTITY(1,1),    
     ID INT NULL,    
     InvoiceDescription nvarchar(255) NULL,    
     BillingScheduleID int NULL,    
     BillingSchedule nvarchar(50) NULL,    
     BillingScheduleTypeID nvarchar(50) NULL,    
     BillingScheduleType nvarchar(50) NULL,    
     ScheduleDate DATETIME NULL,    
     ScheduleRangeBegin DATETIME NULL,    
     ScheduleRangeEnd DATETIME NULL,    
     InvoiceNumber nvarchar(7) NULL,    
     InvoiceDate DATETIME NULL,    
     InvoiceStatusID int NULL,    
     InvoiceStatus nvarchar(50) NULL,  
     TotalDetailCount int NULL,    
     TotalDetailAmount money NULL,    
     ReadyToBillCount int NULL,    
     ReadyToBillAmount money NULL,    
     PendingCount int NULL,    
     PendingAmount money NULL,         
     ExcludedCount int NULL,    
     ExceptionAmount money NULL,         
     ExceptionCount int NULL,    
     ExcludedAmount money NULL,         
     OnHoldCount int NULL,    
     OnHoldAmount money NULL,         
     PostedCount int NULL,    
     PostedAmount money NULL,    
     BillingDefinitionInvoiceID int NULL,    
     ClientID int NULL,    
     InvoiceName nvarchar(50) NULL,    
     PONumber nvarchar(100) NULL,    
     AccountingSystemCustomerNumber nvarchar(7) NULL,    
     ClientName nvarchar(50) NULL,  
     CanAddLines BIT NULL   ,  
     BilingScheduleStatus nvarchar(100) NULL ,  
     ScheduleDateTypeID  INT NULL,  
     ScheduleRangeTypeID INT NULL  ,
     AccountingSystemAddressCode NVARCHAR(100) NULL
  )    

INSERT INTO @tmpForWhereClause
SELECT  
		T.c.value('@ScheduleDateFrom','datetime'),
		T.c.value('@ScheduleDateTo','datetime'),
		T.c.value('@ClientID','int') ,
		T.c.value('@BillingDefinitionInvoiceID','int') ,
		T.c.value('@LineStatuses','NVARCHAR(MAX)'),
		T.c.value('@InvoiceStatuses','NVARCHAR(MAX)'), 
		T.c.value('@BillingDefinitionInvoiceLines','NVARCHAR(MAX)') 
				
		
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @ScheduleDateFrom DATETIME ,
@ScheduleDateTo DATETIME ,
@ClientID INT ,
@BillingDefinitionInvoiceID INT ,
@LineStatuses NVARCHAR(MAX) ,
@InvoiceStatuses NVARCHAR(MAX),
@BillingDefinitionInvoiceLines NVARCHAR(MAX)

SELECT	@ScheduleDateFrom = T.ScheduleDateFrom ,
		@ScheduleDateTo = T.ScheduleDateTo,
		@ClientID = T.ClientID ,
		@BillingDefinitionInvoiceID = T.BillingDefinitionInvoiceID ,
		@LineStatuses = T.LineStatuses ,
		@InvoiceStatuses = T.InvoiceStatuses,
		@BillingDefinitionInvoiceLines = T.BillingDefinitionInvoiceLines
FROM	@tmpForWhereClause T

  INSERT INTO #tmpFinalResults    
  SELECT  DISTINCT   
 BI.ID,    
 BI.[Description],    
 BI.BillingScheduleID,    
    BS.Name,    
    BS.ScheduleTypeID,    
    BST.Name,    
    BI.ScheduleDate,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleDate, 1),''),    
    BI.ScheduleRangeBegin,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeBegin, 1),''),    
    BI.ScheduleRangeEnd,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeEnd, 1),''),    
    BI.InvoiceNumber,    
    BI.InvoiceDate,--ISNULL(CONVERT(VARCHAR(10), BI.InvoiceDate, 1),''),    
    BI.InvoiceStatusID,    
    BIS.Name,    
    DTLData.TotalDetailCount,  
 DTLData.TotalDetailAmount,    
 DTLData.ReadyToBillCount,  
 DTLData.ReadyToBillAmount,  
 DTLData.PendingCount,  
 DTLData.PendingAmount,  
 DTLData.ExceptionCount,  
 DTLData.ExceptionAmount,  
 DTLData.ExcludedCount,  
 DTLData.ExcludedAmount,  
 DTLData.OnHoldCount,  
 DTLData.OnHoldAmount,    
 DTLData.PostedCount,  
 DTLData.PostedAmount,  
    BI.BillingDefinitionInvoiceID,    
    BI.ClientID,    
    BI.Name,    
    isnull(bi.POPrefix, '') + isnull(bi.PONumber, '') as PONumber,  
    BI.AccountingSystemCustomerNumber,    
    cl.Name ,  
    bi.CanAddLines,  
    bss.Name AS BilingScheduleStatus ,  
    bdi.ScheduleDateTypeID,  
    bdi.ScheduleRangeTypeID  ,
    bi.AccountingSystemAddressCode
  from BillingInvoice bi with (nolock)  
left outer join BillingDefinitionInvoice bdi with(nolock) on bdi.ID=bi.BillingDefinitionInvoiceID  
left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID 
left outer join BillingDefinitionInvoiceLine bdil with(nolock) on bdil.BillingDefinitionInvoiceID = bdi.ID 
left outer join BillingSchedule bs with (nolock) on bs.ID = bi.BillingScheduleID  
left outer join Client cl with (nolock) on cl.ID = bi.ClientID  
left outer join Product pr with (nolock) on pr.ID = bil.ProductID  
left outer join RateType rt with (nolock) on rt.ID = bil.RateTypeID  
left outer join BillingInvoiceStatus bis with (nolock) on bis.ID = bi.InvoiceStatusID  
left outer join BillingInvoiceLineStatus bils with (nolock) on bils.ID = bil.InvoiceLineStatusID  
left outer join BillingScheduleType bst with (nolock) on bst.ID = bs.ScheduleTypeID  
left outer join dbo.BillingScheduleStatus bss with (nolock) on bss.ID = bs.ScheduleStatusID  
 --and  bss.Name = @pMode  
left outer join (select bi.ID as InvoiceID,  
    --bil.ID as InvoiceLineID,  
    -- Total  
    isnull(sum(case  
      when bids.Name <> 'DELETED' then 1  
      else 0  
     end), 0) as TotalDetailCount,  
    isnull(sum(case  
      when bids.Name <> 'DELETED' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0  
     end), 0) as TotalDetailAmount,  
    -- READY  
    isnull(sum(case  
      when bids.Name = 'READY' then 1  
      else 0  
     end), 0) as ReadyToBillCount,  
    isnull(sum(case  
      when bids.Name = 'READY' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as ReadyToBillAmount,  
    -- PENDING  
    isnull(sum(case  
      when bids.Name = 'PENDING' then 1  
      else 0  
     end), 0) as PendingCount,  
    isnull(sum(case  
      when bids.Name = 'PENDING' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as PendingAmount,  
    -- EXCEPTION  
    isnull(sum(case  
      when bids.Name = 'EXCEPTION' then 1  
      else 0  
     end), 0) as ExceptionCount,  
    isnull(sum(case  
      when bids.Name = 'EXCEPTION' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as ExceptionAmount,  
    -- EXCLUDED  
    isnull(sum(case  
      when bids.Name = 'EXCLUDED' then 1  
      else 0  
     end), 0) as ExcludedCount,  
    isnull(sum(case  
      when bids.Name = 'EXCLUDED' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as ExcludedAmount,  
    -- ONHOLD  
    isnull(sum(case  
      when bids.Name = 'ONHOLD' then 1  
      else 0  
     end), 0) as OnHoldCount,  
    isnull(sum(case  
      when bids.Name = 'ONHOLD' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as OnHoldAmount,  
    -- POSTED  
    isnull(sum(case  
      when bids.Name = 'POSTED' then 1  
      else 0  
     end), 0) as PostedCount,  
    isnull(sum(case  
      when bids.Name = 'POSTED' then -- COALESCE(bid.AdjustmentAmount, bid.EventAmount)  
			CASE WHEN ISNULL(bid.IsAdjusted,0) = 1 THEN bid.AdjustmentAmount ELSE bid.EventAmount END
      else 0.00  
     end), 0.00) as PostedAmount  
  from BillingInvoice bi with (nolock)  
  left outer join BillingInvoiceLine bil with (nolock) on bil.BillingInvoiceID = bi.ID  
  left outer join BillingInvoiceDetail bid with (nolock) on bid.BillingInvoiceLineID = bil.ID  
  left outer join BillingInvoiceDetailStatus bids with (nolock) on bids.ID = bid.InvoiceDetailStatusID  
 
   group by  
    bi.ID  
    --bil.ID  
   ) as DTLData on DTLData.InvoiceID = bi.ID  
      --and DTLData.InvoiceLineID = bil.ID  
where (@pMode IS NULL OR bss.Name = @pMode)
AND	(@ScheduleDateFrom IS NULL OR bs.ScheduleDate >= @ScheduleDateFrom )
AND	(@ScheduleDateTo IS NULL OR bs.ScheduleDate < DATEADD(DD,1,@ScheduleDateTo) )
AND	(@ClientID IS NULL OR @ClientID = cl.ID)
AND	(@BillingDefinitionInvoiceID IS NULL OR @BillingDefinitionInvoiceID = bdi.ID)
--AND	(@LineStatuses IS NULL )--OR bids.ID IN (SELECT item FROM fnSplitString(@LineStatuses,',') ))
AND	(@InvoiceStatuses IS NULL OR bis.ID IN (SELECT item FROM fnSplitString(@InvoiceStatuses,',') ))
AND	(@BillingDefinitionInvoiceLines IS NULL OR bdil.ID IN (SELECT item FROM fnSplitString(@BillingDefinitionInvoiceLines,',') ))
order by  
  BI.ID,    
 BI.[Description],    
 BI.BillingScheduleID,    
    BS.Name,    
    BS.ScheduleTypeID,    
    BST.Name,    
    BI.ScheduleDate,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleDate, 1),''),    
    BI.ScheduleRangeBegin,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeBegin, 1),''),    
    BI.ScheduleRangeEnd,--ISNULL(CONVERT(VARCHAR(10), BI.ScheduleRangeEnd, 1),''),    
    BI.InvoiceNumber,    
    BI.InvoiceDate,--ISNULL(CONVERT(VARCHAR(10), BI.InvoiceDate, 1),''),    
    BI.InvoiceStatusID,    
    BIS.Name,    
    DTLData.TotalDetailCount,  
 DTLData.TotalDetailAmount,    
 DTLData.ReadyToBillCount,  
 DTLData.ReadyToBillAmount,  
 DTLData.PendingCount,  
 DTLData.PendingAmount,  
 DTLData.ExceptionCount,  
 DTLData.ExceptionAmount,  
 DTLData.ExcludedCount,  
 DTLData.ExcludedAmount,  
 DTLData.OnHoldCount,  
 DTLData.OnHoldAmount,    
 DTLData.PostedCount,  
 DTLData.PostedAmount,  
    BI.BillingDefinitionInvoiceID,    
    BI.ClientID,    
    BI.Name,    
    isnull(bi.POPrefix, '') + isnull(bi.PONumber, ''),  
    BI.AccountingSystemCustomerNumber,    
    cl.Name ,  
    bi.CanAddLines,  
    bss.Name  ,  
    bdi.ScheduleDateTypeID,  
    bdi.ScheduleRangeTypeID  ,
    bi.AccountingSystemAddressCode
  
      
  INSERT INTO #FinalResults    
SELECT     
 T.ID,    
 T.InvoiceDescription,    
 T.BillingScheduleID,    
 T.BillingSchedule,    
 T.BillingScheduleTypeID,    
 T.BillingScheduleType,    
 T.ScheduleDate,    
 T.ScheduleRangeBegin,    
 T.ScheduleRangeEnd,    
 T.InvoiceNumber,    
 T.InvoiceDate,    
 T.InvoiceStatusID,    
 T.InvoiceStatus,    
 T.TotalDetailCount,    
 T.TotalDetailAmount,    
 T.ReadyToBillCount,    
 T.ReadyToBillAmount,    
 T.PendingCount,    
 T.PendingAmount,     
 T.ExceptionCount,    
 T.ExceptionAmount,   
 T.ExcludedCount,    
 T.ExcludedAmount,   
 T.OnHoldCount,    
 T.OnHoldAmount,   
 T.PostedCount,    
 T.PostedAmount,    
 T.BillingDefinitionInvoiceID,    
 T.ClientID,    
 T.InvoiceName,    
 T.PONumber,    
 T.AccountingSystemCustomerNumber,    
 T.ClientName,  
 T.CanAddLines ,  
 T.BilingScheduleStatus ,  
 T.ScheduleDateTypeID,  
 T.ScheduleRangeTypeID  ,
 T.AccountingSystemAddressCode
 FROM #tmpFinalResults T    
    ORDER BY     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'    
  THEN T.ID END ASC,     
  CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'    
  THEN T.ID END DESC    ,

	 CASE WHEN @sortColumn = 'InvoiceDescription' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDescription END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDescription' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDescription END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleID END DESC ,

	 CASE WHEN @sortColumn = 'BillingSchedule' AND @sortOrder = 'ASC'
	 THEN T.BillingSchedule END ASC, 
	 CASE WHEN @sortColumn = 'BillingSchedule' AND @sortOrder = 'DESC'
	 THEN T.BillingSchedule END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleTypeID' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleTypeID' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'BillingScheduleType' AND @sortOrder = 'ASC'
	 THEN T.BillingScheduleType END ASC, 
	 CASE WHEN @sortColumn = 'BillingScheduleType' AND @sortOrder = 'DESC'
	 THEN T.BillingScheduleType END DESC ,

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

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatusID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceStatusID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatusID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceStatusID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'ASC'
	 THEN T.InvoiceStatus END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceStatus' AND @sortOrder = 'DESC'
	 THEN T.InvoiceStatus END DESC ,

	 CASE WHEN @sortColumn = 'TotalDetailCount' AND @sortOrder = 'ASC'
	 THEN T.TotalDetailCount END ASC, 
	 CASE WHEN @sortColumn = 'TotalDetailCount' AND @sortOrder = 'DESC'
	 THEN T.TotalDetailCount END DESC ,

	 CASE WHEN @sortColumn = 'TotalDetailAmount' AND @sortOrder = 'ASC'
	 THEN T.TotalDetailAmount END ASC, 
	 CASE WHEN @sortColumn = 'TotalDetailAmount' AND @sortOrder = 'DESC'
	 THEN T.TotalDetailAmount END DESC ,

	 CASE WHEN @sortColumn = 'ReadyToBillCount' AND @sortOrder = 'ASC'
	 THEN T.ReadyToBillCount END ASC, 
	 CASE WHEN @sortColumn = 'ReadyToBillCount' AND @sortOrder = 'DESC'
	 THEN T.ReadyToBillCount END DESC ,

	 CASE WHEN @sortColumn = 'ReadyToBillAmount' AND @sortOrder = 'ASC'
	 THEN T.ReadyToBillAmount END ASC, 
	 CASE WHEN @sortColumn = 'ReadyToBillAmount' AND @sortOrder = 'DESC'
	 THEN T.ReadyToBillAmount END DESC ,

	 CASE WHEN @sortColumn = 'PendingCount' AND @sortOrder = 'ASC'
	 THEN T.PendingCount END ASC, 
	 CASE WHEN @sortColumn = 'PendingCount' AND @sortOrder = 'DESC'
	 THEN T.PendingCount END DESC ,

	 CASE WHEN @sortColumn = 'PendingAmount' AND @sortOrder = 'ASC'
	 THEN T.PendingAmount END ASC, 
	 CASE WHEN @sortColumn = 'PendingAmount' AND @sortOrder = 'DESC'
	 THEN T.PendingAmount END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedCount' AND @sortOrder = 'ASC'
	 THEN T.ExcludedCount END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedCount' AND @sortOrder = 'DESC'
	 THEN T.ExcludedCount END DESC ,

	 CASE WHEN @sortColumn = 'ExceptionAmount' AND @sortOrder = 'ASC'
	 THEN T.ExceptionAmount END ASC, 
	 CASE WHEN @sortColumn = 'ExceptionAmount' AND @sortOrder = 'DESC'
	 THEN T.ExceptionAmount END DESC ,

	 CASE WHEN @sortColumn = 'ExceptionCount' AND @sortOrder = 'ASC'
	 THEN T.ExceptionCount END ASC, 
	 CASE WHEN @sortColumn = 'ExceptionCount' AND @sortOrder = 'DESC'
	 THEN T.ExceptionCount END DESC ,

	 CASE WHEN @sortColumn = 'ExcludedAmount' AND @sortOrder = 'ASC'
	 THEN T.ExcludedAmount END ASC, 
	 CASE WHEN @sortColumn = 'ExcludedAmount' AND @sortOrder = 'DESC'
	 THEN T.ExcludedAmount END DESC ,

	 CASE WHEN @sortColumn = 'OnHoldCount' AND @sortOrder = 'ASC'
	 THEN T.OnHoldCount END ASC, 
	 CASE WHEN @sortColumn = 'OnHoldCount' AND @sortOrder = 'DESC'
	 THEN T.OnHoldCount END DESC ,

	 CASE WHEN @sortColumn = 'OnHoldAmount' AND @sortOrder = 'ASC'
	 THEN T.OnHoldAmount END ASC, 
	 CASE WHEN @sortColumn = 'OnHoldAmount' AND @sortOrder = 'DESC'
	 THEN T.OnHoldAmount END DESC ,

	 CASE WHEN @sortColumn = 'PostedCount' AND @sortOrder = 'ASC'
	 THEN T.PostedCount END ASC, 
	 CASE WHEN @sortColumn = 'PostedCount' AND @sortOrder = 'DESC'
	 THEN T.PostedCount END DESC ,

	 CASE WHEN @sortColumn = 'PostedAmount' AND @sortOrder = 'ASC'
	 THEN T.PostedAmount END ASC, 
	 CASE WHEN @sortColumn = 'PostedAmount' AND @sortOrder = 'DESC'
	 THEN T.PostedAmount END DESC ,

	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceID' AND @sortOrder = 'ASC'
	 THEN T.BillingDefinitionInvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceID' AND @sortOrder = 'DESC'
	 THEN T.BillingDefinitionInvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceName' AND @sortOrder = 'ASC'
	 THEN T.InvoiceName END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceName' AND @sortOrder = 'DESC'
	 THEN T.InvoiceName END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'AccountingSystemCustomerNumber' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemCustomerNumber END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemCustomerNumber' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemCustomerNumber END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'CanAddLines' AND @sortOrder = 'ASC'
	 THEN T.CanAddLines END ASC, 
	 CASE WHEN @sortColumn = 'CanAddLines' AND @sortOrder = 'DESC'
	 THEN T.CanAddLines END DESC ,

	 CASE WHEN @sortColumn = 'BilingScheduleStatus' AND @sortOrder = 'ASC'
	 THEN T.BilingScheduleStatus END ASC, 
	 CASE WHEN @sortColumn = 'BilingScheduleStatus' AND @sortOrder = 'DESC'
	 THEN T.BilingScheduleStatus END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleDateTypeID' AND @sortOrder = 'ASC'
	 THEN T.ScheduleDateTypeID END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleDateTypeID' AND @sortOrder = 'DESC'
	 THEN T.ScheduleDateTypeID END DESC ,

	 CASE WHEN @sortColumn = 'ScheduleRangeTypeID' AND @sortOrder = 'ASC'
	 THEN T.ScheduleRangeTypeID END ASC, 
	 CASE WHEN @sortColumn = 'ScheduleRangeTypeID' AND @sortOrder = 'DESC'
	 THEN T.ScheduleRangeTypeID END DESC  ,

	 CASE WHEN @sortColumn = 'AccountingSystemAddressCode' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemAddressCode END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemAddressCode' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemAddressCode END DESC  
      
      
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
     
 DROP TABLE #FinalResults    
 DROP TABLE #tmpFinalResults    
 END 
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Call_Summary]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_Call_Summary]
GO

--EXEC dms_Call_Summary @serviceRequestID = 1468  
CREATE PROC dms_Call_Summary(@serviceRequestID INT = NULL)  
AS  
BEGIN 


DECLARE @programID AS INT
SET     @programID = (SELECT ProgramID FROM [Case] WHERE ID = (SELECT CaseID FROM ServiceRequest WHERE ID = @serviceRequestID))

DECLARE @ProgramConfigurationDetails AS TABLE(
	Name NVARCHAR(100) NULL,
	Value NVARCHAR(100) NULL,
	ControlType NVARCHAR(100) NULL,
	DataType NVARCHAR(100) NULL,
	Sequence INT NULL)

INSERT INTO @ProgramConfigurationDetails
EXEC [dms_programconfiguration_for_program_get]
   @programID = @programID,
   @configurationType = 'Service',
   @configurationCategory  ='Validation'


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
   -- Ignore time while comparing dates here
    -- KB: Considering Effective and Expiration Dates to calculate member status
	, CASE 
		WHEN	ISNULL(m.EffectiveDate,@minDate) <= @now AND ISNULL(m.ExpirationDate,@minDate) >= @now
		THEN	'Active'
		ELSE	'Inactive'
		END	AS Member_Status     
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
	,CASE	WHEN C.IsVehicleEligible IS NULL THEN '' 
			WHEN C.IsVehicleEligible = 1 THEN 'In Warranty'
			ELSE 'Out of Warranty' END AS Vehicle_IsEligible
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
	
	, CASE WHEN sr.IsPrimaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsPrimaryOverallCovered
	, pc.Name as Service_ProductCategoryTow
	, sr.PrimaryServiceEligiblityMessage as Service_PrimaryServiceEligiblityMessage

	, CASE WHEN sr.IsSecondaryOverallCovered  = 1 THEN 'Covered' ELSE 'Not Covered' END AS Service_IsSecondaryOverallCovered
	, CASE WHEN sr.IsPossibleTow = 1 THEN 'Possible Tow' ELSE '' END AS Service_IsPossibleTow
	, sr.SecondaryServiceEligiblityMessage as Service_SecondaryServiceEligiblityMessage

	--, '$' + CONVERT(NVARCHAR(50),ISNULL(sr.PrimaryCoverageLimit,0)) as Service_CoverageLimit  

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
 UPDATE @Hold SET GroupName = 'Member', DefaultRows = 6 WHERE CHARINDEX('Member_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Vehicle', DefaultRows = 3 WHERE CHARINDEX('Vehicle_',ColumnName) > 0    
 UPDATE @Hold SET GroupName = 'Service' ,DefaultRows = 6 WHERE CHARINDEX('Service_',ColumnName) > 0    
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
 UPDATE @Hold SET DataType = 'LabelTheme' WHERE CHARINDEX('Member_Status',ColumnName) > 0 OR CHARINDEX('Vehicle_IsEligible',ColumnName) > 0  
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsPrimaryOverallCovered',ColumnName) > 0
 UPDATE @Hold SET DataType = 'LabelThemeInline' WHERE CHARINDEX('Service_IsSecondaryOverallCovered',ColumnName) > 0   

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_IsPossibleTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsSecondaryOverallCovered'
	DELETE FROM @Hold WHERE ColumnName  = 'Service_SecondaryServiceEligiblityMessage'
 END

 IF NOT EXISTS (SELECT * FROM @Hold WHERE ColumnName  = 'Service_ProductCategoryTow' AND ColumnValue IS NOT NULL AND  ColumnValue != '')
 BEGIN
	DELETE FROM @Hold WHERE ColumnName  = 'Service_IsPrimaryOverallCovered'
 END

 DELETE FROM @Hold WHERE ColumnValue IS NULL

 DECLARE @DefaultRows INT
 SET  @DefaultRows = (SELECT Sequence FROM @Hold WHERE ColumnName = 'Member_AltCallbackPhoneNumber')
 IF @DefaultRows IS NOT NULL
 BEGIN
 SET @DefaultRows = (SELECT COUNT(*) FROM @Hold WHERE ColumnName LIKE 'Member_%' AND Sequence <= @DefaultRows)
 -- Re Setting values 
 UPDATE @Hold SET DefaultRows = @DefaultRows WHERE GroupName = 'Member' 
 END

 -- Sanghi - 01-04-2014 CR : 248 Increase Number of Columns to be Displayed When Warranty is Applicable.
 -- Validate Vehicle_IsEligible COLUMN 
 IF EXISTS (SELECT * FROM @Hold WHERE ColumnName = 'Vehicle_IsEligible')
 BEGIN
	UPDATE @Hold SET DefaultRows = 4 WHERE GroupName = 'Vehicle' 
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


IF NOT EXISTS (SELECT * FROM @ProgramConfigurationDetails WHERE Name = 'MemberEligibilityApplies' AND Value = 'Yes')
BEGIN
	DELETE FROM @Hold WHERE ColumnName = 'Member_Status'
END
 
 
 SELECT * FROM @Hold WHERE ColumnValue IS NOT NULL ORDER BY Sequence ASC 
 
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
AND TCC.IssueDate > DATEADD(mm, -3, GETDATE())

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
 WHERE id = object_id(N'[dbo].[dms_Claims_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Claims_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Claims_List_Get]@sortColumn='AmountApproved' ,@endInd=50,@pageSize=50,@whereClauseXML='<ROW><Filter ClaimAmountFrom="0"/></ROW>',@sortOrder='DESC'
 CREATE PROCEDURE [dbo].[dms_Claims_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDType=""
IDValue=""
NameType=""
NameOperator=""
NameValue=""
ClaimTypes=""
ClaimStatuses=""
ClaimCategories=""
ClientID=""
ProgramID=""
ExportBatchID=""
 ></Filter></ROW>'
END

--CREATE TABLE #tmpForWhereClause
DECLARE @tmpForWhereClause TABLE
(
IDType			NVARCHAR(50) NULL,
IDValue			NVARCHAR(100) NULL,
NameType		NVARCHAR(50) NULL,
NameOperator	NVARCHAR(50) NULL,
NameValue		NVARCHAR(MAX) NULL,
ClaimTypes		NVARCHAR(MAX) NULL,
ClaimStatuses	NVARCHAR(MAX) NULL,
ClaimCategories	NVARCHAR(MAX) NULL,
ClientID		INT NULL,
ProgramID		INT NULL,
Preset			INT NULL,
ClaimDateFrom	DATETIME NULL,
ClaimDateTo		DATETIME NULL,
ClaimAmountFrom	MONEY NULL,
ClaimAmountTo	MONEY NULL,
CheckNumber		NVARCHAR(50) NULL,
CheckDateFrom	DATETIME NULL,
CheckDateTo		DATETIME NULL,
ExportBatchID	INT NULL,
ACESSubmitFromDate DATETIME NULL,
ACESSubmitToDate DATETIME NULL,
ACESClearedFromDate DATETIME NULL,
ACESClearedToDate DATETIME NULL,
ACESStatus NVARCHAR(MAX) NULL,
ReceivedFromDate DATETIME NULL,
ReceivedToDate DATETIME NULL
)
 CREATE TABLE #FinalResultsFiltered( 	
	ClaimID			INT  NULL ,
	ClaimType		NVARCHAR(100)  NULL ,
	ClaimDate		DATETIME  NULL ,
	ReceivedDate	DATETIME  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee			NVARCHAR(100)  NULL ,
	ClaimStatus		NVARCHAR(100)  NULL ,
	NextAction		NVARCHAR(100)  NULL ,
	AssignedTo		NVARCHAR(100)  NULL ,
	NextActionScheduledDate DATETIME  NULL ,
	ACESSubmitDate	DATETIME  NULL ,
	CheckNumber		NVARCHAR(100)  NULL ,
	PaymentDate		DATETIME  NULL ,
	PaymentAmount	MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AuthorizationCount	BIGINT NULL,
	InProcessCount	BIGINT NULL,
	CancelledCount	BIGINT NULL,
	ApprovedCount	BIGINT NULL,
	DeniedCount	BIGINT NULL,
	ReadyForPaymentCount BIGINT NULL,
	PaidCount		BIGINT NULL,
	ExceptionCount		BIGINT NULL,
	ClaimExceptionDetails NVARCHAR(MAX) NULL,
	MembershipNumber NVARCHAR(100) NULL,
	ProgramName NVARCHAR(100) NULL,
	BatchID INT NULL,
	AmountApproved MONEY  NULL ,
	ACESStatus nvarchar(100) NULL ,
	ACESClearedDate DATETIME NULL,
	ACESFeeAmount MONEY NULL
) 

CREATE TABLE #FinalResultsSorted( 
	[RowNum]		[BIGINT]	NOT NULL IDENTITY(1,1),
	ClaimID			INT  NULL ,
	ClaimType		NVARCHAR(100)  NULL ,
	ClaimDate		DATETIME  NULL ,
	ReceivedDate	DATETIME  NULL ,
	AmountRequested MONEY  NULL ,
	Payeee			NVARCHAR(100)  NULL ,
	ClaimStatus		NVARCHAR(100)  NULL ,
	NextAction		NVARCHAR(100)  NULL ,
	AssignedTo		NVARCHAR(100)  NULL ,
	NextActionScheduledDate DATETIME  NULL ,
	ACESSubmitDate	DATETIME  NULL ,
	CheckNumber		NVARCHAR(100)  NULL ,
	PaymentDate		DATETIME  NULL ,
	PaymentAmount	MONEY  NULL,
	CheckClearedDate DATETIME NULL,
	AuthorizationCount	BIGINT NULL,
	InProcessCount	BIGINT NULL,
	CancelledCount	BIGINT NULL,
	ApprovedCount	BIGINT NULL,
	DeniedCount	BIGINT NULL,
	ReadyForPaymentCount BIGINT NULL,
	PaidCount		BIGINT NULL,
	ExceptionCount		BIGINT NULL ,
	ClaimExceptionDetails NVARCHAR(MAX)NULL,
	MembershipNumber NVARCHAR(100) NULL,
	ProgramName NVARCHAR(100) NULL,
	BatchID INT NULL,
	AmountApproved MONEY  NULL,
	ACESStatus nvarchar(100) NULL ,
	ACESClearedDate DATETIME NULL ,
	ACESFeeAmount MONEY NULL
) 

INSERT INTO @tmpForWhereClause
SELECT  
	T.c.value('@IDType','NVARCHAR(50)'),
	T.c.value('@IDValue','NVARCHAR(100)'),
	T.c.value('@NameType','NVARCHAR(50)'),
	T.c.value('@NameOperator','NVARCHAR(50)'),
	T.c.value('@NameValue','NVARCHAR(MAX)'),
	T.c.value('@ClaimTypes','NVARCHAR(MAX)'),
	T.c.value('@ClaimStatuses','NVARCHAR(MAX)'),
	T.c.value('@ClaimCategories','NVARCHAR(MAX)'),
	T.c.value('@ClientID','INT'),
	T.c.value('@ProgramID','INT'),
	T.c.value('@Preset','INT'),
	T.c.value('@ClaimDateFrom','DATETIME'),
	T.c.value('@ClaimDateTo','DATETIME'),
	T.c.value('@ClaimAmountFrom','MONEY'),
	T.c.value('@ClaimAmountTo','MONEY'),
	T.c.value('@CheckNumber','NVARCHAR(50)'),
	T.c.value('@CheckDateFrom','DATETIME'),
	T.c.value('@CheckDateTo','DATETIME'),
	T.c.value('@ExportBatchID','INT'),
	T.c.value('@ACESSubmitFromDate','DATETIME'),
	T.c.value('@ACESSubmitToDate','DATETIME'),
	T.c.value('@ACESClearedFromDate','DATETIME'),
	T.c.value('@ACESClearedToDate','DATETIME'),
	T.c.value('@ACESStatus','NVARCHAR(MAX)'),
	T.c.value('@ReceivedFromDate','DATETIME'),
	T.c.value('@ReceivedToDate','DATETIME')
	
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @IDType			NVARCHAR(50)= NULL,
@IDValue			NVARCHAR(100)= NULL,
@NameType		NVARCHAR(50)= NULL,
@NameOperator	NVARCHAR(50)= NULL,
@NameValue		NVARCHAR(MAX)= NULL,
@ClaimTypes		NVARCHAR(MAX)= NULL,
@ClaimStatuses	NVARCHAR(MAX)= NULL,
@ClaimCategories	NVARCHAR(MAX)= NULL,
@ClientID		INT= NULL,
@ProgramID		INT= NULL,
@preset			INT=NULL,
@ClaimDateFrom	DATETIME= NULL,
@ClaimDateTo		DATETIME= NULL,
@ClaimAmountFrom	MONEY= NULL,
@ClaimAmountTo	MONEY= NULL,
@CheckNumber		NVARCHAR(50)= NULL,
@CheckDateFrom	DATETIME= NULL,
@CheckDateTo		DATETIME= NULL,
@ExportBatchID	INT= NULL,
@ACESSubmitFromDate DATETIME= NULL,
@ACESSubmitToDate DATETIME= NULL,
@ACESClearedFromDate DATETIME= NULL,
@ACESClearedToDate DATETIME= NULL,
@ACESStatus NVARCHAR(MAX) = NULL,
@ReceivedFromDate DATETIME= NULL,
@ReceivedToDate DATETIME= NULL

SELECT 
		@IDType					= IDType				
		,@IDValue				= IDValue				
		,@NameType				= NameType			
		,@NameOperator			= NameOperator		
		,@NameValue				= NameValue			
		,@ClaimTypes			= ClaimTypes			
		,@ClaimStatuses			= ClaimStatuses		
		,@ClaimCategories		= ClaimCategories		
		,@ClientID				= ClientID			
		,@ProgramID				= ProgramID			
		,@preset				= Preset				
		,@ClaimDateFrom			= ClaimDateFrom		
		,@ClaimDateTo			= ClaimDateTo			
		,@ClaimAmountFrom		= ClaimAmountFrom		
		,@ClaimAmountTo			= ClaimAmountTo		
		,@CheckNumber			= CheckNumber			
		,@CheckDateFrom			= CheckDateFrom		
		,@CheckDateTo			= CheckDateTo			
		,@ExportBatchID			= ExportBatchID		
		,@ACESSubmitFromDate	= ACESSubmitFromDate	
		,@ACESSubmitToDate		= ACESSubmitToDate
		,@ACESClearedFromDate	= ACESClearedFromDate
		,@ACESClearedToDate		= ACESClearedToDate
		,@ACESStatus			= ACESStatus
		,@ReceivedFromDate      = ReceivedFromDate
        ,@ReceivedToDate        = ReceivedToDate
FROM	@tmpForWhereClause

--SELECT @preset
IF (@preset IS NOT NULL)
BEGIN
	DECLARE @fromDate DATETIME
	SET @fromDate = DATEADD(DD, DATEDIFF(DD,0, DATEADD(DD,-1 * @preset,GETDATE())),0)
	UPDATE @tmpForWhereClause 
	SET		ClaimDateFrom  = @fromDate,
			ClaimDateTo = DATEADD(DD,1,GETDATE())
		

END



--SELECT * FROM @tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResultsFiltered
SELECT
		C.ID AS ClaimID
		, CT.Name AS ClaimType
		, C.ClaimDate
		, C.ReceivedDate
		, C.AmountRequested
		, CASE
                        WHEN ISNULL(C.PayeeType,'') = 'Member' THEN 'M-' + C.ContactName
                        WHEN ISNULL(C.PayeeType,'') = 'Vendor' THEN 'V-' + C.ContactName
                        ELSE C.ContactName
          END AS Payeee
		, CS.Name AS ClaimStatus
		, NA.Name AS NextAction
		, U.FirstName + ' ' + U.LastName AS AssignedTo
		, C.NextActionScheduledDate
		, C.ACESSubmitDate
		, C.CheckNumber
		, C.PaymentDate
		, C.PaymentAmount
		, C.CheckClearedDate
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, NULL
		, CE.[Description]
		, MS.MembershipNumber
		, P.Name
		, B.ID AS BatchID
		, C.AmountApproved
		, ACS.Name AS ACESClaimStatus
		, C.ACESClearedDate
		, C.ACESFeeAmount 
FROM	Claim C
JOIN	ClaimType CT WITH(NOLOCK) ON CT.ID = C.ClaimTypeID
LEFT JOIN ClaimStatus CS WITH(NOLOCK) ON CS.ID = C.ClaimStatusID 
LEFT JOIN ClaimException CE WITH(NOLOCK) ON CE.ClaimID = C.ID
LEFT JOIN NextAction NA WITH(NOLOCK) ON NA.ID = C.NextActionID
LEFT JOIN [User] U WITH(NOLOCK) ON U.ID = C.NextActionAssignedToUserID
LEFT JOIN Vendor V WITH (NOLOCK) ON C.VendorID = V.ID
LEFT JOIN Member M WITH (NOLOCK) ON C.MemberID = M.ID
LEFT JOIN Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
LEFT JOIN PurchaseOrder PO WITH (NOLOCK) ON C.PurchaseOrderID = PO.ID
LEFT JOIN Program P WITH (NOLOCK) ON P.ID = C.ProgramID
LEFT JOIN Batch B WITH(NOLOCK) ON B.ID=C.ExportBatchID
LEFT JOIN ACESClaimStatus ACS WITH(NOLOCK) ON ACS.ID=C.ACESClaimStatusID
WHERE C.IsActive = 1
AND		(ISNULL(LEN(@IDType),0) = 0 OR (	( @IDType = 'Claim' AND @IDValue	= CONVERT(NVARCHAR(100),C.ID))
											OR
											( @IDType = 'Vendor' AND @IDValue = V.VendorNumber)
											OR
											( @IDType = 'Member' AND @IDValue = MS.MembershipNumber)
										) )
AND		(ISNULL(LEN(@NameType),0) = 0 OR (	
											(@NameType = 'Member' AND (
																			-- TODO: Review the conditions against M.LastName. we might have to use first and last names.
																			(@NameOperator = 'Is equal to' AND @NameValue = M.LastName)
																			OR
																			(@NameOperator = 'Begins with' AND M.LastName LIKE  @NameValue + '%')
																			OR
																			(@NameOperator = 'Ends with' AND M.LastName LIKE  '%' + @NameValue)
																			OR
																			(@NameOperator = 'Contains' AND M.LastName LIKE  '%' + @NameValue + '%')

																		) )
												OR
											(@NameType = 'Vendor' AND (
																			(@NameOperator = 'Is equal to' AND @NameValue = V.Name)
																			OR
																			(@NameOperator = 'Begins with' AND V.Name LIKE  @NameValue + '%')
																			OR
																			(@NameOperator = 'Ends with' AND V.Name LIKE  '%' + @NameValue)
																			OR
																			(@NameOperator = 'Contains' AND V.Name LIKE  '%' + @NameValue + '%')

																		) )

											) )
AND		(ISNULL(LEN(@ClaimTypes),0) = 0  OR (C.ClaimTypeID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimTypes,',')) ) )
AND		(ISNULL(LEN(@ClaimStatuses),0) = 0  OR (C.ClaimStatusID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimStatuses,',')) ) )
AND		(ISNULL(LEN(@ClaimCategories),0) = 0  OR (C.ClaimCategoryID IN ( SELECT item FROM [dbo].[fnSplitString](@ClaimCategories,',')) ) )
AND		(ISNULL(@ClientID,0) = 0 OR @ClientID = 0 OR (P.ClientID = @ClientID  ) )
AND		(ISNULL(@ProgramID,0) = 0 OR @ProgramID = 0 OR (C.ProgramID = @ProgramID  ) )
AND		(C.ClaimDate IS NULL 
		OR
		C.ClaimDate IS NOT NULL
		AND		(@ClaimDateFrom IS NULL  OR ( C.ClaimDate >= @ClaimDateFrom ) )
		AND		(@ClaimDateTo IS NULL  OR ( C.ClaimDate < DATEADD(DD,1,@ClaimDateTo) ) )
		)
AND		(@ClaimAmountFrom IS NULL OR (ISNULL(C.AmountRequested,0) >= @ClaimAmountFrom))
AND		(@ClaimAmountTo IS NULL OR (ISNULL(C.AmountRequested,0) <= @ClaimAmountTo))
AND		(ISNULL(LEN(@CheckNumber),0) = 0 OR C.CheckNumber = @CheckNumber)
AND		(ISNULL(@ExportBatchID,0) = 0 OR @ExportBatchID = 0 OR (B.ID = @ExportBatchID  ) )
AND		(@CheckDateFrom IS NULL OR (C.CheckClearedDate >= @CheckDateFrom))
AND		(@CheckDateTo IS NULL OR (C.CheckClearedDate < DATEADD(DD,1,@CheckDateTo)))
AND		(@ACESSubmitFromDate IS NULL OR (C.ACESSubmitDate >= @ACESSubmitFromDate))
AND		(@ACESSubmitToDate IS NULL OR (C.ACESSubmitDate < DATEADD(DD,1,@ACESSubmitToDate)))	
AND		(@ACESClearedFromDate IS NULL OR (C.ACESClearedDate >= @ACESClearedFromDate))
AND		(@ACESClearedToDate IS NULL OR (C.ACESClearedDate < DATEADD(DD,1,@ACESClearedToDate)))		
AND		(@ACESStatus IS NULL OR (C.ACESClaimStatusID IN (SELECT item FROM [dbo].[fnSplitString](@ACESStatus,','))))
AND		(@ReceivedFromDate IS NULL OR (C.ReceivedDate >= @ReceivedFromDate))
AND		(@ReceivedToDate IS NULL OR (C.ReceivedDate < DATEADD(DD,1,@ReceivedToDate)))	


--FILTERING has to be taken care here
INSERT INTO #FinalResultsSorted
SELECT 
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.ReceivedDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.NextAction,
	T.AssignedTo,
	T.NextActionScheduledDate,
	T.ACESSubmitDate,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AuthorizationCount,
	T.InProcessCount,
	T.CancelledCount,
	T.ApprovedCount,
	T.DeniedCount,
	T.ReadyForPaymentCount,
	T.PaidCount,
	T.ExceptionCount,
   [dbo].[fnConcatenate](T.ClaimExceptionDetails) AS ClaimExceptionDetails,
    T.MembershipNumber,
    T.ProgramName,
    T.BatchID,
    T.AmountApproved,
    T.ACESStatus,
    T.ACESClearedDate,
	T.ACESFeeAmount 
FROM #FinalResultsFiltered T
GROUP BY 
	T.ClaimID,
	T.ClaimType,
	T.ClaimDate,
	T.ReceivedDate,
	T.AmountRequested,
	T.Payeee,
	T.ClaimStatus,
	T.NextAction,
	T.AssignedTo,
	T.NextActionScheduledDate,
	T.ACESSubmitDate,
	T.CheckNumber,
	T.PaymentDate,
	T.PaymentAmount,
	T.CheckClearedDate,
	T.AuthorizationCount,
	T.InProcessCount,
	T.CancelledCount,
	T.ApprovedCount,
	T.DeniedCount,
	T.ReadyForPaymentCount,
	T.PaidCount,
	T.ExceptionCount,
	T.MembershipNumber,
	T.ProgramName,
	T.BatchID,
	T.AmountApproved,
	T.ACESStatus,
	T.ACESClearedDate,
	T.ACESFeeAmount 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'ASC'
	 THEN T.ClaimID END ASC, 
	 CASE WHEN @sortColumn = 'ClaimID' AND @sortOrder = 'DESC'
	 THEN T.ClaimID END DESC ,

	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'ASC'
	 THEN T.ClaimType END ASC, 
	 CASE WHEN @sortColumn = 'ClaimType' AND @sortOrder = 'DESC'
	 THEN T.ClaimType END DESC ,

	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'ASC'
	 THEN T.ClaimDate END ASC, 
	 CASE WHEN @sortColumn = 'ClaimDate' AND @sortOrder = 'DESC'
	 THEN T.ClaimDate END DESC ,

	  CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'ASC'
	 THEN T.ReceivedDate END ASC, 
	 CASE WHEN @sortColumn = 'ReceivedDate' AND @sortOrder = 'DESC'
	 THEN T.ReceivedDate END DESC ,

	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'ASC'
	 THEN T.AmountRequested END ASC, 
	 CASE WHEN @sortColumn = 'AmountRequested' AND @sortOrder = 'DESC'
	 THEN T.AmountRequested END DESC ,

	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'ASC'
	 THEN T.Payeee END ASC, 
	 CASE WHEN @sortColumn = 'Payeee' AND @sortOrder = 'DESC'
	 THEN T.Payeee END DESC ,

	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'ASC'
	 THEN T.ClaimStatus END ASC, 
	 CASE WHEN @sortColumn = 'ClaimStatus' AND @sortOrder = 'DESC'
	 THEN T.ClaimStatus END DESC ,

	 CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'
	 THEN T.NextAction END ASC, 
	 CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'
	 THEN T.NextAction END DESC ,

	 CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'
	 THEN T.AssignedTo END ASC, 
	 CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'
	 THEN T.AssignedTo END DESC ,

	 CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'ASC'
	 THEN T.NextActionScheduledDate END ASC, 
	 CASE WHEN @sortColumn = 'NextActionScheduledDate' AND @sortOrder = 'DESC'
	 THEN T.NextActionScheduledDate END DESC ,

	 CASE WHEN @sortColumn = 'ACESSubmitDate' AND @sortOrder = 'ASC'
	 THEN T.ACESSubmitDate END ASC, 
	 CASE WHEN @sortColumn = 'ACESSubmitDate' AND @sortOrder = 'DESC'
	 THEN T.ACESSubmitDate END DESC ,

	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'ASC'
	 THEN T.CheckNumber END ASC, 
	 CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'DESC'
	 THEN T.CheckNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN T.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN T.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC, 
	 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN T.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN T.CheckClearedDate END DESC,
	 
	 CASE WHEN @sortColumn = 'BatchID' AND @sortOrder = 'ASC'
	 THEN T.BatchID END ASC, 
	 CASE WHEN @sortColumn = 'BatchID' AND @sortOrder = 'DESC'
	 THEN T.BatchID END DESC,

	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'ASC'
	 THEN T.AmountApproved END ASC, 
	 CASE WHEN @sortColumn = 'AmountApproved' AND @sortOrder = 'DESC'
	 THEN T.AmountApproved END DESC,

	 CASE WHEN @sortColumn = 'ACESStatus' AND @sortOrder = 'ASC'
	 THEN T.ACESStatus END ASC, 
	 CASE WHEN @sortColumn = 'ACESStatus' AND @sortOrder = 'DESC'
	 THEN T.ACESStatus END DESC,

	 CASE WHEN @sortColumn = 'ACESClearedDate' AND @sortOrder = 'ASC'
	 THEN T.ACESClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'ACESClearedDate' AND @sortOrder = 'DESC'
	 THEN T.ACESClearedDate END DESC,

	 CASE WHEN @sortColumn = 'ACESFeeAmount' AND @sortOrder = 'ASC'
	 THEN T.ACESFeeAmount END ASC, 
	 CASE WHEN @sortColumn = 'ACESFeeAmount' AND @sortOrder = 'DESC'
	 THEN T.ACESFeeAmount END DESC


DECLARE @authorizationIssuedCount  BIGINT = 0,
		@inProcessCount BIGINT = 0,
		@cancelledCount BIGINT = 0,
		@approvedCount  BIGINT = 0,
		@deniedCount  BIGINT = 0,
		@readyForPaymentCount BIGINT = 0,
		@PaidCount BIGINT = 0,
		@exceptionCount BIGINT = 0


SELECT @authorizationIssuedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'AuthorizationIssued'
SELECT @inProcessCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'In-Process'
SELECT @cancelledCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Cancelled'
SELECT @approvedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Approved'
SELECT @deniedCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Denied'
SELECT @readyForPaymentCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'ReadyForPayment'
SELECT @PaidCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Paid'
SELECT @exceptionCount = COUNT(*) FROM #FinalResultsSorted F WHERE F.ClaimStatus = 'Exception'

-- DEBUG : SELECT * FROM #FinalResultsSorted WHERE ClaimStatus  ='Approved'

UPDATE #FinalResultsSorted
SET AuthorizationCount = @authorizationIssuedCount,
	InProcessCount = @inProcessCount,
	CancelledCount = @cancelledCount,
   	ApprovedCount = @approvedCount,
    DeniedCount = @deniedCount,
    ReadyForPaymentCount = @readyForPaymentCount,
    PaidCount = @PaidCount,
    ExceptionCount = @exceptionCount

DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted
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

SELECT @count AS TotalRows, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd

--DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResultsFiltered
DROP TABLE #FinalResultsSorted

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
			@agentUserID INT,
			@nextActionPriorityID INT = NULL,
			@defaultScheduleDateInterval INT = NULL,
			@defaultScheduleDateIntervalUOM NVARCHAR(50) = NULL,
			@vendorEntityID INT = NULL,
			@vendorID INT = NULL

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	
	SELECT @vendorEntityID = ID FROM [Entity] WHERE Name = 'Vendor'

	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	SELECT	@nextActionPriorityID = DefaultPriorityID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'

	IF (@nextActionPriorityID IS NULL)
	BEGIN
		SELECT @nextActionPriorityID = (SELECT ID FROM ServiceRequestPriority WITH (NOLOCK) WHERE Name = 'Normal')
	END


	SELECT	@defaultScheduleDateInterval	= ISNULL(DefaultScheduleDateInterval,0),
			@defaultScheduleDateIntervalUOM = DefaultScheduleDateIntervalUOM
	FROM	NextAction WITH (NOLOCK)
	WHERE	ID = @resendPONextActionID


	--SELECT	@agentUserID = U.ID
	--FROM	[User] U WITH (NOLOCK) 
	--JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	--JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	--WHERE	AU.UserName = 'Agent'
	--AND		A.ApplicationName = 'DMS'

	SELECT	@eventData = EL.Data
	FROM	EventLog EL WITH (NOLOCK)
	JOIN	Event E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	EL.ID = @eventLogID

	SELECT	@eventName = E.Name
	FROM	EventSubscription ES WITH (NOLOCK) 
	JOIN	Event E WITH (NOLOCK) ON ES.EventID = E.ID
	WHERE	ES.ID = @eventSubscriptionID
	
	IF (@eventName = 'InsuranceExpiring' OR @eventName = 'InsuranceExpired')
	BEGIN

		SELECT @vendorID = ELL.RecordID
		FROM	EventLogLink ELL WITH (NOLOCK)
		WHERE	ELL.EventLogID = @eventLogID
		AND		ELL.EntityID = @vendorEntityID
		

		INSERT INTO @tmpCurrentUser
		SELECT	NULL,
				V.Email
		FROM	Vendor V WITH (NOLOCK)
		WHERE	V.ID = @vendorID
	END
	ELSE
	BEGIN

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
			PRINT 'AssignedToUserID On Case is not null'
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
			-- TFS: 390
			--IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			--BEGIN
				
			--	INSERT INTO @tmpCurrentUser
			--	SELECT	AU.UserId,
			--			AU.UserName
			--	FROM	aspnet_Users AU WITH (NOLOCK) 
			--	JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
			--	WHERE	AU.UserName = @CreateByUser
			--	AND		A.ApplicationName = 'DMS'
				
			--END
			--ELSE
			--BEGIN
			PRINT 'AssignedToUserID On Case is null'
				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				--IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					PRINT 'Setting service request attributes'
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							--TFS : 390
							NextActionAssignedToUserID = (SELECT DefaultAssignedToUserID FROM NextAction 
															WHERE ID = @resendPONextActionID 
														 ),
							ServiceRequestPriorityID = @nextActionPriorityID,
							NextActionScheduledDate =  CASE WHEN @defaultScheduleDateIntervalUOM = 'days'
																THEN DATEADD(dd,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'hours'
																THEN DATEADD(hh,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'minutes'
																THEN DATEADD(mi,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'seconds'
																THEN DATEADD(ss,@defaultScheduleDateInterval,GETDATE())
															ELSE NULL
															END
														
					WHERE	ID = @ServiceRequest

					; WITH wManagers
					AS
					(
						SELECT	DISTINCT AU.UserId,
								AU.UserName,
								[dbo].[fnIsUserConnected](AU.UserName) AS IsConnected
						FROM	aspnet_Users AU WITH (NOLOCK) 
						JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId
						JOIN	aspnet_Membership M WITH (NOLOCK) ON M.ApplicationId = A.ApplicationId AND ISNULL(M.IsApproved,0) = 1 AND ISNULL(M.IsLockedOut,0) = 0 AND M.UserID = AU.UserID
						JOIN	aspnet_UsersInRoles UR WITH (NOLOCK) ON UR.UserId = AU.UserId
						JOIN	aspnet_Roles R WITH (NOLOCK) ON UR.RoleId = R.RoleId AND R.ApplicationId = A.ApplicationId
						WHERE	A.ApplicationName = 'DMS'
						AND		R.RoleName = 'Manager'					
					)
					INSERT INTO @tmpCurrentUser
					SELECT  W.UserId,
							W.UserName
					FROM	wManagers W
					WHERE	ISNULL(W.IsConnected,0) = 1
			
				END				
		END	
	END
	
	ELSE IF (@eventName = 'ManualNotification' OR @eventName = 'LockedRequestComment')
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

	END

	SELECT UserId, Username from @tmpCurrentUser

END

GO


GO

 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_GoToPODetails_row]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_GoToPODetails_row] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_GoToPODetails_row] 323184, 3,3,2,139,122825,NULL   
--32.780122,-96.801412,'TX','US',32.864132,-96.942948,
 CREATE PROCEDURE [dbo].[dms_GoToPODetails_row](
	@ServiceRequestID int 
	,@EnrouteMiles decimal(18,4) 
	,@ReturnMiles  decimal(18,4) 
	,@EstimatedHours decimal(18,4) 
	,@ProductID int 
	,@VendorLocationID int 
	,@VendorID int = NULL
) 
AS 
BEGIN

	SET FMTONLY OFF;
 	SET NOCOUNT ON;
 	
	DECLARE @ServiceLocationLatitude decimal(10,7)
		,@ServiceLocationLongitude decimal(10,7)
		,@ServiceLocationStateProvince varchar(20)
		,@ServiceLocationCountryCode varchar(20)
		,@DestinationLocationLatitude  decimal(10,7)
		,@DestinationLocationLongitude  decimal(10,7)
		,@ServiceMiles decimal(10,2)
		,@PrimaryCoverageLimitMileage int
		,@EnrouteFreeRateTypeID int
		,@ServiceFreeRateTypeID int
		,@ServiceLocation as geography  

	SET @EnrouteFreeRateTypeID = (SELECT ID FROM RateType WHERE Name = 'EnrouteFree')
	SET @ServiceFreeRateTypeID = (SELECT ID FROM RateType WHERE Name = 'ServiceFree')

	SELECT 
		@ServiceLocationLatitude =ServiceLocationLatitude
		,@ServiceLocationLongitude=ServiceLocationLongitude
		,@ServiceLocationStateProvince=ServiceLocationStateProvince
		,@ServiceLocationCountryCode=ServiceLocationCountryCode
		,@DestinationLocationLatitude=DestinationLatitude
		,@DestinationLocationLongitude=DestinationLongitude
		,@ServiceMiles= ISNULL(ServiceMiles,0)
		,@PrimaryCoverageLimitMileage = ISNULL(PrimaryCoverageLimitMileage,0)
		FROM ServiceRequest Where 
		ID=@ServiceRequestID

	-- KB: Take the product from service request, if the param is null.
	IF (@ProductID IS NULL)
	BEGIN
	SELECT @ProductID = PrimaryProductID FROM ServiceRequest Where ID=@ServiceRequestID 
	END
	--PR: Take the VendorID From VendorLocation
	IF(@VendorID IS NULL)
	BEGIN
	SELECT @VendorID= VendorID from VendorLocation where ID=@VendorLocationID
	END

	SET @ServiceLocation = geography::Point(ISNULL(@ServiceLocationLatitude,0), ISNULL(@ServiceLocationLongitude,0), 4326)  
      
	SELECT 
		  @VendorLocationID AS VendorLocationID
		  ,RateDetail.ProductID
		  ,RateDetail.ProductName
		  ,RateDetail.RateTypeID
		  ,RateTypeName
		  ,RateDetail.Sequence
		  ,RateDetail.ContractedRate
		  ,RateDetail.RatePrice
		  ,RateDetail.RateQuantity
		  ,RateDetail.UnitOfMeasure
		  ,RateDetail.UnitOfMeasureSource
		  ,CASE 
				WHEN RateDetail.UnitOfMeasure = 'Each' THEN 1 
				WHEN RateDetail.UnitOfMeasure = 'Hour' THEN @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and ISNULL(RateDetail.RateQuantity,0) = 0 THEN @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) = 0 and ISNULL(@PrimaryCoverageLimitMileage,0) > 0 and @ServiceMiles > ISNULL(@PrimaryCoverageLimitMileage,0) THEN ISNULL(@PrimaryCoverageLimitMileage,0)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) = 0 THEN @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and ISNULL(RateDetail.RateQuantity,0) <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) <> 0 THEN (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END Quantity
	,ROUND(CASE 
		  WHEN RateDetail.UnitOfMeasure = 'Each' THEN RateDetail.RatePrice 
	WHEN RateDetail.UnitOfMeasure = 'Hour' THEN RateDetail.RatePrice * @EstimatedHours
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and ISNULL(RateDetail.RateQuantity,0) = 0 THEN RateDetail.RatePrice * @EnrouteMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) = 0 and ISNULL(@PrimaryCoverageLimitMileage,0) > 0 and @ServiceMiles > ISNULL(@PrimaryCoverageLimitMileage,0)  THEN RateDetail.RatePrice * ISNULL(@PrimaryCoverageLimitMileage,0)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) = 0 THEN RateDetail.RatePrice * @ServiceMiles
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Enroute' and ISNULL(RateDetail.RateQuantity,0) <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @EnrouteMiles THEN @EnrouteMiles ELSE RateDetail.RateQuantity END)
	WHEN RateDetail.UnitOfMeasure = 'Mile' and RateDetail.UnitOfMeasureSource = 'Service' and ISNULL(RateDetail.RateQuantity,0) <> 0 THEN RateDetail.RatePrice * (CASE WHEN RateDetail.RateQuantity > @ServiceMiles THEN @ServiceMiles ELSE RateDetail.RateQuantity END)
		  ELSE 0 END,2) ExtendedAmount
	,0 IsMemberPay
	INTO #PODetail
	FROM
		  (
		  Select 
				p.ID ProductID
				,p.Name ProductName
				,prt.RateTypeID 
				,rt.Name RateTypeName
				,prt.Sequence
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
						  ELSE 0 END AS ContractedRate
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Price
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Price
						  ELSE 0 END AS RatePrice
				,CASE WHEN VendorLocationRate.Price IS NOT NULL THEN VendorLocationRate.Quantity
						  WHEN VendorDefaultRate.Price IS NOT NULL THEN VendorDefaultRate.Quantity
						  ELSE 0 END AS RateQuantity
				,rt.UnitOfMeasure 
				,rt.UnitOfMeasureSource 
		  From dbo.Product p 
		  Join dbo.ProductRateType prt 
				On prt.ProductID = p.ID
		  Left Outer Join dbo.RateType rt 
				On prt.RateTypeID = rt.ID
		  LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorLocationRate 
				ON VendorLocationRate.VendorID = @VendorID AND 
				p.ID = VendorLocationRate.ProductID AND 
				prt.RateTypeID = VendorLocationRate.RateTypeID AND
				VendorLocationRate.VendorLocationID = @VendorLocationID 
		  LEFT OUTER JOIN dbo.fnGetCurrentProductRatesByVendorLocation() VendorDefaultRate
				ON VendorDefaultRate.VendorID = @VendorID AND 
				p.ID = VendorDefaultRate.ProductID AND 
				prt.RateTypeID = VendorDefaultRate.RateTypeID AND
				VendorDefaultRate.VendorLocationID IS NULL
		  WHERE p.id = @ProductID
				and prt.IsOptional = 0
		  ) RateDetail
	--TP: Add logic to eliminate Free Mile rates without mile quantity; Causing all miles to be free
	WHERE (RateDetail.RateTypeID <> @EnrouteFreeRateTypeID OR ISNULL(RateDetail.RateQuantity,0) <> 0)
	AND (RateDetail.RateTypeID <> @ServiceFreeRateTypeID OR ISNULL(RateDetail.RateQuantity,0) <> 0)

	--TP: Added logic to inject additional Member Pay line item for over program towing limit
	IF @PrimaryCoverageLimitMileage > 0 AND @ServiceMiles > @PrimaryCoverageLimitMileage
		INSERT INTO #PODetail
		SELECT VendorLocationID
			,ProductID
			,ProductName
			,RateTypeID
			,RateTypeName
			,Sequence
			,ContractedRate
			,RatePrice
			,RateQuantity
			,UnitOfMeasure
			,UnitOfMeasureSource
			,(@ServiceMiles - @PrimaryCoverageLimitMileage) Quantity
			,(@ServiceMiles - @PrimaryCoverageLimitMileage) * RatePrice ExtendedAmount
			,IsMemberPay = 1
		FROM #PODetail 
		WHERE RateTypeName = 'Service'
		ORDER BY Sequence

	SELECT 
		VendorLocationID
		,ProductID
		,ProductName
		,RateTypeID
		,RateTypeName
		,Sequence
		,ContractedRate
		,RatePrice
		,RateQuantity
		,UnitOfMeasure
		,UnitOfMeasureSource
		,Quantity
		,ExtendedAmount
		,IsMemberPay 
	FROM #PODetail
	ORDER BY Sequence

	DROP TABLE #PODetail
	

END
GO
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
[IsPossibleCallback] [bit] NOT NULL  
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
[IsInProductSearchRadius] [bit] NULL  
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
[IsProductMatch] [int] NOT NULL  
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
            ,v.Name VendorName    
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
FROM  #tmpVendorLocation tvl  
JOIN  dbo.VendorLocation vl on tvl.VendorLocationID = vl.ID   
JOIN  dbo.Vendor v  ON vl.VendorID = v.ID    
-- TP - Eliminate join duplication due to multiple dispatch numbers  
--JOIN (  
-- SELECT EntityID, RecordID, MAX(PhoneNumber) PhoneNumber  
-- FROM dbo.[PhoneEntity]   
-- WHERE EntityID = @VendorLocationEntityID  
-- AND PhoneTypeID = @DispatchPhoneTypeID  
-- GROUP BY EntityID, RecordID  
-- ) ph ON ph.RecordID = vl.ID     
JOIN  dbo.VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1  
JOIN  dbo.Product p ON p.ID = vlp.ProductID    
JOIN  dbo.ProductRateType prt ON prt.ProductID = p.ID AND   prt.IsOptional = 0   
JOIN  dbo.RateType rt ON prt.RateTypeID = rt.ID    
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON
	v.ID = ContractedVendors.VendorID    
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
  
ORDER BY WiseScore DESC, EstimatedPrice, EnrouteMiles, ProductRating DESC    
  
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
      ISP.IsInProductSearchRadius DESC,  
      ISP.WiseScore DESC,   
      ISP.EstimatedPrice,   
      ISP.EnrouteMiles,   
      ISP.ProductRating DESC   
  
/* Return results */  
SELECT      ISP.*   
FROM  @ISPSelectionFinalResults ISP  
ORDER BY      
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
 WHERE id = object_id(N'[dbo].[dms_map_callHistory]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_map_callHistory]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

--EXEC dms_map_callHistory 310804
CREATE PROC [dbo].[dms_map_callHistory](@ServiceRequestID AS INT = NULL)  
AS  
BEGIN  
SET FMTONLY  OFF
-- FOR Program Dynamci Values 
-- Sanghi 02.15.2013
;with wprogramDynamicValues AS(
SELECT PDI.Label,
	   PDIVE.Value,
	   PDIVE.RecordID AS 'ContactLogID'
	   FROM ProgramDataItem PDI
JOIN ProgramDataItemValueEntity PDIVE 
ON PDI.ID = PDIVE.ProgramDataItemID
WHERE PDIVE.Value IS NOT NULL AND PDIVE.Value != ''
AND PDIVE.EntityID = (SELECT ID FROM Entity WHERE Name = 'ContactLog')
) SELECT ContactLogID,
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
	   
SELECT CC.Description AS ContactCategory  
, CL.Company AS CompanyName  
, CL.PhoneNumber AS PhoneNumber  
, CL.TalkedTo AS TalkedTo  
, CL.Comments AS Comments  
, CL.CreateDate AS CreateDate  
, CL.CreateBy AS CreateBy  
, CR.Name AS Reason  
--, CA.Name ASAction -- TFS: 396
, CA.[Description] AS ASAction -- TFS: 396
, CLL.RecordID AS ServiceRequestID
, VCLL.RecordID AS VendorLocationID
, CPDV.Question
, CPDV.Answer
FROM ContactLog CL WITH (NOLOCK)
JOIN ContactLogLink CLL WITH (NOLOCK) ON CLL.ContactLogID = CL.ID
LEFT OUTER JOIN ContactLogLink VCLL WITH (NOLOCK) ON VCLL.ContactLogID = CL.ID AND   VCLL.EntityID=((Select ID From Entity Where Name ='VendorLocation')  ) 
JOIN ContactCategory CC WITH (NOLOCK) ON CC.ID = CL.ContactCategoryID  
JOIN ContactLogReason CLR WITH (NOLOCK) ON CLR.ContactLogID = CL.ID  
JOIN ContactReason CR WITH (NOLOCK) ON CR.ID = CLR.ContactReasonID  
JOIN ContactLogAction CLA WITH (NOLOCK) on CLA.ContactLogID = CL.ID  
JOIN ContactAction CA WITH (NOLOCK) on CA.ID = CLA.ContactActionID  
LEFT JOIN #CustomProgramDynamicValues CPDV ON CPDV.ContactLogID = CL.ID
WHERE  
CLL.RecordID = @ServiceRequestID AND CLL.EntityID =(Select ID From Entity Where Name ='ServiceRequest')  
AND CC.ID =(Select ID From ContactCategory Where Name ='ServiceLocationSelection')  
ORDER BY  
CL.CreateDate DESC  

DROP TABLE #CustomProgramDynamicValues
END


GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Mobile_Configuration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Mobile_Configuration] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 /*
 *	-- KB : Added two parameters - memberID and membershipID.
 *	The stored procedure will be called in two cases:
 *	1. Lookup a mobile  / prior Case record using the callback number
 *	2. The stored procedure might return multiple member records when there are multiple matching Case records.
 *	3. The application allows user to pick one member from a prior case record and this sp would then be invoked just to update the related inbound call record.
 */
CREATE PROC dms_Mobile_Configuration(@programID INT = NULL,  
          @configurationType nvarchar(50) = NULL,  
          @configurationCategory nvarchar(50) = NULL,  
          @callBackNumber nvarchar(50) = NULL,  
          @inBoundCallID INT = NULL,
		  @memberID INT = NULL,
		  @membershipID INT = NULL)  
AS  
BEGIN  
	--Declare
	--@programID INT = 286,  
	--@configurationType nvarchar(50) = 5,  
	--@configurationCategory nvarchar(50) = 3,  
	--@callBackNumber nvarchar(50) = '1 9858791084',  
	--@inBoundCallID INT = 509092,
	--@memberID INT = NULL, --16432463,
	--@membershipID INT = NULL --14802600  
		  
	SET FMTONLY OFF  
	-- Output Values   
	DECLARE @unformattedNumber nvarchar(50) = NULL  
	DECLARE @isMobileEnabled BIT = NULL  
	DECLARE @searchCaseRecords BIT = 1
	DECLARE @appOrgName NVARCHAR(100) = NULL

	-- Temporary Holders  
	DECLARE       @ProgramInformation_Temp TABLE(  
		Name  NVARCHAR(MAX),  
		Value NVARCHAR(MAX),  
		ControlType INT NULL,  
		DataType NVARCHAR(MAX) NULL,  
		Sequence INT NULL,
		ProgramLevel INT NULL)  
	 
	 -- Lakshmi - Added on 7/24/14
	 DECLARE  @GetPrograms_Temp TABLE(  
		ProgramID INT NULL )  
	 
	DECLARE @Mobile_CallForService_Temp TABLE(  
		[PKID] [int]  NULL,  
		[MemberNumber] [nvarchar](50) NULL,  
		[GUID] [nvarchar](50) NULL,  
		[FirstName] [nvarchar](50) NULL,  
		[LastName] [nvarchar](50) NULL,  
		[MemberDevicePhoneNumber] [nvarchar](20) NULL,  
		[locationLatitude] [nvarchar](10) NULL,  
		[locationLongtitude] [nvarchar](10) NULL,  
		[serviceType] [nvarchar](100) NULL,  
		[ErrorCode] [int] NULL,  
		[ErrorMessage] [nvarchar](200) NULL,  
		[DateTime] [datetime] NULL,  
		[IsMobileEnabled] BIT,  
		[MemberID] INT,  
		[MembershipID] INT)  
 

	IF ( @memberID IS NOT NULL)
		BEGIN
			
			UPDATE	InboundCall 
			SET		MemberID = @memberID   		
			WHERE	ID = @inBoundCallID 

			INSERT INTO @Mobile_CallForService_Temp
				([MemberID],[MembershipID],[IsMobileEnabled]) 
			VALUES
				(@memberID,@membershipID,@isMobileEnabled) 

		END
	ELSE
		BEGIN


			DECLARE @charIndex INT = 0  
			SELECT @charIndex = CHARINDEX('x',@callBackNumber,0)  

			IF @charIndex = 0  
				BEGIN  
					SET @charIndex = LEN(@callBackNumber)  
				END  
			ELSE  
				BEGIN  
					SET @charIndex = @charIndex -1  
				END  

		-- DEBUG:
		--PRINT @charIndex  
		--SELECT @callBackNumber
		
			SELECT @unformattedNumber = SUBSTRING(@callBackNumber,1,@charIndex)  
			SET @charIndex = 0  
			SELECT @charIndex = CHARINDEX(' ',@unformattedNumber,0)  
			SELECT @unformattedNumber = LTRIM(RTRIM(SUBSTRING(@unformattedNumber, @charIndex + 1, LEN(@unformattedNumber) - @charIndex)))  

		--DEBUG:
		--SELECT @unformattedNumber As UnformattedNumber, @callBackNumber AS CallbackNumber

	 
		-- Step 1 : Get the Program Information  
			;with wResultB AS  
			(    
				SELECT PC.Name,     
				PC.Value,     
				CT.Name AS ControlType,     
				DT.Name AS DataType,      
				PC.Sequence AS Sequence	,
				ROW_NUMBER() OVER ( PARTITION BY PC.Name ORDER BY PP.Sequence) AS [ProgramLevel]			    
				FROM ProgramConfiguration PC    
				 JOIN dbo.fnc_GetProgramsandParents(@programID)PP ON PP.ProgramID=PC.ProgramID    
				 JOIN [dbo].[fnc_GetProgramConfigurationForProgram](@programID,@configurationType) P ON P.ProgramConfigurationID = PC.ID    
				 LEFT JOIN ControlType CT ON PC.ControlTypeID = CT.ID    
				 LEFT JOIN DataType DT ON PC.DataTypeID = DT.ID    
			)  
			INSERT INTO @ProgramInformation_Temp SELECT * FROM wResultB  ORDER BY ProgramLevel, Sequence, Name   
		
			-- CR : 1225 - Start Tab - change process to lookup mobile phone number to incorporate appOrgName
			SELECT @appOrgName = Value FROM @ProgramInformation_Temp WHERE ProgramLevel = 1 AND Name = 'MobileAppOrg'
		
			--Lakshmi - Added on 7/24/2014
			INSERT INTO @GetPrograms_Temp ([ProgramID]) 
			((SELECT ProgramID FROM fnc_GetChildPrograms(@programID)
			UNION
			SELECT ProgramID FROM MemberSearchProgramGrouping
			WHERE ProgramID in(SELECT ProgramID FROM fnc_GetChildPrograms(@programID))))
		
			--DEBUG:  
			-- SELECT @appOrgName
			--SELECT * FROM @ProgramInformation_Temp  
	 
			--Step 2 :  
			-- Check Mobile is Enabled or NOT  
			IF EXISTS(SELECT * FROM @ProgramInformation_Temp WHERE Name = 'IsMobileEnabled' AND Value = 'yes')  
			BEGIN  
			--DEBUG:
			--PRINT 'Mobile config found'
				SET @isMobileEnabled = 1  
				SET @unformattedNumber  =  RTRIM(LTRIM(@unformattedNumber))  
				-- Get the Details FROM Mobile_CallForService  
				SELECT TOP 1 *  INTO #Mobile_CallForService_Temp  
					FROM Mobile_CallForService M  
					WHERE REPLACE(M.MemberDevicePhoneNumber,'-','') = @unformattedNumber  
					AND DATEDIFF(hh,M.[DateTime],GETDATE()) < 1  
					AND ISNULL(M.ErrorCode,0) = 0  
					AND appOrgName = @appOrgName -- CR : 1225 - Start Tab - change process to lookup mobile phone number to incorporate appOrgName
					ORDER BY M.[DateTime] DESC  

				IF((SELECT COUNT(*) FROM #Mobile_CallForService_Temp) >= 1)  
				BEGIN  
					--DEBUG:
					--PRINT 'Mobile record found'
				
					SET @searchCaseRecords = 0
				
					-- Try to find the member using the member number.
					
					INSERT INTO @Mobile_CallForService_Temp
								([MemberID],[MembershipID],[IsMobileEnabled]) 
					  
						SELECT DISTINCT M.ID, 
						M.MembershipID ,
						@isMobileEnabled
						FROM Membership MS 
						JOIN Member M ON MS.ID = M.MembershipID 
						JOIN Program P ON M.ProgramID=P.ID
						WHERE M.IsPrimary = 1 
						AND MS.MembershipNumber = 
						(SELECT MemberNumber FROM #Mobile_CallForService_Temp where membernumber IS NOT NULL AND memberNumber <> '') 
						AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))
	  
							
					IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
					BEGIN
			        
						UPDATE InboundCall SET MemberID = @memberID,
							 MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
							WHERE ID = @inBoundCallID 

						-- Create a case phone location record when there is lat/long information.
						IF EXISTS(	SELECT * FROM #Mobile_CallForService_Temp   
								WHERE ISNULL(locationLatitude,'') <> ''  
								AND ISNULL(locationLongtitude,'') <> ''  
							)  
						BEGIN
							INSERT INTO CasePhoneLocation(	CaseID,  
														PhoneNumber,  
														CivicLatitude,  
														CivicLongitude,  
														IsSMSAvailable,  
														LocationDate,  
														LocationAccuracy,  
														InboundCallID,  
														PhoneTypeID,  
														CreateDate)   
														VALUES(NULL,  
														@callBackNumber,  
														(SELECT  locationLatitude FROM #Mobile_CallForService_Temp),  
														(SELECT  locationLongtitude FROM #Mobile_CallForService_Temp),  
														1,  
														(SELECT  [DateTime] FROM #Mobile_CallForService_Temp),  
														'mobile',  
														@inBoundCallID,  
														(SELECT ID FROM PhoneType WHERE Name = 'Cell'),  
														GETDATE()  
														)  
						END
					END

					IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp) > 1)
					BEGIN
						--PRINT 'Update Inbound Call'
						UPDATE InboundCall 
						SET  MobileID = (SELECT PKID FROM #Mobile_CallForService_Temp)  
						WHERE ID = @inBoundCallID  
					END
				
					IF @memberID IS NULL
					BEGIN
						-- Search in prior cases when you don't get a member using the membernumber from the mobile record.
						SET @searchCaseRecords = 1 
					END
				
					DROP TABLE #Mobile_CallForService_Temp
			
				END  
				
			END
		
			IF ( @searchCaseRecords = 1 )  
			BEGIN 
				--PRINT 'Search Case Records'
		
				INSERT INTO @Mobile_CallForService_Temp
									([MemberID],[MembershipID],[IsMobileEnabled]) 
					SELECT  DISTINCT M.ID,   
									M.MembershipID,
									@isMobileEnabled
					FROM [Case] C  
					JOIN Member M ON C.MemberID = M.ID 
					JOIN Program P ON M.ProgramID=P.ID		--Lakshmi
					WHERE C.ContactPhoneNumber = @callBackNumber 
					AND (ISNULL(@ProgramID,0) = 0 OR M.ProgramID IN (SELECT * FROM @GetPrograms_Temp))
					ORDER BY ID DESC
					
				IF((SELECT COUNT(*) FROM @Mobile_CallForService_Temp)= 0 OR (SELECT COUNT(*) FROM @Mobile_CallForService_Temp) = 1) 
				BEGIN
					--PRINT 'Update Inbound Call'
					UPDATE InboundCall 
					SET MemberID = @memberID   		
					WHERE ID = @inBoundCallID  
				END
			END  

		-- If one of the matching member IDs has an open SR then only return the associated Member, otherwise return all matching Members
		IF EXISTS (
			SELECT temp.*
			FROM @Mobile_CallForService_Temp temp
			JOIN [Case] c ON temp.MemberID = c.MemberID
			JOIN ServiceRequest sr ON c.ID = sr.CaseID
			WHERE sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Entry','Submitted','Dispatched'))
			)
			SELECT temp.*
			FROM @Mobile_CallForService_Temp temp
			JOIN [Case] c ON temp.MemberID = c.MemberID
			JOIN ServiceRequest sr ON c.ID = sr.CaseID
			WHERE sr.ServiceRequestStatusID IN (SELECT ID FROM ServiceRequestStatus WHERE Name IN ('Entry','Submitted','Dispatched'))
		ELSE
			SELECT * FROM @Mobile_CallForService_Temp     
	END     

END

GO
/****** Object:  StoredProcedure [dbo].[dms_Process_Vendor_Insurance_Expiration]    Script Date: 04/29/2014 02:13:23 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Process_Vendor_Insurance_Expiration]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Process_Vendor_Insurance_Expiration] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--EXEC [dms_Process_Vendor_Insurance_Expiration]
 CREATE PROCEDURE [dbo].[dms_Process_Vendor_Insurance_Expiration]
 AS 
 BEGIN 
 
    DECLARE @VendorsInsuranceExpired AS TABLE( 
	ID int NOT NULL IDENTITY(1,1),
	VendorID INT NOT NULL)
	
    DECLARE @VendorsInsuranceExpiring AS TABLE( 
	ID int NOT NULL IDENTITY(1,1),
	VendorID INT NOT NULL)
	

	INSERT INTO @VendorsInsuranceExpired
	SELECT ID FROM Vendor WHERE InsuranceExpirationDate IS NOT NULL AND InsuranceExpirationDate <= GETDATE()

	INSERT INTO @VendorsInsuranceExpiring
	SELECT ID FROM Vendor WHERE InsuranceExpirationDate IS NOT NULL AND 
																		InsuranceExpirationDate < DATEADD(dd,30,GETDATE()) 
																	AND InsuranceExpirationDate >= GETDATE()
	
	--SELECT * FROM @VendorsInsuranceExpired
	--SELECT * FROM @VendorsInsuranceExpiring
	
	
	DECLARE  @counter AS INT
	DECLARE  @maxItem AS INT
	DECLARE @vendorID AS INT
	SET @counter = 1
	SET @maxItem = (SELECT MAX(ID) FROM @VendorsInsuranceExpired)
	

		DECLARE @insuranceExpireDate DATETIME =NULL
		DECLARE @vendorName NVARCHAR(100) = NULL
		DECLARE @vendorNumber NVARCHAR(100) = NULL
		DECLARE @contactFirstName NVARCHAR(100) =NULL
		DECLARE @contactLastName NVARCHAR(100) = NULL
		DECLARE @regionName NVARCHAR(100) = NULL
		DECLARE @Email NVARCHAR(100) =NULL
		DECLARE @PhoneNumber NVARCHAR(100) =NULL
		DECLARE @vendorRegionID INT = NULL
		DECLARE @vendorRegionEntityID INT = NULL
		DECLARE @officePhoneTypeID INT = NULL
		DECLARE @faxPhoneTypeID INT = NULL
		
		DECLARE @officePhone NVARCHAR(100) = NULL
		DECLARE @faxPhone NVARCHAR(100) = NULL
		
		DECLARE @messageData NVARCHAR(MAX) = NULL

	WHILE @counter <= @maxItem
	BEGIN
		SET @vendorID = (SELECT VendorID FROM @VendorsInsuranceExpired WHERE ID = @counter)
		SET @counter =  @counter + 1
		
		
		SET @insuranceExpireDate = (Select TOP 1 InsuranceExpirationDate from Vendor where ID = @vendorID)
		SET @vendorName  = (Select TOP 1 Name from Vendor where ID = @vendorID)
		SET @vendorNumber = (Select TOP 1 VendorNumber from Vendor where ID = @vendorID)
		SET @contactFirstName = (Select TOP 1 ContactFirstName from VendorRegion where ID = (Select  TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @contactLastName  = (Select TOP 1 ContactLastName from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @regionName  = (Select TOP 1 Name from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @Email = (Select TOP 1 Email from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @PhoneNumber = (Select TOP 1 PhoneNumber from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @vendorRegionID  = (Select TOP 1 ID from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @vendorRegionEntityID  = (Select top 1  ID from Entity where Name='VendorRegion')
		SET @officePhoneTypeID  = (SELECT top 1 ID from PhoneType where Name = 'Office')
		SET @faxPhoneTypeID  = (SELECT top 1 ID from PhoneType where Name = 'FAX')
		
		SET @officePhone = (Select TOP 1 PhoneNumber from PhoneEntity where EntityID = @vendorRegionEntityID AND RecordID = @vendorRegionID AND PhoneTypeID = @officePhoneTypeID)
		SET @faxPhone = (Select TOP 1 PhoneNumber from PhoneEntity where EntityID = @vendorRegionEntityID AND RecordID = @vendorRegionID AND PhoneTypeID = @faxPhoneTypeID)
		
		
		SET @messageData =  '<MessageData>'
		SET @messageData = @messageData + '<VendorName>'+ISNULL(@vendorName,'')+'</VendorName>'
		SET @messageData = @messageData + '<InsuranceExpireDate>'+CAST(ISNULL(@insuranceExpireDate,GETDATE()) AS NVARCHAR)+'</InsuranceExpireDate>'
		SET @messageData = @messageData + '<VendorNumber>'+ISNULL(@vendorNumber,'')+'</VendorNumber>'
		SET @messageData = @messageData + '<ContactFirstName>'+ISNULL(@contactFirstName,'')+'</ContactFirstName>'
		SET @messageData = @messageData + '<ContactLastName>'+ISNULL(@contactLastName,'')+'</ContactLastName>'
		SET @messageData = @messageData + '<RegionName>'+ISNULL(@regionName,'')+'</RegionName>'
		SET @messageData = @messageData + '<Email>'+ISNULL(@Email,'')+'</Email>'
		SET @messageData = @messageData + '<PhoneNumber>'+ISNULL(@PhoneNumber,'')+'</PhoneNumber>'
		SET @messageData = @messageData + '<Office>'+ISNULL(@officePhone,'')+'</Office>'
		SET @messageData = @messageData + '<fax>'+ISNULL(@faxPhone,'')+'</fax>'
		
		INSERT INTO EventLog (EventID,
						[Description],
						[Data],
						NotificationQueueDate,
						CreateDate,
						CreateBy)
			VALUES(
			(SELECT ID FROM [Event] WHERE Name='InsuranceExpired'),
			(SELECT [Description] FROM [Event] WHERE Name='InsuranceExpired'),
			@messageData,
			NULL,
			GETDATE(),
			'system'
			)
		INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
		VALUES(
			SCOPE_IDENTITY(),
			(SELECT ID FROM Entity where Name='Vendor'),
			@vendorID
		)
	END
	
	SET @counter = 1
	SET @maxItem = (SELECT MAX(ID) FROM @VendorsInsuranceExpiring)
	
	WHILE @counter <= @maxItem
	BEGIN
		SET @vendorID = (SELECT VendorID FROM @VendorsInsuranceExpiring WHERE ID = @counter)
		SET @counter =  @counter + 1
		
		
		SET @insuranceExpireDate = (Select TOP 1 InsuranceExpirationDate from Vendor where ID = @vendorID)
		SET @vendorName  = (Select TOP 1 Name from Vendor where ID = @vendorID)
		SET @vendorNumber = (Select TOP 1 VendorNumber from Vendor where ID = @vendorID)
		SET @contactFirstName = (Select TOP 1 ContactFirstName from VendorRegion where ID = (Select  TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @contactLastName  = (Select TOP 1 ContactLastName from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @regionName  = (Select TOP 1 Name from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @Email = (Select TOP 1 Email from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @PhoneNumber = (Select TOP 1 PhoneNumber from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @vendorRegionID  = (Select TOP 1 ID from VendorRegion where ID = (Select TOP 1 VendorRegionID from Vendor where ID = @vendorID))
		SET @vendorRegionEntityID  = (Select top 1  ID from Entity where Name='VendorRegion')
		SET @officePhoneTypeID  = (SELECT top 1 ID from PhoneType where Name = 'Office')
		SET @faxPhoneTypeID  = (SELECT top 1 ID from PhoneType where Name = 'FAX')
		
		SET @officePhone = (Select TOP 1 PhoneNumber from PhoneEntity where EntityID = @vendorRegionEntityID AND RecordID = @vendorRegionID AND PhoneTypeID = @officePhoneTypeID)
		SET @faxPhone = (Select TOP 1 PhoneNumber from PhoneEntity where EntityID = @vendorRegionEntityID AND RecordID = @vendorRegionID AND PhoneTypeID = @faxPhoneTypeID)
		
		
		SET @messageData =  '<MessageData>'
		SET @messageData = @messageData + '<VendorName>'+ISNULL(@vendorName,'')+'</VendorName>'
		SET @messageData = @messageData + '<InsuranceExpireDate>'+CAST(ISNULL(@insuranceExpireDate,GETDATE()) AS NVARCHAR)+'</InsuranceExpireDate>'
		SET @messageData = @messageData + '<VendorNumber>'+ISNULL(@vendorNumber,'')+'</VendorNumber>'
		SET @messageData = @messageData + '<ContactFirstName>'+ISNULL(@contactFirstName,'')+'</ContactFirstName>'
		SET @messageData = @messageData + '<ContactLastName>'+ISNULL(@contactLastName,'')+'</ContactLastName>'
		SET @messageData = @messageData + '<RegionName>'+ISNULL(@regionName,'')+'</RegionName>'
		SET @messageData = @messageData + '<Email>'+ISNULL(@Email,'')+'</Email>'
		SET @messageData = @messageData + '<PhoneNumber>'+ISNULL(@PhoneNumber,'')+'</PhoneNumber>'
		SET @messageData = @messageData + '<Office>'+ISNULL(@officePhone,'')+'</Office>'
		SET @messageData = @messageData + '<fax>'+ISNULL(@faxPhone,'')+'</fax>'
		--PRINT @messageData
		
		
		INSERT INTO EventLog (EventID,
						[Description],
						[Data],
						NotificationQueueDate,
						CreateDate,
						CreateBy)
			VALUES(
			(SELECT ID FROM [Event] WHERE Name='InsuranceExpiring'),
			(SELECT [Description] FROM [Event] WHERE Name='InsuranceExpiring'),
			@messageData,
			NULL,
			GETDATE(),
			'system'
			)
		INSERT INTO EventLogLink(EventLogID,EntityID,RecordID)
		VALUES(
			SCOPE_IDENTITY(),
			(SELECT ID FROM Entity where Name='Vendor'),
			@vendorID
		)
	END
		
		

	UPDATE
		VendorUser
	SET
		PostLoginPromptID = (SELECT ID  FROM PostLoginPrompt where Name ='InsuranceExpiring')
	FROM
		@VendorsInsuranceExpired VIE 
	INNER JOIN
		VendorUser VU
	ON 
		VU.VendorID = VIE.VendorID
    
    
	UPDATE
		VendorUser
	SET
		PostLoginPromptID = (SELECT ID  FROM PostLoginPrompt where Name ='InsuranceExpiring')
	FROM
		VendorUser VU
	INNER JOIN
		@VendorsInsuranceExpiring VIE 
	ON 
		VU.VendorID = VIE.VendorID

END
GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_program_productcategory_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_program_productcategory_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_program_productcategory_get] 1,NULL,NULL
 
CREATE PROCEDURE [dbo].[dms_program_productcategory_get]( 
   @ProgramID int, 
   @vehicleTypeID INT = NULL,
   @vehicleCategoryID INT = NULL   
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

	SELECT	PC.ID,
			PC.Name,
			PC.Sequence,
			CASE WHEN EL.ID IS NULL 
				THEN CAST(0 AS BIT)
				ELSE CAST(1 AS BIT)
			END AS [Enabled],
			PC.IsVehicleRequired
	FROM	ProductCategory PC 
	LEFT JOIN
	(	SELECT DISTINCT ProductCategoryID AS ID 
		FROM	ProgramProductCategory PC
		JOIN	[dbo].[fnc_getprogramsandparents](@ProgramID) FNCP ON PC.ProgramID = FNCP.ProgramID
		AND		(VehicleTypeID = @vehicleTypeID OR VehicleTypeID IS NULL)
		AND		(VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)

	
	) EL ON PC.ID = EL.ID
	ORDER BY PC.Sequence

END
GO

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_PurchaseOrderTemplate_select]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_PurchaseOrderTemplate_select]
GO
/****** Object:  StoredProcedure [dbo].[dms_users_list]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC [dms_PurchaseOrderTemplate_select] 108,1
CREATE PROCEDURE [dbo].[dms_PurchaseOrderTemplate_select]   
   @PurchaseOrderID int,  
   @ContactLogID int  
 AS   
 BEGIN   
    
 SET NOCOUNT ON  
  
DECLARE @TalkedTo nvarchar(50)  
DECLARE @FaxNo nvarchar(50)  
DECLARE @VendorCallback nvarchar(50)
DECLARE @VendorBilling nvarchar(50)
  
SELECT @TalkedTo = CL.TalkedTo,   
@FaxNo = REPLACE(CL.PhoneNumber, ' ','')   
FROM ContactLog CL  
WHERE CL.ID = @ContactLogID  
  
 
SELECT   
@TalkedTo as POTo,  
V.Name as VendorName,  
V.VendorNumber,  
@FaxNo as FaxPhoneNumber,  
ACFrom.Value as POFrom,  
ACVendorCallbackPhone.Value as VendorCallback,
ACBilling.Value as VendorBilling,
PO.IssueDate,  
--CONVERT(VARCHAR(8), PO.IssueDate, 108) + '-' + CONVERT(VARCHAR(10), PO.IssueDate, 101) as IssueDate,
PO.PurchaseOrderNumber,  
PO.CreateBy as OpenedBy,  
COALESCE(PC.Name, PC2.Name) as ServiceName,  
PO.EtaMinutes,  
CASE WHEN Isnull(C.IsSafe,1) = 1 THEN 'Y'  
ELSE 'N'  
END AS Safe,  
CASE WHEN Isnull(PO.IsMemberAmountCollectedByVendor,0) = 1 THEN 'Y'  
ELSE 'N'  
END AS MemberPay,  
REPLACE(RTRIM(COALESCE(M.FirstName, '') +     
          COALESCE(' ' + LEFT(M.MiddleName,1), '') +    
          COALESCE(' ' + M.LastName, '')), '  ', ' ')     
          as MemberName,     
MS.MembershipNumber,  
dbo.fnc_FormatPhoneNumber(C.ContactPhoneNumber,0) as ContactPhoneNumber,  
dbo.fnc_FormatPhoneNumber(C.ContactAltPhoneNumber,0) as ContactAltPhoneNumber,  
SR.ServiceLocationDescription,  
SR.ServiceLocationAddress,  
SR.ServiceLocationCrossStreet1 + COALESCE(' & ' + SR.ServicelocationCrossStreet2, '') as ServiceLocationCrossStreet,  
SR.ServiceLocationCity + ', ' + ServiceLocationStateProvince as CityState,  
SR.ServiceLocationPostalCode as Zip,  
SR.DestinationDescription,  
SR.DestinationAddress,  
SR.DestinationCrossStreet1 + COALESCE(' & ' + SR.DestinationCrossStreet2, '') as DestinationCrossStreet,  
SR.DestinationCity + ', ' + ServiceLocationStateProvince as DestinationCityState,  
SR.DestinationPostalCode as DestinationZip,  
C.VehicleYear,   
--C.VehicleMake,  
--C.VehicleModel,  
CASE c.VehicleMake WHEN 'Other' THEN C.VehicleMakeOther ELSE C.VehicleMake END AS VehicleMake,
CASE C.VehicleModel WHEN 'Other' THEN C.VehicleModelOther ELSE C.VehicleModel END AS VehicleModel,
C.VehicleDescription,  
C.VehicleColor,  
C.VehicleLicenseState + COALESCE('/' + C.VehicleLicenseNumber,'') as License,  
C.VehicleVIN,  
C.VehicleChassis,  
C.VehicleLength,  
C.VehicleEngine,  
REPLACE(RVT.Name,'Class','') as Class  
FROM PurchaseOrder PO  
JOIN ServiceRequest SR ON PO.ServiceRequestID = SR.ID  
JOIN [Case] C ON C.ID = SR.CaseID   
JOIN VendorLocation VL on VL.ID = PO.VendorLocationID   
JOIN Vendor V on V.ID = VL.VendorID   
JOIN ApplicationConfiguration ACFrom ON ACFrom.Name = 'POFaxFrom'  
JOIN ApplicationConfiguration ACVendorCallbackPhone ON ACVendorCallbackPhone.Name = 'VendorCallback'  
JOIN ApplicationConfiguration ACBilling ON ACBilling.Name = 'VendorBilling'  
LEFT JOIN Product P ON P.ID = PO.ProductID
LEFT JOIN ProductCategory PC ON PC.ID = P.ProductCategoryID
JOIN ProductCategory PC2 ON PC2.ID = SR.ProductCategoryID
JOIN Member M on M.ID = C.MemberID   
JOIN Membership MS ON MS.ID = M.MembershipID   
LEFT JOIN RVType RVT ON RVT.ID = C.VehicleRVTypeID   
WHERE PO.ID = @PurchaseOrderID   
  
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
 WHERE id = object_id(N'[dbo].[dms_queue_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_queue_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC', @whereClauseXML = '<ROW><Filter RequestNumberOperator="4" RequestNumberValue="4"></Filter></ROW>'
-- EXEC [dbo].[dms_queue_list] @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB', @sortColumn='RequestNumber',@sortOrder = 'ASC',@whereClauseXML = '<ROW><Filter StatusOperator="11" StatusValue="Cancelled"></Filter></ROW>'
 CREATE PROCEDURE [dbo].[dms_queue_list](   
   @userID UNIQUEIDENTIFIER = NULL  
 , @whereClauseXML NVARCHAR(4000) = NULL   
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 100    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = 'ASC'   
    
 )   
 AS   
 BEGIN   
    
SET NOCOUNT ON  
SET FMTONLY OFF  

CREATE TABLE #FinalResultsFiltered (  
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
FirstName nvarchar(50)  NULL ,    
LastName nvarchar(50)  NULL , 
MiddleName   nvarchar(50)  NULL ,   
Suffix nvarchar(50)  NULL ,    
Prefix nvarchar(50)  NULL ,  
SubmittedOriginal DATETIME, 
SecondaryProductID INT NULL,   
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
IsRedispatched BIT NULL,
AssignedToUserID INT NULL,
NextActionAssignedToUserID INT NULL,
ClosedLoop nvarchar(100) NULL ,  
PONumber nvarchar(50) NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
NextActionID INT NULL,  
ClosedLoopID INT NULL,  
ServiceTypeID INT NULL,  
MemberNumber NVARCHAR(50) NULL,  
PriorityID INT NULL,  
[Priority] NVARCHAR(255) NULL,   
ScheduledOriginal DATETIME NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL,  -- Added by Lakshmi - Queue Color
PrioritySort INT NULL,             -- Added by Phani - TFS 442
NextActionScheduledDate DATETIME NULL,     -- Added by Phani - TFS 442
ScheduleDateSort DATETIME NULL
)  
  
CREATE TABLE #FinalResultsFormatted (    
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
Member nvarchar(max) NULL ,  
Submitted nvarchar(100) NULL ,  
SubmittedOriginal DATETIME,  
Elapsed NVARCHAR(10),  
ElapsedOriginal bigint,  
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
AssignedTo nvarchar(100) NULL ,  
ClosedLoop nvarchar(100) NULL ,  
PONumber int NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
MemberNumber NVARCHAR(50) NULL,  
[Priority] NVARCHAR(255) NULL,  
[Scheduled] nvarchar(100) NULL,  
ScheduledOriginal DATETIME  NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
)  

CREATE TABLE #FinalResultsSorted (  
[RowNum] [bigint] NOT NULL IDENTITY(1,1),  
[Case] int NULL ,  
RequestNumber int NULL ,  
Client nvarchar(100) NULL ,  
Member nvarchar(max) NULL ,  
Submitted nvarchar(100) NULL ,  
SubmittedOriginal DATETIME,  
Elapsed NVARCHAR(10),  
ElapsedOriginal bigint,  
ServiceType nvarchar(100) NULL ,  
[Status] nvarchar(100) NULL ,  
AssignedTo nvarchar(100) NULL ,  
ClosedLoop nvarchar(100) NULL ,  
PONumber int NULL ,  
ISPName nvarchar(255) NULL ,  
CreateBy nvarchar(100) NULL ,  
NextAction nvarchar(MAX) NULL,  
MemberNumber NVARCHAR(50) NULL,  
[Priority] NVARCHAR(255) NULL,  
[Scheduled] nvarchar(100) NULL,  
ScheduledOriginal DATETIME NULL,
-- KB: Added extra IDs
ProgramName NVARCHAR(50) NULL,
ProgramID INT NULL,
MemberID INT NULL,
StatusDateModified DATETIME NULL  -- Added by Lakshmi - Queue Color
)
  
DECLARE @openedCount BIGINT = 0  
DECLARE @submittedCount BIGINT = 0  
  
DECLARE @dispatchedCount BIGINT = 0  
--  
DECLARE @completecount BIGINT = 0  
DECLARE @cancelledcount BIGINT = 0  
  
--DECLARE @scheduledCount BIGINT = 0  
  
DECLARE @queueDisplayHours INT  
DECLARE @now DATETIME  
  
SET @now = GETDATE()  
  
SET @queueDisplayHours = 0  
SELECT @queueDisplayHours = CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'QueueDisplayHours'  
  
DECLARE @idoc int  
IF @whereClauseXML IS NULL  
BEGIN  
SET @whereClauseXML = '<ROW><Filter  
CaseOperator="-1"  
RequestNumberOperator="-1"  
MemberOperator="-1"  
ServiceTypeOperator="-1"  
PONumberOperator="-1"  
ISPNameOperator="-1"  
CreateByOperator="-1"  
StatusOperator="-1"  
ClosedLoopOperator="-1"  
NextActionOperator="-1"  
AssignedToOperator="-1"  
></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
CaseOperator INT NOT NULL,  
CaseValue int NULL,  
RequestNumberOperator INT NOT NULL,  
RequestNumberValue int NULL,  
MemberOperator INT NOT NULL,  
MemberValue nvarchar(200) NULL,  
ServiceTypeOperator INT NOT NULL,  
ServiceTypeValue nvarchar(50) NULL,  
PONumberOperator INT NOT NULL,  
PONumberValue nvarchar(50) NULL,  
ISPNameOperator INT NOT NULL,  
ISPNameValue nvarchar(255) NULL,  
CreateByOperator INT NOT NULL,  
CreateByValue nvarchar(50) NULL,  
StatusOperator INT NOT NULL,  
StatusValue nvarchar(50) NULL,  
ClosedLoopOperator INT NOT NULL,  
ClosedLoopValue nvarchar(50) NULL,  
NextActionOperator INT NOT NULL,  
NextActionValue nvarchar(50) NULL,  
AssignedToOperator INT NOT NULL,  
AssignedToValue nvarchar(50) NULL,  
MemberNumberOperator INT NOT NULL,  
MemberNumberValue nvarchar(50) NULL,  
PriorityOperator INT NOT NULL,  
PriorityValue nvarchar(50) NULL  
)  
  
  
INSERT INTO @tmpForWhereClause  
SELECT  
ISNULL(CaseOperator,-1),  
CaseValue ,  
ISNULL(RequestNumberOperator,-1),  
RequestNumberValue ,  
ISNULL(MemberOperator,-1),  
MemberValue ,  
ISNULL(ServiceTypeOperator,-1),  
ServiceTypeValue ,  
ISNULL(PONumberOperator,-1),  
PONumberValue ,  
ISNULL(ISPNameOperator,-1),  
ISPNameValue ,  
ISNULL(CreateByOperator,-1),  
CreateByValue,  
ISNULL(StatusOperator,-1),  
StatusValue ,  
ISNULL(ClosedLoopOperator,-1),  
ClosedLoopValue,  
ISNULL(NextActionOperator,-1),  
NextActionValue,  
ISNULL(AssignedToOperator,-1),  
AssignedToValue,  
ISNULL(MemberNumberOperator,-1),  
MemberNumberValue,  
ISNULL(PriorityOperator,-1),  
PriorityValue  
  
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
CaseOperator INT,  
CaseValue int  
,RequestNumberOperator INT,  
RequestNumberValue int  
,MemberOperator INT,  
MemberValue nvarchar(200)  
,ServiceTypeOperator INT,  
ServiceTypeValue nvarchar(50)  
,PONumberOperator INT,  
PONumberValue nvarchar(50)  
,ISPNameOperator INT,  
ISPNameValue nvarchar(255)  
,CreateByOperator INT,  
CreateByValue nvarchar(50)  
,StatusOperator INT,  
StatusValue nvarchar(50),  
ClosedLoopOperator INT,  
ClosedLoopValue nvarchar(50),  
NextActionOperator INT,  
NextActionValue nvarchar(50),  
AssignedToOperator INT,  
AssignedToValue nvarchar(50),  
MemberNumberOperator INT,  
MemberNumberValue nvarchar(50),  
PriorityOperator INT,  
PriorityValue nvarchar(50)  
)  

DECLARE @CaseValue int  
DECLARE @RequestNumberValue int
DECLARE @MemberValue nvarchar(200)
DECLARE @ServiceTypeValue nvarchar(50)  
DECLARE @PONumberValue nvarchar(50)  
DECLARE @ISPNameValue nvarchar(255)  
DECLARE @CreateByValue nvarchar(50)  
DECLARE @StatusValue nvarchar(50)
DECLARE @ClosedLoopValue nvarchar(50)
DECLARE @NextActionValue nvarchar(50)
DECLARE @AssignedToValue nvarchar(50)
DECLARE @MemberNumberValue nvarchar(50)
DECLARE @PriorityValue nvarchar(50)
DECLARE @isFHT  BIT = 0

DECLARE @serviceRequestEntityID INT
DECLARE @fhtContactReasonID INT
DECLARE @dispatchStatusID INT

SET @serviceRequestEntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
SET @fhtContactReasonID = (SELECT ID FROM ContactReason WHERE Name = 'HumanTouch')
SET @dispatchStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Dispatched')

DECLARE @StartMins INT = 0 
SELECT @StartMins = -1 * CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchStartMins' 

DECLARE @EndMins INT = 0 
SELECT @EndMins = -1 * CONVERT(INT,ISNULL(Value,0)) FROM ApplicationConfiguration WITH (NOLOCK) WHERE Name = 'FordHumanTouchEndMins' 

-- DEBUG:
--SELECT @StartMins, @EndMins

 SELECT @CaseValue = CaseValue,
		@RequestNumberValue = RequestNumberValue,
		@MemberValue = MemberValue,
		@ServiceTypeValue = ServiceTypeValue,
		@PONumberValue = PONumberValue,
		@ISPNameValue = ISPNameValue,
		@CreateByValue = CreateByValue,
		@StatusValue = StatusValue,
		@ClosedLoopValue = ClosedLoopValue,
		@NextActionValue = NextActionValue,
		@AssignedToValue = AssignedToValue,
		@MemberNumberValue = MemberNumberValue,
		@PriorityValue = PriorityValue
 FROM	@tmpForWhereClause
  
-- Extract the status values.  
  
DECLARE @tmpStatusInput TABLE  
(  
 StatusName NVARCHAR(100)  
)  
 
DECLARE @fhtCharIndex INT = -1
SET @fhtCharIndex = CHARINDEX('FHT',@StatusValue,0)

IF (@fhtCharIndex > 0)
BEGIN
	SET @StatusValue = REPLACE(@StatusValue,'FHT','')
	SET @isFHT = 1
END


  
INSERT INTO @tmpStatusInput  
SELECT Item FROM [dbo].[fnSplitString](@StatusValue,',')  
  
  
-- Include StatusNames with '^' suffix.  
INSERT INTO @tmpStatusInput  
SELECT StatusName + '^' FROM @tmpStatusInput  

-- CR : 1244 - FHT
IF (@isFHT = 1)
BEGIN	
	-- remove FHT from the StatusValue.	
	DECLARE @cnt INT = 0
	SELECT @cnt = COUNT(*) FROM @tmpStatusInput	
	IF (@cnt = 0)
	BEGIN
		SET @StatusValue = NULL		
	END
END

  
--DEBUG: SELECT * FROM @tmpStatusInput  
  
-- For EF to generate proper classes  
IF @userID IS NULL  
BEGIN  
SELECT 0 AS TotalRows,  
F.[RowNum],  
F.[Case],  
F.RequestNumber,  
F.Client,  
F.Member,  
F.Submitted,  
  
F.Elapsed,  
  
F.ServiceType,  
F.[Status] ,  
F.AssignedTo ,  
F.ClosedLoop ,  
F.PONumber ,  
  
F.ISPName ,  
F.CreateBy ,  
F.NextAction,  
F.MemberNumber,  
F.[Priority], 
F.ProgramName, 
F.ProgramID,
F.MemberID,
@openedCount AS [OpenedCount],  
@submittedCount AS [SubmittedCount],  
@cancelledcount AS [CancelledCount],  
@dispatchedCount AS [DispatchedCount],  
@completecount AS [CompleteCount],  
F.[Scheduled],
F.ScheduledOriginal ,	-- Added by Lakshmi- Queue Color
F.StatusDateModified  -- Added by Lakshmi  - Queue Color 
FROM #FinalResultsSorted F  
RETURN;  
END  
--------------------- BEGIN -----------------------------  
---- Create a temp variable or a CTE with the actual SQL search query ----------  
---- and use that CTE in the place of <table> in the following SQL statements ---  
--------------------- END -----------------------------  
-- LOGIC : BEGIN 

IF ( @isFHT = 0 )
BEGIN 
	
	INSERT INTO #FinalResultsFiltered
	SELECT  
			  DISTINCT  
			  SR.CaseID AS [Case],  
			  SR.ID AS [RequestNumber],  
			  CL.Name AS [Client],  
			  M.FirstName,
			  M.LastName,
			  M.MiddleName,
			  M.Suffix,
			  M.Prefix,     
			-- KB: Retain original values here for sorting  
			  sr.CreateDate AS SubmittedOriginal,
			-- KB: Retain original values here for sorting   
			  SR.SecondaryProductID,
			  PC.Name AS [ServiceType],  
			  SRS.Name As [Status],
			  SR.IsRedispatched,    
			  C.AssignedToUserID,
			  SR.NextActionAssignedToUserID,
			  CLS.[Description] AS [ClosedLoop],     
			  CONVERT(int,PO.PurchaseOrderNumber) AS [PONumber],  
			  V.Name AS [ISPName],  
			  SR.CreateBy AS [CreateBy],
			--RH: Temporary fix until we remove Ford Tech from Next Action
			  CASE 
				WHEN NA.Description = 'Ford Tech' THEN 'RV Tech'
				ELSE COALESCE(NA.Description,'') 
			  END AS [NextAction],  
			  CASE 
				WHEN SR.NextActionID = (SELECT ID FROM NextAction WHERE Name = 'FordTech' AND IsActive = 1) 
					THEN (SELECT ID FROM NextAction WHERE Name = 'RVTech')
				ELSE SR.NextActionID
			  END AS NextActionID,  
			--RH: See above
			  SR.ClosedLoopStatusID as [ClosedLoopID],  
			  SR.ProductCategoryID as [ServiceTypeID],  
			  MS.MembershipNumber AS [MemberNumber],  
			  SR.ServiceRequestPriorityID AS [PriorityID],  
			  CASE 
				WHEN SRP.Name IN ('Normal','Low') THEN ''  -- Do not display Normal and Low text
				ELSE SRP.Name 
			  END AS [Priority],   
			  sr.NextActionScheduledDate AS 'ScheduledOriginal', -- This field is used for Queue Color
			  P.ProgramName,
			  P.ProgramID,
			  M.ID AS MemberID,
			  SR.StatusDateModified	,		-- Added by Lakshmi	-Queue Color
			  CASE 
				WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = 'Critical') THEN 1
				WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = 'High') THEN 2
				ELSE 3
				END PrioritySort,             -- Push critical and High to the top 
			  SR.NextActionScheduledDate,
			  CASE
				WHEN sr.NextActionScheduledDate <= DATEADD(HH,1,getdate())
				THEN sr.NextActionScheduledDate
				ELSE '1/1/2099'
				END ScheduleDateSort         -- Push items scheduled now to the top 


	FROM [Case] C WITH (NOLOCK)
	JOIN [ServiceRequest] SR WITH (NOLOCK) ON C.ID = SR.CaseID  
	JOIN [ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN [ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID  
	JOIN dbo.fnc_GetProgramsForUser(@userID) P ON C.ProgramID = P.ProgramID  
	JOIN [Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID  
	JOIN [Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	JOIN Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID  	
	LEFT JOIN (  
	SELECT ROW_NUMBER() OVER (PARTITION BY ServiceRequestID ORDER BY CreateDate DESC) AS RowNum,  
	ID,  
	PurchaseOrderNumber,  
	ServiceRequestID,  
	VendorLocationID   
	FROM PurchaseOrder WITH (NOLOCK)   
	WHERE --IsActive = 1 AND  
	PurchaseOrderStatusID NOT IN (SELECT ID FROM PurchaseOrderStatus WITH (NOLOCK) WHERE Name in ('Pending'))   
	AND (@PONumberValue IS NULL OR @PONumberValue = PurchaseOrderNumber)  
	) PO ON SR.ID = PO.ServiceRequestID AND PO.RowNum = 1  
	LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID  
	LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID  
	LEFT JOIN (  
	SELECT ROW_NUMBER() OVER (PARTITION BY ELL.RecordID ORDER BY EL.CreateDate ASC) AS RowNum,  
	ELL.RecordID,  
	EL.EventID,  
	EL.CreateDate AS [Submitted]  
	FROM EventLog EL  WITH (NOLOCK) 
	JOIN EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID  
	JOIN [Event] E WITH (NOLOCK) ON EL.EventID = E.ID  
	JOIN [EventCategory] EC WITH (NOLOCK) ON E.EventCategoryID = EC.ID  
	WHERE ELL.EntityID = (SELECT ID FROM Entity WITH (NOLOCK) WHERE Name = 'ServiceRequest')  
	AND E.Name = 'SubmittedForDispatch'  
	) ELOG ON SR.ID = ELOG.RecordID AND ELOG.RowNum = 1  
	LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID  

	WHERE	(@RequestNumberValue IS NOT NULL AND SR.ID = @RequestNumberValue)
	OR		(@RequestNumberValue IS NULL AND DATEDIFF(HH,SR.CreateDate,@now) <= @queueDisplayHours )--and SR.IsRedispatched is null  
END
ELSE
BEGIN
	
	INSERT INTO #FinalResultsFiltered	
	SELECT  
			DISTINCT  
			SR.CaseID AS [Case],  
			SR.ID AS [RequestNumber],  
			CL.Name AS [Client],  
			M.FirstName,
			M.LastName,
			M.MiddleName,
			M.Suffix,
			M.Prefix,     
			-- KB: Retain original values here for sorting  
			sr.CreateDate AS SubmittedOriginal,
			-- KB: Retain original values here for sorting   
			SR.SecondaryProductID,
			PC.Name AS [ServiceType],  
			SRS.Name As [Status],
			SR.IsRedispatched,    
			C.AssignedToUserID,
			SR.NextActionAssignedToUserID,
			CLS.[Description] AS [ClosedLoop],     
			CONVERT(int,PO.PurchaseOrderNumber) AS [PONumber],  
			V.Name AS [ISPName],  
			SR.CreateBy AS [CreateBy],  
			--RH: Temporary fix until we remove Ford Tech from Next Action
			  CASE 
				WHEN NA.Description = 'Ford Tech' THEN 'RV Tech'
				ELSE COALESCE(NA.Description,'') 
			  END AS [NextAction],  
			  CASE 
				WHEN SR.NextActionID = (SELECT ID FROM NextAction WHERE Name = 'FordTech' AND IsActive = 1) 
					THEN (SELECT ID FROM NextAction WHERE Name = 'RVTech')
				ELSE SR.NextActionID
			  END AS NextActionID, 
			--RH: See above  
			SR.ClosedLoopStatusID as [ClosedLoopID],  
			SR.ProductCategoryID as [ServiceTypeID],  
			MS.MembershipNumber AS [MemberNumber],  
			SR.ServiceRequestPriorityID AS [PriorityID],  
			--SRP.Name AS [Priority],
			CASE 
				WHEN SRP.Name IN ('Normal','Low') THEN ''
				ELSE SRP.Name 
			END AS [Priority],   
			SR.NextActionScheduledDate AS 'ScheduledOriginal',		-- This field is used for Queue Color
			P.Name AS ProgramName,
			P.ID AS ProgramID,
			M.ID AS MemberID,
			SR.StatusDateModified	,		-- Added by Lakshmi	-Queue Color
			CASE 
				WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = 'Critical') THEN 1
				WHEN sr.ServiceRequestPriorityID = (SELECT ID FROM ServiceRequestPriority WHERE Name = 'High') THEN 2
				ELSE 3
				END PrioritySort,
			SR.NextActionScheduledDate,
			CASE
				WHEN sr.NextActionScheduledDate <= DATEADD(HH,1,getdate())
				THEN sr.NextActionScheduledDate
				ELSE '1/1/2099'
				END ScheduleDateSort
	FROM	ServiceRequest SR	
	JOIN	[ServiceRequestStatus] SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID  
	LEFT JOIN	[ServiceRequestPriority] SRP WITH (NOLOCK) ON SR.ServiceRequestPriorityID = SRP.ID 
	JOIN	[Case] C on C.ID = SR.CaseID
	JOIN	Program P on P.ID = C.ProgramID
	JOIN	[Client] CL WITH (NOLOCK) ON P.ClientID = CL.ID
	JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID  
	JOIN	Membership MS WITH (NOLOCK) ON M.MembershipID = MS.ID  
	LEFT JOIN [ProductCategory] PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID    
	JOIN	PurchaseOrder PO on PO.ServiceRequestID = SR.ID 
							AND PO.PurchaseOrderStatusID IN 
							(SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid'))
	LEFT JOIN [NextAction] NA WITH (NOLOCK) ON SR.NextActionID=NA.ID 
	LEFT JOIN [VendorLocation] VL WITH (NOLOCK) ON PO.VendorLocationID = VL.ID  
	LEFT JOIN [Vendor] V WITH (NOLOCK) ON VL.VendorID = V.ID  
	LEFT OUTER JOIN ClosedLoopStatus CLS WITH (NOLOCK) on CLS.ID=SR.ClosedLoopStatusID 
	LEFT OUTER JOIN (
		SELECT	CLL.RecordID 
				FROM	ContactLogLink cll 
				JOIN	ContactLog cl ON cl.ID = cll.ContactLogID
				JOIN	ContactLogReason clr ON clr.ContactLogID = cl.ID
				WHERE	cll.EntityID = @serviceRequestEntityID
				AND clr.ContactReasonID = @fhtContactReasonID
	) CLSR ON CLSR.RecordID = SR.ID
	WHERE	CL.Name = 'Ford'
	AND		SR.ServiceRequestStatusID = @dispatchStatusID
	AND		@now between dateadd(mi,@StartMins,po.ETADate) and dateadd(mi,@EndMins,po.ETADate)   
	-- Filter out those SRs that has a contactlog record for HumanTouch.
	AND		CLSR.RecordID IS NULL
	
END

  
-- LOGIC : END  
  

  
  
INSERT INTO #FinalResultsFormatted  
SELECT  
T.[Case],  
T.RequestNumber,  
T.Client,  
-- CR : 1256
REPLACE(RTRIM(
  COALESCE(T.LastName,'')+  
  COALESCE(' ' + CASE WHEN T.Suffix = '' THEN NULL ELSE T.Suffix END,'')+  
  COALESCE(', '+ CASE WHEN T.FirstName = '' THEN NULL ELSE T.FirstName END,'' )+
  COALESCE(' ' + LEFT(T.MiddleName,1),'')
  ),'','') AS [Member],
--REPLACE(RTRIM(  
--  COALESCE(''+T.LastName,'')+  
--  COALESCE(''+ space(1)+ T.Suffix,'')+  
--  COALESCE(','+  space(1) + T.FirstName,'' )+  
--  COALESCE(''+ space(1) + left(T.MiddleName,1),'')  
--  ),'','') AS [Member],  
CONVERT(VARCHAR(3),DATENAME(MONTH,T.SubmittedOriginal)) + SPACE(1)+   
+''+CONVERT (VARCHAR(2),DATEPART(dd,T.SubmittedOriginal)) + SPACE(1) +   
+''+REPLACE(REPLACE(RIGHT('0'+LTRIM(RIGHT(CONVERT(VARCHAR,T.SubmittedOriginal,100),7)),7),'AM','AM'),'PM','PM')as [Submitted], 
T.SubmittedOriginal,  
CONVERT(VARCHAR(6),DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600)+':'  
  +RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60),2) AS [Elapsed],  
DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())/3600 + ((DATEDIFF(SECOND,T.SubmittedOriginal,GETDATE())%3600)/60) AS ElapsedOriginal,    
CASE  
	WHEN T.SecondaryProductID IS NOT NULL  
	THEN T.ServiceType + '+'  
	ELSE T.ServiceType 
END AS ServiceType,
CASE  
	WHEN T.IsRedispatched =1 then T.[Status] + '^'  
	ELSE T.[Status]  
END AS [Status],
CASE WHEN T.AssignedToUserID IS NOT NULL  
	THEN '*' + ISNULL(ASU.FirstName,'') + ' ' + ISNULL(ASU.LastName,'')  
	ELSE ISNULL(SASU.FirstName,'') + ' ' + ISNULL(SASU.LastName,'')  
END AS [AssignedTo],    
T.ClosedLoop,  
T.PONumber,  
T.ISPName,  
T.CreateBy,  
T.NextAction,  
T.MemberNumber,  
T.[Priority],  
CONVERT(VARCHAR(3),DATENAME(MONTH,T.ScheduledOriginal)) + SPACE(1)+   
  +''+CONVERT (VARCHAR(2),DATEPART(dd,T.ScheduledOriginal)) + SPACE(1) +   
  +''+REPLACE(REPLACE(RIGHT('0'+LTRIM(RIGHT(CONVERT(VARCHAR,T.ScheduledOriginal,100),7)),7),'AM','AM'),'PM','PM')as [Scheduled],
T.[ScheduledOriginal],		-- This field is used for Queue Color
T.ProgramName,
T.ProgramID,
T.MemberID,
T.StatusDateModified					--Added by Lakshmi - Queue Color
FROM #FinalResultsFiltered T
LEFT JOIN [User] ASU WITH (NOLOCK) ON T.AssignedToUserID = ASU.ID  
LEFT JOIN [User] SASU WITH (NOLOCK) ON T.NextActionAssignedToUserID = SASU.ID  
WHERE (
		( @CaseValue IS NULL OR @CaseValue = T.[Case])
		AND
		( @RequestNumberValue IS NULL OR @RequestNumberValue = T.RequestNumber)
		AND
		( @ServiceTypeValue IS NULL OR @ServiceTypeValue = T.ServiceTypeID)
		AND
		( @ISPNameValue IS NULL OR T.ISPName LIKE '%' + @ISPNameValue + '%')
		AND
		( @CreateByValue IS NULL OR T.CreateBy LIKE '%' + @CreateByValue + '%')
		
		AND
		( @ClosedLoopValue IS NULL OR T.ClosedLoopID = @ClosedLoopValue)
		AND
		( @NextActionValue IS NULL OR T.NextActionID = @NextActionValue)
		AND
		( @MemberNumberValue IS NULL OR @MemberNumberValue = T.MemberNumber)
		AND 
		( @PriorityValue IS NULL OR @PriorityValue = T.PriorityID)	
		AND 
		( @PONumberValue IS NULL OR @PONumberValue = T.PONumber)		
	)
ORDER BY T.PrioritySort,T.ScheduleDateSort ,T.RequestNumber DESC



INSERT INTO #FinalResultsSorted
SELECT	T.[Case],  
		T.RequestNumber,  
		T.Client,  
		T.Member,  
		T.Submitted,  
		T.SubmittedOriginal,  
		T.Elapsed,  
		T.ElapsedOriginal,  
		T.ServiceType,  
		T.[Status],  
		T.AssignedTo,  
		T.ClosedLoop,  
		T.PONumber,  
		T.ISPName,  
		T.CreateBy,  
		T.NextAction,  
		T.MemberNumber,  
		T.[Priority],  
		T.[Scheduled],  
		T.ScheduledOriginal,
		T.ProgramName,
		T.ProgramID,
		T.MemberID,
		T.StatusDateModified				--Added by Lakshmi
FROM	#FinalResultsFormatted T
WHERE	( 
			( @MemberValue IS NULL OR  T.Member LIKE '%' + @MemberValue  + '%')
			AND
			( @AssignedToValue IS NULL OR T.AssignedTo LIKE '%' + @AssignedToValue + '%' )
			AND
			( @StatusValue IS NULL OR T.[Status] IN (       
											SELECT T.StatusName FROM @tmpStatusInput T    
											)  
										)
		)

ORDER BY  
CASE WHEN @sortColumn = 'Case' AND @sortOrder = 'ASC'  
THEN T.[Case] END ASC,  
CASE WHEN @sortColumn = 'Case' AND @sortOrder = 'DESC'  
THEN T.[Case] END DESC ,  
  
CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'ASC'  
THEN T.RequestNumber END ASC,  
CASE WHEN @sortColumn = 'RequestNumber' AND @sortOrder = 'DESC'  
THEN T.RequestNumber END DESC ,  
  
CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'ASC'  
THEN T.Client END ASC,  
CASE WHEN @sortColumn = 'Client' AND @sortOrder = 'DESC'  
THEN T.Client END DESC ,  
  
CASE WHEN @sortColumn = 'Member' AND @sortOrder = 'ASC'  
THEN T.Member END ASC,  
CASE WHEN @sortColumn = 'Member' AND @sortOrder = 'DESC'  
THEN T.Member END DESC ,  
  
CASE WHEN @sortColumn = 'Submitted' AND @sortOrder = 'ASC'  
THEN T.SubmittedOriginal END ASC,  
CASE WHEN @sortColumn = 'Submitted' AND @sortOrder = 'DESC'  
THEN T.SubmittedOriginal END DESC ,  
  
CASE WHEN @sortColumn = 'FormattedElapsedTime' AND @sortOrder = 'ASC'  
THEN T.ElapsedOriginal END ASC,  
CASE WHEN @sortColumn = 'FormattedElapsedTime' AND @sortOrder = 'DESC'  
THEN T.ElapsedOriginal END DESC ,  
  
CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'ASC'  
THEN T.ServiceType END ASC,  
CASE WHEN @sortColumn = 'ServiceType' AND @sortOrder = 'DESC'  
THEN T.ServiceType END DESC ,  
  
CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'  
THEN T.[Status] END ASC,  
CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'  
THEN T.[Status] END DESC ,  
  
CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'ASC'  
THEN T.AssignedTo END ASC,  
CASE WHEN @sortColumn = 'AssignedTo' AND @sortOrder = 'DESC'  
THEN T.AssignedTo END DESC ,  
  
CASE WHEN @sortColumn = 'ClosedLoop' AND @sortOrder = 'ASC'  
THEN T.ClosedLoop END ASC,  
CASE WHEN @sortColumn = 'ClosedLoop' AND @sortOrder = 'DESC'  
THEN T.ClosedLoop END DESC ,  
  
CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'  
THEN T.PONumber END ASC,  
CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'  
THEN T.PONumber END DESC ,  
  
CASE WHEN @sortColumn = 'ISPName' AND @sortOrder = 'ASC'  
THEN T.ISPName END ASC,  
CASE WHEN @sortColumn = 'ISPName' AND @sortOrder = 'DESC'  
THEN T.ISPName END DESC ,  
  
CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'  
THEN T.CreateBy END ASC,  
CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'  
THEN T.CreateBy END DESC,  
  
CASE WHEN @sortColumn = 'Scheduled' AND @sortOrder = 'ASC'  
THEN T.ScheduledOriginal END ASC,  
CASE WHEN @sortColumn = 'Scheduled' AND @sortOrder = 'DESC'  
THEN T.ScheduledOriginal END DESC,  

CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'ASC'  
THEN T.NextAction END ASC,  
CASE WHEN @sortColumn = 'NextAction' AND @sortOrder = 'DESC'  
THEN T.NextAction END DESC   
  
DECLARE @count INT  
SET @count = 0  
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted  
SET @endInd = @startInd + @pageSize - 1  
IF @startInd > @count  
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
  
SELECT [Status],  
  COUNT(*) AS [Total]  
INTO #tmpStatusSummary  
FROM #FinalResultsFiltered  
WHERE [Status] IN ('Entry','Submitted','Submitted^','Dispatched','Dispatched^','Complete','Complete^','Cancelled','Cancelled^')  
GROUP BY [Status]  
--DEBUG: SELECT * FROM #tmpStatusSummary   
  
SELECT @openedCount = [Total] FROM #tmpStatusSummary WHERE [Status] = 'Entry'  
SELECT @submittedCount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] IN ('Submitted','Submitted^')  
SELECT @dispatchedCount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Dispatched', 'Dispatched^')  
SELECT @completecount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Complete', 'Complete^')  
SELECT @cancelledcount = SUM([Total]) FROM #tmpStatusSummary WHERE [Status] in ('Cancelled', 'Cancelled^')  
  
UPDATE #FinalResultsSorted SET Elapsed = NULL WHERE [Status] IN ('Complete','Complete^','Cancelled','Cancelled^')  
  
SELECT @count AS TotalRows,   
F.[RowNum],  
F.[Case],  
F.RequestNumber,  
F.Client,  
F.Member,  
F.Submitted,  
  
F.Elapsed,  
  
F.ServiceType,  
F.[Status] ,  
F.AssignedTo ,  
F.ClosedLoop ,  
F.PONumber ,  
  
F.ISPName ,  
F.CreateBy ,  
F.NextAction,  
F.MemberNumber,  
F.[Priority],  
  
  ISNULL(@openedCount,0) AS [OpenedCount],  
  ISNULL(@submittedCount,0) AS [SubmittedCount],  
  ISNULL(@dispatchedCount,0) AS [DispatchedCount],  
  ISNULL(@completecount,0) AS [CompleteCount],  
  ISNULL(@cancelledcount,0) AS [CancelledCount],  
  F.[Scheduled],
  F.ProgramName,
  F.ProgramID,
  F.MemberID,
  F.StatusDateModified,				--Added by Lakshmi - Queue Color
  F.ScheduledOriginal				--Added by Lakshmi - Queue Color
  
FROM #FinalResultsSorted F  
WHERE F.RowNum BETWEEN @startInd AND @endInd  
  
DROP TABLE #FinalResultsFiltered  
DROP TABLE #FinalResultsFormatted
DROP TABLE #FinalResultsSorted
DROP TABLE #tmpStatusSummary  
  
  
END  
  



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
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ReQueueFaxFailures]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ReQueueFaxFailures]
GO



/****** Object:  StoredProcedure [dbo].[dms_ReQueueFaxFailures]    Script Date: 10/15/2014 16:51:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[dms_ReQueueFaxFailures]
	@StartDate datetime
AS
BEGIN

	--DECLARE @StartDate datetime
	--SET @StartDate = '10/13/2014 09:00'

	INSERT INTO [DMS].[dbo].[CommunicationQueue]
	           ([ContactLogID]
	           ,[ContactMethodID]
	           ,[TemplateID]
	           ,[MessageData]
	           ,[Subject]
	           ,[MessageText]
	           ,[Attempts]
	           ,[ScheduledDate]
	           ,[CreateDate]
	           ,[CreateBy]
	           ,EventLogID
	           ,NotificationRecipient)
	SELECT [ContactLogID]
		  ,[ContactMethodID]
		  ,[TemplateID]
		  ,[Subject]
		  ,[Subject]
		  ,[MessageText]
		  ,0
		  ,getdate()
		  ,[CreateDate]
		  ,[CreateBy]
		  ,[EventLogID]
		  ,[NotificationRecipient]
	FROM [DMS].[dbo].[CommunicationLog]
	where createdate > @StartDate 
	and ContactMethodID = (SELECT ID FROM ContactMethod WHERE Name = 'Fax')
	and status = 'FAILURE' 
	and Comments like '%Unknown error%'
	order by CreateDate desc

END



GO



GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ServiceRequestList_ByClient_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRequestList_ByClient_Get] 
 END 
 GO  
/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestList_ByClient_Get]    Script Date: 07/23/2013 18:34:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

 
 -- EXEC dms_ServiceRequestList_ByClient_Get '32','1/1/2013', '7/31/2013'
 CREATE PROCEDURE [dbo].[dms_ServiceRequestList_ByClient_Get]( 
	@clientIDs NVARCHAR(MAX),
	@startDate DATETIME,
	@endDate DATETIME
 ) 
 AS 
 BEGIN
	DECLARE @tblClients TABLE (
	ClientID	INT
	)
	INSERT INTO @tblClients
	SELECT * FROM [dbo].[fnSplitString](@clientIDs,',')
	
	SELECT 
			CLT.ClientID AS [ClientID]
			, P.ID AS [ProgramID]
			, P.Name AS [ProgramName]
			, SR.ID AS [SRNumber]
			, SR.CreateDate AS [SRDate]
			, SRS.Name AS [SRStatus]
			, PC.Name AS [SRServiceTypeName]
			, PC.Description AS [SRServiceTypeDescription]
			, MS.MembershipNumber AS [MemberNumber]
			, M.Prefix AS [Prefix]
			, M.FirstName AS [FirstName]
			, M.MiddleName AS [MiddleName]
			, M.LastName AS [LastName]
			, M.Suffix AS [Suffix]
			, REPLACE(RTRIM(
			  COALESCE(M.LastName,'')+  
			  COALESCE(' ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')+  
			  COALESCE(', '+ CASE WHEN M.FirstName = '' THEN NULL ELSE M.FirstName END,'' )+
			  COALESCE(' ' + LEFT(M.MiddleName,1),'')
				),'','') AS [MemberName]
			, PO.ID AS [POID]
			, PO.PurchaseOrderNumber AS [PONumber]
			, PO.IssueDate AS [POIssueDate]
			, POS.Name AS [POStatus]
			, PO.CancellationReasonID AS [POCancellationReasonID]
			, POCR.Name AS [POCancellationReasonName]
			, PO.CancellationReasonOther AS [POCancellationReasonOther]
			, PO.CancellationComment AS [POCancellationComment]
			, PO.IsGOA AS [POIsGOA]
			, PO.GOAReasonID AS [POGOAReasonID]
			, POGR.Name AS [POGOAReasonName]
			, PO.GOAReasonOther AS [POGOAReasonOther]
			, PO.GOAComment AS [POGOAComment]
			, V.VendorNumber AS [ISPNumber]
			, V.Name AS [ISPName]
	FROM		ServiceRequest SR WITH (NOLOCK)
	LEFT JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SRS.ID = SR.ServiceRequestStatusID
	LEFT JOIN	ProductCategory PC WITH (NOLOCK) ON PC.ID = SR.ProductCategoryID
	LEFT JOIN	PurchaseOrder PO WITH (NOLOCK) ON PO.ServiceRequestID = SR.ID AND PO.IsActive = 1 AND PO.PurchaseOrderStatusID IN (SELECT ID FROM PurchaseOrderStatus WHERE Name IN ('Issued', 'Issued-Paid', 'Cancelled'))
	LEFT JOIN	PurchaseOrderStatus POS WITH (NOLOCK) ON POS.ID = PO.PurchaseOrderStatusID 
	LEFT JOIN	PurchaseOrderCancellationReason POCR WITH (NOLOCK) ON POCR.ID = PO.CancellationReasonID
	LEFT JOIN	PurchaseOrderGOAReason POGR WITH (NOLOCK) ON POGR.ID = PO.GOAReasonID
	LEFT JOIN	[Case] C WITH (NOLOCK) ON C.ID = SR.CaseID
	LEFT JOIN	Program P WITH (NOLOCK) ON P.ID = C.ProgramID
	LEFT JOIN	Member M WITH (NOLOCK) ON M.ID = C.MemberID
	LEFT JOIN	Membership MS WITH (NOLOCK) ON MS.ID = M.MembershipID
	LEFT JOIN	VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
	LEFT JOIN	Vendor V WITH (NOLOCK) ON V.ID = VL.VendorID
	JOIN		@tblClients CLT ON CLT.ClientID	= P.ClientID
	WHERE		SRS.Name IN ('Complete','Cancelled')
	AND			((@startDate IS NULL AND @endDate IS NULL) OR (SR.CreateDate BETWEEN @StartDate AND @EndDate))
	AND			(
				(ISNULL(PO.ID,'')='') 
				OR  
				(PO.IsActive = 1 AND PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending'))
				)	
	AND			SR.CreateBy <> 'Sysadmin'
	--AND			PO.IsActive = '1' 
	--AND			PO.PurchaseOrderStatusID <> (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Pending')
	--TFS:473
	AND P.ID <> 312 -- This is to stop showing Four Winds Program for the THOR account

	ORDER BY
				SR.ID, 
				PO.PurchaseOrderNumber DESC
	
 END

GO

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_servicerequest_get]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_servicerequest_get]
GO
/****** Object:  StoredProcedure [dbo].[dms_servicerequest_get]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_servicerequest_get] 1414
CREATE PROCEDURE [dbo].[dms_servicerequest_get](
   @serviceRequestID INT=NULL
)
AS
BEGIN
SET NOCOUNT ON

declare @MemberID INT=NULL
-- GET CASE ID
SET   @MemberID =(SELECT CaseID FROM [ServiceRequest](NOLOCK) WHERE ID = @serviceRequestID)
-- GET Member ID
SET @MemberID =(SELECT MemberID FROM [Case](NOLOCK) WHERE ID = @MemberID)

DECLARE @ProductID INT
SET @ProductID =NULL
SELECT  @ProductID = PrimaryProductID FROM ServiceRequest(NOLOCK) WHERE ID = @serviceRequestID

DECLARE @memberEntityID INT
DECLARE @vendorLocationEntityID INT
DECLARE @otherReasonID INT
DECLARE @dispatchPhoneTypeID INT

SET @memberEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='Member')
SET @vendorLocationEntityID = (SELECT ID FROM Entity(NOLOCK) WHERE Name ='VendorLocation')
SET @otherReasonID = (Select ID From PurchaseOrderCancellationReason(NOLOCK) Where Name ='Other')
SET @dispatchPhoneTypeID = (SELECT ID FROM PhoneType(NOLOCK) WHERE Name ='Dispatch')

SELECT
		-- Service Request Data Section
		-- Column 1		
		SR.CaseID,
		C.IsDeliveryDriver,
		SR.ID AS [RequestNumber],
		SRS.Name AS [Status],
		SRP.Name AS [Priority],
		SR.CreateDate AS [CreateDate],
		SR.CreateBy AS [CreateBy],
		SR.ModifyDate AS [ModifyDate],
		SR.ModifyBy AS [ModifyBy],
		-- Column 2
		NA.Name AS [NextAction],
		SR.NextActionScheduledDate AS [NextActionScheduledDate],
		SASU.FirstName +' '+ SASU.LastName AS [NextActionAssignedTo],
		CLS.Name AS [ClosedLoop],
		SR.ClosedLoopNextSend AS [ClosedLoopNextSend],
		-- Column 3
		CASE WHEN SR.IsPossibleTow = 1 THEN PC.Name +'/Possible Tow'ELSE PC.Name +''END AS [ServiceCategory],
		CASE
			WHEN SRS.Name ='Dispatched'
				  THEN CONVERT(VARCHAR(6),DATEDIFF(SECOND,sr.CreateDate,GETDATE())/3600)+':'
						+RIGHT('0'+CONVERT(VARCHAR(2),(DATEDIFF(SECOND,sr.CreateDate,GETDATE())%3600)/60),2)
			ELSE''
		END AS [Elapsed],
		(SELECT MAX(IssueDate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxIssueDate],
		(SELECT MAX(ETADate)FROM PurchaseOrder(NOLOCK) Where ServiceRequestID = @ServiceRequestID) AS [PoMaxETADate],
		SR.DataTransferDate AS [DataTransferDate],

		-- Member data  
		REPLACE(RTRIM(
		COALESCE(m.FirstName,'')+
		COALESCE(' '+left(m.MiddleName,1),'')+
		COALESCE(' '+ m.LastName,'')+
		COALESCE(' '+ m.Suffix,'')
		),'  ',' ')AS [Member],
		MS.MembershipNumber,
		C.MemberStatus,
		CL.Name AS [Client],
		P.ID AS ProgramID,
		P.Name AS [ProgramName],
		CONVERT(varchar(10),M.MemberSinceDate,101)AS [MemberSince],
		CONVERT(varchar(10),M.ExpirationDate,101)AS [ExpirationDate],
		MS.ClientReferenceNumber as [ClientReferenceNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactPhoneTypeID),'')AS [CallbackPhoneType],
		C.ContactPhoneNumber AS [CallbackNumber],
		ISNULL((SELECT NAME FROM PhoneType(NOLOCK) WHERE ID = c.ContactAltPhoneTypeID),'')AS [AlternatePhoneType],
		C.ContactAltPhoneNumber AS [AlternateNumber],
		ISNULL(MA.Line1,'')AS Line1,
		ISNULL(MA.Line2,'')AS Line2,
		ISNULL(MA.Line3,'')AS Line3,
		REPLACE(RTRIM(
			COALESCE(MA.City,'')+
			COALESCE(', '+RTRIM(MA.StateProvince),'')+
			COALESCE(' '+LTRIM(MA.PostalCode),'')+
			COALESCE(' '+ MA.CountryCode,'')
			),' ',' ')AS MemberCityStateZipCountry,

		-- Vehicle Section
		-- Vehcile 
		ISNULL(RTRIM(COALESCE(c.VehicleYear +' ','')+
		COALESCE(CASE c.VehicleMake WHEN'Other'THEN C.VehicleMakeOther ELSE C.VehicleMake END+' ','')+
		COALESCE(CASE C.VehicleModel WHEN'Other'THEN C.VehicleModelOther ELSE C.VehicleModel END,'')),' ')AS [YearMakeModel],
		VT.Name +' - '+ VC.Name AS [VehicleTypeAndCategory],
		C.VehicleColor AS [VehicleColor],
		C.VehicleVIN AS [VehicleVIN],
		COALESCE(C.VehicleLicenseState +'-','')+COALESCE(c.VehicleLicenseNumber,'')AS [License],
		C.VehicleDescription,
		-- For vehicle type = RV only  
		RVT.Name AS [RVType],
		C.VehicleChassis AS [VehicleChassis],
		C.VehicleEngine AS [VehicleEngine],
		C.VehicleTransmission AS [VehicleTransmission],
		C.VehicleCurrentMileage AS [Mileage],
		-- Location  
		SR.ServiceLocationAddress +' '+ SR.ServiceLocationCountryCode AS [ServiceLocationAddress],
		SR.ServiceLocationDescription,
		-- Destination
		SR.DestinationAddress +' '+ SR.DestinationCountryCode AS [DestinationAddress],
		SR.DestinationDescription,

		-- Service Section 
		CASE
			WHEN SR.IsPossibleTow = 1 
			THEN PC.Name +'/Possible Tow'
			ELSE PC.Name
		END AS [ServiceCategorySection],
		SR.PrimaryCoverageLimit As CoverageLimit,
		CASE
			WHEN C.IsSafe IN(NULL,1)
			THEN'Yes'
			ELSE'No'
		END AS [Safe],
		SR.PrimaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.PrimaryProductID) AS PrimaryProductName,
		SR.PrimaryServiceEligiblityMessage,
		SR.SecondaryProductID,
		(SELECT Name FROM Product WHERE ID = SR.SecondaryProductID) AS SecondaryProductName,
		SR.SecondaryServiceEligiblityMessage,
		SR.IsPrimaryOverallCovered,
		SR.IsSecondaryOverallCovered,
		SR.IsPossibleTow,
		

		-- Service Q&A's


		---- Service Provider Section  
		--CASE 
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NOT NULL THEN 'Contracted'
		--	WHEN @ProductID IS NOT NULL AND DefaultVendorRates.ProductID IS NULL THEN 'Not Contracted'
		--	WHEN c.ID IS NOT NULL THEN 'Contracted' 
		--	ELSE 'Not Contracted'
		--	END as ContractStatus,
		CASE
			WHEN ContractedVendors.ContractID IS NOT NULL 
				AND ContractedVendors.ContractRateScheduleID IS NOT NULL THEN 'Contracted'
			ELSE 'Not Contracted' 
			END AS ContractStatus,
		V.Name AS [VendorName],
		V.ID AS [VendorID],
		V.VendorNumber AS [VendorNumber],
		(SELECT TOP 1 PE.PhoneNumber
			FROM PhoneEntity PE
			WHERE PE.RecordID = VL.ID
			AND PE.EntityID = @vendorLocationEntityID
			AND PE.PhoneTypeID = @dispatchPhoneTypeID
			ORDER BY PE.ID DESC
		) AS [VendorLocationPhoneNumber] ,
		VLA.Line1 AS [VendorLocationLine1],
		VLA.Line2 AS [VendorLocationLine2],
		VLA.Line3 AS [VendorLocationLine3],
		REPLACE(RTRIM(
			COALESCE(VLA.City,'')+
			COALESCE(', '+RTRIM(VLA.StateProvince),'')+
			COALESCE(' '+LTRIM(VLA.PostalCode),'')+
			COALESCE(' '+ VLA.CountryCode,'')
			),' ',' ')AS VendorCityStateZipCountry,
		-- PO data
		convert(int,PO.PurchaseOrderNumber) AS [PONumber],
		PO.LegacyReferenceNumber,
		--convert(int,PO.ID) AS [PONumber],
		POS.Name AS [POStatus],
		CASE
				WHEN PO.CancellationReasonID = @otherReasonID
				THEN PO.CancellationReasonOther 
				ELSE ISNULL(CR.Name,'')
		END AS [CancelReason],
		PO.PurchaseOrderAmount AS [POAmount],
		POPC.Name AS [ServiceType],
		PO.IssueDate AS [IssueDate],
		PO.ETADate AS [ETADate],
		PO.DataTransferDate AS [ExtractDate],

		-- Other
		CASE WHEN C.AssignedToUserID IS NOT NULL
			THEN'*'+ISNULL(ASU.FirstName,'')+' '+ISNULL(ASU.LastName,'')
			ELSE ISNULL(SASU.FirstName,'')+' '+ISNULL(SASU.LastName,'')
		END AS [AssignedTo],
		C.AssignedToUserID AS [AssignedToID],
      
      -- Vendor Invoice Details
		VI.InvoiceDate,
		CASE	WHEN PT.Name = 'ACH' 
		THEN 'ACH'
				WHEN PT.Name = 'Check'
		THEN VI.PaymentNumber
		ELSE ''
		END AS PaymentType,
		
		VI.PaymentAmount,
		VI.PaymentDate,
		VI.CheckClearedDate
FROM [ServiceRequest](NOLOCK) SR  
JOIN [Case](NOLOCK) C ON C.ID = SR.CaseID  
JOIN [ServiceRequestStatus](NOLOCK) SRS ON SR.ServiceRequestStatusID = SRS.ID  
LEFT JOIN [ServiceRequestPriority](NOLOCK) SRP ON SR.ServiceRequestPriorityID = SRP.ID   
LEFT JOIN [Program](NOLOCK) P ON C.ProgramID = P.ID   
LEFT JOIN [Client](NOLOCK) CL ON P.ClientID = CL.ID  
LEFT JOIN [Member](NOLOCK) M ON C.MemberID = M.ID  
LEFT JOIN [Membership](NOLOCK) MS ON M.MembershipID = MS.ID  
LEFT JOIN [AddressEntity](NOLOCK) MA ON M.ID = MA.RecordID  
            AND MA.EntityID = @memberEntityID
LEFT JOIN [Country](NOLOCK) MCNTRY ON MA.CountryCode = MCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) LCNTRY ON SR.ServiceLocationCountryCode = LCNTRY.ISOCode  
LEFT JOIN [Country](NOLOCK) DCNTRY ON SR.DestinationCountryCode = DCNTRY.ISOCode  
LEFT JOIN [VehicleType](NOLOCK) VT ON C.VehicleTypeID = VT.ID  
LEFT JOIN [VehicleCategory](NOLOCK) VC ON C.VehicleCategoryID = VC.ID  
LEFT JOIN [RVType](NOLOCK) RVT ON C.VehicleRVTypeID = RVT.ID  
LEFT JOIN [ProductCategory](NOLOCK) PC ON PC.ID = SR.ProductCategoryID  
LEFT JOIN [User](NOLOCK) ASU ON C.AssignedToUserID = ASU.ID  
LEFT OUTER JOIN [User](NOLOCK) SASU ON SR.NextActionAssignedToUserID = SASU.ID  
LEFT JOIN [PurchaseOrder](NOLOCK) PO ON PO.ServiceRequestID = SR.ID  AND PO.IsActive = 1 
LEFT JOIN [PurchaseOrderStatus](NOLOCK) POS ON PO.PurchaseOrderStatusID = POS.ID
LEFT JOIN [PurchaseOrderCancellationReason](NOLOCK) CR ON PO.CancellationReasonID = CR.ID
LEFT JOIN [Product](NOLOCK) PR ON PO.ProductID = PR.ID
LEFT JOIN [ProductCategory](NOLOCK) POPC ON PR.ProductCategoryID = POPC.ID
LEFT JOIN [VendorLocation](NOLOCK) VL ON PO.VendorLocationID = VL.ID  
LEFT JOIN [AddressEntity](NOLOCK) VLA ON VL.ID = VLA.RecordID 
            AND VLA.EntityID =@vendorLocationEntityID
LEFT JOIN [Vendor](NOLOCK) V ON VL.VendorID = V.ID 
--LEFT JOIN [Contract](NOLOCK) CON on CON.VendorID = V.ID and CON.IsActive = 1 and CON.ContractStatusID = (Select ID From ContractStatus Where Name = 'Active')
LEFT JOIN [ClosedLoopStatus](NOLOCK) CLS ON SR.ClosedLoopStatusID = CLS.ID 
LEFT JOIN [NextAction](NOLOCK) NA ON SR.NextActionID = NA.ID

--Join to get information needed to determine Vendor Contract status ********************
--LEFT OUTER JOIN (
--      SELECT DISTINCT vr.VendorID, vr.ProductID
--      FROM dbo.fnGetCurrentProductRatesByVendorLocation() vr 
--      ) DefaultVendorRates ON v.ID = DefaultVendorRates.VendorID And @ProductID = DefaultVendorRates.ProductID
LEFT OUTER JOIN(
	  SELECT DISTINCT cv.VendorID, cv.ContractID, cv.ContractRateScheduleID
	  FROM dbo.fnGetContractedVendors() cv
	  ) ContractedVendors ON v.ID = ContractedVendors.VendorID 
      
LEFT JOIN [VendorInvoice] VI WITH (NOLOCK) ON PO.ID = VI.PurchaseOrderID
LEFT JOIN [PaymentType] PT WITH (NOLOCK) ON VI.PaymentTypeID = PT.ID
WHERE SR.ID = @serviceRequestID

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
-- EXEC [dbo].[dms_servicerequest_history_list] @whereClauseXML = '<ROW><Filter IDType="Service Request" IDValue="1234" NameType="" NameValue="" LastName="" FilterType = "StartsWith" FromDate = "" ToDate = "" Preset ="" Clients ="1" Programs ="" ServiceRequestStatuses = "" ServiceTypes ="" IsGOA = "" IsRedispatched = "" IsPossibleTow ="" VehicleType ="1" VehicleYear ="2012" VehicleMake = "" VehicleModel = "" PaymentByCheque = "" PaymentByCard = "" MemberPaid ="" POStatuses =""/></ROW>', @userID = 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'
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
		IDType NVARCHAR(255) NULL UNIQUE NonClustered,
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
	IF @IDType = 'VIN'
	BEGIN
		SELECT	@vinParam = IDValue 
		FROM	@tmpWhereClause
		WHERE	IDType = 'VIN'
	END
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
	
	Declare @PurchaseOrder NVARCHAR(50) = CONVERT(NVARCHAR(50),@IDValue)
	Declare @iServiceRequestID INT = 0
	IF (@IDType = 'Service Request')
	BEGIN
		SET @iServiceRequestID = CONVERT(INT, @IDValue)
	END

	Declare @ISP nvarchar(50) = CONVERT(NVARCHAR(50),@IDValue)
	Declare @Member nvarchar(50) = CONVERT(NVARCHAR(50),@IDValue)
	Declare @VIN nvarchar(50) = CONVERT(NVARCHAR(50),@IDValue)
	
			
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
	LEFT JOIN	[Member] M WITH (NOLOCK) ON C.MemberID = M.ID   -- RH 2/10/2014 Insisted on by the users
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
			(@IDType = 'Purchase Order' AND PO.PurchaseOrderNumber = @PurchaseOrder )
			OR			
			(@IDType = 'Service Request' AND @iServiceRequestID = SR.ID )
			OR
			(@IDType = 'ISP' AND V.VendorNumber =  @ISP )
			OR
			(@IDType = 'Member' AND MS.MembershipNumber = @Member )			 
			OR
			(@IDType = 'VIN' AND C.VehicleVIN = @VIN )
		)

		---- IDs
		--(
		--	(@IDType IS NULL)
		--	OR
		--	(@IDType = 'Purchase Order' AND PO.PurchaseOrderNumber = CONVERT(NVARCHAR(50),@IDValue))
		--	OR
		--	(@IDType = 'Service Request' AND @IDValue = CONVERT(NVARCHAR(50),SR.ID))
		--	OR
		--	(@IDType = 'ISP' AND V.VendorNumber =  CONVERT(NVARCHAR(50),@IDValue) )
		--	OR
		--	(@IDType = 'Member' AND MS.MembershipNumber = CONVERT(NVARCHAR(50),@IDValue))			 
		--	OR
		--	(@IDType = 'VIN' AND C.VehicleVIN = CONVERT(NVARCHAR(50),@IDValue))
		--)
	
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



GO

/****** Object:  StoredProcedure [dbo].[dms_service_request_export_prepare]    Script Date: 04/04/2013 09:45:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


		 
ALTER PROC [dbo].[dms_service_request_export_prepare]
AS
BEGIN

	DECLARE @AppConfig AS INT  

	SET @AppConfig = (Select ISNULL(AC.Value,330) From ApplicationConfiguration AC 
	JOIN ApplicationConfigurationType ACT on ACT.ID = AC.ApplicationConfigurationTypeID
	JOIN ApplicationConfigurationCategory ACC on ACC.ID = AC.ApplicationConfigurationCategoryID
	Where AC.Name='AgingReadyForExportMinutes'
	AND ACT.Name = 'WindowsService'
	AND ACC.Name = 'DispatchProcessingService') 

	UPDATE SR 
	SET 
		ReadyForExportDate = GETDATE(),
		ModifyDate = getdate(),
		ModifyBy = 'system'
	FROM ServiceRequest SR
	JOIN dbo.ServiceRequestStatus SRStatus
		ON SR.ServiceRequestStatusID = SRStatus.ID
	WHERE
	SRStatus.Name IN ('Cancelled', 'Complete')		
	AND SR.ReadyForExportDate IS NULL 
	AND SR.DataTransferDate IS NULL
	AND DATEADD(mi,@AppConfig,SR.CreateDate)<= GETDATE()	
	AND NOT EXISTS (
		SELECT *
		FROM PurchaseOrder PO
		JOIN PurchaseOrderStatus POStatus
			ON PO.PurchaseOrderStatusID = POStatus.ID
		WHERE PO.ServiceRequestID = SR.ID
		AND POStatus.Name IN ('Cancelled', 'Issued','Issued-Paid')
		)

		
	UPDATE PO   
	SET 
		ReadyForExportDate = GETDATE(),
		ModifyDate = getdate(),
		ModifyBy = 'system'
	FROM PurchaseOrder  PO
	JOIN PurchaseOrderStatus POStatus
		ON PO.PurchaseOrderStatusID = POStatus.ID
	WHERE 
	PO.ReadyForExportDate IS NULL
	AND PO.DataTransferDate IS NULL
	AND POStatus.Name IN ('Cancelled', 'Issued','Issued-Paid')
	AND DATEADD(mi,@AppConfig,PO.IssueDate)<= GETDATE()
	AND PO.IsActive = 1	  -- RH Added 3/16/2013 4:44 PM
	
	
	/* Force expiration of added (temp) members to 2 days (or less)  */
	/* Exception: ARS */
	--UPDATE M SET
	--	EffectiveDate = CAST(CONVERT(varchar, m.CreateDate,101) as datetime)
	--	,ExpirationDate = DATEADD(dd, 2, CAST(CONVERT(varchar, m.CreateDate,101) as datetime))
	--FROM member m 
	--JOIN program p on p.ID = m.ProgramID
	--JOIN client cl on cl.ID = p.ClientID
	--WHERE
	--m.ClientMemberKey IS NULL
	--AND p.Name <> 'Hagerty Employee'


	/* Prevent bad data entry for ARS effective and expiration dates */
	--UPDATE M SET
	--	EffectiveDate = CASE WHEN m.EffectiveDate < '1950-01-01' THEN CAST(CONVERT(varchar, m.CreateDate,101) as datetime) ELSE m.EffectiveDate END
	--	,ExpirationDate = CASE WHEN m.ExpirationDate > '2039-12-31' THEN DATEADD(yy, 5, CAST(CONVERT(varchar, m.CreateDate,101) as datetime)) ELSE m.ExpirationDate END
	--FROM member m 
	--JOIN program p on p.ID = m.ProgramID
	--JOIN client cl on cl.ID = p.ClientID
	--WHERE
	--m.ClientMemberKey IS NULL
	--AND cl.Name = 'ARS'
	--AND (m.EffectiveDate < '1950-01-01' OR m.ExpirationDate > '2039-12-31')

END
GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_TempCC_VendorInvoice_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_TempCC_VendorInvoice_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_TempCC_VendorInvoice_update] 169
 CREATE PROCEDURE [dbo].[dms_TempCC_VendorInvoice_update](
 @BatchId int
 )
 AS 
 BEGIN
 
	---- Added Logic to create invoices for 'real' CCs issued to Managers to pay POs
	---- Identifies specific CC#s and creates corresponding Vendor Invoices
	---- Added here to be part of the Temp CC Post processing
	EXEC dms_Vendor_Invoice_ManagerCC_PO
	---- End Comment


    DECLARE @invoicesFromDB TABLE
	(	
		ID INT IDENTITY(1,1),
		InvoiceID INT
	)
	
	INSERT INTO @invoicesFromDB
	SELECT VI.ID
	FROM	VendorInvoice VI
	WHERE VI.ExportBatchID = @BatchId
	
    DECLARE @glAccountFromAppConfig NVARCHAR(255)

	SET @glAccountFromAppConfig = (SELECT Value FROM ApplicationConfiguration WHERE Name = 'ISPCheckGLExpenseAccount')

	;WITH wVendorInvoiceGLExpenseAccount
	AS
	(
		SELECT	VI.ID AS VendorInvoiceID,
				PO.PurchaseOrderNumber,		
				@glAccountFromAppConfig AS AppConfigValue,
				C.ProgramID,
				C.IsDeliveryDriver,
				[dbo].[fnc_GetProgramConfigurationItemValueForProgram](C.ProgramID,
																	'Application',
																	NULL, 
																	CASE	WHEN ISNULL(C.IsDeliveryDriver,0) = 1 
																			THEN 'DeliveryDriverISPGLCheckExpenseAccount'
																			ELSE 'ISPCheckGLExpenseAccount' 
																			END) AS ProgramConfigItemValue
		FROM	VendorInvoice VI
		JOIN	@invoicesFromDB I ON VI.ID = I.InvoiceID
		JOIN	PurchaseOrder PO ON VI.PurchaseOrderID = PO.ID
		JOIN	ServiceRequest SR ON PO.ServiceRequestID = SR.ID
		JOIN	[Case] C ON SR.CaseID = C.ID
	)
	
	UPDATE	VendorInvoice
	SET		GLExpenseAccount = COALESCE(W.ProgramConfigItemValue,AppConfigValue)
	FROM	VendorInvoice VI
	JOIN	wVendorInvoiceGLExpenseAccount W ON VI.ID = W.VendorInvoiceID
	
	
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
      ModifyBy nvarchar(100)  NULL--,
      --CreditCardIssueNumber nvarchar(100) NULL
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
      ModifyBy nvarchar(100)  NULL--,
      --CreditCardIssueNumber nvarchar(100) NULL
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
            --, TCC.CreditCardIssueNumber
FROM  Batch B
JOIN  BatchType BT ON BT.ID = B.BatchTypeID
JOIN  BatchStatus BS ON BS.ID = B.BatchStatusID
LEFT JOIN TemporaryCreditCard TCC ON TCC.PostingBatchID = B.ID
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
            --, TCC.CreditCardIssueNumber
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
      T.ModifyBy--,
      --T.CreditCardIssueNumber
      
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
      THEN T.ModifyBy END DESC --,

      --CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'
      --THEN T.CreditCardIssueNumber END ASC, 
      -- CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'
      --THEN T.CreditCardIssueNumber END DESC 


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

/****** Object:  StoredProcedure [dbo].[dms_clients_get]    Script Date: 06/21/2012 12:46:26 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_users_list]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_users_list]
GO
/****** Object:  StoredProcedure [dbo].[dms_users_list]    Script Date: 07/03/2012 17:56:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- EXEC  [dbo].[dms_users_list] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB',NULL,1,100,10,'UserName','ASC'
-- EXEC  [dbo].[dms_users_list] '20EE6D5C-6B06-43E1-A723-D53FD6D593B5',NULL,1,100,10,'UserName','ASC'
-- EXEC  [dbo].[dms_users_list] '63B8CB08-9265-4613-AFBD-1226999DF139',NULL,1,100,10,'UserName','ASC'
 CREATE PROCEDURE [dbo].[dms_users_list]( 
   @userID UNIQUEIDENTIFIER = NULL,
   @whereClauseXML NVARCHAR(4000) = NULL 
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
UserNameOperator="-1" 
FirstNameOperator="-1" 
LastNameOperator="-1" 
OrganizationNameOperator="-1" 
RolesOperator="-1" 
DataGroupsOperator="-1" 
IsApprovedOperator="-1" 
EmailOperator="-1"
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
UserNameOperator INT NOT NULL,
UserNameValue nvarchar(255) NULL,
FirstNameOperator INT NOT NULL,
FirstNameValue nvarchar(100) NULL,
LastNameOperator INT NOT NULL,
LastNameValue nvarchar(100) NULL,
OrganizationNameOperator INT NOT NULL,
OrganizationNameValue nvarchar(100) NULL,
RolesOperator INT NOT NULL,
RolesValue nvarchar(255) NULL,
DataGroupsOperator INT NOT NULL,
DataGroupsValue nvarchar(255) NULL,
IsApprovedOperator INT NOT NULL,
IsApprovedValue BIT NULL,
EmailOperator INT NOT NULL,
EmailValue nvarchar(100) NULL
)

DECLARE @tmpResults TABLE (
	
	ID int  NULL ,
	UserID UNIQUEIDENTIFIER NULL,
	UserName nvarchar(MAX)  NULL ,
	FirstName nvarchar(MAX)  NULL ,
	LastName nvarchar(MAX)  NULL ,
	OrganizationName nvarchar(MAX)  NULL ,
	Roles nvarchar(MAX)  NULL ,
	DataGroups nvarchar(MAX)  NULL ,
	DisplayOrder int  NULL ,
	IsApproved BIT  NULL,
	Email NVARCHAR(MAX) NULL 
) 

DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	UserID UNIQUEIDENTIFIER NULL,
	UserName nvarchar(MAX)  NULL ,
	FirstName nvarchar(MAX)  NULL ,
	LastName nvarchar(MAX)  NULL ,
	OrganizationName nvarchar(MAX)  NULL ,
	Roles nvarchar(MAX)  NULL ,
	DataGroups nvarchar(MAX)  NULL ,
	IsApproved BIT  NULL ,
	DisplayOrder int  NULL ,
	Email NVARCHAR(MAX) NULL
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(UserNameOperator,-1),
	UserNameValue ,
	ISNULL(FirstNameOperator,-1),
	FirstNameValue ,
	ISNULL(LastNameOperator,-1),
	LastNameValue ,
	ISNULL(OrganizationNameOperator,-1),
	OrganizationNameValue ,
	ISNULL(RolesOperator,-1),
	RolesValue ,
	ISNULL(DataGroupsOperator,-1),
	DataGroupsValue ,
	ISNULL(IsApprovedOperator,-1),
	IsApprovedValue ,
	ISNULL(EmailOperator,-1),
	EmailValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
UserNameOperator INT,
UserNameValue nvarchar(255) 
,FirstNameOperator INT,
FirstNameValue nvarchar(100) 
,LastNameOperator INT,
LastNameValue nvarchar(100) 
,OrganizationNameOperator INT,
OrganizationNameValue nvarchar(100) 
,RolesOperator INT,
RolesValue nvarchar(255) 
,DataGroupsOperator INT,
DataGroupsValue nvarchar(255) 
,IsApprovedOperator INT,
IsApprovedValue BIT 
,EmailOperator INT,
EmailValue nvarchar(100) 
 ) 

-- DEBUG: The following statement is for EF to generate complex types
IF @userID IS NULL
BEGIN

	SELECT 0 as TotalRows,* FROM @FinalResults
	RETURN;
END
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
--- LOGIC : START

		;WITH wResults
		AS
		(
			SELECT	UP.ID,
					U.UserId,
					U.UserName,
					UP.FirstName,
					UP.LastName,
					R.RoleName,
					O.Name OrganizationName,
					--T.DisplayOrder,
					DG.Name AS DataGroupName,
					M.IsApproved,
					M.Email
			FROM	[dbo].[aspnet_Users] U WITH (NOLOCK)
			LEFT JOIN [dbo].[aspnet_Membership] M WITH (NOLOCK) ON U.UserId = M.UserId
			LEFT JOIN [dbo].[aspnet_Applications] A WITH (NOLOCK) ON A.ApplicationId = M.ApplicationId
			LEFT JOIN [dbo].[aspnet_UsersInRoles] UR WITH (NOLOCK) ON U.UserId = UR.UserId
			LEFT JOIN [dbo].[aspnet_Roles] R WITH (NOLOCK) ON UR.RoleId = R.RoleId
			JOIN [dbo].[User] UP WITH (NOLOCK) ON UP.aspnet_UserID = U.UserId
			JOIN [dbo].fnc_GetOrganizationsForUser(@userID) O ON UP.OrganizationID = O.OrganizationID
			LEFT JOIN [dbo].[UserDataGroup] UDG WITH (NOLOCK) ON UDG.UserID = UP.ID
			LEFT JOIN [dbo].[DataGroup] DG WITH (NOLOCK) ON DG.ID = UDG.DataGroupID
			--WHERE M.IsApproved = 1
			AND A.ApplicationName = 'DMS'
		)
		INSERT INTO @tmpResults
		(
				ID,
				UserID,
				UserName ,
				FirstName ,
				LastName  ,
				OrganizationName,
				Roles,
				DataGroups,
				DisplayOrder,
				IsApproved,
				Email  
		)
		SELECT	W1.ID,
				W1.UserId,
				W1.UserName,
				W1.FirstName,
				W1.LastName,
				W1.OrganizationName,
				[dbo].[fnConcatenate]( DISTINCT W1.RoleName) AS Roles,
				[dbo].[fnConcatenate]( DISTINCT W1.DataGroupName) AS DataGroups,			
				0 as DisplayOrder,
				W1.IsApproved,
				W1.Email
		
		FROM	wResults W1 
		GROUP BY	W1.ID,
					W1.UserId,
					W1.UserName,
					W1.FirstName,
					W1.LastName,
					W1.OrganizationName,
					W1.IsApproved,
					W1.Email
		ORDER BY W1.UserName ASC
		
	
		
	
--- LOGIC : END

INSERT INTO @FinalResults(
				ID,
				UserID,
				UserName ,
				FirstName ,
				LastName  ,
				OrganizationName,
				Roles,
				DataGroups,
				DisplayOrder,
				IsApproved,
				Email  )
SELECT 
	T.ID,
	T.UserID,
	T.UserName,
	T.FirstName,
	T.LastName,
	T.OrganizationName,
	T.Roles,
	T.DataGroups,
	T.DisplayOrder,
	T.IsApproved,
	T.Email
FROM @tmpResults T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.UserNameOperator = -1 ) 
 OR 
	 ( TMP.UserNameOperator = 0 AND T.UserName IS NULL ) 
 OR 
	 ( TMP.UserNameOperator = 1 AND T.UserName IS NOT NULL ) 
 OR 
	 ( TMP.UserNameOperator = 2 AND T.UserName = TMP.UserNameValue ) 
 OR 
	 ( TMP.UserNameOperator = 3 AND T.UserName <> TMP.UserNameValue ) 
 OR 
	 ( TMP.UserNameOperator = 4 AND T.UserName LIKE TMP.UserNameValue + '%') 
 OR 
	 ( TMP.UserNameOperator = 5 AND T.UserName LIKE '%' + TMP.UserNameValue ) 
 OR 
	 ( TMP.UserNameOperator = 6 AND T.UserName LIKE '%' + TMP.UserNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.FirstNameOperator = -1 ) 
 OR 
	 ( TMP.FirstNameOperator = 0 AND T.FirstName IS NULL ) 
 OR 
	 ( TMP.FirstNameOperator = 1 AND T.FirstName IS NOT NULL ) 
 OR 
	 ( TMP.FirstNameOperator = 2 AND T.FirstName = TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 3 AND T.FirstName <> TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 4 AND T.FirstName LIKE TMP.FirstNameValue + '%') 
 OR 
	 ( TMP.FirstNameOperator = 5 AND T.FirstName LIKE '%' + TMP.FirstNameValue ) 
 OR 
	 ( TMP.FirstNameOperator = 6 AND T.FirstName LIKE '%' + TMP.FirstNameValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.EmailOperator = -1 ) 
 OR 
	 ( TMP.EmailOperator = 0 AND T.Email IS NULL ) 
 OR 
	 ( TMP.EmailOperator = 1 AND T.Email IS NOT NULL ) 
 OR 
	 ( TMP.EmailOperator = 2 AND T.Email = TMP.EmailValue ) 
 OR 
	 ( TMP.EmailOperator = 3 AND T.Email <> TMP.EmailValue ) 
 OR 
	 ( TMP.EmailOperator = 4 AND T.Email LIKE TMP.EmailValue + '%') 
 OR 
	 ( TMP.EmailOperator = 5 AND T.Email LIKE '%' + TMP.EmailValue ) 
 OR 
	 ( TMP.EmailOperator = 6 AND T.Email LIKE '%' + TMP.EmailValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LastNameOperator = -1 ) 
 OR 
	 ( TMP.LastNameOperator = 0 AND T.LastName IS NULL ) 
 OR 
	 ( TMP.LastNameOperator = 1 AND T.LastName IS NOT NULL ) 
 OR 
	 ( TMP.LastNameOperator = 2 AND T.LastName = TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 3 AND T.LastName <> TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 4 AND T.LastName LIKE TMP.LastNameValue + '%') 
 OR 
	 ( TMP.LastNameOperator = 5 AND T.LastName LIKE '%' + TMP.LastNameValue ) 
 OR 
	 ( TMP.LastNameOperator = 6 AND T.LastName LIKE '%' + TMP.LastNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.OrganizationNameOperator = -1 ) 
 OR 
	 ( TMP.OrganizationNameOperator = 0 AND T.OrganizationName IS NULL ) 
 OR 
	 ( TMP.OrganizationNameOperator = 1 AND T.OrganizationName IS NOT NULL ) 
 OR 
	 ( TMP.OrganizationNameOperator = 2 AND T.OrganizationName = TMP.OrganizationNameValue ) 
 OR 
	 ( TMP.OrganizationNameOperator = 3 AND T.OrganizationName <> TMP.OrganizationNameValue ) 
 OR 
	 ( TMP.OrganizationNameOperator = 4 AND T.OrganizationName LIKE TMP.OrganizationNameValue + '%') 
 OR 
	 ( TMP.OrganizationNameOperator = 5 AND T.OrganizationName LIKE '%' + TMP.OrganizationNameValue ) 
 OR 
	 ( TMP.OrganizationNameOperator = 6 AND T.OrganizationName LIKE '%' + TMP.OrganizationNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.RolesOperator = -1 ) 
 OR 
	 ( TMP.RolesOperator = 0 AND T.Roles IS NULL ) 
 OR 
	 ( TMP.RolesOperator = 1 AND T.Roles IS NOT NULL ) 
 OR 
	 ( TMP.RolesOperator = 2 AND T.Roles = TMP.RolesValue ) 
 OR 
	 ( TMP.RolesOperator = 3 AND T.Roles <> TMP.RolesValue ) 
 OR 
	 ( TMP.RolesOperator = 4 AND T.Roles LIKE TMP.RolesValue + '%') 
 OR 
	 ( TMP.RolesOperator = 5 AND T.Roles LIKE '%' + TMP.RolesValue ) 
 OR 
	 ( TMP.RolesOperator = 6 AND T.Roles LIKE '%' + TMP.RolesValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DataGroupsOperator = -1 ) 
 OR 
	 ( TMP.DataGroupsOperator = 0 AND T.DataGroups IS NULL ) 
 OR 
	 ( TMP.DataGroupsOperator = 1 AND T.DataGroups IS NOT NULL ) 
 OR 
	 ( TMP.DataGroupsOperator = 2 AND T.DataGroups = TMP.DataGroupsValue ) 
 OR 
	 ( TMP.DataGroupsOperator = 3 AND T.DataGroups <> TMP.DataGroupsValue ) 
 OR 
	 ( TMP.DataGroupsOperator = 4 AND T.DataGroups LIKE TMP.DataGroupsValue + '%') 
 OR 
	 ( TMP.DataGroupsOperator = 5 AND T.DataGroups LIKE '%' + TMP.DataGroupsValue ) 
 OR 
	 ( TMP.DataGroupsOperator = 6 AND T.DataGroups LIKE '%' + TMP.DataGroupsValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsApprovedOperator = -1 ) 
 OR 
	 ( TMP.IsApprovedOperator = 0 AND T.IsApproved IS NULL ) 
 OR 
	 ( TMP.IsApprovedOperator = 1 AND T.IsApproved IS NOT NULL ) 
 OR 
	 ( TMP.IsApprovedOperator = 2 AND T.IsApproved = TMP.IsApprovedValue ) 
 OR 
	 ( TMP.IsApprovedOperator = 3 AND T.IsApproved <> TMP.IsApprovedValue )
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'ASC'
	 THEN T.UserName END ASC, 
	 CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'DESC'
	 THEN T.UserName END DESC ,

	 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'ASC'
	 THEN T.FirstName END ASC, 
	 CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'DESC'
	 THEN T.FirstName END DESC ,
	 
	 CASE WHEN @sortColumn = 'Email' AND @sortOrder = 'ASC'
	 THEN T.Email END ASC, 
	 CASE WHEN @sortColumn = 'Email' AND @sortOrder = 'DESC'
	 THEN T.Email END DESC ,

	 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'ASC'
	 THEN T.LastName END ASC, 
	 CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'DESC'
	 THEN T.LastName END DESC ,

	 CASE WHEN @sortColumn = 'OrganizationName' AND @sortOrder = 'ASC'
	 THEN T.OrganizationName END ASC, 
	 CASE WHEN @sortColumn = 'OrganizationName' AND @sortOrder = 'DESC'
	 THEN T.OrganizationName END DESC ,

	 CASE WHEN @sortColumn = 'Roles' AND @sortOrder = 'ASC'
	 THEN T.Roles END ASC, 
	 CASE WHEN @sortColumn = 'Roles' AND @sortOrder = 'DESC'
	 THEN T.Roles END DESC ,

	 CASE WHEN @sortColumn = 'DataGroups' AND @sortOrder = 'ASC'
	 THEN T.DataGroups END ASC, 
	 CASE WHEN @sortColumn = 'DataGroups' AND @sortOrder = 'DESC'
	 THEN T.DataGroups END DESC ,

	 CASE WHEN @sortColumn = 'IsApproved' AND @sortOrder = 'ASC'
	 THEN T.IsApproved END ASC, 
	 CASE WHEN @sortColumn = 'IsApproved' AND @sortOrder = 'DESC'
	 THEN T.IsApproved END DESC 


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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Invoice_ManagerCC_PO]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Invoice_ManagerCC_PO] 
 END 
 GO  

/****** Object:  StoredProcedure [dbo].[dms_Vendor_Invoice_ManagerCC_PO]    Script Date: 11/17/2014 12:08:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

---- Create Vendor Invoices for POs paid with Manager's real CC -- not a temporary CC 
CREATE PROCEDURE [dbo].[dms_Vendor_Invoice_ManagerCC_PO]
AS
BEGIN

	--Delay creation of invoice to allow for changes after PO is initially issued
	DECLARE @InvoiceDelayDays int
	SET @InvoiceDelayDays = 10

    DECLARE @glAccountFromAppConfig NVARCHAR(255)
	SET @glAccountFromAppConfig = (SELECT Value FROM ApplicationConfiguration WHERE Name = 'ISPCheckGLExpenseAccount')

	INSERT INTO [DMS].[dbo].[VendorInvoice]
			   ([PurchaseOrderID]
			   ,[VendorID]
			   ,[VendorInvoiceStatusID]
			   ,[SourceSystemID]
			   ,[PaymentTypeID]
			   ,[AccountingInvoiceBatchID]
			   ,[InvoiceNumber]
			   ,[ReceivedDate]
			   ,[ReceiveContactMethodID]
			   ,[InvoiceDate]
			   ,[InvoiceAmount]
			   ,[BillingBusinessName]
			   ,[BillingContactName]
			   ,[BillingAddressLine1]
			   ,[BillingAddressLine2]
			   ,[BillingAddressLine3]
			   ,[BillingAddressCity]
			   ,[BillingAddressStateProvince]
			   ,[BillingAddressPostalCode]
			   ,[BillingAddressCountryCode]
			   ,[ToBePaidDate]
			   ,[ExportDate]
			   ,[ExportBatchID]
			   ,[PaymentDate]
			   ,[PaymentAmount]
			   ,[PaymentNumber]
			   ,[CheckClearedDate]
			   ,[ActualETAMinutes]
			   ,[Last8OfVIN]
			   ,[VehicleMileage]
			   ,[IsActive]
			   ,[CreateDate]
			   ,[CreateBy]
			   ,[ModifyDate]
			   ,[ModifyBy]
			   ,[VendorInvoicePaymentDifferenceReasonCodeID]
			   ,[GLExpenseAccount])
	Select 
			   po.ID [PurchaseOrderID]
			   ,vl.[VendorID]
			   ,(Select ID FROM VendorInvoiceStatus WHERE Name = 'Paid') [VendorInvoiceStatusID]
			   ,(Select ID From SourceSystem Where Name = 'Dispatch') [SourceSystemID]
			   ,(Select ID From PaymentType Where Name = 'MasterCard') [PaymentTypeID]
			   ,NULL [AccountingInvoiceBatchID]
			   ,NULL [InvoiceNumber]
			   ,po.IssueDate [ReceivedDate]
			   ,NULL [ReceiveContactMethodID]
			   ,po.IssueDate [InvoiceDate]
			   ,po.PurchaseOrderAmount [InvoiceAmount]
			   ,v.Name [BillingBusinessName]
			   ,NULL [BillingContactName]
			   ,[BillingAddressLine1]
			   ,[BillingAddressLine2]
			   ,[BillingAddressLine3]
			   ,[BillingAddressCity]
			   ,[BillingAddressStateProvince]
			   ,[BillingAddressPostalCode]
			   ,[BillingAddressCountryCode]
			   ,po.IssueDate [ToBePaidDate]
			   ,NULL [ExportDate]
			   ,NULL [ExportBatchID]
			   ,po.IssueDate [PaymentDate]
			   ,po.PurchaseOrderAmount [PaymentAmount]
			   ,NULL [PaymentNumber]
			   ,NULL [CheckClearedDate]
			   ,NULL [ActualETAMinutes]
			   ,Right(c.VehicleVIN,8) [Last8OfVIN]
			   ,c.VehicleCurrentMileage [VehicleMileage]
			   ,1 [IsActive]
			   ,getdate() [CreateDate]
			   ,'system' [CreateBy]
			   ,NULL [ModifyDate]
			   ,NULL [ModifyBy]
			   ,NULL [VendorInvoicePaymentDifferenceReasonCodeID]
			   ,COALESCE(
					[dbo].[fnc_GetProgramConfigurationItemValueForProgram](C.ProgramID,
						'Application',
						NULL, 
						CASE	WHEN ISNULL(C.IsDeliveryDriver,0) = 1 
								THEN 'DeliveryDriverISPGLCheckExpenseAccount'
								ELSE 'ISPCheckGLExpenseAccount' 
								END)
						,@glAccountFromAppConfig) [GLExpenseAccount]
	From PurchaseOrder po 
	Join ServiceRequest sr on sr.ID = po.ServiceRequestID
	Join [Case] c on c.id = sr.CaseID
	Join VendorLocation vl on po.VendorLocationID = vl.ID
	Join Vendor v on v.ID = vl.VendorID
	where
	po.IsActive = 1
	and po.PurchaseOrderStatusID in (Select ID From PurchaseOrderStatus Where Name in ('Issued', 'Issued-Paid')) 
	and po.CompanyCreditCardNumber in (
	---- List of CCs issued to Managers
	'5563150000106519'
	,'5563150000106501'
	,'5563150000175787'
	,'5563150000095944')
	and Not exists (
		Select * From VendorInvoice vi where vi.PurchaseOrderID = po.ID)
	and po.IssueDate < DATEADD(dd,-10, GETDATE())

END
GO



GO

 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Product_Save_Cascade]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Product_Save_Cascade] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Vendor_Location_Product_Save_Cascade @vendorLocationID=292, @productIDs='1,2,3',@createBy = 'system'
 CREATE PROCEDURE [dbo].[dms_Vendor_Location_Product_Save_Cascade] 
 (
	  @vendorLocationID INT = NULL 
	, @productIDs NVARCHAR(MAX) = NULL
	, @createBy NVARCHAR(50) = NULL
 )
 
AS
BEGIN 

	/* KB:	When a Product is unchecked via VendorLocation -> Services, Get active RateSchedules and delete the related CRSPs */

	DECLARE @now DATETIME = GETDATE()

	DECLARE @tblNewProductList TABLE	
	(
		ProductID INT NOT NULL,
		Rating Decimal NULL
	)
	
	-- Dump the products chosen by the user into the temp table.
	INSERT INTO @tblNewProductList(ProductID)
	SELECT item FROM [dbo].[fnSplitString](@productIDs,',')
	
	
	UPDATE
		@tblNewProductList
	SET
		Rating = VLP.Rating
	FROM
		@tblNewProductList TBPL
	INNER JOIN
		VendorLocationProduct VLP 
	ON 
		TBPL.ProductID = VLP.ProductID AND VLP.VendorLocationID = @vendorLocationID
    
	

	;WITH wProductsToBeDeleted
	AS
	(
		SELECT		VLP.ProductID
		FROM		VendorLocationProduct VLP
		LEFT OUTER JOIN @tblNewProductList T ON VLP.ProductID = T.ProductID
		WHERE		T.ProductID IS NULL
		AND			VLP.VendorLocationID = @vendorLocationID
	)	
	,wCRSPsToBeDeleted
	AS
	(
		SELECT	CRSP.ID
		FROM	ContractRateScheduleProduct CRSP,
				ContractRateSchedule CRS		
		WHERE	CRSP.ContractRateScheduleID = CRS.ID
		AND		CRS.ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active') 
		AND		CRS.IsActive = 1
		AND		CRSP.VendorLocationID = @vendorLocationID
		AND		CRSP.ProductID IN ( SELECT ProductID FROM wProductsToBeDeleted)
	)


	DELETE FROM ContractRateScheduleProduct WHERE ID IN (SELECT ID FROM wCRSPsToBeDeleted)
	
	-- Delete all and insert afresh
	DELETE FROM VendorLocationProduct WHERE VendorLocationID = @vendorLocationID
	INSERT INTO VendorLocationProduct (	 VendorLocationID
										,ProductID
										,Rating
										,IsActive
										,CreateBy
										,CreateDate
									)
	SELECT	 @vendorLocationID
			,ProductID
			,Rating
			,1
			,@createBy
			,@now
	FROM	@tblNewProductList
			 

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
*  ---- for int, money, datetime ---
*  7 - GreaterThan
*  8 - GreaterThanOrEquals
*  9 - LessThan
*  10 - LessThanOrEquals
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_PO_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_PO_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
  -- EXEC [dms_Vendor_PO_List_Get] @VendorID =316
 CREATE PROCEDURE [dbo].[dms_Vendor_PO_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT = null
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ServiceRequestIDOperator="-1" 
PurchaseOrderNumberOperator="-1" 
IssueDateOperator="-1" 
PurchaseOrderAmountOperator="-1" 
StatusOperator="-1" 
ServiceOperator="-1" 
CreateByOperator="-1" 
MemberNameOperator="-1" 
MemberNumberOperator="-1" 
AddressOperator="-1" 
InvoiceNumberOperator="-1" 
InvoiceDateOperator="-1" 
InvoiceAmountOperator="-1" 
InvoiceStatusOperator="-1" 
PaymentNumberOperator="-1" 
PaidDateOperator="-1" 
PaymentAmountOperator="-1" 
CheckClearedDateOperator="-1" 
InvoiceReceivedDateOperator="-1"
InvoiceReceiveMethodOperator="-1"
InvoiceToBePaidDateOperator="-1"
PaymentTypeOperator="-1"
PurchaseOrderPayStatusCodeDescOperator="-1"
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ServiceRequestIDOperator INT NOT NULL,
ServiceRequestIDValue int NULL,
PurchaseOrderNumberOperator INT NOT NULL,
PurchaseOrderNumberValue nvarchar(100) NULL,
IssueDateOperator INT NOT NULL,
IssueDateValue datetime NULL,
PurchaseOrderAmountOperator INT NOT NULL,
PurchaseOrderAmountValue money NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL,
ServiceOperator INT NOT NULL,
ServiceValue nvarchar(100) NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(100) NULL,
MemberNameOperator INT NOT NULL,
MemberNameValue nvarchar(100) NULL,
MemberNumberOperator INT NOT NULL,
MemberNumberValue int NULL,
AddressOperator INT NOT NULL,
AddressValue nvarchar(1000) NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
InvoiceDateOperator INT NOT NULL,
InvoiceDateValue datetime NULL,
InvoiceAmountOperator INT NOT NULL,
InvoiceAmountValue money NULL,
InvoiceStatusOperator INT NOT NULL,
InvoiceStatusValue nvarchar(100) NULL,
PaymentNumberOperator INT NOT NULL,
PaymentNumberValue nvarchar(100) NULL,
PaidDateOperator INT NOT NULL,
PaidDateValue datetime NULL,
PaymentAmountOperator INT NOT NULL,
PaymentAmountValue money NULL,
CheckClearedDateOperator INT NOT NULL,
CheckClearedDateValue datetime NULL,
InvoiceReceivedDateOperator INT NOT NULL,
InvoiceReceivedDateValue datetime NULL,
InvoiceReceiveMethodOperator INT NOT NULL,
InvoiceReceiveMethodValue nvarchar(100) NULL,
InvoiceToBePaidDateOperator INT NOT NULL,
InvoiceToBePaidDateValue datetime NULL,
PaymentTypeOperator INT NOT NULL,
PaymentTypeValue nvarchar(100) NULL,
PurchaseOrderPayStatusCodeDescOperator INT NOT NULL,
PurchaseOrderPayStatusCodeDescValue nvarchar(255) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ServiceRequestID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	PurchaseOrderAmount money  NULL ,
	Status nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	MemberName nvarchar(100)  NULL ,
	MemberNumber int  NULL ,
	Address nvarchar(1000)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceDate datetime  NULL ,
	InvoiceAmount money  NULL ,
	InvoiceStatus nvarchar(100)  NULL ,
	PaymentNumber nvarchar(100)  NULL ,
	PaidDate datetime  NULL ,
	PaymentAmount money  NULL ,
	CheckClearedDate datetime  NULL ,
	InvoiceReceivedDate datetime NULL ,
	InvoiceReceiveMethod nvarchar(100) NULL ,
	InvoiceToBePaidDate datetime NULL ,
	PaymentType nvarchar(100) NULL ,
	PurchaseOrderID INT NULL,
	PurchaseOrderPayStatusCodeDesc nvarchar(255) NULL
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ServiceRequestID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	PurchaseOrderAmount money  NULL ,
	Status nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	MemberName nvarchar(100)  NULL ,
	MemberNumber int  NULL ,
	Address nvarchar(1000)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceDate datetime  NULL ,
	InvoiceAmount money  NULL ,
	InvoiceStatus nvarchar(100)  NULL ,
	PaymentNumber nvarchar(100)  NULL ,
	PaidDate datetime  NULL ,
	PaymentAmount money  NULL ,
	CheckClearedDate datetime  NULL ,
	InvoiceReceivedDate datetime NULL ,
	InvoiceReceiveMethod nvarchar(100) NULL ,
	InvoiceToBePaidDate datetime NULL ,
	PaymentType nvarchar(100) NULL ,
	PurchaseOrderID INT NULL,
	PurchaseOrderPayStatusCodeDesc nvarchar(255) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ServiceRequestIDOperator','INT'),-1),
	T.c.value('@ServiceRequestIDValue','int') ,
	ISNULL(T.c.value('@PurchaseOrderNumberOperator','INT'),-1),
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IssueDateOperator','INT'),-1),
	T.c.value('@IssueDateValue','datetime') ,
	ISNULL(T.c.value('@PurchaseOrderAmountOperator','INT'),-1),
	T.c.value('@PurchaseOrderAmountValue','money') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberNameOperator','INT'),-1),
	T.c.value('@MemberNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@MemberNumberOperator','INT'),-1),
	T.c.value('@MemberNumberValue','int') ,
	ISNULL(T.c.value('@AddressOperator','INT'),-1),
	T.c.value('@AddressValue','nvarchar(1000)') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceDateOperator','INT'),-1),
	T.c.value('@InvoiceDateValue','datetime') ,
	ISNULL(T.c.value('@InvoiceAmountOperator','INT'),-1),
	T.c.value('@InvoiceAmountValue','money') ,
	ISNULL(T.c.value('@InvoiceStatusOperator','INT'),-1),
	T.c.value('@InvoiceStatusValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaymentNumberOperator','INT'),-1),
	T.c.value('@PaymentNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaidDateOperator','INT'),-1),
	T.c.value('@PaidDateValue','datetime') ,
	ISNULL(T.c.value('@PaymentAmountOperator','INT'),-1),
	T.c.value('@PaymentAmountValue','money') ,
	ISNULL(T.c.value('@CheckClearedDateOperator','INT'),-1),
	T.c.value('@CheckClearedDateValue','datetime') ,
	ISNULL(T.c.value('@InvoiceReceivedDateOperator','INT'),-1),
	T.c.value('@InvoiceReceivedDateValue','datetime') ,
	ISNULL(T.c.value('@InvoiceReceiveMethodOperator','INT'),-1),
	T.c.value('@InvoiceReceiveMethodValue','nvarchar(100)')  ,
	ISNULL(T.c.value('@InvoiceToBePaidDateOperator','INT'),-1),
	T.c.value('@InvoiceToBePaidDateValue','datetime') ,
	ISNULL(T.c.value('@PaymentTypeOperator','INT'),-1),
	T.c.value('@PaymentTypeValue','nvarchar(100)'),
	ISNULL(T.c.value('@PurchaseOrderPayStatusCodeDescOperator','INT'),-1),
	T.c.value('@PurchaseOrderPayStatusCodeDescValue','nvarchar(255)')
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT PO.ID
, SR.ID AS ServiceRequestID
, PO.PurchaseOrderNumber
, ISNULL(CONVERT(NVARCHAR(10),PO.IssueDate,101),'') AS IssueDate
, PO.PurchaseOrderAmount
, POS.Name AS [Status]
, P.Name AS [Service]
, PO.CreateBy 
, ISNULL(REPLACE(RTRIM(
COALESCE(M.FirstName, '') +
COALESCE(' ' + M.MiddleName, '') +
COALESCE(' ' + M.LastName, '') +
COALESCE(' ' + M.Suffix, '') 
), ' ', ' ' )
,'') AS [MemberName] 
, M.MembershipID AS MemberNumber
, ISNULL(REPLACE(RTRIM(
COALESCE(PO.BillingAddressLine1, '') + 
COALESCE(PO.BillingAddressLine2, '') + 
COALESCE(PO.BillingAddressLine3, '') + 
COALESCE(', ' + PO.BillingAddressCity, '') +
COALESCE(', ' + RTRIM(PO.BillingAddressStateProvince), '') +
COALESCE(' ' + PO.BillingAddressPostalCode, '') +
COALESCE(' ' + PO.BillingAddressCountryCode, '') 
), ' ', ' ')
,'') AS [Address]
, VI.InvoiceNumber
, VI.InvoiceDate
, VI.InvoiceAmount
, VIS.Name AS [InvoiceStatus]
, VI.PaymentNumber
, VI.PaymentDate AS [PaidDate]
, VI.PaymentAmount 
, VI.CheckClearedDate
, VI.ReceivedDate
, CM.Name
, VI.ToBePaidDate
, CASE 
WHEN VIS.Name = 'Paid' THEN PT.NAME 
WHEN ISNULL(VIS.Name,'') <> 'Paid' AND ISNULL(ACH.ID,'') <> '' AND ISNULL(V.IsLevyActive,'') <> 1 THEN 'ACH' 
ELSE 'Check' 
END AS PaymentType 
, PO.ID AS PurchaseOrderID
,POSC.Description
FROM PurchaseOrder PO
LEFT OUTER JOIN PurchaseOrderPayStatusCode POSC
	ON POSC.ID = PO.PayStatusCodeID
LEFT OUTER JOIN VendorLocation VL 
	ON VL.ID = PO.VendorLocationID
LEFT OUTER JOIN Vendor V
	ON V.ID = VL.VendorID
LEFT OUTER JOIN ServiceRequest SR
	ON SR.ID = PO.ServiceRequestID
LEFT OUTER JOIN [Case] C 
	ON C.ID = SR.CaseID
LEFT OUTER JOIN Member M
	ON M.ID = C.MemberID
LEFT OUTER JOIN PurchaseOrderStatus POS
	ON POS.ID = PO.PurchaseOrderStatusID
LEFT OUTER JOIN Product P -- Really need to verify through PODetail
	ON P.ID = PO.ProductID
LEFT OUTER JOIN VendorInvoice VI
	ON VI.PurchaseOrderID = PO.ID AND VI.IsActive=1
LEFT OUTER JOIN VendorInvoiceStatus VIS
	ON VIS.ID = VI.VendorInvoiceStatusID 
LEFT OUTER JOIN ContactMethod CM
	ON CM.ID=VI.ReceiveContactMethodID
LEFT OUTER JOIN PaymentType PT 
	ON VI.PaymentTypeID=PT.ID
LEFT OUTER JOIN VendorACH ACH
	ON ACH.VendorID = V.ID AND ACH.IsActive = 1
WHERE PO.IsActive = 1 
--AND VI.IsActive = 1
AND V.ID = @VendorID
AND POS.Name <> 'Pending'
ORDER BY PO.PurchaseOrderNumber DESC


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.ServiceRequestID,
	T.PurchaseOrderNumber,
	T.IssueDate,
	T.PurchaseOrderAmount,
	T.Status,
	T.Service,
	T.CreateBy,
	T.MemberName,
	T.MemberNumber,
	T.Address,
	T.InvoiceNumber,
	T.InvoiceDate,
	T.InvoiceAmount,
	T.InvoiceStatus,
	T.PaymentNumber,
	T.PaidDate,
	T.PaymentAmount,
	T.CheckClearedDate,	
	T.InvoiceReceivedDate,
	T.InvoiceReceiveMethod,
	T.InvoiceToBePaidDate,
	T.PaymentType,
	T.PurchaseOrderID,
	T.PurchaseOrderPayStatusCodeDesc
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
	 ( TMP.ServiceRequestIDOperator = -1 ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 0 AND T.ServiceRequestID IS NULL ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 1 AND T.ServiceRequestID IS NOT NULL ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 2 AND T.ServiceRequestID = TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 3 AND T.ServiceRequestID <> TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 7 AND T.ServiceRequestID > TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 8 AND T.ServiceRequestID >= TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 9 AND T.ServiceRequestID < TMP.ServiceRequestIDValue ) 
 OR 
	 ( TMP.ServiceRequestIDOperator = 10 AND T.ServiceRequestID <= TMP.ServiceRequestIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PurchaseOrderNumberOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 0 AND T.PurchaseOrderNumber IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 1 AND T.PurchaseOrderNumber IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 2 AND T.PurchaseOrderNumber = TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 3 AND T.PurchaseOrderNumber <> TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 4 AND T.PurchaseOrderNumber LIKE TMP.PurchaseOrderNumberValue + '%') 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 5 AND T.PurchaseOrderNumber LIKE '%' + TMP.PurchaseOrderNumberValue ) 
 OR 
	 ( TMP.PurchaseOrderNumberOperator = 6 AND T.PurchaseOrderNumber LIKE '%' + TMP.PurchaseOrderNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IssueDateOperator = -1 ) 
 OR 
	 ( TMP.IssueDateOperator = 0 AND T.IssueDate IS NULL ) 
 OR 
	 ( TMP.IssueDateOperator = 1 AND T.IssueDate IS NOT NULL ) 
 OR 
	 ( TMP.IssueDateOperator = 2 AND T.IssueDate = TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 3 AND T.IssueDate <> TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 7 AND T.IssueDate > TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 8 AND T.IssueDate >= TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 9 AND T.IssueDate < TMP.IssueDateValue ) 
 OR 
	 ( TMP.IssueDateOperator = 10 AND T.IssueDate <= TMP.IssueDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PurchaseOrderAmountOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 0 AND T.PurchaseOrderAmount IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 1 AND T.PurchaseOrderAmount IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 2 AND T.PurchaseOrderAmount = TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 3 AND T.PurchaseOrderAmount <> TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 7 AND T.PurchaseOrderAmount > TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 8 AND T.PurchaseOrderAmount >= TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 9 AND T.PurchaseOrderAmount < TMP.PurchaseOrderAmountValue ) 
 OR 
	 ( TMP.PurchaseOrderAmountOperator = 10 AND T.PurchaseOrderAmount <= TMP.PurchaseOrderAmountValue ) 

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
	 ( TMP.ServiceOperator = -1 ) 
 OR 
	 ( TMP.ServiceOperator = 0 AND T.Service IS NULL ) 
 OR 
	 ( TMP.ServiceOperator = 1 AND T.Service IS NOT NULL ) 
 OR 
	 ( TMP.ServiceOperator = 2 AND T.Service = TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 3 AND T.Service <> TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 4 AND T.Service LIKE TMP.ServiceValue + '%') 
 OR 
	 ( TMP.ServiceOperator = 5 AND T.Service LIKE '%' + TMP.ServiceValue ) 
 OR 
	 ( TMP.ServiceOperator = 6 AND T.Service LIKE '%' + TMP.ServiceValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CreateByOperator = -1 ) 
 OR 
	 ( TMP.CreateByOperator = 0 AND T.CreateBy IS NULL ) 
 OR 
	 ( TMP.CreateByOperator = 1 AND T.CreateBy IS NOT NULL ) 
 OR 
	 ( TMP.CreateByOperator = 2 AND T.CreateBy = TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 3 AND T.CreateBy <> TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 4 AND T.CreateBy LIKE TMP.CreateByValue + '%') 
 OR 
	 ( TMP.CreateByOperator = 5 AND T.CreateBy LIKE '%' + TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 6 AND T.CreateBy LIKE '%' + TMP.CreateByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MemberNameOperator = -1 ) 
 OR 
	 ( TMP.MemberNameOperator = 0 AND T.MemberName IS NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 1 AND T.MemberName IS NOT NULL ) 
 OR 
	 ( TMP.MemberNameOperator = 2 AND T.MemberName = TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 3 AND T.MemberName <> TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 4 AND T.MemberName LIKE TMP.MemberNameValue + '%') 
 OR 
	 ( TMP.MemberNameOperator = 5 AND T.MemberName LIKE '%' + TMP.MemberNameValue ) 
 OR 
	 ( TMP.MemberNameOperator = 6 AND T.MemberName LIKE '%' + TMP.MemberNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MemberNumberOperator = -1 ) 
 OR 
	 ( TMP.MemberNumberOperator = 0 AND T.MemberNumber IS NULL ) 
 OR 
	 ( TMP.MemberNumberOperator = 1 AND T.MemberNumber IS NOT NULL ) 
 OR 
	 ( TMP.MemberNumberOperator = 2 AND T.MemberNumber = TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 3 AND T.MemberNumber <> TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 7 AND T.MemberNumber > TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 8 AND T.MemberNumber >= TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 9 AND T.MemberNumber < TMP.MemberNumberValue ) 
 OR 
	 ( TMP.MemberNumberOperator = 10 AND T.MemberNumber <= TMP.MemberNumberValue ) 

 ) 

 AND 

 ( 
	 ( TMP.AddressOperator = -1 ) 
 OR 
	 ( TMP.AddressOperator = 0 AND T.Address IS NULL ) 
 OR 
	 ( TMP.AddressOperator = 1 AND T.Address IS NOT NULL ) 
 OR 
	 ( TMP.AddressOperator = 2 AND T.Address = TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 3 AND T.Address <> TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 4 AND T.Address LIKE TMP.AddressValue + '%') 
 OR 
	 ( TMP.AddressOperator = 5 AND T.Address LIKE '%' + TMP.AddressValue ) 
 OR 
	 ( TMP.AddressOperator = 6 AND T.Address LIKE '%' + TMP.AddressValue + '%' ) 
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
	 ( TMP.InvoiceDateOperator = -1 ) 
 OR 
	 ( TMP.InvoiceDateOperator = 0 AND T.InvoiceDate IS NULL ) 
 OR 
	 ( TMP.InvoiceDateOperator = 1 AND T.InvoiceDate IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceDateOperator = 2 AND T.InvoiceDate = TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 3 AND T.InvoiceDate <> TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 7 AND T.InvoiceDate > TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 8 AND T.InvoiceDate >= TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 9 AND T.InvoiceDate < TMP.InvoiceDateValue ) 
 OR 
	 ( TMP.InvoiceDateOperator = 10 AND T.InvoiceDate <= TMP.InvoiceDateValue ) 

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

 ( 
	 ( TMP.InvoiceStatusOperator = -1 ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 0 AND T.InvoiceStatus IS NULL ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 1 AND T.InvoiceStatus IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 2 AND T.InvoiceStatus = TMP.InvoiceStatusValue ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 3 AND T.InvoiceStatus <> TMP.InvoiceStatusValue ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 4 AND T.InvoiceStatus LIKE TMP.InvoiceStatusValue + '%') 
 OR 
	 ( TMP.InvoiceStatusOperator = 5 AND T.InvoiceStatus LIKE '%' + TMP.InvoiceStatusValue ) 
 OR 
	 ( TMP.InvoiceStatusOperator = 6 AND T.InvoiceStatus LIKE '%' + TMP.InvoiceStatusValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PaymentNumberOperator = -1 ) 
 OR 
	 ( TMP.PaymentNumberOperator = 0 AND T.PaymentNumber IS NULL ) 
 OR 
	 ( TMP.PaymentNumberOperator = 1 AND T.PaymentNumber IS NOT NULL ) 
 OR 
	 ( TMP.PaymentNumberOperator = 2 AND T.PaymentNumber = TMP.PaymentNumberValue ) 
 OR 
	 ( TMP.PaymentNumberOperator = 3 AND T.PaymentNumber <> TMP.PaymentNumberValue ) 
 OR 
	 ( TMP.PaymentNumberOperator = 4 AND T.PaymentNumber LIKE TMP.PaymentNumberValue + '%') 
 OR 
	 ( TMP.PaymentNumberOperator = 5 AND T.PaymentNumber LIKE '%' + TMP.PaymentNumberValue ) 
 OR 
	 ( TMP.PaymentNumberOperator = 6 AND T.PaymentNumber LIKE '%' + TMP.PaymentNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PaidDateOperator = -1 ) 
 OR 
	 ( TMP.PaidDateOperator = 0 AND T.PaidDate IS NULL ) 
 OR 
	 ( TMP.PaidDateOperator = 1 AND T.PaidDate IS NOT NULL ) 
 OR 
	 ( TMP.PaidDateOperator = 2 AND T.PaidDate = TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 3 AND T.PaidDate <> TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 7 AND T.PaidDate > TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 8 AND T.PaidDate >= TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 9 AND T.PaidDate < TMP.PaidDateValue ) 
 OR 
	 ( TMP.PaidDateOperator = 10 AND T.PaidDate <= TMP.PaidDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PaymentAmountOperator = -1 ) 
 OR 
	 ( TMP.PaymentAmountOperator = 0 AND T.PaymentAmount IS NULL ) 
 OR 
	 ( TMP.PaymentAmountOperator = 1 AND T.PaymentAmount IS NOT NULL ) 
 OR 
	 ( TMP.PaymentAmountOperator = 2 AND T.PaymentAmount = TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 3 AND T.PaymentAmount <> TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 7 AND T.PaymentAmount > TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 8 AND T.PaymentAmount >= TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 9 AND T.PaymentAmount < TMP.PaymentAmountValue ) 
 OR 
	 ( TMP.PaymentAmountOperator = 10 AND T.PaymentAmount <= TMP.PaymentAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CheckClearedDateOperator = -1 ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 0 AND T.CheckClearedDate IS NULL ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 1 AND T.CheckClearedDate IS NOT NULL ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 2 AND T.CheckClearedDate = TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 3 AND T.CheckClearedDate <> TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 7 AND T.CheckClearedDate > TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 8 AND T.CheckClearedDate >= TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 9 AND T.CheckClearedDate < TMP.CheckClearedDateValue ) 
 OR 
	 ( TMP.CheckClearedDateOperator = 10 AND T.CheckClearedDate <= TMP.CheckClearedDateValue ) 

 ) 

AND 

 ( 
	 ( TMP.InvoiceReceivedDateOperator = -1 ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 0 AND T.InvoiceReceivedDate IS NULL ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 1 AND T.InvoiceReceivedDate IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 2 AND T.InvoiceReceivedDate = TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 3 AND T.InvoiceReceivedDate <> TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 7 AND T.InvoiceReceivedDate > TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 8 AND T.InvoiceReceivedDate >= TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 9 AND T.InvoiceReceivedDate < TMP.InvoiceReceivedDateValue ) 
 OR 
	 ( TMP.InvoiceReceivedDateOperator = 10 AND T.InvoiceReceivedDate <= TMP.InvoiceReceivedDateValue ) 

 ) 

AND 

 ( 
	 ( TMP.InvoiceReceiveMethodOperator = -1 ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 0 AND T.InvoiceReceiveMethod IS NULL ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 1 AND T.InvoiceReceiveMethod IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 2 AND T.InvoiceReceiveMethod = TMP.InvoiceReceiveMethodValue ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 3 AND T.InvoiceReceiveMethod <> TMP.InvoiceReceiveMethodValue ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 4 AND T.InvoiceReceiveMethod LIKE TMP.InvoiceReceiveMethodValue + '%') 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 5 AND T.InvoiceReceiveMethod LIKE '%' + TMP.InvoiceReceiveMethodValue ) 
 OR 
	 ( TMP.InvoiceReceiveMethodOperator = 6 AND T.InvoiceReceiveMethod LIKE '%' + TMP.InvoiceReceiveMethodValue + '%' ) 
 ) 

AND 

 ( 
	 ( TMP.InvoiceToBePaidDateOperator = -1 ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 0 AND T.InvoiceToBePaidDate IS NULL ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 1 AND T.InvoiceToBePaidDate IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 2 AND T.InvoiceToBePaidDate = TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 3 AND T.InvoiceToBePaidDate <> TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 7 AND T.InvoiceToBePaidDate > TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 8 AND T.InvoiceToBePaidDate >= TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 9 AND T.InvoiceToBePaidDate < TMP.InvoiceToBePaidDateValue ) 
 OR 
	 ( TMP.InvoiceToBePaidDateOperator = 10 AND T.InvoiceToBePaidDate <= TMP.InvoiceToBePaidDateValue ) 

 ) 

AND 

 ( 
	 ( TMP.PaymentTypeOperator = -1 ) 
 OR 
	 ( TMP.PaymentTypeOperator = 0 AND T.PaymentType IS NULL ) 
 OR 
	 ( TMP.PaymentTypeOperator = 1 AND T.PaymentType IS NOT NULL ) 
 OR 
	 ( TMP.PaymentTypeOperator = 2 AND T.PaymentType = TMP.PaymentTypeValue ) 
 OR 
	 ( TMP.PaymentTypeOperator = 3 AND T.PaymentType <> TMP.PaymentTypeValue ) 
 OR 
	 ( TMP.PaymentTypeOperator = 4 AND T.PaymentType LIKE TMP.PaymentTypeValue + '%') 
 OR 
	 ( TMP.PaymentTypeOperator = 5 AND T.PaymentType LIKE '%' + TMP.PaymentTypeValue ) 
 OR 
	 ( TMP.PaymentTypeOperator = 6 AND T.PaymentType LIKE '%' + TMP.PaymentTypeValue + '%' ) 
 ) 
 AND 

 ( 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = -1 ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 0 AND T.PurchaseOrderPayStatusCodeDesc IS NULL ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 1 AND T.PurchaseOrderPayStatusCodeDesc IS NOT NULL ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 2 AND T.PurchaseOrderPayStatusCodeDesc = TMP.PurchaseOrderPayStatusCodeDescValue ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 3 AND T.PurchaseOrderPayStatusCodeDesc <> TMP.PurchaseOrderPayStatusCodeDescValue ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 4 AND T.PurchaseOrderPayStatusCodeDesc LIKE TMP.PurchaseOrderPayStatusCodeDescValue + '%') 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 5 AND T.PurchaseOrderPayStatusCodeDesc LIKE '%' + TMP.PurchaseOrderPayStatusCodeDescValue ) 
 OR 
	 ( TMP.PurchaseOrderPayStatusCodeDescOperator = 6 AND T.PurchaseOrderPayStatusCodeDesc LIKE '%' + TMP.PurchaseOrderPayStatusCodeDescValue + '%' ) 
 )
 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'ASC'
	 THEN T.ServiceRequestID END ASC, 
	 CASE WHEN @sortColumn = 'ServiceRequestID' AND @sortOrder = 'DESC'
	 THEN T.ServiceRequestID END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderNumber END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderNumber END DESC ,

	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'
	 THEN T.IssueDate END ASC, 
	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'
	 THEN T.IssueDate END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderAmount END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderAmount' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderAmount END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'ASC'
	 THEN T.MemberName END ASC, 
	 CASE WHEN @sortColumn = 'MemberName' AND @sortOrder = 'DESC'
	 THEN T.MemberName END DESC ,

	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'ASC'
	 THEN T.MemberNumber END ASC, 
	 CASE WHEN @sortColumn = 'MemberNumber' AND @sortOrder = 'DESC'
	 THEN T.MemberNumber END DESC ,

	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'ASC'
	 THEN T.Address END ASC, 
	 CASE WHEN @sortColumn = 'Address' AND @sortOrder = 'DESC'
	 THEN T.Address END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

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

	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'ASC'
	 THEN T.PaymentNumber END ASC, 
	 CASE WHEN @sortColumn = 'PaymentNumber' AND @sortOrder = 'DESC'
	 THEN T.PaymentNumber END DESC ,

	 CASE WHEN @sortColumn = 'PaidDate' AND @sortOrder = 'ASC'
	 THEN T.PaidDate END ASC, 
	 CASE WHEN @sortColumn = 'PaidDate' AND @sortOrder = 'DESC'
	 THEN T.PaidDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC ,

	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'ASC'
	 THEN T.CheckClearedDate END ASC, 
	 CASE WHEN @sortColumn = 'CheckClearedDate' AND @sortOrder = 'DESC'
	 THEN T.CheckClearedDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceReceivedDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceivedDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceReceivedDate END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'ASC'
	 THEN T.InvoiceReceiveMethod END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceReceiveMethod' AND @sortOrder = 'DESC'
	 THEN T.InvoiceReceiveMethod END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceToBePaidDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceToBePaidDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'
	 THEN T.PaymentType END ASC, 
	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'
	 THEN T.PaymentType END DESC,
	 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCodeDesc' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderPayStatusCodeDesc END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderPayStatusCodeDesc' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderPayStatusCodeDesc END DESC


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
 WHERE id = object_id(N'[dbo].[dms_Vendor_UpdateAdminisrativeRating]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_UpdateAdminisrativeRating] 
 END 
 GO  
 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Vendor_UpdateAdminisrativeRating] 
AS
BEGIN

      Update v1 Set 
      --select v1.id, (Select name from VendorStatus where id = v1.VendorStatusID), v1.vendornumber, v1.AdministrativeRating,
            AdministrativeRating = v2.AdministrativeRating,
            AdministrativeRatingModifyDate = GETDATE()
      From vendor v1
      JOIN (
            SELECT v.ID, v.VendorNumber
                  ,CASE WHEN ContractVendor.VendorID IS NOT NULL THEN 60 ELSE 20 END +
                   CASE WHEN v.InsuranceExpirationDate >= getdate() THEN 10 ELSE 0 END +
                   CASE WHEN ach.ID IS NOT NULL THEN 10 ELSE 0 END +
                   CASE WHEN [24Hours].VendorID IS NOT NULL THEN 10 ELSE 0 END +
                   CASE WHEN (v.TaxSSN IS NOT NULL AND LEN(v.TaxSSN) = 9) OR v.TaxEIN IS NOT NULL THEN 10 ELSE 0 END AS AdministrativeRating
            FROM dbo.Vendor v
            LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractVendor On ContractVendor.VendorID = v.ID
            LEFT OUTER JOIN VendorACH ach ON ach.VendorID = v.ID AND ach.IsActive = 1 AND ach.ACHStatusID = (SELECT ID FROM ACHStatus WHERE Name = 'Valid')
            LEFT OUTER JOIN (
                  Select VendorID
                  From VendorLocation 
                  Where IsOpen24Hours = 'TRUE'
                  Group By VendorID
                  ) [24Hours] On [24Hours].VendorID = v.ID
            ) v2 on v2.ID = v1.ID
      where ISNULL(v1.AdministrativeRating, 0) <> v2.AdministrativeRating
      and v1.VendorStatusID = (SELECT ID FROM VendorStatus WHERE Name = 'Active')
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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceBenefit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC dms_VerifyProgramServiceBenefit 1, 1, 1, 1, 1, NULL, NULL  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceBenefit]  
       @ProgramID INT   
      , @ProductCategoryID INT  
      , @VehicleCategoryID INT  
      , @VehicleTypeID INT  
      , @SecondaryCategoryID INT = NULL  
      , @ServiceRequestID  INT = NULL  
      , @ProductID INT = NULL  
      , @IsPrimaryOverride BIT = NULL
AS  
BEGIN   
  
	SET NOCOUNT ON    
	SET FMTONLY OFF    

	--KB: 
	SET @ProductID = NULL

	DECLARE @SecondaryProductID INT
		,@OverrideCoverageLimit money 

	/*** Determine Primary and Secondary Product IDs ***/  
	/* Ignore Vehicle related values for Product Categories not requiring a Vehicle */
	IF @ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE IsVehicleRequired = 0)
	BEGIN
		SET @VehicleCategoryID = NULL
		SET @VehicleTypeID = NULL
	END

	/* Select Basic Lockout over Locksmith when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Lockout')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name = 'Basic Lockout')  
	END  

	/* Select Tire Change over Tire Repair when a specific product is not provided */  
	IF @ProductID IS NULL AND @ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tire')  
	BEGIN  
	SET @ProductID = (SELECT ID FROM Product WHERE Name like 'Tire Change%' AND VehicleCategoryID = @VehicleCategoryID)  
	END  

	IF @ProductID IS NULL  
	SELECT @ProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @ProductCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  


	IF @SecondaryCategoryID IS NOT NULL  
	SELECT @SecondaryProductID = p.ID   
	FROM  ProductCategory pc (NOLOCK)   
	JOIN  Product p (NOLOCK) ON pc.id = p.ProductCategoryID   
	  AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service')  
	  AND p.ProductSubTypeID = (SELECT ID FROM ProductSubType WHERE Name = 'PrimaryService')  
	WHERE  
	pc.ID = @SecondaryCategoryID   
	AND (@VehicleCategoryID IS NULL OR p.VehicleCategoryID IS NULL OR p.VehicleCategoryID = @VehicleCategoryID)  
	AND (@VehicleTypeID IS NULL OR p.VehicleTypeID IS NULL OR p.VehicleTypeID = @VehicleTypeID)  


	-- Coverage Limit Override for Ford ESP vehicles E/F 650 and 750; Blue Bird Bus
	IF @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Extended Service Plan (RV & COMM)')
	BEGIN
	
	----Override for Ford Medium and Heavy Duty
	---- TP 10/1 - All Ford Comm now $200 - Logic no longer needed
	--IF EXISTS(
	--	SELECT * 
	--	FROM [Case] c
	--	JOIN ServiceRequest sr ON sr.CaseID = c.ID
	--	WHERE sr.ID = @ServiceRequestID
	--		AND (SUBSTRING(c.VehicleVIN, 6, 1) IN ('6','7')
	--			OR c.VehicleModel IN ('F-650', 'F-750', 'E-650', 'E-750'))
	--	)
	--	SET @OverrideCoverageLimit = 200.00
		
	-- Override for Ford Bluebird bus	
	IF EXISTS(
		SELECT * 
		FROM [Case] c
		JOIN ServiceRequest sr ON sr.CaseID = c.ID
		WHERE sr.ID = @ServiceRequestID
			AND c.VehicleMake = 'Blue bird'
		)
		SET @OverrideCoverageLimit = 400.00	
	END
   
   
	SELECT ISNULL(pc.Name,'') ProductCategoryName  
		,pc.ID ProductCategoryID  
		--,pc.Sequence  
		,ISNULL(vc.Name,'') VehicleCategoryName  
		,vc.ID VehicleCategoryID  
		,pp.ProductID  

		,CAST (pp.IsServiceCoverageBestValue AS BIT) AS IsServiceCoverageBestValue
		,CASE WHEN @OverrideCoverageLimit IS NOT NULL THEN @OverrideCoverageLimit ELSE pp.ServiceCoverageLimit END AS ServiceCoverageLimit
		,pp.CurrencyTypeID   
		,pp.ServiceMileageLimit   
		,pp.ServiceMileageLimitUOM   
		,1 AS IsServiceEligible
		--TP: Below logic is not needed; Only eligible services will be added to ProgramProduct 
		--,CASE WHEN pp.ServiceCoverageLimit IS NULL THEN 0   
		--              WHEN pp.IsServiceCoverageBestValue = 1 THEN 1  
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 1 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND ISNULL(pp.ServiceMileageLimit,0) > 0 THEN 1   
		--              WHEN pp.ServiceCoverageLimit = 0 AND pp.ProductID IN (SELECT p.ID FROM Product p WHERE p.ProductCategoryID IN (SELECT ID FROM ProductCategory WHERE Name IN ('Info', 'Tech', 'Concierge'))) THEN 1
		--              WHEN pp.ServiceCoverageLimit > 0 THEN 1  
		--              ELSE 0 END IsServiceEligible  
		,pp.IsServiceGuaranteed   
		,pp.ServiceCoverageDescription  
		,pp.IsReimbursementOnly  
		,CASE WHEN ISNULL(@IsPrimaryOverride,0) = 0 AND pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END AS IsPrimary  
	FROM ProgramProduct pp (NOLOCK)  
	JOIN Product p ON p.ID = pp.ProductID  
	LEFT OUTER JOIN ProductCategory pc (NOLOCK) ON pc.ID = p.ProductCategoryID  
	LEFT OUTER JOIN VehicleCategory vc (NOLOCK) ON vc.id = p.VehicleCategoryID  
	WHERE pp.ProgramID = @ProgramID  
	AND (pp.ProductID = @ProductID OR pp.ProductID = @SecondaryProductID)  
	ORDER BY   
	(CASE WHEN pc.ID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC  
	,pc.Sequence  
     
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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

 --EXEC dms_VerifyProgramServiceEventLimit 1, 3,1,null, null, null  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit]  
      @ServiceRequestID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int 
      ,@VehicleTypeID int
      ,@VehicleCategoryID int 
      ,@SecondaryCategoryID INT = NULL
AS
BEGIN

	----Debug
	--DECLARE 
	--      @ServiceRequestID int = 7779982
	--      ,@ProgramID int = 3
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 1
	--      ,@VehicleCategoryID int = 1
	--      ,@SecondaryCategoryID INT = 1

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@ProgramServiceEventLimitID int
		,@ProgramServiceEventLimitStoredProcedureName nvarchar(255)
		,@ProgramServiceEventLimitDescription nvarchar(255)
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime

	SELECT @MemberID = m.ID
	  ,@MemberExpirationDate = m.ExpirationDate
	  ,@ProgramID = CASE WHEN @ProgramID IS NULL THEN m.ProgramID ELSE  @ProgramID END
	FROM ServiceRequest SR 
	JOIN [Case] c on c.id = SR.CaseID
	JOIN Member m on m.ID = c.MemberID
	WHERE SR.ID = @ServiceRequestID
	
	-- Determine last annual renewal date 
	SET @MemberRenewalDate = DATEADD(yy, (ROUND(DATEDIFF(dd, getdate(), @MemberExpirationDate)/365.00,0,1) + 1)*-1, @MemberExpirationDate)
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	-- Check for a custom stored procedure that verifies the event limits for this program
	SELECT TOP 1 
		@ProgramServiceEventLimitID = ID
		,@ProgramServiceEventLimitStoredProcedureName = StoredProcedureName
		,@ProgramServiceEventLimitDescription = [Description]
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	AND StoredProcedureName IS NOT NULL
	AND IsActive = 1
	
	
	IF @ProgramServiceEventLimitStoredProcedureName IS NOT NULL
		-- Custome stored procedure used to verify the event limits for the program
		BEGIN
		
		DECLARE @LimitEligibilityResults TABLE (
			ID int
			,ProgramID int
			,[Description] nvarchar(255)
			,Limit int
			,EventCount int
			,IsPrimary int
			,IsEligible int)
		
		INSERT INTO @LimitEligibilityResults	
		EXECUTE @ProgramServiceEventLimitStoredProcedureName 
		   @ServiceRequestID
		  ,@ProgramID
		  ,@ProductCategoryID
		  ,@ProductID
		  ,@VehicleTypeID
		  ,@VehicleCategoryID
		  ,@SecondaryCategoryID

		SELECT 
			@ProgramServiceEventLimitID ID
			,@ProgramID ProgramID
			,@ProgramServiceEventLimitDescription [Description]
			,Limit
			,EventCount
			,IsPrimary
			,IsEligible
		FROM @LimitEligibilityResults
			
		END
	
	ELSE
		-- Event limits are configured for specific program products
		BEGIN
		Select 
				ServiceRequestEvent.ProgramServiceEventLimitID
				,ServiceRequestEvent.ProgramEventLimitDescription
				,ServiceRequestEvent.ProgramEventLimit
				,ServiceRequestEvent.ProgramID
				,ServiceRequestEvent.MemberID
				,ServiceRequestEvent.ProductCategoryID
				,ServiceRequestEvent.ProductID
				,MIN(MinEventDate) MinEventDate
				,count(*) EventCount
			Into #tmpProgramEventCount
			From (
				Select 
					  ppl.ID ProgramServiceEventLimitID
					  ,ppl.[Description] ProgramEventLimitDescription
					  ,ppl.Limit ProgramEventLimit
					  ,c.ProgramID 
					  ,c.MemberID
					  ,sr.ID ServiceRequestID
					  ,ppl.ProductCategoryID
					  ,ppl.ProductID
					  ,pc.Name ProductCategoryName
					  ,MIN(po.IssueDate) MinEventDate 
				From [Case] c
				Join ServiceRequest sr on c.ID = sr.CaseID
				Join PurchaseOrder po on sr.ID = po.ServiceRequestID and po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid')) and po.IsActive = 1
				Join Product p on po.ProductID = p.ID
				Join ProductCategory pc on pc.id = p.ProductCategoryID
				Join ProgramServiceEventLimit ppl on ppl.ProgramID = c.ProgramID 
					  and (ppl.ProductCategoryID IS NULL OR ppl.ProductCategoryID = pc.ID)
					  and (ppl.ProductID IS NULL OR ppl.ProductID = p.ID)
					  and ppl.IsActive = 1
					  and po.IssueDate > 
							CASE WHEN ppl.IsLimitDurationSinceMemberRenewal = 1
									AND @MemberRenewalDate > (
										CASE WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
											 ELSE NULL
											 END
										) THEN @MemberRenewalDate
  								 WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
								 ELSE NULL
							END 
				Where 
					  c.MemberID = @MemberID
					  and c.ProgramID = @ProgramID
					  and po.IssueDate IS NOT NULL
					  and sr.ID <> @ServiceRequestID
				Group By 
					  ppl.ID
					  ,ppl.[Description]
					  ,ppl.Limit
					  ,c.programid
					  ,c.MemberID
					  ,sr.ID
					  ,ppl.ProductCategoryID
					  ,ppl.ProductID
					  ,pc.Name
				) ServiceRequestEvent
			Group By 
				ServiceRequestEvent.ProgramServiceEventLimitID
				,ServiceRequestEvent.ProgramEventLimit
				,ServiceRequestEvent.ProgramEventLimitDescription
				,ServiceRequestEvent.ProgramID
				,ServiceRequestEvent.MemberID
				,ServiceRequestEvent.ProductCategoryID
				,ServiceRequestEvent.ProductID


			Select 
				psel.ID --ProgramServiceEventLimitID
				,psel.ProgramID
				,psel.[Description]
				,psel.Limit
				,ISNULL(pec.EventCount, 0) EventCount
				,CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID THEN 0 ELSE 1 END IsPrimary
				,CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END IsEligible
			From ProgramServiceEventLimit psel
			Left Outer Join #tmpProgramEventCount pec on pec.ProgramServiceEventLimitID = psel.ID
			Where psel.IsActive = 1
			AND psel.ProgramID = @ProgramID
			AND   (
					  (@ProductID IS NOT NULL 
							AND psel.ProductID = @ProductID)
					  OR
					  (@ProductID IS NULL 
							AND (psel.ProductCategoryID = @ProductCategoryID OR psel.ProductCategoryID IS NULL) 
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  )
					  OR
					  (psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  ))
			ORDER BY 
				(CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END) ASC
				,(CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC
				,psel.ProductID DESC

			Drop table #tmpProgramEventCount
		END

END

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit_Program_414]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit_Program_414] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Special service event limit logic for CNET Limited (program 414) */

CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit_Program_414]  
      @ServiceRequestID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int 
      ,@VehicleTypeID int
      ,@VehicleCategoryID int 
      ,@SecondaryCategoryID INT = NULL
AS
BEGIN

	----Debug
	--DECLARE 
	--      @ServiceRequestID int = 16256913
	--      ,@ProgramID int = 414
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 2
	--      ,@VehicleCategoryID int = 2
	--      ,@SecondaryCategoryID INT = NULL

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@Description nvarchar(255)
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime
		,@IsEligible bit 
	
	DECLARE @MembershipMembers TABLE (MembershipID int, MemberID int, IsServiceRequestMember bit)
	DECLARE @ProductEvents TABLE (ProductCategoryID int, ProductID int, ProductCategoryName nvarchar(100), EventCount int, LastEventDate datetime)


	SELECT @MemberID = m.ID
	  ,@MemberExpirationDate = m.ExpirationDate
	  ,@ProgramID = CASE WHEN @ProgramID IS NULL THEN m.ProgramID ELSE  @ProgramID END
	FROM ServiceRequest SR 
	JOIN [Case] c on c.id = SR.CaseID
	JOIN Member m on m.ID = c.MemberID
	WHERE SR.ID = @ServiceRequestID
	
	-- Determine last annual renewal date 
	SET @MemberRenewalDate = DATEADD(yy, (ROUND(DATEDIFF(dd, getdate(), @MemberExpirationDate)/365.00,0,1) + 1)*-1, @MemberExpirationDate)
	
	INSERT INTO @MembershipMembers (MembershipID, MemberID, IsServiceRequestMember)
	SELECT m.MembershipID, m.ID MemberID, CASE WHEN m.ID = @MemberID THEN 1 ELSE 0 END IsServiceRequestMember
	FROM Member m
	WHERE m.MembershipID = (
		SELECT ms.ID 
		FROM Membership ms
		JOIN Member m ON m.MembershipID = ms.ID
		WHERE m.ID = @MemberID)
	AND m.ProgramID = @ProgramID -- Insure that the member on the membership has the same program as the SR member
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	----DEBUG
	--SELECT @ProductID
	--SELECT * From @MembershipMembers
	
	-- Counting EACH PO as an occurrence VS each SR
	INSERT INTO @ProductEvents (ProductCategoryID, ProductID, ProductCategoryName, EventCount, LastEventDate)
	SELECT 
		  --sr.ID ServiceRequestID
		  p.ProductCategoryID
		  ,p.ID ProductID
		  ,pc.Name ProductCategoryName
		  ,Count(*) EventCount
		  ,MAX(po.IssueDate) LastEventDate 
	From [Case] c
	Join ServiceRequest sr on c.ID = sr.CaseID
	Join PurchaseOrder po on sr.ID = po.ServiceRequestID and po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid')) and po.IsActive = 1
	Join Product p on po.ProductID = p.ID
	Join ProductCategory pc on pc.id = p.ProductCategoryID
	Join @MembershipMembers mm on mm.MemberID = c.MemberID
	Where 1=1
		  and sr.ID <> @ServiceRequestID
		  and po.IssueDate IS NOT NULL
		  and po.IssueDate > @MemberRenewalDate
	Group By 
		  --sr.ID
		  p.ProductCategoryID
		  ,p.ID
		  ,pc.Name

	----DEBUG
	--SELECT @MemberRenewalDate, * from #ProductEvents
	
	---RULE
	--Event Limit: 1 Tow and 1 Non-Tow Service
	SET @IsEligible = 1
	IF (@ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow')  --Requested service is Tow
		AND EXISTS(SELECT * FROM @ProductEvents WHERE ProductCategoryID = (SELECT ID FROM ProductCategory WHERE Name = 'Tow'))) --Has at least one prior Tow
		OR
		(@ProductCategoryID <> (SELECT ID FROM ProductCategory WHERE Name = 'Tow') --Requested service is Non-Tow
		AND EXISTS(SELECT * FROM @ProductEvents WHERE ProductCategoryID <> (SELECT ID FROM ProductCategory WHERE Name = 'Tow'))) --Has at least one prior Non-Tow
		SET @IsEligible = 0


	---- RESULT SET
	SELECT TOP 1
		ID 
		,@ProgramID
		,[Description] 
		,Limit
		,EventCount = ISNULL((Select SUM(EventCount) FROM @ProductEvents),0)
		,1 AS IsPrimary
		,@IsEligible
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	
END


GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit_Program_6]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit_Program_6] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* Custom service event limit logic for Pinnacle (program ID 6) */

CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit_Program_6]  
      @ServiceRequestID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int 
      ,@VehicleTypeID int
      ,@VehicleCategoryID int 
      ,@SecondaryCategoryID INT = NULL
AS
BEGIN

	----Debug
	--DECLARE 
	--      @ServiceRequestID int = 124110
	--      ,@ProgramID int = 6
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 1
	--      ,@VehicleCategoryID int = 1
	--      ,@SecondaryCategoryID INT = NULL

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@Description nvarchar(255)
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime
		,@IsEligible bit 
		,@EventLimit int
	
	DECLARE @MembershipMembers TABLE (MembershipID int, MemberID int, IsServiceRequestMember bit)
	DECLARE @ServiceEvents TABLE (ServiceRequestID int, EventDate datetime)

	SELECT @MemberID = m.ID
	  ,@MemberExpirationDate = m.ExpirationDate
	  ,@ProgramID = CASE WHEN @ProgramID IS NULL THEN m.ProgramID ELSE  @ProgramID END
	FROM ServiceRequest SR 
	JOIN [Case] c on c.id = SR.CaseID
	JOIN Member m on m.ID = c.MemberID
	WHERE SR.ID = @ServiceRequestID
	
	-- Determine last annual renewal date 
	SET @MemberRenewalDate = DATEADD(yy, (ROUND(DATEDIFF(dd, getdate(), @MemberExpirationDate)/365.00,0,1) + 1)*-1, @MemberExpirationDate)
	
	INSERT INTO @MembershipMembers (MembershipID, MemberID, IsServiceRequestMember)
	SELECT m.MembershipID, m.ID MemberID, CASE WHEN m.ID = @MemberID THEN 1 ELSE 0 END IsServiceRequestMember
	FROM Member m
	WHERE m.MembershipID = (
		SELECT ms.ID 
		FROM Membership ms
		JOIN Member m ON m.MembershipID = ms.ID
		WHERE m.ID = @MemberID)
	AND m.ProgramID = @ProgramID -- Insure that the member on the membership has the same program as the SR member
	
	SET @EventLimit = (SELECT CASE (SELECT COUNT(*) FROM @MembershipMembers)
		WHEN 1 THEN 5
		WHEN 2 THEN 8
		ELSE 10 END)
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	----DEBUG
	--SELECT @ProductID
	--SELECT * From @MembershipMembers
	
	-- Counting EACH SR with at least 1 issued PO; Could be more than one PO, but still counted as just 1 event
	INSERT INTO @ServiceEvents (ServiceRequestID, EventDate)
	SELECT 
		  sr.ID ServiceRequestID
		  ,sr.CreateDate
	From [Case] c
	Join ServiceRequest sr on c.ID = sr.CaseID
	Join @MembershipMembers mm on mm.MemberID = c.MemberID
	Where 1=1
		  and sr.ID <> @ServiceRequestID
		  and EXISTS (
			SELECT *
			FROM PurchaseOrder po 
			WHERE sr.ID = po.ServiceRequestID and 
				po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid')) and 
				po.IsActive = 1 and
				po.IssueDate IS NOT NULL and
				po.IssueDate > @MemberRenewalDate)

	--DEBUG
	--SELECT @MemberRenewalDate, * from @ServiceEvents
	
	---RULE
	--Event Limit: 5/8/10 Service Events (SRs with 1 or more issued POs) 
	SET @IsEligible = 1
	IF (SELECT COUNT(*) FROM @ServiceEvents) >= @EventLimit
		SET @IsEligible = 0


	---- RESULT SET
	SELECT TOP 1
		ID 
		,@ProgramID
		,[Description] 
		,@EventLimit
		,EventCount = ISNULL((Select COUNT(*) FROM @ServiceEvents),0)
		,1 AS IsPrimary
		,@IsEligible
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	
END


GO
  
ALTER view [dbo].[vw_BillingServiceRequestsPurchaseOrders]  
as  
-- Change Log:  
-- ^1 : 01/06/2014 : Per Garfield - add criteria to exclude Legacy Code 14, as a Diagnostic Code  
--   
-- ^2 : Added Cols : ServiceRequestCreateBy, PurchaseOrderCreateBy  
-- ^3 : 4/4/2014 Added: Service Location Postal Code Clay McNurlin project 13766  
-- ^4 : 4/4/2014 Added: Logic to adjust membership number to client reference Number for PDG   
--   
select ServiceRequestID,  
  ServiceRequestStatus,  
  ServiceRequestDate,  
  ServiceRequestDatetime,  
  ClientID,  
  ClientName,  
  ProgramID,  
  ProgramName,  
  ProgramCode,  
  MemberID,  
  LastName,  
  FirstName,  
  MembershipNumber,  
  MemberSinceDate,  
  EffectiveDate,  
  ExpirationDate,  
  MemberCreateDate,  
  MemberCreateDatetime,  
  PurchaseOrderID,  
  PurchaseOrderNumber,  
  PurchaseOrderDate,  
  PurchaseOrderDatetime,  
  PurchaseOrderStatus,  
  PurchaseOrderIsActive,  
  ContactLastName,  
  ContactFirstName,  
  VIN,  
  VehicleYear,  
  VehicleMake,  
  VehicleModel,  
  VINModelYear,  
  VINModel,  
  VehicleCurrentMileage,  
  VehicleMileageUOM,  
  VehicleLicenseNumber,  
  VehicleLicenseState,  
  SRPrimaryProductCat,  
  SRPrimaryProductID,  
  SRPrimaryProductDescription,  
  SRPrimaryProductCategoryDescription,  
  SRSecondaryProductID,  
  SRSecondProductDescription,  
  SRSecondaryProductCategoryDescription,  
  ServiceCode,  
  POProductID,  
  POProductDescription,  
  POPProductCategoryDescription,  
  PODetailProductID,  
  PODetailProductDescription,  
  PODetailProductCategoryDescription,  
  ServiceLocationAddress,  
  ServiceLocationCity,  
  ServiceLocationStateProvince,  
  DestinationDescription,  
  DestinationCity,  
  DestinationStateProvince,  
  TotalServiceAmount,  
  CoachNetServiceAmount,  
  MemberServiceAmount,  
  PurchaseOrderAmount,  
  ServiceRequestCCPaymentsReceived,  
  IsPaidByCompanyCC,  
  BillingApprovalCode,  
  IsCancelledSR,  
  IsDispatchIntended,  
  IsDispatched,  
  IsCancelledPO,  
  GOAReason,  
  IsVendorPay,  
  IsMemberPay,  
  IsReDispatch,  
  IsTechAssistance,  
  IsDiagnostics,  
  IsVerifyService,  
  IsISPSelection,  
  IsInfoContact,  
  IsNoMemberOnService,  
  IsMbrManuallyCreated,  
  IsImpoundRelease,  
  IsOutOfWarranty,  
    
  IsDeliveryDriver,  
    
  IsDirectTowApprovedDestination,  
  DispatchFee,  
  DispatchFeeBillToName,  
  VendorID,  
  VendorNumber,  
  VendorLocationID,  
  DealerNumber,  
  PACode,  
  
  PrimaryVehicleDiagnosticCodeID,  
  PrimaryVehicleDiagnosticCodeName,  
  VehicleDiagnosticCodeCount,  
  InboundContactsTOTAL,  
  InboundContactsNEWCALL,  
  InboundContactsCUSTOMER,  
  InboundContactsVENDOR,  
  InboundContactsCLOSEDLOOP,  
  InboundContactsOTHER,  
  OutboundContactsTOTAL,  
  OutboundContactsNEWCALL,  
  OutboundContactsCUSTOMER,  
  OutboundContactsVENDOR,  
  OutboundContactsCLOSEDLOOP,  
  OutboundContactsOTHER,  
  cast(case when IsDispatchIntended = 1 then 1 else 0 end as int) as DISPATCH,  
  cast(case when IsDispatchIntended = 0 then 1 else 0 end as int) as NON_DISPATCH,  
  cast(case   
    when IsDispatchIntended = 0   
    and (IsTechAssistance = 1  
      or IsDiagnostics = 1  
      or IsVerifyService = 1  
      or IsISPSelection = 1)  
    then 1 else 0   
    end  
   as int) as CUSTOMER_ASSISTANCE,  
  cast(case   
    when IsDispatchIntended = 0   
    and IsTechAssistance = 0  
    and IsDiagnostics = 0  
    and IsVerifyService = 0  
    and IsISPSelection = 0  
    and IsInfoContact = 1  
    then 1 else 0   
    end  
   as int) as INFO,  
  cast(case   
    when IsDispatchIntended = 0   
    and IsTechAssistance = 0  
    and IsDiagnostics = 0  
    and IsVerifyService = 0  
    and IsISPSelection = 0  
    and IsInfoContact = 0  
    then 1 else 0   
    end  
   as int) as OTHER,  
  cast(case   
    when IsDispatched = 1  
    and IsVendorPay = 1  
    then 1 else 0  
    end   
   as int) as PASS_THRU,  
  
  AccountingInvoiceBatchID_ServiceRequest,  
  AccountingInvoiceBatchID_PurchaseOrder,  
  
  ServiceRequestComments,  
  ServiceRequestCommentsClaimNum,  
  ServiceRequestCommentsPACode,  
  ServiceRequestCommentsDealerID,  
  
  (select ID from dbo.Entity with (nolock) where Name = 'ServiceRequest') as EntityID_ServiceRequest,  
  ServiceRequestID as  EntityKey_ServiceRequest,  
  (select ID from dbo.Entity with (nolock) where Name = 'PurchaseOrder') as EntityID_PurchaseOrder,  
  PurchaseOrderID as  EntityKey_PurchaseOrder,  
    
  ServiceRequestCreateBy, -- ^2  
  PurchaseOrderCreateBy -- ^2  
    
     ,case when CHARINDEX(', ' + [ServiceLocationStateProvince] +' ', [ServiceLocationAddress]) > 0  
   then substring([ServiceLocationAddress],(   
   CHARINDEX(', ' + [ServiceLocationStateProvince] +' ', [ServiceLocationAddress]) +  
   LEN(', ' + [ServiceLocationStateProvince] +' ')+1),  
   7) end ServiceLocationPostalCode  ---^3  
  
from  
  (select sr.ID as ServiceRequestID,  
    srs.Name as ServiceRequestStatus,  
    convert(date, sr.CreateDate) as ServiceRequestDate,  
    sr.CreateDate as ServiceRequestDatetime,  
    cl.ID as ClientID,  
    cl.Name as ClientName,  
    (CASE WHEN ISNULL(ca.ProgramID,0) <> 0 THEN COALESCE(mbr.ProgramID, ca.ProgramID, 0) ELSE 0 END) as ProgramID,  
    pro.Name as ProgramName,  
    pro.Code as ProgramCode,  
    mbr.ID as MemberID,  
    mbr.LastName,  
    mbr.FirstName,  
--- ^ 4 Updated to use ClientReference for PDG     
    case when cl.ID = 24 then upper(coalesce(mbrs.ClientReferenceNumber,mbrs.[MembershipNumber]))  
      else mbrs.MembershipNumber end as MembershipNumber,  
    mbr.MemberSinceDate,  
    mbr.EffectiveDate,  
    convert(date, mbr.CreateDate) as MemberCreateDate,  
    mbr.CreateDate as MemberCreateDatetime,  
    mbr.ExpirationDate,  
    ca.ContactLastName,  
    ca.ContactFirstName,  
  
    ca.VehicleVIN as VIN,  
    ca.VehicleYear,  
    ca.VehicleMake,  
    ca.VehicleModel,  
    dbo.fnc_BillingVINModelYear(ca.VehicleVIN) as VINModelYear,  
    dbo.fnc_BillingVINModel(ca.VehicleVIN) as VINModel,  
    ca.VehicleCurrentMileage,  
    ca.VehicleMileageUOM,  
    ca.VehicleLicenseNumber,  
    ca.VehicleLicenseState,  
          
    -- SR Product Category  
    srpc.Name as SRPrimaryProductCat,  
      
    -- SR Primary Product  
    srpr.ID as SRPrimaryProductID,  
    srpr.[Description] as SRPrimaryProductDescription,  
    srprpc.[Description] as SRPrimaryProductCategoryDescription,  
      
    -- SR Secondary Product  
    srpr2.ID as SRSecondaryProductID,  
    srpr2.[Description] as SRSecondProductDescription,  
    srprpc2.[Description] as SRSecondaryProductCategoryDescription,  
      
    -- PO Product  
    popr.ID as POProductID,  
    popr.[Description] as POProductDescription,  
    popc.[Description] as POPProductCategoryDescription,  
      
    -- PO Detail Product  
    p4.ID as PODetailProductID,  
    p4.[Description] as PODetailProductDescription,  
    p4pc.[Description] as PODetailProductCategoryDescription,  
      
    scv.ServiceCode,  
      
    sr.ServiceLocationAddress,  
    sr.ServiceLocationCity,  
    sr.ServiceLocationStateProvince,  
  
    sr.DestinationDescription,  
    sr.DestinationCity,  
    sr.DestinationStateProvince,  
          
    po.ID as PurchaseOrderID,  
    po.PurchaseOrderNumber,  
    convert(date, po.CreateDate) as PurchaseOrderDate,  
    po.CreateDate as PurchaseOrderDatetime,  
    pos.Name as PurchaseOrderStatus,  
    po.IsActive as PurchaseOrderIsActive,  
    po.TotalServiceAmount,  
    po.CoachNetServiceAmount,  
    po.MemberServiceAmount,  
    po.PurchaseOrderAmount,  
    CC.ServiceRequestCCPaymentsReceived,  
      
    cast(  
     case  
     when po.IsPayByCompanyCreditCard = 1 and po.CompanyCreditCardNumber is not null then 1  
     else 0  
    end   
    as int) as IsPaidByCompanyCC,  
      
    cast(null as nvarchar(50)) as BillingApprovalCode,  -- NEED TO GET QFC BILLING CODE HERE  
  
    cast(  
    case  
     when srs.Name = 'Cancelled' then 1  
     else 0  
    end as int) as IsCancelledSR,  
    cast(  
     case  
     when po.ID is null and COALESCE(popc.Name, srpc.Name) = 'Tech' then 0 -- 1. No PO and Tech then No DispatchIntended  
     when po.ID is not null then 1 -- 2. Has a PO, then DispatchIntended  
     when -- 3. When Member Data, Vehicle Data, Is of Dispatch Concern, and Location then DispatchIntended  
       (mbrs.MembershipNumber is not null -- Member Data  
        and (ca.VehicleYear is not null -- Vehicle Data  
          or ca.VehicleMake is not null  
          or ca.VehicleModel is not null)  
        and COALESCE(popc.Name, srpc.Name) in ('Tow', 'Tire', 'Lockout', 'Fluid', 'Jump', 'Winch', 'Tech', 'Mobile', 'Repair') -- is of Dispatch Concern  
        and sr.ServiceLocationAddress is not null  
        and sr.ServiceLocationCity is not null  
        and sr.ServiceLocationStateProvince is not null) then 1  
     else 0  
     end as int) as IsDispatchIntended,  
     cast(  
     case  
      when po.ID is not null then 1  
      else 0  
     end as int) as IsDispatched,  
     cast(  
     case  
      when pos.Name = 'Cancelled' then 1  
      else 0  
     end as int)as IsCancelledPO,  
     pocr.[Description] as CancelledPOReason,  
     isnull(cast(po.IsGOA as int), 0) as IsGOA,  
     goa.[Description] as GOAReason,  
     case  
      when po.PurchaseOrderAmount > 0.00 then 1  
      else 0  
     end as IsVendorPay,  
     case  
     -- when (po.MemberServiceAmount = po.TotalServiceAmount) and po.PurchaseOrderAmount = 0.00 then 1  
      when (po.MemberServiceAmount = po.TotalServiceAmount) and po.TotalServiceAmount <> 0.00 then 1  
      else 0  
     end as IsMemberPay,  
     cast(  
     case  
      when isnull(CLOG.ReDispatchContact, 0) > 0 then 1  
      else 0  
     end as int) as IsReDispatch,  
     cast(  
     case  
      when COALESCE(popc.Name, srpc.Name) = 'Tech' or IsWorkedByTech = 1 then 1  
      else 0  
     end as int) as IsTechAssistance,  
     cast(  
     case  
      when isnull(DIAG.VehicleDiagnosticCodeCount, 0) > 0 then 1  
      else 0  
     end as int) as IsDiagnostics,  
     cast(  
     case  
      when isnull(CLOG.VerifyServiceContact, 0) > 0 then 1  
      else 0  
     end as int) as IsVerifyService,  
     cast(  
     case  
      when isnull(CLOG.ISPSelectionContact, 0) > 0 then 1  
      else 0  
     end as int) as IsISPSelection,  
     cast(  
     case  
      when COALESCE(popc.Name, srpc.Name) like '%Info%' then 1 -- Info Product  
      when isnull(CLOG.InfoContact, 0) > 0 then 1 -- Coded with Info Contact  
      else 0  
     end as int) as IsInfoContact,  
     cast(  
     case  
      when mbr.ID is null then 1  
      else 0  
     end as int) as IsNoMemberOnService,  
     cast(  
     case  
      when mbr.CreateBy not in ('System', 'DISPATCHPOST') then 1  
      else 0  
     end as int) as IsMbrManuallyCreated,  
     cast(  
     case  
      when IMP.PurchaseOrderID is not null then 1  
      else 0  
     end as int) as IsImpoundRelease,  
     cast(  
     case  
      when isnull(CLOG.OutOfWarrantyContact, 0) > 0 then 1  
      else 0  
     end as int) as IsOutOfWarranty,  
      
     ca.IsDeliveryDriver,  
  
     DT.IsDirectTowApprovedDestination,  
     po.DispatchFee,  
     bt.Name as DispatchFeeBillToName,  
       
     -- Direct Tow  
     DT.VendorID,  
     DT.VendorNumber,  
     DT.VendorLocationID,  
     DT.DealerNumber,  
     DT.PACode,  
       
     -- Diagnostics  
     DIAG.PrimaryVehicleDiagnosticCodeID,  
     DIAG.PrimaryVehicleDiagnosticCodeName,  
     isnull(DIAG.VehicleDiagnosticCodeCount, 0) as VehicleDiagnosticCodeCount,  
  
     -- Contacts  
     InboundContactsTOTAL,  
     InboundContactsNEWCALL,  
     InboundContactsCUSTOMER,  
     InboundContactsVENDOR,  
     InboundContactsCLOSEDLOOP,  
     InboundContactsOTHER,  
     OutboundContactsTOTAL,  
     OutboundContactsNEWCALL,  
     OutboundContactsCUSTOMER,  
     OutboundContactsVENDOR,  
     OutboundContactsCLOSEDLOOP,  
     OutboundContactsOTHER,  
       
     sr.AccountingInvoiceBatchID as AccountingInvoiceBatchID_ServiceRequest,  
     po.AccountingInvoiceBatchID as AccountingInvoiceBatchID_PurchaseOrder,  
  
     -- Comments  
     CMT.ServiceRequestComments,  
     CMT.ServiceRequestCommentsClaimNum,  
     CMT.ServiceRequestCommentsPACode,  
     CMT.ServiceRequestCommentsDealerID,  
     sr.CreateBy as ServiceRequestCreateBy,  
     po.CreateBy as PurchaseOrderCreateBy  
    
  from dbo.ServiceRequest sr with (nolock)  
  left outer join dbo.ProductCategory srpc with (nolock) on srpc.ID = sr.ProductCategoryID  
  left outer join dbo.ServiceRequestStatus srs with (nolock) on srs.ID = sr.ServiceRequestStatusID  
  left outer join dbo.[Case] ca with (nolock) on ca.ID = sr.CaseID  
  left outer join dbo.CaseStatus cas with (nolock) on cas.ID = ca.CaseStatusID  
  left outer join PurchaseOrder po with (nolock) on sr.ID = po.ServiceRequestID  
  left outer join dbo.ContactMethod cm with (nolock) on cm.ID = po.ContactMethodID  
  left outer join dbo.PurchaseOrderType pot with (nolock) on pot.ID = po.PurchaseOrderTypeID  
  left outer join dbo.PurchaseOrderStatus pos with (nolock) on pos.ID = po.PurchaseOrderStatusID  
  left outer join dbo.PurchaseOrderCancellationReason pocr with (nolock) on pocr.ID = po.CancellationReasonID  
  left outer join dbo.CurrencyType ct with (nolock) on ct.ID = po.CurrencyTypeID  
  left outer join dbo.PaymentType pt with (nolock) on pt.ID = po.MemberPaymentTypeID  
  left outer join dbo.PurchaseOrderGOAReason goa with (nolock) on goa.ID = po.GOAReasonID  
  left outer join dbo.Product popr with (nolock) on popr.ID = po.ProductID  
  left outer join dbo.ProductCategory popc with (nolock) on popc.ID = popr.ProductCategoryID  
  
  left outer join dbo.Member mbr with (nolock) on mbr.ID = ca.MemberID  
  left outer join dbo.Membership mbrs with (nolock) on mbrs.ID = mbr.MembershipID  
  left outer join dbo.Program pro with (nolock) on pro.ID = (CASE WHEN ISNULL(ca.ProgramID,0) <> 0 THEN COALESCE(mbr.ProgramID, ca.ProgramID, 0) ELSE 0 END)  
  left outer join dbo.Program pra with (nolock) on pra.ID = pro.ParentProgramID  
  left outer join dbo.Client cl with (nolock) on cl.ID = pro.ClientID  
  left outer join dbo.Product srpr with (nolock) on srpr.ID = sr.PrimaryProductID  
  left outer join dbo.ProductCategory srprpc with (nolock) on srprpc.ID = srpr.ProductCategoryID  
  left outer join dbo.Product srpr2 with (nolock) on srpr2.ID = sr.SecondaryProductID  
  left outer join dbo.ProductCategory srprpc2 with (nolock) on srprpc2.ID = srpr2.ProductCategoryID  
  left outer join dbo.BillTo bt with (nolock) on bt.ID = po.DispatchFeeBillToID  
    
  -- To Get the Service Code  
  left outer join vw_ServiceCode scv on scv.ServiceRequestID = sr.ID  
    and isnull(scv.PurchaseOrderID, -999) = isnull(po.ID, -999)  
  
  left outer join   
    
    (select distinct pod.PurchaseOrderID, pod.ProductID from dbo.PurchaseOrderDetail pod with (nolock)) b    
      on b.PurchaseOrderID = po.ID    
       and --if the po detail records have the same product as the po record then use it to define the product for the call  
       b.ProductID = (Case when po.ProductID = (select distinct pod1.productid from dbo.PurchaseOrderDetail pod1 with (nolock)   
           where pod1.PurchaseOrderID = po.ID and pod1.ProductID = po.ProductID) then po.ProductID  
        --if the productid from the Purchase order detail doesn't match the product id on the po record then use the max id from the purchase order detail  
           else (select distinct max(pod2.productid) from dbo.PurchaseOrderDetail pod2 with (nolock)   
           where pod2.PurchaseOrderID = po.ID) end)  
   --Get the lable for the Product Name  
  left outer join dbo.Product p4 with (nolock) on p4.ID = b.ProductID   
  left outer join dbo.ProductCategory p4pc with (nolock) on p4pc.ID = p4.ProductCategoryID   
  
  
  left outer join -- Diagnostics  
  
    (select srvdc.ServiceRequestID,  
      srvdc.VehicleDiagnosticCodeID as PrimaryVehicleDiagnosticCodeID,  
      vdc.Name as PrimaryVehicleDiagnosticCodeName,  
      (select count(*)  
       from ServiceRequestVehicleDiagnosticCode dc1 with (nolock)  
       where dc1.ServiceRequestID = srvdc.ServiceRequestID) as VehicleDiagnosticCodeCount  
     from ServiceRequestVehicleDiagnosticCode srvdc with (nolock)  
     join VehicleDiagnosticCode vdc with (nolock) on vdc.ID = srvdc.VehicleDiagnosticCodeID  
     where srvdc.IsPrimary = 1  
     and isnull(vdc.LegacyCode, '') <> '14' -- ^1 : Eexclude Legacy Code 14, as a Diagnostic Code  
     ) DIAG on DIAG.ServiceRequestID = SR.ID  
  
  left outer join -- Contact Logs  
  
    (select sr2.ID as ServiceRequestID,  
      -- Inbound  
      count(distinct   
         case when cl.Direction = 'Inbound' then cl.ID  
         else null  
         end) as InboundContactsTOTAL,  
      count(distinct  
         case when cl.Direction = 'Inbound' and cc.Name = 'NewCall' then cl.ID  
         else null  
         end) as InboundContactsNEWCALL,  
      count(distinct  
         case when cl.Direction = 'Inbound' and cc.Name in ('ContactCustomer', 'CustomerCallback') then cl.ID  
         else null  
         end) as InboundContactsCUSTOMER,  
      count(distinct  
         case when cl.Direction = 'Inbound' and cc.Name in ('ContactVendor', 'VendorCallback', 'VendorSelection') then cl.ID  
         else null  
         end) as InboundContactsVENDOR,  
      count(distinct  
         case when cl.Direction = 'Inbound' and cc.Name in ('ClosedLoop') then cl.ID  
         else null  
         end) as InboundContactsCLOSEDLOOP,  
      count(distinct  
         case when cl.Direction = 'Inbound' and cc.Name not in   
         ('NewCall', 'ContactCustomer', 'CustomerCallback', 'ContactVendor', 'VendorCallback', 'VendorSelection', 'ClosedLoop')  
         then cl.ID  
         else null  
         end) as InboundContactsOTHER,  
      -- Outbound  
      count(distinct   
         case when cl.Direction = 'Outbound' then cl.ID  
         else null  
         end) as OutboundContactsTOTAL,  
      count(distinct  
         case when cl.Direction = 'Outbound' and cc.Name = 'NewCall' then cl.ID  
         else null  
         end) as OutboundContactsNEWCALL,  
      count(distinct  
         case when cl.Direction = 'Outbound' and cc.Name in ('ContactCustomer', 'CustomerCallback') then cl.ID  
         else null  
         end) as OutboundContactsCUSTOMER,  
      count(distinct  
         case when cl.Direction = 'Outbound' and cc.Name in ('ContactVendor', 'VendorCallback', 'VendorSelection') then cl.ID  
         else null  
         end) as OutboundContactsVENDOR,  
      count(distinct  
         case when cl.Direction = 'Outbound' and cc.Name in ('ClosedLoop') then cl.ID  
         else null  
         end) as OutboundContactsCLOSEDLOOP,  
      count(distinct  
         case when cl.Direction = 'Outbound' and cc.Name not in   
         ('NewCall', 'ContactCustomer', 'CustomerCallback', 'ContactVendor', 'VendorCallback', 'VendorSelection', 'ClosedLoop')  
         then cl.ID  
         else null  
         end) as OutboundContactsOTHER,  
      count(distinct  
         case when ca.Name like '%Information%'  
         then cl.ID  
         else null  
         end) as InfoContact,  
      count(distinct  
         case when cr.Name = 'Verify Service'  
         then cl.ID  
         else null  
         end) as VerifyServiceContact,  
      count(distinct  
         case when cr.Name = 'ISP Selection'  
         then cl.ID  
         else null  
         end) as ISPSelectionContact,              
      count(distinct  
         case when cr.Name = 'Re-dispatch'  
         then cl.ID  
         else null  
         end) as ReDispatchContact,  
      count(distinct  
         case when ca.Name = 'OutOfWarranty'  
         then cl.ID  
         else null  
         end) as OutOfWarrantyContact  
    from contactlog cl with (nolock)  
    join contactloglink cll with (nolock) on cl.id = cll.contactlogid and cll.EntityID = (select ID from Entity where Name = 'ServiceRequest')  
    join servicerequest sr2 with (nolock) on sr2.id = cll.recordid  
    join contactcategory cc with (nolock) on cl.contactcategoryid = cc.id  
    join contactlogReason clr with (nolock) on cl.id = clr.contactlogid  
    join contactreason cr with (nolock) on clr.ContactReasonID = cr.ID  
    join contactlogaction cla with (nolock) on cl.id = cla.contactlogid  
    join contactaction ca with (nolock) on cla.ContactActionID = ca.ID  
    group by  
      sr2.ID) CLOG on CLOG.ServiceRequestID = SR.ID  
  
  left outer join -- Impound Release Fees  
       
     (select distinct po.ID as PurchaseOrderID  
      from dbo.PurchaseOrder po with (nolock)  
      join dbo.PurchaseOrderDetail pod with (nolock) on pod.PurchaseOrderID = po.ID  
      join dbo.Product pr with (nolock) on pr.ID = pod.ProductID  
      where pr.Name = 'Impound Release Fee'  
     ) IMP on IMP.PurchaseOrderID = po.ID  
  
  
  left outer join -- Direct Tow Destination Attributes  
    
     (select v.ID as VendorID,  
       v.VendorNumber,  
       vl.ID as VendorLocationID,  
       vl.DealerNumber,  
       cast(null as nvarchar(50)) as PACode,  
       cast(1 as int) as IsDirectTowApprovedDestination  
     from Vendor v with (nolock)  
     left outer join VendorLocation vl with (nolock) on vl.VendorID = v.ID  
     left outer join VendorLocationProduct vlp with (nolock) on vlp.VendorLocationID = vl.ID  
     left outer join Product pr with (nolock) on pr.ID = vlp.ProductID  
     where 1=1  
     and  pr.Name = 'Ford Direct Tow') DT on DT.VendorLocationID = sr.DestinationVendorLocationID  
       
  left outer join -- Service Request CC Payments Received  
  
     (select sr.ID as ServiceRequestID,  
       sum(pmt.Amount) ServiceRequestCCPaymentsReceived  
     from Payment pmt with (nolock)  
     join PaymentStatus ps on ps.ID = pmt.PaymentStatusID  
       and ps.Name = 'Approved'  
     join PaymentType pt on pt.ID = pmt.PaymentTypeID  
     join PaymentCategory pc on pc.ID = pt.PaymentCategoryID  
       and pc.Name = 'CreditCard'  
     join ServiceRequest sr on sr.ID = pmt.ServiceRequestID  
     join PaymentReason pr on pr.ID = pmt.PaymentReasonID  
     group by  
       sr.ID) CC on CC.ServiceRequestID = sr.ID  
         
  Left outer join dbo.vw_ServiceRequestComments CMT on CMT.ServiceRequestID = sr.ID -- Service Request Comments  
  
  
   ) DTL  
 where 1=1  
GO


/****** Object:  StoredProcedure [dbo].[dms_BillingClaimsProcessedRoadsideReimbursement_Get]    Script Date: 04/29/2014 02:13:20 ******/
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_BillingVendorInvoices]') ) 
 BEGIN
 DROP   VIEW [dbo].[vw_BillingVendorInvoices] 
 END 
 GO  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[vw_BillingVendorInvoices]  
as  
  
-- CHANGE LOG:  
--  
-- ^1 01/21/2014 - MJK - Added join to PaymentCatgory  
-- ^2 01/21/2014 - MJK - Added New field for PaymentDateWith1MonthDelay  
-- ^3 02/02/2014 - MJK - Added IsDeliveryDriver  
--   
 select vi.ID as VendorInvoiceID,  
   vi.PurchaseOrderID,  
   vpo.PurchaseOrderNumber,  
   vpo.ServiceRequestID,  
   vpo.ServiceRequestDate,  
   vpo.ServiceRequestDatetime,  
   vpo.ClientID,  
   vpo.ClientName,  
   vpo.ProgramID,  
   vpo.ProgramName,  
   vpo.ProgramCode,  
   vpo.MemberID,  
   vpo.MembershipNumber,  
   vpo.LastName,  
   vpo.FirstName,  
   vpo.MemberSinceDate,  
   vpo.EffectiveDate,  
   vpo.ExpirationDate,  
   vpo.MemberCreateDate,  
   vpo.MemberCreateDatetime,  
   vpo.ContactLastName,  
   vpo.ContactFirstName,  
   vpo.TotalServiceAmount,  
   vpo.MemberServiceAmount,  
   vpo.PurchaseOrderAmount,  
   vpo.ServiceRequestCCPaymentsReceived,  
   vpo.BillingApprovalCode,  
   vpo.VIN,  
   vpo.VehicleYear,  
   vpo.VehicleMake,  
   vpo.VehicleModel,  
   vpo.VINModelYear,  
   vpo.VINModel,  
   vpo.VehicleCurrentMileage,  
   vpo.VehicleMileageUOM,  
   vpo.VehicleLicenseNumber,  
   vpo.VehicleLicenseState,  
  
   vpo.IsDirectTowApprovedDestination,  
   vpo.DispatchFee,  
   vpo.DispatchFeeBillToName,  
   vpo.VendorNumber,  
   vpo.VendorLocationID,  
   vpo.DealerNumber,  
   vpo.PACode,  
  
   vpo.ServiceCode,  
   vpo.isMemberPay,  
     
   vpo.GOAReason,  
     
   vi.VendorID,  
   vi.VendorInvoiceStatusID,  
   vi.SourceSystemID,  
   vi.PaymentTypeID,  
   vi.InvoiceNumber,  
   convert(date, vi.ReceivedDate) as ReceivedDate,  
   vi.ReceivedDate as ReceivedDatetime,  
   vi.ReceiveContactMethodID,  
   convert(date, vi.InvoiceDate) as InvoiceDate,  
   vi.InvoiceDate as InvoiceDatetime,  
   vi.InvoiceAmount,  
   vi.BillingBusinessName,  
   vi.BillingContactName,  
   vi.BillingAddressLine1,  
   vi.BillingAddressLine2,  
   vi.BillingAddressLine3,  
   vi.BillingAddressCity,  
   vi.BillingAddressStateProvince,  
   vi.BillingAddressPostalCode,  
   vi.BillingAddressCountryCode,  
   convert(date, vi.ToBePaidDate) as ToBePaidDate,  
   vi.ToBePaidDate as ToBePaidDatetime,  
   vi.ExportDate,  
   vi.ExportBatchID,  
   convert(date, vi.PaymentDate) as PaymentDate,  
   vi.PaymentDate as PaymentDatetime,  
   vi.PaymentAmount,  
--   vi.CheckNumber,  
   vi.CheckClearedDate,  
   vi.ActualETAMinutes,  
   vi.Last8OfVIN,  
   vi.VehicleMileage,  
   vi.AccountingInvoiceBatchID,  
   vi.IsActive,  
   vi.CreateDate as VendorInvoiceCreateDate,  
   vi.CreateBy as VendorInvoiceCreatedBy,  
     
   (select ID from dbo.Entity with (nolock) where Name = 'VendorInvoice') as EntityID,  
   vi.ID as  EntityKey,  
     
   pc.ID as PaymentCategoryID,  
   isnull(pc.Name, '~') as PaymentCategoryName,  
   dateadd(mm, 1, convert(date, vi.PaymentDate)) as PaymentDateWith1MonthDelay, -- ^2  
   vpo.IsDeliveryDriver  
  
from dbo.VendorInvoice vi with (nolock)  
left outer join dbo.VendorInvoiceException vie with (nolock) on vie.VendorInvoiceID = vi.ID  
left outer join dbo.VendorInvoiceStatus vis with (nolock) on vis.ID = vi.VendorInvoiceStatusID  
left outer join dbo.Vendor ven with (nolock) on ven.ID = vi.VendorID  
left outer join dbo.PaymentType pt with (nolock) on pt.ID = vi.PaymentTypeID  
left outer join dbo.PaymentCategory pc with (nolock) on pc.ID = pt.PaymentCategoryID -- ^1  
  
left outer join vw_BillingServiceRequestsPurchaseOrders vpo on vpo.PurchaseOrderID = vi.PurchaseOrderID  
  
  
  
  
GO
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[vw_Vendors]')) 
 BEGIN
 DROP VIEW [dbo].[vw_Vendors] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
/****** Object:  View [dbo].[vw_Vendors]    Script Date: 11/09/2014 17:58:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[vw_Vendors]

AS

SELECT	v.ID
		, v.Name AS VendorName
		, v.CorporationName
		, v.VendorStatusID
		, vs.Name AS VendorStatus
		, v.VendorRegionID
		, vr.Name AS VendorRegion
		, vr.ContactFirstName + ' ' + vr.ContactLastName AS VendorRegionContact 
		, v.SourceSystemID
		, ss.Name AS SourceSystem
		, v.VendorNumber
		, v.ContactFirstName
		, v.ContactLastName
		, v.AdministrativeRating
		, v.AdministrativeRatingModifyDate
		, v.Website
		, v.Email
		, ae.Line1 AS BusinessLine1
		, ae.Line2 AS BusinessLine2
		, ae.City AS BusinessCity
		, ae.StateProvinceID AS BusinessStateProvinceID
		, ae.StateProvince AS BusinessStateProvince
		, ae.PostalCode AS BusinessPostalCode
		, ae.CountryID AS BusinessCountryID
		, ae.CountryCode AS BusinessCountryCode
		, aeBill.Line1 AS BillingLine1
		, aeBill.Line2 AS BillingLine2
		, aeBill.City AS BillingCity
		, aeBill.StateProvinceID AS BillingStateProvinceID
		, aeBill.StateProvince AS BillingStateProvince
		, aeBill.PostalCode AS BillingPostalCode
		, aeBill.CountryID AS BillingCountryID
		, aeBill.CountryCode AS BillingCountryCode
		, peofc.PhoneNumber AS OfficePhone
		, pedis.PhoneNumber AS DispatchPhone
		, v.TaxClassification
		, v.TaxClassificationOther
		, v.TaxEIN
		, v.TaxSSN
		, v.W9SignedBy
		, v.IsW9OnFile
		, v.InsuranceCarrierName
		, v.InsurancePolicyNumber
		, v.InsuranceExpirationDate
		, v.IsInsuranceCertificateOnFile
		, v.IsInsuranceAdditional
		, v.IsEmployeeBackgroundChecked
		, v.IsEmployeeBackgroundCheckedComment
		, v.IsEmployeeDrugTested
		, v.IsEmployeeDrugTestedComment
		, v.IsDriverUniformed
		, v.IsDriverUniformedComment
		, v.IsEachServiceTruckMarked
		, v.IsEachServiceTruckMarkedComment
		, v.DepartmentOfTransportationNumber
		, v.MotorCarrierNumber
		, v.IsLevyActive
		, v.LevyRecipientName
		, v.IsPaymentOnHold
		, v.IsVirtualLocationEnabled
		, v.IsActive
		, CASE 
			WHEN ISNULL(ach.ID,'') = '' THEN 'No'
			ELSE 'Yes'
		  END  AS ACH
		, achs.Name AS ACHStatus
		, CASE 
			WHEN ISNULL(ach.ID,'') = '' THEN NULL
			ELSE ss.Name 
		  END AS ACHSourceSystem
		, ach.ReceiptContactMethodID 
		, cmACH.Name AS ACHReceiptContactMethod
		, Case 
			WHEN ISNULL(va.ID,'') = '' THEN 'No'
			ELSE 'Yes'
		  END AS VendorApplication
		, va.CreateDate AS VendorApplicationCreateDate
		, Case 
			WHEN ISNULL(vu.ID,'')= '' THEN 'No'
			ELSE 'Yes'
		  END AS WebAccount
		, CASE 
			WHEN ISNULL(cs.Name,'')='' THEN 'None'
			ELSE cs.Name
		  END  AS ContractStatus
		, c.StartDate AS ContractStartDate
		, c.EndDate AS ContractEndDate
		, Case
			WHEN ISNULL(crss.Name,'')='' THEN 'None'
			ELSE crss.Name 
		  END AS RateScheduleStatus
		, crs.StartDate AS RateScheduleStartDate
		, crs.EndDate AS RateScheduleEndDate
		, v.CreateDate
		, v.CreateBy
		, v.ModifyDate
		, v.ModifyBy    
FROM	Vendor v (NOLOCK)
LEFT JOIN	VendorStatus vs (NOLOCK) ON vs.ID = v.VendorStatusID
LEFT JOIN	VendorRegion vr (NOLOCK) ON vr.ID = v.VendorRegionID
LEFT JOIN	SourceSystem ss (NOLOCK) ON ss.ID = v.SourceSystemID  
LEFT JOIN	AddressEntity ae (NOLOCK) ON ae.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor') AND ae.RecordID = v.ID  AND ae.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
LEFT JOIN	AddressEntity aeBill (NOLOCK) ON aeBill.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor') AND aeBill.RecordID = v.ID  AND aeBill.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	PhoneEntity peofc (NOLOCK) ON peofc.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor') AND peofc.RecordID = v.ID 	AND peofc.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN	PhoneEntity pedis (NOLOCK) ON pedis.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor') AND pedis.RecordID = v.ID 	AND pedis.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
LEFT JOIN	VendorACH ach (NOLOCK) ON ach.VendorID = v.ID AND ach.IsActive = 1
LEFT JOIN	ACHStatus achs (NOLOCK) ON achs.ID = ach.ACHStatusID 
LEFT JOIN	SourceSystem ssACH (NOLOCK) ON ssACH.ID = ach.SourceSystemID
LEFT JOIN	ContactMethod cmACH (NOLOCK) ON cmACH.ID = ach.ReceiptContactMethodID
LEFT JOIN	VendorApplication va (NOLOCK) ON va.VendorID = v.ID 
LEFT JOIN	VendorUser vu (NOLOCK) ON vu.VendorID = v.ID 
LEFT JOIN	Contract c (NOLOCK) ON c.VendorID = v.ID AND c.IsActive = 1 
LEFT JOIN	ContractStatus cs (NOLOCK) ON cs.ID = c.ContractStatusID
LEFT JOIN	ContractRateSchedule crs (NOLOCK) ON crs.ContractID = c.ID AND crs.IsActive = 1 
LEFT JOIN	ContractRateScheduleStatus crss (NOLOCK) ON crss.ID = crs.ContractRateScheduleStatusID
WHERE	v.IsActive = 1




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
 WHERE id = object_id(N'[dbo].[dms_VerifyProgramServiceEventLimit]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

 --EXEC dms_VerifyProgramServiceEventLimit 1, 3,1,null, null, null  
CREATE PROCEDURE [dbo].[dms_VerifyProgramServiceEventLimit]  
      @ServiceRequestID int
      ,@ProgramID int
      ,@ProductCategoryID int
      ,@ProductID int 
      ,@VehicleTypeID int
      ,@VehicleCategoryID int 
      ,@SecondaryCategoryID INT = NULL
AS
BEGIN

	----Debug
	--DECLARE 
	--      @ServiceRequestID int = 7779982
	--      ,@ProgramID int = 3
	--      ,@ProductCategoryID int = 1
	--      ,@ProductID int = NULL
	--      ,@VehicleTypeID int = 1
	--      ,@VehicleCategoryID int = 1
	--      ,@SecondaryCategoryID INT = 1

	SET NOCOUNT ON  
	SET FMTONLY OFF  

	DECLARE @MemberID INT
		,@ProgramServiceEventLimitID int
		,@ProgramServiceEventLimitStoredProcedureName nvarchar(255)
		,@ProgramServiceEventLimitDescription nvarchar(255)
		,@MemberExpirationDate datetime
		,@MemberRenewalDate datetime

	SELECT @MemberID = m.ID
	  ,@MemberExpirationDate = m.ExpirationDate
	  ,@ProgramID = CASE WHEN @ProgramID IS NULL THEN m.ProgramID ELSE  @ProgramID END
	FROM ServiceRequest SR 
	JOIN [Case] c on c.id = SR.CaseID
	JOIN Member m on m.ID = c.MemberID
	WHERE SR.ID = @ServiceRequestID
	
	-- Determine last annual renewal date 
	SET @MemberRenewalDate = DATEADD(yy, (ROUND(DATEDIFF(dd, getdate(), @MemberExpirationDate)/365.00,0,1) + 1)*-1, @MemberExpirationDate)
	  
	If @ProductID IS NOT NULL
		SELECT @ProductCategoryID = ProductCategoryID
			  ,@VehicleCategoryID = VehicleCategoryID
			  ,@VehicleTypeID = VehicleTypeID
		FROM Product 
		WHERE ID = @ProductID

	-- Check for a custom stored procedure that verifies the event limits for this program
	SELECT TOP 1 
		@ProgramServiceEventLimitID = ID
		,@ProgramServiceEventLimitStoredProcedureName = StoredProcedureName
		,@ProgramServiceEventLimitDescription = [Description]
	FROM ProgramServiceEventLimit
	WHERE ProgramID = @ProgramID
	AND StoredProcedureName IS NOT NULL
	AND IsActive = 1
	
	
	IF @ProgramServiceEventLimitStoredProcedureName IS NOT NULL
		-- Custome stored procedure used to verify the event limits for the program
		BEGIN
		
		DECLARE @LimitEligibilityResults TABLE (
			ID int
			,ProgramID int
			,[Description] nvarchar(255)
			,Limit int
			,EventCount int
			,IsPrimary int
			,IsEligible int)
		
		INSERT INTO @LimitEligibilityResults	
		EXECUTE @ProgramServiceEventLimitStoredProcedureName 
		   @ServiceRequestID
		  ,@ProgramID
		  ,@ProductCategoryID
		  ,@ProductID
		  ,@VehicleTypeID
		  ,@VehicleCategoryID
		  ,@SecondaryCategoryID

		SELECT 
			@ProgramServiceEventLimitID ID
			,@ProgramID ProgramID
			,@ProgramServiceEventLimitDescription [Description]
			,Limit
			,EventCount
			,IsPrimary
			,IsEligible
		FROM @LimitEligibilityResults
			
		END
	
	ELSE
		-- Event limits are configured for specific program products
		BEGIN
		Select 
				ServiceRequestEvent.ProgramServiceEventLimitID
				,ServiceRequestEvent.ProgramEventLimitDescription
				,ServiceRequestEvent.ProgramEventLimit
				,ServiceRequestEvent.ProgramID
				,ServiceRequestEvent.MemberID
				,ServiceRequestEvent.ProductCategoryID
				,ServiceRequestEvent.ProductID
				,MIN(MinEventDate) MinEventDate
				,count(*) EventCount
			Into #tmpProgramEventCount
			From (
				Select 
					  ppl.ID ProgramServiceEventLimitID
					  ,ppl.[Description] ProgramEventLimitDescription
					  ,ppl.Limit ProgramEventLimit
					  ,c.ProgramID 
					  ,c.MemberID
					  ,sr.ID ServiceRequestID
					  ,ppl.ProductCategoryID
					  ,ppl.ProductID
					  ,pc.Name ProductCategoryName
					  ,MIN(po.IssueDate) MinEventDate 
				From [Case] c
				Join ServiceRequest sr on c.ID = sr.CaseID
				Join PurchaseOrder po on sr.ID = po.ServiceRequestID and po.PurchaseOrderStatusID in (Select ID from PurchaseOrderStatus Where Name IN ('Issued', 'Issued-Paid')) and po.IsActive = 1
				Join Product p on po.ProductID = p.ID
				Join ProductCategory pc on pc.id = p.ProductCategoryID
				Join ProgramServiceEventLimit ppl on ppl.ProgramID = c.ProgramID 
					  and (ppl.ProductCategoryID IS NULL OR ppl.ProductCategoryID = pc.ID)
					  and (ppl.ProductID IS NULL OR ppl.ProductID = p.ID)
					  and ppl.IsActive = 1
					  and po.IssueDate > 
							CASE WHEN ppl.IsLimitDurationSinceMemberRenewal = 1
									AND @MemberRenewalDate > (
										CASE WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
											 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
											 ELSE NULL
											 END
										) THEN @MemberRenewalDate
  								 WHEN ppl.LimitDurationUOM = 'Day' THEN DATEADD(dd,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Month' THEN DATEADD(mm,-ppl.LimitDuration, getdate())
								 WHEN ppl.LimitDurationUOM = 'Year' THEN DATEADD(yy,-ppl.LimitDuration, getdate())
								 ELSE NULL
							END 
				Where 
					  c.MemberID = @MemberID
					  and c.ProgramID = @ProgramID
					  and po.IssueDate IS NOT NULL
					  and sr.ID <> @ServiceRequestID
				Group By 
					  ppl.ID
					  ,ppl.[Description]
					  ,ppl.Limit
					  ,c.programid
					  ,c.MemberID
					  ,sr.ID
					  ,ppl.ProductCategoryID
					  ,ppl.ProductID
					  ,pc.Name
				) ServiceRequestEvent
			Group By 
				ServiceRequestEvent.ProgramServiceEventLimitID
				,ServiceRequestEvent.ProgramEventLimit
				,ServiceRequestEvent.ProgramEventLimitDescription
				,ServiceRequestEvent.ProgramID
				,ServiceRequestEvent.MemberID
				,ServiceRequestEvent.ProductCategoryID
				,ServiceRequestEvent.ProductID


			Select 
				psel.ID --ProgramServiceEventLimitID
				,psel.ProgramID
				,psel.[Description]
				,psel.Limit
				,ISNULL(pec.EventCount, 0) EventCount
				,CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID THEN 0 ELSE 1 END IsPrimary
				,CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END IsEligible
			From ProgramServiceEventLimit psel
			Left Outer Join #tmpProgramEventCount pec on pec.ProgramServiceEventLimitID = psel.ID
			Where psel.IsActive = 1
			AND psel.ProgramID = @ProgramID
			AND   (
					  (@ProductID IS NOT NULL 
							AND psel.ProductID = @ProductID)
					  OR
					  ((@ProductID IS NULL OR psel.ProductID IS NULL)
							AND (psel.ProductCategoryID = @ProductCategoryID OR psel.ProductCategoryID IS NULL) 
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  )
					  OR
					  (psel.ProductCategoryID = @SecondaryCategoryID AND @ProductCategoryID <> @SecondaryCategoryID
							AND (@VehicleCategoryID IS NULL OR psel.VehicleCategoryID IS NULL OR psel.VehicleCategoryID = @VehicleCategoryID)
							AND (@VehicleTypeID IS NULL OR psel.VehicleTypeID IS NULL OR psel.VehicleTypeID = @VehicleTypeID)
					  ))
			ORDER BY 
				(CASE WHEN ISNULL(pec.EventCount, 0) < psel.Limit THEN 1 ELSE 0 END) ASC
				,(CASE WHEN psel.ProductCategoryID = @SecondaryCategoryID THEN 0 ELSE 1 END) DESC
				,psel.ProductID DESC

			Drop table #tmpProgramEventCount
		END

END
