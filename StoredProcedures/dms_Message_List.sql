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
 WHERE id = object_id(N'[dbo].[dms_Message_List]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Message_List] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Message_List]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
  
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
MessageIDOperator="-1" 
MessageScopeOperator="-1" 
MessageTypeOperator="-1" 
SubjectOperator="-1" 
MessageTextOperator="-1" 
StartDateOperator="-1" 
EndDateOperator="-1" 
SequenceOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
MessageIDOperator INT NOT NULL,
MessageIDValue int NULL,
MessageScopeOperator INT NOT NULL,
MessageScopeValue nvarchar(50) NULL,
MessageTypeOperator INT NOT NULL,
MessageTypeValue nvarchar(50) NULL,
SubjectOperator INT NOT NULL,
SubjectValue nvarchar(50) NULL,
MessageTextOperator INT NOT NULL,
MessageTextValue nvarchar(50) NULL,
StartDateOperator INT NOT NULL,
StartDateValue datetime NULL,
EndDateOperator INT NOT NULL,
EndDateValue datetime NULL,
SequenceOperator INT NOT NULL,
SequenceValue int NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue BIT NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	MessageID int  NULL ,
	MessageScope nvarchar(50)  NULL ,
	MessageType nvarchar(50)  NULL ,
	Subject nvarchar(255)  NULL ,
	MessageText nvarchar(MAX)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	Sequence int  NULL ,
	IsActive BIT  NULL 
) 

DECLARE @QueryResult TABLE ( 
	MessageID int  NULL ,
	MessageScope nvarchar(50)  NULL ,
	MessageType nvarchar(50)  NULL ,
	Subject nvarchar(255)  NULL ,
	MessageText nvarchar(MAX)  NULL ,
	StartDate datetime  NULL ,
	EndDate datetime  NULL ,
	Sequence int  NULL ,
	IsActive BIT  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(MessageIDOperator,-1),
	MessageIDValue ,
	ISNULL(MessageScopeOperator,-1),
	MessageScopeValue ,
	ISNULL(MessageTypeOperator,-1),
	MessageTypeValue ,
	ISNULL(SubjectOperator,-1),
	SubjectValue ,
	ISNULL(MessageTextOperator,-1),
	MessageTextValue ,
	ISNULL(StartDateOperator,-1),
	StartDateValue ,
	ISNULL(EndDateOperator,-1),
	EndDateValue ,
	ISNULL(SequenceOperator,-1),
	SequenceValue ,
	ISNULL(IsActiveOperator,-1),
	IsActiveValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
MessageIDOperator INT,
MessageIDValue int 
,MessageScopeOperator INT,
MessageScopeValue nvarchar(50) 
,MessageTypeOperator INT,
MessageTypeValue nvarchar(50) 
,SubjectOperator INT,
SubjectValue nvarchar(50) 
,MessageTextOperator INT,
MessageTextValue nvarchar(50) 
,StartDateOperator INT,
StartDateValue datetime 
,EndDateOperator INT,
EndDateValue datetime 
,SequenceOperator INT,
SequenceValue int ,
IsActiveOperator INT,
IsActiveValue BIT
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @QueryResult
SELECT	  m.ID 
		, m.MessageScope	
		, mt.Name AS MessageType
		, m.Subject
		, m.MessageText
		, m.StartDate 
		, m.EndDate
		, m.Sequence
		, m.IsActive
FROM	Message m
JOIN	MessageType mt ON mt.ID = m.MessageTypeID
ORDER BY  m.ID DESC

INSERT INTO @FinalResults
SELECT 
	T.MessageID,
	T.MessageScope,
	T.MessageType,
	CASE WHEN LEN(T.Subject) > 50 THEN SUBSTRING(T.Subject,1,50) + '...' ELSE T.Subject END,
	CASE WHEN LEN(T.MessageText) > 50 THEN SUBSTRING(T.MessageText,1,50) + '...' ELSE T.MessageText END,
	T.StartDate,
	T.EndDate,
	T.Sequence,
	T.IsActive
FROM @QueryResult T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.MessageIDOperator = -1 ) 
 OR 
	 ( TMP.MessageIDOperator = 0 AND T.MessageID IS NULL ) 
 OR 
	 ( TMP.MessageIDOperator = 1 AND T.MessageID IS NOT NULL ) 
 OR 
	 ( TMP.MessageIDOperator = 2 AND T.MessageID = TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 3 AND T.MessageID <> TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 7 AND T.MessageID > TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 8 AND T.MessageID >= TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 9 AND T.MessageID < TMP.MessageIDValue ) 
 OR 
	 ( TMP.MessageIDOperator = 10 AND T.MessageID <= TMP.MessageIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.MessageScopeOperator = -1 ) 
 OR 
	 ( TMP.MessageScopeOperator = 0 AND T.MessageScope IS NULL ) 
 OR 
	 ( TMP.MessageScopeOperator = 1 AND T.MessageScope IS NOT NULL ) 
 OR 
	 ( TMP.MessageScopeOperator = 2 AND T.MessageScope = TMP.MessageScopeValue ) 
 OR 
	 ( TMP.MessageScopeOperator = 3 AND T.MessageScope <> TMP.MessageScopeValue ) 
 OR 
	 ( TMP.MessageScopeOperator = 4 AND T.MessageScope LIKE TMP.MessageScopeValue + '%') 
 OR 
	 ( TMP.MessageScopeOperator = 5 AND T.MessageScope LIKE '%' + TMP.MessageScopeValue ) 
 OR 
	 ( TMP.MessageScopeOperator = 6 AND T.MessageScope LIKE '%' + TMP.MessageScopeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MessageTypeOperator = -1 ) 
 OR 
	 ( TMP.MessageTypeOperator = 0 AND T.MessageType IS NULL ) 
 OR 
	 ( TMP.MessageTypeOperator = 1 AND T.MessageType IS NOT NULL ) 
 OR 
	 ( TMP.MessageTypeOperator = 2 AND T.MessageType = TMP.MessageTypeValue ) 
 OR 
	 ( TMP.MessageTypeOperator = 3 AND T.MessageType <> TMP.MessageTypeValue ) 
 OR 
	 ( TMP.MessageTypeOperator = 4 AND T.MessageType LIKE TMP.MessageTypeValue + '%') 
 OR 
	 ( TMP.MessageTypeOperator = 5 AND T.MessageType LIKE '%' + TMP.MessageTypeValue ) 
 OR 
	 ( TMP.MessageTypeOperator = 6 AND T.MessageType LIKE '%' + TMP.MessageTypeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SubjectOperator = -1 ) 
 OR 
	 ( TMP.SubjectOperator = 0 AND T.Subject IS NULL ) 
 OR 
	 ( TMP.SubjectOperator = 1 AND T.Subject IS NOT NULL ) 
 OR 
	 ( TMP.SubjectOperator = 2 AND T.Subject = TMP.SubjectValue ) 
 OR 
	 ( TMP.SubjectOperator = 3 AND T.Subject <> TMP.SubjectValue ) 
 OR 
	 ( TMP.SubjectOperator = 4 AND T.Subject LIKE TMP.SubjectValue + '%') 
 OR 
	 ( TMP.SubjectOperator = 5 AND T.Subject LIKE '%' + TMP.SubjectValue ) 
 OR 
	 ( TMP.SubjectOperator = 6 AND T.Subject LIKE '%' + TMP.SubjectValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.MessageTextOperator = -1 ) 
 OR 
	 ( TMP.MessageTextOperator = 0 AND T.MessageText IS NULL ) 
 OR 
	 ( TMP.MessageTextOperator = 1 AND T.MessageText IS NOT NULL ) 
 OR 
	 ( TMP.MessageTextOperator = 2 AND T.MessageText = TMP.MessageTextValue ) 
 OR 
	 ( TMP.MessageTextOperator = 3 AND T.MessageText <> TMP.MessageTextValue ) 
 OR 
	 ( TMP.MessageTextOperator = 4 AND T.MessageText LIKE TMP.MessageTextValue + '%') 
 OR 
	 ( TMP.MessageTextOperator = 5 AND T.MessageText LIKE '%' + TMP.MessageTextValue ) 
 OR 
	 ( TMP.MessageTextOperator = 6 AND T.MessageText LIKE '%' + TMP.MessageTextValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.StartDateOperator = -1 ) 
 OR 
	 ( TMP.StartDateOperator = 0 AND T.StartDate IS NULL ) 
 OR 
	 ( TMP.StartDateOperator = 1 AND T.StartDate IS NOT NULL ) 
 OR 
	 ( TMP.StartDateOperator = 2 AND T.StartDate = TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 3 AND T.StartDate <> TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 7 AND T.StartDate > TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 8 AND T.StartDate >= TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 9 AND T.StartDate < TMP.StartDateValue ) 
 OR 
	 ( TMP.StartDateOperator = 10 AND T.StartDate <= TMP.StartDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.EndDateOperator = -1 ) 
 OR 
	 ( TMP.EndDateOperator = 0 AND T.EndDate IS NULL ) 
 OR 
	 ( TMP.EndDateOperator = 1 AND T.EndDate IS NOT NULL ) 
 OR 
	 ( TMP.EndDateOperator = 2 AND T.EndDate = TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 3 AND T.EndDate <> TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 7 AND T.EndDate > TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 8 AND T.EndDate >= TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 9 AND T.EndDate < TMP.EndDateValue ) 
 OR 
	 ( TMP.EndDateOperator = 10 AND T.EndDate <= TMP.EndDateValue ) 

 ) 

 AND 

 ( 
	 ( TMP.SequenceOperator = -1 ) 
 OR 
	 ( TMP.SequenceOperator = 0 AND T.Sequence IS NULL ) 
 OR 
	 ( TMP.SequenceOperator = 1 AND T.Sequence IS NOT NULL ) 
 OR 
	 ( TMP.SequenceOperator = 2 AND T.Sequence = TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 3 AND T.Sequence <> TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 7 AND T.Sequence > TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 8 AND T.Sequence >= TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 9 AND T.Sequence < TMP.SequenceValue ) 
 OR 
	 ( TMP.SequenceOperator = 10 AND T.Sequence <= TMP.SequenceValue ) 

 ) 
 AND 

 ( 
	 ( TMP.IsActiveOperator = -1 ) 
 OR 
	 ( TMP.IsActiveOperator = 0 AND T.IsActive IS NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 1 AND T.IsActive IS NOT NULL ) 
 OR 
	 ( TMP.IsActiveOperator = 2 AND T.IsActive = TMP.IsActiveValue	 ) 
 OR 
	 ( TMP.IsActiveOperator = 3 AND T.IsActive <> TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 7 AND T.IsActive > TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 8 AND T.IsActive >= TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 9 AND T.IsActive < TMP.IsActiveValue ) 
 OR 
	 ( TMP.IsActiveOperator = 10 AND T.IsActive <= TMP.IsActiveValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'MessageID' AND @sortOrder = 'ASC'
	 THEN T.MessageID END ASC, 
	 CASE WHEN @sortColumn = 'MessageID' AND @sortOrder = 'DESC'
	 THEN T.MessageID END DESC ,

	 CASE WHEN @sortColumn = 'MessageScope' AND @sortOrder = 'ASC'
	 THEN T.MessageScope END ASC, 
	 CASE WHEN @sortColumn = 'MessageScope' AND @sortOrder = 'DESC'
	 THEN T.MessageScope END DESC ,

	 CASE WHEN @sortColumn = 'MessageType' AND @sortOrder = 'ASC'
	 THEN T.MessageType END ASC, 
	 CASE WHEN @sortColumn = 'MessageType' AND @sortOrder = 'DESC'
	 THEN T.MessageType END DESC ,

	 CASE WHEN @sortColumn = 'Subject' AND @sortOrder = 'ASC'
	 THEN T.Subject END ASC, 
	 CASE WHEN @sortColumn = 'Subject' AND @sortOrder = 'DESC'
	 THEN T.Subject END DESC ,

	 CASE WHEN @sortColumn = 'MessageText' AND @sortOrder = 'ASC'
	 THEN T.MessageText END ASC, 
	 CASE WHEN @sortColumn = 'MessageText' AND @sortOrder = 'DESC'
	 THEN T.MessageText END DESC ,

	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'ASC'
	 THEN T.StartDate END ASC, 
	 CASE WHEN @sortColumn = 'StartDate' AND @sortOrder = 'DESC'
	 THEN T.StartDate END DESC ,

	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'ASC'
	 THEN T.EndDate END ASC, 
	 CASE WHEN @sortColumn = 'EndDate' AND @sortOrder = 'DESC'
	 THEN T.EndDate END DESC ,

	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'ASC'
	 THEN T.Sequence END ASC, 
	 CASE WHEN @sortColumn = 'Sequence' AND @sortOrder = 'DESC'
	 THEN T.Sequence END DESC ,

	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'ASC'
	 THEN T.IsActive END ASC, 
	 CASE WHEN @sortColumn = 'IsActive' AND @sortOrder = 'DESC'
	 THEN T.IsActive END DESC 


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
