IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess] 
END 
GO
CREATE PROC [dbo].[dms_Client_OpenPeriodProcess](@billingDefinitionInvoiceID INT,
												 @billingScheduleID INT,
												 @scheduleTypeID INT,
												 @scheduleDateTypeID INT,
												 @scheduleRangeTypeID INT,
												 @userName NVARCHAR(100),
												 @sessionID NVARCHAR(MAX),
												 @pageReference NVARCHAR(MAX))
AS
BEGIN
		BEGIN TRY
		BEGIN TRAN
			
			DECLARE @entityID AS INT 
			DECLARE @eventID AS INT
			DECLARE	@eventDescription AS NVARCHAR(MAX)
			SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingInvoice'
			SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
			SELECT  @eventDescription =  Description FROM Event WHERE Name = 'OpenPeriod'
			
			DECLARE @pInvoiceXML AS NVARCHAR(MAX)
			SET @pInvoiceXML = '<Records><BillingDefinitionInvoiceID>' + CONVERT(NVARCHAR(50),@billingDefinitionInvoiceID) + '</BillingDefinitionInvoiceID></Records>'
			
			EXEC dbo.dms_BillingGenerateInvoices 
				 @pUserName  = @userName,
				 @pScheduleTypeID = @scheduleTypeID,
				 @pScheduleDateTypeID = @scheduleDateTypeID,
				 @pScheduleRangeTypeID = @scheduleRangeTypeID,
				 @pInvoicesXML = @pInvoiceXML
		
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN
		DECLARE @ErrorMessage    NVARCHAR(4000)			
		-- Assign variables to error-handling functions that 
		-- capture information for RAISERROR.
		SELECT  @ErrorMessage = ERROR_MESSAGE();
		RAISERROR(@ErrorMessage,16,1);
	END CATCH
END

