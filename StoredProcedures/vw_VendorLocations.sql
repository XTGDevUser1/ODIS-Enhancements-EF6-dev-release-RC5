CREATE VIEW [dbo].[vw_VendorLocations]
AS
SELECT VL.ID VendorLocationID,
	   VL.VendorID,
	   V.VendorNumber,
	   V.Name VendorName,
	   VL.Sequence,
	   VL.Latitude,
	   VL.Longitude,
	   VL.GeographyLocation,
	   VL.Email,
	   VL.BusinessHours,
	   VL.DealerNumber,
	   VL.IsOpen24Hours,
	   VL.IsActive,
	   VL.CreateDate,
	   VL.CreateBy,
	   VL.ModifyDate,
	   VL.ModifyBy,
	   VL.IsKeyDropAvailable,
	   VL.IsOvernightStayAllowed,
	   VL.IsDirectTow,
	   Vl.PartsAndAccessoryCode,
	   VL.VendorLocationStatusID,
	   VLS.Description VendorLocationStatusDescription,
	   VL.DispatchNote,
	   VL.IsElectronicDispatchAvailable,
	   VL.IsOvernightStorageAvailable,
	   VL.IsUsingZipCodes,
	   VL.IsAbleToCrossStateLines,
	   VL.IsAbleToCrossNationalBorders,
	   VL.DispatchEmail

	  ,AEBusiness.Line1 AS BusinessLine1
	  ,AEBusiness.Line2 AS BusinessLine2
	  ,AEBusiness.City AS BusinessCity
	  ,AEBusiness.StateProvinceID AS BusinessStateProvinceID
	  ,AEBusiness.StateProvince AS BusinessStateProvince
	  ,AEBusiness.PostalCode AS BusinessPostalCode
	  ,AEBusiness.CountryID AS BusinessCountryID
	  ,AEBusiness.CountryCode AS BusinessCountryCode

	  ,AEBilling.Line1 AS BillingLine1
	  ,AEBilling.Line2 AS BillingLine2
	  ,AEBilling.City AS BillingCity
	  ,AEBilling.StateProvinceID AS BillingStateProvinceID
	  ,AEBilling.StateProvince AS BillingStateProvince
	  ,AEBilling.PostalCode AS BillingPostalCode
	  ,AEBilling.CountryID AS BillingCountryID
	  ,AEBilling.CountryCode AS BillingCountryCode

	  ,AEOther.Line1 AS OtherLine1
	  ,AEOther.Line2 AS OtherLine2
	  ,AEOther.City AS OtherCity
	  ,AEOther.StateProvinceID AS OtherStateProvinceID
	  ,AEOther.StateProvince AS   OtherStateProvince
	  ,AEOther.PostalCode AS      OtherPostalCode
	  ,AEOther.CountryID AS       OtherCountryID
	  ,AEOther.CountryCode AS     OtherCountryCode

	  ,PECell.PhoneNumber AS CellPhone
	  ,PEFax.PhoneNumber AS FaxPhone
	  ,PEDispatch.PhoneNumber AS DispatchPhone
	  ,PEOffice.PhoneNumber AS OfficePhone
	  ,PEOther.PhoneNumber AS OtherPhone
	  ,PEAlternateDispatch.PhoneNumber AS AlternateDispatchPhone

FROM VendorLocation VL
LEFT JOIN  VendorLocationStatus VLS ON VL.VendorLocationStatusID = VLS.ID
LEFT JOIN Vendor V ON VL.VendorID = V.ID

LEFT JOIN	AddressEntity AEBusiness (NOLOCK) ON AEBusiness.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND AEBusiness.RecordID = VL.ID  AND AEBusiness.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
LEFT JOIN	AddressEntity AEBilling (NOLOCK) ON AEBilling.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND AEBilling.RecordID = VL.ID  AND AEBilling.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	AddressEntity AEOther (NOLOCK) ON AEOther.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND AEOther.RecordID = VL.ID  AND AEOther.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Other')

LEFT JOIN	PhoneEntity PECell (NOLOCK) ON PECell.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PECell.RecordID = VL.ID 	AND PECell.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Cell')
LEFT JOIN	PhoneEntity PEFax (NOLOCK) ON PEFax.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEFax.RecordID = VL.ID 	AND PEFax.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax')
LEFT JOIN	PhoneEntity PEDispatch (NOLOCK) ON PEDispatch.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEDispatch.RecordID = VL.ID 	AND PEDispatch.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
LEFT JOIN	PhoneEntity PEOffice (NOLOCK) ON PEOffice.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEOffice.RecordID = VL.ID 	AND PEOffice.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN	PhoneEntity PEOther (NOLOCK) ON PEOther.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEOther.RecordID = VL.ID 	AND PEOther.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Other')
LEFT JOIN	PhoneEntity PEAlternateDispatch (NOLOCK) ON PEAlternateDispatch.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND PEAlternateDispatch.RecordID = VL.ID 	AND PEAlternateDispatch.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'AlternateDispatch')
GO

