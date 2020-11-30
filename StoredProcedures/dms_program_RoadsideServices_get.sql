IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_program_RoadsideServices_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_program_RoadsideServices_get]
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_program_RoadsideServices_get] 458
CREATE PROCEDURE [dbo].[dms_program_RoadsideServices_get]( 
   @ProgramID int 
) 
AS 
BEGIN 
  
	--DECLARE @ProgramID INT = 1
  
	SET NOCOUNT ON


	SELECT 
		ProgramService.Name ProgramService
		,ProgramService.[Description] ProgramServiceDescription
		,ProgramService.Limit
		,ProgramService.IsLightDuty
		,ProgramService.IsMediumDuty
		,ProgramService.IsHeavyDuty
	FROM (
		SELECT	pc.[Name] AS Name
			, pc.[Description] AS [Description]
			, max(CASE
				WHEN pp.ServiceCoverageLimit > 0 THEN '$' + CONVERT(NVARCHAR(10),CONVERT(NUMERIC(10),pp.ServiceCoverageLimit))
				WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 1 THEN 'Best Value'
				WHEN pp.ServiceCoverageLimit = 0 AND pp.IsServiceCoverageBestValue = 0 THEN '$0'
				WHEN pp.ServiceCoverageLimit >= 0 AND pp.IsReimbursementOnly = 1 THEN '$' + CONVERT(NVARCHAR(10),CONVERT(NUMERIC(10),pp.ServiceCoverageLimit)) + '-' + 'Reimbursement'
				WHEN pp.ServiceCoverageLimit = 0 AND pp.IsReimbursementOnly = 0 THEN 'Assit Only'
				ELSE ''
				END) +
				coalesce(max(CASE WHEN convert(nvarchar(3),pp.ServiceMileageLimit) > 0 THEN ' - ' + convert(nvarchar(3),pp.ServiceMileageLimit) + ' miles' ELSE '' END), '')
				AS Limit
			,MAX(CASE WHEN vc.Name IS NULL OR vc.Name = 'LightDuty' THEN 1 ELSE 0 END) IsLightDuty
			,MAX(CASE WHEN vc.Name IS NULL OR vc.Name = 'MediumDuty' THEN 1 ELSE 0 END) IsMediumDuty
			,MAX(CASE WHEN vc.Name IS NULL OR vc.Name = 'HeavyDuty' THEN 1 ELSE 0 END) IsHeavyDuty
			--, max(CASE WHEN RIGHT(p.Name,2) = 'LD' THEN 'LD' ELSE '' END) +
			--coalesce('-' + max(CASE WHEN RIGHT(p.Name,2) = 'MD' THEN 'MD' END),'') +
			--coalesce('-'+max(CASE WHEN RIGHT(p.Name,2) = 'HD' THEN 'HD' END),'') AS Vehicles
			,pc.Sequence
		FROM	ProgramProduct pp
		JOIN	Product p (NOLOCK) ON p.id = pp.ProductID
		JOIN	ProductCategory pc (NOLOCK) ON pc.id = p.productcategoryid
		LEFT OUTER JOIN VehicleCategory vc ON vc.ID = p.VehicleCategoryID
		WHERE	pc.Name NOT IN ('Tech','Mobile')
			AND pc.IsVehicleRequired = 1
			AND	 pp.ProgramID = @ProgramID
		GROUP BY pc.Name, pc.[Description], pc.sequence
		) ProgramService 
	WHERE ProgramService.Limit NOT IN ('$0','Assist Only','')
	ORDER BY ProgramService.Sequence

END
