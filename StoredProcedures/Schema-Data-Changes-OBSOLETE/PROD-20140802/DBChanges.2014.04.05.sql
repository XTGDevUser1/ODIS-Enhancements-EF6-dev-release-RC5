ALTER TABLE ServiceRequest
DROP COLUMN IsServiceEligible
GO

ALTER TABLE ServiceRequest
DROP COLUMN ServiceCoverageDescription
GO

ALTER TABLE ServiceRequest
DROP COLUMN ServiceEligiblityMessage
GO

ALTER TABLE ServiceRequest
DROP COLUMN IsServiceCovered
GO

Alter table PurchaseOrder
Add CoverageLimitMileage money NULL
GO

Alter table PurchaseOrder
Add MileageUOM  NVARCHAR(50) NULL
GO

Alter table PurchaseOrder
Add IsServiceCoverageBestValue BIT NULL
GO

Alter table PurchaseOrder
Add ServiceEligibilityMessage  nvarchar(255) NULL
GO

--PO Change service
DECLARE @manager UNIQUEIDENTIFIER
DECLARE @vendorrep  UNIQUEIDENTIFIER
DECLARE @sysadmin UNIQUEIDENTIFIER
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT
DECLARE @Button INT

SET @manager = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Manager')
SET @vendorrep = (SELECT R.RoleId FROM aspnet_Roles R JOIN aspnet_Applications A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='VendorRep')
SET @sysadmin = (SELECT R.RoleId FROM aspnet_Roles R JOIN aspnet_Applications A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

-- Setup Securable
IF NOT EXISTS (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_PO_SERVICECOVERED_EDIT')
	BEGIN
	INSERT INTO [dbo].[Securable] ([FriendlyName], [ParentID], [SecurityContext])
		VALUES ('BUTTON_PO_SERVICECOVERED_EDIT', NULL, NULL)
	END

SET @Button = (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_PO_SERVICECOVERED_EDIT')

-- Setup Manager AccessControlList
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @Button AND RoleID = @manager)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@Button,@manager,@AccessTypeID)
	END


IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @Button AND RoleID = @vendorrep)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@Button,@vendorrep,@AccessTypeID)
	END


IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @Button AND RoleID = @sysadmin)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@Button,@sysadmin,@AccessTypeID)
	END
	
GO


-- Setup Event for Edit PO Service Coverage
IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'OverridePOServiceCovered')
	BEGIN
		INSERT 
			INTO [dbo].[Event] ([EventTypeID],[EventCategoryID],[Name],[Description],[IsShownOnScreen],[IsActive],[CreateBy],[CreateDate])
			VALUES (
				(SELECT ID FROM EventType WHERE Name = 'User')
				, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
				, 'OverridePOServiceCovered'
				, 'Override PO Service Covered'
				, 1
				, 1
				, 'System'
				, getdate()
				)
	END
GO



-- Setup Event for Edit PO Change Service 
IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'POChangeService')
	BEGIN
		INSERT 
			INTO [dbo].[Event] ([EventTypeID],[EventCategoryID],[Name],[Description],[IsShownOnScreen],[IsActive],[CreateBy],[CreateDate])
			VALUES (
				(SELECT ID FROM EventType WHERE Name = 'User')
				, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
				, 'POChangeService'
				, 'PO Change Service'
				, 1
				, 1
				, 'System'
				, getdate()
				)
	END
GO

IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'CopyPO')
	BEGIN
		INSERT 
			INTO [dbo].[Event] ([EventTypeID],[EventCategoryID],[Name],[Description],[IsShownOnScreen],[IsActive],[CreateBy],[CreateDate])
			VALUES (
				(SELECT ID FROM EventType WHERE Name = 'User')
				, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
				, 'CopyPO'
				, 'Copy PO'
				, 1
				, 1
				, 'System'
				, getdate()
				)
	END
GO


-- Setup Event for Edit PO Change Service 
IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'POChangeService')
	BEGIN
		INSERT 
			INTO [dbo].[Event] ([EventTypeID],[EventCategoryID],[Name],[Description],[IsShownOnScreen],[IsActive],[CreateBy],[CreateDate])
			VALUES (
				(SELECT ID FROM EventType WHERE Name = 'User')
				, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
				, 'POChangeService'
				, 'PO Change Service'
				, 1
				, 1
				, 'System'
				, getdate()
				)
	END
GO


