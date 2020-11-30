IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_VendorLocationProduct]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_VendorLocationProduct]
GO

CREATE PROCEDURE [dbo].[etl_Update_VendorLocationProduct] 
	@BatchID int
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRANSACTION;
	
	/** Add New Vendor Location Products **/
	INSERT INTO dbo.[VendorLocationProduct]
		([VendorLocationID]
		,[ProductID]
		,[IsActive]
		,[Rating]
		,[CreateDate]
		,[CreateBy])
	SELECT 
		[VendorLocationID]
		,[ProductID]
		,[IsActive]
		,[Rating]
		,[DateAdded]
		,'System'
  	FROM [dbo].[etl_Staging_VendorLocationProduct] staging
  	WHERE staging.[BatchID] = @BatchID
  	AND staging.Operation = 'I'
  	AND staging.[ProcessFlag] <> 'Y';


	/** Update Existing Vendor Location Products (Deactivate) **/
	UPDATE VendorLocationProduct
	SET 
		[IsActive] = staging.[IsActive],
		[Rating] = staging.Rating,
		[ModifyDate] = staging.[DateAdded],
		[ModifyBy] = 'System'
  	FROM [dbo].[etl_Staging_VendorLocationProduct] staging
  	JOIN dbo.VendorLocationProduct VendorLocationProduct
  		ON staging.VendorLocationID = VendorLocationProduct.VendorLocationID AND
  			staging.ProductID = VendorLocationProduct.ProductID
  	WHERE staging.[BatchID] = @BatchID
  	AND staging.[Operation] = 'U'
  	AND staging.[ProcessFlag] <> 'Y';

	COMMIT TRANSACTION;

END
GO

