IF NOT EXISTS ( SELECT * FROM BatchType WHERE Name = 'ClientBillingUnbilled')
BEGIN
	INSERT INTO BatchType
	SELECT 'ClientBillingUnbilled','Client Billing Unbilled',4,1,NULL
END
