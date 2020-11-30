IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveServiceCategoryInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveServiceCategoryInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveServiceCategoryInformation]( 
 @id INT ,
 @programID INT = NULL,
 @productCategoryID INT = NULL,
 @vehicleTypeID INT = NULL,
 @vehicleCategoryID INT = NULL,
 @sequence INT = NULL,
 @isActive BIT = NULL
 )
  AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramProductCategory 
		SET ProductCategoryID = @productCategoryID,
			VehicleCategoryID = @vehicleCategoryID,
			VehicleTypeID = @vehicleTypeID,
			Sequence = @sequence,
			IsActive = @isActive,
			ProgramID = @programID
		WHERE ID = @id
			
	 END
 ELSE
	 BEGIN
		INSERT INTO ProgramProductCategory(
			ProductCategoryID,
			ProgramID,
			VehicleCategoryID,
			VehicleTypeID,
			Sequence,
			IsActive
		)
		VALUES(
			@productCategoryID,
			@programID,
			@vehicleCategoryID,
			@vehicleTypeID,
			@sequence,
			@isActive
		)
	 END
 END