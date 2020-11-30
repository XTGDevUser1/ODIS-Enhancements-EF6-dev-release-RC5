IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Vendor_By_Number_Phone_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Vendor_By_Number_Phone_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Vendor_By_Number_Phone_Get] 72237,1
CREATE PROCEDURE [dbo].[dms_Vendor_By_Number_Phone_Get](
	@vendorNumber NVARCHAR(50),
	@phoneNumber NVARCHAR(50)
)
AS
BEGIN

	DECLARE @vendorEntityID INT = (SELECT ID FROM Entity WHERE Name = 'Vendor'),
			@vendorLocationEntityID INT = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')

	SELECT	V.ID AS VendorID,
			PH.PhoneTypeID AS PhoneTypeID,
			PH.PhoneNumber AS PhoneNumber
	FROM	Vendor V WITH (NOLOCK) 	
	JOIN	PhoneEntity PH WITH (NOLOCK) ON PH.EntityID = @vendorEntityID AND PH.RecordID = V.ID
	WHERE	V.VendorNumber = @vendorNumber
	AND		PH.PhoneNumber = @phoneNumber

	UNION ALL

	SELECT	V.ID AS VendorID,
			PH.PhoneTypeID AS PhoneTypeID,
			PH.PhoneNumber AS PhoneNumber
	FROM	Vendor V WITH (NOLOCK) 	
	JOIN	VendorLocation VL WITH (NOLOCK) ON VL.VendorID = V.ID
	JOIN	PhoneEntity PH WITH (NOLOCK) ON PH.EntityID = @vendorLocationEntityID AND PH.RecordID = VL.ID
	WHERE	V.VendorNumber = @vendorNumber
	AND		PH.PhoneNumber = @phoneNumber

END