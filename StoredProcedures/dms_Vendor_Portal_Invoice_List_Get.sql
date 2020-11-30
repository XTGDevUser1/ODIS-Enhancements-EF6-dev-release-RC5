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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Portal_Invoice_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Portal_Invoice_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC   [dbo].[dms_Vendor_Portal_Invoice_List_Get] @vendorID = 66905, @whereClauseXML = '<ROW><Filter PurchaseOrderNumberValue="7770395"/></ROW>' 
 CREATE PROCEDURE [dbo].[dms_Vendor_Portal_Invoice_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'IssueDate' 
 , @sortOrder nvarchar(100) = 'DESC'
 , @VendorID INT = NULL 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 

 ></Filter></ROW>'
END

SET FMTONLY OFF;

CREATE TABLE #tmpForWhereClause
(

PurchaseOrderNumberValue nvarchar(100) NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)

CREATE TABLE #tmpFinalResults( 	
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Service nvarchar(100)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money NULL,
	InvoiceDate datetime  NULL ,
	ToBePaidDate datetime  NULL ,
	PaymentType nvarchar(100)  NULL ,
	ReceivedDate datetime NULL,
	SubmitMethod nvarchar(100) NULL,
	DocumentID INT NULL,
	DocumentName nvarchar(255) NULL
) 

 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PurchaseOrderNumber nvarchar(100)  NULL ,
	IssueDate datetime  NULL ,
	Service nvarchar(100)  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	InvoiceAmount money NULL,
	InvoiceDate datetime  NULL ,
	ToBePaidDate datetime  NULL ,
	PaymentType nvarchar(100)  NULL ,
	ReceivedDate datetime NULL,
	SubmitMethod nvarchar(100) NULL,
	DocumentID INT NULL,
	DocumentName nvarchar(255) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	
	T.c.value('@PurchaseOrderNumberValue','nvarchar(100)'),
	T.c.value('@FromDate','datetime') ,
	T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @poNumber NVARCHAR(100) = NULL,
		@fromDate DATETIME = NULL,
		@toDate DATETIME = NULL
		
SELECT	@poNumber = PurchaseOrderNumberValue, 
		@fromDate = FromDate,
		@toDate = ToDate
FROM	#tmpForWhereClause


IF @toDate IS NOT NULL
BEGIN
	SET @toDate = DATEADD(DD,1,@toDate)
END

IF @fromDate IS NULL AND @toDate IS NULL
BEGIN
	--SET @fromDate = DATEADD(DD,-30,GETDATE())
	SET @toDate = DATEADD(DD,1,GETDATE())
END


--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT	VI.ID
		, PO.PurchaseOrderNumber
		, PO.IssueDate
		, P.Name AS Service
		, VI.InvoiceNumber
		, VI.InvoiceAmount
		, VI.InvoiceDate		
		, VI.PaymentDate
		, PT.Name AS PaymentType
		, VI.ReceivedDate 
		, CM.Name AS SubmitMethod
		, D.ID AS DocumentID
		, D.Name AS DocumentName
FROM	PurchaseOrder PO
JOIN	PurchaseOrderStatus POS ON POS.ID = PO.PurchaseOrderStatusID
JOIN	Product P ON P.ID = PO.ProductID
JOIN	VendorLocation VL ON VL.ID = PO.VendorLocationID 
JOIN	Vendor V ON V.ID = VL.VendorID 
LEFT JOIN VendorInvoice VI ON VI.PurchaseOrderID = PO.ID 
LEFT JOIN VendorInvoiceStatus VIS ON VIS.ID = VI.VendorInvoiceStatusID
LEFT JOIN PaymentType PT ON PT.ID = VI.PaymentTypeID
LEFT JOIN ContactMethod CM ON CM.ID = VI.ReceiveContactMethodID
LEFT JOIN Document D ON D.RecordID = VI.ID AND D.EntityID = (Select ID from Entity where Name='VendorInvoice') AND D.ISActive = 1
WHERE	VI.VendorID = @VendorID
AND		(@poNumber IS NULL OR @poNumber = PO.PurchaseOrderNumber)
AND		(@fromDate IS NULL OR PO.IssueDate >= @fromDate)
AND		(@toDate IS NULL OR PO.IssueDate <= @toDate)
AND		(VI.ID IS NOT NULL OR DATEDIFF(dd,PO.IssueDate,getdate())<=89) 


INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.PurchaseOrderNumber,
	T.IssueDate,
	T.[Service],
	T.InvoiceNumber,
	T.InvoiceAmount,
	T.InvoiceDate,
	T.ToBePaidDate,
	T.PaymentType,
	T.ReceivedDate,
	T.SubmitMethod,
	T.DocumentID,
	T.DocumentName
FROM #tmpFinalResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'ASC'
	 THEN T.PurchaseOrderNumber END ASC, 
	 CASE WHEN @sortColumn = 'PurchaseOrderNumber' AND @sortOrder = 'DESC'
	 THEN T.PurchaseOrderNumber END DESC ,

	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'ASC'
	 THEN T.IssueDate END ASC, 
	 CASE WHEN @sortColumn = 'IssueDate' AND @sortOrder = 'DESC'
	 THEN T.IssueDate END DESC ,

	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'ASC'
	 THEN T.Service END ASC, 
	 CASE WHEN @sortColumn = 'Service' AND @sortOrder = 'DESC'
	 THEN T.Service END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,
	 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'ASC'
	 THEN T.InvoiceAmount END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceAmount' AND @sortOrder = 'DESC'
	 THEN T.InvoiceAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'ASC'
	 THEN T.InvoiceDate END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceDate' AND @sortOrder = 'DESC'
	 THEN T.InvoiceDate END DESC ,

	 CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'ASC'
	 THEN T.ToBePaidDate END ASC, 
	 CASE WHEN @sortColumn = 'ToBePaidDate' AND @sortOrder = 'DESC'
	 THEN T.ToBePaidDate END DESC ,

	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'
	 THEN T.PaymentType END ASC, 
	 CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'
	 THEN T.PaymentType END DESC ,
	 
	 CASE WHEN @sortColumn = 'SubmitMethod' AND @sortOrder = 'ASC'
	 THEN T.SubmitMethod END ASC, 
	 CASE WHEN @sortColumn = 'SubmitMethod' AND @sortOrder = 'DESC'
	 THEN T.SubmitMethod END DESC,
	 
	 CASE WHEN @sortColumn = 'DocumentID' AND @sortOrder = 'ASC'
	 THEN T.DocumentID END ASC, 
	 CASE WHEN @sortColumn = 'DocumentID' AND @sortOrder = 'DESC'
	 THEN T.DocumentID END DESC,
	 
	 CASE WHEN @sortColumn = 'DocumentName' AND @sortOrder = 'ASC'
	 THEN T.DocumentName END ASC, 
	 CASE WHEN @sortColumn = 'DocumentName' AND @sortOrder = 'DESC'
	 THEN T.DocumentName END DESC

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
