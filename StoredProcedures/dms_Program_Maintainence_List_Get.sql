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
 WHERE id = object_id(N'[dbo].[dms_Program_Maintainence_List_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Maintainence_List_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Maintainence_List_Get]( 
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
SortOperator="-1" 
ClientIDOperator="-1" 
ClientNameOperator="-1" 
ParentProgramIDOperator="-1" 
ParentNameOperator="-1" 
ProgramIDOperator="-1" 
ProgramCodeOperator="-1" 
ProgramNameOperator="-1" 
ProgramDescriptionOperator="-1" 
ProgramIsActiveOperator="-1" 
IsAuditedOperator="-1" 
IsClosedLoopAutomatedOperator="-1" 
IsGroupOperator="-1"
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
SortOperator INT NOT NULL,
SortValue int NULL,
ClientIDOperator INT NOT NULL,
ClientIDValue int NULL,
ClientNameOperator INT NOT NULL,
ClientNameValue nvarchar(50) NULL,
ParentProgramIDOperator INT NOT NULL,
ParentProgramIDValue int NULL,
ParentNameOperator INT NOT NULL,
ParentNameValue nvarchar(50) NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramCodeOperator INT NOT NULL,
ProgramCodeValue nvarchar(50) NULL,
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(50) NULL,
ProgramDescriptionOperator INT NOT NULL,
ProgramDescriptionValue nvarchar(50) NULL,
ProgramIsActiveOperator INT NOT NULL,
ProgramIsActiveValue bit NULL,
IsAuditedOperator INT NOT NULL,
IsAuditedValue bit NULL,
IsClosedLoopAutomatedOperator INT NOT NULL,
IsClosedLoopAutomatedValue bit NULL,
IsGroupOperator INT NOT NULL,
IsGroupValue bit NULL


)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 

DECLARE @FinalResults_Temp TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	Sort int  NULL ,
	ClientID int  NULL ,
	ClientName nvarchar(50)  NULL ,
	ParentProgramID int  NULL ,
	ParentName nvarchar(50)  NULL ,
	ProgramID int  NULL ,
	ProgramCode nvarchar(50)  NULL ,
	ProgramName nvarchar(50)  NULL ,
	ProgramDescription nvarchar(50)  NULL ,
	ProgramIsActive bit  NULL ,
	IsAudited bit  NULL ,
	IsClosedLoopAutomated bit  NULL ,
	IsGroup bit  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(SortOperator,-1),
	SortValue ,
	ISNULL(ClientIDOperator,-1),
	ClientIDValue ,
	ISNULL( ClientNameOperator,-1),
	ClientNameValue ,
	ISNULL(ParentProgramIDOperator,-1),
	ParentProgramIDValue ,
	ISNULL(ParentNameOperator,-1),
	ParentNameValue ,
	ISNULL(ProgramIDOperator,-1),
	ProgramIDValue ,
	ISNULL(ProgramCodeOperator,-1),
	ProgramCodeValue ,
	ISNULL(ProgramNameOperator,-1),
	ProgramNameValue ,
	ISNULL(ProgramDescriptionOperator,-1),
	ProgramDescriptionValue ,
	ISNULL(ProgramIsActiveOperator,-1),
	ProgramIsActiveValue ,
	ISNULL(IsAuditedOperator,-1),
	IsAuditedValue ,
	ISNULL(IsClosedLoopAutomatedOperator,-1),
	IsClosedLoopAutomatedValue ,
	ISNULL(IsGroupOperator,-1),
	IsGroupValue
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
SortOperator INT,
SortValue int 
,ClientIDOperator INT,
ClientIDValue int 
,ClientNameOperator INT,
ClientNameValue nvarchar(50) 
,ParentProgramIDOperator INT,
ParentProgramIDValue int 
,ParentNameOperator INT,
ParentNameValue nvarchar(50) 
,ProgramIDOperator INT,
ProgramIDValue int 
,ProgramCodeOperator INT,
ProgramCodeValue nvarchar(50) 
,ProgramNameOperator INT,
ProgramNameValue nvarchar(50) 
,ProgramDescriptionOperator INT,
ProgramDescriptionValue nvarchar(50) 
,ProgramIsActiveOperator INT,
ProgramIsActiveValue bit 
,IsAuditedOperator INT,
IsAuditedValue bit 
,IsClosedLoopAutomatedOperator INT,
IsClosedLoopAutomatedValue bit 
,IsGroupOperator INT,
IsGroupValue bit 

 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults_Temp
SELECT
CASE
WHEN PP.ID IS NULL THEN P.ID
ELSE PP.ID
END AS Sort
, C.ID AS ClientID
, C.Name AS ClientName
, PP.ID AS ParentProgramID
, PP.Name AS ParentName
, P.ID AS ProgramID
, P.Code AS ProgramCode
, P.Name AS ProgramName
, P.Description AS ProgramDescription
, P.IsActive AS ProgramIsActive
, P.IsAudited AS IsAudited
, P.IsClosedLoopAutomated AS IsClosedLoopAutomated
, P.IsGroup AS IsGroup
--, *
FROM Program P (NOLOCK)
JOIN Client C (NOLOCK) ON C.ID = P.ClientID
LEFT JOIN Program PP (NOLOCK) ON PP.ID = P.ParentProgramID
WHERE C.Name <> 'ARS'
ORDER BY C.Name, Sort, PP.ID, P.ID


INSERT INTO @FinalResults
SELECT 
	T.Sort,
	T.ClientID,
	T.ClientName,
	T.ParentProgramID,
	T.ParentName,
	T.ProgramID,
	T.ProgramCode,
	T.ProgramName,
	T.ProgramDescription,
	T.ProgramIsActive,
	T.IsAudited,
	T.IsClosedLoopAutomated,
	T.IsGroup
FROM @FinalResults_Temp T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.SortOperator = -1 ) 
 OR 
	 ( TMP.SortOperator = 0 AND T.Sort IS NULL ) 
 OR 
	 ( TMP.SortOperator = 1 AND T.Sort IS NOT NULL ) 
 OR 
	 ( TMP.SortOperator = 2 AND T.Sort = TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 3 AND T.Sort <> TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 7 AND T.Sort > TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 8 AND T.Sort >= TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 9 AND T.Sort < TMP.SortValue ) 
 OR 
	 ( TMP.SortOperator = 10 AND T.Sort <= TMP.SortValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ClientIDOperator = -1 ) 
 OR 
	 ( TMP.ClientIDOperator = 0 AND T.ClientID IS NULL ) 
 OR 
	 ( TMP.ClientIDOperator = 1 AND T.ClientID IS NOT NULL ) 
 OR 
	 ( TMP.ClientIDOperator = 2 AND T.ClientID = TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 3 AND T.ClientID <> TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 7 AND T.ClientID > TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 8 AND T.ClientID >= TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 9 AND T.ClientID < TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 10 AND T.ClientID <= TMP.ClientIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ClientNameOperator = -1 ) 
 OR 
	 ( TMP.ClientNameOperator = 0 AND T.ClientName IS NULL ) 
 OR 
	 ( TMP.ClientNameOperator = 1 AND T.ClientName IS NOT NULL ) 
 OR 
	 ( TMP.ClientNameOperator = 2 AND T.ClientName = TMP.ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 3 AND T.ClientName <> TMP.ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 4 AND T.ClientName LIKE TMP.ClientNameValue + '%') 
 OR 
	 ( TMP.ClientNameOperator = 5 AND T.ClientName LIKE '%' + TMP. ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 6 AND T.ClientName LIKE '%' + TMP. ClientNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ParentProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 0 AND T.ParentProgramID IS NULL ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 1 AND T.ParentProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 2 AND T.ParentProgramID = TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 3 AND T.ParentProgramID <> TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 7 AND T.ParentProgramID > TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 8 AND T.ParentProgramID >= TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 9 AND T.ParentProgramID < TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 10 AND T.ParentProgramID <= TMP.ParentProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ParentNameOperator = -1 ) 
 OR 
	 ( TMP.ParentNameOperator = 0 AND T.ParentName IS NULL ) 
 OR 
	 ( TMP.ParentNameOperator = 1 AND T.ParentName IS NOT NULL ) 
 OR 
	 ( TMP.ParentNameOperator = 2 AND T.ParentName = TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 3 AND T.ParentName <> TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 4 AND T.ParentName LIKE TMP.ParentNameValue + '%') 
 OR 
	 ( TMP.ParentNameOperator = 5 AND T.ParentName LIKE '%' + TMP.ParentNameValue ) 
 OR 
	 ( TMP.ParentNameOperator = 6 AND T.ParentName LIKE '%' + TMP.ParentNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramIDOperator = -1 ) 
 OR 
	 ( TMP.ProgramIDOperator = 0 AND T.ProgramID IS NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 1 AND T.ProgramID IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIDOperator = 2 AND T.ProgramID = TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 3 AND T.ProgramID <> TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 7 AND T.ProgramID > TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 8 AND T.ProgramID >= TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 9 AND T.ProgramID < TMP.ProgramIDValue ) 
 OR 
	 ( TMP.ProgramIDOperator = 10 AND T.ProgramID <= TMP.ProgramIDValue ) 

 ) 

 AND 

 ( 
	 ( TMP.ProgramCodeOperator = -1 ) 
 OR 
	 ( TMP.ProgramCodeOperator = 0 AND T.ProgramCode IS NULL ) 
 OR 
	 ( TMP.ProgramCodeOperator = 1 AND T.ProgramCode IS NOT NULL ) 
 OR 
	 ( TMP.ProgramCodeOperator = 2 AND T.ProgramCode = TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 3 AND T.ProgramCode <> TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 4 AND T.ProgramCode LIKE TMP.ProgramCodeValue + '%') 
 OR 
	 ( TMP.ProgramCodeOperator = 5 AND T.ProgramCode LIKE '%' + TMP.ProgramCodeValue ) 
 OR 
	 ( TMP.ProgramCodeOperator = 6 AND T.ProgramCode LIKE '%' + TMP.ProgramCodeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramNameOperator = -1 ) 
 OR 
	 ( TMP.ProgramNameOperator = 0 AND T.ProgramName IS NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 1 AND T.ProgramName IS NOT NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 2 AND T.ProgramName = TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 3 AND T.ProgramName <> TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 4 AND T.ProgramName LIKE TMP.ProgramNameValue + '%') 
 OR 
	 ( TMP.ProgramNameOperator = 5 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 6 AND T.ProgramName LIKE '%' + TMP.ProgramNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramDescriptionOperator = -1 ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 0 AND T.ProgramDescription IS NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 1 AND T.ProgramDescription IS NOT NULL ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 2 AND T.ProgramDescription = TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 3 AND T.ProgramDescription <> TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 4 AND T.ProgramDescription LIKE TMP.ProgramDescriptionValue + '%') 
 OR 
	 ( TMP.ProgramDescriptionOperator = 5 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue ) 
 OR 
	 ( TMP.ProgramDescriptionOperator = 6 AND T.ProgramDescription LIKE '%' + TMP.ProgramDescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramIsActiveOperator = -1 ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 0 AND T.ProgramIsActive IS NULL ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 1 AND T.ProgramIsActive IS NOT NULL ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 2 AND T.ProgramIsActive = TMP.ProgramIsActiveValue ) 
 OR 
	 ( TMP.ProgramIsActiveOperator = 3 AND T.ProgramIsActive <> TMP.ProgramIsActiveValue ) 
 ) 

 AND 

 ( 
	 ( TMP.IsAuditedOperator = -1 ) 
 OR 
	 ( TMP.IsAuditedOperator = 0 AND T.IsAudited IS NULL ) 
 OR 
	 ( TMP.IsAuditedOperator = 1 AND T.IsAudited IS NOT NULL ) 
 OR 
	 ( TMP.IsAuditedOperator = 2 AND T.IsAudited = TMP.IsAuditedValue ) 
 OR 
	 ( TMP.IsAuditedOperator = 3 AND T.IsAudited <> TMP.IsAuditedValue ) 

 ) 

 AND 

 ( 
	 ( TMP.IsClosedLoopAutomatedOperator = -1 ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 0 AND T.IsClosedLoopAutomated IS NULL ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 1 AND T.IsClosedLoopAutomated IS NOT NULL ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 2 AND T.IsClosedLoopAutomated = TMP.IsClosedLoopAutomatedValue ) 
 OR 
	 ( TMP.IsClosedLoopAutomatedOperator = 3 AND T.IsClosedLoopAutomated <> TMP.IsClosedLoopAutomatedValue )

 ) 

 AND 

 ( 
	 ( TMP.IsGroupOperator = -1 ) 
 OR 
	 ( TMP.IsGroupOperator = 0 AND T.IsGroup IS NULL ) 
 OR 
	 ( TMP.IsGroupOperator = 1 AND T.IsGroup IS NOT NULL ) 
 OR 
	 ( TMP.IsGroupOperator = 2 AND T.IsGroup = TMP.IsGroupValue ) 
 OR 
	 ( TMP.IsGroupOperator = 3 AND T.IsGroup <> TMP.IsGroupValue )

 ) 
 
 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'ASC'
	 THEN T.Sort END ASC, 
	 CASE WHEN @sortColumn = 'Sort' AND @sortOrder = 'DESC'
	 THEN T.Sort END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'ASC'
	 THEN T.ParentProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'DESC'
	 THEN T.ParentProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'ASC'
	 THEN T.ParentName END ASC, 
	 CASE WHEN @sortColumn = 'ParentName' AND @sortOrder = 'DESC'
	 THEN T.ParentName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'ASC'
	 THEN T.ProgramCode END ASC, 
	 CASE WHEN @sortColumn = 'ProgramCode' AND @sortOrder = 'DESC'
	 THEN T.ProgramCode END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN T.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN T.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'ASC'
	 THEN T.ProgramDescription END ASC, 
	 CASE WHEN @sortColumn = 'ProgramDescription' AND @sortOrder = 'DESC'
	 THEN T.ProgramDescription END DESC ,

	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'ASC'
	 THEN T.ProgramIsActive END ASC, 
	 CASE WHEN @sortColumn = 'ProgramIsActive' AND @sortOrder = 'DESC'
	 THEN T.ProgramIsActive END DESC ,

	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'ASC'
	 THEN T.IsAudited END ASC, 
	 CASE WHEN @sortColumn = 'IsAudited' AND @sortOrder = 'DESC'
	 THEN T.IsAudited END DESC ,

	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'ASC'
	 THEN T.IsClosedLoopAutomated END ASC, 
	 CASE WHEN @sortColumn = 'IsClosedLoopAutomated' AND @sortOrder = 'DESC'
	 THEN T.IsClosedLoopAutomated END DESC ,

	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'ASC'
	 THEN T.IsGroup END ASC, 
	 CASE WHEN @sortColumn = 'IsGroup' AND @sortOrder = 'DESC'
	 THEN T.IsGroup END DESC 


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
