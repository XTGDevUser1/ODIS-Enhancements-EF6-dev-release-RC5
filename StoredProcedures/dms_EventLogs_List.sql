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
 WHERE id = object_id(N'[dbo].[dms_EventLogList]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_EventLogList] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_EventLogList]( 
   @whereClauseXML XML = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC') 
 AS 
 BEGIN 
  
SET NOCOUNT ON

DECLARE @Filters AS TABLE(
	UserName NVARCHAR(50) NULL,
	FromDate DATE NULL,
	ToDate DATE NULL,
	EventCategoryID INT NULL,
	EventTypeID INT NULL,
	EventID INT NULL)

INSERT INTO @Filters
SELECT  
	ISNULL(T.c.value('@UserName','NVARCHAR(50)'),NULL),
	ISNULL(T.c.value('@FromDate','DATE'),NULL),
	ISNULL(T.c.value('@ToDate','DATE'),NULL),
	ISNULL(T.c.value('@EventCategoryID','INT'),NULL),
	ISNULL(T.c.value('@EventTypeID','INT'),NULL),
	ISNULL(T.c.value('@EventID','INT'),NULL)
FROM  @whereClauseXML.nodes('/ROW/Filter') T(c)


DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	EventLogID int  NULL ,
	SessionID nvarchar(100)  NULL ,
	Description nvarchar(MAX)  NULL ,
	Data nvarchar(MAX)  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(50)  NULL 
) 

DECLARE @QueryResult TABLE ( 
	EventLogID int  NULL ,
	SessionID nvarchar(100)  NULL ,
	Description nvarchar(MAX)  NULL ,
	Data nvarchar(MAX)  NULL ,
	CreateDate datetime  NULL ,
	CreateBy nvarchar(50)  NULL 
) 

INSERT INTO @QueryResult
SELECT	      el.ID
			, el.SessionID
			, el.Description
			, el.Data
			, el.CreateDate
			, el.CreateBy
FROM	    EventLog el WITH (NOLOCK)
JOIN	    Event e  WITH (NOLOCK) ON e.ID = el.EventID,@Filters FL
WHERE       ((FL.UserName IS NULL) OR (FL.UserName IS NOT NULL AND el.CreateBy = FL.UserName))
AND			((FL.EventCategoryID IS NULL) OR (FL.EventCategoryID IS NOT NULL AND e.EventCategoryID = FL.EventCategoryID))
AND			((FL.EventTypeID IS NULL) OR (FL.EventTypeID IS NOT NULL AND e.EventTypeID = FL.EventTypeID))
AND			((FL.EventID IS NULL) OR (FL.EventID IS NOT NULL AND e.ID = FL.EventID))
AND			((FL.FromDate IS NULL) OR (FL.FromDate IS NOT NULL AND el.CreateDate >= FL.FromDate))
AND			((FL.ToDate IS NULL) OR (FL.ToDate IS NOT NULL AND el.CreateDate <= FL.ToDate))


--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults
SELECT 
	T.EventLogID,
	T.SessionID,
	T.Description,
	T.Data,
	T.CreateDate,
	T.CreateBy
FROM @QueryResult T
WHERE ( 1 = 1 )
	 
	 ORDER BY 
	 CASE WHEN @sortColumn = 'EventLogID' AND @sortOrder = 'ASC'
	 THEN T.EventLogID END ASC, 
	 CASE WHEN @sortColumn = 'EventLogID' AND @sortOrder = 'DESC'
	 THEN T.EventLogID END DESC ,

	 CASE WHEN @sortColumn = 'SessionID' AND @sortOrder = 'ASC'
	 THEN T.SessionID END ASC, 
	 CASE WHEN @sortColumn = 'SessionID' AND @sortOrder = 'DESC'
	 THEN T.SessionID END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'Data' AND @sortOrder = 'ASC'
	 THEN T.Data END ASC, 
	 CASE WHEN @sortColumn = 'Data' AND @sortOrder = 'DESC'
	 THEN T.Data END DESC ,

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
