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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Service_Ratings_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Service_Ratings_List_Get] 
 END 
 GO   
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Vendor_Portal_Service_Ratings_List_Get] @VendorID=190,@ProductCategoryID=5
 CREATE PROCEDURE [dbo].[dms_Vendor_Portal_Service_Ratings_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 100  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT = NULL
 , @VendorLocationID INT = NULL
 , @ProductCategoryID INT = NULL
 ) 
 AS 
 BEGIN 
  SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
VendorIDOperator="-1" 
VendorLocationIDOperator="-1" 
ProductCategoryNameOperator="-1" 
ProductNameOperator="-1" 
ProductRatingOperator="-1" 
ServiceRequestIDOperator="-1" 
PurchaseOrderNumberOperator="-1" 
ContactActionOperator="-1" 
VendorServiceRatingAdjustmentOperator="-1" 
TalkedToOperator="-1" 
CreateDateOperator="-1" 
ContactLogIDOperator="-1" 
PCSequenceOperator="-1" 
VCSequenceOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
VendorIDOperator INT NOT NULL,
VendorIDValue int NULL,
VendorLocationIDOperator INT NOT NULL,
VendorLocationIDValue int NULL,
ProductCategoryNameOperator INT NOT NULL,
ProductCategoryNameValue nvarchar(100) NULL,
ProductNameOperator INT NOT NULL,
ProductNameValue nvarchar(100) NULL,
ProductRatingOperator INT NOT NULL,
ProductRatingValue decimal NULL,
ServiceRequestIDOperator INT NOT NULL,
ServiceRequestIDValue int NULL,
PurchaseOrderNumberOperator INT NOT NULL,
PurchaseOrderNumberValue nvarchar(100) NULL,
ContactActionOperator INT NOT NULL,
ContactActionValue nvarchar(100) NULL,
VendorServiceRatingAdjustmentOperator INT NOT NULL,
VendorServiceRatingAdjustmentValue decimal NULL,
TalkedToOperator INT NOT NULL,
TalkedToValue nvarchar(100) NULL,
CreateDateOperator INT NOT NULL,
CreateDateValue datetime NULL,
ContactLogIDOperator INT NOT NULL,
ContactLogIDValue int NULL,
PCSequenceOperator INT NOT NULL,
PCSequenceValue int NULL,
VCSequenceOperator INT NOT NULL,
VCSequenceValue int NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorID int  NULL ,	
	ProductID INT NULL,
	ProductCategoryName nvarchar(100)  NULL ,
	ProductName nvarchar(100)  NULL ,
	ProductRating decimal  NULL ,
	CreateDate datetime  NULL
	
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorID int  NULL ,
	ProductID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	ProductName nvarchar(100)  NULL ,
	ProductRating decimal  NULL ,	
	CreateDate datetime  NULL	
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@VendorIDOperator','INT'),-1),
	T.c.value('@VendorIDValue','int') ,
	ISNULL(T.c.value('@VendorLocationIDOperator','INT'),-1),
	T.c.value('@VendorLocationIDValue','int') ,
	ISNULL(T.c.value('@ProductCategoryNameOperator','INT'),-1),
	T.c.value('@ProductCategoryNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductNameOperator','INT'),-1),
	T.c.value('@ProductNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ProductRatingOperator','INT'),-1),
	T.c.value('@ProductRatingValue','decimal') ,
	ISNULL(T.c.value('@ServiceRequestIDOperator','INT'),-1),
	T.c.value('@ServiceRequestIDValue','int') ,
	ISNULL(T.c.value('@PurchaseOrderNumberOperator','INT'),-1),
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@ContactActionOperator','INT'),-1),
	T.c.value('@ContactActionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VendorServiceRatingAdjustmentOperator','INT'),-1),
	T.c.value('@VendorServiceRatingAdjustmentValue','decimal') ,
	ISNULL(T.c.value('@TalkedToOperator','INT'),-1),
	T.c.value('@TalkedToValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CreateDateOperator','INT'),-1),
	T.c.value('@CreateDateValue','datetime') ,
	ISNULL(T.c.value('@ContactLogIDOperator','INT'),-1),
	T.c.value('@ContactLogIDValue','int') ,
	ISNULL(T.c.value('@PCSequenceOperator','INT'),-1),
	T.c.value('@PCSequenceValue','int') ,
	ISNULL(T.c.value('@VCSequenceOperator','INT'),-1),
	T.c.value('@VCSequenceValue','int') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
Select DISTINCT
      v.ID VendorID
      ,p.ID AS ProductID      
      ,pc.Name ProductCategoryName
      ,p.Name ProductName
      ,MAX(ISNULL(vlp.Rating,0)) AS ProductRating
      ,MAX(VendorContactLog.CreateDate)      
FROM Vendor v
JOIN VendorLocation vl ON v.ID = vl.VendorID
JOIN VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1
JOIN Product p ON p.ID = vlp.ProductID
JOIN ProductCategory pc ON pc.ID = p.ProductCategoryID
LEFT OUTER JOIN VehicleCategory vc ON vc.ID = p.VehicleCategoryID
LEFT OUTER JOIN dbo.fnc_GetVendorLocationProduct_ContactLog() VendorContactLog ON VendorContactLog.VendorLocationID = vl.ID AND VendorContactLog.ProductID = vlp.ProductID
WHERE
v.id = @VendorID
AND pc.ID= @ProductCategoryID
AND (@VendorLocationID IS NULL OR vl.id = @VendorLocationID)
AND p.ProductTypeID = (SELECT ID FROM ProductType WHERE Name = 'Service') 
AND p.ProductSubTypeID IN (SELECT ID FROM ProductSubType WHERE Name IN ('PrimaryService','SecondaryService'))
AND p.IsShowOnPO = 1
GROUP BY v.ID,p.ID,pc.Name,p.Name


INSERT INTO #FinalResults
SELECT 
	T.VendorID,
	T.ProductID,
	T.ProductCategoryName,
	T.ProductName,
	T.ProductRating,	
	T.CreateDate
	
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.VendorIDOperator = -1 ) 
 OR 
	 ( TMP.VendorIDOperator = 0 AND T.VendorID IS NULL ) 
 OR 
	 ( TMP.VendorIDOperator = 1 AND T.VendorID IS NOT NULL ) 
 OR 
	 ( TMP.VendorIDOperator = 2 AND T.VendorID = TMP.VendorIDValue ) 
 OR 
	 ( TMP.VendorIDOperator = 3 AND T.VendorID <> TMP.VendorIDValue ) 
 OR 
	 ( TMP.VendorIDOperator = 7 AND T.VendorID > TMP.VendorIDValue ) 
 OR 
	 ( TMP.VendorIDOperator = 8 AND T.VendorID >= TMP.VendorIDValue ) 
 OR 
	 ( TMP.VendorIDOperator = 9 AND T.VendorID < TMP.VendorIDValue ) 
 OR 
	 ( TMP.VendorIDOperator = 10 AND T.VendorID <= TMP.VendorIDValue ) 

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
	 ( TMP.ProductRatingOperator = -1 ) 
 OR 
	 ( TMP.ProductRatingOperator = 0 AND T.ProductRating IS NULL ) 
 OR 
	 ( TMP.ProductRatingOperator = 1 AND T.ProductRating IS NOT NULL ) 
 OR 
	 ( TMP.ProductRatingOperator = 2 AND T.ProductRating = TMP.ProductRatingValue ) 
 OR 
	 ( TMP.ProductRatingOperator = 3 AND T.ProductRating <> TMP.ProductRatingValue ) 
 OR 
	 ( TMP.ProductRatingOperator = 7 AND T.ProductRating > TMP.ProductRatingValue ) 
 OR 
	 ( TMP.ProductRatingOperator = 8 AND T.ProductRating >= TMP.ProductRatingValue ) 
 OR 
	 ( TMP.ProductRatingOperator = 9 AND T.ProductRating < TMP.ProductRatingValue ) 
 OR 
	 ( TMP.ProductRatingOperator = 10 AND T.ProductRating <= TMP.ProductRatingValue ) 

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
	 CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'ASC'
	 THEN T.VendorID END ASC, 
	 CASE WHEN @sortColumn = 'VendorID' AND @sortOrder = 'DESC'
	 THEN T.VendorID END DESC ,

	 CASE WHEN @sortColumn = 'ProductCategoryName' AND @sortOrder = 'ASC'
	 THEN T.ProductCategoryName END ASC, 
	 CASE WHEN @sortColumn = 'ProductCategoryName' AND @sortOrder = 'DESC'
	 THEN T.ProductCategoryName END DESC ,

	 CASE WHEN @sortColumn = 'ProductName' AND @sortOrder = 'ASC'
	 THEN T.ProductName END ASC, 
	 CASE WHEN @sortColumn = 'ProductName' AND @sortOrder = 'DESC'
	 THEN T.ProductName END DESC ,

	 CASE WHEN @sortColumn = 'ProductRating' AND @sortOrder = 'ASC'
	 THEN T.ProductRating END ASC, 
	 CASE WHEN @sortColumn = 'ProductRating' AND @sortOrder = 'DESC'
	 THEN T.ProductRating END DESC ,

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
