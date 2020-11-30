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
 WHERE id = object_id(N'[dbo].[dms_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Batch_Payment_Runs_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC dms_Batch_Payment_Runs_List_Get @BatchID=90
 CREATE PROCEDURE [dbo].[dms_Batch_Payment_Runs_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @BatchID INT = NULL 
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF;
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
VendorInvoiceIDOperator="-1" 
VendorNumberOperator="-1" 
VendorNameOperator="-1" 
PurchaseOrderNumberOperator="-1" 
InvoiceNumberOperator="-1" 
InvoiceDateOperator="-1" 
PayMethodOperator="-1" 
PaymentDateOperator="-1" 
PaymentAmountOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
VendorInvoiceIDOperator INT NOT NULL,
VendorInvoiceIDValue int NULL,
VendorNumberOperator INT NOT NULL,
VendorNumberValue nvarchar(100) NULL,
VendorNameOperator INT NOT NULL,
VendorNameValue nvarchar(100) NULL,
PurchaseOrderNumberOperator INT NOT NULL,
PurchaseOrderNumberValue nvarchar(100) NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
InvoiceDateOperator INT NOT NULL,
InvoiceDateValue datetime NULL,
PayMethodOperator INT NOT NULL,
PayMethodValue nvarchar(100) NULL,
PaymentDateOperator INT NOT NULL,
PaymentDateValue datetime NULL,
PaymentAmountOperator INT NOT NULL,
PaymentAmountValue money NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorInvoiceID int  NULL ,
	VendorNumber nvarchar(100)  NULL ,
	VendorName nvarchar(100)  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceDate datetime  NULL ,
	PayMethod nvarchar(100)  NULL ,
	PaymentDate datetime  NULL ,
	PaymentAmount money  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	VendorInvoiceID int  NULL ,
	VendorNumber nvarchar(100)  NULL ,
	VendorName nvarchar(100)  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceDate datetime  NULL ,
	PayMethod nvarchar(100)  NULL ,
	PaymentDate datetime  NULL ,
	PaymentAmount money  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@VendorInvoiceIDOperator','INT'),-1),
	T.c.value('@VendorInvoiceIDValue','int') ,
	ISNULL(T.c.value('@VendorNumberOperator','INT'),-1),
	T.c.value('@VendorNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@VendorNameOperator','INT'),-1),
	T.c.value('@VendorNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PurchaseOrderNumberOperator','INT'),-1),
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceDateOperator','INT'),-1),
	T.c.value('@InvoiceDateValue','datetime') ,
	ISNULL(T.c.value('@PayMethodOperator','INT'),-1),
	T.c.value('@PayMethodValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PaymentDateOperator','INT'),-1),
	T.c.value('@PaymentDateValue','datetime') ,
	ISNULL(T.c.value('@PaymentAmountOperator','INT'),-1),
	T.c.value('@PaymentAmountValue','money') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT	VI.ID AS VendorInvoiceID
		, V.VendorNumber
		, V.Name AS [VendorName]
		, PO.PurchaseOrderNumber
		, VI.InvoiceNumber
		, VI.InvoiceDate
		, CASE 
			WHEN PT.Name = 'Check' THEN 'CK ' + COALESCE(VI.PaymentNumber,'')
			ELSE 'ACH'
			END AS [PayMethod]
		, VI.PaymentDate
		, VI.PaymentAmount
FROM	Batch B
JOIN	BatchType BT WITH(NOLOCK) ON BT.ID = B.BatchTypeID
JOIN	VendorInvoice VI WITH(NOLOCK) ON VI.ExportBatchID = B.ID
JOIN	Vendor V WITH(NOLOCK) ON V.ID = VI.VendorID
JOIN	PurchaseOrder PO WITH(NOLOCK) ON PO.ID = VI.PurchaseOrderID
LEFT JOIN	PaymentType PT WITH(NOLOCK) ON PT.ID = VI.PaymentTypeID
WHERE B.ID=@BatchID
ORDER BY B.CreateDate DESC


INSERT INTO #FinalResults
SELECT 
	T.VendorInvoiceID,
	T.VendorNumber,
	T.VendorName,
	T.PurchaseOrderNumber,
	T.InvoiceNumber,
	T.InvoiceDate,
	T.PayMethod,
	T.PaymentDate,
	T.PaymentAmount
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.VendorInvoiceIDOperator = -1 ) 
 OR 
	 ( TMP.VendorInvoiceIDOperator = 0 AND T.VendorInvoiceID IS NULL ) 
 OR 
	 ( TMP.VendorInvoiceIDOperator = 1 AND T.VendorInvoiceID IS NOT NULL ) 
 OR 
	 ( TMP.VendorInvoiceIDOperator = 2 AND T.VendorInvoiceID = TMP.VendorInvoiceIDValue ) 
 OR 
	 ( TMP.VendorInvoiceIDOperator = 3 AND T.VendorInvoiceID <> TMP.VendorInvoiceIDValue ) 
 OR 
	 ( TMP.VendorInvoiceIDOperator = 7 AND T.VendorInvoiceID > TMP.VendorInvoiceIDValue ) 
 OR 
	 ( TMP.VendorInvoiceIDOperator = 8 AND T.VendorInvoiceID >= TMP.VendorInvoiceIDValue ) 
 OR 
	 ( TMP.VendorInvoiceIDOperator = 9 AND T.VendorInvoiceID < TMP.VendorInvoiceIDValue ) 
 OR 
	 ( TMP.VendorInvoiceIDOperator = 10 AND T.VendorInvoiceID <= TMP.VendorInvoiceIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.VendorNumberOperator = -1 ) 
 OR 
	 ( TMP.VendorNumberOperator = 0 AND T.VendorNumber IS NULL ) 
 OR 
	 ( TMP.VendorNumberOperator = 1 AND T.VendorNumber IS NOT NULL ) 
 OR 
	 ( TMP.VendorNumberOperator = 2 AND T.VendorNumber = TMP.VendorNumberValue ) 
 OR 
	 ( TMP.VendorNumberOperator = 3 AND T.VendorNumber <> TMP.VendorNumberValue ) 
 OR 
	 ( TMP.VendorNumberOperator = 4 AND T.VendorNumber LIKE TMP.VendorNumberValue + '%') 
 OR 
	 ( TMP.VendorNumberOperator = 5 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue ) 
 OR 
	 ( TMP.VendorNumberOperator = 6 AND T.VendorNumber LIKE '%' + TMP.VendorNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.VendorNameOperator = -1 ) 
 OR 
	 ( TMP.VendorNameOperator = 0 AND T.VendorName IS NULL ) 
 OR 
	 ( TMP.VendorNameOperator = 1 AND T.VendorName IS NOT NULL ) 
 OR 
	 ( TMP.VendorNameOperator = 2 AND T.VendorName = TMP.VendorNameValue ) 
 OR 
	 ( TMP.VendorNameOperator = 3 AND T.VendorName <> TMP.VendorNameValue ) 
 OR 
	 ( TMP.VendorNameOperator = 4 AND T.VendorName LIKE TMP.VendorNameValue + '%') 
 OR 
	 ( TMP.VendorNameOperator = 5 AND T.VendorName LIKE '%' + TMP.VendorNameValue ) 
 OR 
	 ( TMP.VendorNameOperator = 6 AND T.VendorName LIKE '%' + TMP.VendorNameValue + '%' ) 
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
	 ( TMP.PayMethodOperator = -1 ) 
 OR 
	 ( TMP.PayMethodOperator = 0 AND T.PayMethod IS NULL ) 
 OR 
	 ( TMP.PayMethodOperator = 1 AND T.PayMethod IS NOT NULL ) 
 OR 
	 ( TMP.PayMethodOperator = 2 AND T.PayMethod = TMP.PayMethodValue ) 
 OR 
	 ( TMP.PayMethodOperator = 3 AND T.PayMethod <> TMP.PayMethodValue ) 
 OR 
	 ( TMP.PayMethodOperator = 4 AND T.PayMethod LIKE TMP.PayMethodValue + '%') 
 OR 
	 ( TMP.PayMethodOperator = 5 AND T.PayMethod LIKE '%' + TMP.PayMethodValue ) 
 OR 
	 ( TMP.PayMethodOperator = 6 AND T.PayMethod LIKE '%' + TMP.PayMethodValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PaymentDateOperator = -1 ) 
 OR 
	 ( TMP.PaymentDateOperator = 0 AND T.PaymentDate IS NULL ) 
 OR 
	 ( TMP.PaymentDateOperator = 1 AND T.PaymentDate IS NOT NULL ) 
 OR 
	 ( TMP.PaymentDateOperator = 2 AND T.PaymentDate = TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 3 AND T.PaymentDate <> TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 7 AND T.PaymentDate > TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 8 AND T.PaymentDate >= TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 9 AND T.PaymentDate < TMP.PaymentDateValue ) 
 OR 
	 ( TMP.PaymentDateOperator = 10 AND T.PaymentDate <= TMP.PaymentDateValue ) 

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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'VendorInvoiceID' AND @sortOrder = 'ASC'
	 THEN T.VendorInvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'VendorInvoiceID' AND @sortOrder = 'DESC'
	 THEN T.VendorInvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'ASC'
	 THEN T.VendorNumber END ASC, 
	 CASE WHEN @sortColumn = 'VendorNumber' AND @sortOrder = 'DESC'
	 THEN T.VendorNumber END DESC ,

	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'ASC'
	 THEN T.VendorName END ASC, 
	 CASE WHEN @sortColumn = 'VendorName' AND @sortOrder = 'DESC'
	 THEN T.VendorName END DESC ,

	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderNumber END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'PayMethod' AND @sortOrder = 'ASC'
	 THEN T.PayMethod END ASC, 
	 CASE WHEN @sortColumn = 'PayMethod' AND @sortOrder = 'DESC'
	 THEN T.PayMethod END DESC ,

	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'ASC'
	 THEN T.PaymentDate END ASC, 
	 CASE WHEN @sortColumn = 'PaymentDate' AND @sortOrder = 'DESC'
	 THEN T.PaymentDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC 


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
