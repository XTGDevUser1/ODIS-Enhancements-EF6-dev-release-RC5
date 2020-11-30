exec sp_configure  'clr enabled','1'
Reconfigure with override
GO

use master;
create asymmetric key ODISCLRExtensionKeyForMapSnapshot
from file = 'F:\ODIS-CLR-Maps\ODIS-CLR-key.snk'
encryption by password = 'm@rt3x13'


use DMS_DEV_Enhancement;
create login ODISCLRExtensionLoginForMapSnapshot from asymmetric key ODISCLRExtensionKeyForMapSnapshot;

use master;
grant external access assembly to ODISCLRExtensionLoginForMapSnapshot;

use DMS_DEV_Enhancement;
CREATE ASSEMBLY ODISCLRForMapSnapshot FROM 'D:\Backup\ODIS-Map-Snapshot.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS;
GO

-- Function that was already in use in ODIS.
CREATE FUNCTION fnGenerateMapSnapshot (@serviceLocationLatitude decimal(10,7),
										@serviceLocationLongitude decimal(10,7),
										@destinationLatitude decimal(10,7),
										@destinationLongitude decimal(10,7),
										@bingKey nvarchar(max)
										)
										RETURNS nvarchar(max)
EXTERNAL NAME ODISCLRForMapSnapshot.[ODIS.Map.Snapshot.MapSnapshotGenerator].GetSnapshot


-- Cleanup if you want to remove the assembly
--DROP FUNCTION [dbo].[fnGenerateMapSnapshot]
--DROP ASSEMBLY ODISCLRForMapSnapshot
/* Example

DECLARE @bingKey NVARCHAR(MAX)
SELECT @bingKey = Value FROM ApplicationConfiguration WHERE Name = 'BING_API_KEY'
SELECT [dbo].[fnGenerateMapSnapshot](SR.ServiceLocationLatitude,
									SR.ServiceLocationLongitude,
									SR.DestinationLatitude,
									SR.DestinationLongitude,
									@bingKey
									) AS SnapshotAsBase64
FROM	ServiceRequest SR
WHERE ID = 1533

*/
