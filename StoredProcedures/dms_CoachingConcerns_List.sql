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
 WHERE id = object_id(N'[dbo].[dms_CoachingConcerns_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CoachingConcerns_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_CoachingConcerns_List]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 

BEGIN 

IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter></Filter></ROW>'
END



DECLARE @Filters AS TABLE(
	NameOperator NVARCHAR(50) NULL,
	NameType NVARCHAR(50) NULL,
	NameValue NVARCHAR(50) NULL,
	ConcernTypeList NVARCHAR(200) NULL,
	ConcernID INT NULL,
	ConcernTypeID INT NULL)

INSERT INTO @Filters
SELECT  
	ISNULL(T.c.value('@NameOperator','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@NameType','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@NameValue','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@ConcernTypeList','NVARCHAR(200)'),NULL),
	ISNULL(T.c.value('@ConcernID','INT'),NULL),
	ISNULL(T.c.value('@ConcernTypeID','INT'),NULL)
FROM  @whereClauseXML.nodes('/ROW/Filter') T(c)


DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	UserName nvarchar(50)  NULL ,
	Concern nvarchar(50)  NULL ,
	Coached nvarchar(50)  NULL ,
	TeamManager nvarchar(50)  NULL ,
	Area nvarchar(50)  NULL ,
	CreateDate datetime  NULL ,
	Documents nvarchar(50)  NULL 
) 


DECLARE @QueryResults TABLE ( 
	ID int  NULL ,
	UserName nvarchar(50)  NULL ,
	Concern nvarchar(50)  NULL ,
	Coached nvarchar(50)  NULL ,
	TeamManager nvarchar(50)  NULL ,
	Area nvarchar(50)  NULL ,
	CreateDate datetime  NULL ,
	Documents nvarchar(50)  NULL 
) 


INSERT INTO @QueryResults
SELECT CC.ID,
	   CC.AgentUserName UserName,
	   C.Description Concern,
	   CASE ISNULL(CC.IsCoached,0) WHEN 0 THEN 'No' ELSE 'Yes' END Coached,
	   CC.TeamManager,
	   '' AS Area,
	   CC.CreateDate,
	   '' AS Documents
FROM CoachingConcern CC  WITH (NOLOCK)
LEFT JOIN Concern C ON CC.ConcernID = C.ID,@Filters FL
WHERE ((FL.ConcernTypeID IS NULL) OR (FL.ConcernTypeID IS NOT NULL AND CC.ConcernTypeID = FL.ConcernTypeID))
AND   ((FL.ConcernID IS NULL) OR (FL.ConcernID IS NOT NULL AND CC.ConcernID = FL.ConcernID))
AND   ((FL.ConcernTypeList IS NULL) OR (FL.ConcernTypeList IS NOT NULL AND CC.ConcernTypeID IN (select item from dbo.fnSplitString(FL.ConcernTypeList,','))))
AND   ((FL.NameValue IS NULL) OR (FL.NameType = 'User' AND FL.NameOperator = 'eq' AND CC.AgentUserName = FL.NameValue ) 
							  OR (FL.NameType = 'User' AND FL.NameOperator = 'begins' AND CC.AgentUserName LIKE FL.NameValue + '%'  )
							  OR (FL.NameType = 'User' AND FL.NameOperator = 'contains' AND CC.AgentUserName LIKE '%'  + FL.NameValue + '%')
							  OR (FL.NameType = 'User' AND FL.NameOperator = 'endwith' AND CC.AgentUserName LIKE '%' + FL.NameValue )
							  OR (FL.NameType = 'Manager' AND FL.NameOperator = 'eq' AND CC.TeamManager = FL.NameValue ) 
							  OR (FL.NameType = 'Manager' AND FL.NameOperator = 'begins' AND CC.TeamManager LIKE FL.NameValue + '%'  )
							  OR (FL.NameType = 'Manager' AND FL.NameOperator = 'contains' AND CC.TeamManager LIKE '%'  + FL.NameValue + '%')
							  OR (FL.NameType = 'Manager' AND FL.NameOperator = 'endwith' AND CC.TeamManager LIKE '%' + FL.NameValue ))

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.UserName,
	T.Concern,
	T.Coached,
	T.TeamManager,
	T.Area,
	T.CreateDate,
	T.Documents
FROM @QueryResults T

 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'ASC'
	 THEN T.UserName END ASC, 
	 CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'DESC'
	 THEN T.UserName END DESC ,

	 CASE WHEN @sortColumn = 'Concern' AND @sortOrder = 'ASC'
	 THEN T.Concern END ASC, 
	 CASE WHEN @sortColumn = 'Concern' AND @sortOrder = 'DESC'
	 THEN T.Concern END DESC ,

	 CASE WHEN @sortColumn = 'Coached' AND @sortOrder = 'ASC'
	 THEN T.Coached END ASC, 
	 CASE WHEN @sortColumn = 'Coached' AND @sortOrder = 'DESC'
	 THEN T.Coached END DESC ,

	 CASE WHEN @sortColumn = 'TeamManager' AND @sortOrder = 'ASC'
	 THEN T.TeamManager END ASC, 
	 CASE WHEN @sortColumn = 'TeamManager' AND @sortOrder = 'DESC'
	 THEN T.TeamManager END DESC ,

	 CASE WHEN @sortColumn = 'Area' AND @sortOrder = 'ASC'
	 THEN T.Area END ASC, 
	 CASE WHEN @sortColumn = 'Area' AND @sortOrder = 'DESC'
	 THEN T.Area END DESC ,

	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'ASC'
	 THEN T.CreateDate END ASC, 
	 CASE WHEN @sortColumn = 'CreateDate' AND @sortOrder = 'DESC'
	 THEN T.CreateDate END DESC 


DECLARE @count INT   
SET @count = 0   
SELECT @count = MAX(RowNum) FROM @FinalResults
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

SELECT @count AS TotalRows, * FROM @FinalResults WHERE RowNum BETWEEN @startInd AND @endInd

END
