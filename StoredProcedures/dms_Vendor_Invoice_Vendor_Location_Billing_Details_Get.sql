-- Get Vendor Billing with logic added to check for Alternate
IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get @VendorLocationID=356, @POID=619
 CREATE PROCEDURE [dbo].dms_Vendor_Invoice_Vendor_Location_Billing_Details_Get( 
	@VendorLocationID INT =NULL
	, @POID INT = NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF
SELECT V.ID
	--, CASE
	--	WHEN ISNULL(CRS.ID,'') = '' THEN 'Not Contracted'
	--	ELSE 'Contracted'
	--	END AS 'ContractStatus'
	, CASE
		WHEN ContractedVendors.VendorID IS NOT NULL THEN 'Contracted'
		ELSE 'Not Contracted' 
		END AS ContractStatus
	, V.Name
	, V.VendorNumber
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine1
		ELSE AE.Line1
		END AS Line1
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine2
		ELSE AE.Line2
	END AS Line2
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN ''
		WHEN ISNULL(VI.ID, '') <> '' THEN VI.BillingAddressLine3
		ELSE AE.Line3
	END AS Line3
	, CASE
		WHEN ISNULL(AE.ID,'') = '' THEN 'No billing address on file'
		WHEN ISNULL(VI.ID,'') <> '' THEN
		ISNULL(REPLACE(RTRIM(
			COALESCE(VI.BillingAddressCity, '') +
			COALESCE(', ' + VI.BillingAddressStateProvince, '') +
			COALESCE(' ' + VI.BillingAddressPostalCode, '') +
			COALESCE(' ' + VI.BillingAddressCountryCode, '')
		), ' ', ' ')
	,'')
	ELSE ISNULL(REPLACE(RTRIM(
			COALESCE(AE.City, '') +
			COALESCE(', ' + AE.StateProvince, '') +
			COALESCE(' ' + AE.PostalCode, '') +
			COALESCE(' ' + AE.CountryCode, '')
		), ' ', ' ')
	,'')
	END AS BillingCityStZip
	, ISNULL(REPLACE(RTRIM(
		COALESCE(V.TaxSSN,'')+
		COALESCE(V.TaxEIN,'')
		), ' ', ' ')
	,'') AS TaxID
	, PE.PhoneNumber
	, V.Email
	, (V.ContactFirstName + ' ' + V.ContactLastName) AS ContactName
	, VI.ID AS VendorInvoiceID
FROM		Vendor V
JOIN		VendorLocation VL ON VL.VendorID = V.ID
LEFT JOIN	Contract C ON C.VendorID = V.ID
			AND C.IsActive = 1
LEFT JOIN ContractRateSchedule CRS ON CRS.ContractID = V.ID
			AND C.IsActive = 1
LEFT JOIN	AddressEntity AE ON AE.RecordID = V.ID
			AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND	AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	PhoneEntity PE ON PE.RecordID = V.ID
			AND	PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN	VendorInvoice VI ON VI.PurchaseOrderID = @POID
LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractedVendors ON v.ID = ContractedVendors.VendorID
WHERE VL.ID = @VendorLocationID
END
GO