IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_claim_diagnostic_codes_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_claim_diagnostic_codes_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
/****** Object:  StoredProcedure [dbo].[dms_claim_diagnostic_codes_get]    Script Date: 04/16/2013 16:52:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- EXEC [dbo].[dms_claim_diagnostic_codes_get] 37,2
 
CREATE PROCEDURE [dbo].[dms_claim_diagnostic_codes_get]( 
	@claimID INT = NULL,
	@VehicleTypeID INT = NULL,
	@CodeType NVARCHAR(50) = 'Ford Claim'
)
AS
BEGIN

	WITH wSelectedCodesForClaim
	AS
	(
		SELECT	VehicleDiagnosticCodeID AS ID,
				IsPrimary
		FROM	ClaimVehicleDiagnosticCode
		WHERE	ClaimID = @claimID
	),
	wAllDiagnosticCodes
	AS
	(
		SELECT	VDC.ID
				, dc.Name as CategoryName
				, CASE @CodeType 
					WHEN 'Ford Claim' THEN vdc.FordClaimCode					
					ELSE ''
				  END AS Code
				, vdc.name AS CodeName
				, dc.Sequence AS DCSequence
				, vdc.Sequence AS VDCSequence
		FROM	VehicleTypeVehicleDiagnosticCode vtvdc
		LEFT JOIN VehicleDiagnosticCode vdc on vtvdc.VehicleDiagnosticCodeID = vdc.ID
		LEFT JOIN VehicleDiagnosticCategory dc on vdc.VehicleDiagnosticCategoryID = dc.ID	
		WHERE vtvdc.IsActive = 'TRUE' 
		AND (ISNULL(vdc.IsActive,'TRUE') = 'TRUE')
		AND vtvdc.VehicleTypeID = @VehicleTypeID
		AND CASE @CodeType 
					WHEN 'Ford Claim' THEN vdc.FordClaimCode					
					ELSE ''
				  END <> '' --TP 4/16
		
	)	
	
	SELECT	wAll.ID,
			wAll.CategoryName,
			wAll.Code,
			wAll.CodeName,
			CASE WHEN WS.ID IS NULL
				THEN 0
				ELSE 1
			END AS IsSelectedForServiceRequest,
			WS.IsPrimary
	FROM	wAllDiagnosticCodes wAll
	LEFT JOIN wSelectedCodesForClaim WS ON WAll.ID = WS.ID
	ORDER BY wAll.DCSequence, wAll.VDCSequence
END
