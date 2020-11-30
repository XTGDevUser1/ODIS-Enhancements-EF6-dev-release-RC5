IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveProgramVehicleType]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveProgramVehicleType] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveProgramVehicleType]( 
 @programVehicleId INT,
 @vehicleTypeID INT=NULL,
 @maxAllowed INT=NULL,
 @isActive bit=NULL,
 @isAdd bit,
 @programID int=NULL
 )
 AS
 BEGIN
 
 IF @isAdd=1 
 BEGIN
 
	INSERT INTO ProgramVehicleType(ProgramID,VehicleTypeID,MaxAllowed,IsActive)
	VALUES(@programID,@vehicleTypeID,@maxAllowed,@isActive)
	
 END
 ELSE BEGIN
 
	UPDATE ProgramVehicleType
	SET VehicleTypeID=@vehicleTypeID,
		MaxAllowed=@maxAllowed,
		IsActive=@isActive
	WHERE ID=@programVehicleId
 END
 
 END