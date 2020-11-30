
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vendor_indicators_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vendor_indicators_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dms_vendor_indicators_get] 'VendorLocation',222
 
 CREATE PROCEDURE [dbo].[dms_vendor_indicators_get](
 @entityName NVARCHAR(255),
 @entityID INT
 )
 AS
 BEGIN

	DECLARE @indicators NVARCHAR(MAX) = NULL

	SELECT	@indicators = F.Indicators
	FROM	[dbo].[fnc_GetVendorIndicators](@entityName) F 
	WHERE	F.RecordID = @entityID
	

	SELECT ISNULL(@indicators,'') AS Indicators

 END