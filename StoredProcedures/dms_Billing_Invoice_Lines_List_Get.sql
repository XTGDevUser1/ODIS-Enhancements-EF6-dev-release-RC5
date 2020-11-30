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
 WHERE id = object_id(N'[dbo].[dms_Billing_Invoice_Lines_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Billing_Invoice_Lines_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Billing_Invoice_Lines_List_Get] @BillingInvoiceID=14
 CREATE PROCEDURE [dbo].[dms_Billing_Invoice_Lines_List_Get](   
   @whereClauseXML XML = NULL 
 , @startInd Int = 1   
 , @endInd BIGINT = 5000   
 , @pageSize int = 10    
 , @sortColumn nvarchar(100)  = ''   
 , @sortOrder nvarchar(100) = ''   
 , @BillingInvoiceID INT = NULL  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON
DECLARE @tmpForWhereClause TABLE
(
ScheduleDateFrom DATETIME NULL,
ScheduleDateTo DATETIME NULL,
ClientID INT NULL,
BillingDefinitionInvoiceID INT NULL,
LineStatuses NVARCHAR(MAX) NULL,
InvoiceStatuses NVARCHAR(MAX) NULL,
BillingDefinitionInvoiceLines NVARCHAR(MAX) NULL
)
CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Product nvarchar(100)  NULL ,
	RateType nvarchar(100)  NULL ,
	BillingDefinitionInvoiceLine nvarchar(100)  NULL ,
	BillingInvoiceLineStatus nvarchar(100)  NULL ,
	ID int  NULL ,
	BillingInvoiceID int  NULL ,
	ProductID int  NULL ,
	RateTypeID int  NULL ,
	Name nvarchar(100)  NULL ,
	Description nvarchar(100)  NULL ,
	Comment nvarchar(100)  NULL ,
	AccountingSystemGLCode nvarchar(100)  NULL ,
	LineQuantity int  NULL ,
	LineCost money  NULL ,
	LineAmount money  NULL ,
	InvoiceLineStatusID int  NULL ,
	BillingDefinitionInvoiceLineID int  NULL ,
	AccountingSystemItemCode nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL 
) 
CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Product nvarchar(100)  NULL ,
	RateType nvarchar(100)  NULL ,
	BillingDefinitionInvoiceLine nvarchar(100)  NULL ,
	BillingInvoiceLineStatus nvarchar(100)  NULL ,
	ID int  NULL ,
	BillingInvoiceID int  NULL ,
	ProductID int  NULL ,
	RateTypeID int  NULL ,
	Name nvarchar(100)  NULL ,
	Description nvarchar(100)  NULL ,
	Comment nvarchar(100)  NULL ,
	AccountingSystemGLCode nvarchar(100)  NULL ,
	LineQuantity int  NULL ,
	LineCost money  NULL ,
	LineAmount money  NULL ,
	InvoiceLineStatusID int  NULL ,
	BillingDefinitionInvoiceLineID int  NULL ,
	AccountingSystemItemCode nvarchar(100)  NULL ,
	Sequence int  NULL ,
	IsActive bit  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL 
) 
INSERT INTO @tmpForWhereClause
SELECT  
		T.c.value('@ScheduleDateFrom','datetime'),
		T.c.value('@ScheduleDateTo','datetime'),
		T.c.value('@ClientID','int') ,
		T.c.value('@BillingDefinitionInvoiceID','int') ,
		T.c.value('@LineStatuses','NVARCHAR(MAX)'),
		T.c.value('@InvoiceStatuses','NVARCHAR(MAX)'), 
		T.c.value('@BillingDefinitionInvoiceLines','NVARCHAR(MAX)') 
				
		
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @ScheduleDateFrom DATETIME ,
@ScheduleDateTo DATETIME ,
@ClientID INT ,
@BillingDefinitionInvoiceID INT ,
@LineStatuses NVARCHAR(MAX) ,
@InvoiceStatuses NVARCHAR(MAX),
@BillingDefinitionInvoiceLines NVARCHAR(MAX)

SELECT	@LineStatuses = T.LineStatuses,
		@BillingDefinitionInvoiceLines = T.BillingDefinitionInvoiceLines
FROM	@tmpForWhereClause T

INSERT INTO #tmpFinalResults    
Select	P.Name AS Product
	 , RT.Name AS RateType
	 , BDIL.Name AS BillingDefinitionInvoiceLine
	 , BILS.Name AS BillingInvoiceLineStatus
	 , BIL.* from BillingInvoiceLine BIL 
LEFT OUTER JOIN Product P ON P.ID = BIL.ProductID
LEFT OUTER JOIN RateType RT ON RT.ID = BIL.RateTypeID
LEFT OUTER JOIN BillingDefinitionInvoiceLine BDIL ON BDIL.ID = BIL.BillingDefinitionInvoiceLineID
LEFT OUTER JOIN BillingInvoiceLineStatus BILS ON BILS.ID = BIL.InvoiceLineStatusID
where BIL.BillingInvoiceID = @BillingInvoiceID
AND		ISNULL(BIL.IsActive,0) = 1
AND	(@LineStatuses IS NULL OR BILS.ID IN (SELECT item FROM fnSplitString(@LineStatuses,',') ))
AND	(@BillingDefinitionInvoiceLines IS NULL OR BDIL.ID IN (SELECT item FROM fnSplitString(@BillingDefinitionInvoiceLines,',') ))
ORDER BY BIL.Sequence

INSERT INTO #FinalResults
SELECT 
	T.Product,
	T.RateType,
	T.BillingDefinitionInvoiceLine,
	T.BillingInvoiceLineStatus,
	T.ID,
	T.BillingInvoiceID,
	T.ProductID,
	T.RateTypeID,
	T.Name,
	T.[Description],
	T.Comment,
	T.AccountingSystemGLCode,
	T.LineQuantity,
	T.LineCost,
	T.LineAmount,
	T.InvoiceLineStatusID,
	T.BillingDefinitionInvoiceLineID,
	T.AccountingSystemItemCode,
	T.Sequence,
	T.IsActive,
	T.CreateDate,
	T.CreateBy,
	T.ModifyDate,
	T.ModifyBy
FROM #tmpFinalResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'ASC'
	 THEN T.Product END ASC, 
	 CASE WHEN @sortColumn = 'Product' AND @sortOrder = 'DESC'
	 THEN T.Product END DESC ,

	 CASE WHEN @sortColumn = 'RateType' AND @sortOrder = 'ASC'
	 THEN T.RateType END ASC, 
	 CASE WHEN @sortColumn = 'RateType' AND @sortOrder = 'DESC'
	 THEN T.RateType END DESC ,

	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceLine' AND @sortOrder = 'ASC'
	 THEN T.BillingDefinitionInvoiceLine END ASC, 
	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceLine' AND @sortOrder = 'DESC'
	 THEN T.BillingDefinitionInvoiceLine END DESC ,

	 CASE WHEN @sortColumn = 'BillingInvoiceLineStatus' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceLineStatus END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceLineStatus' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceLineStatus END DESC ,

	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'BillingInvoiceID' AND @sortOrder = 'ASC'
	 THEN T.BillingInvoiceID END ASC, 
	 CASE WHEN @sortColumn = 'BillingInvoiceID' AND @sortOrder = 'DESC'
	 THEN T.BillingInvoiceID END DESC ,

	 CASE WHEN @sortColumn = 'ProductID' AND @sortOrder = 'ASC'
	 THEN T.ProductID END ASC, 
	 CASE WHEN @sortColumn = 'ProductID' AND @sortOrder = 'DESC'
	 THEN T.ProductID END DESC ,

	 CASE WHEN @sortColumn = 'RateTypeID' AND @sortOrder = 'ASC'
	 THEN T.RateTypeID END ASC, 
	 CASE WHEN @sortColumn = 'RateTypeID' AND @sortOrder = 'DESC'
	 THEN T.RateTypeID END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'ASC'
	 THEN T.Comment END ASC, 
	 CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'DESC'
	 THEN T.Comment END DESC ,

	 CASE WHEN @sortColumn = 'AccountingSystemGLCode' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemGLCode END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemGLCode' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemGLCode END DESC ,

	 CASE WHEN @sortColumn = 'LineQuantity' AND @sortOrder = 'ASC'
	 THEN T.LineQuantity END ASC, 
	 CASE WHEN @sortColumn = 'LineQuantity' AND @sortOrder = 'DESC'
	 THEN T.LineQuantity END DESC ,

	 CASE WHEN @sortColumn = 'LineCost' AND @sortOrder = 'ASC'
	 THEN T.LineCost END ASC, 
	 CASE WHEN @sortColumn = 'LineCost' AND @sortOrder = 'DESC'
	 THEN T.LineCost END DESC ,

	 CASE WHEN @sortColumn = 'LineAmount' AND @sortOrder = 'ASC'
	 THEN T.LineAmount END ASC, 
	 CASE WHEN @sortColumn = 'LineAmount' AND @sortOrder = 'DESC'
	 THEN T.LineAmount END DESC ,

	 CASE WHEN @sortColumn = 'InvoiceLineStatusID' AND @sortOrder = 'ASC'
	 THEN T.InvoiceLineStatusID END ASC, 
	 CASE WHEN @sortColumn = 'InvoiceLineStatusID' AND @sortOrder = 'DESC'
	 THEN T.InvoiceLineStatusID END DESC ,

	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceLineID' AND @sortOrder = 'ASC'
	 THEN T.BillingDefinitionInvoiceLineID END ASC, 
	 CASE WHEN @sortColumn = 'BillingDefinitionInvoiceLineID' AND @sortOrder = 'DESC'
	 THEN T.BillingDefinitionInvoiceLineID END DESC ,

	 CASE WHEN @sortColumn = 'AccountingSystemItemCode' AND @sortOrder = 'ASC'
	 THEN T.AccountingSystemItemCode END ASC, 
	 CASE WHEN @sortColumn = 'AccountingSystemItemCode' AND @sortOrder = 'DESC'
	 THEN T.AccountingSystemItemCode END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC ,

	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
	 THEN T.CreateBy END ASC, 
	 CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
	 THEN T.CreateBy END DESC ,

	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'ASC'
	 THEN T.ModifyDate END ASC, 
	 CASE WHEN @sortColumn = 'ModifyDate' AND @sortOrder = 'DESC'
	 THEN T.ModifyDate END DESC ,

	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'ASC'
	 THEN T.ModifyBy END ASC, 
	 CASE WHEN @sortColumn = 'ModifyBy' AND @sortOrder = 'DESC'
	 THEN T.ModifyBy END DESC 

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
     
 DROP TABLE #FinalResults    
 DROP TABLE #tmpFinalResults    

END
