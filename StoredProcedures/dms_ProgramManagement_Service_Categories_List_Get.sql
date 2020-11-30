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
