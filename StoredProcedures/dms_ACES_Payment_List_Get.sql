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

WhereClauseXML : 

'<ROW><Filter 
CheckNumber=""
CheckDateFrom=""
CheckDateTo=""
AmountFrom=""
AmountTo=""
CreateBy=""
CreateDateFrom=""
CreateDateTo=""
 ></Filter></ROW>'
 
*******************/
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ACES_Payment_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ACES_Payment_List_Get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_ACES_Payment_List_Get
 CREATE PROCEDURE [dbo].[dms_ACES_Payment_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = 'RecievedDate' 
 , @sortOrder nvarchar(100) = 'DESC' 
  
 ) 
 AS 
 BEGIN 
	SET FMTONLY OFF
 	SET NOCOUNT ON

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
CheckNumber NVARCHAR(100) NULL,
CheckDateFrom DATETIME NULL,
CheckDateTo DATETIME NULL,
AmountFrom MONEY NULL,
AmountTo MONEY NULL,
CreateBy NVARCHAR(50) NULL,
CreateDateFrom DATETIME NULL,
CreateDateTo DATETIME NULL
)

 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	PaymentType nvarchar(100)  NULL ,
	CheckNumber nvarchar(100)  NULL ,
	CheckDate datetime  NULL ,
	TotalAmount money  NULL ,
	RecievedDate datetime  NULL ,
	Comment nvarchar(100)  NULL ,
	CreateBy nvarchar(100)  NULL ,
	CreateDate datetime  NULL ,
	ModifyBy nvarchar(100)  NULL ,
	ModifyDate datetime  NULL,
	PaymentBalance money NULL
) 



INSERT INTO #tmpForWhereClause
SELECT  
	T.c.value('@CheckNumber','NVARCHAR(50)'),
	T.c.value('@CheckDateFrom','DATETIME') ,
	T.c.value('@CheckDateTo','DATETIME'),
	T.c.value('@AmountFrom','MONEY') ,
	T.c.value('@AmountTo','MONEY'),
	T.c.value('@CreateBy','NVARCHAR(50)') ,
	T.c.value('@CreateDateFrom','DATETIME'),
	T.c.value('@CreateDateTo','DATETIME')	
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT		CP.ID
			,PT.Name AS PaymentType
			, CP.CheckNumber
			, CP.CheckDate  
			, CP.TotalAmount 
			, CP.RecievedDate
			, CP.Comment
			, CP.CreateBy
			, CP.CreateDate
			, CP.ModifyBy
			, CP.ModifyDate
			,(SELECT TOP 1 PaymentBalance FROM Client WITH(NOLOCK) WHERE Name='Ford') PaymentBalance
FROM		ClientPayment CP WITH(NOLOCK)
LEFT JOIN	PaymentType PT WITH(NOLOCK) ON PT.ID = CP.PaymentTypeID
LEFT JOIN	#tmpForWhereClause T ON 1=1
WHERE	CP.IsActive=1
AND		( T.AmountFrom IS NULL OR CP.TotalAmount >= T.AmountFrom)
AND		(T.AmountTo IS NULL OR CP.TotalAmount <= T.AmountTo)
AND		(LEN(ISNULL(T.CheckNumber,'')) = 0 OR CP.CheckNumber = T.CheckNumber)
AND		(T.CheckDateFrom IS NULL OR CP.CheckDate >= T.CheckDateFrom)
AND		(T.CheckDateTo IS NULL OR CP.CheckDate <= DATEADD(DD,1,T.CheckDateTo))
AND		(LEN(ISNULL(T.CreateBy,'')) = 0 OR CP.CreateBy = T.CreateBy)
AND		(T.CreateDateFrom IS NULL OR CP.CreateDate >= T.CreateDateFrom)
AND		(T.CreateDateTo IS NULL OR CP.CreateDate <= DATEADD(DD,1,T.CreateDateTo))		 
ORDER BY
	CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'ASC'
    THEN PT.Name END ASC, 
    CASE WHEN @sortColumn = 'PaymentType' AND @sortOrder = 'DESC'
    THEN PT.Name END DESC ,

	CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'ASC'
    THEN CP.CheckNumber END ASC, 
    CASE WHEN @sortColumn = 'CheckNumber' AND @sortOrder = 'DESC'
    THEN CP.CheckNumber END DESC ,

	CASE WHEN @sortColumn = 'CheckDate' AND @sortOrder = 'ASC'
    THEN CP.CheckDate END ASC, 
    CASE WHEN @sortColumn = 'CheckDate' AND @sortOrder = 'DESC'
    THEN CP.CheckDate END DESC ,

	CASE WHEN @sortColumn = 'TotalAmountRequired' AND @sortOrder = 'ASC'
    THEN CP.TotalAmount END ASC, 
    CASE WHEN @sortColumn = 'TotalAmountRequired' AND @sortOrder = 'DESC'
    THEN CP.TotalAmount END DESC ,

	CASE WHEN @sortColumn = 'RecievedDate' AND @sortOrder = 'ASC'
    THEN CP.RecievedDate END ASC, 
    CASE WHEN @sortColumn = 'RecievedDate' AND @sortOrder = 'DESC'
    THEN CP.RecievedDate END DESC ,

	CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'ASC'
    THEN CP.Comment END ASC, 
    CASE WHEN @sortColumn = 'Comment' AND @sortOrder = 'DESC'
    THEN CP.Comment END DESC ,

	CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'ASC'
    THEN CP.CreateBy END ASC, 
    CASE WHEN @sortColumn = 'CreateBy' AND @sortOrder = 'DESC'
    THEN CP.CreateBy END DESC ,

	CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
    THEN CP.CreateDate END ASC, 
    CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
    THEN CP.CreateDate END DESC 



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
