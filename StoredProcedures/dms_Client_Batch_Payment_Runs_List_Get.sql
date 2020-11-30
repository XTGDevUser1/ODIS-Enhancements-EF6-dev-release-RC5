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
 WHERE id = object_id(N'[dbo].[dms_Client_Batch_Payment_Runs_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Batch_Payment_Runs_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dms_Client_Batch_Payment_Runs_List_Get] @BatchID=147
 CREATE PROCEDURE [dbo].[dms_Client_Batch_Payment_Runs_List_Get]( 
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
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
InvoiceNumberOperator="-1" 
DateOperator="-1" 
NameOperator="-1" 
DescriptionOperator="-1" 
LinesOperator="-1" 
AmountOperator="-1" 
CustomerNumberOperator="-1" 
AddressCodeOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
InvoiceNumberOperator INT NOT NULL,
InvoiceNumberValue nvarchar(100) NULL,
DateOperator INT NOT NULL,
DateValue datetime NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(100) NULL,
DescriptionOperator INT NOT NULL,
DescriptionValue nvarchar(100) NULL,
LinesOperator INT NOT NULL,
LinesValue int NULL,
AmountOperator INT NOT NULL,
AmountValue money NULL,
CustomerNumberOperator INT NOT NULL,
CustomerNumberValue nvarchar(100) NULL,
AddressCodeOperator INT NOT NULL,
AddressCodeValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	Date datetime  NULL ,
	Name nvarchar(100)  NULL ,
	Description nvarchar(100)  NULL ,
	Lines int  NULL ,
	Amount money  NULL ,
	CustomerNumber nvarchar(100)  NULL ,
	AddressCode nvarchar(100)  NULL 
) 

CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	InvoiceNumber nvarchar(100)  NULL ,
	Date datetime  NULL ,
	Name nvarchar(100)  NULL ,
	Description nvarchar(100)  NULL ,
	Lines int  NULL ,
	Amount money  NULL ,
	CustomerNumber nvarchar(100)  NULL ,
	AddressCode nvarchar(100)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@InvoiceNumberOperator','INT'),-1),
	T.c.value('@InvoiceNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DateOperator','INT'),-1),
	T.c.value('@DateValue','datetime') ,
	ISNULL(T.c.value('@NameOperator','INT'),-1),
	T.c.value('@NameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@DescriptionOperator','INT'),-1),
	T.c.value('@DescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@LinesOperator','INT'),-1),
	T.c.value('@LinesValue','int') ,
	ISNULL(T.c.value('@AmountOperator','INT'),-1),
	T.c.value('@AmountValue','money') ,
	ISNULL(T.c.value('@CustomerNumberOperator','INT'),-1),
	T.c.value('@CustomerNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@AddressCodeOperator','INT'),-1),
	T.c.value('@AddressCodeValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT BI.ID
, BI.InvoiceNumber AS InvoiceNumber
, BI.InvoiceDate AS [Date]
, BI.Name AS Name
, BI.Description AS [Description]
, COUNT(BIL.ID) AS Lines
, SUM(BIL.LineAmount) AS Amount
, BI.AccountingSystemCustomerNumber AS CustomerNumber
, BI.AccountingSystemAddressCode AS AddressCode
FROM BillingInvoice BI
LEFT JOIN BillingInvoiceLine BIL WITH(NOLOCK) ON BIL.BillingInvoiceID = BI.ID
WHERE BI.AccountingInvoiceBatchID = @BatchID
GROUP BY
BI.ID
, BI.InvoiceNumber
, BI.InvoiceDate
, BI.Name
, BI.[Description]
, BI.AccountingSystemCustomerNumber
, BI.AccountingSystemAddressCode

INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.InvoiceNumber,
	T.Date,
	T.Name,
	T.Description,
	T.Lines,
	T.Amount,
	T.CustomerNumber,
	T.AddressCode
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
	 ( TMP.NameOperator = -1 ) 
 OR 
	 ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
	 ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
	 ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
	 ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DescriptionOperator = -1 ) 
 OR 
	 ( TMP.DescriptionOperator = 0 AND T.Description IS NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 1 AND T.Description IS NOT NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 2 AND T.Description = TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 3 AND T.Description <> TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 4 AND T.Description LIKE TMP.DescriptionValue + '%') 
 OR 
	 ( TMP.DescriptionOperator = 5 AND T.Description LIKE '%' + TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 6 AND T.Description LIKE '%' + TMP.DescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.LinesOperator = -1 ) 
 OR 
	 ( TMP.LinesOperator = 0 AND T.Lines IS NULL ) 
 OR 
	 ( TMP.LinesOperator = 1 AND T.Lines IS NOT NULL ) 
 OR 
	 ( TMP.LinesOperator = 2 AND T.Lines = TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 3 AND T.Lines <> TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 7 AND T.Lines > TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 8 AND T.Lines >= TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 9 AND T.Lines < TMP.LinesValue ) 
 OR 
	 ( TMP.LinesOperator = 10 AND T.Lines <= TMP.LinesValue ) 

 ) 

 AND 

 ( 
	 ( TMP.AmountOperator = -1 ) 
 OR 
	 ( TMP.AmountOperator = 0 AND T.Amount IS NULL ) 
 OR 
	 ( TMP.AmountOperator = 1 AND T.Amount IS NOT NULL ) 
 OR 
	 ( TMP.AmountOperator = 2 AND T.Amount = TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 3 AND T.Amount <> TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 7 AND T.Amount > TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 8 AND T.Amount >= TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 9 AND T.Amount < TMP.AmountValue ) 
 OR 
	 ( TMP.AmountOperator = 10 AND T.Amount <= TMP.AmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CustomerNumberOperator = -1 ) 
 OR 
	 ( TMP.CustomerNumberOperator = 0 AND T.CustomerNumber IS NULL ) 
 OR 
	 ( TMP.CustomerNumberOperator = 1 AND T.CustomerNumber IS NOT NULL ) 
 OR 
	 ( TMP.CustomerNumberOperator = 2 AND T.CustomerNumber = TMP.CustomerNumberValue ) 
 OR 
	 ( TMP.CustomerNumberOperator = 3 AND T.CustomerNumber <> TMP.CustomerNumberValue ) 
 OR 
	 ( TMP.CustomerNumberOperator = 4 AND T.CustomerNumber LIKE TMP.CustomerNumberValue + '%') 
 OR 
	 ( TMP.CustomerNumberOperator = 5 AND T.CustomerNumber LIKE '%' + TMP.CustomerNumberValue ) 
 OR 
	 ( TMP.CustomerNumberOperator = 6 AND T.CustomerNumber LIKE '%' + TMP.CustomerNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.AddressCodeOperator = -1 ) 
 OR 
	 ( TMP.AddressCodeOperator = 0 AND T.AddressCode IS NULL ) 
 OR 
	 ( TMP.AddressCodeOperator = 1 AND T.AddressCode IS NOT NULL ) 
 OR 
	 ( TMP.AddressCodeOperator = 2 AND T.AddressCode = TMP.AddressCodeValue ) 
 OR 
	 ( TMP.AddressCodeOperator = 3 AND T.AddressCode <> TMP.AddressCodeValue ) 
 OR 
	 ( TMP.AddressCodeOperator = 4 AND T.AddressCode LIKE TMP.AddressCodeValue + '%') 
 OR 
	 ( TMP.AddressCodeOperator = 5 AND T.AddressCode LIKE '%' + TMP.AddressCodeValue ) 
 OR 
	 ( TMP.AddressCodeOperator = 6 AND T.AddressCode LIKE '%' + TMP.AddressCodeValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'ASC'
	 THEN T.InvoiceNumber END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceNumber' AND @sortOrder = 'DESC'
	 THEN T.InvoiceNumber END DESC ,

	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'ASC'
	 THEN T.Date END ASC, 
	 CASE WHEN @sortColumn = 'Date' AND @sortOrder = 'DESC'
	 THEN T.Date END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'Lines' AND @sortOrder = 'ASC'
	 THEN T.Lines END ASC, 
	 CASE WHEN @sortColumn = 'Lines' AND @sortOrder = 'DESC'
	 THEN T.Lines END DESC ,

	 CASE WHEN @sortColumn = 'Amount' AND @sortOrder = 'ASC'
	 THEN T.Amount END ASC, 
	 CASE WHEN @sortColumn = 'Amount' AND @sortOrder = 'DESC'
	 THEN T.Amount END DESC ,

	 CASE WHEN @sortColumn = 'CustomerNumber' AND @sortOrder = 'ASC'
	 THEN T.CustomerNumber END ASC, 
	 CASE WHEN @sortColumn = 'CustomerNumber' AND @sortOrder = 'DESC'
	 THEN T.CustomerNumber END DESC ,

	 CASE WHEN @sortColumn = 'AddressCode' AND @sortOrder = 'ASC'
	 THEN T.AddressCode END ASC, 
	 CASE WHEN @sortColumn = 'AddressCode' AND @sortOrder = 'DESC'
	 THEN T.AddressCode END DESC 


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
