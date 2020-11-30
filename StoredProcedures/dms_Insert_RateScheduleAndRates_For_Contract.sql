IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Insert_RateScheduleAndRates_For_Contract]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Insert_RateScheduleAndRates_For_Contract] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Insert_RateScheduleAndRates_For_Contract]  150
CREATE PROCEDURE [dbo].[dms_Insert_RateScheduleAndRates_For_Contract](
	@contractID INT
)
AS
BEGIN

	IF EXISTS(SELECT * FROM [Contract] where ID = @contractID)
	BEGIN

		DECLARE @vendorID INT = NULL
		DECLARE @newlyAddedContractRateScheduleID INT = NULL
		DECLARE @contractCreatedBy NVARCHAR(100) = NULL 
		DECLARE @latestContractRateScheduleID INT = NULL
		DECLARE @latestContractID INT = NULL 
		DECLARE @contractRateScheduleStatusID INT = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active')
		SET		@latestContractRateScheduleID = NULL 
		
		SELECT  @vendorID = C.VendorID,
				@contractCreatedBy = C.CreateBy
		FROM	[Contract] C 
		WHERE	C.ID = @contractID


		SELECT TOP 1	@latestContractID = C.ID,
						@latestContractRateScheduleID = CRS.ID 
		FROM	ContractRateSchedule CRS 
		JOIN	[Contract] C ON C.ID = CRS.ContractID
		WHERE	C.VendorID = @vendorID AND C.ID <> (@contractID)
		AND		ISNULL(C.IsActive,0) = 1
		ORDER BY CRS.StartDate DESC

		-- Update older contracts to be inactive		
		UPDATE	[Contract]
		SET		ContractStatusID = (SELECT ID FROM ContractStatus WHERE Name = 'Inactive')
		WHERE	VendorID = @vendorID
		AND		ID <> @contractID
		
		-- Update older ContractRateSchedules to be inactive
		UPDATE ContractRateSchedule
		SET		ContractRateScheduleStatusID = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Inactive')
		WHERE	ContractID IN 
		(
			SELECT ID FROM [Contract] WHERE VendorID = @vendorID AND ID <> @contractID
		)

		INSERT INTO ContractRateSchedule (
			ContractID,
			ContractRateScheduleStatusID,
			StartDate,
			EndDate,
			SignedDate,
			SignedBy,
			SignedByTitle,
			IsActive,
			CreateDate,
			CreateBy
		)
		-- DECLARE @contractRateScheduleStatusID INT = (SELECT ID FROM ContractRateScheduleStatus WHERE Name = 'Active')
		SELECT TOP 1	C.ID,
						@contractRateScheduleStatusID,
						CONVERT (DATE, GETDATE()) 'Date Part Only',
						NULL,
						C.SignedDate,
						C.SignedBy,
						C.SignedByTitle,
						1,
						GETDATE(),
						C.CreateBy
		FROM [Contract] C where C.ID = @contractID
		SET @newlyAddedContractRateScheduleID = SCOPE_IDENTITY()
			
		-- PRINT 'Newly Added Contract Rate Schedule ID is'
		-- PRINT @newlyAddedContractRateScheduleID

		IF @latestContractRateScheduleID IS NOT NULL
		BEGIN
			INSERT INTO ContractRateScheduleProduct
			(
				ContractRateScheduleID,
				VendorLocationID,
				ProductID,
				RateTypeID,
				Price,
				Quantity,
				CreateDate,
				CreateBy,
				ModifyDate,
				ModifyBy
			)
			SELECT 
				@newlyAddedContractRateScheduleID,
				NULL,
				CRSP.ProductID,
				CRSP.RateTypeID,
				CRSP.Price,
				CRSP.Quantity,
				GETDATE(),
				@contractCreatedBy,
				NULL,
				NULL			 
			FROM ContractRateScheduleProduct CRSP where CRSP.ContractRateScheduleID = @latestContractRateScheduleID

			INSERT INTO ContractRateScheduleProductLog
			(
				ContractRateScheduleID,
				VendorLocationID,
				ProductID,
				RateTypeID,
				OldPrice,
				NewPrice,
				OldQuantity,
				NewQuantity,
				ActivityType,
				CreateDate,
				CreateBy
			)
			SELECT	CRSP.ContractRateScheduleID,
					NULL,
					CRSP.ProductID,
					CRSP.RateTypeID,
					NULL,
					CRSP.Price,
					NULL,
					CRSP.Quantity,
					'Insert',
					GETDATE(),
					CRSP.CreateBy
			FROM ContractRateScheduleProduct CRSP where CRSP.ContractRateScheduleID = @newlyAddedContractRateScheduleID
		END
	END

END
