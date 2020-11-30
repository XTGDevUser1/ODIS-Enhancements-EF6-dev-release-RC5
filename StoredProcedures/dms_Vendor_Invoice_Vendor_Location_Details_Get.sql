-- Get VendorLocation data
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Details_Get @VendorLocationID=356
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Details_Get( 
	@VendorLocationID INT =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
	
	SELECT VL.ID
	 ,CASE WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted' ELSE 'Not Contracted' END AS 'ContractStatus'
	, V.Name
	, V.VendorNumber
	, AE.Line1
	, AE.Line2
	, AE.Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, PE24.PhoneNumber AS [24HRNumber]
	, PEFax.PhoneNumber AS FaxNumber
	, 'Talked To' AS TalkedTo
	
	FROM VendorLocation VL
	JOIN Vendor V ON V.ID = VL.VendorID
	LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
	LEFT JOIN Contract C ON C.VendorID = V.ID
	AND C.IsActive = 1
	LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
	AND C.IsActive = 1
	LEFT JOIN AddressEntity AE ON AE.RecordID = VL.ID
	AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Business')
	LEFT JOIN PhoneEntity PE24 ON PE24.RecordID = VL.ID
	AND PE24.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND PE24.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
	LEFT JOIN PhoneEntity PEFax ON PEFax.RecordID = VL.ID
	AND PEFax.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	AND PEFax.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Fax')
	WHERE VL.ID = @VendorLocationID
END
GO