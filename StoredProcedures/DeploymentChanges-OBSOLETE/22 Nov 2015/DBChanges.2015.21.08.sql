IF NOT EXISTS (SELECT * FROM ApplicationConfiguration where Name='RolesThatAllowPOPaymentEdit')
BEGIN
	INSERT INTO ApplicationConfiguration VALUES(
		(SELECT ID FROM ApplicationConfigurationType where Name='PurchaseOrderInformation'),
		NULL,
		NULL,
		NULL,
		'RolesThatAllowPOPaymentEdit',
		'sysadmin',
		GETDATE(),
		'system',
		NULL,
		NULL
	)
END