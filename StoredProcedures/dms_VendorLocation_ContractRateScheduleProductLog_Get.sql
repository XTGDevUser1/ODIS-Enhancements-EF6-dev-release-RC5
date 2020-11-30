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
 WHERE id = object_id(N'[dbo].dms_VendorLocation_ContractRateScheduleProductLog_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_VendorLocation_ContractRateScheduleProductLog_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 --EXEC dms_VendorLocation_ContractRateScheduleProductLog_Get @ContractRateScheduleID = 82
 CREATE PROCEDURE [dbo].dms_VendorLocation_ContractRateScheduleProductLog_Get( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @ContractRateScheduleID INT = NULL 
 , @VendorLocationID INT = NULL
 ) 
 AS 
 BEGIN 
  SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ActivityTypeOperator="-1" 
ProductIDOperator="-1" 
ProductNameOperator="-1" 
RateTypeIDOperator="-1" 
RateTypeNameOperator="-1" 
OldPriceOperator="-1" 
NewPriceOperator="-1" 
OldQuantityOperator="-1" 
NewQuantityOperator="-1" 
CreateDateOperator="-1" 
CreateByOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
ActivityTypeOperator INT NOT NULL,
ActivityTypeValue nvarchar(100) NULL,
ProductIDOperator INT NOT NULL,
ProductIDValue int NULL,
ProductNameOperator INT NOT NULL,
ProductNameValue nvarchar(100) NULL,
RateTypeIDOperator INT NOT NULL,
RateTypeIDValue int NULL,
RateTypeNameOperator INT NOT NULL,
RateTypeNameValue nvarchar(100) NULL,
OldPriceOperator INT NOT NULL,
OldPriceValue money NULL,
NewPriceOperator INT NOT NULL,
NewPriceValue money NULL,
OldQuantityOperator INT NOT NULL,
OldQuantityValue int NULL,
NewQuantityOperator INT NOT NULL,
NewQuantityValue int NULL,
CreateDateOperator INT NOT NULL,
CreateDateValue datetime NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(100) NULL
)
 DECLARE @FinalResults AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ActivityType nvarchar(100)  NULL ,
	ProductID int  NULL ,
	ProductName nvarchar(100)  NULL ,
	RateTypeID int  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	OldPrice money  NULL ,
	NewPrice money  NULL ,
	OldQuantity int  NULL ,
	NewQuantity int  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL 
) 

DECLARE @FinalResults_TEMP AS TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ActivityType nvarchar(100)  NULL ,
	ProductID int  NULL ,
	ProductName nvarchar(100)  NULL ,
	RateTypeID int  NULL ,
	RateTypeName nvarchar(100)  NULL ,
	OldPrice money  NULL ,
	NewPrice money  NULL ,
	OldQuantity int  NULL ,
	NewQuantity int  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@ActivityTypeOperator','INT'),-1),
	T.c.value('@ActivityTypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductIDOperator','INT'),-1),
	T.c.value('@ProductIDValue','int') ,
	ISNULL(T.c.value('@ProductNameOperator','INT'),-1),
	T.c.value('@ProductNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@RateTypeIDOperator','INT'),-1),
	T.c.value('@RateTypeIDValue','int') ,
	ISNULL(T.c.value('@RateTypeNameOperator','INT'),-1),
	T.c.value('@RateTypeNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@OldPriceOperator','INT'),-1),
	T.c.value('@OldPriceValue','money') ,
	ISNULL(T.c.value('@NewPriceOperator','INT'),-1),
	T.c.value('@NewPriceValue','money') ,
	ISNULL(T.c.value('@OldQuantityOperator','INT'),-1),
	T.c.value('@OldQuantityValue','int') ,
	ISNULL(T.c.value('@NewQuantityOperator','INT'),-1),
	T.c.value('@NewQuantityValue','int') ,
	ISNULL(T.c.value('@CreateDateOperator','INT'),-1),
	T.c.value('@CreateDateValue','datetime') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

INSERT INTO @FinalResults_TEMP

 	SELECT PL.ID
	, PL.ActivityType
	, PL.ProductID
	, P.Name AS ProductName
	, PL.RateTypeID
	, RT.Name AS RateTypeName
	, PL.OldPrice
	, PL.NewPrice
	, PL.OldQuantity
	, PL.NewQuantity
	, PL.CreateDate
	, PL.CreateBy
FROM ContractRateScheduleProductLog PL
JOIN Product P ON P.ID = PL.ProductID
JOIN RateType RT ON RT.ID = PL.RateTypeID
WHERE PL.ContractRateScheduleID = @ContractRateScheduleID 
AND ((@VendorLocationID IS NULL) AND (PL.VendorLocationID IS NULL))
OR ((@VendorLocationID IS NOT NULL) AND (PL.VendorLocationID = @VendorLocationID))

ORDER BY PL.ID,PL.RateTypeID
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.ActivityType,
	T.ProductID,
	T.ProductName,
	T.RateTypeID,
	T.RateTypeName,
	T.OldPrice,
	T.NewPrice,
	T.OldQuantity,
	T.NewQuantity,
	T.CreateDate,
	T.CreateBy
FROM @FinalResults_TEMP T,
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
	 ( TMP.ActivityTypeOperator = -1 ) 
 OR 
	 ( TMP.ActivityTypeOperator = 0 AND T.ActivityType IS NULL ) 
 OR 
	 ( TMP.ActivityTypeOperator = 1 AND T.ActivityType IS NOT NULL ) 
 OR 
	 ( TMP.ActivityTypeOperator = 2 AND T.ActivityType = TMP.ActivityTypeValue ) 
 OR 
	 ( TMP.ActivityTypeOperator = 3 AND T.ActivityType <> TMP.ActivityTypeValue ) 
 OR 
	 ( TMP.ActivityTypeOperator = 4 AND T.ActivityType LIKE TMP.ActivityTypeValue + '%') 
 OR 
	 ( TMP.ActivityTypeOperator = 5 AND T.ActivityType LIKE '%' + TMP.ActivityTypeValue ) 
 OR 
	 ( TMP.ActivityTypeOperator = 6 AND T.ActivityType LIKE '%' + TMP.ActivityTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProductIDOperator = -1 ) 
 OR 
	 ( TMP.ProductIDOperator = 0 AND T.ProductID IS NULL ) 
 OR 
	 ( TMP.ProductIDOperator = 1 AND T.ProductID IS NOT NULL ) 
 OR 
	 ( TMP.ProductIDOperator = 2 AND T.ProductID = TMP.ProductIDValue ) 
 OR 
	 ( TMP.ProductIDOperator = 3 AND T.ProductID <> TMP.ProductIDValue ) 
 OR 
	 ( TMP.ProductIDOperator = 7 AND T.ProductID > TMP.ProductIDValue ) 
 OR 
	 ( TMP.ProductIDOperator = 8 AND T.ProductID >= TMP.ProductIDValue ) 
 OR 
	 ( TMP.ProductIDOperator = 9 AND T.ProductID < TMP.ProductIDValue ) 
 OR 
	 ( TMP.ProductIDOperator = 10 AND T.ProductID <= TMP.ProductIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProductNameOperator = -1 ) 
 OR 
	 ( TMP.ProductNameOperator = 0 AND T.ProductName IS NULL ) 
 OR 
	 ( TMP.ProductNameOperator = 1 AND T.ProductName IS NOT NULL ) 
 OR 
	 ( TMP.ProductNameOperator = 2 AND T.ProductName = TMP.ProductNameValue ) 
 OR 
	 ( TMP.ProductNameOperator = 3 AND T.ProductName <> TMP.ProductNameValue ) 
 OR 
	 ( TMP.ProductNameOperator = 4 AND T.ProductName LIKE TMP.ProductNameValue + '%') 
 OR 
	 ( TMP.ProductNameOperator = 5 AND T.ProductName LIKE '%' + TMP.ProductNameValue ) 
 OR 
	 ( TMP.ProductNameOperator = 6 AND T.ProductName LIKE '%' + TMP.ProductNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.RateTypeIDOperator = -1 ) 
 OR 
	 ( TMP.RateTypeIDOperator = 0 AND T.RateTypeID IS NULL ) 
 OR 
	 ( TMP.RateTypeIDOperator = 1 AND T.RateTypeID IS NOT NULL ) 
 OR 
	 ( TMP.RateTypeIDOperator = 2 AND T.RateTypeID = TMP.RateTypeIDValue ) 
 OR 
	 ( TMP.RateTypeIDOperator = 3 AND T.RateTypeID <> TMP.RateTypeIDValue ) 
 OR 
	 ( TMP.RateTypeIDOperator = 7 AND T.RateTypeID > TMP.RateTypeIDValue ) 
 OR 
	 ( TMP.RateTypeIDOperator = 8 AND T.RateTypeID >= TMP.RateTypeIDValue ) 
 OR 
	 ( TMP.RateTypeIDOperator = 9 AND T.RateTypeID < TMP.RateTypeIDValue ) 
 OR 
	 ( TMP.RateTypeIDOperator = 10 AND T.RateTypeID <= TMP.RateTypeIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RateTypeNameOperator = -1 ) 
 OR 
	 ( TMP.RateTypeNameOperator = 0 AND T.RateTypeName IS NULL ) 
 OR 
	 ( TMP.RateTypeNameOperator = 1 AND T.RateTypeName IS NOT NULL ) 
 OR 
	 ( TMP.RateTypeNameOperator = 2 AND T.RateTypeName = TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 3 AND T.RateTypeName <> TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 4 AND T.RateTypeName LIKE TMP.RateTypeNameValue + '%') 
 OR 
	 ( TMP.RateTypeNameOperator = 5 AND T.RateTypeName LIKE '%' + TMP.RateTypeNameValue ) 
 OR 
	 ( TMP.RateTypeNameOperator = 6 AND T.RateTypeName LIKE '%' + TMP.RateTypeNameValue + '%' ) 
 ) 

 AND 

 ( 
 
 ( TMP.OldPriceOperator = -1 ) 
 OR 
	 ( TMP.OldPriceOperator = 0 AND T.OldPrice IS NULL ) 
 OR 
	 ( TMP.OldPriceOperator = 1 AND T.OldPrice IS NOT NULL ) 
 OR 
	 ( TMP.OldPriceOperator = 2 AND T.OldPrice = TMP.OldPriceValue ) 
 OR 
	 ( TMP.OldPriceOperator = 3 AND T.OldPrice <> TMP.OldPriceValue ) 
 OR 
	 ( TMP.OldPriceOperator = 7 AND T.OldPrice > TMP.OldPriceValue ) 
 OR 
	 ( TMP.OldPriceOperator = 8 AND T.OldPrice >= TMP.OldPriceValue ) 
 OR 
	 ( TMP.OldPriceOperator = 9 AND T.OldPrice < TMP.OldPriceValue ) 
 OR 
	 ( TMP.OldPriceOperator = 10 AND T.OldPrice <= TMP.OldPriceValue ) 	 
	 
 ) 

 AND 

 ( 
	 ( TMP.NewPriceOperator = -1 ) 
 OR 
	 ( TMP.NewPriceOperator = 0 AND T.NewPrice IS NULL ) 
 OR 
	 ( TMP.NewPriceOperator = 1 AND T.NewPrice IS NOT NULL ) 
 OR 
	 ( TMP.NewPriceOperator = 2 AND T.NewPrice = TMP.NewPriceValue ) 
 OR 
	 ( TMP.NewPriceOperator = 3 AND T.NewPrice <> TMP.NewPriceValue ) 
 OR 
	 ( TMP.NewPriceOperator = 7 AND T.NewPrice > TMP.NewPriceValue ) 
 OR 
	 ( TMP.NewPriceOperator = 8 AND T.NewPrice >= TMP.NewPriceValue ) 
 OR 
	 ( TMP.NewPriceOperator = 9 AND T.NewPrice < TMP.NewPriceValue ) 
 OR 
	 ( TMP.NewPriceOperator = 10 AND T.NewPrice <= TMP.NewPriceValue ) 	 
	  
 ) 

 AND 

 ( 
	 ( TMP.OldQuantityOperator = -1 ) 
 OR 
	 ( TMP.OldQuantityOperator = 0 AND T.OldQuantity IS NULL ) 
 OR 
	 ( TMP.OldQuantityOperator = 1 AND T.OldQuantity IS NOT NULL ) 
 OR 
	 ( TMP.OldQuantityOperator = 2 AND T.OldQuantity = TMP.OldQuantityValue ) 
 OR 
	 ( TMP.OldQuantityOperator = 3 AND T.OldQuantity <> TMP.OldQuantityValue ) 
 OR 
	 ( TMP.OldQuantityOperator = 7 AND T.OldQuantity > TMP.OldQuantityValue ) 
 OR 
	 ( TMP.OldQuantityOperator = 8 AND T.OldQuantity >= TMP.OldQuantityValue ) 
 OR 
	 ( TMP.OldQuantityOperator = 9 AND T.OldQuantity < TMP.OldQuantityValue ) 
 OR 
	 ( TMP.OldQuantityOperator = 10 AND T.OldQuantity <= TMP.OldQuantityValue ) 

 ) 

 AND 

 ( 
	 ( TMP.NewQuantityOperator = -1 ) 
 OR 
	 ( TMP.NewQuantityOperator = 0 AND T.NewQuantity IS NULL ) 
 OR 
	 ( TMP.NewQuantityOperator = 1 AND T.NewQuantity IS NOT NULL ) 
 OR 
	 ( TMP.NewQuantityOperator = 2 AND T.NewQuantity = TMP.NewQuantityValue ) 
 OR 
	 ( TMP.NewQuantityOperator = 3 AND T.NewQuantity <> TMP.NewQuantityValue ) 
 OR 
	 ( TMP.NewQuantityOperator = 7 AND T.NewQuantity > TMP.NewQuantityValue ) 
 OR 
	 ( TMP.NewQuantityOperator = 8 AND T.NewQuantity >= TMP.NewQuantityValue ) 
 OR 
	 ( TMP.NewQuantityOperator = 9 AND T.NewQuantity < TMP.NewQuantityValue ) 
 OR 
	 ( TMP.NewQuantityOperator = 10 AND T.NewQuantity <= TMP.NewQuantityValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'ActivityType' AND @sortOrder = 'ASC'
	 THEN T.ActivityType END ASC, 
	 CASE WHEN @sortColumn = 'ActivityType' AND @sortOrder = 'DESC'
	 THEN T.ActivityType END DESC ,

	 CASE WHEN @sortColumn = 'ProductID' AND @sortOrder = 'ASC'
	 THEN T.ProductID END ASC, 
	 CASE WHEN @sortColumn = 'ProductID' AND @sortOrder = 'DESC'
	 THEN T.ProductID END DESC ,

	 CASE WHEN @sortColumn = 'ProductName' AND @sortOrder = 'ASC'
	 THEN T.ProductName END ASC, 
	 CASE WHEN @sortColumn = 'ProductName' AND @sortOrder = 'DESC'
	 THEN T.ProductName END DESC ,

	 CASE WHEN @sortColumn = 'RateTypeID' AND @sortOrder = 'ASC'
	 THEN T.RateTypeID END ASC, 
	 CASE WHEN @sortColumn = 'RateTypeID' AND @sortOrder = 'DESC'
	 THEN T.RateTypeID END DESC ,

	 CASE WHEN @sortColumn = 'RateTypeName' AND @sortOrder = 'ASC'
	 THEN T.RateTypeName END ASC, 
	 CASE WHEN @sortColumn = 'RateTypeName' AND @sortOrder = 'DESC'
	 THEN T.RateTypeName END DESC ,

	 CASE WHEN @sortColumn = 'OldPrice' AND @sortOrder = 'ASC'
	 THEN T.OldPrice END ASC, 
	 CASE WHEN @sortColumn = 'OldPrice' AND @sortOrder = 'DESC'
	 THEN T.OldPrice END DESC ,

	 CASE WHEN @sortColumn = 'NewPrice' AND @sortOrder = 'ASC'
	 THEN T.NewPrice END ASC, 
	 CASE WHEN @sortColumn = 'NewPrice' AND @sortOrder = 'DESC'
	 THEN T.NewPrice END DESC ,

	 CASE WHEN @sortColumn = 'OldQuantity' AND @sortOrder = 'ASC'
	 THEN T.OldQuantity END ASC, 
	 CASE WHEN @sortColumn = 'OldQuantity' AND @sortOrder = 'DESC'
	 THEN T.OldQuantity END DESC ,

	 CASE WHEN @sortColumn = 'NewQuantity' AND @sortOrder = 'ASC'
	 THEN T.NewQuantity END ASC, 
	 CASE WHEN @sortColumn = 'NewQuantity' AND @sortOrder = 'DESC'
	 THEN T.NewQuantity END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC 


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

DROP TABLE #tmpForWhereClause
END
