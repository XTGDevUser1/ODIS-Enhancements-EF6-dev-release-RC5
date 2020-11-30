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
 WHERE id = object_id(N'[dbo].[dms_TempCC_GLAccountList_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_TempCC_GLAccountList_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_TempCC_GLAccountList_get] @BatchID=169
 CREATE PROCEDURE [dbo].[dms_TempCC_GLAccountList_get]( 
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

Declare @DefaultGLAccount nvarchar(50)
	   , @ApplicationConfigurationType INT
SET @ApplicationConfigurationType = (Select ID from ApplicationConfigurationTYpe where name = 'VendorInvoice')
SET @DefaultGLAccount = (Select Value From ApplicationConfiguration where Name = 'ISPCheckGLExpenseAccount' And ApplicationConfigurationTypeID = @ApplicationConfigurationType)


 CREATE TABLE #FinalResultsFiltered( 	
	GLAccountName			NVARCHAR(11)  NULL ,
	GLAccountCount		INT  NULL ,
	PaymentAmount		money  NULL
) 

CREATE TABLE #FinalResultsSorted( 
	[RowNum]		[BIGINT]	NOT NULL IDENTITY(1,1),
	GLAccountName			NVARCHAR(11)  NULL ,
	GLAccountCount		INT  NULL ,
	PaymentAmount		money  NULL 
) 

--SELECT * FROM @tmpForWhereClause

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResultsFiltered
SELECT
VI.GLExpenseAccount [GLAccountName],
COUNT(TCC.ID) [GLAccountCount],
SUM(TCC.TotalChargedAmount) [PaymentAmount]
 from VendorInvoice VI
join TemporaryCreditCard TCC ON TCC.VendorInvoiceID = VI.ID
WHERE VI.ExportBatchID = @BatchID
group by vi.GLExpenseAccount
order by vi.GLExpenseAccount



--Select COALESCE(pc.Value, @DefaultGLAccount) [GL Account]
--, count(*) [Count]
--, SUM(vi.paymentamount) Amount
--, po.ID
--, TCC.ID
--From TemporaryCreditCard tcc
--Join PurchaseOrder po on po.id = tcc.PurchaseOrderID
--Join VendorInvoice vi on po.ID = vi.PurchaseOrderID
--Join ServiceRequest sr on sr.ID = po.ServiceRequestID
--Join [Case] c on c.ID = SR.CaseID
--Left Outer Join ProgramConfiguration pc on pc.ProgramID = c.ProgramID And pc.Name = 'ISPCheckGLExpenseAccount'
--Where tcc.PostingBatchID = @BatchID
--Group By
--COALESCE(pc.Value, @DefaultGLAccount),po.ID

INSERT INTO #FinalResultsSorted
SELECT 
	T.GLAccountName,
	T.GLAccountCount,
	T.PaymentAmount
FROM #FinalResultsFiltered T

 ORDER BY 
	 CASE WHEN @sortColumn = 'GLAccountName' AND @sortOrder = 'ASC'
	 THEN T.GLAccountName END ASC, 
	 CASE WHEN @sortColumn = 'GLAccountName' AND @sortOrder = 'DESC'
	 THEN T.GLAccountName END DESC ,

	 CASE WHEN @sortColumn = 'GLAccountCount' AND @sortOrder = 'ASC'
	 THEN T.GLAccountCount END ASC, 
	 CASE WHEN @sortColumn = 'GLAccountCount' AND @sortOrder = 'DESC'
	 THEN T.GLAccountCount END DESC ,

	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'ASC'
	 THEN T.PaymentAmount END ASC, 
	 CASE WHEN @sortColumn = 'PaymentAmount' AND @sortOrder = 'DESC'
	 THEN T.PaymentAmount END DESC 
	 
	 

DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM #FinalResultsSorted
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

SELECT @count AS TotalRows,@BatchID AS BatchId, * FROM #FinalResultsSorted WHERE RowNum BETWEEN @startInd AND @endInd

DROP TABLE #FinalResultsFiltered
DROP TABLE #FinalResultsSorted

END
