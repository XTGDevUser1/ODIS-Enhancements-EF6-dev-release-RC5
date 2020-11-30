IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VendorLocation_GeoLocation_Update]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[VendorLocation_GeoLocation_Update]
GO

CREATE PROCEDURE [dbo].[VendorLocation_GeoLocation_Update]
(	
	@pClientID int = null,
	@pClientVendorKey varchar(50) = null,
	@pCountryCode varchar(2) = null,
	@pStateProvinceCode varchar(10) = null,
	@pCity varchar(100) = null,
	@pPostalCode varchar(20) = null,
	@pAddressLine1 varchar(100) = null
)
AS
--******************************************************************************************
--******************************************************************************************
--
--SELECT @point = [dbo].[fnGeocode]('US','TX', 'Arlington','76011','818 W Park Row Dr')
--******************************************************************************************
--******************************************************************************************

DECLARE @point geography

SELECT @point = dbo.[fnGeocode](@pCountryCode ,@pStateProvinceCode , @pCity ,@pPostalCode ,@pAddressLine1 )

DECLARE @vendorID int
select @VendorID = id from Vendor where ClientVendorKey = @pClientVendorKey and ClientID = @pClientID 


UPDATE VendorLocation
	SET GeographyLocation = @point,
		Latitude = @point.Lat,
		Longitude = @point.Long
	WHERE VendorID = @vendorID
GO

