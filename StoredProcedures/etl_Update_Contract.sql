IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_Contract]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_Contract]
GO

CREATE PROCEDURE [dbo].[etl_Update_Contract] 
	@BatchID int
AS
BEGIN

	SET NOCOUNT ON

	BEGIN TRANSACTION
	
	/** Update Existing Contracts (Deactivate) **/
	UPDATE [Contract]
	SET 
		[EndDate] = staging.[EndDate]
		,[IsActive] = staging.[IsActive]
		,[ModifyDate] = staging.DateAdded
		,[ModifyBy] = 'System'
  	FROM dbo.[etl_Staging_Contract] staging
  	JOIN dbo.[Contract] [Contract]
  		ON staging.ContractID = [Contract].ID --and [Contract].StartDate = staging.StartDate
  	WHERE staging.[BatchID] = @BatchID
  	AND staging.[Operation] = 'U'
  	AND staging.[ProcessFlag] <> 'Y';

  	
	/** Add New Contracts **/
	INSERT INTO dbo.[Contract]
		([VendorID]
		,[StartDate]
		,[EndDate]
		,[IsActive]
		,[CreateDate]
		,[CreateBy])
	SELECT 
		[VendorID]
		,[StartDate]
		,[EndDate]
		,[IsActive]
		,[DateAdded]
		,'System'
	FROM dbo.[etl_Staging_Contract] staging
	WHERE staging.[BatchID] = @BatchID
	AND staging.Operation = 'I'
	AND staging.[ProcessFlag] <> 'Y'
	AND NOT EXISTS (
		SELECT *
		FROM dbo.[Contract] [Contract]
		WHERE [Contract].VendorID = staging.VendorID
		AND [Contract].StartDate <> staging.StartDate
		AND [Contract].IsActive = 'TRUE')
	
	/** Add Product Rates for New Contracts (just added above) **/
	INSERT INTO dbo.[ContractProductRate]
		([ContractID]
		,[VendorLocationID]
		,[ProductID]
		,[RateTypeID]
		,[Price]
		,[Quantity]
		,[CreateDate]
		,[CreateBy])
	SELECT 
		[Contract].ID
		,staging.[VendorLocationID]
		,staging.[ProductID]
		,staging.[RateTypeID]
		,staging.[Price]
		,ISNULL(staging.[Quantity],0)
		,staging.[DateAdded]
		,'System'
	FROM dbo.[etl_Staging_ContractProductRate] staging
	JOIN dbo.[Contract] [Contract] 
		ON staging.VendorID = [Contract].VendorID
			AND staging.ContractDate = [Contract].StartDate
			AND [Contract].IsActive = 'TRUE'
	WHERE staging.[BatchID] = @BatchID
	AND staging.Operation = 'I'
	AND staging.[ProcessFlag] <> 'Y'
	AND NOT EXISTS (
		SELECT *
		FROM dbo.ContractProductRate cpr
		WHERE cpr.ContractID = [Contract].ID
		AND cpr.VendorLocationID = staging.[VendorLocationID]
		AND cpr.ProductID = staging.[ProductID]
		AND cpr.RateTypeID = staging.[RateTypeID])

	/* Add Contract Product Rates not already in DMS for existing contracts */
	INSERT INTO dbo.[ContractProductRate]
		([ContractID]
		,[VendorLocationID]
		,[ProductID]
		,[RateTypeID]
		,[Price]
		,[Quantity]
		,[CreateDate]
		,[CreateBy])
	SELECT 
		[Contract].ID
		,staging.[VendorLocationID]
		,staging.[ProductID]
		,staging.[RateTypeID]
		,staging.[Price]
		,ISNULL(staging.[Quantity],0)
		,staging.[DateAdded]
		,'System'
	FROM dbo.[etl_Staging_ContractProductRate] staging
	JOIN dbo.[Contract] [Contract] 
		ON staging.ContractID = [Contract].ID AND [Contract].IsActive = 'TRUE'
	WHERE staging.[BatchID] = @BatchID
	AND staging.Operation = 'I'
	AND staging.[ProcessFlag] <> 'Y'
	AND NOT EXISTS (
		SELECT *
		FROM dbo.ContractProductRate cpr
		WHERE cpr.ContractID = [Contract].ID
		AND cpr.VendorLocationID = staging.[VendorLocationID]
		AND cpr.ProductID = staging.[ProductID]
		AND cpr.RateTypeID = staging.[RateTypeID])

	/* Update rate changes unassociated with a contract change */
	UPDATE ContractProductRate 
	SET [Price] = staging.[Price]
		,[Quantity] = ISNULL(staging.[Quantity],0)
		,[ModifyDate] = staging.DateAdded
		,[ModifyBy] = 'System'
	FROM dbo.[etl_Staging_ContractProductRate] staging
	JOIN dbo.ContractProductRate ContractProductRate
		ON staging.ContractID = ContractProductRate.ContractID
		AND staging.VendorLocationID = ContractProductRate.VendorLocationID
		AND staging.ProductID = ContractProductRate.ProductID
		AND staging.RateTypeID = ContractProductRate.RateTypeID
	WHERE staging.[BatchID] = @BatchID
	AND staging.Operation = 'U'
	AND staging.[ProcessFlag] <> 'Y'

	COMMIT TRANSACTION

END
GO

