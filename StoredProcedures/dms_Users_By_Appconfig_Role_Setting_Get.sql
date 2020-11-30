IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Users_By_Appconfig_Role_Setting_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Users_By_Appconfig_Role_Setting_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO

/*
	EXEC dms_Users_By_Appconfig_Role_Setting_Get @ApplicationConguration = 'RolesThatCanRequestGiftCard'
*/

CREATE PROCEDURE [dms_Users_By_Appconfig_Role_Setting_Get](
	@ApplicationConguration NVARCHAR(100) = NULL 
 )
AS
BEGIN
	SET NOCOUNT ON    
	SET FMTONLY OFF    
  
	DECLARE @appConfigKeyValue NVARCHAR(MAX)
	SELECT @appConfigKeyValue = Value FROM ApplicationConfiguration WHERE Name LIKE @ApplicationConguration
	
	SELECT 
		DISTINCT U.*
	FROM
		[User] U
		INNER JOIN aspnet_Users AU WITH(NOLOCK) ON AU.UserId = U.aspnet_UserID
		INNER JOIN aspnet_UsersInRoles AUR WITH(NOLOCK) ON AUR.UserId = AU.UserId
		INNER JOIN aspnet_Roles AR WITH(NOLOCK) ON AR.RoleId = AUR.RoleId
		INNER JOIN aspnet_applications AA WITH(NOLOCK) ON AA.ApplicationId = AU.ApplicationId
	WHERE
		AA.ApplicationName = 'DMS'
		AND AR.RoleName IN (SELECT Item FROM [dbo].[fnSplitString](@appConfigKeyValue,','))
END
GO
