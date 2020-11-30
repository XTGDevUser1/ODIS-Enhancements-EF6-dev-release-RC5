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
 WHERE id = object_id(N'[dbo].[dms_CustomerFeedback_Details_Get]') AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CustomerFeedback_Details_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 /*
	EXEC [dms_CustomerFeedback_Details_Get] @customerFeedbackId = 15
 */

 CREATE PROCEDURE [dbo].[dms_CustomerFeedback_Details_Get](
   @customerFeedbackId int = NULL
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @whereClauseXML XML = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
	SET FMTONLY OFF
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
CustomerFeedbackIdOperator="-1" 
FeedbackTypeDescriptionOperator="-1" 
FeedbackCategoryDescriptionOperator="-1" 
FeedbackSubCategroyDescriptionOperator="-1" 
FeedbackDetailResolutionDescriptionOperator="-1" 
 ></Filter></ROW>'
END

CREATE TABLE #tmpForWhereClause
(
IDOperator INT NOT NULL,
IDValue int NULL,
CustomerFeedbackIdOperator INT NOT NULL,
CustomerFeedbackIdValue int NULL,
FeedbackTypeDescriptionOperator INT NOT NULL,
FeedbackTypeDescriptionValue nvarchar(100) NULL,
FeedbackCategoryDescriptionOperator INT NOT NULL,
FeedbackCategoryDescriptionValue nvarchar(100) NULL,
FeedbackSubCategroyDescriptionOperator INT NOT NULL,
FeedbackSubCategroyDescriptionValue nvarchar(100) NULL,
FeedbackDetailResolutionDescriptionOperator INT NOT NULL,
FeedbackDetailResolutionDescriptionValue nvarchar(MAX) NULL
)
 CREATE TABLE #FinalResults( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	CustomerFeedbackId int  NULL ,
	FeedbackTypeDescription nvarchar(100)  NULL ,
	FeedbackCategoryDescription nvarchar(100)  NULL ,
	FeedbackSubCategroyDescription nvarchar(100)  NULL ,
	FeedbackDetailResolutionDescription nvarchar(MAX)  NULL 
) 

 CREATE TABLE #QueryResult ( 
	ID int  NULL ,
	CustomerFeedbackId int  NULL ,
	FeedbackTypeDescription nvarchar(100)  NULL ,
	FeedbackCategoryDescription nvarchar(100)  NULL ,
	FeedbackSubCategroyDescription nvarchar(100)  NULL ,
	FeedbackDetailResolutionDescription nvarchar(MAX)  NULL 
) 

INSERT INTO #tmpForWhereClause
SELECT  
	ISNULL(T.c.value('@IDOperator','INT'),-1),
	T.c.value('@IDValue','int') ,
	ISNULL(T.c.value('@CustomerFeedbackIdOperator','INT'),-1),
	T.c.value('@CustomerFeedbackIdValue','int') ,
	ISNULL(T.c.value('@FeedbackTypeDescriptionOperator','INT'),-1),
	T.c.value('@FeedbackTypeDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@FeedbackCategoryDescriptionOperator','INT'),-1),
	T.c.value('@FeedbackCategoryDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@FeedbackSubCategroyDescriptionOperator','INT'),-1),
	T.c.value('@FeedbackSubCategroyDescriptionValue','nvarchar(100)') ,
	ISNULL(T.c.value('@FeedbackDetailResolutionDescriptionOperator','INT'),-1),
	T.c.value('@FeedbackDetailResolutionDescriptionValue','nvarchar(MAX)') 
FROM @whereClauseXML.nodes('/ROW/Filter') T(c)

--------------------- BEGIN -----------------------------
INSERT INTO #QueryResult
SELECT 
		CD.ID,
		CF.ID,
		CT.Description,
		CC.Description,
		CSC.Description,
		CD.ResolutionDescription				
FROM
	CustomerFeedbackDetail CD	
	INNER JOIN CustomerFeedback CF WITH(NOLOCK) ON CF.ID = CD.CustomerFeedbackID
	INNER JOIN CustomerFeedbackType CT WITH(NOLOCK) ON CT.ID = CD.CustomerFeedbackTypeID
	INNER JOIN CustomerFeedbackCategory CC WITH(NOLOCK) ON CC.ID = CD.CustomerFeedbackCategoryID
	LEFT JOIN CustomerFeedbackSubCategory CSC WITH(NOLOCK) ON CSC.ID = CD.CustomerFeedbackSubCategoryID
WHERE
	CF.ID = @customerFeedbackId
--------------------- END -----------------------------
INSERT INTO #FinalResults
SELECT 
	T.ID,
	T.CustomerFeedbackId,
	T.FeedbackTypeDescription,
	T.FeedbackCategoryDescription,
	T.FeedbackSubCategroyDescription,
	T.FeedbackDetailResolutionDescription
FROM #QueryResult T,
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
	 ( TMP.CustomerFeedbackIdOperator = -1 ) 
 OR 
	 ( TMP.CustomerFeedbackIdOperator = 0 AND T.CustomerFeedbackId IS NULL ) 
 OR 
	 ( TMP.CustomerFeedbackIdOperator = 1 AND T.CustomerFeedbackId IS NOT NULL ) 
 OR 
	 ( TMP.CustomerFeedbackIdOperator = 2 AND T.CustomerFeedbackId = TMP.CustomerFeedbackIdValue ) 
 OR 
	 ( TMP.CustomerFeedbackIdOperator = 3 AND T.CustomerFeedbackId <> TMP.CustomerFeedbackIdValue ) 
 OR 
	 ( TMP.CustomerFeedbackIdOperator = 7 AND T.CustomerFeedbackId > TMP.CustomerFeedbackIdValue ) 
 OR 
	 ( TMP.CustomerFeedbackIdOperator = 8 AND T.CustomerFeedbackId >= TMP.CustomerFeedbackIdValue ) 
 OR 
	 ( TMP.CustomerFeedbackIdOperator = 9 AND T.CustomerFeedbackId < TMP.CustomerFeedbackIdValue ) 
 OR 
	 ( TMP.CustomerFeedbackIdOperator = 10 AND T.CustomerFeedbackId <= TMP.CustomerFeedbackIdValue ) 

 ) 

 AND 

 ( 
	 ( TMP.FeedbackTypeDescriptionOperator = -1 ) 
 OR 
	 ( TMP.FeedbackTypeDescriptionOperator = 0 AND T.FeedbackTypeDescription IS NULL ) 
 OR 
	 ( TMP.FeedbackTypeDescriptionOperator = 1 AND T.FeedbackTypeDescription IS NOT NULL ) 
 OR 
	 ( TMP.FeedbackTypeDescriptionOperator = 2 AND T.FeedbackTypeDescription = TMP.FeedbackTypeDescriptionValue ) 
 OR 
	 ( TMP.FeedbackTypeDescriptionOperator = 3 AND T.FeedbackTypeDescription <> TMP.FeedbackTypeDescriptionValue ) 
 OR 
	 ( TMP.FeedbackTypeDescriptionOperator = 4 AND T.FeedbackTypeDescription LIKE TMP.FeedbackTypeDescriptionValue + '%') 
 OR 
	 ( TMP.FeedbackTypeDescriptionOperator = 5 AND T.FeedbackTypeDescription LIKE '%' + TMP.FeedbackTypeDescriptionValue ) 
 OR 
	 ( TMP.FeedbackTypeDescriptionOperator = 6 AND T.FeedbackTypeDescription LIKE '%' + TMP.FeedbackTypeDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.FeedbackCategoryDescriptionOperator = -1 ) 
 OR 
	 ( TMP.FeedbackCategoryDescriptionOperator = 0 AND T.FeedbackCategoryDescription IS NULL ) 
 OR 
	 ( TMP.FeedbackCategoryDescriptionOperator = 1 AND T.FeedbackCategoryDescription IS NOT NULL ) 
 OR 
	 ( TMP.FeedbackCategoryDescriptionOperator = 2 AND T.FeedbackCategoryDescription = TMP.FeedbackCategoryDescriptionValue ) 
 OR 
	 ( TMP.FeedbackCategoryDescriptionOperator = 3 AND T.FeedbackCategoryDescription <> TMP.FeedbackCategoryDescriptionValue ) 
 OR 
	 ( TMP.FeedbackCategoryDescriptionOperator = 4 AND T.FeedbackCategoryDescription LIKE TMP.FeedbackCategoryDescriptionValue + '%') 
 OR 
	 ( TMP.FeedbackCategoryDescriptionOperator = 5 AND T.FeedbackCategoryDescription LIKE '%' + TMP.FeedbackCategoryDescriptionValue ) 
 OR 
	 ( TMP.FeedbackCategoryDescriptionOperator = 6 AND T.FeedbackCategoryDescription LIKE '%' + TMP.FeedbackCategoryDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.FeedbackSubCategroyDescriptionOperator = -1 ) 
 OR 
	 ( TMP.FeedbackSubCategroyDescriptionOperator = 0 AND T.FeedbackSubCategroyDescription IS NULL ) 
 OR 
	 ( TMP.FeedbackSubCategroyDescriptionOperator = 1 AND T.FeedbackSubCategroyDescription IS NOT NULL ) 
 OR 
	 ( TMP.FeedbackSubCategroyDescriptionOperator = 2 AND T.FeedbackSubCategroyDescription = TMP.FeedbackSubCategroyDescriptionValue ) 
 OR 
	 ( TMP.FeedbackSubCategroyDescriptionOperator = 3 AND T.FeedbackSubCategroyDescription <> TMP.FeedbackSubCategroyDescriptionValue ) 
 OR 
	 ( TMP.FeedbackSubCategroyDescriptionOperator = 4 AND T.FeedbackSubCategroyDescription LIKE TMP.FeedbackSubCategroyDescriptionValue + '%') 
 OR 
	 ( TMP.FeedbackSubCategroyDescriptionOperator = 5 AND T.FeedbackSubCategroyDescription LIKE '%' + TMP.FeedbackSubCategroyDescriptionValue ) 
 OR 
	 ( TMP.FeedbackSubCategroyDescriptionOperator = 6 AND T.FeedbackSubCategroyDescription LIKE '%' + TMP.FeedbackSubCategroyDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.FeedbackDetailResolutionDescriptionOperator = -1 ) 
 OR 
	 ( TMP.FeedbackDetailResolutionDescriptionOperator = 0 AND T.FeedbackDetailResolutionDescription IS NULL ) 
 OR 
	 ( TMP.FeedbackDetailResolutionDescriptionOperator = 1 AND T.FeedbackDetailResolutionDescription IS NOT NULL ) 
 OR 
	 ( TMP.FeedbackDetailResolutionDescriptionOperator = 2 AND T.FeedbackDetailResolutionDescription = TMP.FeedbackDetailResolutionDescriptionValue ) 
 OR 
	 ( TMP.FeedbackDetailResolutionDescriptionOperator = 3 AND T.FeedbackDetailResolutionDescription <> TMP.FeedbackDetailResolutionDescriptionValue ) 
 OR 
	 ( TMP.FeedbackDetailResolutionDescriptionOperator = 4 AND T.FeedbackDetailResolutionDescription LIKE TMP.FeedbackDetailResolutionDescriptionValue + '%') 
 OR 
	 ( TMP.FeedbackDetailResolutionDescriptionOperator = 5 AND T.FeedbackDetailResolutionDescription LIKE '%' + TMP.FeedbackDetailResolutionDescriptionValue ) 
 OR 
	 ( TMP.FeedbackDetailResolutionDescriptionOperator = 6 AND T.FeedbackDetailResolutionDescription LIKE '%' + TMP.FeedbackDetailResolutionDescriptionValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'CustomerFeedbackId' AND @sortOrder = 'ASC'
	 THEN T.CustomerFeedbackId END ASC, 
	 CASE WHEN @sortColumn = 'CustomerFeedbackId' AND @sortOrder = 'DESC'
	 THEN T.CustomerFeedbackId END DESC ,

	 CASE WHEN @sortColumn = 'FeedbackTypeDescription' AND @sortOrder = 'ASC'
	 THEN T.FeedbackTypeDescription END ASC, 
	 CASE WHEN @sortColumn = 'FeedbackTypeDescription' AND @sortOrder = 'DESC'
	 THEN T.FeedbackTypeDescription END DESC ,

	 CASE WHEN @sortColumn = 'FeedbackCategoryDescription' AND @sortOrder = 'ASC'
	 THEN T.FeedbackCategoryDescription END ASC, 
	 CASE WHEN @sortColumn = 'FeedbackCategoryDescription' AND @sortOrder = 'DESC'
	 THEN T.FeedbackCategoryDescription END DESC ,

	 CASE WHEN @sortColumn = 'FeedbackSubCategroyDescription' AND @sortOrder = 'ASC'
	 THEN T.FeedbackSubCategroyDescription END ASC, 
	 CASE WHEN @sortColumn = 'FeedbackSubCategroyDescription' AND @sortOrder = 'DESC'
	 THEN T.FeedbackSubCategroyDescription END DESC ,

	 CASE WHEN @sortColumn = 'FeedbackDetailResolutionDescription' AND @sortOrder = 'ASC'
	 THEN T.FeedbackDetailResolutionDescription END ASC, 
	 CASE WHEN @sortColumn = 'FeedbackDetailResolutionDescription' AND @sortOrder = 'DESC'
	 THEN T.FeedbackDetailResolutionDescription END DESC 


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
DROP TABLE #QueryResult
DROP TABLE #FinalResults
END
