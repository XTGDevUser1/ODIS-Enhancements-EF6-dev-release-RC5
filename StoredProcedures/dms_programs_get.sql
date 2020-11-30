IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_programs_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_programs_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
-- EXEC [dbo].[dms_programs_get] '20EE6D5C-6B06-43E1-A723-D53FD6D593B5'
-- EXEC [dbo].[dms_programs_get] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB'

-- EXEC [dbo].[dms_programs_get] '20EE6D5C-6B06-43E1-A723-D53FD6D593B5'    
-- EXEC [dbo].[dms_programs_get] 'BEB5FA18-50CE-499D-BB62-FFB9585242AB',14   
   
CREATE PROC [dbo].[dms_programs_get](    
@userID UNIQUEIDENTIFIER = NULL,    
@currentOrganizationID INT = NULL    
)    
AS    
BEGIN    
DECLARE @isAdmin BIT = 0    
     
 SELECT @isAdmin = 1 FROM aspnet_UsersInRoles U JOIN aspnet_Roles R ON U.RoleId = R.RoleId    
 WHERE U.UserId = @userId AND R.LoweredRoleName = 'sysadmin'    
 
 IF @isAdmin = 1    
 BEGIN    
  SELECT P.ID,P.Name    
  FROM [dbo].[Program] P     
  where P.IsActive = 1 -- AB    
 END    
 ELSE    
 BEGIN    
     
 IF (@currentOrganizationID IS NULL)    
 BEGIN    
  SELECT @currentOrganizationID = OrganizationID     
    FROM [dbo].[User] U WITH (NOLOCK)     
    WHERE U.aspnet_UserID = @userID    
 END    
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
   SELECT P.ID,    
     P.Name    
   FROM [dbo].[aspnet_Users] U WITH (NOLOCK)       
   INNER JOIN [dbo].[User] UP WITH (NOLOCK) ON UP.aspnet_UserID = U.UserId    
   INNER JOIN [dbo].[Organization] O WITH (NOLOCK) ON UP.OrganizationID = O.ID    
   INNER JOIN [dbo].[#tmpOrgHierarchy] T WITH (NOLOCK) ON T.ID = O.ID    
   INNER JOIN [dbo].[OrganizationClient] OC WITH (NOLOCK) ON O.ID = OC.OrganizationID    
   INNER JOIN [dbo].[Program] P WITH (NOLOCK) ON P.ClientID = OC.ClientID    
   WHERE (U.UserId = @userID )AND P.IsActive = 1    
       
  )    
  SELECT W.ID,W.Name      
  FROM wResults W    
      
  DROP TABLE #tmpOrgHierarchy    
 END    
END
GO



