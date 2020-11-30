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

GO

IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_Client_OpenPeriodProcess_EventLogs]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_Client_OpenPeriodProcess_EventLogs] 
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
CREATE PROC dms_Client_OpenPeriodProcess_EventLogs(@userName NVARCHAR(100),
												   @sessionID NVARCHAR(MAX),
												   @pageReference NVARCHAR(MAX),
												   @billingScheduleIDList NVARCHAR(MAX),
												   @billingDefinitionInvoiceIDList NVARCHAR(MAX))
AS
BEGIN
		
				DECLARE @BillingScheduleList AS TABLE(Serial INT IDENTITY(1,1), BillingScheduleID INT NULL)
				DECLARE @BillingDefinitionList AS TABLE(Serial INT IDENTITY(1,1),BillingDefinitionInvoiceID INT NULL)

				INSERT INTO @BillingScheduleList(BillingScheduleID)			   SELECT DISTINCT item from dbo.fnSplitString(@billingScheduleIDList,',')
				INSERT INTO @BillingDefinitionList(BillingDefinitionInvoiceID) SELECT item from dbo.fnSplitString(@billingDefinitionInvoiceIDList,',')
		
				DECLARE @eventLogID AS INT
				DECLARE @openBillingScheduleStatus AS INT
				DECLARE @scheduleID AS INT
				DECLARE @billingDefinitionID AS INT
				DECLARE @invoiceEntityID AS INT
				DECLARE @TotalRows AS INT
				DECLARE @ProcessingCounter AS INT = 1
				SELECT  @TotalRows = MAX(Serial) FROM @BillingScheduleList
				DECLARE @entityID AS INT 
				DECLARE @eventID AS INT
				SELECT  @entityID = ID FROM Entity WHERE Name = 'BillingSchedule'
				SELECT  @invoiceEntityID = ID FROM Entity WHERE Name = 'BillingInvoice'
				SELECT  @eventID =  ID FROM Event WHERE Name = 'OpenPeriod'
				SET @openBillingScheduleStatus = (SELECT ID From BillingScheduleStatus WHERE Name = 'OPEN')
		
				-- Create Event Logs for Billing Schedule ID List
				WHILE @ProcessingCounter <= @TotalRows
		BEGIN
			SET @scheduleID = (SELECT BillingScheduleID FROM @BillingScheduleList WHERE Serial = @ProcessingCounter)
			-- Create Event Logs Reocords
			INSERT INTO EventLog([EventID],				[SessionID],				[Source],			[Description],
								 [Data],				[NotificationQueueDate],	[CreateBy],			[CreateDate]) 
			VALUES				(@eventID,				@sessionID,					@pageReference,		 @scheduleID,
								 NULL,					NULL,						@userName,			GETDATE())
			
			SET @eventLogID = SCOPE_IDENTITY()
			-- CREATE Link Records
			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) VALUES(@eventLogID,@entityID,@scheduleID)
			

			-- CREATE LINK RECORDS FOR THE RECENTLY GENEREATED BillingInvoices.
			;WITH wGeneratedBillingInvoices
			AS
			(
				SELECT	ROW_NUMBER () OVER ( PARTITION BY BillingScheduleID, BillingDefinitionInvoiceID ORDER BY CreateDate DESC) AS RowNumber,
						ID AS BillingInvoiceID
				FROM	BillingInvoice BI WITH (NOLOCK)
				WHERE	BillingScheduleID = @scheduleID
			)

			INSERT INTO EventLogLink(EventLogID,EntityID,RecordID) 
			SELECT	@eventLogID,@invoiceEntityID,W.BillingInvoiceID FROM wGeneratedBillingInvoices W WHERE W.RowNumber = 1


			UPDATE	BillingSchedule
			SET		ScheduleStatusID = @openBillingScheduleStatus
			WHERE	ID = @scheduleID


			SET @ProcessingCounter = @ProcessingCounter + 1
		END
END

GO