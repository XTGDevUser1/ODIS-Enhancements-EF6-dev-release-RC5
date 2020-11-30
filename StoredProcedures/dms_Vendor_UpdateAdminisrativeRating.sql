IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_UpdateAdminisrativeRating]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_UpdateAdminisrativeRating] 
 END 
 GO  
 SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[dms_Vendor_UpdateAdminisrativeRating] 
AS
BEGIN

      Update v1 Set 
      --select v1.id, (Select name from VendorStatus where id = v1.VendorStatusID), v1.vendornumber, v1.AdministrativeRating,
            AdministrativeRating = v2.AdministrativeRating,
            AdministrativeRatingModifyDate = GETDATE()
      From vendor v1
      JOIN (
            SELECT v.ID, v.VendorNumber
                  ,CASE WHEN ContractVendor.VendorID IS NOT NULL THEN 60 ELSE 20 END +
                   CASE WHEN v.InsuranceExpirationDate >= getdate() THEN 10 ELSE 0 END +
                   CASE WHEN ach.ID IS NOT NULL THEN 10 ELSE 0 END +
                   CASE WHEN [24Hours].VendorID IS NOT NULL THEN 10 ELSE 0 END +
                   CASE WHEN (v.TaxSSN IS NOT NULL AND LEN(v.TaxSSN) = 9) OR v.TaxEIN IS NOT NULL THEN 10 ELSE 0 END AS AdministrativeRating
            FROM dbo.Vendor v
            LEFT OUTER JOIN dbo.fnGetContractedVendors() ContractVendor On ContractVendor.VendorID = v.ID
            LEFT OUTER JOIN VendorACH ach ON ach.VendorID = v.ID AND ach.IsActive = 1 AND ach.ACHStatusID = (SELECT ID FROM ACHStatus WHERE Name = 'Valid')
            LEFT OUTER JOIN (
                  Select VendorID
                  From VendorLocation 
                  Where IsOpen24Hours = 'TRUE'
                  Group By VendorID
                  ) [24Hours] On [24Hours].VendorID = v.ID
            ) v2 on v2.ID = v1.ID
      where ISNULL(v1.AdministrativeRating, 0) <> v2.AdministrativeRating
      and v1.VendorStatusID = (SELECT ID FROM VendorStatus WHERE Name = 'Active')
END
