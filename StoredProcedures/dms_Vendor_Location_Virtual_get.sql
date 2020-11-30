
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Location_Virtual_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
	DROP PROCEDURE [dbo].[dms_Vendor_Location_Virtual_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO  
 --EXEC dms_Vendor_Location_Virtual_get 640
 CREATE PROCEDURE [dbo].[dms_Vendor_Location_Virtual_get]( 
	@vendorLocationID int = NULL
 ) 
 AS 
 BEGIN
	Select 
	VLV.LocationAddress,
	VLV.LocationCity,
	VLV.LocationStateProvince,
	VLV.LocationCountryCode,
	VLV.LocationPostalCode,
	VLV.Latitude,
	VLV.Longitude,
	CONVERT(NVARCHAR(MAX),VLV.GeographyLocation) AS GeographyLocation
FROM VendorLocationVirtual VLV 
LEFT JOIN VendorLocation VL ON VL.ID= VLV.VendorLocationID
where VendorLocationID = @vendorLocationID

 END
 GO
