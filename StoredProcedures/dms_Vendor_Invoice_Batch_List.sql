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
 WHERE id = object_id(N'[dbo].[dms_Vendor_Invoice_Batch_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Invoice_Batch_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Vendor_Invoice_Batch_List]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'CreateDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
      SET FMTONLY OFF;
     SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
      SET @whereClauseXML = '<ROW><Filter 

></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
BatchStatusID int NULL,
FromDate DATETIME NULL,
ToDate DATETIME NULL
)
CREATE TABLE #FinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,
      MasterETLLoadID int  NULL ,
      TransactionETLLoadID int  NULL ,
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL ,
      CheckCount int  NULL ,
      CheckAmount money  NULL,
      ACHCount int  NULL ,
      ACHAmount money  NULL
) 

CREATE TABLE #tmpFinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,
      MasterETLLoadID int  NULL ,
      TransactionETLLoadID int  NULL ,
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL ,
      CheckCount int  NULL ,
      CheckAmount money  NULL,
      ACHCount int  NULL ,
      ACHAmount money  NULL
) 

INSERT INTO #tmpForWhereClause
SELECT 
      T.c.value('@BatchStatusID','int') ,
      T.c.value('@FromDate','datetime') ,
      T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @batchStatusID NVARCHAR(100) = NULL,
            @fromDate DATETIME = NULL,
            @toDate DATETIME = NULL,
			@Check INT = (SELECT ID FROM PaymentType WHERE Name = 'Check'),
			@ACH INT = (SELECT ID FROM PaymentType WHERE Name = 'ACH')
            
SELECT      @batchStatusID = BatchStatusID, 
            @fromDate = FromDate,
            @toDate = ToDate
FROM  #tmpForWhereClause
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


INSERT INTO #tmpFinalResults
SELECT      B.ID
            , BT.Name AS BatchType
            , B.BatchStatusID
            , BS.Name AS BatchStatus
            , COUNT(VI.ID) AS TotalCount
            , SUM(ISNULL(VI.PaymentAmount,0)) AS TotalAmount
            , B.MasterETLLoadID
            , B.TransactionETLLoadID
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy 
            --, COUNT(CVI.ID) AS CheckCount
            --, SUM(ISNULL(CVI.PaymentAmount,0)) AS CheckAmount
            --, COUNT(AVI.ID) AS ACHCount
            --, SUM(ISNULL(AVI.PaymentAmount,0)) AS ACHAmount
            , (SELECT Count(*) FROM VendorInvoice WHERE ExportBatchID = B.ID AND PaymentTypeID = @Check) AS CheckCount
            , (SELECT SUM(ISNULL(PaymentAmount,0)) FROM VendorInvoice WHERE ExportBatchID = B.ID AND PaymentTypeID = @Check) AS CheckAmount
            , (SELECT Count(*) FROM VendorInvoice WHERE ExportBatchID = B.ID AND PaymentTypeID = @ACH) AS ACHCount
            , (SELECT SUM(ISNULL(PaymentAmount,0)) FROM VendorInvoice WHERE ExportBatchID = B.ID AND PaymentTypeID = @ACH) AS ACHAmount
FROM  Batch B
JOIN  BatchType BT ON BT.ID = B.BatchTypeID
JOIN  BatchStatus BS ON BS.ID = B.BatchStatusID
LEFT JOIN   VendorInvoice VI ON VI.ExportBatchID = B.ID
--LEFT JOIN   VendorInvoice CVI ON CVI.ExportBatchID = B.ID AND CVI.PaymentTypeID = (Select ID from PaymentType  where Name='Check')
--LEFT JOIN	VendorInvoice AVI ON AVI.ExportBatchID = B.ID AND AVI.PaymentTypeID = (Select ID from PaymentType  where Name='ACH')
WHERE B.BatchTypeID = (SELECT ID FROM BatchType WHERE Name = 'VendorInvoiceExport')
AND         (@batchStatusID IS NULL OR @batchStatusID = B.BatchStatusID)
AND         (@fromDate IS NULL OR B.CreateDate > @fromDate)
AND         (@toDate IS NULL OR B.CreateDate < @toDate)
GROUP BY    B.ID
            , BT.Name 
            , B.BatchStatusID
            , BS.Name
            , B.MasterETLLoadID
            , B.TransactionETLLoadID
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy

ORDER BY B.CreateDate DESC



INSERT INTO #FinalResults
SELECT 
      T.ID,
      T.BatchType,
      T.BatchStatusID,
      T.BatchStatus,
      T.TotalCount,
      T.TotalAmount,
      T.MasterETLLoadID,
      T.TransactionETLLoadID,
      T.CreateDate,
      T.CreateBy,
      T.ModifyDate,
      T.ModifyBy,
      T.CheckCount,
      T.CheckAmount,
      T.ACHCount,
      T.ACHAmount
      
FROM #tmpFinalResults T

ORDER BY 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
      THEN T.ID END ASC, 
       CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
      THEN T.ID END DESC ,

      CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'ASC'
      THEN T.BatchType END ASC, 
       CASE WHEN @sortColumn = 'BatchType' AND @sortOrder = 'DESC'
      THEN T.BatchType END DESC ,

      CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'ASC'
      THEN T.BatchStatusID END ASC, 
       CASE WHEN @sortColumn = 'BatchStatusID' AND @sortOrder = 'DESC'
      THEN T.BatchStatusID END DESC ,

      CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'ASC'
      THEN T.BatchStatus END ASC, 
       CASE WHEN @sortColumn = 'BatchStatus' AND @sortOrder = 'DESC'
      THEN T.BatchStatus END DESC ,

      CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'ASC'
      THEN T.TotalCount END ASC, 
       CASE WHEN @sortColumn = 'TotalCount' AND @sortOrder = 'DESC'
      THEN T.TotalCount END DESC ,

      CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'ASC'
      THEN T.TotalAmount END ASC, 
       CASE WHEN @sortColumn = 'TotalAmount' AND @sortOrder = 'DESC'
      THEN T.TotalAmount END DESC ,

      CASE WHEN @sortColumn = 'MasterETLLoadID' AND @sortOrder = 'ASC'
      THEN T.MasterETLLoadID END ASC, 
       CASE WHEN @sortColumn = 'MasterETLLoadID' AND @sortOrder = 'DESC'
      THEN T.MasterETLLoadID END DESC ,

      CASE WHEN @sortColumn = 'TransactionETLLoadID' AND @sortOrder = 'ASC'
      THEN T.TransactionETLLoadID END ASC, 
       CASE WHEN @sortColumn = 'TransactionETLLoadID' AND @sortOrder = 'DESC'
      THEN T.TransactionETLLoadID END DESC ,

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
      THEN T.ModifyBy END DESC  ,

      CASE WHEN @sortColumn = 'CheckCount' AND @sortOrder = 'ASC'
      THEN T.CheckCount END ASC, 
       CASE WHEN @sortColumn = 'CheckCount' AND @sortOrder = 'DESC'
      THEN T.CheckCount END DESC  ,

      CASE WHEN @sortColumn = 'CheckAmount' AND @sortOrder = 'ASC'
      THEN T.CheckAmount END ASC, 
       CASE WHEN @sortColumn = 'CheckAmount' AND @sortOrder = 'DESC'
      THEN T.CheckAmount END DESC ,

      CASE WHEN @sortColumn = 'ACHCount' AND @sortOrder = 'ASC'
      THEN T.ACHCount END ASC, 
       CASE WHEN @sortColumn = 'ACHCount' AND @sortOrder = 'DESC'
      THEN T.ACHCount END DESC ,

      CASE WHEN @sortColumn = 'ACHAmount' AND @sortOrder = 'ASC'
      THEN T.ACHAmount END ASC, 
       CASE WHEN @sortColumn = 'ACHAmount' AND @sortOrder = 'DESC'
      THEN T.ACHAmount END DESC 


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

GO