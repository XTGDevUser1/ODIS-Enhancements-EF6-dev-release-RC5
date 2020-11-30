IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_diagnostic_codes_save]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_diagnostic_codes_save]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- SELECT * FROM ServiceRequestVehicleDiagnosticCode WHERE ServiceRequestID = 2
-- EXEC [dbo].[dms_diagnostic_codes_save] 2,'1,2','Standard',1,'system'
 
CREATE PROCEDURE [dbo].[dms_diagnostic_codes_save]( 
	@serviceRequestID INT = NULL,
	@selectedCodes NVARCHAR(MAX),
	@codeType NVARCHAR(100),
	@primaryCode INT,
	@createBy NVARCHAR(50)
)
AS
BEGIN

	DELETE FROM ServiceRequestVehicleDiagnosticCode WHERE ServiceRequestID = @serviceRequestID
	
	INSERT INTO ServiceRequestVehicleDiagnosticCode 
						( 
							ServiceRequestID,
							VehicleDiagnosticCodeID,
							VehicleDiagnosticCodeType,
							IsPrimary,
							CreateBy,
							CreateDate
						)
	SELECT	@serviceRequestID,
			F.item,
			@codeType,
			CASE WHEN F.item = @primaryCode
				THEN 1
				ELSE 0
			END,
			@createBy,
			GETDATE()			
	 FROM	[dbo].[fnSplitString](@selectedCodes,',') F

END
