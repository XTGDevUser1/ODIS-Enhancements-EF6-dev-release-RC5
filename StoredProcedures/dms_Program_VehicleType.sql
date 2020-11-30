
 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Vehicle_Type]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Vehicle_Type] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 
 CREATE proc [dbo].[dms_Program_Vehicle_Type](@programID INT)
 AS
 BEGIN
  DECLARE @currentProgram INT
  SET @currentProgram = @programID
  DECLARE @recordCount INT = 0
  
  DECLARE @temp TABLE (VehicleTypeID INT)
  
  WHILE @recordCount = 0 
	  BEGIN
		 INSERT INTO @temp 
		 SELECT DISTINCT VehicleTypeID 
								FROM ProgramVehicleType 
								WHERE ProgramID = @currentProgram
		 SET @recordCount = (SELECT COUNT(*) FROM @temp)
		 IF @recordCount > 0
			 BEGIN
			    BREAK;
			 END
		 ELSE
			 BEGIN
			     DELETE FROM @temp
				 SET @currentProgram  = (SELECT [ParentProgramID] FROM Program WHERE ID = @currentProgram)
				 IF @currentProgram IS NULL
					 BEGIN
						BREAK
					 END
				 ELSE
					 BEGIN
						CONTINUE;
					 END
			 END
	  END				
  
  SELECT * FROM ProgramVehicleType WHERE VehicleTypeID IN(SELECT VehicleTypeID FROM @temp)
  --DROP TABLE @temp
END
GO

