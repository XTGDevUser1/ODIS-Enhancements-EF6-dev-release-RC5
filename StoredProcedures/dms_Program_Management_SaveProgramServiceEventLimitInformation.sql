IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Program_Management_SaveServiceEventLimitInformation]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Program_Management_SaveServiceEventLimitInformation] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  
 CREATE PROCEDURE [dbo].[dms_Program_Management_SaveServiceEventLimitInformation]( 
   @id INT = NULL
 , @programID INT = NULL
 , @productCategoryID INT = NULL
 , @productID INT = NULL
 , @vehicleTypeID INT = NULL
 , @vehicleCategoryID INT = NULL
 , @description NVARCHAR(MAX) = NULL
 , @limit INT = NULL
 , @limitDuration INT = NULL
 , @limitDurationUOM NVARCHAR(100) = NULL
 , @storedProcedureName NVARCHAR(100) = NULL
 , @currentUser NVARCHAR(100) = NULL 
 , @isActive BIT = NULL
 )
 AS
 BEGIN
 IF @id > 0 
	 BEGIN
		UPDATE ProgramServiceEventLimit 
		SET ProductCategoryID = @productCategoryID,
			ProductID = @productID,
			VehicleTypeID = @vehicleTypeID,
			VehicleCategoryID = @vehicleCategoryID,
			Description = @description,
			Limit = @limit,
			LimitDuration = @limitDuration,
			LimitDurationUOM=@limitDurationUOM,
			IsActive = @isActive,
			StoredProcedureName= @storedProcedureName
		WHERE ID = @id
	 END
ELSE
	BEGIN
		INSERT INTO ProgramServiceEventLimit (
			ProgramID,
			ProductCategoryID,
			ProductID,
			VehicleTypeID,
			VehicleCategoryID,
			Description,
			Limit,
			LimitDuration,
			LimitDurationUOM,
			StoredProcedureName,
			IsActive,
			CreateBy,
			CreateDate		
		)
		VALUES(
			@programID,
			@productCategoryID,
			@productID,
			@vehicleTypeID,
			@vehicleCategoryID,
			@description,
			@limit,
			@limitDuration,
			@limitDurationUOM,
			@storedProcedureName,
			@isActive,
			@currentUser,
			GETDATE()
		)
	END
END