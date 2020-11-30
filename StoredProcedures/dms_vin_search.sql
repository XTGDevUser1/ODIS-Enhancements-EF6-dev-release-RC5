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
 WHERE id = object_id(N'[dbo].[dms_vin_search]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vin_search] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vin_search] @searchText = '1FT8W3BT6BEB57029'
 create PROCEDURE [dbo].[dms_vin_search]( 
   @searchText	NVARCHAR(100) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 100 
 , @pageSize int = 100
 , @sortColumn nvarchar(100)  = 'ExpirationDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
  
SET NOCOUNT ON

SET FMTONLY OFF

CREATE TABLE #FinalResults (
[RowNum] [bigint] NOT NULL IDENTITY(1,1),
[VehicleID] [int] NOT NULL,
[VIN] [nvarchar](50) NULL,
[VehicleType] [nvarchar](50) NULL,
[RVType] [nvarchar](50) NULL,
[WeightClass] [nvarchar](50) NULL,
[Year] [nvarchar](4) NULL,
[Make] [nvarchar](50) NULL,
[Model] [nvarchar](50) NULL,
[WarrantyStartDate] [nvarchar](10) NULL,
[CreateDate] [nvarchar](10) NULL,
[MembershipNumber] [nvarchar](25) NULL,
[MemberName] [nvarchar](4000) NULL,
[EffectiveDate] [nvarchar](10) NULL,
[ExpirationDate] [nvarchar](10) NULL
)

--------------------- BEGIN -----------------------------
---- Create a temp variable or a CTE with the actual SQL search query ----------
---- and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
-- LOGIC : BEGIN


INSERT INTO #FinalResults
SELECT    V.ID 
		, V.VIN
		, VT.Name AS [VehicleType]
		, RVT.Name AS [RVType]
		, VC.Name AS [WeightClass]
		, V.Year 
		, CASE WHEN V.Make = 'Other' THEN V.MakeOther ELSE V.Make END AS [Make]
		, CASE WHEN V.Model = 'Other' THEN V.ModelOther ELSE V.Model END AS [Model]
		, CONVERT(NVARCHAR(10),V.WarrantyStartDate,101) AS WarrantyStartDate
		, CONVERT(NVARCHAR(10),V.CreateDate,101) AS CreateDate
		, MS.MembershipNumber
		, REPLACE(RTRIM(
			  COALESCE(M.FirstName,'')+  
			  COALESCE(' ' + LEFT(M.MiddleName,1),'') +
			  COALESCE(' ' + CASE WHEN M.LastName = '' THEN NULL ELSE M.LastName END,'' )+
			  COALESCE(', ' + CASE WHEN M.Suffix = '' THEN NULL ELSE M.Suffix END,'')
				),'','') AS [MemberName]
		, CONVERT(NVARCHAR(10),M.EffectiveDate,101) AS EffectiveDate
		, CONVERT(NVARCHAR(10),M.ExpirationDate,101) AS ExpirationDate
FROM	Vehicle V
LEFT JOIN	VehicleType VT ON VT.ID = V.VehicleTypeID
LEFT JOIN	VehicleCategory VC ON VC.ID = V.VehicleCategoryID
LEFT JOIN	RVType RVT ON RVT.ID = V.RVTypeID
LEFT JOIN	Membership MS WITH(NOLOCK) ON MS.ID = V.MembershipID
JOIN	Member M WITH(NOLOCK) ON M.MembershipID = MS.ID AND M.IsPrimary = 1
WHERE	V.VIN = @searchText
AND		V.IsActive = 1
--AND		MS.IsActive = 1
ORDER BY	M.ExpirationDate DESC



DECLARE @count INT
SET @count = 0
SELECT @count = MAX(RowNum) FROM #FinalResults
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



SELECT	@count AS TotalRows, F.*

FROM	#FinalResults F
WHERE	F.RowNum BETWEEN @startInd AND @endInd

DROP TABLE #FinalResults



END
GO