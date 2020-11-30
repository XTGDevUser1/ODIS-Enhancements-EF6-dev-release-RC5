IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fnGetAddress]') 
AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[fnGetAddress]
GO
CREATE FUNCTION dbo.fnGetAddress(@EntityName NVARCHAR(50),@AddressTypeName NVARCHAR(50),@RecordID INT)
RETURNS @AddressDetails TABLE
(
		AddressID INT,
		AddressEntityID INT,
		AddressRecordID INT,
		AddressTypeID INT NULL,
		AddressLine1	NVARCHAR(100) NULL,
		AddressLine2	NVARCHAR(100) NULL,
		AddressLine3	NVARCHAR(100) NULL,
		AddressCity	NVARCHAR(100) NULL,
		AddressPostalCode	NVARCHAR(50) NULL,
		AddressCountryID	INT NULL,
		AddressStateProvinceID INT NULL
)
AS
BEGIN
	
	with wAddress AS(
						SELECT TOP 1 * FROM AddressEntity 
						WHERE EntityID = (SELECT EntityID FROM Entity WHERE Name = @EntityName)
					    AND RecordID = @RecordID
						AND AddressTypeID = (SELECT AddressTypeID FROM AddressType WHERE Name = @AddressTypeName)
					)
	
	INSERT INTO @AddressDetails 
	SELECT ID,
		   EntityID,
		   RecordID,
		   AddressTypeID,
		   Line1,
		   Line2,
		   Line3,
		   City,
		   PostalCode,
		   CountryID,
		   StateProvinceID
	FROM wAddress
	RETURN 
END






