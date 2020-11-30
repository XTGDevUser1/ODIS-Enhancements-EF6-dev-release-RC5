-- SCRIPT to add records for logging when a user clicks Open For Edit and the assigned user is not online so we open SR for user
IF NOT EXISTS (SELECT ID FROM Event WHERE Name = 'OpenedLockedRequestBecauseNotOnline')
BEGIN
	INSERT INTO [dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (
           (SELECT ID FROM EventType WHERE Name = 'User')
           ,(SELECT ID FROM EventCategory WHERE Name= 'ServiceRequest')
           ,'OpenedLockedRequestBecauseNotOnline'
           ,'Opened locked request because person not online'
           ,1
           ,1
           ,'system'
           ,getdate())
END
GO


IF NOT EXISTS (SELECT ID FROM ApplicationConfiguration WHERE Name = 'OpenForEditCheckOnlineStatus')
BEGIN
	INSERT INTO [dbo].[ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           (
           (SELECT ID FROM ApplicationConfigurationType WHERE Name = 'System')
           , NULL
           , NULL
           , NULL
           , 'OpenForEditCheckOnlineStatus' 
           , 'Yes'
           , getdate()
           , 'system' 
           , NULL
           , NULL)
END
GO

IF NOT EXISTS(SELECT ID FROM ApplicationConfiguration WHERE Name = 'RolesInAddNotificationList')
BEGIN

      INSERT INTO [dbo].[ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES(
           (SELECT ID FROM ApplicationConfigurationType WHERE Name = 'System')
           , NULL
           , NULL
           , NULL
           , 'RolesInAddNotificationList' 
           , 'Agent,Manager'
           , getdate()
           , 'system' 
           , NULL
           , NULL)

END

GO

-- Setup Add Notification Auto Close Spinner control

DECLARE @SpinnerNotificationAutoClose INT
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'SPINNER_NOTIFICATION_AUTOCLOSE')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('SPINNER_NOTIFICATION_AUTOCLOSE',NULL,NULL) 
	END

SET @SpinnerNotificationAutoClose = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'SPINNER_NOTIFICATION_AUTOCLOSE')

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Manager')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Agent')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='VendorMgr')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='VendorRep')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='FrontEnd')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='ClientRelationsMgr')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END	
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='ClientRelations')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END	

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='RVTech')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END	

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='ClaimsMgr')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END	

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='QA')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END	

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Accounting')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END	
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Claims')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
	END	
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Dispatcher')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadOnly')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @SpinnerNotificationAutoClose AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@SpinnerNotificationAutoClose,@RoleID,@AccessTypeID)
END	
	
--NP 7/28:

	
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NextAction]') AND type in (N'U'))
BEGIN

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [name] = N'DefaultAssignedToUserID' AND [object_id] = OBJECT_ID(N'NextAction'))
BEGIN

ALTER TABLE [NextAction]  ADD [DefaultAssignedToUserID] INT NULL
END 

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_NextAction_User]') AND parent_object_id = OBJECT_ID(N'[dbo].[NextAction]'))
ALTER TABLE [dbo].[NextAction]  WITH CHECK ADD  CONSTRAINT [FK_NextAction_User] FOREIGN KEY([DefaultAssignedToUserID])
REFERENCES [dbo].[User] ([ID])

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_NextAction_User]') AND parent_object_id = OBJECT_ID(N'[dbo].[NextAction]'))
ALTER TABLE [dbo].[NextAction] CHECK CONSTRAINT [FK_NextAction_User]

END

--EXECUTE Line by Line
UPDATE ServiceRequest SET PrimaryCoverageLimit = CoverageLimit where PrimaryCoverageLimit IS NULL
UPDATE ServiceRequest SET CoverageLimit = null  WHERE PrimaryCoverageLimit IS NOT  NULL
UPDATE ServiceRequest SET PrimaryCoverageLimit = 0, IsServiceCoverageBestValue = 1 where PrimaryCoverageLimit IN (999,9999,9999.99)

IF EXISTS(SELECT * FROM sys.columns 
        WHERE [name] = N'CoverageLimit' AND [object_id] = OBJECT_ID(N'ServiceRequest'))
BEGIN
ALTER TABLE ServiceRequest DROP COLUMN CoverageLimit
END






--
-- Setup to make fields on Vehicle Tab program driven 
-- Warranty Terms: time and mileage

-- Add program configuration item 
DECLARE @ProgramID INT

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Commercial Truck')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END


SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Commercial Truck')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford RV - Rental')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford RV')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Transport')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END
GO
-- ENDS HERE



--TP 8/1
--Populate TemporaryCreditCard.LastChargedDate
UPDATE tc SET LastChargedDate = tcd.LastChargedDate
FROM TemporaryCreditCard tc
JOIN (
	SELECT TemporaryCreditCardID, MAX(ChargeDate) LastChargedDate
	FROM TemporaryCreditCardDetail
	WHERE TransactionType='Charge'
	GROUP BY TemporaryCreditCardID
	) tcd ON tcd.TemporaryCreditCardID = tc.ID
WHERE tc.LastChargedDate IS NULL
GO



--Sanghi TFS 402
UPDATE ApplicationConfiguration SET Value = 'SysAdmin' WHERE Name = 'RolesThatCanChangeDollarLimit'
DELETE AccessControlList WHERE SecurableID = (SELECT ID FROM Securable WHERE FriendlyName = 'TEXT_DOLLAR_LIMIT')
INSERT INTO AccessControlList Values((SELECT ID FROM Securable WHERE FriendlyName = 'TEXT_DOLLAR_LIMIT'),(SELECT RoleID FROM aspnet_Roles WHERE RoleName = 'SysAdmin' AND ApplicationId = (Select ApplicationId FROM aspnet_Applications WHERE ApplicationName = 'DMS')),(SELECT ID FROM AccessType WHERE Name = 'ReadWrite'))
