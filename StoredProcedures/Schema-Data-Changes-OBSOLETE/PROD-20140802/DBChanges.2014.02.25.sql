--
-- Setup Insurance phone type
--

DECLARE @EntityVL INT
DECLARE @EntityV INT
DECLARE @PhoneTypeInsurance INT

SET @EntityVL = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
SET @EntityV = (SELECT ID FROM Entity WHERE Name = 'Vendor')
SET @PhoneTypeInsurance = (SELECT ID FROM PHoneType WHERE Name = 'Insurance')

-- Create new phone type
IF NOT EXISTS (SELECT * FROM PhoneType WHERE Name = 'Insurance') 
	BEGIN
		INSERT INTO PhoneType (Name, Description, IsActive, Sequence)
			VALUES ('Insurance', 'Insurance', 1, 8)
	END

SET @PhoneTypeInsurance = (SELECT ID FROM PhoneType WHERE Name = 'Insurance')

-- Create link from new phonetype Insurance to Vendor
IF NOT EXISTS (SELECT * FROM PhoneTypeEntity WHERE EntityID = @EntityV AND PhoneTypeID = @PhoneTypeInsurance)
	BEGIN
		INSERT INTO PhoneTypeEntity (EntityID, PhoneTypeID, IsShownOnScreen, Sequence)
			VALUES (@EntityV, @PhoneTypeInsurance, 1, 6)
END

