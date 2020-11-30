--exec dms_Programs_list 'ADE16211-64F6-49A5-8874-33F1EAC51CCD'
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
 WHERE id = object_id(N'[dbo].[dms_Programs_list]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Programs_list] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
CREATE PROCEDURE [dbo].[dms_Programs_list]( 
   @userID uniqueidentifier = NULL,
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
IDOperator="-1" 
CodeOperator="-1" 
NameOperator="-1" 
DescriptionOperator="-1" 
ClientIDOperator="-1" 
ParentProgramIDOperator="-1" 
CallFeeOperator="-1" 
DispatchFeeOperator="-1" 
 ></Filter></ROW>'
END
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML

DECLARE @tmpForWhereClause TABLE
(
IDOperator INT NOT NULL,
IDValue int NULL,
CodeOperator INT NOT NULL,
CodeValue nvarchar(50) NULL,
NameOperator INT NOT NULL,
NameValue nvarchar(50) NULL,
DescriptionOperator INT NOT NULL,
DescriptionValue nvarchar(50) NULL,
ClientIDOperator INT NOT NULL,
ClientIDValue nvarchar(50) NULL,
ParentProgramIDOperator INT NOT NULL,
ParentProgramIDValue nvarchar(50) NULL,
CallFeeOperator money NOT NULL,
CallFeeValue money NULL,
DispatchFeeOperator money NOT NULL,
DispatchFeeValue money NULL
)
DECLARE @FinalResults TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Code nvarchar(50)  NULL ,
	Name nvarchar(50)  NULL ,
	Description nvarchar(50)  NULL ,
	ClientID nvarchar(50)  NULL ,
	ParentProgramID nvarchar(50)  NULL ,
	CallFee money  NULL ,
	DispatchFee money  NULL ,
	IsActive bit  NULL 
) 


DECLARE @Results TABLE ( 
	[RowNum] [bigint] NOT NULL IDENTITY(1,1),
	ID int  NULL ,
	Code nvarchar(50)  NULL ,
	Name nvarchar(50)  NULL ,
	Description nvarchar(50)  NULL ,
	ClientID nvarchar(50)  NULL ,
	ParentProgramID nvarchar(50)  NULL ,
	CallFee money  NULL ,
	DispatchFee money  NULL ,
	IsActive bit  NULL 
) 

INSERT INTO @tmpForWhereClause
SELECT  
	ISNULL(IDOperator,-1),
	IDValue ,
	ISNULL(CodeOperator,-1),
	CodeValue ,
	ISNULL(NameOperator,-1),
	NameValue ,
	ISNULL(DescriptionOperator,-1),
	DescriptionValue ,
	ISNULL(ClientIDOperator,-1),
	ClientIDValue ,
	ISNULL(ParentProgramIDOperator,-1),
	ParentProgramIDValue ,
	ISNULL(CallFeeOperator,-1),
	CallFeeValue ,
	ISNULL(DispatchFeeOperator,-1),
	DispatchFeeValue 
FROM	OPENXML (@idoc,'/ROW/Filter',1) WITH (
IDOperator INT,
IDValue int 
,CodeOperator INT,
CodeValue nvarchar(50) 
,NameOperator INT,
NameValue nvarchar(50) 
,DescriptionOperator INT,
DescriptionValue nvarchar(50) 
,ClientIDOperator INT,
ClientIDValue nvarchar(50) 
,ParentProgramIDOperator INT,
ParentProgramIDValue nvarchar(50) 
,CallFeeOperator INT,
CallFeeValue decimal 
,DispatchFeeOperator INT,
DispatchFeeValue decimal 
 ) 

--------------------- BEGIN -----------------------------
----   Create a temp variable or a CTE with the actual SQL search query ----------
----   and use that CTE in the place of <table> in the following SQL statements ---
--------------------- END -----------------------------
IF @userID IS NULL
BEGIN

	SELECT 0 as TotalRows,* FROM @FinalResults
	RETURN;
END

DECLARE @isAdmin BIT = 0
DECLARE @currentOrganizationID INT

SET @currentOrganizationID = NULL

SELECT @isAdmin = 1 FROM aspnet_UsersInRoles U JOIN aspnet_Roles R ON U.RoleId = R.RoleId
WHERE U.UserId = @userId AND R.LoweredRoleName = 'sysadmin'

IF @isAdmin = 1
	BEGIN
		INSERT INTO @Results SELECT DISTINCT P.ID,
											 P.Code,
											 P.Name,
											 P.[Description],
											 C.Name AS ClientID,
											 (SELECT Name FROM Program WHERE ID = P.ParentProgramID) AS ParentProgramID,
											 P.CallFee,
											 P.DispatchFee,
											 P.IsActive 
										FROM Organization O
										LEFT JOIN OrganizationClient OC ON OC.OrganizationID = O.ID 
										LEFT JOIN Client C ON C.ID = OC.ClientID
										LEFT JOIN Program P ON P.ClientID = OC.ClientID
										WHERE P.ID IS NOT NULL
										
	END
ELSE
	BEGIN
	;WITH wOrgHierarchy
		AS
		(
			SELECT	O.ID,
					O.Name,
					0 AS [DisplayOrder]
			FROM	[dbo].[Organization] O WITH (NOLOCK)
			WHERE	O.ID = (SELECT [OrganizationID] FROM [User] WHERE [aspnet_UserID] = @userID)
			
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

INSERT INTO @Results SELECT DISTINCT P.ID,
	   P.Code,
	   P.Name,
	   P.[Description],
	   C.Name AS ClientID,
	   (SELECT Name FROM Program WHERE ID = P.ParentProgramID) AS ParentProgramID,
	   P.CallFee,
	   P.DispatchFee,
	   P.IsActive 
	  
FROM	#tmpOrgHierarchy O
LEFT JOIN OrganizationClient OC ON OC.OrganizationID = O.ID 
LEFT JOIN Client C ON C.ID = OC.ClientID
LEFT JOIN Program P ON P.ClientID = OC.ClientID
WHERE P.ID IS NOT NULL
AND P.IsActive = 1
AND C.IsActive = 1

END


INSERT INTO @FinalResults
SELECT 
	T.ID,
	T.Code,
	T.Name,
	T.Description,
	T.ClientID,
	T.ParentProgramID,
	T.CallFee,
	T.DispatchFee,
	T.IsActive
FROM @Results T,
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
	 ( TMP.CodeOperator = -1 ) 
 OR 
	 ( TMP.CodeOperator = 0 AND T.Code IS NULL ) 
 OR 
	 ( TMP.CodeOperator = 1 AND T.Code IS NOT NULL ) 
 OR 
	 ( TMP.CodeOperator = 2 AND T.Code = TMP.CodeValue ) 
 OR 
	 ( TMP.CodeOperator = 3 AND T.Code <> TMP.CodeValue ) 
 OR 
	 ( TMP.CodeOperator = 4 AND T.Code LIKE TMP.CodeValue + '%') 
 OR 
	 ( TMP.CodeOperator = 5 AND T.Code LIKE '%' + TMP.CodeValue ) 
 OR 
	 ( TMP.CodeOperator = 6 AND T.Code LIKE '%' + TMP.CodeValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.NameOperator = -1 ) 
 OR 
	 ( TMP.NameOperator = 0 AND T.Name IS NULL ) 
 OR 
	 ( TMP.NameOperator = 1 AND T.Name IS NOT NULL ) 
 OR 
	 ( TMP.NameOperator = 2 AND T.Name = TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 3 AND T.Name <> TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 4 AND T.Name LIKE TMP.NameValue + '%') 
 OR 
	 ( TMP.NameOperator = 5 AND T.Name LIKE '%' + TMP.NameValue ) 
 OR 
	 ( TMP.NameOperator = 6 AND T.Name LIKE '%' + TMP.NameValue + '%' ) 
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
	 ( TMP.ClientIDOperator = 4 AND T.ClientID LIKE TMP.ClientIDValue + '%') 
 OR 
	 ( TMP.ClientIDOperator = 5 AND T.ClientID LIKE '%' + TMP.ClientIDValue ) 
 OR 
	 ( TMP.ClientIDOperator = 6 AND T.ClientID LIKE '%' + TMP.ClientIDValue + '%' ) 
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
	 ( TMP.ParentProgramIDOperator = 4 AND T.ParentProgramID LIKE TMP.ParentProgramIDValue + '%') 
 OR 
	 ( TMP.ParentProgramIDOperator = 5 AND T.ParentProgramID LIKE '%' + TMP.ParentProgramIDValue ) 
 OR 
	 ( TMP.ParentProgramIDOperator = 6 AND T.ParentProgramID LIKE '%' + TMP.ParentProgramIDValue + '%' ) 
 ) 

 AND 

 ( 
	 ( TMP.CallFeeOperator = -1 ) 
 OR 
	 ( TMP.CallFeeOperator = 0 AND T.CallFee IS NULL ) 
 OR 
	 ( TMP.CallFeeOperator = 1 AND T.CallFee IS NOT NULL ) 
 OR 
	 ( TMP.CallFeeOperator = 2 AND T.CallFee = TMP.CallFeeValue ) 
 OR 
	 ( TMP.CallFeeOperator = 3 AND T.CallFee <> TMP.CallFeeValue ) 
 OR 
	 ( TMP.CallFeeOperator = 7 AND T.CallFee > TMP.CallFeeValue ) 
 OR 
	 ( TMP.CallFeeOperator = 8 AND T.CallFee >= TMP.CallFeeValue ) 
 OR 
	 ( TMP.CallFeeOperator = 9 AND T.CallFee < TMP.CallFeeValue ) 
 OR 
	 ( TMP.CallFeeOperator = 10 AND T.CallFee <= TMP.CallFeeValue ) 

 ) 

 AND 

 ( 
	 ( TMP.DispatchFeeOperator = -1 ) 
 OR 
	 ( TMP.DispatchFeeOperator = 0 AND T.DispatchFee IS NULL ) 
 OR 
	 ( TMP.DispatchFeeOperator = 1 AND T.DispatchFee IS NOT NULL ) 
 OR 
	 ( TMP.DispatchFeeOperator = 2 AND T.DispatchFee = TMP.DispatchFeeValue ) 
 OR 
	 ( TMP.DispatchFeeOperator = 3 AND T.DispatchFee <> TMP.DispatchFeeValue ) 
 OR 
	 ( TMP.DispatchFeeOperator = 7 AND T.DispatchFee > TMP.DispatchFeeValue ) 
 OR 
	 ( TMP.DispatchFeeOperator = 8 AND T.DispatchFee >= TMP.DispatchFeeValue ) 
 OR 
	 ( TMP.DispatchFeeOperator = 9 AND T.DispatchFee < TMP.DispatchFeeValue ) 
 OR 
	 ( TMP.DispatchFeeOperator = 10 AND T.DispatchFee <= TMP.DispatchFeeValue ) 

 ) 

 AND 
 1 = 1 
 ) 
 ORDER BY 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'ASC'
	 THEN T.ID END ASC, 
	 CASE WHEN @sortColumn = 'ID' AND @sortOrder = 'DESC'
	 THEN T.ID END DESC ,

	 CASE WHEN @sortColumn = 'Code' AND @sortOrder = 'ASC'
	 THEN T.Code END ASC, 
	 CASE WHEN @sortColumn = 'Code' AND @sortOrder = 'DESC'
	 THEN T.Code END DESC ,

	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'ASC'
	 THEN T.Name END ASC, 
	 CASE WHEN @sortColumn = 'Name' AND @sortOrder = 'DESC'
	 THEN T.Name END DESC ,

	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'ASC'
	 THEN T.Description END ASC, 
	 CASE WHEN @sortColumn = 'Description' AND @sortOrder = 'DESC'
	 THEN T.Description END DESC ,

	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'ASC'
	 THEN T.ClientID END ASC, 
	 CASE WHEN @sortColumn = 'ClientID' AND @sortOrder = 'DESC'
	 THEN T.ClientID END DESC ,

	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'ASC'
	 THEN T.ParentProgramID END ASC, 
	 CASE WHEN @sortColumn = 'ParentProgramID' AND @sortOrder = 'DESC'
	 THEN T.ParentProgramID END DESC ,

	 CASE WHEN @sortColumn = 'CallFee' AND @sortOrder = 'ASC'
	 THEN T.CallFee END ASC, 
	 CASE WHEN @sortColumn = 'CallFee' AND @sortOrder = 'DESC'
	 THEN T.CallFee END DESC ,

	 CASE WHEN @sortColumn = 'DispatchFee' AND @sortOrder = 'ASC'
	 THEN T.DispatchFee END ASC, 
	 CASE WHEN @sortColumn = 'DispatchFee' AND @sortOrder = 'DESC'
	 THEN T.DispatchFee END DESC ,

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

