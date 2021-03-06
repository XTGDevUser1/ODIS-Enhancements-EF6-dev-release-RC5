/****** Object:  UserDefinedFunction [dbo].[fnc_GetOrganizationsForUser]    Script Date: 09/03/2012 15:48:18 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnc_GetOrganizationsForUser]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnc_GetOrganizationsForUser]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fnc_GetOrganizationsForUser] ( @userID UNIQUEIDENTIFIER = NULL )
RETURNS @OrganizationsForUser TABLE
   (
    OrganizationID     int,
    Name nvarchar(50)
   )
AS
BEGIN

	DECLARE @isAdmin BIT = 0
	DECLARE @currentOrganizationID INT

	SET @currentOrganizationID = NULL

	SELECT @isAdmin = 1 FROM aspnet_UsersInRoles UIR 
	JOIN aspnet_Roles R ON UIR.RoleId = R.RoleId
	WHERE UIR.UserId = @userId AND R.LoweredRoleName = 'sysadmin'
    
    --IF SYSADMIN THEN GRAB ALL ORGS AND SKIP RECURSION LOGIC
	IF @isAdmin = 1
	BEGIN
		;WITH wResults
		AS
		(
			SELECT	O.ID,
					O.Name AS OrganizationName
			FROM	[dbo].[Organization] O	WITH (NOLOCK) 
				
		)
		INSERT INTO @OrganizationsForUser
		SELECT	W.ID,
				W.OrganizationName
		FROM	wResults W		
		ORDER BY W.OrganizationName ASC

      END
      ELSE
      BEGIN
		   ;WITH wOrgHierarchy
			AS
			(
				SELECT	O.ID,
				O.Name
				FROM	[dbo].[Organization] O WITH (NOLOCK)
				WHERE	O.ID = (SELECT TOP 1 [OrganizationID] FROM [User] WHERE aspnet_UserID = @UserID)
				AND O.IsActive = 1
				
				UNION ALL
				
				SELECT	C.ID,
				C.Name 
				FROM	[dbo].[Organization] C WITH (NOLOCK)
				JOIN	wOrgHierarchy W ON C.ParentOrganizationID = W.ID	
				WHERE C.IsActive = 1 
			)
			
			INSERT INTO @OrganizationsForUser 
			SELECT	ID, 
			Name
			FROM	wOrgHierarchy
	END

RETURN 


END
GO
