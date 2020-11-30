-- Setup Add Comment and Add Contact buttons for SysAdmin
DECLARE @AddComment INT
DECLARE @AddContact INT 
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT 

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_COMMENT')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('BUTTON_VENDOR_ACTIVITY_ADD_COMMENT',NULL,NULL) 
	END
SET @AddComment = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_COMMENT')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_CONTACT')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('BUTTON_VENDOR_ACTIVITY_ADD_CONTACT',NULL,NULL) 
	END
SET @AddContact = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_CONTACT')

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')

SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @AddComment AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@AddComment,@RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @AddContact AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@AddContact,@RoleID,@AccessTypeID)
	END
