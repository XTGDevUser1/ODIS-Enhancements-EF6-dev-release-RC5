IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Details_For_Report_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Details_For_Report_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_Vendor_Details_For_Report_Get] 190
 CREATE PROCEDURE [dbo].[dms_Vendor_Details_For_Report_Get](
 @vendorID INT
 )
 AS
 BEGIN
 
	DECLARE @vendorServicesPhoneNumber NVARCHAR(100) = NULL,
			@vendorServicesFaxNumber NVARCHAR(100) = NULL

	-- KB: TFS : 2433 - Fix the VendorServicesPhone and Fax numbers
	SET	@vendorServicesPhoneNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesPhoneNumber')
	SET	@vendorServicesFaxNumber	= (SELECT Value FROM ApplicationConfiguration WHERE Name = 'VendorServicesFaxNumber')

	-- KB: Handle the case when there are multiple Office addresses and Business phone numbers.
	;WITH wBusinessAddresses
	AS
	(	
		SELECT	ROW_NUMBER() OVER (ORDER BY AE.ID DESC) AS RowNum,
				AE.*
		FROM	AddressEntity AE WITH (NOLOCK)
		WHERE	AE.RecordID = @vendorID AND AE.EntityID =
					  (SELECT     ID
						FROM          Entity
						WHERE      (Name = 'Vendor')) AND AE.AddressTypeID =
					  (SELECT     ID
						FROM          AddressType
						WHERE      (Name = 'Business'))
	),
	wOfficePhoneNumbers
	AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY PE.ID DESC) AS RowNum,
				PE.*
		FROM	PhoneEntity PE WITH (NOLOCK)
		WHERE	PE.RecordID = @vendorID AND PE.EntityID =
					  (SELECT     ID
						FROM          Entity
						WHERE      (Name = 'Vendor')) AND PE.PhoneTypeID =
					  (SELECT     ID
						FROM          PhoneType
						WHERE      (Name = 'Office'))
	)
		
	SELECT     
			V.VendorNumber, 
			V.Name, 
			V.ContactFirstName AS VendorFirstName, 
			V.ContactLastName AS VendorLastName, 
			V.Email as VendorEmail,
			VR.Name as VendorRegionName,
			VR.ContactFirstName AS RepFirstName, 
			VR.ContactLastName AS RepLastName, 
			VR.Email as RepEmail, 
			dbo.fnc_FormatPhoneNumber(PE.PhoneNumber, 0) AS VendorPhoneNumber,
			dbo.fnc_FormatPhoneNumber(VR.PhoneNumber, 0) AS RepPhoneNumber, 
			dbo.fnc_FormatPhoneNumber(@vendorServicesPhoneNumber, 0) AS VendorRegionOffice, 
			dbo.fnc_FormatPhoneNumber(@vendorServicesFaxNumber,0) as VendorRegionFax,
			AE.Line1, 
			AE.Line2, 
			AE.Line3, 
			AE.City, 
			AE.StateProvince, 
			AE.CountryCode, 
			AE.PostalCode
	FROM    Vendor AS V WITH (NOLOCK)
	LEFT OUTER JOIN	VendorRegion AS VR WITH (NOLOCK) ON V.VendorRegionID = VR.ID 
	LEFT OUTER JOIN wBusinessAddresses AE WITH (NOLOCK) ON AE.RecordID = V.ID AND AE.RowNum = 1
	LEFT OUTER JOIN wOfficePhoneNumbers PE WITH (NOLOCK) ON PE.RecordID = V.ID AND PE.RowNum = 1	
	WHERE     (V.ID = @vendorID)
 
 END
 GO