IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_Event_For_ServiceRequest_Status_Log]') AND type in (N'P', N'PC'))
BEGIN
	DROP PROCEDURE [dbo].[dms_Event_For_ServiceRequest_Status_Log]
END
GO
/*
EXEC [dbo].[dms_Event_For_ServiceRequest_Status_Log] 'ServiceCompleted',1656,'sql',null,null,'sql',null
*/
CREATE PROCEDURE [dbo].[dms_Event_For_ServiceRequest_Status_Log](
  @eventName NVARCHAR(100)
, @serviceRequestID INT
, @currentUser NVARCHAR(100)
, @eventData NVARCHAR(MAX) = NULL
, @sessionID NVARCHAR(MAX) = NULL
, @eventSource NVARCHAR(255) = NULL
, @poID INT = NULL
)
AS
BEGIN
	
	DECLARE @serviceRequestEntityID INT = NULL,
			@purchaseOrderEntityID INT = NULL,
			@programEntityID INT = NULL,
			@clientEntityID INT = NULL,
			@memberEntityID INT = NULL,
			@programID INT = NULL,
			@clientID INT = NULL,
			@logEvent BIT = 0,
			@eventLogID BIGINT = NULL
	
	--SELECT * FROM [Entity]
	SET @serviceRequestEntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
	SET @purchaseOrderEntityID = (SELECT ID FROM Entity WHERE Name = 'PurchaseOrder')
	SET @programEntityID = (SELECT ID FROM Entity WHERE Name = 'Program')
	SET @clientEntityID = (SELECT ID FROM Entity WHERE Name = 'Client')
	SET @memberEntityID = (SELECT ID FROM Entity WHERE Name = 'Member')

	SELECT 
			@clientID = P.ClientID,
			@programID = P.ID
	FROM	Program P WITH (NOLOCK) 	
	JOIN	[Case] C WITH (NOLOCK) ON C.ProgramID = P.ID
	JOIN	ServiceRequest SR WITH(NOLOCK) ON SR.CaseID = C.ID
	WHERE	SR.ID = @serviceRequestID

	IF @eventName = 'SubmittedForDispatch'
	BEGIN
		/*	When an SR is saved with Status = 'Submitted' and Next Action = 'Dispatch'; 
			AND the event 'Submitted For Dispatch' has not already been logged in the EventLog for the SR.
		*/
		IF EXISTS (	SELECT	* 
					FROM	ServiceRequest SR WITH (NOLOCK) 
					JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID
					JOIN	NextAction NA WITH (NOLOCK) ON SR.NextActionID = NA.ID
					WHERE	NA.Name = 'Dispatch'
					AND		SR.ID = @serviceRequestID
					)
					AND
			NOT EXISTS (
					SELECT	*
					FROM	EventLog EL WITH (NOLOCK) 
					JOIN	[Event] EVT WITH (NOLOCK) ON EL.EventID = EVT.ID
					JOIN	EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID
					WHERE	ELL.RecordID = @serviceRequestID
					AND		ELL.EntityID = @serviceRequestEntityID
					AND		EVT.Name = @eventName
					)
		BEGIN
			SET @logEvent = 1
		END


	END

	ELSE IF @eventName = 'DispatchInProcess'
	BEGIN
		/*	SR is opened for edit 
			AND the event 'Submitted for Dispatch' exists in the EventLog for the SR 
			AND the event 'DispatchInProcess' does not exist in the EventLog for the SR. 
		*/
		IF EXISTS (	SELECT	*
					FROM	EventLog EL WITH (NOLOCK) 
					JOIN	[Event] EVT WITH (NOLOCK) ON EL.EventID = EVT.ID
					JOIN	EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID
					WHERE	ELL.RecordID = @serviceRequestID
					AND		ELL.EntityID = @serviceRequestEntityID
					AND		EVT.Name = 'SubmittedForDispatch'
					)
					AND
			NOT EXISTS (
					SELECT	*
					FROM	EventLog EL WITH (NOLOCK) 
					JOIN	[Event] EVT WITH (NOLOCK) ON EL.EventID = EVT.ID
					JOIN	EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID
					WHERE	ELL.RecordID = @serviceRequestID
					AND		ELL.EntityID = @serviceRequestEntityID
					AND		EVT.Name = @eventName
					)
		BEGIN
			SET @logEvent = 1
		END

	END

	ELSE IF @eventName = 'Dispatched'
	BEGIN
		/*	PurchaseOrder is assigned a PurchaseOrderNumber and the IssueDate is set */
		SET @logEvent = 1

	END
	ELSE IF @eventName = 'ServiceCancelled'
	BEGIN
		/*	PurchaseOrder is assigned a PurchaseOrderNumber and the IssueDate is set */
		SET @logEvent = 1

	END
	ELSE IF @eventName = 'ServiceArrived'
	BEGIN
		/*	When ClosedLoopStatus on the SR is set to 'Service Arrived'
			AND the event ServiceArrived  does not exist in the EventLog for the SR.
		*/
		IF EXISTS (	SELECT	* 
					FROM	ServiceRequest SR WITH (NOLOCK) 
					JOIN	ClosedLoopStatus CS WITH (NOLOCK) ON SR.ClosedLoopStatusID = CS.ID					
					WHERE	CS.Name = 'ServiceArrived'					
					AND		SR.ID = @serviceRequestID
					)
					AND
			NOT EXISTS (
					SELECT	*
					FROM	EventLog EL WITH (NOLOCK) 
					JOIN	[Event] EVT WITH (NOLOCK) ON EL.EventID = EVT.ID
					JOIN	EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID
					WHERE	ELL.RecordID = @serviceRequestID
					AND		ELL.EntityID = @serviceRequestEntityID
					AND		EVT.Name = @eventName
					)
		BEGIN
			SET @logEvent = 1
		END

	END
	ELSE IF @eventName = 'ServiceCompleted'
	BEGIN
		/*	When ServiceRequestStatus is set to Complete
			AND the event ServiceCompleted  does not exist in the EventLog for the SR
		*/
		IF EXISTS (	SELECT	* 
					FROM	ServiceRequest SR WITH (NOLOCK) 
					JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID					
					WHERE	SRS.Name = 'Complete'					
					AND		SR.ID = @serviceRequestID
					)
					AND
			NOT EXISTS (
					SELECT	*
					FROM	EventLog EL WITH (NOLOCK) 
					JOIN	[Event] EVT WITH (NOLOCK) ON EL.EventID = EVT.ID
					JOIN	EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID
					WHERE	ELL.RecordID = @serviceRequestID
					AND		ELL.EntityID = @serviceRequestEntityID
					AND		EVT.Name = @eventName
					)
		BEGIN
			SET @logEvent = 1
		END
	END

	IF @logEvent = 1
	BEGIN
		PRINT 'Logging an event'
		INSERT INTO EventLog (	EventID,
									SessionID,
									Source,
									[Description],
									Data,
									NotificationQueueDate,
									CreateDate,
									CreateBy)
			SELECT	(SELECT ID FROM [Event] WHERE Name = @eventName),
					@sessionID,
					@eventSource,
					(SELECT Description FROM [Event] WHERE Name = @eventName),
					@eventData,
					NULL,
					GETDATE(),
					@currentUser
		SET @eventLogID = SCOPE_IDENTITY()

		--Create a link record.
		INSERT INTO EventLogLink (EventLogID, EntityID,RecordID)
		SELECT @eventLogID, @serviceRequestEntityID, @serviceRequestID

		IF  @eventName = 'Dispatched' AND @poID  IS NOT NULL
		BEGIN
			INSERT INTO EventLogLink (EventLogID, EntityID,RecordID)
			SELECT @eventLogID, @purchaseOrderEntityID, @poID
		END
		IF @eventName IN ('SubmittedForDispatch', 'Dispatched')
		BEGIN
			IF @programID IS NOT NULL
			BEGIN
				INSERT INTO EventLogLink (EventLogID, EntityID,RecordID)
				SELECT @eventLogID, @programEntityID, @programID
			END
			IF @clientID IS NOT NULL
			BEGIN
				INSERT INTO EventLogLink (EventLogID, EntityID,RecordID)
				SELECT @eventLogID, @clientEntityID, @clientID
			END
		END

		/*
			If eventname is ServiceCompleted, do the following:
			a.	Member belongs to a client/program that gets surveys
				i.	ProgramConfiguration where Name=�SurveyGroup� and IsActive=1?
			b.	Service request is set to Complete
			c.	Service Request resulted in a PO � service was delivered
			d.	Member has an email address
				i.	Case.ContactEmail 
			e.	Member has agreed to a survey
				i.	Case.ReasonID IS NULL
		*/
		IF @eventName = 'ServiceCompleted'
		BEGIN
			DECLARE @programConfig TABLE (
											Name NVARCHAR(50) NULL,
											Value NVARCHAR(MAX) NULL,
											ControlType NVARCHAR(100) NULL,
											DataType NVARCHAR(100) NULL,
											Sequence INT NULL
											)
			DECLARE @isProgramConfiguredForSurvey BIT = 0

			INSERT INTO @programConfig
			EXEC dms_programconfiguration_for_program_get @programID, 'Application'
			
			IF EXISTS (SELECT * FROM @programConfig WHERE Name = 'IsSurveyEnabled' AND Value = 'Yes')
			BEGIN
				SET @isProgramConfiguredForSurvey = 1
			END
			-- KB: Comment out for debugging purposes
			IF @isProgramConfiguredForSurvey = 1 
			BEGIN
				IF EXISTS (	SELECT	* 
									FROM	ServiceRequest SR 
									JOIN	[Case] C ON C.ID = SR.CaseID
									WHERE	SR.ID = @serviceRequestID
									AND		C.ContactEmail IS NOT NULL 
									AND		C.ReasonID IS NULL)
				AND EXISTS (
								SELECT	*
								FROM	EventLog EL WITH (NOLOCK) 
								JOIN	[Event] EVT WITH (NOLOCK) ON EL.EventID = EVT.ID
								JOIN	EventLogLink ELL WITH (NOLOCK) ON EL.ID = ELL.EventLogID
								WHERE	ELL.RecordID = @serviceRequestID
								AND		ELL.EntityID = @serviceRequestEntityID
								AND		EVT.Name = 'ServiceArrived'
							)
				BEGIN
				
					DECLARE @eventSendSurveyID INT = NULL,
							@eventLogIDForSendSurvey INT = NULL,
							@memberEmail NVARCHAR(100) = NULL,
							@contactLogIDForSendSurvey INT = NULL,
							@memberID INT = NULL,
							@purchaseOrderID INT = NULL

					SET @eventSendSurveyID = (SELECT ID FROM Event WHERE Name = 'SendSurvey')

					SELECT	@memberEmail = C.ContactEmail,
							@memberID = C.MemberID
					FROM	[Case] C 
					JOIN	ServiceRequest SR ON SR.CaseID = C.ID 
					WHERE	SR.ID = @serviceRequestID

					SET @purchaseOrderID = (SELECT TOP 1 ID FROM PurchaseOrder WHERE ServiceRequestID = @serviceRequestID AND PurchaseOrderStatusID = (SELECT ID FROM PurchaseOrderStatus WHERE Name = 'Issued'))
				
					IF @eventSendSurveyID IS NOT NULL
					BEGIN
					
						-- Insert EventLog Records
						INSERT INTO EventLog (
												EventID
												, SessionID
												, Source
												, [Description]
												, Data
												, NotificationQueueDate
												, CreateDate
												, CreateBy
												)
						SELECT	@eventSendSurveyID,
								@sessionID,
								@eventSource,
								'Send Survey',							
								'<EventDetail><Email>' + @memberEmail + '</Email></EventDetail>',
								NULL,
								GETDATE(),
								@currentUser

						SET @eventLogIDForSendSurvey = SCOPE_IDENTITY()

						INSERT INTO EventLogLink (	EventLogID,
													EntityID,
													RecordID
												 )
						SELECT	@eventLogIDForSendSurvey,
								@serviceRequestEntityID,
								@serviceRequestID

						UNION ALL

						SELECT	@eventLogIDForSendSurvey,
								@purchaseOrderEntityID,
								@purchaseOrderID
						WHERE	@purchaseOrderID IS NOT NULL

						-- Insert Contact Log records
						INSERT INTO ContactLog (	ContactCategoryID,
													ContactTypeID,
													ContactMethodID,
													ContactSourceID,
													Email,
													Direction,
													[Description],
													CreateDate,
													CreateBy
												)
						SELECT	(SELECT ID FROM ContactCategory WHERE Name = 'ContactCustomer'),
								(SELECT ID FROM ContactType WHERE Name = 'System'),
								(SELECT ID FROM ContactMethod WHERE Name = 'Email'),
								(SELECT ID FROM ContactSource WHERE Name = 'ServiceRequest' AND ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ContactCustomer')),
								@memberEmail,
								'Outbound',
								'Send Survey Request',
								GETDATE(),
								@currentUser

						SET @contactLogIDForSendSurvey = SCOPE_IDENTITY()

						INSERT INTO ContactLogLink (ContactLogID,
													EntityID,
													RecordID
													)
						SELECT	@contactLogIDForSendSurvey,
								@serviceRequestEntityID,
								@serviceRequestID
						UNION ALL
						SELECT	@contactLogIDForSendSurvey,
								@memberEntityID,
								@memberID

						-- ContactLogAction
						INSERT INTO ContactLogAction (	ContactActionID,
														ContactLogID,
														CreateDate,
														CreateBy
													)
						SELECT (SELECT ID FROM ContactAction WHERE Name = 'Pending' AND ContactCategoryID = (SELECT ID FROM ContactCategory WHERE Name = 'ContactCustomer')),
								@contactLogIDForSendSurvey,
								GETDATE(),
								@currentUser

					END
				END
			END
		END
	
	END
END
GO
