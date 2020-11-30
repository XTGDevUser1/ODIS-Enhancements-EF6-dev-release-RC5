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
 WHERE id = object_id(N'[dbo].[dms_Client_Rep_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Client_Rep_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Client_Rep_List_Get]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	SET FMTONLY OFF

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
RepNameOperator="-1" 
EmailOperator="-1" 
PhoneNumberOperator="-1" 
IsActiveOperator="-1" 
TitleOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
RepNameOperator INT NOT NULL,
RepNameValue nvarchar(100) NULL,
EmailOperator INT NOT NULL,
EmailValue nvarchar(100) NULL,
PhoneNumberOperator INT NOT NULL,
PhoneNumberValue nvarchar(100) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue bit NULL,
TitleOperator INT NOT NULL,
TitleValue nvarchar(100) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	RepName nvarchar(100)  NULL ,
	Email nvarchar(100)  NULL ,
	PhoneNumber nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	Title nvarchar(100)  NULL
) 

 CREATE TABLE #tmpFinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	RepName nvarchar(100)  NULL ,
	Email nvarchar(100)  NULL ,
	PhoneNumber nvarchar(100)  NULL ,
	IsActive bit  NULL ,
	Title nvarchar(100)  NULL
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@RepNameOperator','INT'),-1),
	T.c.value('@RepNameValue','nvarchar(100)') ,
	ISNULL(T.c.value('@EmailOperator','INT'),-1),
	T.c.value('@EmailValue','nvarchar(100)') ,
	ISNULL(T.c.value('@PhoneNumberOperator','INT'),-1),
	T.c.value('@PhoneNumberValue','nvarchar(100)') ,
	ISNULL(T.c.value('@IsActiveOperator','INT'),-1),
	T.c.value('@IsActiveValue','bit') ,
	ISNULL(T.c.value('@TitleOperator','INT'),-1),
	T.c.value('@TitleValue','nvarchar(100)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO #tmpFinalResults
SELECT 
	CR.ID,
	CR.FirstName + ' ' + CR.LastName AS RepName,
	CR.Email,
	CR.PhoneNumber,
	CR.IsActive,
	CR.Title
FROM ClientRep CR
where CR.IsActive=1

INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.RepName,
	T.Email,
	T.PhoneNumber,
	T.IsActive,
	T.Title
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
	 ( TMP.RepNameOperator = -1 ) 
 OR 
	 ( TMP.RepNameOperator = 0 AND T.RepName IS NULL ) 
 OR 
	 ( TMP.RepNameOperator = 1 AND T.RepName IS NOT NULL ) 
 OR 
	 ( TMP.RepNameOperator = 2 AND T.RepName = TMP.RepNameValue ) 
 OR 
	 ( TMP.RepNameOperator = 3 AND T.RepName <> TMP.RepNameValue ) 
 OR 
	 ( TMP.RepNameOperator = 4 AND T.RepName LIKE TMP.RepNameValue + '%') 
 OR 
	 ( TMP.RepNameOperator = 5 AND T.RepName LIKE '%' + TMP.RepNameValue ) 
 OR 
	 ( TMP.RepNameOperator = 6 AND T.RepName LIKE '%' + TMP.RepNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.EmailOperator = -1 ) 
 OR 
	 ( TMP.EmailOperator = 0 AND T.Email IS NULL ) 
 OR 
	 ( TMP.EmailOperator = 1 AND T.Email IS NOT NULL ) 
 OR 
	 ( TMP.EmailOperator = 2 AND T.Email = TMP.EmailValue ) 
 OR 
	 ( TMP.EmailOperator = 3 AND T.Email <> TMP.EmailValue ) 
 OR 
	 ( TMP.EmailOperator = 4 AND T.Email LIKE TMP.EmailValue + '%') 
 OR 
	 ( TMP.EmailOperator = 5 AND T.Email LIKE '%' + TMP.EmailValue ) 
 OR 
	 ( TMP.EmailOperator = 6 AND T.Email LIKE '%' + TMP.EmailValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PhoneNumberOperator = -1 ) 
 OR 
	 ( TMP.PhoneNumberOperator = 0 AND T.PhoneNumber IS NULL ) 
 OR 
	 ( TMP.PhoneNumberOperator = 1 AND T.PhoneNumber IS NOT NULL ) 
 OR 
	 ( TMP.PhoneNumberOperator = 2 AND T.PhoneNumber = TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 3 AND T.PhoneNumber <> TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 4 AND T.PhoneNumber LIKE TMP.PhoneNumberValue + '%') 
 OR 
	 ( TMP.PhoneNumberOperator = 5 AND T.PhoneNumber LIKE '%' + TMP.PhoneNumberValue ) 
 OR 
	 ( TMP.PhoneNumberOperator = 6 AND T.PhoneNumber LIKE '%' + TMP.PhoneNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 ) 

  AND 

 ( 
	 ( TMP.TitleOperator = -1 ) 
 OR 
	 ( TMP.TitleOperator = 0 AND T.Title IS NULL ) 
 OR 
	 ( TMP.TitleOperator = 1 AND T.Title IS NOT NULL ) 
 OR 
	 ( TMP.TitleOperator = 2 AND T.Title = TMP.TitleValue ) 
 OR 
	 ( TMP.TitleOperator = 3 AND T.Title <> TMP.TitleValue ) 
 OR 
	 ( TMP.TitleOperator = 4 AND T.Title LIKE TMP.TitleValue + '%') 
 OR 
	 ( TMP.TitleOperator = 5 AND T.Title LIKE '%' + TMP.TitleValue ) 
 OR 
	 ( TMP.TitleOperator = 6 AND T.Title LIKE '%' + TMP.TitleValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'RepName' AND @sortOrder = 'ASC'
	 THEN T.RepName END ASC, 
	 CASE WHEN @sortColumn = 'RepName' AND @sortOrder = 'DESC'
	 THEN T.RepName END DESC ,

	 CASE WHEN @sortColumn = 'Email' AND @sortOrder = 'ASC'
	 THEN T.Email END ASC, 
	 CASE WHEN @sortColumn = 'Email' AND @sortOrder = 'DESC'
	 THEN T.Email END DESC ,

	 CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'ASC'
	 THEN T.PhoneNumber END ASC, 
	 CASE WHEN @sortColumn = 'PhoneNumber' AND @sortOrder = 'DESC'
	 THEN T.PhoneNumber END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC ,

	 CASE WHEN @sortColumn = 'Title' AND @sortOrder = 'ASC'
	 THEN T.Title END ASC, 
	 CASE WHEN @sortColumn = 'Title' AND @sortOrder = 'DESC'
	 THEN T.Title END DESC 


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
