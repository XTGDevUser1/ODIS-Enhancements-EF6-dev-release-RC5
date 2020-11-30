DECLARE @applicationID AS UNIQUEIDENTIFIER
SELECT  @applicationID =  ApplicationId FROM aspnet_Applications WHERE ApplicationName = 'DMS'


IF NOT EXISTS (SELECT ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_CLIENT_CLIENTREP_MAINTENANCE')
BEGIN
	INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
	SELECT 'MENU_LEFT_CLIENT_CLIENTREP_MAINTENANCE',(SELECT ID FROM Securable where FriendlyName='MENU_TOP_CLIENT'),NULL
END
DECLARE @SecurableClientRepMaintenance INT
SET @SecurableClientRepMaintenance = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_CLIENT_CLIENTREP_MAINTENANCE')

DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @Denied INT
DECLARE @ReadOnly INT
DECLARE @ReadWrite INT

SET @Denied = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'Denied')
SET @ReadOnly = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')
SET @ReadWrite = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

SET @RoleID = (SELECT RoleID FROM aspnet_Roles WHERE LOWER(RoleName) = 'sysadmin' AND ApplicationId = @applicationID)
IF NOT EXISTS (SELECT ID FROM AccessControlList WHERE SecurableID = @SecurableClientRepMaintenance AND RoleID = @RoleID )
BEGIN INSERT AccessControlList (SecurableID, RoleID, AccessTypeID) VALUES (@SecurableClientRepMaintenance, @RoleID, @ReadWrite) END

SET @RoleID = (SELECT RoleID FROM aspnet_Roles WHERE LOWER(RoleName) = 'clientrelationsmgr' AND ApplicationId = @applicationID)
IF NOT EXISTS (SELECT ID FROM AccessControlList WHERE SecurableID = @SecurableClientRepMaintenance AND RoleID = @RoleID )
BEGIN INSERT AccessControlList (SecurableID, RoleID, AccessTypeID) VALUES (@SecurableClientRepMaintenance, @RoleID, @ReadWrite) END

SET @RoleID = (SELECT RoleID FROM aspnet_Roles WHERE LOWER(RoleName) = 'clientrelations' AND ApplicationId = @applicationID)
IF NOT EXISTS (SELECT ID FROM AccessControlList WHERE SecurableID = @SecurableClientRepMaintenance AND RoleID = @RoleID )
BEGIN INSERT AccessControlList (SecurableID, RoleID, AccessTypeID) VALUES (@SecurableClientRepMaintenance, @RoleID, @ReadWrite) END



IF NOT EXISTS(SELECT * FROM [Event] where Name='CreateClientRep')
BEGIN
	INSERT INTO [Event](
		EventTypeID,
		EventCategoryID,
		Name,
		[Description],
		IsShownOnScreen,
		IsActive,
		CreateBy,
		CreateDate
	) VALUES(
		(SELECT ID FROM EventType WHERE Name = 'User'),
		(SELECT ID FROM EventCategory WHERE Name = 'Client'),
		'CreateClientRep',
		'Create a Client Rep',
		1,
		1,
		'sysadmin',
		GETDATE()
	)
END

IF NOT EXISTS(SELECT * FROM [Event] where Name='UpdateClientRep')
BEGIN
	INSERT INTO [Event](
		EventTypeID,
		EventCategoryID,
		Name,
		[Description],
		IsShownOnScreen,
		IsActive,
		CreateBy,
		CreateDate
	) VALUES(
		(SELECT ID FROM EventType WHERE Name = 'User'),
		(SELECT ID FROM EventCategory WHERE Name = 'Client'),
		'UpdateClientRep',
		'Update a Client Rep',
		1,
		1,
		'sysadmin',
		GETDATE()
	)
END

IF NOT EXISTS(Select * from Entity where Name='ClientRep')
BEGIN
	INSERT INTO Entity(Name,IsAudited)
	VALUES('ClientRep',0)
END


ALTER TABLE Feedback
ADD ClientID INT NULL

ALTER TABLE [dbo].[Feedback]  WITH CHECK ADD  CONSTRAINT [FK_Feedback_Client] FOREIGN KEY([ClientID])
REFERENCES [dbo].[Client] ([ID])
GO
ALTER TABLE [dbo].[Feedback] CHECK CONSTRAINT [FK_Feedback_Client]
GO