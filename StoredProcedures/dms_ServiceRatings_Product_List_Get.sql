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
 WHERE id = object_id(N'[dbo].[dms_ServiceRatings_Product_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ServiceRatings_Product_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_ServiceRatings_Product_List_Get] @VendorID=190 
 CREATE PROCEDURE [dbo].[dms_ServiceRatings_Product_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
ProductCategoryNameOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
ProductCategoryNameOperator INT NOT NULL,
ProductCategoryNameValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProductCategoryID int  NULL ,
	VendorID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	AvgProductRating decimal  NULL 
) 
CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ProductCategoryID int  NULL ,
	VendorID int  NULL ,
	ProductCategoryName nvarchar(100)  NULL ,
	AvgProductRating decimal  NULL 
) 
INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@ProductCategoryNameOperator','INT'),-1),
	T.c.value('@ProductCategoryNameValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT
	 pc.ID AS ProductCategoryID
	,v.ID AS VendorID
    ,pc.Name ProductCategoryName
	,ROUND(AVG(vlp.Rating),0) AvgProductRating
FROM Vendor v
JOIN VendorLocation vl ON v.ID = vl.VendorID
JOIN VendorLocationProduct vlp ON vl.ID = vlp.VendorLocationID AND vlp.IsActive = 1
JOIN Product p ON p.ID = vlp.ProductID
JOIN ProductCategory pc ON pc.ID = p.ProductCategoryID
WHERE
            v.id = @VendorID
GROUP BY
            v.VendorNumber
            ,v.ID
            ,pc.Name
            ,pc.ID


INSERT INTO #FinalResults
SELECT 
	T.ProductCategoryID,
	T.VendorID,
	T.ProductCategoryName,
	T.AvgProductRating
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

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
 1 = 1 
 ) 

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
