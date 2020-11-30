
ALTER TABLE Vendor
ADD DriverSoftwareProductOther nvarchar(255) NULL


ALTER TABLE Vendor
ADD DispatchGPSNetworkOther nvarchar(255) NULL

Update DispatchSoftwareProduct SET IsActive = 1 where SoftwareName = 'Other'

IF NOT EXISTS(SELECT * FROM [DispatchGPSNetwork] where Name='Other')
BEGIN
	INSERT INTO [DispatchGPSNetwork] VALUES
	(
		'Other',
		'Other',
		4,
		1
	)
END