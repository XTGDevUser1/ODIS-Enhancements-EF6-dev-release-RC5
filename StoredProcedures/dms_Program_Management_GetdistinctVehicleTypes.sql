IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetdistinctVehicleTypes]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetdistinctVehicleTypes] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
  --EXEC dms_Program_Management_GetdistinctVehicleTypes 4,8
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetdistinctVehicleTypes]( 
   @programId INT=NULL,
   @programVehicleTypeId INT=NULL
  
 ) 
 AS 
 BEGIN 
 
	SET FMTONLY OFF;
 	SET NOCOUNT ON
 	
 	DECLARE @tmpVehicleType TABLE
	(
	ID INT NULL,
	Descipriton nvarchar(255) null,
	Name nvarchar(50) null
	)
	
	IF @programVehicleTypeId IS NULL
	BEGIN
		INSERT INTO @tmpVehicleType
		SELECT ID,[Description],Name 
		FROM VehicleType
		WHERE ID not in(SELECT DISTINCT VehicleTypeID from ProgramVehicleType WHERE ProgramID=@programId)
	END
	ELSE BEGIN
		INSERT INTO @tmpVehicleType
		
		SELECT ID,[Description],Name 
		FROM VehicleType
		WHERE ID not in(SELECT DISTINCT VehicleTypeID from ProgramVehicleType WHERE ProgramID=@programId)
		
		UNION 
		
		SELECT ID,[Description],Name FROM VehicleType
		WHERE ID=(SELECT VehicleTypeID FROM ProgramVehicleType where ID=@programVehicleTypeId)
	END
	
	SELECT * FROM @tmpVehicleType
	
 END