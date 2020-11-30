IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Securable_IsAccessible]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Securable_IsAccessible] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

CREATE PROC dms_Securable_IsAccessible(@userID UNIQUEIDENTIFIER = NULL,@securableName NVARCHAR(MAX)= NULL)
AS
	BEGIN
	DECLARE @userRoles AS TABLE(
		RoleId UNIQUEIDENTIFIER
	)
	INSERT INTO @userRoles 
		   SELECT UR.RoleId FROM aspnet_Users AU 
		   JOIN aspnet_UsersInRoles UR ON AU.UserId = UR.UserId
		   WHERE AU.UserId = @userID 

	SELECT	
		   DISTINCT
		   S.ID,
		   S.FriendlyName 
	FROM   Securable S
	JOIN   AccessControlList  ACL ON S.ID = ACL.SecurableID
	WHERE  S.FriendlyName = @securableName
	AND    ACL.RoleID IN (SELECT UR.RoleID FROM @userRoles UR)
END
