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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Transaction_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Location_Transaction_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dms_Vendor_Location_Transaction_List_Get] @VendorLocationID=11
 CREATE PROCEDURE [dbo].[dms_Vendor_Location_Transaction_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @VendorLocationID INT = NULL 
 ) 
 AS 
 SET FMTONLY OFF
 BEGIN 
  
 	SET NOCOUNT ON
	
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
TypeOperator="-1" 
NumberOperator="-1" 
DateOperator="-1" 
StatusOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
TypeOperator INT NOT NULL,
TypeValue nvarchar(100) NULL,
NumberOperator INT NOT NULL,
NumberValue nvarchar(100) NULL,
DateOperator INT NOT NULL,
DateValue datetime NULL,
StatusOperator INT NOT NULL,
StatusValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Type nvarchar(100)  NULL ,
	Number nvarchar(100)  NULL ,
	Date datetime  NULL ,
	Status nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Type nvarchar(100)  NULL ,
	Number nvarchar(100)  NULL ,
	Date datetime  NULL ,
	Status nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@TypeOperator','INT'),-1),
	T.c.value('@TypeValue','nvarchar(100)') ,
	ISNULL(T.c.value('@NumberOperator','INT'),-1),
	T.c.value('@NumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DateOperator','INT'),-1),
	T.c.value('@DateValue','datetime') ,
	ISNULL(T.c.value('@StatusOperator','INT'),-1),
	T.c.value('@StatusValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT		PO.ID
			, 'PO' AS [Type]
			, PO.PurchaseOrderNumber AS Number
			, PO.IssueDate AS [Date]
			, POS.Name AS [Status]
FROM		PurchaseOrder PO
JOIN		PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
WHERE		PO.VendorLocationID = @VendorLocationID
AND			PO.IsActive = 1

UNION

SELECT		VI.ID
			, 'Invoice' AS [Type]
			, VI.ID AS Number
			, VI.InvoiceDate AS [Date]
			, VIS.Name AS [Status]
FROM		VendorInvoice VI
JOIN		Vendor V ON V.ID = VI.VendorID
JOIN		VendorLocation VL ON VL.VendorID = V.ID
JOIN		VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID
WHERE		VL.ID = @VendorLocationID
AND			VI.IsActive = 1
AND			V.IsActive = 1
ORDER BY	Date DESC

INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.Type,
	T.Number,
	T.Date,
	T.Status
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
	 ( TMP.TypeOperator = -1 ) 
 OR 
	 ( TMP.TypeOperator = 0 AND T.Type IS NULL ) 
 OR 
	 ( TMP.TypeOperator = 1 AND T.Type IS NOT NULL ) 
 OR 
	 ( TMP.TypeOperator = 2 AND T.Type = TMP.TypeValue ) 
 OR 
	 ( TMP.TypeOperator = 3 AND T.Type <> TMP.TypeValue ) 
 OR 
	 ( TMP.TypeOperator = 4 AND T.Type LIKE TMP.TypeValue + '%') 
 OR 
	 ( TMP.TypeOperator = 5 AND T.Type LIKE '%' + TMP.TypeValue ) 
 OR 
	 ( TMP.TypeOperator = 6 AND T.Type LIKE '%' + TMP.TypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.NumberOperator = -1 ) 
 OR 
	 ( TMP.NumberOperator = 0 AND T.Number IS NULL ) 
 OR 
	 ( TMP.NumberOperator = 1 AND T.Number IS NOT NULL ) 
 OR 
	 ( TMP.NumberOperator = 2 AND T.Number = TMP.NumberValue ) 
 OR 
	 ( TMP.NumberOperator = 3 AND T.Number <> TMP.NumberValue ) 
 OR 
	 ( TMP.NumberOperator = 4 AND T.Number LIKE TMP.NumberValue + '%') 
 OR 
	 ( TMP.NumberOperator = 5 AND T.Number LIKE '%' + TMP.NumberValue ) 
 OR 
	 ( TMP.NumberOperator = 6 AND T.Number LIKE '%' + TMP.NumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DateOperator = -1 ) 
 OR 
	 ( TMP.DateOperator = 0 AND T.Date IS NULL ) 
 OR 
	 ( TMP.DateOperator = 1 AND T.Date IS NOT NULL ) 
 OR 
	 ( TMP.DateOperator = 2 AND T.Date = TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 3 AND T.Date <> TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 7 AND T.Date > TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 8 AND T.Date >= TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 9 AND T.Date < TMP.DateValue ) 
 OR 
	 ( TMP.DateOperator = 10 AND T.Date <= TMP.DateValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'Type' AND @sortOrder = 'ASC'
	 THEN T.Type END ASC, 
	 CASE WHEN @sortColumn = 'Type' AND @sortOrder = 'DESC'
	 THEN T.Type END DESC ,

	 CASE WHEN @sortColumn = 'Number' AND @sortOrder = 'ASC'
	 THEN T.Number END ASC, 
	 CASE WHEN @sortColumn = 'Number' AND @sortOrder = 'DESC'
	 THEN T.Number END DESC ,

	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'ASC'
	 THEN T.Date END ASC, 
	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'DESC'
	 THEN T.Date END DESC ,

	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'ASC'
	 THEN T.Status END ASC, 
	 CASE WHEN @sortColumn = 'Status' AND @sortOrder = 'DESC'
	 THEN T.Status END DESC 


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
