IF NOT EXISTS(SELECT * FROM aspnet_Roles
				WHERE ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE ApplicationName = 'VendorPortal')
				AND RoleName='VendorBilling'
				)
BEGIN
INSERT INTO aspnet_Roles(
			ApplicationId,
			RoleName,
			LoweredRoleName)
		VALUES(
			(SELECT ApplicationId FROM aspnet_Applications WHERE ApplicationName = 'VendorPortal'),
			'VendorBilling',
			'vendorbilling'
		)			

END

DECLARE @securable_MENU_TOP_ISP AS INT = (SELECT ID FROM Securable where FriendlyName ='MENU_TOP_ISP')
DECLARE @securable_MENU_LEFT_ISP_SUBMITINVOICE AS INT = (SELECT ID FROM Securable where FriendlyName ='MENU_LEFT_ISP_SUBMITINVOICE')
DECLARE @securable_MENU_LEFT_ISP_INVOICEHISTORY AS INT = (SELECT ID FROM Securable where FriendlyName ='MENU_LEFT_ISP_INVOICEHISTORY')
DECLARE @securable_MENU_LEFT_ISP_MYPROFILE AS INT = (SELECT ID FROM Securable where FriendlyName ='MENU_LEFT_ISP_MYPROFILE')
DECLARE @readWriteAccessTypeID AS INT = (SELECT ID FROM AccessType where  Name = 'ReadWrite')
DECLARE @vendorBillingRoleID AS UNIQUEIDENTIFIER = (SELECT RoleId FROM aspnet_Roles
				WHERE ApplicationId = (SELECT ApplicationId FROM aspnet_Applications WHERE ApplicationName = 'VendorPortal')
				AND RoleName='VendorBilling'
				)
IF NOT EXISTS(SELECT * FROM AccessControlList where SecurableID = @securable_MENU_TOP_ISP AND RoleID = @vendorBillingRoleID)
BEGIN
	INSERT INTO AccessControlList(
					SecurableID,
					RoleID,
					AccessTypeID
	)
	VALUES(
		@securable_MENU_TOP_ISP,
		@vendorBillingRoleID,
		@readWriteAccessTypeID
	)
END

IF NOT EXISTS(SELECT * FROM AccessControlList where SecurableID = @securable_MENU_LEFT_ISP_SUBMITINVOICE AND RoleID = @vendorBillingRoleID)
BEGIN
	INSERT INTO AccessControlList(
					SecurableID,
					RoleID,
					AccessTypeID
	)
	VALUES(
		@securable_MENU_LEFT_ISP_SUBMITINVOICE,
		@vendorBillingRoleID,
		@readWriteAccessTypeID
	)
END

IF NOT EXISTS(SELECT * FROM AccessControlList where SecurableID = @securable_MENU_LEFT_ISP_INVOICEHISTORY AND RoleID = @vendorBillingRoleID)
BEGIN
	INSERT INTO AccessControlList(
					SecurableID,
					RoleID,
					AccessTypeID
	)
	VALUES(
		@securable_MENU_LEFT_ISP_INVOICEHISTORY,
		@vendorBillingRoleID,
		@readWriteAccessTypeID
	)
END

IF NOT EXISTS(SELECT * FROM AccessControlList where SecurableID = @securable_MENU_LEFT_ISP_MYPROFILE AND RoleID = @vendorBillingRoleID)
BEGIN
	INSERT INTO AccessControlList(
					SecurableID,
					RoleID,
					AccessTypeID
	)
	VALUES(
		@securable_MENU_LEFT_ISP_MYPROFILE,
		@vendorBillingRoleID,
		@readWriteAccessTypeID
	)
END