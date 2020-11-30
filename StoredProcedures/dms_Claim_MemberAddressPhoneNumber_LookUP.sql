IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Claim_MemberAddressPhoneNumber_LookUP]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Claim_MemberAddressPhoneNumber_LookUP] 
END 
GO 
CREATE PROC [dbo].[dms_Claim_MemberAddressPhoneNumber_LookUP](@memberID INT = NULL)
AS
BEGIN
DECLARE @Result AS TABLE
(
		MemberID	INT,
		MembershipID INT,
		MembershipNumber	NVARCHAR(100),
		MemberName	NVARCHAR(200),
		
		IsAddressFound BIT DEFAULT 0,
		IsPhoneFound BIT DEFAULT 0,
		
		Line1	NVARCHAR(100) NULL,
		Line2	NVARCHAR(100) NULL,
		Line3	NVARCHAR(100) NULL,
		City	NVARCHAR(100) NULL,
		PostalCode	NVARCHAR(50) NULL,
		CountryID	INT NULL,
		StateProvinceID INT NULL,
	
	    MemberPhoneNumber NVARCHAR(100) NULL
)

INSERT INTO @Result(
	MemberID,
	MembershipID,
	MembershipNumber,
	MemberName
)
SELECT
	   M.ID MemberID,
	   MS.ID MembershipID,
	   MS.MembershipNumber,
	   M.FirstName + ' ' + M.LastName MemberName
FROM   Member M
JOIN Membership MS ON MS.ID = M.MembershipID
WHERE M.ID = @memberID

;with wResult AS(
	SELECT	R.*,
			AE.AddressEntityID,
			AE.AddressRecordID,
			AE.AddressTypeID,
			AE.AddressLine1,
			AE.AddressLine2,
			AE.AddressLine3,
			AE.AddressCity,
			AE.AddressPostalCode,
			AE.AddressCountryID,
			AE.AddressStateProvinceID,
			AE.AddressID,
			PH.PhoneEntityID,
			PH.PhoneRecordID,
			PH.PhoneTypeID,
			PH.PhoneNumber,
			PH.PhoneID
			FROM @Result R
	JOIN	dbo.fnGetAddress('Member','Home',(SELECT MemberID FROM @Result)) AS AE ON R.MemberID = AE.AddressRecordID
	JOIN	dbo.fnGetPhoneDetails('Member','Home',(SELECT MemberID FROM @Result)) AS PH ON R.MemberID = PH.PhoneRecordID
)
UPDATE wResult
SET 
Line1 = wResult.AddressLine1,
Line2 = wResult.AddressLine2,
Line3 = wResult.AddressLine3,
City  = wResult.AddressCity,
PostalCode = wResult.AddressPostalCode,
CountryID = wResult.AddressCountryID,
StateProvinceID = wResult.AddressStateProvinceID,
MemberPhoneNumber = ISNULL(wResult.PhoneNumber,''),
IsAddressFound   = Case WHEN wResult.AddressID IS NULL THEN 0 ELSE 1 END,
IsPhoneFound     = Case WHEN wResult.PhoneID IS NULL THEN 0 ELSE 1 END

SELECT * FROM @Result
END