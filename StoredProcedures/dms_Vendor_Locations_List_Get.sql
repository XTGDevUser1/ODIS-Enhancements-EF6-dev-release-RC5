IF  EXISTS 
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].dms_Vendor_Locations_List_Get') 
AND type IN (N'P', N'PC'))
DROP PROCEDURE [dbo].dms_Vendor_Locations_List_Get
GO
--EXEC dms_Vendor_Locations_List_Get @VendorID=55
CREATE PROCEDURE dms_Vendor_Locations_List_Get
	-- Add the parameters for the stored procedure here
	@VendorID INT 
AS
BEGIN

SET NOCOUNT ON;
DECLARE @FinalResults TABLE ( 
	
	VendorLocationID INT NULL,
	LocationAddress nvarchar(MAX)  NULL	
)
INSERT INTO @FinalResults VALUES(0,'Vendor Information')

INSERT INTO @FinalResults 
SELECT DISTINCT VL.ID AS VendorLocation
		, ISNULL(REPLACE(RTRIM(
		  'Location - ' +
		  --COALESCE(AE.Line1, ' ') + 
		  --COALESCE(AE.Line2, ' ') +     
		  --COALESCE(AE.Line3, ' ') +  ' '+   
		  --COALESCE(AE.City, '') + ' '+
		  COALESCE(AE.Line1, '') + 
		COALESCE(' ' + AE.Line2, '') + 
		COALESCE(' ' + AE.Line3, '') + 
		COALESCE(', ' + AE.City, '') +
		COALESCE(RTRIM(', ' + AE.StateProvince), '') + 
		COALESCE(' ' + AE.PostalCode, '') +	
		COALESCE(' ' + AE.CountryCode, '') + 
		COALESCE(' ' + VLS.Description,'')
		), '  ', ' ')
		,'') AS LocationAddress
		
		
FROM		VendorLocation VL
LEFT JOIN		VendorLocationStatus VLS ON VLS.ID = VL.VendorLocationStatusID
JOIN		AddressEntity AE 
		ON AE.RecordID = VL.ID 
		AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
WHERE		VL.VendorID = @VendorID AND VL.IsActive=1
ORDER BY	VL.ID
 
SELECT * FROM @FinalResults
END
GO
