IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_ServiceTech_RepairLocationDetails]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_ServiceTech_RepairLocationDetails] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 

CREATE PROC dms_ServiceTech_RepairLocationDetails(@ServiceRequestID AS INT = NULL)
AS
BEGIN

DECLARE @Result AS TABLE(
		
		ServiceRequestID INT NOT NULL,
		VendorLocationID INT NULL,
	
		VendorNumber		  NVARCHAR(MAX),
		VendorName			  NVARCHAR(MAX),
		VendorAddressLine1    NVARCHAR(MAX),
		VendorCity			  NVARCHAR(MAX),
		VendorStateProvince   NVARCHAR(MAX),
		VendorPostalCode      NVARCHAR(MAX),
		VendorCountryCode     NVARCHAR(MAX),
		VendorDispatchNumber  NVARCHAR(MAX),
		
		SRDestinationDescription    NVARCHAR(MAX),
		SRDestinationAddress    NVARCHAR(MAX),
		SRDestinationCity    NVARCHAR(MAX),
		SRDestinationStateProvince    NVARCHAR(MAX),
		SRDestinationPostalCode    NVARCHAR(MAX),
		SRDestinationCountryCode    NVARCHAR(MAX)
)

IF EXISTS (SELECT * FROM ServiceRequest SR WITH(NOLOCK) WHERE SR.ID = @ServiceRequestID AND SR.DestinationVendorLocationID IS NOT NULL)
BEGIN
	  DECLARE @DestinationVendorLocationID AS INT
	  SET     @DestinationVendorLocationID = (SELECT SR.DestinationVendorLocationID FROM ServiceRequest SR WITH(NOLOCK) WHERE SR.ID = @ServiceRequestID)
	  
	  INSERT INTO @Result(ServiceRequestID,VendorLocationID,VendorNumber,VendorName,VendorAddressLine1,VendorCity,VendorStateProvince,VendorPostalCode,VendorCountryCode,VendorDispatchNumber)
	  SELECT  @ServiceRequestID,
			  @DestinationVendorLocationID	
			, v.VendorNumber AS VendorNumber
			, v.Name AS VendorName
			, ae.Line1 AS Line1
			, ae.City AS City
			, ae.StateProvince AS StateProvince
			, ae.PostalCode AS PostalCode
			, ae.CountryCode AS CountryCode
			, ped.PhoneNumber AS DispatchNumber
	  FROM	VendorLocation vl (NOLOCK)
	  JOIN	Vendor v (NOLOCK) ON v.ID = vl.VendorID
	  JOIN	AddressEntity ae (NOLOCK) ON ae.RecordID = vl.ID AND ae.EntityID = (SELECT ID FROM Entity WHERE Name = 'VendorLocation')
	  LEFT JOIN PhoneEntity ped (NOLOCK) ON ped.RecordID = vl.ID AND ped.EntityID  = (SELECT ID FROM Entity WHERE Name = 'VendorLocation') AND ped.PhoneTypeID = (SELECT ID FROM PhoneType WHERE Name = 'Dispatch')
	  WHERE	vl.ID = @DestinationVendorLocationID
END
	
ELSE
	 INSERT INTO @Result(ServiceRequestID,SRDestinationDescription,SRDestinationAddress,SRDestinationCity,SRDestinationStateProvince,SRDestinationPostalCode,SRDestinationCountryCode)
	 SELECT	  @ServiceRequestID
			, sr.DestinationDescription 
			, sr.DestinationAddress
			, sr.DestinationCity
			, sr.DestinationStateProvince
			, sr.DestinationPostalCode
			, sr.DestinationCountryCode
	FROM	ServiceRequest sr (NOLOCK)
	WHERE	sr.ID = @ServiceRequestID
BEGIN

SELECT * FROM @Result
	
END

END