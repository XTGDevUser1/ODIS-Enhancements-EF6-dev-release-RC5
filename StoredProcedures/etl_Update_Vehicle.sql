IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_Vehicle]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_Vehicle]
GO

CREATE PROCEDURE [dbo].[etl_Update_Vehicle] 
	@BatchID int
	,@ProcessGroup int
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION	
		
		/* Insert new Vehicle entries */
		INSERT INTO [DMS].[dbo].[Vehicle] (
			[VehicleCategoryID]
			,[RVTypeID]
			,[VehicleTypeID]
			,[MembershipID]
			,[MemberID]
			,[VIN]
			,[Year]
			,[Make]
			,[MakeOther]
			,[Model]
			,[ModelOther]
			,[LicenseNumber]
			,[LicenseState]
			,[Description]
			,[Color]
			,[Length]
			,[Height]
			,[TireSize]
			,[TireBrand]
			,[TireBrandOther]
			,[TrailerTypeID]
			,[TrailerTypeOther]
			,[SerialNumber]
			,[NumberofAxles]
			,[HitchTypeID]
			,[HitchTypeOther]
			,[TrailerBallSize]
			,[TrailerBallSizeOther]
			,[Transmission]
			,[Engine]
			,[GVWR]
			,[Chassis]
			,[PurchaseDate]
			,[WarrantyStartDate]
			,[StartMileage]
			,[EndMileage]
			,[MileageUOM]
			,[IsFirstOwner]
			,[IsSportUtilityRV]
			,[Source]
			,[IsActive]
			,[CreateBatchID]
			,[CreateDate]
			,[CreateBy])
		SELECT 
			staging.[VehicleCategoryID]
			,staging.[RVTypeID]
			,staging.[VehicleTypeID]
			,staging.[MembershipID]
			,NULL
			,staging.[VIN]
			,staging.[Year]
			,CASE WHEN ISNULL(staging.[MakeOther],'') <> '' THEN 'Other' ELSE NULL END AS [Make]
			,CASE WHEN ISNULL(staging.[MakeOther],'') <> '' THEN staging.[MakeOther] ELSE NULL END AS [MakeOther]
			,CASE WHEN ISNULL(staging.[ModelOther],'') <> '' THEN 'Other' ELSE NULL END AS [Model]
			,CASE WHEN ISNULL(staging.[ModelOther],'') <> '' THEN staging.[ModelOther] ELSE NULL END AS [ModelOther]
			,NULL
			,NULL
			,NULL
			,NULL
			,staging.[Length]
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,staging.[Transmission]
			,staging.[Engine]
			,staging.[GVWR]
			,staging.[Chassis]
			,staging.[PurchaseDate]
			,staging.[WarrantyStartDate]
			,staging.[StartMileage]
			,staging.[EndMileage]
			,staging.[MileageUOM]
			,staging.[IsFirstOwner]
			,NULL
			,NULL
			,'TRUE'
			,staging.[BatchID]
			,staging.[DateAdded]
			,'System'	
		FROM dbo.[etl_Staging_Vehicle] staging
  		WHERE staging.[BatchID] = @BatchID
		AND staging.ProcessGroup = @ProcessGroup
  		AND staging.[Operation] = 'I'
  		AND staging.[ProcessFlag] <> 'Y'
  		AND NOT EXISTS (
  			SELECT *
  			FROM dbo.Vehicle v
  			WHERE v.MembershipID = staging.MembershipID
  			AND v.VIN = staging.VIN)


		/** Update Vehicle Records **/
		UPDATE Vehicle 
		SET 
			[VehicleCategoryID] = staging.[VehicleCategoryID]
			,[RVTypeID] = staging.[RVTypeID]
			,[VehicleTypeID] = staging.[VehicleTypeID]
			,[MembershipID] = staging.[MembershipID]
			,[VIN] = staging.[VIN]
			,[Year] = staging.[Year]
			,[Make] = CASE WHEN ISNULL(staging.[MakeOther],'') <> '' THEN 'Other' ELSE NULL END 
			,[MakeOther] = CASE WHEN ISNULL(staging.[MakeOther],'') <> '' THEN staging.[MakeOther] ELSE NULL END
			,[Model] = CASE WHEN ISNULL(staging.[ModelOther],'') <> '' THEN 'Other' ELSE NULL END 
			,[ModelOther] = CASE WHEN ISNULL(staging.[ModelOther],'') <> '' THEN staging.[ModelOther] ELSE NULL END
			,[Length] = staging.[Length]
			,[Transmission] = staging.[Transmission]
			,[Engine] = staging.[Engine]
			,[GVWR] = staging.[GVWR]
			,[Chassis] = staging.[Chassis]
			,[PurchaseDate] = staging.[PurchaseDate]
			,[WarrantyStartDate] = staging.[WarrantyStartDate]
			,[StartMileage] = staging.[StartMileage]
			,[EndMileage] = staging.[EndMileage]
			,[MileageUOM] = staging.[MileageUOM]
			,[IsFirstOwner] = staging.[IsFirstOwner]		
			,[ModifyBatchID] = staging.[BatchID]
			,[ModifyDate] = staging.[DateAdded]
			,[ModifyBy] = 'System'	
		FROM dbo.[etl_Staging_Vehicle] staging
		JOIN dbo.Vehicle Vehicle
			ON staging.VehicleID = Vehicle.ID
		WHERE staging.[BatchID] = @BatchID
 		AND staging.ProcessGroup = @ProcessGroup
 		AND staging.[Operation] = 'U'
  		AND staging.[ProcessFlag] <> 'Y'


		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN 1;
	END CATCH

	RETURN 0;
END
GO

