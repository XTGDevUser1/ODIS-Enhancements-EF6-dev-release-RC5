	  
IF EXISTS (SELECT * FROM dbo.sysobjects 
	WHERE id = object_id(N'[dbo].[dms_service_request_status_update]')   		AND type in (N'P', N'PC')) 
BEGIN
	DROP PROCEDURE [dbo].[dms_service_request_status_update]
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 


CREATE PROC [dbo].[dms_service_request_status_update]
AS
BEGIN
	   
	DECLARE @AppConfig AS INT  
	DECLARE @completeServiceRequestStatusID INT
	DECLARE @idx INT = 1
	DECLARE @maxRows INT = 0
	DECLARE @eventLogID BIGINT = 0
	DECLARE @serviceRequestEntityID INT = 0
	DECLARE @serviceRequestID INT = 0
	DECLARE @bingKey NVARCHAR(MAX)
	SELECT @bingKey = Value FROM ApplicationConfiguration WHERE Name = 'BING_API_KEY'
	   
	SET @completeServiceRequestStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Complete')
	SET @serviceRequestEntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')

	SET @AppConfig = (	Select ISNULL(AC.Value,48) From ApplicationConfiguration AC 
						JOIN ApplicationConfigurationType ACT on ACT.ID = AC.ApplicationConfigurationTypeID
						JOIN ApplicationConfigurationCategory ACC on ACC.ID = AC.ApplicationConfigurationCategoryID
						Where AC.Name='AgingServiceRequestHours'
						AND ACT.Name = 'WindowsService'
						AND ACC.Name = 'DispatchProcessingService')

	CREATE TABLE #wSRsToBeUpdated	   
	(
		RowNum INT NOT NULL IDENTITY(1,1),
		ServiceRequestID INT NOT NULL
	)

	;with wResult AS
	(
		SELECT	SR.ID AS ServiceRequestID,
				SR.ServiceRequestStatusID,
				DATEADD(hh,@AppConfig,coalesce(SR.NextActionScheduledDate, SR.CreateDate)) AS 'NextActionCreateDate', 
				SR.CreateDate, 
				SR.NextActionScheduledDate
		FROM	ServiceRequest SR
		WHERE	SR.ServiceRequestStatusID IN(SELECT ID FROM ServiceRequestStatus WHERE Name IN('Entry','Submitted'))
		AND		DATEADD(hh,@AppConfig,COALESCE(SR.NextActionScheduledDate, SR.CreateDate))<= GETDATE()
	)

	/* OLD LOGIC
	UPDATE wResult
	SET ServiceRequestStatusID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Complete')
	*/

	INSERT INTO #wSRsToBeUpdated
	SELECT	W.ServiceRequestID
	FROM		wResult W

	UPDATE	ServiceRequest
	SET		ServiceRequestStatusID = @completeServiceRequestStatusID
	WHERE	ID IN (SELECT ServiceRequestID FROM #wSRsToBeUpdated)

	/* TFS: 1352 - Dispatch Processing Service - Post event when SR set to Complete */
	SET @maxRows = (SELECT MAX(RowNum) FROM #wSRsToBeUpdated)

	WHILE (@idx <= @maxRows)
	BEGIN
		SET @serviceRequestID = (SELECT ServiceRequestID FROM #wSRsToBeUpdated WHERE RowNum = @idx)
		INSERT INTO EventLog (	EventID,
								SessionID,
								Source,
								[Description],
								Data,
								NotificationQueueDate,
								CreateDate,
								CreateBy)
		SELECT	(SELECT ID FROM [Event] WHERE Name = 'ServiceCompleted'),
				NULL,
				'Dispatch Processing Service',
				(SELECT Description FROM [Event] WHERE Name = 'ServiceCompleted'),
				NULL,
				NULL,
				GETDATE(),
				'system'
		SET @eventLogID = SCOPE_IDENTITY()

		--Create a link record.
		INSERT INTO EventLogLink (EventLogID, EntityID,RecordID)
		SELECT @eventLogID, @serviceRequestEntityID, @serviceRequestID

		SET @idx = @idx + 1

		UPDATE  ServiceRequest
		SET		MapSnapshot = [dbo].[fnGenerateMapSnapshot](ServiceLocationLatitude,
								ServiceLocationLongitude,
								DestinationLatitude,
								DestinationLongitude,
								@bingKey
								)
		WHERE	ID = @serviceRequestID
		AND		ServiceLocationLatitude is not null 
		AND		ServiceLocationLongitude is not null		

	END

	DROP TABLE #wSRsToBeUpdated

END