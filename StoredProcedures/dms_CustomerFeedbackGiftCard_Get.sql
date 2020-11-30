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
 WHERE id = object_id(N'[dbo].[dms_CustomerFeedbackGiftCard_Get]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CustomerFeedbackGiftCard_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
/*
	EXEC dms_CustomerFeedbackGiftCard_Get
*/ 
 CREATE PROCEDURE [dbo].[dms_CustomerFeedbackGiftCard_Get](   
   @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @whereClauseXML XML = NULL  
 , @customerFeedbackId INT = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
CustomerFeedbackIDOperator="-1" 
CardNumberOperator="-1" 
CardAmountOperator="-1" 
RequestedByOperator="-1" 
CardSentDateOperator="-1" 
CreateDateOperator="-1" 
CreateByOperator="-1" 
ModifyDateOperator="-1" 
ModifyByOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
CustomerFeedbackIDOperator INT NOT NULL,
CustomerFeedbackIDValue int NULL,
CardNumberOperator INT NOT NULL,
CardNumberValue nvarchar(500) NULL,
CardAmountOperator INT NOT NULL,
CardAmountValue money NULL,
RequestedByOperator INT NOT NULL,
RequestedByValue nvarchar(500) NULL,
CardSentDateOperator INT NOT NULL,
CardSentDateValue datetime NULL,
CreateDateOperator INT NOT NULL,
CreateDateValue datetime NULL,
CreateByOperator INT NOT NULL,
CreateByValue nvarchar(500) NULL,
ModifyDateOperator INT NOT NULL,
ModifyDateValue datetime NULL,
ModifyByOperator INT NOT NULL,
ModifyByValue nvarchar(500) NULL
)
 CREATE TABLE #TempResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	CustomerFeedbackID int  NULL ,
	CardNumber nvarchar(500)  NULL ,
	CardAmount money  NULL ,
	RequestedBy nvarchar(500)  NULL ,
	CardSentDate datetime  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(500)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(500)  NULL 
) 

 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	CustomerFeedbackID int  NULL ,
	CardNumber nvarchar(500)  NULL ,
	CardAmount money  NULL ,
	RequestedBy nvarchar(500)  NULL ,
	CardSentDate datetime  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(500)  NULL ,
	ModifyDate datetime  NULL ,
	ModifyBy nvarchar(500)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@CustomerFeedbackIDOperator','INT'),-1),
	T.c.value('@CustomerFeedbackIDValue','int') ,
	ISNULL(T.c.value('@CardNumberOperator','INT'),-1),
	T.c.value('@CardNumberValue','nvarchar(500)') ,
	ISNULL(T.c.value('@CardAmountOperator','INT'),-1),
	T.c.value('@CardAmountValue','money') ,
	ISNULL(T.c.value('@RequestedByOperator','INT'),-1),
	T.c.value('@RequestedByValue','nvarchar(500)') ,
	ISNULL(T.c.value('@CardSentDateOperator','INT'),-1),
	T.c.value('@CardSentDateValue','datetime') ,
	ISNULL(T.c.value('@CreateDateOperator','INT'),-1),
	T.c.value('@CreateDateValue','datetime') ,
	ISNULL(T.c.value('@CreateByOperator','INT'),-1),
	T.c.value('@CreateByValue','nvarchar(500)') ,
	ISNULL(T.c.value('@ModifyDateOperator','INT'),-1),
	T.c.value('@ModifyDateValue','datetime') ,
	ISNULL(T.c.value('@ModifyByOperator','INT'),-1),
	T.c.value('@ModifyByValue','nvarchar(500)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
INSERT INTO #TempResults
SELECT 
	ID,
	CustomerFeedbackID,
	CardNumber,
	CardAmount,
	RequestedBy,
	CardSentDate,
	CreateDate,
	CreateBy,
	ModifyDate,
	ModifyBy
FROM CustomerFeedbackGiftCard
WHERE @customerFeedbackId IS NULL OR CustomerFeedbackID = @customerFeedbackId

--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.CustomerFeedbackID,
	T.CardNumber,
	T.CardAmount,
	T.RequestedBy,
	T.CardSentDate,
	T.CreateDate,
	T.CreateBy,
	T.ModifyDate,
	T.ModifyBy
FROM #TempResults T,
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
	 ( TMP.CustomerFeedbackIDOperator = -1 ) 
 OR 
	 ( TMP.CustomerFeedbackIDOperator = 0 AND T.CustomerFeedbackID IS NULL ) 
 OR 
	 ( TMP.CustomerFeedbackIDOperator = 1 AND T.CustomerFeedbackID IS NOT NULL ) 
 OR 
	 ( TMP.CustomerFeedbackIDOperator = 2 AND T.CustomerFeedbackID = TMP.CustomerFeedbackIDValue ) 
 OR 
	 ( TMP.CustomerFeedbackIDOperator = 3 AND T.CustomerFeedbackID <> TMP.CustomerFeedbackIDValue ) 
 OR 
	 ( TMP.CustomerFeedbackIDOperator = 7 AND T.CustomerFeedbackID > TMP.CustomerFeedbackIDValue ) 
 OR 
	 ( TMP.CustomerFeedbackIDOperator = 8 AND T.CustomerFeedbackID >= TMP.CustomerFeedbackIDValue ) 
 OR 
	 ( TMP.CustomerFeedbackIDOperator = 9 AND T.CustomerFeedbackID < TMP.CustomerFeedbackIDValue ) 
 OR 
	 ( TMP.CustomerFeedbackIDOperator = 10 AND T.CustomerFeedbackID <= TMP.CustomerFeedbackIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CardNumberOperator = -1 ) 
 OR 
	 ( TMP.CardNumberOperator = 0 AND T.CardNumber IS NULL ) 
 OR 
	 ( TMP.CardNumberOperator = 1 AND T.CardNumber IS NOT NULL ) 
 OR 
	 ( TMP.CardNumberOperator = 2 AND T.CardNumber = TMP.CardNumberValue ) 
 OR 
	 ( TMP.CardNumberOperator = 3 AND T.CardNumber <> TMP.CardNumberValue ) 
 OR 
	 ( TMP.CardNumberOperator = 4 AND T.CardNumber LIKE TMP.CardNumberValue + '%') 
 OR 
	 ( TMP.CardNumberOperator = 5 AND T.CardNumber LIKE '%' + TMP.CardNumberValue ) 
 OR 
	 ( TMP.CardNumberOperator = 6 AND T.CardNumber LIKE '%' + TMP.CardNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CardAmountOperator = -1 ) 
 OR 
	 ( TMP.CardAmountOperator = 0 AND T.CardAmount IS NULL ) 
 OR 
	 ( TMP.CardAmountOperator = 1 AND T.CardAmount IS NOT NULL ) 
 OR 
	 ( TMP.CardAmountOperator = 2 AND T.CardAmount = TMP.CardAmountValue ) 
 OR 
	 ( TMP.CardAmountOperator = 3 AND T.CardAmount <> TMP.CardAmountValue ) 
 OR 
	 ( TMP.CardAmountOperator = 7 AND T.CardAmount > TMP.CardAmountValue ) 
 OR 
	 ( TMP.CardAmountOperator = 8 AND T.CardAmount >= TMP.CardAmountValue ) 
 OR 
	 ( TMP.CardAmountOperator = 9 AND T.CardAmount < TMP.CardAmountValue ) 
 OR 
	 ( TMP.CardAmountOperator = 10 AND T.CardAmount <= TMP.CardAmountValue ) 

 ) 

 AND 

 ( 
	 ( TMP.RequestedByOperator = -1 ) 
 OR 
	 ( TMP.RequestedByOperator = 0 AND T.RequestedBy IS NULL ) 
 OR 
	 ( TMP.RequestedByOperator = 1 AND T.RequestedBy IS NOT NULL ) 
 OR 
	 ( TMP.RequestedByOperator = 2 AND T.RequestedBy = TMP.RequestedByValue ) 
 OR 
	 ( TMP.RequestedByOperator = 3 AND T.RequestedBy <> TMP.RequestedByValue ) 
 OR 
	 ( TMP.RequestedByOperator = 4 AND T.RequestedBy LIKE TMP.RequestedByValue + '%') 
 OR 
	 ( TMP.RequestedByOperator = 5 AND T.RequestedBy LIKE '%' + TMP.RequestedByValue ) 
 OR 
	 ( TMP.RequestedByOperator = 6 AND T.RequestedBy LIKE '%' + TMP.RequestedByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CardSentDateOperator = -1 ) 
 OR 
	 ( TMP.CardSentDateOperator = 0 AND T.CardSentDate IS NULL ) 
 OR 
	 ( TMP.CardSentDateOperator = 1 AND T.CardSentDate IS NOT NULL ) 
 OR 
	 ( TMP.CardSentDateOperator = 2 AND T.CardSentDate = TMP.CardSentDateValue ) 
 OR 
	 ( TMP.CardSentDateOperator = 3 AND T.CardSentDate <> TMP.CardSentDateValue ) 
 OR 
	 ( TMP.CardSentDateOperator = 7 AND T.CardSentDate > TMP.CardSentDateValue ) 
 OR 
	 ( TMP.CardSentDateOperator = 8 AND T.CardSentDate >= TMP.CardSentDateValue ) 
 OR 
	 ( TMP.CardSentDateOperator = 9 AND T.CardSentDate < TMP.CardSentDateValue ) 
 OR 
	 ( TMP.CardSentDateOperator = 10 AND T.CardSentDate <= TMP.CardSentDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CreateDateOperator = -1 ) 
 OR 
	 ( TMP.CreateDateOperator = 0 AND T.CreateDate IS NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 1 AND T.CreateDate IS NOT NULL ) 
 OR 
	 ( TMP.CreateDateOperator = 2 AND T.CreateDate = TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 3 AND T.CreateDate <> TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 7 AND T.CreateDate > TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 8 AND T.CreateDate >= TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 9 AND T.CreateDate < TMP.CreateDateValue ) 
 OR 
	 ( TMP.CreateDateOperator = 10 AND T.CreateDate <= TMP.CreateDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.CreateByOperator = -1 ) 
 OR 
	 ( TMP.CreateByOperator = 0 AND T.CreateBy IS NULL ) 
 OR 
	 ( TMP.CreateByOperator = 1 AND T.CreateBy IS NOT NULL ) 
 OR 
	 ( TMP.CreateByOperator = 2 AND T.CreateBy = TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 3 AND T.CreateBy <> TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 4 AND T.CreateBy LIKE TMP.CreateByValue + '%') 
 OR 
	 ( TMP.CreateByOperator = 5 AND T.CreateBy LIKE '%' + TMP.CreateByValue ) 
 OR 
	 ( TMP.CreateByOperator = 6 AND T.CreateBy LIKE '%' + TMP.CreateByValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ModifyDateOperator = -1 ) 
 OR 
	 ( TMP.ModifyDateOperator = 0 AND T.ModifyDate IS NULL ) 
 OR 
	 ( TMP.ModifyDateOperator = 1 AND T.ModifyDate IS NOT NULL ) 
 OR 
	 ( TMP.ModifyDateOperator = 2 AND T.ModifyDate = TMP.ModifyDateValue ) 
 OR 
	 ( TMP.ModifyDateOperator = 3 AND T.ModifyDate <> TMP.ModifyDateValue ) 
 OR 
	 ( TMP.ModifyDateOperator = 7 AND T.ModifyDate > TMP.ModifyDateValue ) 
 OR 
	 ( TMP.ModifyDateOperator = 8 AND T.ModifyDate >= TMP.ModifyDateValue ) 
 OR 
	 ( TMP.ModifyDateOperator = 9 AND T.ModifyDate < TMP.ModifyDateValue ) 
 OR 
	 ( TMP.ModifyDateOperator = 10 AND T.ModifyDate <= TMP.ModifyDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ModifyByOperator = -1 ) 
 OR 
	 ( TMP.ModifyByOperator = 0 AND T.ModifyBy IS NULL ) 
 OR 
	 ( TMP.ModifyByOperator = 1 AND T.ModifyBy IS NOT NULL ) 
 OR 
	 ( TMP.ModifyByOperator = 2 AND T.ModifyBy = TMP.ModifyByValue ) 
 OR 
	 ( TMP.ModifyByOperator = 3 AND T.ModifyBy <> TMP.ModifyByValue ) 
 OR 
	 ( TMP.ModifyByOperator = 4 AND T.ModifyBy LIKE TMP.ModifyByValue + '%') 
 OR 
	 ( TMP.ModifyByOperator = 5 AND T.ModifyBy LIKE '%' + TMP.ModifyByValue ) 
 OR 
	 ( TMP.ModifyByOperator = 6 AND T.ModifyBy LIKE '%' + TMP.ModifyByValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'CustomerFeedbackID' AND @sortOrder = 'ASC'
	 THEN T.CustomerFeedbackID END ASC, 
	 CASE WHEN @sortColumn = 'CustomerFeedbackID' AND @sortOrder = 'DESC'
	 THEN T.CustomerFeedbackID END DESC ,

	 CASE WHEN @sortColumn = 'CardNumber' AND @sortOrder = 'ASC'
	 THEN T.CardNumber END ASC, 
	 CASE WHEN @sortColumn = 'CardNumber' AND @sortOrder = 'DESC'
	 THEN T.CardNumber END DESC ,

	 CASE WHEN @sortColumn = 'CardAmount' AND @sortOrder = 'ASC'
	 THEN T.CardAmount END ASC, 
	 CASE WHEN @sortColumn = 'CardAmount' AND @sortOrder = 'DESC'
	 THEN T.CardAmount END DESC ,

	 CASE WHEN @sortColumn = 'RequestedBy' AND @sortOrder = 'ASC'
	 THEN T.RequestedBy END ASC, 
	 CASE WHEN @sortColumn = 'RequestedBy' AND @sortOrder = 'DESC'
	 THEN T.RequestedBy END DESC ,

	 CASE WHEN @sortColumn = 'CardSentDate' AND @sortOrder = 'ASC'
	 THEN T.CardSentDate END ASC, 
	 CASE WHEN @sortColumn = 'CardSentDate' AND @sortOrder = 'DESC'
	 THEN T.CardSentDate END DESC ,

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

DROP TABLE #tmpForWhereClause
DROP TABLE #FinalResults
END
