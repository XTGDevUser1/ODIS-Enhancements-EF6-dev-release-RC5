-- Securable for Vendor Activity Histroy Add Comment and Add Contract Button
-- Read Write Permission Only to VendorRep Roles

DECLARE @vendorRepRoleID UNIQUEIDENTIFIER
SET		@vendorRepRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'vendorrep' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))


DECLARE @sysAdminRoleID UNIQUEIDENTIFIER
SET		@sysAdminRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'sysadmin' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

-- Create Securable for ADD COMMENT
IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_COMMENT')
BEGIN
	
	INSERT INTO Securable(FriendlyName) VALUES('BUTTON_VENDOR_ACTIVITY_ADD_COMMENT')	
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(SCOPE_IDENTITY(),@vendorRepRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
END

-- Create Securable for ADD CONTACT
IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_VENDOR_ACTIVITY_ADD_CONTACT')
BEGIN
	
	INSERT INTO Securable(FriendlyName) VALUES('BUTTON_VENDOR_ACTIVITY_ADD_CONTACT')	
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(SCOPE_IDENTITY(),@vendorRepRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
END

-- Create Securable for Vendor Location Geography Management Menu
IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'MENU_LEFT_VENDOR_LOCATION_GEOGRAPHY')
BEGIN
	
	INSERT INTO Securable(FriendlyName) VALUES('MENU_LEFT_VENDOR_LOCATION_GEOGRAPHY')	
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(SCOPE_IDENTITY(),@sysAdminRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
END

