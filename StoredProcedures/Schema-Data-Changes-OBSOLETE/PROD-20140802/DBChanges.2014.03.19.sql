-- Changes to CommunicationQueue and CommunicationLog tables.
ALTER TABLE CommunicationQueue
ADD EventLogID BIGINT NULL
GO

ALTER TABLE CommunicationQueue
ADD NotificationRecipient NVARCHAR(MAX) NULL
GO

ALTER TABLE CommunicationLog
ADD EventLogID BIGINT NULL
GO

ALTER TABLE CommunicationLog
ADD NotificationRecipient NVARCHAR(MAX) NULL
GO



UPDATE CommunicationQueue 
SET		NotificationRecipient = CASE WHEN ContactMethodID IN (SELECT ID FROM ContactMethod WHERE Name IN ('Phone', 'Text','Fax','IVR'))
										THEN  PhoneNumber
										ELSE Email
										END


UPDATE CommunicationLog 
SET		NotificationRecipient = CASE WHEN ContactMethodID IN (SELECT ID FROM ContactMethod WHERE Name IN ('Phone', 'Text','Fax','IVR'))
										THEN  PhoneNumber
										ELSE Email
										END


ALTER TABLE CommunicationQueue
DROP COLUMN Email
GO

ALTER TABLE CommunicationQueue
DROP COLUMN PhoneNumber
GO

ALTER TABLE CommunicationLog
DROP COLUMN Email
GO

ALTER TABLE CommunicationLog
DROP COLUMN PhoneNumber
GO


-- Define an app config item for notification history
IF NOT EXISTS ( SELECT * FROM ApplicationConfiguration WHERE Name = 'NotificationHistoryDisplayHours')
BEGIN

	INSERT INTO ApplicationConfiguration ( ApplicationConfigurationTypeID,
											ApplicationConfigurationCategoryID,
											Name,
											Value,
											CreateDate,
											CreateBy
										)
	SELECT  ( SELECT ID FROM ApplicationConfigurationType WHERE Name = 'CommunicationQueue'),
			NULL,
			'NotificationHistoryDisplayHours',
			'48',
			GETDATE(),
			'system'
END
GO

-- Securable for Add notification
-- Setup Add Notification
DECLARE @AddNotification INT
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_ADD_NOTIFICATION')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('BUTTON_ADD_NOTIFICATION',NULL,NULL) 
	END

SET @AddNotification = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_ADD_NOTIFICATION')

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @AddNotification AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@AddNotification,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Manager')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @AddNotification AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@AddNotification,@RoleID,@AccessTypeID)
	END

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Agent')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @AddNotification AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@AddNotification,@RoleID,@AccessTypeID)
	END


-- Program configs for Register member field validation

--
-- Setup ProgramConfiguration for Register Member pop-up fields

--select * from configurationtype
--select * from configurationcategory
--select * From programconfiguration order by name

IF NOT EXISTS (SELECT * FROM ConfigurationType WHERE Name = 'RegisterMember')
	BEGIN
		INSERT [dbo].[ConfigurationType]
			([Name]
			,[Description]
			,[Sequence]
			,[IsActive]
			)
		VALUES 
			('RegisterMember'
			, 'Register Member'
			, 8
			, 1)
	END
	
	
-- insert ProgramConfiguration for controlling register member fields that are required
-- and for settting ExpirationDate based on EffectiveDate

DECLARE @ProgramID INT
DECLARE @ConfigurationTypeID INT
DECLARE @CategoryValidation INT
DECLARE @CategoryRule INT

SET @ConfigurationTypeID = (SELECT ID FROM ConfigurationType WHERE Name = 'RegisterMember')
SET @CategoryValidation = (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation')
SET @CategoryRule = (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'NMC')

IF ( @ProgramID IS NOT NULL)
BEGIN

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireProgram')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireProgram', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequirePrefix')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequirePrefix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireFirstName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireFirstName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireMiddleName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireMiddleName', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireLastName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireLastName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireSuffix')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireSuffix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequirePhone')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequirePhone', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress1')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress1', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress2')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress2', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress3')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress3', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireCity')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireCity', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireCountry')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireCountry', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireState')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireState', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireZip')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireZip', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireEmail')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireEmail', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireEffectiveDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireEffectiveDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireExpirationDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireExpirationDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DaysAddedToEffectiveDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'DaysAddedToEffectiveDate', '14', 1, 1, getdate(), 'System', NULL, NULL)
	END

END

-- PDG
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'PDG - Professional Dispatch Group')

IF ( @ProgramID IS NOT NULL)
BEGIN

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireProgram')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireProgram', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequirePrefix')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequirePrefix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireFirstName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireFirstName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireMiddleName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireMiddleName', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireLastName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireLastName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireSuffix')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireSuffix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequirePhone')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequirePhone', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress1')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress1', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress2')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress2', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress3')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress3', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireCity')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireCity', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireCountry')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireCountry', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireState')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireState', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireZip')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireZip', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireEmail')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireEmail', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireEffectiveDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireEffectiveDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireExpirationDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireExpirationDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DaysAddedToEffectiveDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'DaysAddedToEffectiveDate', '14', 1, 1, getdate(), 'System', NULL, NULL)
	END

END

-- PCG 
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'PCG - Travel Guard')

IF ( @ProgramID IS NOT NULL)
BEGIN

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireProgram')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireProgram', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequirePrefix')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequirePrefix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireFirstName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireFirstName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireMiddleName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireMiddleName', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireLastName')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireLastName', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireSuffix')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireSuffix', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequirePhone')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequirePhone', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress1')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress1', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress2')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress2', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireAddress3')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireAddress3', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireCity')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireCity', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireCountry')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireCountry', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireState')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireState', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireZip')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireZip', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireEmail')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireEmail', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireEffectiveDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireEffectiveDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireExpirationDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'RequireExpirationDate', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DaysAddedToEffectiveDate')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'DaysAddedToEffectiveDate', '14', 1, 1, getdate(), 'System', NULL, NULL)
	END

END

