IF NOT EXISTS(SELECT * FROM Entity WHERE Name='BillingInvoiceDetail')
BEGIN

INSERT INTO [Entity] ([Name],[IsAudited])
VALUES('BillingInvoiceDetail',1)

END

IF NOT EXISTS(SELECT * FROM [Event] WHERE Name='UpdateBillingEventStatus')
BEGIN
INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES (2, 9, 'UpdateBillingEventStatus', 'Update Billing Event Status', 0, 1, NULL, NULL)

END

IF NOT EXISTS(SELECT * FROM [Event] WHERE Name='UpdateBillingEventDisposition')
BEGIN
INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES (2, 9, 'UpdateBillingEventDisposition', 'Update Billing Event Disposition', 0, 1, NULL, NULL)

END

GO

--
-- Close Month Script
--

-- Setup Securables for Open / Close buttons
DECLARE @ClientButtonOpenPeriod INT
DECLARE @ClientButtonClosePeriod INT
DECLARE @AccountingMgr UNIQUEIDENTIFIER
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT

SET @AccountingMgr = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='AccountingMgr')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'CLIENT_BUTTON_OPENPERIOD')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('CLIENT_BUTTON_OPENPERIOD',NULL,NULL) 
	END
SET @ClientButtonOpenPeriod = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'CLIENT_BUTTON_OPENPERIOD')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'CLIENT_BUTTON_CLOSEPERIOD')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('CLIENT_BUTTON_CLOSEPERIOD',NULL,NULL) 
	END
SET @ClientButtonClosePeriod = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'CLIENT_BUTTON_CLOSEPERIOD')

-- Setup AccountingMgr AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='AccountingMgr')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ClientButtonOpenPeriod AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ClientButtonOpenPeriod,@RoleID,@AccessTypeID)
	END
	
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ClientButtonClosePeriod AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ClientButtonClosePeriod,@RoleID,@AccessTypeID)
	END
	
-- Setup SysAdmin AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')  
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ClientButtonOpenPeriod AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ClientButtonOpenPeriod,@RoleID,@AccessTypeID)
	END
	
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ClientButtonClosePeriod AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ClientButtonClosePeriod,@RoleID,@AccessTypeID)
	END

-- Insert new BillingScheduleStatus
IF NOT EXISTS (SELECT * FROM BillingScheduleStatus WHERE Name = 'Pending')
	BEGIN  
      INSERT [dbo].[BillingScheduleStatus] ([Name], [Description], [Sequence], [IsActive]) 
		VALUES('PENDING','Pending',3,1)
	END

-- Insert new events

IF NOT EXISTS (SELECT * FROM Entity WHERE Name = 'BillingSchedule')
	BEGIN
		INSERT INTO [Entity]
			([Name]
			,[IsAudited])
		VALUES ('BillingSchedule',0)
	END

DECLARE @EventType INT = (SELECT ID FROM EventType WHERE Name = 'User')
DECLARE @EventCategory INT = (SELECT ID FROM EventCategory WHERE Name = 'Billing')

IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'OpenPeriod')
	BEGIN
		INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
		VALUES
           (@EventType, @EventCategory, 'OpenPeriod', 'Open New Billing Schedule Period', 1, 1, 'System', getdate())
	END

IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'ClosePeriod')
	BEGIN
		INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
		VALUES
           (@EventType, @EventCategory, 'ClosePeriod', 'Close Current Billing Schedule Period', 1, 1, 'System', getdate())
	END
	

	-- Vendor Summary Securables

	--
-- Script to create Securables for Vendor Summary Tab
-- and assign rights to these tabs
--

--select * from aspnet_roles where applicationid = (select ApplicationID from aspnet_Applications where ApplicationName= 'DMS')
--select * from Securable
--select * from AccessControlList
--select * from accesstype

DECLARE @accounting UNIQUEIDENTIFIER
DECLARE @claims UNIQUEIDENTIFIER
DECLARE @invoiceentry UNIQUEIDENTIFIER
DECLARE @manager UNIQUEIDENTIFIER
DECLARE @vendorrep  UNIQUEIDENTIFIER
DECLARE @sysadmin UNIQUEIDENTIFIER
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT

SET @accounting = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Accounting')
SET @claims = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Claims')
SET @invoiceentry = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='InvoiceEntry')
SET @manager = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Manager')
SET @vendorrep = (SELECT R.RoleId FROM aspnet_Roles R JOIN aspnet_Applications A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='VendorRep')
SET @sysadmin = (SELECT R.RoleId FROM aspnet_Roles R JOIN aspnet_Applications A ON R.ApplicationId = A.ApplicationId WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')

DECLARE @VendorTopID INT 
DECLARE @VendorDashboardID INT 
DECLARE @VendorMaintenanceID INT
DECLARE @TabVendorSummary INT
DECLARE @ButtonAddVendor INT
DECLARE @GridActionVendorSummary INT
DECLARE @GridActionVendorEdit INT
DECLARE @GridActionVendorMerge INT

SET @VendorTopID = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'MENU_TOP_VENDOR')
SET @VendorDashboardID = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_VENDOR_DASHBOARD')
SET @VendorMaintenanceID = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'MENU_LEFT_VENDOR_VENDOR')


-- Insert New Securables 
IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'TAB_VENDOR_SUMMARY')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('TAB_VENDOR_SUMMARY',@VendorMaintenanceID,NULL) 
	END
SET @TabVendorSummary = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'TAB_VENDOR_SUMMARY')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_ADD_VENDOR')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('BUTTON_ADD_VENDOR',NULL,NULL) 
	END
SET @ButtonAddVendor = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_ADD_VENDOR')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'GRID_ACTION_VENDOR_SUMMARY')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('GRID_ACTION_VENDOR_SUMMARY',NULL,NULL) 
	END
SET @GridActionVendorSummary = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'GRID_ACTION_VENDOR_SUMMARY')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'GRID_ACTION_VENDOR_EDIT')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('GRID_ACTION_VENDOR_EDIT',NULL,NULL) 
	END
SET @GridActionVendorEdit = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'GRID_ACTION_VENDOR_EDIT')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'GRID_ACTION_VENDOR_MERGE')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('GRID_ACTION_VENDOR_MERGE',NULL,NULL) 
	END
SET @GridActionVendorMerge = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'GRID_ACTION_VENDOR_MERGE')


-- Setup Manager AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Manager')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @VendorTopID AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@VendorTopID,@RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @VendorDashboardID AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@VendorDashboardID,@RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @VendorMaintenanceID AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@VendorMaintenanceID,@RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @TabVendorSummary AND RoleID = @RoleID)
	BEGIN  
     INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@TabVendorSummary, @RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorSummary AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorSummary,@RoleID,@AccessTypeID)
	END	

-- Setup ACCOUNTING AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Accounting')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonAddVendor AND RoleID = @RoleID)
	BEGIN  
     INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonAddVendor, @RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorEdit AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorEdit,@RoleID,@AccessTypeID)
	END	
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorMerge AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorMerge,@RoleID,@AccessTypeID)
	END	
	

-- Setup CLAIMS AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Claims')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonAddVendor AND RoleID = @RoleID)
	BEGIN  
     INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonAddVendor, @RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorEdit AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorEdit,@RoleID,@AccessTypeID)
	END	
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorMerge AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorMerge,@RoleID,@AccessTypeID)
	END	
	
-- Setup INVOICEENTRY AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='InvoiceEntry')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonAddVendor AND RoleID = @RoleID)
	BEGIN  
     INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonAddVendor, @RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorEdit AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorEdit,@RoleID,@AccessTypeID)
	END	
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorMerge AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorMerge,@RoleID,@AccessTypeID)
	END	
	
-- Setup VENDORREP AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='VendorRep')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonAddVendor AND RoleID = @RoleID)
	BEGIN  
     INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonAddVendor, @RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorEdit AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorEdit,@RoleID,@AccessTypeID)
	END	
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorMerge AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorMerge,@RoleID,@AccessTypeID)
	END
	
-- Setup SYSADMIN AccessControlList
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='SysAdmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'TAB_VENDOR_SUMMARY')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('TAB_VENDOR_SUMMARY',@VendorMaintenanceID,NULL) 
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @ButtonAddVendor AND RoleID = @RoleID)
	BEGIN  
     INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@ButtonAddVendor, @RoleID,@AccessTypeID)
	END
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorSummary AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorSummary,@RoleID,@AccessTypeID)
	END	
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorEdit AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorEdit,@RoleID,@AccessTypeID)
	END	
IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @GridActionVendorMerge AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@GridActionVendorMerge,@RoleID,@AccessTypeID)
	END		




