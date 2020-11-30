IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_GetProgramVehicleTypeDetails]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_GetProgramVehicleTypeDetails] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_GetProgramVehicleTypeDetails]( 
 @programVehicleTypeId INT
 )
 AS
 BEGIN
	SET FMTONLY OFF
 	SET NOCOUNT ON
 	
   SELECT ID,
          VehicleTypeID,
          MaxAllowed,
          IsActive
   FROM ProgramVehicleType
   WHERE ID=@programVehicleTypeId
 END