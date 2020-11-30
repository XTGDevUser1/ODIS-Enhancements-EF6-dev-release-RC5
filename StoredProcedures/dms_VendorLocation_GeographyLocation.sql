IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_VendorLocation_GeographyLocation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_VendorLocation_GeographyLocation]
 END 
 GO  

CREATE PROC dbo.[dms_VendorLocation_GeographyLocation](@vendorLocationID INT = NULL)
AS
BEGIN
DECLARE @Result AS TABLE(
	
	Latitude DECIMAL(10,7) NULL,
	Longitude DECIMAL(10,7) NULL,
	GeographyDetails NVARCHAR(MAX) NULL
)

INSERT INTO @Result SELECT GeographyLocation.Lat,GeographyLocation.Long,CONVERT(NVARCHAR(MAX),GeographyLocation) FROM VendorLocation WHERE ID = @vendorLocationID

SELECT * FROM @Result

END

