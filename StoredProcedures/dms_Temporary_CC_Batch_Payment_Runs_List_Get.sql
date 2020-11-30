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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Temporary_CC_Batch_Payment_Runs_List_Get] @BatchID = 169 , @GLAccountName='6300-310-00'
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_Payment_Runs_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @BatchID INT = NULL  
 , @GLAccountName nvarchar(11) = NULL
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
TemporaryCCIDOperator="-1" 
TemporaryCCNumberOperator="-1" 
CCIssueDateOperator="-1" 
CCIssueByOperator="-1" 
CCApproveOperator="-1" 
CCChargeOperator="-1" 
POIDOperator="-1" 
PONumberOperator="-1" 
POAmountOperator="-1" 
InvoiceIDOperator="-1" 
InvoiceNumberOperator="-1" 
InvoiceAmountOperator="-1" 
CreditCardIssueNumberOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
TemporaryCCIDOperator INT NOT NULL,
TemporaryCCIDValue int NULL,
TemporaryCCNumberOperator INT NOT NULL,
TemporaryCCNumberValue nvarchar(100) NULL,
CCIssueDateOperator INT NOT NULL,
CCIssueDateValue datetime NULL,
CCIssueByOperator INT NOT NULL,
CCIssueByValue nvarchar(100) NULL,
CCApproveOperator INT NOT NULL,
CCApproveValue money NULL,
CCChargeOperator INT NOT NULL,
CCChargeValue money NULL,
POIDOperator INT NOT NULL,
POIDValue int NULL,
PONumberOperator INT NOT NULL,
PONumberValue nvarchar(100) NULL,
POAmountOperator INT NOT NULL,
POAmountValue money NULL,
InvoiceIDOperator INT NOT NULL,
InvoiceIDValue int NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
InvoiceAmountOperator INT NOT NULL,
InvoiceAmountValue money NULL,
CreditCardIssueNumberOperator INT NOT NULL,
CreditCardIssueNumberValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL,
	CreditCardIssueNumber nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	TemporaryCCID int  NULL ,
	TemporaryCCNumber nvarchar(100)  NULL ,
	CCIssueDate datetime  NULL ,
	CCIssueBy nvarchar(100)  NULL ,
	CCApprove money  NULL ,
	CCCharge money  NULL ,
	POID int  NULL ,
	PONumber nvarchar(100)  NULL ,
	POAmount money  NULL ,
	InvoiceID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money  NULL ,
	CreditCardIssueNumber nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@TemporaryCCIDOperator','INT'),-1),
	T.c.value('@TemporaryCCIDValue','int') ,
	ISNULL(T.c.value('@TemporaryCCNumberOperator','INT'),-1),
	T.c.value('@TemporaryCCNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCIssueDateOperator','INT'),-1),
	T.c.value('@CCIssueDateValue','datetime') ,
	ISNULL(T.c.value('@CCIssueByOperator','INT'),-1),
	T.c.value('@CCIssueByValue','nvarchar(100)') ,
	ISNULL(T.c.value('@CCApproveOperator','INT'),-1),
	T.c.value('@CCApproveValue','money') ,
	ISNULL(T.c.value('@CCChargeOperator','INT'),-1),
	T.c.value('@CCChargeValue','money') ,
	ISNULL(T.c.value('@POIDOperator','INT'),-1),
	T.c.value('@POIDValue','int') ,
	ISNULL(T.c.value('@PONumberOperator','INT'),-1),
	T.c.value('@PONumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@POAmountOperator','INT'),-1),
	T.c.value('@POAmountValue','money') ,
	ISNULL(T.c.value('@InvoiceIDOperator','INT'),-1),
	T.c.value('@InvoiceIDValue','int') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@InvoiceAmountOperator','INT'),-1),
	T.c.value('@InvoiceAmountValue','money') ,
	ISNULL(T.c.value('@CreditCardIssueNumberOperator','INT'),-1),
	T.c.value('@CreditCardIssueNumberValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT 
  TCC.ID AS TemporaryCCID
, TCC.CreditCardNumber AS TemporaryCCNumber
, TCC.IssueDate AS CCIssueDate
, TCC.IssueBy AS CCIssueBy
, TCC.ApprovedAmount AS CCApprove
, TCC.TotalChargedAmount AS CCCharge
, PO.ID AS POID
, PO.PurchaseOrderNumber AS PONumber
, PO.PurchaseOrderAmount AS POAmount 
, VI.ID AS InvoiceID
, VI.InvoiceNumber AS InvoiceNumber
, VI.InvoiceAmount AS InvoiceAmount
, TCC.CreditCardIssueNumber AS CreditCardIssueNumber
FROM	TemporaryCreditCard TCC
LEFT JOIN	PurchaseOrder PO ON PO.PurchaseOrderNumber = TCC.ReferencePurchaseOrderNumber
LEFT JOIN   VendorInvoice VI ON VI.PurchaseOrderID = PO.ID
WHERE TCC.PostingBatchID = @BatchID AND VI.GLExpenseAccount = @GLAccountName

INSERT INTO #FinalResults
SELECT 
	T.TemporaryCCID,
	T.TemporaryCCNumber,
	T.CCIssueDate,
	T.CCIssueBy,
	T.CCApprove,
	T.CCCharge,
	T.POID,
	T.PONumber,
	T.POAmount,
	T.InvoiceID,
	T.InvoiceNumber,
	T.InvoiceAmount,
	T.CreditCardIssueNumber
FROM #tmpFinalResults T,
#tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.TemporaryCCIDOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 0 AND T.TemporaryCCID IS NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 1 AND T.TemporaryCCID IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 2 AND T.TemporaryCCID = TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 3 AND T.TemporaryCCID <> TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 7 AND T.TemporaryCCID > TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 8 AND T.TemporaryCCID >= TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 9 AND T.TemporaryCCID < TMP.TemporaryCCIDValue ) 
 OR 
	 ( TMP.TemporaryCCIDOperator = 10 AND T.TemporaryCCID <= TMP.TemporaryCCIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.TemporaryCCNumberOperator = -1 ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 0 AND T.TemporaryCCNumber IS NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 1 AND T.TemporaryCCNumber IS NOT NULL ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 2 AND T.TemporaryCCNumber = TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 3 AND T.TemporaryCCNumber <> TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 4 AND T.TemporaryCCNumber LIKE TMP.TemporaryCCNumberValue + '%') 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 5 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue ) 
 OR 
	 ( TMP.TemporaryCCNumberOperator = 6 AND T.TemporaryCCNumber LIKE '%' + TMP.TemporaryCCNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCIssueDateOperator = -1 ) 
 OR 
	 ( TMP.CCIssueDateOperator = 0 AND T.CCIssueDate IS NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 1 AND T.CCIssueDate IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueDateOperator = 2 AND T.CCIssueDate = TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 3 AND T.CCIssueDate <> TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 7 AND T.CCIssueDate > TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 8 AND T.CCIssueDate >= TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 9 AND T.CCIssueDate < TMP.CCIssueDateValue ) 
 OR 
	 ( TMP.CCIssueDateOperator = 10 AND T.CCIssueDate <= TMP.CCIssueDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCIssueByOperator = -1 ) 
 OR 
	 ( TMP.CCIssueByOperator = 0 AND T.CCIssueBy IS NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 1 AND T.CCIssueBy IS NOT NULL ) 
 OR 
	 ( TMP.CCIssueByOperator = 2 AND T.CCIssueBy = TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 3 AND T.CCIssueBy <> TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 4 AND T.CCIssueBy LIKE TMP.CCIssueByValue + '%') 
 OR 
	 ( TMP.CCIssueByOperator = 5 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue ) 
 OR 
	 ( TMP.CCIssueByOperator = 6 AND T.CCIssueBy LIKE '%' + TMP.CCIssueByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CCApproveOperator = -1 ) 
 OR 
	 ( TMP.CCApproveOperator = 0 AND T.CCApprove IS NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 1 AND T.CCApprove IS NOT NULL ) 
 OR 
	 ( TMP.CCApproveOperator = 2 AND T.CCApprove = TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 3 AND T.CCApprove <> TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 7 AND T.CCApprove > TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 8 AND T.CCApprove >= TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 9 AND T.CCApprove < TMP.CCApproveValue ) 
 OR 
	 ( TMP.CCApproveOperator = 10 AND T.CCApprove <= TMP.CCApproveValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CCChargeOperator = -1 ) 
 OR 
	 ( TMP.CCChargeOperator = 0 AND T.CCCharge IS NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 1 AND T.CCCharge IS NOT NULL ) 
 OR 
	 ( TMP.CCChargeOperator = 2 AND T.CCCharge = TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 3 AND T.CCCharge <> TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 7 AND T.CCCharge > TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 8 AND T.CCCharge >= TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 9 AND T.CCCharge < TMP.CCChargeValue ) 
 OR 
	 ( TMP.CCChargeOperator = 10 AND T.CCCharge <= TMP.CCChargeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.POIDOperator = -1 ) 
 OR 
	 ( TMP.POIDOperator = 0 AND T.POID IS NULL ) 
 OR 
	 ( TMP.POIDOperator = 1 AND T.POID IS NOT NULL ) 
 OR 
	 ( TMP.POIDOperator = 2 AND T.POID = TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 3 AND T.POID <> TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 7 AND T.POID > TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 8 AND T.POID >= TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 9 AND T.POID < TMP.POIDValue ) 
 OR 
	 ( TMP.POIDOperator = 10 AND T.POID <= TMP.POIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.PONumberOperator = -1 ) 
 OR 
	 ( TMP.PONumberOperator = 0 AND T.PONumber IS NULL ) 
 OR 
	 ( TMP.PONumberOperator = 1 AND T.PONumber IS NOT NULL ) 
 OR 
	 ( TMP.PONumberOperator = 2 AND T.PONumber = TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 3 AND T.PONumber <> TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 4 AND T.PONumber LIKE TMP.PONumberValue + '%') 
 OR 
	 ( TMP.PONumberOperator = 5 AND T.PONumber LIKE '%' + TMP.PONumberValue ) 
 OR 
	 ( TMP.PONumberOperator = 6 AND T.PONumber LIKE '%' + TMP.PONumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.POAmountOperator = -1 ) 
 OR 
	 ( TMP.POAmountOperator = 0 AND T.POAmount IS NULL ) 
 OR 
	 ( TMP.POAmountOperator = 1 AND T.POAmount IS NOT NULL ) 
 OR 
	 ( TMP.POAmountOperator = 2 AND T.POAmount = TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 3 AND T.POAmount <> TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 7 AND T.POAmount > TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 8 AND T.POAmount >= TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 9 AND T.POAmount < TMP.POAmountValue ) 
 OR 
	 ( TMP.POAmountOperator = 10 AND T.POAmount <= TMP.POAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.InvoiceIDOperator = -1 ) 
 OR 
	 ( TMP.InvoiceIDOperator = 0 AND T.InvoiceID IS NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 1 AND T.InvoiceID IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceIDOperator = 2 AND T.InvoiceID = TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 3 AND T.InvoiceID <> TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 7 AND T.InvoiceID > TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 8 AND T.InvoiceID >= TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 9 AND T.InvoiceID < TMP.InvoiceIDValue ) 
 OR 
	 ( TMP.InvoiceIDOperator = 10 AND T.InvoiceID <= TMP.InvoiceIDValue ) 

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
	 ( TMP.InvoiceAmountOperator = -1 ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 0 AND T.InvoiceAmount IS NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 1 AND T.InvoiceAmount IS NOT NULL ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 2 AND T.InvoiceAmount = TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 3 AND T.InvoiceAmount <> TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 7 AND T.InvoiceAmount > TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 8 AND T.InvoiceAmount >= TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 9 AND T.InvoiceAmount < TMP.InvoiceAmountValue ) 
 OR 
	 ( TMP.InvoiceAmountOperator = 10 AND T.InvoiceAmount <= TMP.InvoiceAmountValue ) 

 ) 



 AND 
 
 ( 
	 ( TMP.CreditCardIssueNumberOperator = -1 ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 0 AND T.CreditCardIssueNumber IS NULL ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 1 AND T.CreditCardIssueNumber IS NOT NULL ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 2 AND T.CreditCardIssueNumber = TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 3 AND T.CreditCardIssueNumber <> TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 4 AND T.CreditCardIssueNumber LIKE TMP.CreditCardIssueNumberValue + '%') 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 5 AND T.CreditCardIssueNumber LIKE '%' + TMP.CreditCardIssueNumberValue ) 
 OR 
	 ( TMP.CreditCardIssueNumberOperator = 6 AND T.CreditCardIssueNumber LIKE '%' + TMP.CreditCardIssueNumberValue + '%' ) 
 ) 

 AND 
 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCID END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCID' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCID END DESC ,

	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'ASC'
	 THEN T.TemporaryCCNumber END ASC, 
	 CASE WHEN @sortColumn = 'TemporaryCCNumber' AND @sortOrder = 'DESC'
	 THEN T.TemporaryCCNumber END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'ASC'
	 THEN T.CCIssueDate END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueDate' AND @sortOrder = 'DESC'
	 THEN T.CCIssueDate END DESC ,

	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'ASC'
	 THEN T.CCIssueBy END ASC, 
	 CASE WHEN @sortColumn = 'CCIssueBy' AND @sortOrder = 'DESC'
	 THEN T.CCIssueBy END DESC ,

	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'ASC'
	 THEN T.CCApprove END ASC, 
	 CASE WHEN @sortColumn = 'CCApprove' AND @sortOrder = 'DESC'
	 THEN T.CCApprove END DESC ,

	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'ASC'
	 THEN T.CCCharge END ASC, 
	 CASE WHEN @sortColumn = 'CCCharge' AND @sortOrder = 'DESC'
	 THEN T.CCCharge END DESC ,

	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'ASC'
	 THEN T.POID END ASC, 
	 CASE WHEN @sortColumn = 'POID' AND @sortOrder = 'DESC'
	 THEN T.POID END DESC ,

	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'ASC'
	 THEN T.PONumber END ASC, 
	 CASE WHEN @sortColumn = 'PONumber' AND @sortOrder = 'DESC'
	 THEN T.PONumber END DESC ,

	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'ASC'
	 THEN T.POAmount END ASC, 
	 CASE WHEN @sortColumn = 'POAmount' AND @sortOrder = 'DESC'
	 THEN T.POAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC ,
	 
	 CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'
	 THEN T.CreditCardIssueNumber END ASC, 
	 CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'
	 THEN T.CreditCardIssueNumber END DESC 


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
