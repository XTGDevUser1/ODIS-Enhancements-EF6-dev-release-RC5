-- Securable for Program Management Under Admin

DECLARE @sysAdminRoleID UNIQUEIDENTIFIER
SET		@sysAdminRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'sysadmin' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

-- Create Securable for Program Maintenance
IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'MENU_LEFT_ADMIN_PROGRAM_MANAGEMENT')
BEGIN
	
	INSERT INTO Securable(FriendlyName) VALUES('MENU_LEFT_ADMIN_PROGRAM_MANAGEMENT')	
	INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(SCOPE_IDENTITY(),@sysAdminRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite')) 
END

--2449 issue fix update all po's contract status
UPDATE PurchaseOrder
SET ContractStatus = 
CASE WHEN IsActive=1 THEN 'Contracted'
ELSE 'NotContracted' END

DECLARE @vendorRepRoleID UNIQUEIDENTIFIER
SET @vendorRepRoleID = (SELECT RoleID FROM aspnet_Roles WHERE LoweredRoleName = 'vendorrep' AND ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE LoweredApplicationName = 'dms'))

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'TEXT_PO_VENDOR_TAX_ID')
BEGIN

INSERT INTO Securable(FriendlyName) VALUES('TEXT_PO_VENDOR_TAX_ID')
INSERT INTO AccessControlList(SecurableID,RoleID,AccessTypeID) VALUES(SCOPE_IDENTITY(),@vendorRepRoleID,(SELECT ID FROM AccessType WHERE Name = 'ReadWrite'))
END