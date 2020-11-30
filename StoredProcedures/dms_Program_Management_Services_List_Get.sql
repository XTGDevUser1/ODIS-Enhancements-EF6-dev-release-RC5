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
 WHERE id = object_id(N'[dbo].[dms_Program_Management_Services_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_Services_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Program_Management_Services_List_Get] @ProgramID =10 ,@pageSize = 25
 CREATE PROCEDURE [dbo].[dms_Program_Management_Services_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @ProgramID INT = NULL 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
		ProgramNameOperator="-1" 
		ProgramProductIDOperator="-1" 
		CategoryOperator="-1" 
		ServiceOperator="-1" 
		StartDateOperator="-1" 
		EndDateOperator="-1" 
		ServiceCoverageLimitOperator="-1" 
		IsServiceCoverageBestValueOperator="-1" 
		MaterialsCoverageLimitOperator="-1" 
		IsMaterialsMemberPayOperator="-1" 
		ServiceMileageLimitOperator="-1" 
		IsServiceMileageUnlimitedOperator="-1" 
		IsServiceMileageOverageAllowedOperator="-1" 
		IsReimbursementOnlyOperator="-1" 
		 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
	ProgramNameOperator INT NOT NULL,
	ProgramNameValue NVARCHAR(50) NULL,
	ProgramProductIDOperator INT NOT NULL,
	ProgramProductIDValue int NULL,
	CategoryOperator INT NOT NULL,
	CategoryValue nvarchar(100) NULL,
	ServiceOperator INT NOT NULL,
	ServiceValue nvarchar(100) NULL,
	StartDateOperator INT NOT NULL,
	StartDateValue datetime NULL,
	EndDateOperator INT NOT NULL,
	EndDateValue datetime NULL,
	ServiceCoverageLimitOperator INT NOT NULL,
	ServiceCoverageLimitValue money NULL,
	IsServiceCoverageBestValueOperator INT NOT NULL,
	IsServiceCoverageBestValueValue bit NULL,
	MaterialsCoverageLimitOperator INT NOT NULL,
	MaterialsCoverageLimitValue money NULL,
	IsMaterialsMemberPayOperator INT NOT NULL,
	IsMaterialsMemberPayValue bit NULL,
	ServiceMileageLimitOperator INT NOT NULL,
	ServiceMileageLimitValue int NULL,
	IsServiceMileageUnlimitedOperator INT NOT NULL,
	IsServiceMileageUnlimitedValue bit NULL,
	IsServiceMileageOverageAllowedOperator INT NOT NULL,
	IsServiceMileageOverageAllowedValue bit NULL,
	IsReimbursementOnlyOperator INT NOT NULL,
	IsReimbursementOnlyValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName NVARCHAR(50) NULL,
	ProgramProductID int  NULL ,
	Category nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	ServiceCoverageLimit money  NULL ,
	IsServiceCoverageBestValue bit  NULL ,
	MaterialsCoverageLimit money  NULL ,
	IsMaterialsMemberPay bit  NULL ,
	ServiceMileageLimit int  NULL ,
	IsServiceMileageUnlimited bit  NULL ,
	IsServiceMileageOverageAllowed bit  NULL ,
	IsReimbursementOnly bit  NULL 
) 

CREATE TABLE #FinalResults_temp( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName NVARCHAR(50) NULL,
	ProgramProductID int  NULL ,
	Category nvarchar(100)  NULL ,
	Service nvarchar(100)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	ServiceCoverageLimit money  NULL ,
	IsServiceCoverageBestValue bit  NULL ,
	MaterialsCoverageLimit money  NULL ,
	IsMaterialsMemberPay bit  NULL ,
	ServiceMileageLimit int  NULL ,
	IsServiceMileageUnlimited bit  NULL ,
	IsServiceMileageOverageAllowed bit  NULL ,
	IsReimbursementOnly bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','NVARCHAR(50)') ,
	ISNULL(T.c.value('@ProgramProductIDOperator','INT'),-1),
	T.c.value('@ProgramProductIDValue','int') ,
	ISNULL(T.c.value('@CategoryOperator','INT'),-1),
	T.c.value('@CategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ServiceOperator','INT'),-1),
	T.c.value('@ServiceValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StartDateOperator','INT'),-1),
	T.c.value('@StartDateValue','datetime') ,
	ISNULL(T.c.value('@EndDateOperator','INT'),-1),
	T.c.value('@EndDateValue','datetime') ,
	ISNULL(T.c.value('@ServiceCoverageLimitOperator','INT'),-1),
	T.c.value('@ServiceCoverageLimitValue','money') ,
	ISNULL(T.c.value('@IsServiceCoverageBestValueOperator','INT'),-1),
	T.c.value('@IsServiceCoverageBestValueValue','bit') ,
	ISNULL(T.c.value('@MaterialsCoverageLimitOperator','INT'),-1),
	T.c.value('@MaterialsCoverageLimitValue','money') ,
	ISNULL(T.c.value('@IsMaterialsMemberPayOperator','INT'),-1),
	T.c.value('@IsMaterialsMemberPayValue','bit') ,
	ISNULL(T.c.value('@ServiceMileageLimitOperator','INT'),-1),
	T.c.value('@ServiceMileageLimitValue','int') ,
	ISNULL(T.c.value('@IsServiceMileageUnlimitedOperator','INT'),-1),
	T.c.value('@IsServiceMileageUnlimitedValue','bit') ,
	ISNULL(T.c.value('@IsServiceMileageOverageAllowedOperator','INT'),-1),
	T.c.value('@IsServiceMileageOverageAllowedValue','bit') ,
	ISNULL(T.c.value('@IsReimbursementOnlyOperator','INT'),-1),
	T.c.value('@IsReimbursementOnlyValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
;WITH wProgramConfig 
  AS
	(SELECT ROW_NUMBER() OVER ( PARTITION BY PPR.ID ORDER BY PP.Sequence) AS RowNum,
			  P.ID AS ProgramID
			, P.Name AS ProgramName  
			, PPR.ID AS ProgramProductID
			, PC.Name AS Category
			, PR.Name AS [Service]
			, PPR.StartDate
			, PPR.EndDate
			, PPR.ServiceCoverageLimit
			, PPR.IsServiceCoverageBestValue
			, PPR.MaterialsCoverageLimit
			, PPR.IsMaterialsMemberPay
			, PPR.ServiceMileageLimit
			, PPR.IsServiceMileageUnlimited
			, PPR.IsServiceMileageOverageAllowed
			, PPR.IsReimbursementOnly
			, PP.Sequence
			FROM fnc_GetProgramsandParents(@programID) PP
			LEFT JOIN ProgramProduct PPR ON PP.ProgramID = PPR.ProgramID
			JOIN Program P (NOLOCK) ON P.ID = PP.ProgramID
			JOIN Product PR (NOLOCK) ON PR.ID = PPR.ProductID
			JOIN ProductCategory PC (NOLOCK) ON PC.ID = PR.ProductCategoryID
	)

INSERT INTO #FinalResults_temp
SELECT
			  W.ProgramID
			, W.ProgramName  
			, W.ProgramProductID
			, W.Category
			, W.[Service]
			, W.StartDate
			, W.EndDate
			, W.ServiceCoverageLimit
			, W.IsServiceCoverageBestValue
			, W.MaterialsCoverageLimit
			, W.IsMaterialsMemberPay
			, W.ServiceMileageLimit
			, W.IsServiceMileageUnlimited
			, W.IsServiceMileageOverageAllowed
			, W.IsReimbursementOnly
FROM wProgramConfig W WHERE	W.RowNum = 1  ORDER BY W.Sequence
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
	T.ProgramProductID,
	T.Category,
	T.Service,
	T.StartDate,
	T.EndDate,
	T.ServiceCoverageLimit,
	T.IsServiceCoverageBestValue,
	T.MaterialsCoverageLimit,
	T.IsMaterialsMemberPay,
	T.ServiceMileageLimit,
	T.IsServiceMileageUnlimited,
	T.IsServiceMileageOverageAllowed,
	T.IsReimbursementOnly
FROM #FinalResults_temp T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.ProgramProductIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 0 AND T.ProgramProductID IS NULL ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 1 AND T.ProgramProductID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 2 AND T.ProgramProductID = TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 3 AND T.ProgramProductID <> TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 7 AND T.ProgramProductID > TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 8 AND T.ProgramProductID >= TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 9 AND T.ProgramProductID < TMP.ProgramProductIDValue ) 
 OR 
	 ( TMP.ProgramProductIDOperator = 10 AND T.ProgramProductID <= TMP.ProgramProductIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CategoryOperator = -1 ) 
 OR 
	 ( TMP.CategoryOperator = 0 AND T.Category IS NULL ) 
 OR 
	 ( TMP.CategoryOperator = 1 AND T.Category IS NOT NULL ) 
 OR 
	 ( TMP.CategoryOperator = 2 AND T.Category = TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 3 AND T.Category <> TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 4 AND T.Category LIKE TMP.CategoryValue + '%') 
 OR 
	 ( TMP.CategoryOperator = 5 AND T.Category LIKE '%' + TMP.CategoryValue ) 
 OR 
	 ( TMP.CategoryOperator = 6 AND T.Category LIKE '%' + TMP.CategoryValue + '%' ) 
 ) 
  AND 

 ( 
	 ( TMP.ProgramNameOperator = -1 ) 
 OR 
	 ( TMP.ProgramNameOperator = 0 AND T.ProgramName IS NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 1 AND T.ProgramName IS NOT NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 2 AND T.ProgramName = TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 3 AND T.ProgramName <> TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 4 AND T.ProgramName LIKE TMP.ProgramNameValue + '%') 
 OR 
	 ( TMP.ProgramNameOperator = 5 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 6 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue + '%' ) 
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
	 ( TMP.StartDateOperator = -1 ) 
 OR 
	 ( TMP.StartDateOperator = 0 AND T.StartDate IS NULL ) 
 OR 
	 ( TMP.StartDateOperator = 1 AND T.StartDate IS NOT NULL ) 
 OR 
	 ( TMP.StartDateOperator = 2 AND T.StartDate = TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 3 AND T.StartDate <> TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 7 AND T.StartDate > TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 8 AND T.StartDate >= TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 9 AND T.StartDate < TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 10 AND T.StartDate <= TMP.StartDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EndDateOperator = -1 ) 
 OR 
	 ( TMP.EndDateOperator = 0 AND T.EndDate IS NULL ) 
 OR 
	 ( TMP.EndDateOperator = 1 AND T.EndDate IS NOT NULL ) 
 OR 
	 ( TMP.EndDateOperator = 2 AND T.EndDate = TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 3 AND T.EndDate <> TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 7 AND T.EndDate > TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 8 AND T.EndDate >= TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 9 AND T.EndDate < TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 10 AND T.EndDate <= TMP.EndDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ServiceCoverageLimitOperator = -1 ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 0 AND T.ServiceCoverageLimit IS NULL ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 1 AND T.ServiceCoverageLimit IS NOT NULL ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 2 AND T.ServiceCoverageLimit = TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 3 AND T.ServiceCoverageLimit <> TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 7 AND T.ServiceCoverageLimit > TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 8 AND T.ServiceCoverageLimit >= TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 9 AND T.ServiceCoverageLimit < TMP.ServiceCoverageLimitValue ) 
 OR 
	 ( TMP.ServiceCoverageLimitOperator = 10 AND T.ServiceCoverageLimit <= TMP.ServiceCoverageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsServiceCoverageBestValueOperator = -1 ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 0 AND T.IsServiceCoverageBestValue IS NULL ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 1 AND T.IsServiceCoverageBestValue IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 2 AND T.IsServiceCoverageBestValue = TMP.IsServiceCoverageBestValueValue ) 
 OR 
	 ( TMP.IsServiceCoverageBestValueOperator = 3 AND T.IsServiceCoverageBestValue <> TMP.IsServiceCoverageBestValueValue ) 
 ) 

 AND 

 ( 
	 ( TMP.MaterialsCoverageLimitOperator = -1 ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 0 AND T.MaterialsCoverageLimit IS NULL ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 1 AND T.MaterialsCoverageLimit IS NOT NULL ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 2 AND T.MaterialsCoverageLimit = TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 3 AND T.MaterialsCoverageLimit <> TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 7 AND T.MaterialsCoverageLimit > TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 8 AND T.MaterialsCoverageLimit >= TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 9 AND T.MaterialsCoverageLimit < TMP.MaterialsCoverageLimitValue ) 
 OR 
	 ( TMP.MaterialsCoverageLimitOperator = 10 AND T.MaterialsCoverageLimit <= TMP.MaterialsCoverageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsMaterialsMemberPayOperator = -1 ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 0 AND T.IsMaterialsMemberPay IS NULL ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 1 AND T.IsMaterialsMemberPay IS NOT NULL ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 2 AND T.IsMaterialsMemberPay = TMP.IsMaterialsMemberPayValue ) 
 OR 
	 ( TMP.IsMaterialsMemberPayOperator = 3 AND T.IsMaterialsMemberPay <> TMP.IsMaterialsMemberPayValue ) 
 ) 

 AND 

 ( 
	 ( TMP.ServiceMileageLimitOperator = -1 ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 0 AND T.ServiceMileageLimit IS NULL ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 1 AND T.ServiceMileageLimit IS NOT NULL ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 2 AND T.ServiceMileageLimit = TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 3 AND T.ServiceMileageLimit <> TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 7 AND T.ServiceMileageLimit > TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 8 AND T.ServiceMileageLimit >= TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 9 AND T.ServiceMileageLimit < TMP.ServiceMileageLimitValue ) 
 OR 
	 ( TMP.ServiceMileageLimitOperator = 10 AND T.ServiceMileageLimit <= TMP.ServiceMileageLimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsServiceMileageUnlimitedOperator = -1 ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 0 AND T.IsServiceMileageUnlimited IS NULL ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 1 AND T.IsServiceMileageUnlimited IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 2 AND T.IsServiceMileageUnlimited = TMP.IsServiceMileageUnlimitedValue ) 
 OR 
	 ( TMP.IsServiceMileageUnlimitedOperator = 3 AND T.IsServiceMileageUnlimited <> TMP.IsServiceMileageUnlimitedValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsServiceMileageOverageAllowedOperator = -1 ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 0 AND T.IsServiceMileageOverageAllowed IS NULL ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 1 AND T.IsServiceMileageOverageAllowed IS NOT NULL ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 2 AND T.IsServiceMileageOverageAllowed = TMP.IsServiceMileageOverageAllowedValue ) 
 OR 
	 ( TMP.IsServiceMileageOverageAllowedOperator = 3 AND T.IsServiceMileageOverageAllowed <> TMP.IsServiceMileageOverageAllowedValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsReimbursementOnlyOperator = -1 ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 0 AND T.IsReimbursementOnly IS NULL ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 1 AND T.IsReimbursementOnly IS NOT NULL ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 2 AND T.IsReimbursementOnly = TMP.IsReimbursementOnlyValue ) 
 OR 
	 ( TMP.IsReimbursementOnlyOperator = 3 AND T.IsReimbursementOnly <> TMP.IsReimbursementOnlyValue ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ProgramProductID' AND @sortOrder = 'ASC'
	 THEN T.ProgramProductID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramProductID' AND @sortOrder = 'DESC'
	 THEN T.ProgramProductID END DESC ,

	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'ASC'
	 THEN T.Category END ASC, 
	 CASE WHEN @sortColumn = 'Category' AND @sortOrder = 'DESC'
	 THEN T.Category END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'
	 THEN T.StartDate END ASC, 
	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'
	 THEN T.StartDate END DESC ,

	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'
	 THEN T.EndDate END ASC, 
	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'
	 THEN T.EndDate END DESC ,

	 CASE WHEN @sortColumn = 'ServiceCoverageLimit' AND @sortOrder = 'ASC'
	 THEN T.ServiceCoverageLimit END ASC, 
	 CASE WHEN @sortColumn = 'ServiceCoverageLimit' AND @sortOrder = 'DESC'
	 THEN T.ServiceCoverageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceCoverageBestValue' AND @sortOrder = 'ASC'
	 THEN T.IsServiceCoverageBestValue END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceCoverageBestValue' AND @sortOrder = 'DESC'
	 THEN T.IsServiceCoverageBestValue END DESC ,

	 CASE WHEN @sortColumn = 'MaterialsCoverageLimit' AND @sortOrder = 'ASC'
	 THEN T.MaterialsCoverageLimit END ASC, 
	 CASE WHEN @sortColumn = 'MaterialsCoverageLimit' AND @sortOrder = 'DESC'
	 THEN T.MaterialsCoverageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsMaterialsMemberPay' AND @sortOrder = 'ASC'
	 THEN T.IsMaterialsMemberPay END ASC, 
	 CASE WHEN @sortColumn = 'IsMaterialsMemberPay' AND @sortOrder = 'DESC'
	 THEN T.IsMaterialsMemberPay END DESC ,

	 CASE WHEN @sortColumn = 'ServiceMileageLimit' AND @sortOrder = 'ASC'
	 THEN T.ServiceMileageLimit END ASC, 
	 CASE WHEN @sortColumn = 'ServiceMileageLimit' AND @sortOrder = 'DESC'
	 THEN T.ServiceMileageLimit END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceMileageUnlimited' AND @sortOrder = 'ASC'
	 THEN T.IsServiceMileageUnlimited END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceMileageUnlimited' AND @sortOrder = 'DESC'
	 THEN T.IsServiceMileageUnlimited END DESC ,

	 CASE WHEN @sortColumn = 'IsServiceMileageOverageAllowed' AND @sortOrder = 'ASC'
	 THEN T.IsServiceMileageOverageAllowed END ASC, 
	 CASE WHEN @sortColumn = 'IsServiceMileageOverageAllowed' AND @sortOrder = 'DESC'
	 THEN T.IsServiceMileageOverageAllowed END DESC ,

	 CASE WHEN @sortColumn = 'IsReimbursementOnly' AND @sortOrder = 'ASC'
	 THEN T.IsReimbursementOnly END ASC, 
	 CASE WHEN @sortColumn = 'IsReimbursementOnly' AND @sortOrder = 'DESC'
	 THEN T.IsReimbursementOnly END DESC,
	 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC  


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
DROP TABLE #FinalResults_temp
END
