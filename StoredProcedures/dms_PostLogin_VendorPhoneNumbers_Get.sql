IF  EXISTS 
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].dms_PostLogin_VendorPhoneNumbers_Get') 
AND type IN (N'P', N'PC'))
DROP PROCEDURE [dbo].dms_PostLogin_VendorPhoneNumbers_Get
GO
--EXEC dms_PostLogin_VendorPhoneNumbers_Get @vendorId=190
CREATE PROCEDURE dms_PostLogin_VendorPhoneNumbers_Get
	@vendorId INT 
AS
BEGIN

DECLARE @officePhoneType int
DECLARE @dispatchPhoneType int
DECLARE @faxPhoneType int
DECLARE @vendorLocationEntityId int

SET @officePhoneType = (SELECT ID FROM PhoneType where Name = 'Office')
SET @dispatchPhoneType = (SELECT ID FROM PhoneType where Name = 'Dispatch')
SET @faxPhoneType = (SELECT ID FROM PhoneType where Name = 'Fax')
SET @vendorLocationEntityId = (SELECT ID FROM Entity where Name = 'VendorLocation')

SELECT
VL.ID 'VendorLocationId',
DP.ID 'DispatchId',
DP.PhoneNumber 'DispatchPhoneNumber',
FP.ID 'FaxId',
FP.PhoneNumber 'Fax',
ISNULL(REPLACE(RTRIM(
		  'Location : ' +
		COALESCE(AE.Line1, '') + 
		COALESCE(' ' + AE.Line2, '') + 
		COALESCE(' ' + AE.Line3, '') + 
		COALESCE(', ' + AE.City, '') +
		COALESCE(RTRIM(', ' + AE.StateProvince), '') + 
		COALESCE(' ' + AE.PostalCode, '') +	
		COALESCE(' ' + AE.CountryCode, '') 
		), '  ', ' ')
		,'') AS LocationAddress	   
FROM VendorLocation VL
LEFT JOIN PhoneEntity DP ON DP.RecordID = VL.ID AND DP.EntityID = @vendorLocationEntityId AND DP.PhoneTypeID = @dispatchPhoneType
LEFT JOIN PhoneEntity FP ON FP.RecordID = VL.ID AND FP.EntityID = @vendorLocationEntityId AND FP.PhoneTypeID = @faxPhoneType
JOIN AddressEntity AE ON AE.RecordID = VL.ID AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
WHERE VL.VendorID = @vendorId
AND VL.IsActive = 1

END