IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Users_Or_Roles_For_Notification_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Users_Or_Roles_For_Notification_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dms_Users_Or_Roles_For_Notification_Get] 2
 CREATE PROCEDURE [dbo].[dms_Users_Or_Roles_For_Notification_Get](
 @recipientTypeID INT = NULL
 )
 AS
 BEGIN
 DECLARE @ApplicationID UNIQUEIDENTIFIER
 DECLARE @RolesInAddNotificationList NVARCHAR(100)
 DECLARE @Role NVARCHAR(100)
 SET @RolesInAddNotificationList =(SELECT Value FROM ApplicationConfiguration WHERE Name = 'RolesInAddNotificationList')
 SET @ApplicationID = (SELECT ApplicationId FROM aspnet_Applications where ApplicationName='DMS')
 
	 IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	 BEGIN
	 
		;WITH wUsers
		AS
		(
			SELECT	U.UserId AS ID,
					U.UserName AS Name,
					[dbo].[fnIsUserConnected](U.UserName) AS IsConnected
			FROM aspnet_Users U WITH (NOLOCK)
			WHERE U.ApplicationId = @ApplicationID		
		)
		
		SELECT	W.ID,
				W.Name
		FROM	wUsers W 
		WHERE	W.IsConnected = 1
	 
	 END
	 ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role') )
	 BEGIN
		
		if LEN(@RolesInAddNotificationList) > 0 SET @RolesInAddNotificationList = @RolesInAddNotificationList + ',' 
		CREATE TABLE #tempResults(role VARCHAR(100))

		WHILE LEN(@RolesInAddNotificationList) > 0 
		BEGIN
		   SELECT @Role = LTRIM(SUBSTRING(@RolesInAddNotificationList, 1, CHARINDEX(',', @RolesInAddNotificationList) - 1))
		   INSERT INTO #tempResults (role) VALUES (@Role)
		   SELECT @RolesInAddNotificationList = SUBSTRING(@RolesInAddNotificationList, CHARINDEX(',', @RolesInAddNotificationList) + 1, LEN(@RolesInAddNotificationList))
		END
		
		SELECT	R.RoleId AS ID,
						R.RoleName AS Name		
				FROM	aspnet_Roles R WITH (NOLOCK)
				WHERE	R.ApplicationId = @ApplicationID
				AND     R.RoleName IN (select role from #tempResults)
		DROP TABLE #tempResults
		 
	 END
 END