IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Claim_PurchaseOrderNumber_LookUP]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Claim_PurchaseOrderNumber_LookUP] 
END 
GO 
--EXEC dms_Claim_PurchaseOrderNumber_LookUP '7770460'
CREATE PROC [dbo].[dms_Claim_PurchaseOrderNumber_LookUP](@PurchaseOrderNumber NVARCHAR(100) = NULL)
AS
BEGIN
DECLARE @Result AS TABLE
(
		PurchaseOrderID	 INT,
		PurchaseOrderNumber	 NVARCHAR(100),
		ProgramID INT NULL,
		ProgramName NVARCHAR(50) NULL,
		MemberID	INT,
		MembershipID INT,
		MembershipNumber	NVARCHAR(100),
		MemberName	NVARCHAR(200),
		
		VendorNumber NVARCHAR(100),
		VendorName NVARCHAR(100) NULL,
		
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
	PurchaseOrderID,
	PurchaseOrderNumber,
	ProgramID,
	ProgramName,
	MemberID,
	MembershipID,
	MembershipNumber,
	MemberName,
	VendorNumber,
	VendorName
)
SELECT PO.ID PurchaseOrderID,
	   PO.PurchaseOrderNumber,
	   P.ID,
	   P.Name,
	   M.ID MemberID,
	   MS.ID MembershipID,
	   MS.MembershipNumber,
	   M.FirstName + ' ' + M.LastName MemberName,
	   V.VendorNumber,
	   V.Name
FROM   PurchaseOrder PO
JOIN VendorLocation VL ON VL.ID = PO.VendorLocationID
JOIN Vendor V ON V.ID = VL.VendorID
JOIN ServiceRequest SR ON SR.ID = PO.ServiceRequestID
JOIN [Case] C ON C.ID = SR.CaseID
JOIN [Program] P ON C.ProgramID = P.ID
JOIN Member M ON M.ID = C.MemberID
JOIN Membership MS ON MS.ID = M.MembershipID
WHERE PO.PurchaseOrderNumber = @PurchaseOrderNumber

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
MemberPhoneNumber = wResult.PhoneNumber,
IsAddressFound   = Case WHEN wResult.AddressID IS NULL THEN 0 ELSE 1 END,
IsPhoneFound     = Case WHEN wResult.PhoneID IS NULL THEN 0 ELSE 1 END

SELECT * FROM @Result
END