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
 WHERE id = object_id(N'[dbo].[dms_clients_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_clients_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_clients_list] '20EE6D5C-6B06-43E1-A723-D53FD6D593B5'
-- EXEC [dms_clients_list] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB' 
-- EXEC [dms_clients_list] '3c19f725-5d19-4701-ae53-f2c104648541'

 
 -- EXEC [dms_clients_list] '20EE6D5C-6B06-43E1-A723-D53FD6D593B5'
-- EXEC [dms_clients_list] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB' 
-- EXEC [dms_clients_list] '3c19f725-5d19-4701-ae53-f2c104648541'

 
 CREATE PROCEDURE [dbo].[dms_clients_list]( 
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
IDOperator="-1" 
ClientNameOperator="-1" 
DescriptionOperator="-1" 
IsActiveOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
IDOperator INT NOT NULL,
IDValue int NULL,
ClientNameOperator INT NOT NULL,
ClientNameValue nvarchar(255) NULL,
DescriptionOperator INT NOT NULL,
DescriptionValue nvarchar(255) NULL,
IsActiveOperator INT NOT NULL,
IsActiveValue BIT NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	ClientName nvarchar(255)  NULL ,
	Description nvarchar(255)  NULL ,
	IsActive BIT  NULL 
) 
DECLARE @tmpResults TABLE ( 	
	ID int  NULL ,
	ClientName nvarchar(255)  NULL ,
	Description nvarchar(255)  NULL ,
	IsActive BIT  NULL 
) 

-- FOR EF TO GENERATE THE COMPLEX TYPE
IF @userID IS NULL
BEGIN
	SELECT 0 AS TotalRows, * FROM @FinalResults
END

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(IDOperator,-1),
	IDValue ,
	ISNULL(ClientNameOperator,-1),
	ClientNameValue ,
	ISNULL(DescriptionOperator,-1),
	DescriptionValue ,
	ISNULL(IsActiveOperator,-1),
	IsActiveValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
IDOperator INT,
IDValue int 
,ClientNameOperator INT,
ClientNameValue nvarchar(255) 
,DescriptionOperator INT,
DescriptionValue nvarchar(255) 
,IsActiveOperator INT,
IsActiveValue BIT 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
-- LOGIC : START
DECLARE @isAdmin BIT = 0
	DECLARE @currentOrganizationID INT

	SET @currentOrganizationID = NULL


	SELECT @isAdmin = 1 FROM aspnet_UsersInRoles U JOIN aspnet_Roles R ON U.RoleId = R.RoleId
	WHERE U.UserId = @userId AND R.LoweredRoleName = 'sysadmin'

	IF @isAdmin = 1
	BEGIN
		;WITH wResults
		AS
		(
			SELECT	C.ID,
					C.Name AS [ClientName],
					C.[Description],
					C.IsActive
			FROM	[dbo].[Client] C WITH (NOLOCK)		
			
		)
		INSERT INTO @tmpResults
		SELECT	W.ID,
				W.[ClientName],
				W.[Description],
				W.IsActive	
		FROM	wResults W		
	END
	ELSE
	BEGIN

		SELECT	@currentOrganizationID = OrganizationID 
		FROM	[dbo].[User] U WITH (NOLOCK) 
		WHERE U.aspnet_UserID = @userID
		-- Traverse through Org hierarchy (from current to all children)
		;WITH wOrgHierarchy
		AS
		(
			SELECT	O.ID,
					O.Name,
					0 AS [DisplayOrder]
			FROM	[dbo].[Organization] O WITH (NOLOCK)
			WHERE	O.ID = @currentOrganizationID
			
			UNION ALL
			
			SELECT	C.ID,
					C.Name,
					W.[DisplayOrder] + 1 AS DisplayOrder
			FROM	[dbo].[Organization] C WITH (NOLOCK)
			JOIN	wOrgHierarchy W ON C.ParentOrganizationID = W.ID	
		)

		SELECT	*
		INTO	#tmpOrgHierarchy
		FROM	wOrgHierarchy
		
		;WITH wResults
		AS
		(
			SELECT	C.ID,
					C.Name AS [ClientName],
					C.[Description],
					C.IsActive
			FROM	[dbo].[Organization] O WITH (NOLOCK) 
			LEFT JOIN [dbo].[#tmpOrgHierarchy] T WITH (NOLOCK) ON T.ID = O.ID
			LEFT JOIN [dbo].[OrganizationClient] OC WITH (NOLOCK) ON O.ID = OC.OrganizationID
			LEFT JOIN [dbo].[Client] C WITH (NOLOCK) ON C.ID = OC.ClientID			
			WHERE	C.IsActive=1
			
		)
		INSERT INTO @tmpResults
		SELECT	DISTINCT C.ID,
				C.[ClientName],
				C.[Description],
				C.IsActive	
		FROM	wResults C
		
		DROP TABLE #tmpOrgHierarchy
		
	END

-- LOGIC : END


INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.ClientName,
	T.Description,
	T.IsActive
FROM @tmpResults T,
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
	 ( TMP.ClientNameOperator = 5 AND T.ClientName LIKE '%' + TMP.ClientNameValue ) 
 OR 
	 ( TMP.ClientNameOperator = 6 AND T.ClientName LIKE '%' + TMP.ClientNameValue + '%' ) 
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
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'ASC'
	 THEN T.ClientName END ASC, 
	 CASE WHEN @sortColumn = 'ClientName' AND @sortOrder = 'DESC'
	 THEN T.ClientName END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

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
GO

