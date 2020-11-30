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
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC dms_ProgramManagement_ProgramServiceEventLimit_List_Get
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_ProgramServiceEventLimit_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ProgramOperator="-1" 
ProductCategoryOperator="-1" 
ProductOperator="-1" 
VehicleTypeOperator="-1" 
VehicleCategoryOperator="-1" 
PSELDescriptionOperator="-1" 
LimitOperator="-1" 
LimitDurationOperator="-1" 
LimitDurationUOMOperator="-1" 
StoredProcedureNameOperator="-1" 
IsActiveOperator="-1" 
CreateByOperator="-1" 
CreateDateOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ProgramOperator INT NOT NULL,
ProgramValue nvarchar(100) NULL,
ProductCategoryOperator INT NOT NULL,
ProductCategoryValue nvarchar(100) NULL,
ProductOperator INT NOT NULL,
ProductValue nvarchar(100) NULL,
VehicleTypeOperator INT NOT NULL,
VehicleTypeValue nvarchar(100) NULL,
VehicleCategoryOperator INT NOT NULL,
VehicleCategoryValue nvarchar(100) NULL,
PSELDescriptionOperator INT NOT NULL,
PSELDescriptionValue nvarchar(255) NULL,
LimitOperator INT NOT NULL,
LimitValue int NULL,
LimitDurationOperator INT NOT NULL,
LimitDurationValue int NULL,
LimitDurationUOMOperator INT NOT NULL,
LimitDurationUOMValue nvarchar(100) NULL,
StoredProcedureNameOperator INT NOT NULL,
StoredProcedureNameValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(100) NULL,
CreateDateOperator INT NOT NULL,
CreateDateValue datetime NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Program nvarchar(100)  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	Product nvarchar(100)  NULL ,
	VehicleType nvarchar(100)  NULL ,
	VehicleCategory nvarchar(100)  NULL ,
	PSELDescription nvarchar(255)  NULL ,
	Limit int  NULL ,
	LimitDuration int  NULL ,
	LimitDurationUOM nvarchar(100)  NULL ,
	StoredProcedureName nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	CreateBy nvarchar(100)  NULL ,
	CreateDate datetime  NULL 
) 

 CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Program nvarchar(100)  NULL ,
	ProductCategory nvarchar(100)  NULL ,
	Product nvarchar(100)  NULL ,
	VehicleType nvarchar(100)  NULL ,
	VehicleCategory nvarchar(100)  NULL ,
	PSELDescription nvarchar(255)  NULL ,
	Limit int  NULL ,
	LimitDuration int  NULL ,
	LimitDurationUOM nvarchar(100)  NULL ,
	StoredProcedureName nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	CreateBy nvarchar(100)  NULL ,
	CreateDate datetime  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ProgramOperator','INT'),-1),
	T.c.value('@ProgramValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductCategoryOperator','INT'),-1),
	T.c.value('@ProductCategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductOperator','INT'),-1),
	T.c.value('@ProductValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleTypeOperator','INT'),-1),
	T.c.value('@VehicleTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryOperator','INT'),-1),
	T.c.value('@VehicleCategoryValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PSELDescriptionOperator','INT'),-1),
	T.c.value('@PSELDescriptionValue','nvarchar(255)') ,
	ISNULL(T.c.value('@LimitOperator','INT'),-1),
	T.c.value('@LimitValue','int') ,
	ISNULL(T.c.value('@LimitDurationOperator','INT'),-1),
	T.c.value('@LimitDurationValue','int') ,
	ISNULL(T.c.value('@LimitDurationUOMOperator','INT'),-1),
	T.c.value('@LimitDurationUOMValue','nvarchar(100)') ,
	ISNULL(T.c.value('@StoredProcedureNameOperator','INT'),-1),
	T.c.value('@StoredProcedureNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateDateOperator','INT'),-1),
	T.c.value('@CreateDateValue','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
Select 
	  PSEL.ID
	, P.[Description] AS Program
	, PC.[Description] AS ProductCategory
	, PD.Name AS Product
	, VT.Name AS VehicleType
	, VC.Name AS VehicleCategory
	, PSEL.Description AS PSELDescription
	, PSEL.Limit AS Limit
	, PSEL.LimitDuration
	, PSEL.LimitDurationUOM
	, PSEL.StoredProcedureName
	, PSEL.IsActive
	, PSEL.CreateBy
	, PSEL.CreateDate
FROM ProgramServiceEventLimit PSEL
LEFT JOIN Program P (NOLOCK) ON PSEL.ProgramID = P.ID
LEFT JOIN ProductCategory PC (NOLOCK) ON PSEL.ProductCategoryID = PC.ID
LEFT JOIN Product PD (NOLOCK) ON PSEL.ProductID = PD.ID
LEFT JOIN VehicleType VT (NOLOCK) ON PSEL.VehicleTypeID = VT.ID
LEFT JOIN VehicleCategory VC (NOLOCK) ON PSEL.VehicleCategoryID = VC.ID
WHERE P.ID = @programID


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.Program,
	T.ProductCategory,
	T.Product,
	T.VehicleType,
	T.VehicleCategory,
	T.PSELDescription,
	T.Limit,
	T.LimitDuration,
	T.LimitDurationUOM,
	T.StoredProcedureName,
	T.IsActive,
	T.CreateBy,
	T.CreateDate
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
	 ( TMP.ProgramOperator = -1 ) 
 OR 
	 ( TMP.ProgramOperator = 0 AND T.Program IS NULL ) 
 OR 
	 ( TMP.ProgramOperator = 1 AND T.Program IS NOT NULL ) 
 OR 
	 ( TMP.ProgramOperator = 2 AND T.Program = TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 3 AND T.Program <> TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 4 AND T.Program LIKE TMP.ProgramValue + '%') 
 OR 
	 ( TMP.ProgramOperator = 5 AND T.Program LIKE '%' + TMP.ProgramValue ) 
 OR 
	 ( TMP.ProgramOperator = 6 AND T.Program LIKE '%' + TMP.ProgramValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryOperator = 0 AND T.ProductCategory IS NULL ) 
 OR 
	 ( TMP.ProductCategoryOperator = 1 AND T.ProductCategory IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryOperator = 2 AND T.ProductCategory = TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 3 AND T.ProductCategory <> TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 4 AND T.ProductCategory LIKE TMP.ProductCategoryValue + '%') 
 OR 
	 ( TMP.ProductCategoryOperator = 5 AND T.ProductCategory LIKE '%' + TMP.ProductCategoryValue ) 
 OR 
	 ( TMP.ProductCategoryOperator = 6 AND T.ProductCategory LIKE '%' + TMP.ProductCategoryValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductOperator = -1 ) 
 OR 
	 ( TMP.ProductOperator = 0 AND T.Product IS NULL ) 
 OR 
	 ( TMP.ProductOperator = 1 AND T.Product IS NOT NULL ) 
 OR 
	 ( TMP.ProductOperator = 2 AND T.Product = TMP.ProductValue ) 
 OR 
	 ( TMP.ProductOperator = 3 AND T.Product <> TMP.ProductValue ) 
 OR 
	 ( TMP.ProductOperator = 4 AND T.Product LIKE TMP.ProductValue + '%') 
 OR 
	 ( TMP.ProductOperator = 5 AND T.Product LIKE '%' + TMP.ProductValue ) 
 OR 
	 ( TMP.ProductOperator = 6 AND T.Product LIKE '%' + TMP.ProductValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleTypeOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeOperator = 0 AND T.VehicleType IS NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 1 AND T.VehicleType IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeOperator = 2 AND T.VehicleType = TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 3 AND T.VehicleType <> TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 4 AND T.VehicleType LIKE TMP.VehicleTypeValue + '%') 
 OR 
	 ( TMP.VehicleTypeOperator = 5 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue ) 
 OR 
	 ( TMP.VehicleTypeOperator = 6 AND T.VehicleType LIKE '%' + TMP.VehicleTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 0 AND T.VehicleCategory IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 1 AND T.VehicleCategory IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 2 AND T.VehicleCategory = TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 3 AND T.VehicleCategory <> TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 4 AND T.VehicleCategory LIKE TMP.VehicleCategoryValue + '%') 
 OR 
	 ( TMP.VehicleCategoryOperator = 5 AND T.VehicleCategory LIKE '%' + TMP.VehicleCategoryValue ) 
 OR 
	 ( TMP.VehicleCategoryOperator = 6 AND T.VehicleCategory LIKE '%' + TMP.VehicleCategoryValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PSELDescriptionOperator = -1 ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 0 AND T.PSELDescription IS NULL ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 1 AND T.PSELDescription IS NOT NULL ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 2 AND T.PSELDescription = TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 3 AND T.PSELDescription <> TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 4 AND T.PSELDescription LIKE TMP.PSELDescriptionValue + '%') 
 OR 
	 ( TMP.PSELDescriptionOperator = 5 AND T.PSELDescription LIKE '%' + TMP.PSELDescriptionValue ) 
 OR 
	 ( TMP.PSELDescriptionOperator = 6 AND T.PSELDescription LIKE '%' + TMP.PSELDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LimitOperator = -1 ) 
 OR 
	 ( TMP.LimitOperator = 0 AND T.Limit IS NULL ) 
 OR 
	 ( TMP.LimitOperator = 1 AND T.Limit IS NOT NULL ) 
 OR 
	 ( TMP.LimitOperator = 2 AND T.Limit = TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 3 AND T.Limit <> TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 7 AND T.Limit > TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 8 AND T.Limit >= TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 9 AND T.Limit < TMP.LimitValue ) 
 OR 
	 ( TMP.LimitOperator = 10 AND T.Limit <= TMP.LimitValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LimitDurationOperator = -1 ) 
 OR 
	 ( TMP.LimitDurationOperator = 0 AND T.LimitDuration IS NULL ) 
 OR 
	 ( TMP.LimitDurationOperator = 1 AND T.LimitDuration IS NOT NULL ) 
 OR 
	 ( TMP.LimitDurationOperator = 2 AND T.LimitDuration = TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 3 AND T.LimitDuration <> TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 7 AND T.LimitDuration > TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 8 AND T.LimitDuration >= TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 9 AND T.LimitDuration < TMP.LimitDurationValue ) 
 OR 
	 ( TMP.LimitDurationOperator = 10 AND T.LimitDuration <= TMP.LimitDurationValue ) 

 ) 

 AND 

 ( 
	 ( TMP.LimitDurationUOMOperator = -1 ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 0 AND T.LimitDurationUOM IS NULL ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 1 AND T.LimitDurationUOM IS NOT NULL ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 2 AND T.LimitDurationUOM = TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 3 AND T.LimitDurationUOM <> TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 4 AND T.LimitDurationUOM LIKE TMP.LimitDurationUOMValue + '%') 
 OR 
	 ( TMP.LimitDurationUOMOperator = 5 AND T.LimitDurationUOM LIKE '%' + TMP.LimitDurationUOMValue ) 
 OR 
	 ( TMP.LimitDurationUOMOperator = 6 AND T.LimitDurationUOM LIKE '%' + TMP.LimitDurationUOMValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StoredProcedureNameOperator = -1 ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 0 AND T.StoredProcedureName IS NULL ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 1 AND T.StoredProcedureName IS NOT NULL ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 2 AND T.StoredProcedureName = TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 3 AND T.StoredProcedureName <> TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 4 AND T.StoredProcedureName LIKE TMP.StoredProcedureNameValue + '%') 
 OR 
	 ( TMP.StoredProcedureNameOperator = 5 AND T.StoredProcedureName LIKE '%' + TMP.StoredProcedureNameValue ) 
 OR 
	 ( TMP.StoredProcedureNameOperator = 6 AND T.StoredProcedureName LIKE '%' + TMP.StoredProcedureNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
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
	 ( TMP.CreateDateOperator = -1 ) 
 OR 
	 ( TMP.CreateDateOperator = 0 AND T.CreateDate IS NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 1 AND T.CreateDate IS NOT NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 2 AND T.CreateDate = TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 3 AND T.CreateDate <> TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 7 AND T.CreateDate > TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 8 AND T.CreateDate >= TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 9 AND T.CreateDate < TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 10 AND T.CreateDate <= TMP.CreateDateValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'ASC'
	 THEN T.Program END ASC, 
	 CASE WHEN @sortColumn = 'Program' AND @sortOrder = 'DESC'
	 THEN T.Program END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategory' AND @sortOrder = 'ASC'
	 THEN T.ProductCategory END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategory' AND @sortOrder = 'DESC'
	 THEN T.ProductCategory END DESC ,

	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'ASC'
	 THEN T.Product END ASC, 
	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'DESC'
	 THEN T.Product END DESC ,

	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'
	 THEN T.VehicleType END ASC, 
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'
	 THEN T.VehicleType END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategory' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategory END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategory' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategory END DESC ,

	 CASE WHEN @sortColumn = 'PSELDescription' AND @sortOrder = 'ASC'
	 THEN T.PSELDescription END ASC, 
	 CASE WHEN @sortColumn = 'PSELDescription' AND @sortOrder = 'DESC'
	 THEN T.PSELDescription END DESC ,

	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'ASC'
	 THEN T.Limit END ASC, 
	 CASE WHEN @sortColumn = 'Limit' AND @sortOrder = 'DESC'
	 THEN T.Limit END DESC ,

	 CASE WHEN @sortColumn = 'LimitDuration' AND @sortOrder = 'ASC'
	 THEN T.LimitDuration END ASC, 
	 CASE WHEN @sortColumn = 'LimitDuration' AND @sortOrder = 'DESC'
	 THEN T.LimitDuration END DESC ,

	 CASE WHEN @sortColumn = 'LimitDurationUOM' AND @sortOrder = 'ASC'
	 THEN T.LimitDurationUOM END ASC, 
	 CASE WHEN @sortColumn = 'LimitDurationUOM' AND @sortOrder = 'DESC'
	 THEN T.LimitDurationUOM END DESC ,

	 CASE WHEN @sortColumn = 'StoredProcedureName' AND @sortOrder = 'ASC'
	 THEN T.StoredProcedureName END ASC, 
	 CASE WHEN @sortColumn = 'StoredProcedureName' AND @sortOrder = 'DESC'
	 THEN T.StoredProcedureName END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC 


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
