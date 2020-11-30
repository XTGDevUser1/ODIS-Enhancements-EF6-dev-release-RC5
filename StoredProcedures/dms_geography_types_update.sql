IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_geography_types_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_geography_types_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO
 --EXEC dms_geography_types_update @entityID=640, @entityName='VendorLocation'
CREATE PROCEDURE [dbo].[dms_geography_types_update](
 @entityID INT, -- This could be the entityID or the related record id.
 @entityName NVARCHAR(100)
)
AS
BEGIN

	IF @entityName = 'VendorLocation'
	BEGIN
	
		UPDATE	VendorLocation
		SET		GeographyLocation = CASE WHEN Latitude IS NOT NULL AND Longitude IS NOT NULL
										THEN geography::Point(Latitude, Longitude, 4326)  
										ELSE NULL
									END
		WHERE	ID = @entityID
	
	END
	ELSE IF @entityName = 'VendorLocationVirtual'
	BEGIN
		
		UPDATE	VendorLocationVirtual
		SET		GeographyLocation = CASE WHEN Latitude IS NOT NULL AND Longitude IS NOT NULL
										THEN geography::Point(Latitude, Longitude, 4326)  
										ELSE NULL
									END
		WHERE	VendorLocationID = @entityID	
	END
END
