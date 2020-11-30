IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_Dashboard_Profile_completeness]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_Dashboard_Profile_completeness]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 


CREATE PROC [dbo].[dms_Vendor_Dashboard_Profile_completeness](@VendorID INT = NULL)
AS
BEGIN
SELECT 
Profile.Registered
, Profile.AddressPhoneEmail
, Profile.[24HourFlag]
, Profile.TaxID
, Profile.Insurance
, Profile.ACH
, Profile.Contract
, CASE WHEN Profile.Registered = 1 
AND Profile.AddressPhoneEmail = 1 
AND Profile.[24HourFlag] = 1 
AND Profile.TaxID = 1 
AND Profile.Insurance = 1 
AND Profile.ACH = 1 
AND Profile.Contract = 1 
THEN 'Preferred'
ELSE 'NotPreferred'
END AS PreferredStatus

FROM (
		SELECT 
		v.ID
	     , CASE WHEN VendorUser.UserID IS NOT NULL THEN 1 ELSE 0 END Registered
	    , CASE WHEN VendorAddress.AddressID IS NOT NULL AND VendorPhone.PhoneID IS NOT NULL AND v.Email IS NOT						NULL THEN 1 ELSE 0 END AddressPhoneEmail
		, CASE WHEN [24Hours].VendorID IS NOT NULL THEN 1 ELSE 0 END [24HourFlag]
		, CASE WHEN (v.TaxSSN IS NOT NULL AND LEN(v.TaxSSN) = 9) OR v.TaxEIN IS NOT NULL THEN 1 ELSE 0 END TaxID
		, CASE WHEN v.InsuranceExpirationDate >= getdate() THEN 1 ELSE 0 END Insurance
		, CASE WHEN ach.ID IS NOT NULL THEN 1 ELSE 0 END ACH
		, CASE WHEN VendorContract.ContractID IS NOT NULL THEN 1 ELSE 0 END [Contract]
FROM dbo.Vendor v
LEFT OUTER JOIN (
					SELECT TOP 1 VendorID, ID UserID
					FROM VendorUser WHERE VendorID = @VendorID
) VendorUser ON VendorUser.VendorID = v.ID 
LEFT OUTER JOIN (
SELECT ae.RecordID VendorID, ae.ID AddressID
FROM AddressEntity ae 
WHERE ae.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
AND ae.AddressTypeID = (SELECT ID FROM AddressType WHERE Name = 'Billing')
) VendorAddress ON VendorAddress.VendorID = v.ID
LEFT OUTER JOIN (
SELECT pe.RecordID VendorID, pe.ID PhoneID
FROM PhoneEntity pe 
WHERE pe.EntityID = (SELECT ID FROM Entity WHERE Name = 'Vendor')
AND pe.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Office')
) VendorPhone ON VendorPhone.VendorID = v.ID
LEFT OUTER JOIN (
SELECT VendorID, ContractID
FROM [dbo].[fnGetCurrentProductRatesByVendorLocation]() 
GROUP BY VendorID, ContractID
) VendorContract ON VendorContract.VendorID = v.ID
LEFT OUTER JOIN VendorACH ach ON ach.VendorID = v.ID AND ach.IsActive = 1 AND ach.ACHStatusID = (SELECT ID FROM ACHStatus WHERE Name = 'Valid')
LEFT OUTER JOIN (
Select VendorID
From VendorLocation 
Where IsOpen24Hours = 'TRUE'
Group By VendorID
) [24Hours] On [24Hours].VendorID = v.ID
WHERE v.ID =@VendorID
) Profile
END
