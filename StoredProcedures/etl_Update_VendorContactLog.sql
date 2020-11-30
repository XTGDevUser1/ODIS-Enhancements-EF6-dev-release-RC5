IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[etl_Update_VendorContactLog]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[etl_Update_VendorContactLog]
GO

CREATE PROCEDURE [dbo].[etl_Update_VendorContactLog] 
	@BatchID int
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION	
		
		DECLARE @ProcessDate datetime
		SET @ProcessDate = GETDATE()

		UPDATE ContactLog
			SET 
			DataTransferDate = @ProcessDate 
		FROM dbo.etl_Staging_CFDSVNLOG Staging
		JOIN dbo.ContactLog ContactLog ON staging.ContactLogID = ContactLog.ID
		WHERE Staging.BatchID = @BatchID
		AND staging.ProcessFlag = 'Y'
		AND ContactLog.DataTransferDate IS NULL
		
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

