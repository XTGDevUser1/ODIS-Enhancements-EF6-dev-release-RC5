
exec sp_configure  'clr enabled','1'
Reconfigure with override
GO

use master;
create asymmetric key ODISCLRPaymentExtensionKey
from file = 'E:\ODIS-CLR\ODIS-CLR-Payment.snk'
encryption by password = 'm@rt3x13'


use DMS_TEST;
create login ODISCLRPaymentExtensionLogin from asymmetric key ODISCLRPaymentExtensionKey;


use DMS_TEST;
CREATE ASSEMBLY ODISCLRForEncryption FROM 'E:\ODIS-CLR\ODIS-CLR-Payment.dll'
GO

-- Function that was already in use in ODIS.
--CREATE AGGREGATE fnConcatenate (@input nvarchar(100)) RETURNS nvarchar(max)
--EXTERNAL NAME ODISCLR.Concatenate


-- New function for Encrypt String;
CREATE FUNCTION fnEncryptString (@input nvarchar(100)) RETURNS nvarchar(max)
EXTERNAL NAME ODISCLRForEncryption.[ODIS_CLR_Payment.EncryptString].Encrypt


GO
select dbo.fnEncryptString('4715625817520150')  --"4715625817520150"