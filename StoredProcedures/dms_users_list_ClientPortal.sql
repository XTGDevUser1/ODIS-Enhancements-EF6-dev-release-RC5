IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_users_list_ClientPortal]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_users_list_ClientPortal] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 



-- EXEC  [dbo].[dms_users_list] 'A80C0C2B-E81D-464A-BF85-16310D61286A',NULL,1,100,10,'UserName','ASC'  
 
 CREATE PROCEDURE [dbo].[dms_users_list_ClientPortal](   
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
UserNameOperator="-1"   
FirstNameOperator="-1"   
LastNameOperator="-1"   
OrganizationNameOperator="-1"   
RolesOperator="-1"   
DataGroupsOperator="-1"   
IsApprovedOperator="-1"   
EmailOperator="-1"  
 ></Filter></ROW>'  
END  
EXEC sp_xml_preparedocument @idoc OUTPUT, @whereClauseXML  
  
DECLARE @tmpForWhereClause TABLE  
(  
UserNameOperator INT NOT NULL,  
UserNameValue nvarchar(255) NULL,  
FirstNameOperator INT NOT NULL,  
FirstNameValue nvarchar(100) NULL,  
LastNameOperator INT NOT NULL,  
LastNameValue nvarchar(100) NULL,  
OrganizationNameOperator INT NOT NULL,  
OrganizationNameValue nvarchar(100) NULL,  
RolesOperator INT NOT NULL,  
RolesValue nvarchar(255) NULL,  
DataGroupsOperator INT NOT NULL,  
DataGroupsValue nvarchar(255) NULL,  
IsApprovedOperator INT NOT NULL,  
IsApprovedValue BIT NULL,  
EmailOperator INT NOT NULL,  
EmailValue nvarchar(100) NULL  
)  
  
DECLARE @tmpResults TABLE (  
   
 ID int  NULL ,  
 UserID UNIQUEIDENTIFIER NULL,  
 UserName nvarchar(MAX)  NULL ,  
 FirstName nvarchar(MAX)  NULL ,  
 LastName nvarchar(MAX)  NULL ,  
 OrganizationName nvarchar(MAX)  NULL ,  
 Roles nvarchar(MAX)  NULL ,  
 DataGroups nvarchar(MAX)  NULL ,  
 DisplayOrder int  NULL ,  
 IsApproved BIT  NULL,  
 Email NVARCHAR(MAX) NULL   
)   
  
DECLARE @FinalResults TABLE (   
 [RowNum] [bigint] NOT NULL IDENTITY(1,1),  
 ID int  NULL ,  
 UserID UNIQUEIDENTIFIER NULL,  
 UserName nvarchar(MAX)  NULL ,  
 FirstName nvarchar(MAX)  NULL ,  
 LastName nvarchar(MAX)  NULL ,  
 OrganizationName nvarchar(MAX)  NULL ,  
 Roles nvarchar(MAX)  NULL ,  
 DataGroups nvarchar(MAX)  NULL ,  
 IsApproved BIT  NULL ,  
 DisplayOrder int  NULL ,  
 Email NVARCHAR(MAX) NULL  
)   
  
INSERT INTO @tmpForWhereClause  
SELECT    
 ISNULL(UserNameOperator,-1),  
 UserNameValue ,  
 ISNULL(FirstNameOperator,-1),  
 FirstNameValue ,  
 ISNULL(LastNameOperator,-1),  
 LastNameValue ,  
 ISNULL(OrganizationNameOperator,-1),  
 OrganizationNameValue ,  
 ISNULL(RolesOperator,-1),  
 RolesValue ,  
 ISNULL(DataGroupsOperator,-1),  
 DataGroupsValue ,  
 ISNULL(IsApprovedOperator,-1),  
 IsApprovedValue ,  
 ISNULL(EmailOperator,-1),  
 EmailValue   
FROM OPENXML (@idoc,'/ROW/Filter',1) WITH (  
UserNameOperator INT,  
UserNameValue nvarchar(255)   
,FirstNameOperator INT,  
FirstNameValue nvarchar(100)   
,LastNameOperator INT,  
LastNameValue nvarchar(100)   
,OrganizationNameOperator INT,  
OrganizationNameValue nvarchar(100)   
,RolesOperator INT,  
RolesValue nvarchar(255)   
,DataGroupsOperator INT,  
DataGroupsValue nvarchar(255)   
,IsApprovedOperator INT,  
IsApprovedValue BIT   
,EmailOperator INT,  
EmailValue nvarchar(100)   
 )   
  
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
  
 DECLARE @isAdmin BIT = 0  
 DECLARE @currentOrganizationID INT  
  
 SET @currentOrganizationID = NULL  
  
  
 --SELECT @isAdmin = 1 FROM aspnet_UsersInRoles U JOIN aspnet_Roles R ON U.RoleId = R.RoleId  
 --WHERE U.UserId = @userId AND R.LoweredRoleName = 'sysadmin'  
  
  
 IF @isAdmin = 1  
 BEGIN  
  ;WITH wResults  
  AS  
  (  
   SELECT UP.ID,  
     U.UserId,  
     U.UserName,  
     UP.FirstName,  
     UP.LastName,  
     R.RoleName,  
     O.Name AS OrganizationName,  
     0 AS DisplayOrder,  
     DG.Name AS DataGroupName,  
     M.IsApproved,  
     M.Email  
   FROM [dbo].[aspnet_Users] U WITH (NOLOCK)  
   LEFT JOIN [dbo].[aspnet_Membership] M WITH (NOLOCK) ON U.UserId = M.UserId  
   LEFT JOIN [dbo].[aspnet_applications] A WITH (NOLOCK) ON A.ApplicationId = M.ApplicationId  
   LEFT JOIN [dbo].[aspnet_UsersInRoles] UR WITH (NOLOCK) ON U.UserId = UR.UserId  
   LEFT JOIN [dbo].[aspnet_Roles] R WITH (NOLOCK) ON UR.RoleId = R.RoleId  
   LEFT JOIN [dbo].[User] UP WITH (NOLOCK) ON UP.aspnet_UserID = U.UserId  
   LEFT JOIN [dbo].[Organization] O WITH (NOLOCK) ON UP.OrganizationID = O.ID  
   LEFT JOIN [dbo].[UserDataGroup] UDG WITH (NOLOCK) ON UDG.UserID = UP.ID  
   LEFT JOIN [dbo].[DataGroup] DG WITH (NOLOCK) ON DG.ID = UDG.DataGroupID  
   WHERE A.ApplicationName = 'ClientPortal'  
  )  
  INSERT INTO @tmpResults  
  SELECT W1.ID,  
    W1.UserId,  
    W1.UserName,  
    W1.FirstName,  
    W1.LastName,  
    W1.OrganizationName,  
    [dbo].[fnConcatenate]( DISTINCT W1.RoleName) AS Roles,  
    [dbo].[fnConcatenate]( DISTINCT W1.DataGroupName) AS DataGroups,   
    W1.DisplayOrder,  
    W1.IsApproved,  
    W1.Email  
    
  FROM wResults W1   
  GROUP BY W1.ID,  
     W1.UserId,  
     W1.UserName,  
     W1.FirstName,  
     W1.LastName,  
     W1.OrganizationName,  
     W1.DisplayOrder,  
     W1.IsApproved,  
     W1.Email  
  ORDER BY W1.UserName ASC  
 END  
 ELSE  
 BEGIN  
  
  SELECT @currentOrganizationID = OrganizationID   
  FROM [dbo].[User] U WITH (NOLOCK)   
  WHERE U.aspnet_UserID = @userID  
  -- Traverse through Org hierarchy (from current to all children)  
  ;WITH wOrgHierarchy  
  AS  
  (  
   SELECT O.ID,  
     O.Name,  
     0 AS [DisplayOrder]  
   FROM [dbo].[Organization] O WITH (NOLOCK)  
   WHERE O.ID = @currentOrganizationID  
     
   UNION ALL  
     
   SELECT C.ID,  
     C.Name,  
     W.[DisplayOrder] + 1 AS DisplayOrder  
   FROM [dbo].[Organization] C WITH (NOLOCK)  
   JOIN wOrgHierarchy W ON C.ParentOrganizationID = W.ID   
  )  
  
  SELECT *  
  INTO #tmpOrgHierarchy  
  FROM wOrgHierarchy  
    
  ;WITH wResults  
  AS  
  (  
   SELECT 
     DISTINCT
	 UP.ID,  
     U.UserId,  
     U.UserName,  
     UP.FirstName,  
     UP.LastName,  
     R.RoleName,  
     O.Name OrganizationName,  
     T.DisplayOrder,  
     DG.Name AS DataGroupName,  
     M.IsApproved,  
     M.Email  
   FROM [dbo].[aspnet_Users] U WITH (NOLOCK)  
   LEFT JOIN [dbo].[aspnet_Membership] M WITH (NOLOCK) ON U.UserId = M.UserId  
   LEFT JOIN [dbo].[aspnet_applications] A WITH (NOLOCK) ON A.ApplicationId = M.ApplicationId  
   LEFT JOIN [dbo].[aspnet_UsersInRoles] UR WITH (NOLOCK) ON U.UserId = UR.UserId  
   LEFT JOIN [dbo].[aspnet_Roles] R WITH (NOLOCK) ON UR.RoleId = R.RoleId  
   LEFT JOIN [dbo].[User] UP WITH (NOLOCK) ON UP.aspnet_UserID = U.UserId  
   LEFT JOIN [dbo].[Organization] O WITH (NOLOCK) ON UP.OrganizationID = O.ID  
   LEFT JOIN [dbo].[#tmpOrgHierarchy] T WITH (NOLOCK) ON T.ID = O.ID  
   LEFT JOIN [dbo].[UserDataGroup] UDG WITH (NOLOCK) ON UDG.UserID = UP.ID  
   LEFT JOIN [dbo].[DataGroup] DG WITH (NOLOCK) ON DG.ID = UDG.DataGroupID  
   WHERE M.IsApproved = 1  
   AND A.ApplicationName = 'ClientPortal'  
  )  
  INSERT INTO @tmpResults  
  SELECT W1.ID,  
    W1.UserId,  
    W1.UserName,  
    W1.FirstName,  
    W1.LastName,  
    W1.OrganizationName,  
    [dbo].[fnConcatenate]( DISTINCT W1.RoleName) AS Roles,  
    [dbo].[fnConcatenate]( DISTINCT W1.DataGroupName) AS DataGroups,     
    W1.DisplayOrder,  
    W1.IsApproved,  
    W1.Email  
    
  FROM wResults W1   
  GROUP BY W1.ID,  
     W1.UserId,  
     W1.UserName,  
     W1.FirstName,  
     W1.LastName,  
     W1.OrganizationName,  
     W1.DisplayOrder,  
     W1.IsApproved,  
     W1.Email  
  ORDER BY W1.UserName ASC  
    
  DROP TABLE #tmpOrgHierarchy  
    
 END  
  
--- LOGIC : END  
  
INSERT INTO @FinalResults  
SELECT   
 T.ID,  
 T.UserID,  
 T.UserName,  
 T.FirstName,  
 T.LastName,  
 T.OrganizationName,  
 T.Roles,  
 T.DataGroups,  
 T.IsApproved,  
 T.DisplayOrder,  
 T.Email  
FROM @tmpResults T,  
@tmpForWhereClause TMP   
WHERE (   
  
 (   
  ( TMP.UserNameOperator = -1 )   
 OR   
  ( TMP.UserNameOperator = 0 AND T.UserName IS NULL )   
 OR   
  ( TMP.UserNameOperator = 1 AND T.UserName IS NOT NULL )   
 OR   
  ( TMP.UserNameOperator = 2 AND T.UserName = TMP.UserNameValue )   
 OR   
  ( TMP.UserNameOperator = 3 AND T.UserName <> TMP.UserNameValue )   
 OR   
  ( TMP.UserNameOperator = 4 AND T.UserName LIKE TMP.UserNameValue + '%')   
 OR   
  ( TMP.UserNameOperator = 5 AND T.UserName LIKE '%' + TMP.UserNameValue )   
 OR   
  ( TMP.UserNameOperator = 6 AND T.UserName LIKE '%' + TMP.UserNameValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.FirstNameOperator = -1 )   
 OR   
  ( TMP.FirstNameOperator = 0 AND T.FirstName IS NULL )   
 OR   
  ( TMP.FirstNameOperator = 1 AND T.FirstName IS NOT NULL )   
 OR   
  ( TMP.FirstNameOperator = 2 AND T.FirstName = TMP.FirstNameValue )   
 OR   
  ( TMP.FirstNameOperator = 3 AND T.FirstName <> TMP.FirstNameValue )   
 OR   
  ( TMP.FirstNameOperator = 4 AND T.FirstName LIKE TMP.FirstNameValue + '%')   
 OR   
  ( TMP.FirstNameOperator = 5 AND T.FirstName LIKE '%' + TMP.FirstNameValue )   
 OR   
  ( TMP.FirstNameOperator = 6 AND T.FirstName LIKE '%' + TMP.FirstNameValue + '%' )   
 )   
 AND   
  
 (   
  ( TMP.EmailOperator = -1 )   
 OR   
  ( TMP.EmailOperator = 0 AND T.Email IS NULL )   
 OR   
  ( TMP.EmailOperator = 1 AND T.Email IS NOT NULL )   
 OR   
  ( TMP.EmailOperator = 2 AND T.Email = TMP.EmailValue )   
 OR   
  ( TMP.EmailOperator = 3 AND T.Email <> TMP.EmailValue )   
 OR   
  ( TMP.EmailOperator = 4 AND T.Email LIKE TMP.EmailValue + '%')   
 OR   
  ( TMP.EmailOperator = 5 AND T.Email LIKE '%' + TMP.EmailValue )   
 OR   
  ( TMP.EmailOperator = 6 AND T.Email LIKE '%' + TMP.EmailValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.LastNameOperator = -1 )   
 OR   
  ( TMP.LastNameOperator = 0 AND T.LastName IS NULL )   
 OR   
  ( TMP.LastNameOperator = 1 AND T.LastName IS NOT NULL )   
 OR   
  ( TMP.LastNameOperator = 2 AND T.LastName = TMP.LastNameValue )   
 OR   
  ( TMP.LastNameOperator = 3 AND T.LastName <> TMP.LastNameValue )   
 OR   
  ( TMP.LastNameOperator = 4 AND T.LastName LIKE TMP.LastNameValue + '%')   
 OR   
  ( TMP.LastNameOperator = 5 AND T.LastName LIKE '%' + TMP.LastNameValue )   
 OR   
  ( TMP.LastNameOperator = 6 AND T.LastName LIKE '%' + TMP.LastNameValue + '%' )   
 )   
  
 AND   
  
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
  ( TMP.RolesOperator = -1 )   
 OR   
  ( TMP.RolesOperator = 0 AND T.Roles IS NULL )   
 OR   
  ( TMP.RolesOperator = 1 AND T.Roles IS NOT NULL )   
 OR   
  ( TMP.RolesOperator = 2 AND T.Roles = TMP.RolesValue )   
 OR   
  ( TMP.RolesOperator = 3 AND T.Roles <> TMP.RolesValue )   
 OR   
  ( TMP.RolesOperator = 4 AND T.Roles LIKE TMP.RolesValue + '%')   
 OR   
  ( TMP.RolesOperator = 5 AND T.Roles LIKE '%' + TMP.RolesValue )   
 OR   
  ( TMP.RolesOperator = 6 AND T.Roles LIKE '%' + TMP.RolesValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.DataGroupsOperator = -1 )   
 OR   
  ( TMP.DataGroupsOperator = 0 AND T.DataGroups IS NULL )   
 OR   
  ( TMP.DataGroupsOperator = 1 AND T.DataGroups IS NOT NULL )   
 OR   
  ( TMP.DataGroupsOperator = 2 AND T.DataGroups = TMP.DataGroupsValue )   
 OR   
  ( TMP.DataGroupsOperator = 3 AND T.DataGroups <> TMP.DataGroupsValue )   
 OR   
  ( TMP.DataGroupsOperator = 4 AND T.DataGroups LIKE TMP.DataGroupsValue + '%')   
 OR   
  ( TMP.DataGroupsOperator = 5 AND T.DataGroups LIKE '%' + TMP.DataGroupsValue )   
 OR   
  ( TMP.DataGroupsOperator = 6 AND T.DataGroups LIKE '%' + TMP.DataGroupsValue + '%' )   
 )   
  
 AND   
  
 (   
  ( TMP.IsApprovedOperator = -1 )   
 OR   
  ( TMP.IsApprovedOperator = 0 AND T.IsApproved IS NULL )   
 OR   
  ( TMP.IsApprovedOperator = 1 AND T.IsApproved IS NOT NULL )   
 OR   
  ( TMP.IsApprovedOperator = 2 AND T.IsApproved = TMP.IsApprovedValue )   
 OR   
  ( TMP.IsApprovedOperator = 3 AND T.IsApproved <> TMP.IsApprovedValue )  
 )   
  
 AND   
 1 = 1   
 )   
 ORDER BY   
  CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'ASC'  
  THEN T.UserName END ASC,   
  CASE WHEN @sortColumn = 'UserName' AND @sortOrder = 'DESC'  
  THEN T.UserName END DESC ,  
  
  CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'ASC'  
  THEN T.FirstName END ASC,   
  CASE WHEN @sortColumn = 'FirstName' AND @sortOrder = 'DESC'  
  THEN T.FirstName END DESC ,  
    
  CASE WHEN @sortColumn = 'Email' AND @sortOrder = 'ASC'  
  THEN T.Email END ASC,   
  CASE WHEN @sortColumn = 'Email' AND @sortOrder = 'DESC'  
  THEN T.Email END DESC ,  
  
  CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'ASC'  
  THEN T.LastName END ASC,   
  CASE WHEN @sortColumn = 'LastName' AND @sortOrder = 'DESC'  
  THEN T.LastName END DESC ,  
  
  CASE WHEN @sortColumn = 'OrganizationName' AND @sortOrder = 'ASC'  
  THEN T.OrganizationName END ASC,   
  CASE WHEN @sortColumn = 'OrganizationName' AND @sortOrder = 'DESC'  
  THEN T.OrganizationName END DESC ,  
  
  CASE WHEN @sortColumn = 'Roles' AND @sortOrder = 'ASC'  
  THEN T.Roles END ASC,   
  CASE WHEN @sortColumn = 'Roles' AND @sortOrder = 'DESC'  
  THEN T.Roles END DESC ,  
  
  CASE WHEN @sortColumn = 'DataGroups' AND @sortOrder = 'ASC'  
  THEN T.DataGroups END ASC,   
  CASE WHEN @sortColumn = 'DataGroups' AND @sortOrder = 'DESC'  
  THEN T.DataGroups END DESC ,  
  
  CASE WHEN @sortColumn = 'IsApproved' AND @sortOrder = 'ASC'  
  THEN T.IsApproved END ASC,   
  CASE WHEN @sortColumn = 'IsApproved' AND @sortOrder = 'DESC'  
  THEN T.IsApproved END DESC   
  
  
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
   