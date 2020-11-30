INSERT INTO Securable VALUES('MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT',NULL,NULL)

DECLARE @SecurableID INT
SET @SecurableID = (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_ADMIN_SECURABLE_MANAGEMENT')
DECLARE @RoleID UNIQUEIDENTIFIER
SET @RoleID = (SELECT RoleID FROM aspnet_Roles R
			   JOIN aspnet_Applications  A
			   ON R.ApplicationId = A.ApplicationId
			   WHERE A.ApplicationName = 'DMS'
			   AND R.LoweredRoleName = 'sysadmin')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE RoleID = @RoleID AND SecurableID = @SecurableID)
BEGIN
	INSERT INTO AccessControlList VALUES(@SecurableID,@RoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite'))
END

GO

ALTER TABLE ProgramServiceEventLimit ADD IsLimitDurationSinceMemberRenewal BIT NULL
			 