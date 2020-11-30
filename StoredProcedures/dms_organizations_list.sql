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
 WHERE id = object_id(N'[dbo].[dms_organizations_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_organizations_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC  [dbo].[dms_organizations_list] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB',NULL,1,100,10,'UserName','ASC'
-- EXEC  [dbo].[dms_organizations_list] '20EE6D5C-6B06-43E1-A723-D53FD6D593B5',NULL,1,100,10,'UserName','ASC'
-- EXEC  [dbo].[dms_organizations_list] '63B8CB08-9265-4613-AFBD-1226999DF139',NULL,1,100,10,'UserName','ASC'
 CREATE PROCEDURE [dbo].[dms_organizations_list]( 
   @userID UNIQUEIDENTIFIER = NULL,
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
OrganizationNameOperator="-1" 
DescriptionOperator="-1" 
ParentOrganizationNameOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
OrganizationNameOperator INT NOT NULL,
OrganizationNameValue nvarchar(50) NULL,
DescriptionOperator INT NOT NULL,
DescriptionValue nvarchar(255) NULL,
ParentOrganizationNameOperator INT NOT NULL,
ParentOrganizationNameValue nvarchar(50) NULL
)

DECLARE @tmpResults TABLE ( 	
	ID int  NULL ,
	OrganizationName nvarchar(50)  NULL ,
	Description nvarchar(255)  NULL ,
	ParentOrganizationName nvarchar(50)  NULL 
) 

DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	OrganizationName nvarchar(50)  NULL ,
	Description nvarchar(255)  NULL ,
	ParentOrganizationName nvarchar(50)  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(OrganizationNameOperator,-1),
	OrganizationNameValue ,
	ISNULL(DescriptionOperator,-1),
	DescriptionValue ,
	ISNULL(ParentOrganizationNameOperator,-1),
	ParentOrganizationNameValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
OrganizationNameOperator INT,
OrganizationNameValue nvarchar(50) 
,DescriptionOperator INT,
DescriptionValue nvarchar(50) 
,ParentOrganizationNameOperator INT,
ParentOrganizationNameValue nvarchar(50) 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------


-- DEBUG: The following statement is for EF to generate complex types
IF @userID IS NULL
BEGIN

	SELECT 0 as TotalRows,* FROM @FinalResults
	RETURN;
END
--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
--- LOGIC : START

	
	DECLARE @currentOrganizationID INT

	SET @currentOrganizationID = NULL
	
	INSERT INTO @tmpResults
		SELECT	O.ID,
				O.Name,
				O.Description,
				P.Name as ParentOrganizationName
		FROM Organization O
		JOIN fnc_GetOrganizationsForUser(@userID) F ON F.OrganizationID = O.ID
		LEFT JOIN Organization P ON P.ID = O.ParentOrganizationID 
		ORDER BY Name ASC
	
	
		SELECT	@currentOrganizationID = OrganizationID 
		FROM	[dbo].[User] U WITH (NOLOCK) 
		WHERE U.aspnet_UserID = @userID
		
		--Don't show current Org on Org Maintenance, we are not allowing edits of your org
		DELETE FROM @tmpResults WHERE ID = @currentOrganizationID
		

--- LOGIC : END

INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.OrganizationName,
	T.Description,
	T.ParentOrganizationName
FROM @tmpResults T,
@tmpForWhereClause TMP 
WHERE ( 

 ( 
	 ( TMP.OrganizationNameOperator = -1 ) 
 OR 
	 ( TMP.OrganizationNameOperator = 0 AND T.OrganizationName IS NULL ) 
 OR 
	 ( TMP.OrganizationNameOperator = 1 AND T.OrganizationName IS NOT NULL ) 
 OR 
	 ( TMP.OrganizationNameOperator = 2 AND T.OrganizationName = TMP.OrganizationNameValue ) 
 OR 
	 ( TMP.OrganizationNameOperator = 3 AND T.OrganizationName <> TMP.OrganizationNameValue ) 
 OR 
	 ( TMP.OrganizationNameOperator = 4 AND T.OrganizationName LIKE TMP.OrganizationNameValue + '%') 
 OR 
	 ( TMP.OrganizationNameOperator = 5 AND T.OrganizationName LIKE '%' + TMP.OrganizationNameValue ) 
 OR 
	 ( TMP.OrganizationNameOperator = 6 AND T.OrganizationName LIKE '%' + TMP.OrganizationNameValue + '%' ) 
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
	 ( TMP.ParentOrganizationNameOperator = -1 ) 
 OR 
	 ( TMP.ParentOrganizationNameOperator = 0 AND T.ParentOrganizationName IS NULL ) 
 OR 
	 ( TMP.ParentOrganizationNameOperator = 1 AND T.ParentOrganizationName IS NOT NULL ) 
 OR 
	 ( TMP.ParentOrganizationNameOperator = 2 AND T.ParentOrganizationName = TMP.ParentOrganizationNameValue ) 
 OR 
	 ( TMP.ParentOrganizationNameOperator = 3 AND T.ParentOrganizationName <> TMP.ParentOrganizationNameValue ) 
 OR 
	 ( TMP.ParentOrganizationNameOperator = 4 AND T.ParentOrganizationName LIKE TMP.ParentOrganizationNameValue + '%') 
 OR 
	 ( TMP.ParentOrganizationNameOperator = 5 AND T.ParentOrganizationName LIKE '%' + TMP.ParentOrganizationNameValue ) 
 OR 
	 ( TMP.ParentOrganizationNameOperator = 6 AND T.ParentOrganizationName LIKE '%' + TMP.ParentOrganizationNameValue + '%' ) 
 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'OrganizationName' AND @sortOrder = 'ASC'
	 THEN T.OrganizationName END ASC, 
	 CASE WHEN @sortColumn = 'OrganizationName' AND @sortOrder = 'DESC'
	 THEN T.OrganizationName END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'ParentOrganizationName' AND @sortOrder = 'ASC'
	 THEN T.ParentOrganizationName END ASC, 
	 CASE WHEN @sortColumn = 'ParentOrganizationName' AND @sortOrder = 'DESC'
	 THEN T.ParentOrganizationName END DESC 


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
