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

GO

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

GO

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
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_Service_Categories_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_Service_Categories_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_ProgramManagement_Service_Categories_List_Get @programID = 2
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_Service_Categories_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ProductCategoryIDOperator="-1" 
ProductCategoryNameOperator="-1" 
ProductCategoryDescriptionOperator="-1" 
ProgramIDOperator="-1" 
ProgramNameOperator="-1" 
ProgramDescriptionOperator="-1" 
VehicleCategoryIDOperator="-1" 
VehicleCategoryNameOperator="-1" 
VehicleCategoryDescriptionOperator="-1" 
VehicleTypeIDOperator="-1" 
VehicleTypeNameOperator="-1" 
vehicleTypeDescriptionOperator="-1" 
SequenceOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ProductCategoryIDOperator INT NOT NULL,
ProductCategoryIDValue int NULL,
ProductCategoryNameOperator INT NOT NULL,
ProductCategoryNameValue nvarchar(100) NULL,
ProductCategoryDescriptionOperator INT NOT NULL,
ProductCategoryDescriptionValue nvarchar(100) NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(100) NULL,
ProgramDescriptionOperator INT NOT NULL,
ProgramDescriptionValue nvarchar(100) NULL,
VehicleCategoryIDOperator INT NOT NULL,
VehicleCategoryIDValue int NULL,
VehicleCategoryNameOperator INT NOT NULL,
VehicleCategoryNameValue nvarchar(100) NULL,
VehicleCategoryDescriptionOperator INT NOT NULL,
VehicleCategoryDescriptionValue nvarchar(100) NULL,
VehicleTypeIDOperator INT NOT NULL,
VehicleTypeIDValue int NULL,
VehicleTypeNameOperator INT NOT NULL,
VehicleTypeNameValue nvarchar(100) NULL,
vehicleTypeDescriptionOperator INT NOT NULL,
vehicleTypeDescriptionValue nvarchar(100) NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ProductCategoryID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	ProductCategoryDescription nvarchar(100)  NULL ,
	ProgramID int  NULL ,
	ProgramName nvarchar(100)  NULL ,
	ProgramDescription nvarchar(100)  NULL ,
	VehicleCategoryID int  NULL ,
	VehicleCategoryName nvarchar(100)  NULL ,
	VehicleCategoryDescription nvarchar(100)  NULL ,
	VehicleTypeID int  NULL ,
	VehicleTypeName nvarchar(100)  NULL ,
	vehicleTypeDescription nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL 
) 
CREATE TABLE #tmp_FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ProductCategoryID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	ProductCategoryDescription nvarchar(100)  NULL ,
	ProgramID int  NULL ,
	ProgramName nvarchar(100)  NULL ,
	ProgramDescription nvarchar(100)  NULL ,
	VehicleCategoryID int  NULL ,
	VehicleCategoryName nvarchar(100)  NULL ,
	VehicleCategoryDescription nvarchar(100)  NULL ,
	VehicleTypeID int  NULL ,
	VehicleTypeName nvarchar(100)  NULL ,
	vehicleTypeDescription nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ProductCategoryIDOperator','INT'),-1),
	T.c.value('@ProductCategoryIDValue','int') ,
	ISNULL(T.c.value('@ProductCategoryNameOperator','INT'),-1),
	T.c.value('@ProductCategoryNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductCategoryDescriptionOperator','INT'),-1),
	T.c.value('@ProductCategoryDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramIDOperator','INT'),-1),
	T.c.value('@ProgramIDValue','int') ,
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProgramDescriptionOperator','INT'),-1),
	T.c.value('@ProgramDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryIDOperator','INT'),-1),
	T.c.value('@VehicleCategoryIDValue','int') ,
	ISNULL(T.c.value('@VehicleCategoryNameOperator','INT'),-1),
	T.c.value('@VehicleCategoryNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleCategoryDescriptionOperator','INT'),-1),
	T.c.value('@VehicleCategoryDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VehicleTypeIDOperator','INT'),-1),
	T.c.value('@VehicleTypeIDValue','int') ,
	ISNULL(T.c.value('@VehicleTypeNameOperator','INT'),-1),
	T.c.value('@VehicleTypeNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@vehicleTypeDescriptionOperator','INT'),-1),
	T.c.value('@vehicleTypeDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@SequenceOperator','INT'),-1),
	T.c.value('@SequenceValue','int') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------

;WITH wProgramConfig 
  AS
	(SELECT ROW_NUMBER() OVER ( PARTITION BY PPC.ID ORDER BY PP.Sequence) AS RowNum,
			PPC.ID,
			PPC.ProductCategoryID,
			PC.Name AS ProductCategoryName,
			PC.Description AS ProductCategoryDescription,
			PPC.ProgramID,
			P.Name AS ProgramName,
			P.Description AS ProgramDescription,
			PPC.VehicleCategoryID,
			VC.Name AS VehicleCategoryName,
			VC.Description AS VehicleCategoryDescription,
			PPC.VehicleTypeID,
			VT.Name AS VehicleTypeName,
			VT.Description AS vehicleTypeDescription,
			PPC.Sequence,
			PPC.IsActive
			FROM fnc_GetProgramsandParents(@programID) PP
			LEFT JOIN ProgramProductCategory PPC ON PP.ProgramID = PPC.ProgramID
			LEFT JOIN Program P ON P.ID = PPC.ProgramID
			LEFT JOIN ProductCategory PC ON PC.ID = PPC.ProductCategoryID
			LEFT JOIN VehicleCategory VC ON VC.ID = PPC.VehicleCategoryID
			LEFT JOIN VehicleType VT ON VT.ID=PPC.VehicleTypeID	
		)
INSERT INTO #tmp_FinalResults
SELECT 
			W.ID,
			W.ProductCategoryID,
			W.ProductCategoryName,
			W.ProductCategoryDescription,
			W.ProgramID,
			W.ProgramName,
			W.ProgramDescription,
			W.VehicleCategoryID,
			W.VehicleCategoryName,
			W.VehicleCategoryDescription,
			W.VehicleTypeID,
			W.VehicleTypeName,
			W.vehicleTypeDescription,
			W.Sequence,
			W.IsActive
FROM wProgramConfig W WHERE	W.RowNum = 1 AND W.ID IS NOT NULL ORDER BY W.Sequence
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.ProductCategoryID,
	T.ProductCategoryName,
	T.ProductCategoryDescription,
	T.ProgramID,
	T.ProgramName,
	T.ProgramDescription,
	T.VehicleCategoryID,
	T.VehicleCategoryName,
	T.VehicleCategoryDescription,
	T.VehicleTypeID,
	T.VehicleTypeName,
	T.vehicleTypeDescription,
	T.Sequence,
	T.IsActive
FROM #tmp_FinalResults T,
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
	 ( TMP.ProductCategoryIDOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 0 AND T.ProductCategoryID IS NULL ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 1 AND T.ProductCategoryID IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 2 AND T.ProductCategoryID = TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 3 AND T.ProductCategoryID <> TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 7 AND T.ProductCategoryID > TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 8 AND T.ProductCategoryID >= TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 9 AND T.ProductCategoryID < TMP.ProductCategoryIDValue ) 
 OR 
	 ( TMP.ProductCategoryIDOperator = 10 AND T.ProductCategoryID <= TMP.ProductCategoryIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryNameOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 0 AND T.ProductCategoryName IS NULL ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 1 AND T.ProductCategoryName IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 2 AND T.ProductCategoryName = TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 3 AND T.ProductCategoryName <> TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 4 AND T.ProductCategoryName LIKE TMP.ProductCategoryNameValue + '%') 
 OR 
	 ( TMP.ProductCategoryNameOperator = 5 AND T.ProductCategoryName LIKE '%' + TMP.ProductCategoryNameValue ) 
 OR 
	 ( TMP.ProductCategoryNameOperator = 6 AND T.ProductCategoryName LIKE '%' + TMP.ProductCategoryNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductCategoryDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 0 AND T.ProductCategoryDescription IS NULL ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 1 AND T.ProductCategoryDescription IS NOT NULL ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 2 AND T.ProductCategoryDescription = TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 3 AND T.ProductCategoryDescription <> TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 4 AND T.ProductCategoryDescription LIKE TMP.ProductCategoryDescriptionValue + '%') 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 5 AND T.ProductCategoryDescription LIKE '%' + TMP.ProductCategoryDescriptionValue ) 
 OR 
	 ( TMP.ProductCategoryDescriptionOperator = 6 AND T.ProductCategoryDescription LIKE '%' + TMP.ProductCategoryDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramIDOperator = 0 AND T.ProgramID IS NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 1 AND T.ProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 2 AND T.ProgramID = TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 3 AND T.ProgramID <> TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 7 AND T.ProgramID > TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 8 AND T.ProgramID >= TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 9 AND T.ProgramID < TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 10 AND T.ProgramID <= TMP.ProgramIDValue ) 

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
	 ( TMP.ProgramDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 0 AND T.ProgramDescription IS NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 1 AND T.ProgramDescription IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 2 AND T.ProgramDescription = TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 3 AND T.ProgramDescription <> TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 4 AND T.ProgramDescription LIKE TMP.ProgramDescriptionValue + '%') 
 OR 
	 ( TMP.ProgramDescriptionOperator = 5 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 6 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryIDOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 0 AND T.VehicleCategoryID IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 1 AND T.VehicleCategoryID IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 2 AND T.VehicleCategoryID = TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 3 AND T.VehicleCategoryID <> TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 7 AND T.VehicleCategoryID > TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 8 AND T.VehicleCategoryID >= TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 9 AND T.VehicleCategoryID < TMP.VehicleCategoryIDValue ) 
 OR 
	 ( TMP.VehicleCategoryIDOperator = 10 AND T.VehicleCategoryID <= TMP.VehicleCategoryIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryNameOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 0 AND T.VehicleCategoryName IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 1 AND T.VehicleCategoryName IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 2 AND T.VehicleCategoryName = TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 3 AND T.VehicleCategoryName <> TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 4 AND T.VehicleCategoryName LIKE TMP.VehicleCategoryNameValue + '%') 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 5 AND T.VehicleCategoryName LIKE '%' + TMP.VehicleCategoryNameValue ) 
 OR 
	 ( TMP.VehicleCategoryNameOperator = 6 AND T.VehicleCategoryName LIKE '%' + TMP.VehicleCategoryNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleCategoryDescriptionOperator = -1 ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 0 AND T.VehicleCategoryDescription IS NULL ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 1 AND T.VehicleCategoryDescription IS NOT NULL ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 2 AND T.VehicleCategoryDescription = TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 3 AND T.VehicleCategoryDescription <> TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 4 AND T.VehicleCategoryDescription LIKE TMP.VehicleCategoryDescriptionValue + '%') 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 5 AND T.VehicleCategoryDescription LIKE '%' + TMP.VehicleCategoryDescriptionValue ) 
 OR 
	 ( TMP.VehicleCategoryDescriptionOperator = 6 AND T.VehicleCategoryDescription LIKE '%' + TMP.VehicleCategoryDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VehicleTypeIDOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 0 AND T.VehicleTypeID IS NULL ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 1 AND T.VehicleTypeID IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 2 AND T.VehicleTypeID = TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 3 AND T.VehicleTypeID <> TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 7 AND T.VehicleTypeID > TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 8 AND T.VehicleTypeID >= TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 9 AND T.VehicleTypeID < TMP.VehicleTypeIDValue ) 
 OR 
	 ( TMP.VehicleTypeIDOperator = 10 AND T.VehicleTypeID <= TMP.VehicleTypeIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.VehicleTypeNameOperator = -1 ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 0 AND T.VehicleTypeName IS NULL ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 1 AND T.VehicleTypeName IS NOT NULL ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 2 AND T.VehicleTypeName = TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 3 AND T.VehicleTypeName <> TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 4 AND T.VehicleTypeName LIKE TMP.VehicleTypeNameValue + '%') 
 OR 
	 ( TMP.VehicleTypeNameOperator = 5 AND T.VehicleTypeName LIKE '%' + TMP.VehicleTypeNameValue ) 
 OR 
	 ( TMP.VehicleTypeNameOperator = 6 AND T.VehicleTypeName LIKE '%' + TMP.VehicleTypeNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.vehicleTypeDescriptionOperator = -1 ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 0 AND T.vehicleTypeDescription IS NULL ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 1 AND T.vehicleTypeDescription IS NOT NULL ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 2 AND T.vehicleTypeDescription = TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 3 AND T.vehicleTypeDescription <> TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 4 AND T.vehicleTypeDescription LIKE TMP.vehicleTypeDescriptionValue + '%') 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 5 AND T.vehicleTypeDescription LIKE '%' + TMP.vehicleTypeDescriptionValue ) 
 OR 
	 ( TMP.vehicleTypeDescriptionOperator = 6 AND T.vehicleTypeDescription LIKE '%' + TMP.vehicleTypeDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SequenceOperator = -1 ) 
 OR 
	 ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL ) 
 OR 
	 ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL ) 
 OR 
	 ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryID' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryID END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryID' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryID END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryName' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryName END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryName' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryName END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryDescription' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryDescription' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryDescription END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'ASC'
	 THEN T.ProgramDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'DESC'
	 THEN T.ProgramDescription END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryID' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryID END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryID' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryID END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryName' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryName END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryName' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryName END DESC ,

	 CASE WHEN @sortColumn = 'VehicleCategoryDescription' AND @sortOrder = 'ASC'
	 THEN T.VehicleCategoryDescription END ASC, 
	 CASE WHEN @sortColumn = 'VehicleCategoryDescription' AND @sortOrder = 'DESC'
	 THEN T.VehicleCategoryDescription END DESC ,

	 CASE WHEN @sortColumn = 'VehicleTypeID' AND @sortOrder = 'ASC'
	 THEN T.VehicleTypeID END ASC, 
	 CASE WHEN @sortColumn = 'VehicleTypeID' AND @sortOrder = 'DESC'
	 THEN T.VehicleTypeID END DESC ,

	 CASE WHEN @sortColumn = 'VehicleTypeName' AND @sortOrder = 'ASC'
	 THEN T.VehicleTypeName END ASC, 
	 CASE WHEN @sortColumn = 'VehicleTypeName' AND @sortOrder = 'DESC'
	 THEN T.VehicleTypeName END DESC ,

	 CASE WHEN @sortColumn = 'vehicleTypeDescription' AND @sortOrder = 'ASC'
	 THEN T.vehicleTypeDescription END ASC, 
	 CASE WHEN @sortColumn = 'vehicleTypeDescription' AND @sortOrder = 'DESC'
	 THEN T.vehicleTypeDescription END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC 


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
DROP TABLE #tmp_FinalResults
END

GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ProgramManagement_VehicleTypes_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ProgramManagement_VehicleTypes_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_ProgramManagement_VehicleTypes_List_Get @programID = 72
 CREATE PROCEDURE [dbo].[dms_ProgramManagement_VehicleTypes_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @programID INT  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter
ProgramNameOperator = "-1" 
VehicleTypeOperator="-1" 
MaxAllowedOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(50) NULL,
VehicleTypeOperator INT NOT NULL,
VehicleTypeValue NVARCHAR(50) NULL,
MaxAllowedOperator INT NOT NULL,
MaxAllowedValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(50) NULL,
	ID int  NULL ,
	VehicleType NVARCHAR(50)  NULL ,
	MaxAllowed int  NULL ,
	IsActive bit  NULL 
) 
CREATE TABLE #tmp_FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProgramID INT NOT NULL,
	ProgramName nvarchar(50) NULL,
	ID int  NULL ,
	VehicleType NVARCHAR(50)  NULL ,
	MaxAllowed int  NULL ,
	IsActive bit  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProgramNameOperator','INT'),-1),
	T.c.value('@ProgramNameValue','nvarchar(50)') ,
	ISNULL(T.c.value('@VehicleTypeOperator','INT'),-1),
	T.c.value('@VehicleTypeValue','nvarchar(50)') ,
	ISNULL(T.c.value('@MaxAllowedOperator','INT'),-1),
	T.c.value('@MaxAllowedValue','int') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

;WITH wProgramConfig 
		AS
		(	SELECT ROW_NUMBER() OVER ( PARTITION BY V.Name ORDER BY PP.Sequence) AS RowNum,
					PP.ProgramID,
					P.Name ProgramName,
					V.[Description] VehicleType,
					PV.MaxAllowed,
					PV.IsActive,
					PV.ID,
					PP.Sequence AS Sequence
			FROM fnc_GetProgramsandParents(@programID) PP
			JOIN ProgramVehicleType PV ON PV.ProgramID = PP.ProgramID 
			JOIN Program P ON PP.ProgramID = P.ID
			JOIN VehicleType V ON V.ID = PV.VehicleTypeID
			
		)
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmp_FinalResults
SELECT 
	W.ProgramID,
	W.ProgramName,
    W.ID,
    W.VehicleType,
	W.MaxAllowed,
	W.IsActive
FROM wProgramConfig W
	 WHERE	W.RowNum = 1
	 ORDER BY W.Sequence,W.ID
		 
INSERT INTO #FinalResults
SELECT 
	T.ProgramID,
	T.ProgramName,
	T.ID,
	T.VehicleType,
	T.MaxAllowed,
	T.IsActive
FROM #tmp_FinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

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
	 ( TMP.MaxAllowedOperator = -1 ) 
 OR 
	 ( TMP.MaxAllowedOperator = 0 AND T.MaxAllowed IS NULL ) 
 OR 
	 ( TMP.MaxAllowedOperator = 1 AND T.MaxAllowed IS NOT NULL ) 
 OR 
	 ( TMP.MaxAllowedOperator = 2 AND T.MaxAllowed = TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 3 AND T.MaxAllowed <> TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 7 AND T.MaxAllowed > TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 8 AND T.MaxAllowed >= TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 9 AND T.MaxAllowed < TMP.MaxAllowedValue ) 
 OR 
	 ( TMP.MaxAllowedOperator = 10 AND T.MaxAllowed <= TMP.MaxAllowedValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'ASC'
	 THEN T.VehicleType END ASC, 
	 CASE WHEN @sortColumn = 'VehicleType' AND @sortOrder = 'DESC'
	 THEN T.VehicleType END DESC ,

	 CASE WHEN @sortColumn = 'MaxAllowed' AND @sortOrder = 'ASC'
	 THEN T.MaxAllowed END ASC, 
	 CASE WHEN @sortColumn = 'MaxAllowed' AND @sortOrder = 'DESC'
	 THEN T.MaxAllowed END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

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
DROP TABLE #tmp_FinalResults
END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramVehicleType]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramVehicleType] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramVehicleType]( 
 @programVehicleId INT,
 @vehicleTypeID INT=NULL,
 @maxAllowed INT=NULL,
 @isActive bit=NULL,
 @isAdd bit,
 @programID int=NULL
 )
 AS
 BEGIN
 
 IF @isAdd=1 
 BEGIN
 
	INSERT INTO ProgramVehicleType(ProgramID,VehicleTypeID,MaxAllowed,IsActive)
	VALUES(@programID,@vehicleTypeID,@maxAllowed,@isActive)
	
 END
 ELSE BEGIN
 
	UPDATE ProgramVehicleType
	SET VehicleTypeID=@vehicleTypeID,
		MaxAllowed=@maxAllowed,
		IsActive=@isActive
	WHERE ID=@programVehicleId
 END
 
 END
GO

GO

GO
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveServiceCategoryInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveServiceCategoryInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveServiceCategoryInformation]( 
 @id INT ,
 @programID INT = NULL,
 @productCategoryID INT = NULL,
 @vehicleTypeID INT = NULL,
 @vehicleCategoryID INT = NULL,
 @sequence INT = NULL,
 @isActive BIT = NULL
 )
  AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramProductCategory 
		SET ProductCategoryID = @productCategoryID,
			VehicleCategoryID = @vehicleCategoryID,
			VehicleTypeID = @vehicleTypeID,
			Sequence = @sequence,
			IsActive = @isActive,
			ProgramID = @programID
		WHERE ID = @id
			
	 END
 ELSE
	 BEGIN
		INSERT INTO ProgramProductCategory(
			ProductCategoryID,
			ProgramID,
			VehicleCategoryID,
			VehicleTypeID,
			Sequence,
			IsActive
		)
		VALUES(
			@productCategoryID,
			@programID,
			@vehicleCategoryID,
			@vehicleTypeID,
			@sequence,
			@isActive
		)
	 END
 END
GO

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

GO

GO

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
-- EXEC [dbo].[dms_program_productcategory_get] 3,NULL,NULL
 
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
		JOIN	[dbo].[fnc_getprogramsandparents](3) FNCP ON PC.ProgramID = FNCP.ProgramID
		AND		(VehicleTypeID = @vehicleTypeID OR VehicleTypeID IS NULL)
		AND		(VehicleCategoryID = @vehicleCategoryID OR VehicleCategoryID IS NULL)

	
	) EL ON PC.ID = EL.ID
	ORDER BY PC.Sequence

END
GO

GO

GO
