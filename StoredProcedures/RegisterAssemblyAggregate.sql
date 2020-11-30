CREATE ASSEMBLY ODISCLR FROM 'G:\My Projects\ODIS-NMC-TFS\ODIS-Enhancements-EF6-dev\ReferenceDLLs\SQLAggregateFunctions\CustomProduct\bin\Release\ODISCLR.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS;
GO

CREATE AGGREGATE fnConcatenate (@input nvarchar(100)) RETURNS nvarchar(max)
EXTERNAL NAME ODISCLR.Concatenate

exec sp_configure  'clr enabled','1'
Reconfigure with override

ALTER DATABASE Test SET TRUSTWORTHY ON;
GO

CREATE FUNCTION [dbo].[fnGeocode](
  @countryRegion nvarchar(max),
  @adminDistrict nvarchar(max),
  @locality nvarchar(max),  
  @postalCode nvarchar(max),
  @addressLine nvarchar(max) 
  ) RETURNS geography
AS EXTERNAL NAME
ODISCLR.[Spatial.Geocoder].GeocodeUDF;


SELECT [dbo].[fnConcatenate](City)
FROM	[Address]

DECLARE @point geography
SELECT @point = [dbo].[fnGeocode]('US','', 'Arlington','','')
SELECT @point as SpatialType,
		@point.Lat as Latitude,
		@point.Long as Longitude

DROP FUNCTION [dbo].[fnGeocode]
--DROP AGGREGATE dbo.fnProduct
DROP AGGREGATE dbo.fnConcatenate
DROP ASSEMBLY ODISCLR