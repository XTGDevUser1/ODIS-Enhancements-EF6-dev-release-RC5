IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Invoice_Current_Billing_Information_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Invoice_Current_Billing_Information_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  --EXEC [dms_Vendor_Invoice_Current_Billing_Information_Get] @POID=990
 CREATE PROCEDURE [dbo].[dms_Vendor_Invoice_Current_Billing_Information_Get]( 
	@POID INT =NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET FMTONLY OFF

SELECT		V.ID VendorID
			, V.VendorNumber
			, V.Name
			, VS.Name AS [Status]
			, CASE WHEN AE.ID IS NOT NULL THEN ISNULL(AE.Line1,'') ELSE '' END AS Line1
			, CASE WHEN AE.ID IS NOT NULL THEN ISNULL(AE.Line2,'') ELSE '' END AS Line2
			, CASE WHEN AE.ID IS NOT NULL THEN ISNULL(AE.Line3,'') ELSE '' END AS Line3
			, CASE WHEN AE.ID IS NOT NULL THEN 
				ISNULL(REPLACE(RTRIM(
						COALESCE(AE.City, '') + 
						COALESCE(', ' + RTRIM(AE.StateProvince), '') +     
						COALESCE(' ' + AE.PostalCode, '') +     					
						COALESCE(' ' + AE.CountryCode, '') 
					), '  ', ' ')
					,'')
				ELSE ''
			  END AS BillingCityStZip
			, CASE
				WHEN ISNULL(ACHS.Name,'') = 'Valid' THEN 'ACH'
				ELSE 'Check'
			  END AS PaymentType
			, (ISNULL(V.ContactFirstName,'') + CASE WHEN ISNULL(V.ContactFirstName,'') <> '' THEN ' ' ELSE '' END + ISNULL(V.ContactLastName,'')) AS ContactName
			, PE.PhoneNumber
			, V.Email
			, ISNULL(REPLACE(RTRIM(
				COALESCE('XXX-XX-' + RIGHT(V.TaxSSN,4),'')+
				COALESCE(V.TaxEIN,'')
			   ), '  ', ' ')
			   ,'') AS TaxID
			  
			, V.IsLevyActive  
			, CASE WHEN V.IsLevyActive = 1 THEN ISNULL(V.LevyRecipientName,'') ELSE NULL END AS LevyRecipientName
			, CASE WHEN V.IsLevyActive = 1 AND LevyAE.ID IS NOT NULL THEN ISNULL(LevyAE.Line1,'') ELSE NULL END AS LevyAddressLine1
			, CASE WHEN V.IsLevyActive = 1 AND LevyAE.ID IS NOT NULL THEN ISNULL(LevyAE.Line2,'') ELSE NULL END AS LevyAddressLine2
			, CASE WHEN V.IsLevyActive = 1 AND LevyAE.ID IS NOT NULL THEN ISNULL(LevyAE.Line3,'') ELSE NULL END AS LevyAddressLine3
			, CASE
				WHEN V.IsLevyActive = 1 AND LevyAE.ID IS NOT NULL THEN
					ISNULL(REPLACE(RTRIM(
						COALESCE(LevyAE.City, '') + 
						COALESCE(', ' + RTRIM(LevyAE.StateProvince), '') +     
						COALESCE(' ' + LevyAE.PostalCode, '') +     					
						COALESCE(' ' + LevyAE.CountryCode, '') 
					), '  ', ' ')
					,'')
				ELSE NULL
				END AS LevyCityStZip
			, CASE WHEN V.IsLevyActive = 1 THEN 'Check' ELSE NULL END AS LevyPaymentType
			
FROM		PurchaseOrder PO WITH (NOLOCK)
JOIN		VendorLocation VL WITH (NOLOCK) ON VL.ID = PO.VendorLocationID
JOIN		Vendor V WITH (NOLOCK) ON VL.VendorID = V.ID
JOIN		VendorStatus VS WITH (NOLOCK) ON VS.ID = V.VendorStatusID 
LEFT JOIN	AddressEntity AE WITH (NOLOCK) ON AE.RecordID = V.ID 
			AND AE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND AE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
LEFT JOIN	AddressEntity LevyAE WITH (NOLOCK) ON LevyAE.RecordID = V.ID 
			AND LevyAE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND LevyAE.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Levy')
LEFT JOIN	PhoneEntity PE WITH (NOLOCK) ON PE.RecordID = V.ID
			AND PE.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
			AND PE.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
LEFT JOIN	VendorACH ACH WITH (NOLOCK) ON ACH.VendorID = V.ID
LEFT JOIN	ACHStatus ACHS WITH (NOLOCK) ON ACHS.ID = ACH.ACHStatusID
WHERE		PO.ID = @POID

END
GO