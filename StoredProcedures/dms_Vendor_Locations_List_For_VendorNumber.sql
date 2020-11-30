IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Locations_List_For_VendorNumber]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Locations_List_For_VendorNumber] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
  /*
	EXEC [dms_Vendor_Locations_List_For_VendorNumber] 'TX167426'

  */
 CREATE PROCEDURE [dbo].[dms_Vendor_Locations_List_For_VendorNumber]( 
 @vendorNumber nvarchar(100)  = NULL
 )
 AS
 BEGIN
	DECLARE @businessAddressTypeID INT =(SELECT ID FROM AddressType WHERE Name='Business')
	DECLARE @vendorLocationEntityID INT = (SELECT ID FROM Entity WHERE Name ='VendorLocation')
	SELECT vl.ID as VendorLocationID, ae.Line1, ae.Line2, ae.City, ae.StateProvince, ae.PostalCode, ae.CountryCode
	FROM VendorLocation vl
	JOIN Vendor v on v.ID = vl.VendorID
	JOIN AddressEntity ae on ae.EntityID = @vendorLocationEntityID and ae.RecordID = vl.ID and ae.AddressTypeID = @businessAddressTypeID
	WHERE v.VendorNumber = @vendorNumber

END


