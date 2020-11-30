/****** Object:  StoredProcedure [dms].[UpdateExecutionLog_Billing]    Script Date: 10/31/2013 16:36:49 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dms].[UpdateExecutionLog_Billing]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dms].[UpdateExecutionLog_Billing]
GO



/****** Object:  StoredProcedure [dms].[UpdateExecutionLog_Billing]    Script Date: 10/31/2013 16:36:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dms].[UpdateExecutionLog_Billing] (
	@LogID int 
	,@Status int -- 1-Success 0-Failure
)
AS
BEGIN

	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION	

		UPDATE [audit].[ExecutionLog]	
		SET EndTime = GETDATE()
			,[Status] = @Status
		WHERE LogID = @LogID
		
		UPDATE [staging_MAS90].[InvoiceRequest]
		SET [Status] = CASE WHEN @Status = 1 THEN 'Y' ELSE 'N' END
		WHERE ETL_Load_ID = @LogID

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		RETURN 1;
	END CATCH

	RETURN 0;
END

GO


