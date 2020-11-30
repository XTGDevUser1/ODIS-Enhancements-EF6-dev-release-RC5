-- Drop older functions and assembly
DROP AGGREGATE dbo.fnConcatenate
DROP ASSEMBLY CustomProduct

ALTER DATABASE TEST SET TRUSTWORTHY OFF;
GO

-- NOTE: If the above step takes longer, give it some time and cancel the query. Execute the following statements to claim the ownership back.
/*


DECLARE @Command VARCHAR(MAX) = 'ALTER AUTHORIZATION ON DATABASE::DMS_TEST TO 
[NMCDALLAS\ragrawal]' 

SELECT @Command = REPLACE(REPLACE(@Command 
            , 'DMS_TEST', SD.Name)
            , 'NMCDALLAS\ragrawal', SL.Name)
FROM master..sysdatabases SD 
JOIN master..syslogins SL ON  SD.SID = SL.SID
WHERE  SD.Name = DB_NAME()

PRINT @Command
EXEC(@Command)

*/
exec sp_configure  'clr enabled','1'
Reconfigure with override
GO

use master;
create asymmetric key ODISCLRExtensionKey
from file = 'G:\My Projects\ODIS-NMC-TFS\ODIS-Enhancements-EF6-dev\ReferenceDLLs\SQLAggregateFunctions\CustomProduct\ODIS-CLR-Key.snk'
encryption by password = 'm@rt3x13'


use TEST;
create login ODISCLRExtensionLogin from asymmetric key ODISCLRExtensionKey;

use master;
grant external access assembly to ODISCLRExtensionLogin;

use TEST;
CREATE ASSEMBLY ODISCLR FROM 'G:\My Projects\ODIS-NMC-TFS\ODIS-Enhancements-EF6-dev\ReferenceDLLs\SQLAggregateFunctions\CustomProduct\bin\Release\ODISCLR.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS;
GO

-- Function that was already in use in ODIS.
CREATE AGGREGATE fnConcatenate (@input nvarchar(100)) RETURNS nvarchar(max)
EXTERNAL NAME ODISCLR.Concatenate


-- New function for Geocode support
CREATE FUNCTION [dbo].[fnGeocode](
  @countryRegion nvarchar(max),
  @adminDistrict nvarchar(max),
  @locality nvarchar(max),  
  @postalCode nvarchar(max),
  @addressLine nvarchar(max) 
  ) RETURNS geography
AS EXTERNAL NAME
ODISCLR.[Spatial.Geocoder].GeocodeUDF;


-- Validate the new API
DECLARE @point geography
SELECT @point = [dbo].[fnGeocode]('US','', 'Arlington','','')
SELECT @point as SpatialType,
		@point.Lat as Latitude,
		@point.Long as Longitude

-- Cleanup if you want to remove the assembly
--DROP FUNCTION [dbo].[fnGeocode]
--DROP ASSEMBLY ODISCLR

