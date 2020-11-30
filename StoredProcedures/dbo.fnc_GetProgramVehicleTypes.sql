
/****** Object:  UserDefinedFunction [dbo].[fnc_GetProgramVehicleTypes]    Script Date: 11/02/2012 13:27:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER FUNCTION [dbo].[fnc_GetProgramVehicleTypes] (@ProgramID int)
RETURNS @ProgramVehicleType TABLE
   (
    VehicleTypeID int
   )
AS
BEGIN

			
		;WITH wProgramVehicleType
		AS
		(
			SELECT DISTINCT PVT.VehicleTypeID,
			PVT.ProgramID,
			P.ParentProgramID,
		    0 as Iteration
		    FROM Program P
			LEFT JOIN ProgramVehicleType PVT on PVT.ProgramID = P.ID AND PVT.IsActive = 1
			WHERE P.ID = (SELECT TOP 1 PV.ProgramID 
									FROM ProgramVehicleType PV
									JOIN fnc_GetProgramsandParents(@ProgramID) fnc ON fnc.ProgramID = PV.ProgramID
									ORDER BY fnc.Sequence) 
			AND P.IsActive = 1
			
			UNION ALL
			
			SELECT PVT.VehicleTypeID,
			PVT.ProgramID, 
			P.ParentProgramID,
			wP.Iteration + 1
			FROM Program P
			JOIN wProgramVehicleType wP ON P.ID = wP.ParentProgramID  
			JOIN ProgramVehicleType PVT ON P.ID = PVT.ProgramID AND PVT.IsActive = 1
			WHERE P.IsActive = 1 
			--AND (SELECT COUNT(*) FROM wProgramVehicleType WHERE VehicleTypeID IS NOT NULL) = 0
		)

		INSERT @ProgramVehicleType 
		SELECT DISTINCT VehicleTypeID from wProgramVehicleType  
		ORDER BY VehicleTypeID 
	
		

RETURN 

END






