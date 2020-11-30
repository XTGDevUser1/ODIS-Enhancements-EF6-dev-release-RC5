IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Users_By_NextAction_Role_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Users_By_NextAction_Role_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

/*
	EXEC dms_Users_By_NextAction_Role_Get @nextActionID = 16
*/

CREATE PROCEDURE [dms_Users_By_NextAction_Role_Get](
	@nextActionID INT = NULL 
 )
AS
BEGIN
	SET NOCOUNT ON    
	SET FMTONLY OFF    
	
	DECLARE @tblNextActionRoles TABLE
	(
		RoleID UNIQUEIDENTIFIER NOT NULL
	)
	
	IF (@nextActionID IS NOT NULL)
	BEGIN	
		INSERT INTO @tblNextActionRoles (RoleID)
		SELECT	RoleID
		FROM	NextActionRole NR
		WHERE	NextActionID = @nextActionID
	END	
  
	IF ((SELECT COUNT(*) FROM @tblNextActionRoles) > 0 )
	BEGIN

		SELECT DISTINCT U.*
		FROM	[User] U
		INNER JOIN aspnet_Users AU WITH(NOLOCK) ON AU.UserId = U.aspnet_UserID
		INNER JOIN aspnet_Membership M WITH(NOLOCK) ON AU.UserId = M.UserId
		INNER JOIN aspnet_UsersInRoles AUR WITH(NOLOCK) ON AUR.UserId = AU.UserId
		INNER JOIN aspnet_Roles AR WITH(NOLOCK) ON AR.RoleId = AUR.RoleId
		INNER JOIN aspnet_applications AA WITH(NOLOCK) ON AA.ApplicationId = AU.ApplicationId
		INNER JOIN	@tblNextActionRoles T ON AR.RoleId = T.RoleId
		WHERE	AA.ApplicationName = 'DMS'
		AND		ISNULL(M.IsApproved,0) = 1		
	END
	ELSE
	BEGIN
		SELECT DISTINCT U.*
		FROM	[User] U
		INNER JOIN aspnet_Users AU WITH(NOLOCK) ON AU.UserId = U.aspnet_UserID
		INNER JOIN aspnet_Membership M WITH(NOLOCK) ON AU.UserId = M.UserId
		INNER JOIN aspnet_UsersInRoles AUR WITH(NOLOCK) ON AUR.UserId = AU.UserId
		INNER JOIN aspnet_Roles AR WITH(NOLOCK) ON AR.RoleId = AUR.RoleId
		INNER JOIN aspnet_applications AA WITH(NOLOCK) ON AA.ApplicationId = AU.ApplicationId
		WHERE	AA.ApplicationName = 'DMS'
		AND		ISNULL(M.IsApproved,0) = 1
			
	END
END
GO
