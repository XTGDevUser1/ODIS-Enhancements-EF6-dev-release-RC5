IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_vehicles_max_allowed_get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_vehicles_max_allowed_get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_vehicles_max_allowed_get] 2,2
 create PROCEDURE [dbo].[dms_vehicles_max_allowed_get]( 
   @programID INT = NULL ,
   @vehicleTypeID INT = NULL 
 ) 
 AS 
 BEGIN 
 
 DECLARE @maxAllowedVehicles INT
 SET @maxAllowedVehicles = NULL
 
 DECLARE @tmpPrograms TABLE
(
	LevelID INT IDENTITY(1,1),
	ProgramID INT
)

INSERT INTO @tmpPrograms
SELECT ProgramID FROM fnc_GetProgramsandParents (@programID)
	

;WITH wProgramVehicleTypes
AS
(	
	SELECT ROW_NUMBER() OVER (ORDER BY P.LevelID ASC) AS RowNum,
			PVT.MaxAllowed
	FROM	@tmpPrograms P,
			ProgramVehicleType PVT
	WHERE   P.ProgramID = PVT.ProgramID
	AND		PVT.VehicleTypeID = @vehicleTypeID	
	AND		ISNULL(PVT.IsActive,0) = 1
)

SELECT @maxAllowedVehicles = W.MaxAllowed FROM wProgramVehicleTypes W WHERE RowNum = 1

SELECT @maxAllowedVehicles AS MaxAllowed

 END
 
 GO