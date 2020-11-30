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
 WHERE id = object_id(N'[dbo].[dms_Temporary_CC_Batch_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Temporary_CC_Batch_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Temporary_CC_Batch_List]( 
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
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL--,
      --CreditCardIssueNumber nvarchar(100) NULL
) 

CREATE TABLE #tmpFinalResults( 
      [RowNum] [bigint] NOT NULL IDENTITY(1,1),
      ID int  NULL ,
      BatchType nvarchar(100)  NULL ,
      BatchStatusID int  NULL ,
      BatchStatus nvarchar(100)  NULL ,
      TotalCount int  NULL ,
      TotalAmount money  NULL ,     
      CreateDate datetime  NULL ,
      CreateBy nvarchar(100)  NULL ,
      ModifyDate datetime  NULL ,
      ModifyBy nvarchar(100)  NULL--,
      --CreditCardIssueNumber nvarchar(100) NULL
) 

INSERT INTO #tmpForWhereClause
SELECT 
      T.c.value('@BatchStatusID','int') ,
      T.c.value('@FromDate','datetime') ,
      T.c.value('@ToDate','datetime') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

DECLARE @batchStatusID NVARCHAR(100) = NULL,
            @fromDate DATETIME = NULL,
            @toDate DATETIME = NULL
            
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
            , BT.[Description] AS BatchType
            , B.BatchStatusID
            , BS.Name AS BatchStatus
            , B.TotalCount AS TotalCount
            , B.TotalAmount AS TotalAmount
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy 
            --, TCC.CreditCardIssueNumber
FROM  Batch B
JOIN  BatchType BT ON BT.ID = B.BatchTypeID
JOIN  BatchStatus BS ON BS.ID = B.BatchStatusID
LEFT JOIN TemporaryCreditCard TCC ON TCC.PostingBatchID = B.ID
WHERE B.BatchTypeID = (SELECT ID FROM BatchType WHERE Name = 'TemporaryCCPost')
AND         (@batchStatusID IS NULL OR @batchStatusID = B.BatchStatusID)
AND         (@fromDate IS NULL OR B.CreateDate > @fromDate)
AND         (@toDate IS NULL OR B.CreateDate < @toDate)
GROUP BY    B.ID
            , BT.[Description] 
            , B.BatchStatusID
            , BS.Name  
            , B.TotalCount
            , B.TotalAmount         
            , B.CreateDate
            , B.CreateBy
            , B.ModifyDate
            , B.ModifyBy
            --, TCC.CreditCardIssueNumber
ORDER BY B.CreateDate DESC



INSERT INTO #FinalResults
SELECT 
      T.ID,
      T.BatchType,
      T.BatchStatusID,
      T.BatchStatus,
      T.TotalCount,
      T.TotalAmount,    
      T.CreateDate,
      T.CreateBy,
      T.ModifyDate,
      T.ModifyBy--,
      --T.CreditCardIssueNumber
      
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
      THEN T.ModifyBy END DESC --,

      --CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'ASC'
      --THEN T.CreditCardIssueNumber END ASC, 
      -- CASE WHEN @sortColumn = 'CreditCardIssueNumber' AND @sortOrder = 'DESC'
      --THEN T.CreditCardIssueNumber END DESC 


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