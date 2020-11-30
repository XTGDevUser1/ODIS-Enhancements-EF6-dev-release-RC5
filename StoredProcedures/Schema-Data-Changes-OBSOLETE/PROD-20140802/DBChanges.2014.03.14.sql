-- TFS:196 - Rename columns in EventSubscription
sp_RENAME 'EventSubscription.[RecipientTypeID]' , 'NotificationRecipientTypeID', 'COLUMN'
GO
sp_RENAME 'EventSubscription.[Recipient]' , 'NotificationRecipient', 'COLUMN'
GO

-- Event - ManualNotification
IF NOT EXISTS ( SELECT * FROM Event WHERE Name = 'ManualNotification')
BEGIN
	INSERT INTO Event ( EventTypeID, EventCategoryID, Name, Description,IsShownOnScreen, IsActive, CreateBy, CreateDate)
	SELECT	(SELECT ID FROM EventType WHERE Name = 'User'),
			(SELECT ID FROM EventCategory WHERE Name = 'ServiceRequest'),
			'ManualNotification',
			'Manual Notification',
			0,
			1,
			'system',
			GETDATE()


END

GO

-- Template for ManualNotification
IF NOT EXISTS ( SELECT * FROM Template WHERE Name = 'ManualNotification' )
BEGIN
	INSERT INTO Template (Name, Subject, Body, IsActive)
	SELECT 'ManualNotification',
			NULL,
			'Message from ${SentFrom} : ${MessageText}',
			1
END
GO

-- EventTemplate - ManualNotification
IF NOT EXISTS ( SELECT * FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'ManualNotification') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'ManualNotification')
				)
BEGIN
	INSERT INTO EventTemplate (EventID,TemplateID, IsDefault)
	SELECT	(SELECT ID FROM Event WHERE Name = 'ManualNotification'),
			(SELECT ID FROM Template WHERE Name = 'ManualNotification'),
			1

END
GO

-- EventSubscription : Manual Notification

IF NOT EXISTS ( SELECT * FROM EventSubscription 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'ManualNotification') 				
				)
BEGIN
	INSERT INTO EventSubscription ( EventID,
									EventTypeID,
									EventCategoryID, 
									ContactMethodID, 
									EventTemplateID, 
									IsActive, 
									CreateDate, 
									CreateBy, 
									NotificationRecipientTypeID, 
									NotificationRecipient)
	SELECT	(SELECT ID FROM Event WHERE Name = 'ManualNotification'),
			NULL,
			NULL,
			(SELECT ID FROM ContactMethod WHERE Name = 'DesktopNotification'),
			(SELECT ID FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'ManualNotification') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'ManualNotification') 
			),
			1,
			GETDATE(),
			'system',
			(SELECT ID FROM NotificationRecipientType WHERE Name = 'CurrentUser'),
			NULL

END
GO