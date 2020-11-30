
IF  EXISTS 
(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].dms_vendor_Location_Address_Get') 
AND type IN (N'P', N'PC'))
DROP PROCEDURE [dbo].dms_vendor_Location_Address_Get
GO
--EXEC dms_vendor_Location_Address_Get @VendorLocationID=158
CREATE PROCEDURE dms_vendor_Location_Address_Get
	@VendorLocationID INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @FaxPhoneTypeID INT,
        @DispatchPhoneTypeID INT,
        @OfficePhoneTypeID INT,
        @VendorLocationEntityTypeID INT

SET @FaxPhoneTypeID = (SELECT TOP 1 ID FROM PhoneType WHERE Name='Fax')   
SET @DispatchPhoneTypeID = (SELECT TOP 1 ID FROM PhoneType WHERE Name='Dispatch')
SET @OfficePhoneTypeID = (SELECT TOP 1 ID FROM PhoneType WHERE Name='Office')   
SET @VendorLocationEntityTypeID = (SELECT TOP 1 ID FROM Entity WHERE Name='VendorLocation')
  	
SELECT VL.ID AS VendorLocation  
  , ISNULL(REPLACE(RTRIM(  
   COALESCE(AE.Line1, '')  
   ), '  ', ' ')  
   ,'') AS LocationAddress1  
   , ISNULL(REPLACE(RTRIM(  
   COALESCE(AE.Line2, '') 
   ), '  ', ' ')  
   ,'') AS LocationAddress2 
   , ISNULL(REPLACE(RTRIM(      
   COALESCE(AE.Line3, '')  
   ), '  ', ' ')  
   ,'') AS LocationAddress3
   , ISNULL(REPLACE(RTRIM(       
   COALESCE(AE.City, '')   
   ), '  ', ' ')  
   ,'') AS LocationCity
  , AE.StateProvinceID  AS LocationState
  , AE.CountryID AS LocationCountry
  , AE.PostalCode AS LocationPostalCode
  , PEF.PhoneNumber AS LocationFaxNumber
  , PED.PhoneNumber AS LocationDispatchNumber
  , PEO.PhoneNumber AS LocationOfficeNumber
  --, VL.DefaultLocationName AS LocationName
FROM  VendorLocation VL  
JOIN  AddressEntity AE   
  ON AE.RecordID = VL.ID   
  AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')  
 
	LEFT JOIN PhoneEntity PEF ON PEF.RecordID = VL.ID AND PEF.PhoneTypeID = @FaxPhoneTypeID AND PEF.EntityID = @VendorLocationEntityTypeID 
	LEFT JOIN PhoneEntity PED ON PED.RecordID = VL.ID AND PED.PhoneTypeID = @DispatchPhoneTypeID AND PED.EntityID = @VendorLocationEntityTypeID 
	LEFT JOIN PhoneEntity PEO ON PEO.RecordID = VL.ID AND PEO.PhoneTypeID = @OfficePhoneTypeID AND PEO.EntityID = @VendorLocationEntityTypeID 
LEFT OUTER JOIN (  
  SELECT VendorLocationID, COUNT(*) ProductCount  
  FROM VendorLocationProduct   
  GROUP BY VendorLocationID  
  ) VLP ON VLP.VendorLocationID = VL.ID   
LEFT JOIN  VendorLocationStatus VLS  
  ON VLS.ID = VL.VendorLocationStatusID 
WHERE  VL.ID=@VendorLocationID 
END
GO
