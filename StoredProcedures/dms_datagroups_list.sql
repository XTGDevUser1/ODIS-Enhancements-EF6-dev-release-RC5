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
-- EXEC dms_datagroups_list '20EE6D5C-6B06-43E1-A723-D53FD6D593B5'
-- EXEC dms_datagroups_list 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'

 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_datagroups_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_datagroups_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_datagroups_list]( 
   @userID UNIQUEIDENTIFIER = NULL
 , @whereClauseXML NVARCHAR(4000) = NULL 
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
DataGroupNameOperator="-1" 
DescriptionOperator="-1" 
ProgramsOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
DataGroupNameOperator INT NOT NULL,
DataGroupNameValue nvarchar(50) NULL,
DescriptionOperator INT NOT NULL,
DescriptionValue nvarchar(255) NULL,
ProgramsOperator INT NOT NULL,
ProgramsValue nvarchar(MAX) NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	DataGroupName nvarchar(50)  NULL ,
	Description nvarchar(255)  NULL ,
	Programs nvarchar(MAX)  NULL 
) 

DECLARE @tmpResults TABLE
(
	ID INT,
	DataGroupName NVARCHAR(50) NULL,
	Description NVARCHAR(255) NULL,
	Programs NVARCHAR(MAX) NULL
)

-- FOR EF TO GENERATE THE COMPLEX TYPE
IF @userID IS NULL
BEGIN
	SELECT 0 AS TotalRows, * FROM @FinalResults
END

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(DataGroupNameOperator,-1),
	DataGroupNameValue ,
	ISNULL(DescriptionOperator,-1),
	DescriptionValue ,
	ISNULL(ProgramsOperator,-1),
	ProgramsValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
DataGroupNameOperator INT,
DataGroupNameValue nvarchar(50) 
,DescriptionOperator INT,
DescriptionValue nvarchar(50) 
,ProgramsOperator INT,
ProgramsValue nvarchar(50) 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------

;WITH wResults
		AS
		(
			SELECT	DG.ID,
					DG.Name AS [DataGroupName],
					DG.[Description],
					P.Name AS Programs
			FROM	
			[dbo].fnc_GetOrganizationsForUser(@UserID) T 
			JOIN [dbo].[DataGroup] DG WITH (NOLOCK) ON DG.OrganizationID  = T.OrganizationID
			JOIN [dbo].[DataGroupProgram] DGP WITH (NOLOCK) ON DGP.DataGroupID  = DG.ID
			JOIN [dbo].[Program] P WITH (NOLOCK) ON P.ID = DGP.ProgramID 
			WHERE P.IsActive = 1
			
		)
		INSERT INTO @tmpResults
		SELECT	W.ID,
				W.DataGroupName,
				W.[Description],
				[dbo].[fnConcatenate](DISTINCT W.Programs)		
		FROM	wResults W
		GROUP BY	W.ID,
					W.DataGroupName,
					W.[Description]
		
				
	
INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.DataGroupName,
	T.Description,
	T.Programs
FROM @tmpResults T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.DataGroupNameOperator = -1 ) 
 OR 
	 ( TMP.DataGroupNameOperator = 0 AND T.DataGroupName IS NULL ) 
 OR 
	 ( TMP.DataGroupNameOperator = 1 AND T.DataGroupName IS NOT NULL ) 
 OR 
	 ( TMP.DataGroupNameOperator = 2 AND T.DataGroupName = TMP.DataGroupNameValue ) 
 OR 
	 ( TMP.DataGroupNameOperator = 3 AND T.DataGroupName <> TMP.DataGroupNameValue ) 
 OR 
	 ( TMP.DataGroupNameOperator = 4 AND T.DataGroupName LIKE TMP.DataGroupNameValue + '%') 
 OR 
	 ( TMP.DataGroupNameOperator = 5 AND T.DataGroupName LIKE '%' + TMP.DataGroupNameValue ) 
 OR 
	 ( TMP.DataGroupNameOperator = 6 AND T.DataGroupName LIKE '%' + TMP.DataGroupNameValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.DescriptionOperator = -1 ) 
 OR 
	 ( TMP.DescriptionOperator = 0 AND T.Description IS NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 1 AND T.Description IS NOT NULL ) 
 OR 
	 ( TMP.DescriptionOperator = 2 AND T.Description = TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 3 AND T.Description <> TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 4 AND T.Description LIKE TMP.DescriptionValue + '%') 
 OR 
	 ( TMP.DescriptionOperator = 5 AND T.Description LIKE '%' + TMP.DescriptionValue ) 
 OR 
	 ( TMP.DescriptionOperator = 6 AND T.Description LIKE '%' + TMP.DescriptionValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.ProgramsOperator = -1 ) 
 OR 
	 ( TMP.ProgramsOperator = 0 AND T.Programs IS NULL ) 
 OR 
	 ( TMP.ProgramsOperator = 1 AND T.Programs IS NOT NULL ) 
 OR 
	 ( TMP.ProgramsOperator = 2 AND T.Programs = TMP.ProgramsValue ) 
 OR 
	 ( TMP.ProgramsOperator = 3 AND T.Programs <> TMP.ProgramsValue ) 
 OR 
	 ( TMP.ProgramsOperator = 4 AND T.Programs LIKE TMP.ProgramsValue + '%') 
 OR 
	 ( TMP.ProgramsOperator = 5 AND T.Programs LIKE '%' + TMP.ProgramsValue ) 
 OR 
	 ( TMP.ProgramsOperator = 6 AND T.Programs LIKE '%' + TMP.ProgramsValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'DataGroupName' AND @sortOrder = 'ASC'
	 THEN T.DataGroupName END ASC, 
	 CASE WHEN @sortColumn = 'DataGroupName' AND @sortOrder = 'DESC'
	 THEN T.DataGroupName END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'Programs' AND @sortOrder = 'ASC'
	 THEN T.Programs END ASC, 
	 CASE WHEN @sortColumn = 'Programs' AND @sortOrder = 'DESC'
	 THEN T.Programs END DESC 


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

 GO
