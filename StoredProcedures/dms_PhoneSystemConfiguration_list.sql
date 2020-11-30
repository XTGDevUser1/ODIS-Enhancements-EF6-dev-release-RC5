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
 WHERE id = object_id(N'[dbo].[dms_PhoneSystemConfiguration_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PhoneSystemConfiguration_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_PhoneSystemConfiguration_list]( 
   @whereClauseXML NVARCHAR(4000) = NULL 
 , @startInd Int = 1 
 , @endInd BIGINT = 5000 
 , @pageSize int = 10  
 , @sortColumn nvarchar(100)  = '' 
 , @sortOrder nvarchar(100) = 'ASC' 
 , @userID UNIQUEIDENTIFIER 
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON

DECLARE @idoc int
IF @whereClauseXML IS NULL 
BEGIN
	SET @whereClauseXML = '<ROW><Filter 
IDOperator="-1" 
ProgramIDOperator="-1" 
ProgramNameOperator="-1" 
IVRScriptIDOperator="-1" 
PhoneCompanyOperator="-1" 
PilotNumberOperator="-1" 
SkillsetOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
IDOperator INT NOT NULL,
IDValue int NULL,
ProgramIDOperator INT NOT NULL,
ProgramIDValue int NULL,
ProgramNameOperator INT NOT NULL,
ProgramNameValue nvarchar(50) NULL,
IVRScriptIDOperator INT NOT NULL,
IVRScriptIDValue nvarchar(50) NULL,
PhoneCompanyOperator INT NOT NULL,
PhoneCompanyValue nvarchar(50) NULL,
PilotNumberOperator INT NOT NULL,
PilotNumberValue nvarchar(50) NULL,
SkillsetOperator INT NOT NULL,
SkillsetValue nvarchar(50) NULL
)
 DECLARE @FinalResults TABLE(  
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ProgramID int  NULL ,
	ProgramName nvarchar(50)  NULL ,
	InBoundNumber nvarchar(50)  NULL ,
	IVRScriptID nvarchar(50)  NULL ,
	PhoneCompany nvarchar(50)  NULL ,
	PilotNumber nvarchar(50)  NULL ,
	Skillset nvarchar(50)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(IDOperator,-1),
	IDValue ,
	ISNULL(ProgramIDOperator,-1),
	ProgramIDValue ,
	ISNULL(ProgramNameOperator,-1),
	ProgramNameValue ,
	ISNULL(IVRScriptIDOperator,-1),
	IVRScriptIDValue ,
	ISNULL(PhoneCompanyOperator,-1),
	PhoneCompanyValue ,
	ISNULL(PilotNumberOperator,-1),
	PilotNumberValue ,
	ISNULL(SkillsetOperator,-1),
	SkillsetValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
IDOperator INT,
IDValue int 
,ProgramIDOperator INT,
ProgramIDValue int 
,ProgramNameOperator INT,
ProgramNameValue nvarchar(50) 
,IVRScriptIDOperator INT,
IVRScriptIDValue nvarchar(50) 
,PhoneCompanyOperator INT,
PhoneCompanyValue nvarchar(50) 
,PilotNumberOperator INT,
PilotNumberValue nvarchar(50) 
,SkillsetOperator INT,
SkillsetValue nvarchar(50) 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
INSERT INTO @FinalResults

SELECT T.ID,
	   T.ProgramID,
	   P.ProgramName AS [ProgramName],
	   T.InboundNumber,
	   I.[Name] AS [IVRScriptID],
	   PC.[Type] AS [PhoneCompany],
	   T.PilotNumber,
	   S.[Name] AS [Skillset]
FROM PhoneSystemConfiguration T
LEFT JOIN [dbo].[fnc_GetProgramsForUser](@userID) P ON T.ProgramID = P.ProgramID
LEFT JOIN PhoneCompany PC ON T.InboundPhoneCompanyID = PC.ID
LEFT JOIN Skillset S ON T.SkillsetID = S.ID
LEFT JOIN IVRScript I ON T.IVRScriptID = I.ID,

--SELECT 
--	T.ID,
--	T.ProgramID,
--	T.ProgramName,
--	T.InBoundNumber,
--	T.IVRScriptID,
--	T.PhoneCompany,
--	T.PilotNumber,
--	T.Skillset
--FROM <table> T,
@tmpForWhereClause TMP 
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
	 ( TMP.ProgramNameOperator = -1 ) 
 OR 
	 ( TMP.ProgramNameOperator = 0 AND P.ProgramName IS NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 1 AND P.ProgramName IS NOT NULL ) 
 OR 
	 ( TMP.ProgramNameOperator = 2 AND P.ProgramName = TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 3 AND P.ProgramName <> TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 4 AND P.ProgramName LIKE TMP.ProgramNameValue + '%') 
 OR 
	 ( TMP.ProgramNameOperator = 5 AND P.ProgramName LIKE '%' + TMP.ProgramNameValue ) 
 OR 
	 ( TMP.ProgramNameOperator = 6 AND P.ProgramName LIKE '%' + TMP.ProgramNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.IVRScriptIDOperator = -1 ) 
 OR 
	 ( TMP.IVRScriptIDOperator = 0 AND T.IVRScriptID IS NULL ) 
 OR 
	 ( TMP.IVRScriptIDOperator = 1 AND T.IVRScriptID IS NOT NULL ) 
 OR 
	 ( TMP.IVRScriptIDOperator = 2 AND T.IVRScriptID = TMP.IVRScriptIDValue ) 
 OR 
	 ( TMP.IVRScriptIDOperator = 3 AND T.IVRScriptID <> TMP.IVRScriptIDValue ) 
 OR 
	 ( TMP.IVRScriptIDOperator = 4 AND T.IVRScriptID LIKE TMP.IVRScriptIDValue + '%') 
 OR 
	 ( TMP.IVRScriptIDOperator = 5 AND T.IVRScriptID LIKE '%' + TMP.IVRScriptIDValue ) 
 OR 
	 ( TMP.IVRScriptIDOperator = 6 AND T.IVRScriptID LIKE '%' + TMP.IVRScriptIDValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PhoneCompanyOperator = -1 ) 
 OR 
	 ( TMP.PhoneCompanyOperator = 0 AND PC.[Type] IS NULL ) 
 OR 
	 ( TMP.PhoneCompanyOperator = 1 AND PC.[Type] IS NOT NULL ) 
 OR 
	 ( TMP.PhoneCompanyOperator = 2 AND PC.[Type] = TMP.PhoneCompanyValue ) 
 OR 
	 ( TMP.PhoneCompanyOperator = 3 AND PC.[Type] <> TMP.PhoneCompanyValue ) 
 OR 
	 ( TMP.PhoneCompanyOperator = 4 AND PC.[Type] LIKE TMP.PhoneCompanyValue + '%') 
 OR 
	 ( TMP.PhoneCompanyOperator = 5 AND PC.[Type] LIKE '%' + TMP.PhoneCompanyValue ) 
 OR 
	 ( TMP.PhoneCompanyOperator = 6 AND PC.[Type] LIKE '%' + TMP.PhoneCompanyValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.PilotNumberOperator = -1 ) 
 OR 
	 ( TMP.PilotNumberOperator = 0 AND T.PilotNumber IS NULL ) 
 OR 
	 ( TMP.PilotNumberOperator = 1 AND T.PilotNumber IS NOT NULL ) 
 OR 
	 ( TMP.PilotNumberOperator = 2 AND T.PilotNumber = TMP.PilotNumberValue ) 
 OR 
	 ( TMP.PilotNumberOperator = 3 AND T.PilotNumber <> TMP.PilotNumberValue ) 
 OR 
	 ( TMP.PilotNumberOperator = 4 AND T.PilotNumber LIKE TMP.PilotNumberValue + '%') 
 OR 
	 ( TMP.PilotNumberOperator = 5 AND T.PilotNumber LIKE '%' + TMP.PilotNumberValue ) 
 OR 
	 ( TMP.PilotNumberOperator = 6 AND T.PilotNumber LIKE '%' + TMP.PilotNumberValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.SkillsetOperator = -1 ) 
 OR 
	 ( TMP.SkillsetOperator = 0 AND S.[Name] IS NULL ) 
 OR 
	 ( TMP.SkillsetOperator = 1 AND S.[Name] IS NOT NULL ) 
 OR 
	 ( TMP.SkillsetOperator = 2 AND S.[Name] = TMP.SkillsetValue ) 
 OR 
	 ( TMP.SkillsetOperator = 3 AND S.[Name] <> TMP.SkillsetValue ) 
 OR 
	 ( TMP.SkillsetOperator = 4 AND S.[Name] LIKE TMP.SkillsetValue + '%') 
 OR 
	 ( TMP.SkillsetOperator = 5 AND S.[Name] LIKE '%' + TMP.SkillsetValue ) 
 OR 
	 ( TMP.SkillsetOperator = 6 AND S.[Name] LIKE '%' + TMP.SkillsetValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'ASC'
	 THEN T.ProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ProgramID' AND @sortOrder = 'DESC'
	 THEN T.ProgramID END DESC ,

	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'ASC'
	 THEN P.ProgramName END ASC, 
	 CASE WHEN @sortColumn = 'ProgramName' AND @sortOrder = 'DESC'
	 THEN P.ProgramName END DESC ,

	 CASE WHEN @sortColumn = 'InBoundNumber' AND @sortOrder = 'ASC'
	 THEN T.InBoundNumber END ASC, 
	 CASE WHEN @sortColumn = 'InBoundNumber' AND @sortOrder = 'DESC'
	 THEN T.InBoundNumber END DESC ,

	 CASE WHEN @sortColumn = 'IVRScriptID' AND @sortOrder = 'ASC'
	 THEN T.IVRScriptID END ASC, 
	 CASE WHEN @sortColumn = 'IVRScriptID' AND @sortOrder = 'DESC'
	 THEN T.IVRScriptID END DESC ,

	 CASE WHEN @sortColumn = 'PhoneCompany' AND @sortOrder = 'ASC'
	 THEN PC.[Type] END ASC, 
	 CASE WHEN @sortColumn = 'PhoneCompany' AND @sortOrder = 'DESC'
	 THEN PC.[Type] END DESC ,

	 CASE WHEN @sortColumn = 'PilotNumber' AND @sortOrder = 'ASC'
	 THEN T.PilotNumber END ASC, 
	 CASE WHEN @sortColumn = 'PilotNumber' AND @sortOrder = 'DESC'
	 THEN T.PilotNumber END DESC ,

	 CASE WHEN @sortColumn = 'Skillset' AND @sortOrder = 'ASC'
	 THEN S.[Name] END ASC, 
	 CASE WHEN @sortColumn = 'Skillset' AND @sortOrder = 'DESC'
	 THEN S.[Name] END DESC 


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
