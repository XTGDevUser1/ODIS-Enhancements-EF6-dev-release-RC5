IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[EventSubscriptionRecipients_For_EventLog_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[EventSubscriptionRecipients_For_EventLog_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 

 /*
  EXEC [EventSubscriptionRecipients_For_EventLog_Get] 175814

  */
 CREATE PROCEDURE [dbo].[EventSubscriptionRecipients_For_EventLog_Get]( 
	@eventLogID BIGINT	
 )
 AS
 BEGIN

/*	Implementation Logic:
	For the given EventSubscription, check if there exists one or more EventSubscriptionLink records.
	Case #1: If there are no EventSubscriptionLink records, it falls under "ANY" context. Grab all the EventSubscriptionRecipients.
	Case #2: If there are one or more EventSubscriptionLink records, check if there is a matching eventLogLink record (on RecordID and EntityID) on the current EventLog record.If there exists a match, grab the EventSubscriptionRecipients. Return none, otherwise.
*/

	DECLARE  @tmpEventSubscriptionRecipient AS TABLE(
	[ID] [int] NOT NULL,
	[EventSubscriptionID] [int]  NULL,
	[ContactMethodID] [int] NULL,
	[EventTemplateID] [int] NULL,
	[PersonID] INT NULL,
	[RecipientTypeID] [int] NULL,
	[Recipient] [nvarchar](255) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDoNotDisturb] [bit] NOT NULL
	)

	DECLARE @tmpEventSubscriptions TABLE
	(
		RowNum INT NOT NULL IDENTITY(1,1),
		EventSubscriptionID INT NOT NULL
	)
	DECLARE @tmpRecipientsForEventSubscription TABLE
	(
		RowNum INT NOT NULL,
		[ID] [int] NOT NULL,
		[EventSubscriptionID] [int]  NULL,
		[ContactMethodID] [int] NULL,
		[EventTemplateID] [int] NULL,
		[PersonID] INT NULL,
		[RecipientTypeID] [int] NULL,
		[Recipient] [nvarchar](255) NULL,
		[IsActive] [bit] NOT NULL,
		[IsDoNotDisturb] [bit] NOT NULL
	)


	DECLARE @numOfEventSubscriptionLinks INT = 0,
			@eventSubscriptionID INT = 0,
			@eventSubscriptionRecipientID INT = 0,
			@eventID INT = NULL,
			@eventTypeID INT = NULL,
			@eventCategoryID INT = NULL,
			@maxEventSubscriptions INT = 0,
			@idx INT = 1,
			@eventName NVARCHAR(255) = NULL,
			--@eventData XML = NULL,
			@emailContactMethodID INT,
			@smsContactMethodID INT,
			@desktopNotificationContactMethodID INT,
			@surveyContactMethodID INT,
			@jdx INT = 1,
			@maxEventSubscriptionRecipients INT = 0,
			@sendSurveyEventID INT = NULL,
			@currentUserRecipientTypeID INT = NULL

		
	SELECT @emailContactMethodID = ID FROM ContactMethod WHERE Name = 'Email'
	SELECT @smsContactMethodID = ID FROM ContactMethod WHERE Name = 'Text'
	SELECT @desktopNotificationContactMethodID = ID FROM ContactMethod WHERE Name = 'DesktopNotification'

	SELECT @sendSurveyEventID = ID FROM Event WHERE Name = 'SendSurvey'
	SELECT @currentUserRecipientTypeID = ID FROM NotificationRecipientType WHERE Name = 'CurrentUser'


	SELECT	@eventID			= EL.EventID,
			@eventTypeID		= E.EventTypeID,
			@eventCategoryID	= E.EventCategoryID,
			@eventName			= E.Name
			--@eventData			= EL.Data
	FROM	EventLog EL WITH (NOLOCK) 
	JOIN	[Event] E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	EL.ID = @eventLogID

	DECLARE @cellPhoneTypeID INT = (SELECT TOP 1 ID FROM PhoneType where Name = 'Cell')
	-- Gather relevant EventSubscriptions.
	INSERT INTO @tmpEventSubscriptions
	SELECT  ES.ID
	FROM	EventSubscription ES WITH (NOLOCK) 
	WHERE	(ES.EventID = @eventID ) -- KB: Preventing erroneous notifications OR ES.EventTypeID = @eventTypeID OR ES.EventCategoryID = @eventCategoryID)
	AND		ISNULL(ES.IsActive,0) = 1

	-- DEBUG:SELECT * FROM @tmpEventSubscriptions
	BEGIN

		SET @maxEventSubscriptions = (SELECT MAX(RowNum) FROM @tmpEventSubscriptions)

		WHILE ( @idx <= @maxEventSubscriptions )
		BEGIN		

			SET @eventSubscriptionID = (SELECT EventSubscriptionID FROM @tmpEventSubscriptions WHERE RowNum = @idx)
			SET @numOfEventSubscriptionLinks = (SELECT COUNT(*) FROM EventSubscriptionLink WITH (NOLOCK) WHERE EventSubscriptionID = @eventSubscriptionID)
	
			-- ANY Context
			IF (@numOfEventSubscriptionLinks = 0
					OR
				-- Not "Any" Context. Need to check if all the EventSubscriptionLink records have a related EventLogLink record for the current EventLog.
				(
					SELECT	COUNT(*)
					FROM	
							(SELECT *
							FROM	EventSubscriptionLink ESL WITH (NOLOCK)
							WHERE	EventSubscriptionID = @eventSubscriptionID
							) RESL
					LEFT JOIN
							(
								SELECT *
								FROM	EventLogLink ELL WITH (NOLOCK)
								WHERE	ELL.EventLogID = @eventLogID
							) RELL ON RESL.EntityID = RELL.EntityID AND RESL.RecordID = RELL.RecordID
					WHERE	RELL.ID IS NULL
				) = 0)
			BEGIN

				DELETE FROM @tmpRecipientsForEventSubscription
				
				-- Gather EventSubscriptionRecipients for the current EventSubscription
				INSERT INTO @tmpRecipientsForEventSubscription
				SELECT ROW_NUMBER() OVER (ORDER BY ESR.EventSubscriptionID) AS RowNum,
						ESR.[ID],
						ESR.[EventSubscriptionID],
						ESR.[ContactMethodID],
						ESR.[EventTemplateID],
						ESR.[PersonID],
						ESR.[RecipientTypeID],
						ESR.[Recipient],
						ESR.[IsActive],
						ESR.[IsDoNotDisturb]
				FROM	EventSubscriptionRecipient ESR WITH (NOLOCK)
				WHERE	ESR.EventSubscriptionID = @eventSubscriptionID


				SET @jdx = 1
				SET @maxEventSubscriptionRecipients = (SELECT ISNULL(MAX(RowNum),0) FROM @tmpRecipientsForEventSubscription)

				WHILE (@jdx <= @maxEventSubscriptionRecipients)
				BEGIN

					SET @eventSubscriptionRecipientID = (SELECT ID FROM @tmpRecipientsForEventSubscription WHERE RowNum = @jdx)

					-- If Event = SendSurvey and RecipientType = 'CurrentUser', the recipient is the member email grabbed from the SR -> Case via EventLog and Link
					IF EXISTS ( SELECT * FROM @tmpRecipientsForEventSubscription T JOIN EventSubscription ES ON T.EventSubscriptionID = ES.ID WHERE RowNum = @jdx AND T.RecipientTypeID = @currentUserRecipientTypeID AND ES.EventID = @sendSurveyEventID)
					BEGIN
							DECLARE @memberEmail NVARCHAR(255) = NULL

							SELECT	@memberEmail = C.ContactEmail
							FROM	EventLog EL 
							JOIN	EventLogLink ELL ON EL.ID = ELL.EventLogID
							JOIN	ServiceRequest SR ON ELL.RecordID = SR.ID AND ELL.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
							JOIN	[Case] C ON C.ID = SR.CaseID
							WHERE	EL.ID = @eventLogID

							
							INSERT INTO @tmpEventSubscriptionRecipient (
								ID
								,EventSubscriptionID
								,ContactMethodID
								,EventTemplateID
								,PersonID
								,RecipientTypeID
								,Recipient
								,IsActive
								,IsDoNotDisturb
							)			

							SELECT	T.ID,
									T.EventSubscriptionID,
									T.ContactMethodID,
									T.EventTemplateID,
									T.PersonID,
									T.RecipientTypeID,
									@memberEmail,
									1,
									0
							FROM	@tmpRecipientsForEventSubscription T							
							WHERE	RowNum = @jdx
					END
					-- Call the sp - dms_Recipients_For_DesktopNotification_Get if current contact method = DesktopNotification
					ELSE IF( (SELECT ContactMethodID FROM @tmpRecipientsForEventSubscription WHERE RowNum = @jdx) = @desktopNotificationContactMethodID)
					BEGIN
						INSERT INTO @tmpEventSubscriptionRecipient
						EXEC dms_Recipients_For_DesktopNotification_Get @eventLogID,@eventSubscriptionRecipientID
					END
					ELSE -- Else Grab the email or phone details of user or take the details on the recipient record as is.
					BEGIN						
						;WITH wEmailAndPhoneNumbers
						AS
						(

							SELECT	ESR.EventSubscriptionID AS EventSubscriptionID,
									U.ID,
									M.Email,
									PE.PhoneNumber AS PhoneNumber
							FROM	[User] U WITH (NOLOCK)
							JOIN	[aspnet_Membership] M WITH (NOLOCK) ON U.aspnet_UserID = M.UserId
							JOIN	EventSubscriptionRecipient ESR WITH (NOLOCK) ON ESR.PersonID = U.ID 
							JOIN	NotificationRecipientType NRT WITH(NOLOCK) ON NRT.ID = ESR.RecipientTypeID
							JOIN	Entity ET WITH (NOLOCK) ON ET.Name = NRT.Name
							LEFT JOIN	PhoneEntity PE WITH (NOLOCK) ON PE.EntityID = ET.ID AND PE.PhoneTypeID = @cellPhoneTypeID AND PE.RecordID = ESR.PersonID
							WHERE	ESR.RecipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User')
							AND		ESR.EventSubscriptionID = @eventSubscriptionID
							AND		ESR.ID = @eventSubscriptionRecipientID
					
							UNION ALL
					
							SELECT	ESR.EventSubscriptionID AS EventSubscriptionID,
									U.ID,
									M.Email,
									PE.PhoneNumber AS PhoneNumber
							FROM	[ClientUser] U WITH (NOLOCK)
							JOIN	[aspnet_Membership] M WITH (NOLOCK) ON U.aspnet_UserID = M.UserId
							JOIN	EventSubscriptionRecipient ESR WITH (NOLOCK) ON ESR.PersonID = U.ID 
							JOIN	NotificationRecipientType NRT WITH(NOLOCK) ON NRT.ID = ESR.RecipientTypeID
							JOIN	Entity ET WITH (NOLOCK) ON ET.Name = NRT.Name
							LEFT JOIN	PhoneEntity PE WITH (NOLOCK) ON PE.EntityID = ET.ID AND PE.PhoneTypeID = @cellPhoneTypeID AND PE.RecordID = ESR.PersonID
							WHERE	ESR.RecipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'ClientUser')
							AND		ESR.EventSubscriptionID = @eventSubscriptionID
							AND		ESR.ID = @eventSubscriptionRecipientID

							UNION ALL
					
							SELECT	ESR.EventSubscriptionID AS EventSubscriptionID,
									U.ID,
									M.Email,
									PE.PhoneNumber AS PhoneNumber
							FROM	[VendorUser] U WITH (NOLOCK)
							JOIN	[aspnet_Membership] M WITH (NOLOCK) ON U.aspnet_UserID = M.UserId
							JOIN	EventSubscriptionRecipient ESR WITH (NOLOCK) ON ESR.PersonID = U.ID 
							JOIN	NotificationRecipientType NRT WITH(NOLOCK) ON NRT.ID = ESR.RecipientTypeID
							JOIN	Entity ET WITH (NOLOCK) ON ET.Name = NRT.Name
							LEFT JOIN	PhoneEntity PE WITH (NOLOCK) ON PE.EntityID = ET.ID AND PE.PhoneTypeID = @cellPhoneTypeID AND PE.RecordID = ESR.PersonID
							WHERE	ESR.RecipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'VendorUser')
							AND		ESR.EventSubscriptionID = @eventSubscriptionID											
							AND		ESR.ID = @eventSubscriptionRecipientID									
					
						)
			
						INSERT INTO @tmpEventSubscriptionRecipient (
							ID
							,EventSubscriptionID
							,ContactMethodID
							,EventTemplateID
							,PersonID
							,RecipientTypeID
							,Recipient
							,IsActive
							,IsDoNotDisturb
						)
						SELECT	 ESR.ID
							,ESR.EventSubscriptionID
							,ContactMethodID
							,EventTemplateID
							,PersonID
							,RecipientTypeID
							-- Grab the email / phone number when RecipientTypeID and PersonID
							,CASE WHEN Recipient IS NOT NULL THEN Recipient
									WHEN Recipient IS NULL AND ContactMethodID = @emailContactMethodID THEN P.Email
									WHEN Recipient	IS NULL AND ContactMethodID = @smsContactMethodID THEN P.PhoneNumber
									ELSE NULL END AS Recipient
							,ESR.IsActive
							,0
						FROM	EventSubscriptionRecipient ESR WITH (NOLOCK)
						LEFT JOIN	wEmailAndPhoneNumbers P ON ESR.EventSubscriptionID = P.EventSubscriptionID				
						WHERE	ESR.EventSubscriptionID = @eventSubscriptionID				
						AND		ISNULL(ESR.IsActive,0) = 1
						AND		ESR.ContactMethodID <> @desktopNotificationContactMethodID
						AND		ESR.ID = @eventSubscriptionRecipientID
					END

					SET @jdx = @jdx + 1
						
				END

		
			END

			SET @idx = @idx + 1

		END
	
	END
	SELECT	DISTINCT ID
			,EventSubscriptionID
			,ContactMethodID
			,EventTemplateID
			,PersonID
			,Recipient
			,RecipientTypeID
			,IsActive
			,IsDoNotDisturb
	FROM	@tmpEventSubscriptionRecipient ESR
END

GO

