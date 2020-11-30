IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'UpdateMemberExpiration')
	BEGIN
		INSERT INTO Event (EventTypeID, 
							EventCategoryID,
							Name,
							Description,
							IsShownOnScreen,
							IsActive,
							CreateBy,
							CreateDate
							)			
		SELECT (SELECT ID FROM EventType WHERE Name = 'User')
			, (SELECT ID FROM EventCategory WHERE Name = 'Member')
			, 'UpdateMemberExpiration'
			, 'Update Member Expiration'
			, 1
			, 1
			, 'System'
			, getdate()
	END
GO

-- Securable for BUTTON_MEMBER_EDIT_EXPIRATION Button
-- Read Write Permission to manager,sysadmin,agent

DECLARE @managerRoleID UNIQUEIDENTIFIER
SET		@managerRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'manager' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

DECLARE @sysAdminRoleID UNIQUEIDENTIFIER
SET		@sysAdminRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'sysadmin' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

DECLARE @agentRoleID UNIQUEIDENTIFIER
SET		@agentRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'agent' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

DECLARE @securableID INT
-- Create Securable for ADD COMMENT
IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_MEMBER_EDIT_EXPIRATION')
BEGIN
	
	INSERT INTO Securable(FriendlyName) VALUES('BUTTON_MEMBER_EDIT_EXPIRATION')	
	SET @securableID = (SELECT ID FROM Securable WHERE FriendlyName = 'BUTTON_MEMBER_EDIT_EXPIRATION')
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(@securableID,@managerRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(@securableID,@sysAdminRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(@securableID,@agentRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
END



IF NOT EXISTS (SELECT * FROM CommentType WHERE Name = 'Member')
	BEGIN
		INSERT [dbo].[CommentType]
			([Name]
			,[Description]
			,[Sequence]
			,[IsActive]
			)
		VALUES
			('Member'
			,'Member'
			,1
			,1
			)
	END
GO

-- Setup New Configuration Items
DECLARE @ProgramID INT
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford')

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'WarrantyRequired')
	BEGIN
		INSERT INTO [dbo].[ProgramConfiguration]
			([ProgramID]
			,[ConfigurationTypeID]
			,[ConfigurationCategoryID]
			,[ControlTypeID]
			,[DataTypeID]
			,[Name]
			,[Value]
			,[IsActive]
			,[Sequence]
			,[CreateDate]
			,[CreateBy]
			,[ModifyDate]
			,[ModifyBy]			
			)
		VALUES 
			(
			@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation')
			, NULL
			, NULL
			, 'WarrantyRequired'
			, 'Yes'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
GO
