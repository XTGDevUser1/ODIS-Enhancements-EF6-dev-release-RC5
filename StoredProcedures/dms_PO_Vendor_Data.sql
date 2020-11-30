IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_PO_Vendor_Data]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_PO_Vendor_Data] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 --EXEC [dbo].[dms_PO_Vendor_Data] 719
 CREATE PROCEDURE [dbo].[dms_PO_Vendor_Data]( 
  @vendorLocationID  INT = NULL
 ) 
 AS 
 BEGIN 
  
 	SET NOCOUNT ON
 	SELECT 
	at.ID as BusinessAddressTypeID  
 ,ae.Line1 as BusinessAddressLine1  
 , ae.Line2 as BusinessAddressLine2  
 , ae.Line3 as BusinessAddressLine3  
 , ae.City as BusinessAddressCity  
 , ae.StateProvince as BusinessAddressStateProviince  
 , ae.CountryCode as BusinessAddressCountryCode  
 ,ae.PostalCode AS BusinessAddressPostalCode  
 ,ISNULL(vl.DispatchEmail,v.Email) Email
FROM VendorLocation vl  
LEFT JOIN Vendor v on v.ID = vl.VendorID  
LEFT JOIN AddressEntity ae on ae.EntityID = (Select ID From Entity Where Name = 'Vendor') and ae.RecordID = v.ID JOIN AddressType at on at.ID = ae.AddressTypeID and at.Name = 'Business'  
WHERE  
 vl.ID = @vendorLocationID  
	 END 


