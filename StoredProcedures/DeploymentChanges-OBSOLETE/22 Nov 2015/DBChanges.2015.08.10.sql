DECLARE @ClientID INT = (SELECT ID FROM Client WHERE Name = 'FORD')

DECLARE @ProgramID INT = (SELECT ID FROM Program WHERE Name = 'Ford RV/Commercial')

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowInvoiceUploadOnSubmitInvoice')
BEGIN
	INSERT ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy)
	VALUES (@ProgramID, 
			(SELECT ID FROM ConfigurationType WHERE Name = 'Vendor') , 
			(SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule'), 
			NULL, 
			NULL, 
			'ShowInvoiceUploadOnSubmitInvoice',
			'Yes',
			1, 
			1, 
			NULL, 
			NULL, 
			NULL, 
			NULL)
END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'RequireInvoiceUploadOnSubmitInvoice')
BEGIN
	INSERT ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy)VALUES (@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vendor'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule'), NULL, NULL, 'RequireInvoiceUploadOnSubmitInvoice','Yes',1, 1, NULL, NULL, NULL, NULL)
END

ALTER TABLE PurchaseOrder
ADD InternalDispatchFee  MONEY NULL


ALTER TABLE PurchaseOrder
ADD ClientDispatchFee MONEY NULL


ALTER TABLE PurchaseOrder
ADD CreditCardProcessingFee MONEY NULL

IF NOT EXISTS(Select * from Client where Name = 'RentalCover.com')
BEGIN
INSERT INTO Client VALUES(
	'RentalCover.com',
	'RentalCover.com',
	1,
	GETDATE(),
	'system',
	NULL,
	NULL,
	'RNTLCVR',
	'RCC1',
	NULL
)
END


IF NOT EXISTS(SELECT * FROM Program where Name='RentalCover.com')
BEGIN
	INSERT INTO Program VALUES(
		NULL,
		(SELECT ID FROM Client where Name = 'RentalCover.com'),
		'RENTALCOVER',
		'RentalCover.com',
		'RentalCover.com',
		0,
		NULL,
		NULL,
		1,
		0,
		NULL,
		NULL,
		GETDATE(),
		'system',
		NULL,
		NULL,		
		1,
		0,
		1
	)
END

IF NOT EXISTS(SELECT * FROM DataType WHERE Name = 'Query')
BEGIN
	INSERT INTO DataType VALUES(
		'Query',
		'Query',
		6,
		1
)
END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = (SELECT ID FROM Program WHERE Name = 'RentalCover.com') AND Name = 'MemberPayDispatchFee' AND DataTypeID = (SELECT ID FROM DataType WHERE Name = 'Query'))
BEGIN
	INSERT ProgramConfiguration (ProgramID, ConfigurationTypeID, ConfigurationCategoryID, ControlTypeID, DataTypeID, Name, Value, IsActive, Sequence, CreateDate, CreateBy, ModifyDate, ModifyBy)
	VALUES (
			(SELECT ID FROM Program WHERE Name = 'RentalCover.com')
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')
			, NULL
			, (SELECT ID FROM DataType WHERE Name = 'Query')
			, 'MemberPayDispatchFee'
			, 'dms_PO_MemberPayDispatchFee'
			, 1
			, 1
			, getdate()
			, 'system'
			, NULL
			, NULL
			)
END

