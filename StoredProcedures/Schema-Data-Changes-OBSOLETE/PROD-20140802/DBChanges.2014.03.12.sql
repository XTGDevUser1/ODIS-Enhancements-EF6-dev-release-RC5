CREATE TABLE [dbo].[DesktopNotifications]
(  [NotificationID] [bigint] IDENTITY(1,1) NOT NULL PRIMARY KEY,
   [UserName] [nvarchar](100) NOT NULL,
   [ConnectionID] [nvarchar](max) NOT NULL,
   [UserAgent] [nvarchar](max) NOT NULL,
   [IsConnected] [bit] NOT NULL)

GO


CREATE TABLE [dbo].[NotificationRecipientType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[IsShownOnManualNotification] BIT NULL,
	[Sequence] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_NotificationRecipientType] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[EventSubscription]
ADD RecipientTypeID INT NULL

ALTER TABLE [dbo].[EventSubscription]
ADD Recipient NVARCHAR(MAX) NULL


ALTER TABLE [dbo].[EventSubscription]  WITH CHECK ADD  CONSTRAINT [FK_EventSubscription_NotificationRecipientType] FOREIGN KEY([RecipientTypeID])
REFERENCES [dbo].[NotificationRecipientType] ([ID])
GO

ALTER TABLE [dbo].[EventSubscription] CHECK CONSTRAINT [FK_EventSubscription_NotificationRecipientType]
GO
-- New Event - SendPOFaxFailed
INSERT INTO Event ( EventTypeID, EventCategoryID, Name, Description,IsShownOnScreen, IsActive, CreateBy, CreateDate)
SELECT	(SELECT ID FROM EventType WHERE Name = 'System'),
		(SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder'),
		'SendPOFaxFailed',
		'Send PO Fax failed',
		0,
		1,
		'system',
		GETDATE()

GO

-- New ContactMethod - DesktopNotification
INSERT INTO ContactMethod ( Name, Description, IsActive)
SELECT 'DesktopNotification', 'Desktop Notification', 1
GO

-- Add a new entity - ContactLogAction
IF NOT EXISTS ( SELECT * FROM Entity WHERE Name = 'ContactLogAction')
BEGIN
	INSERT INTO Entity ( Name, IsAudited)
	SELECT	'ContactLogAction',0
END
GO

-- Template for notification
IF NOT EXISTS ( SELECT * FROM Template WHERE Name = 'PO_Fax_Failure_Notification' )
BEGIN
	INSERT INTO Template (Name, Subject, Body, IsActive)
	SELECT 'PO_Fax_Failure_Notification',
			NULL,
			'PO send failed <br/> Method: Fax <br/> Reason: ${FaxFailureReason} <br/> SR: ${ServiceRequest} <br/> PO: ${PONumber}',
			1
END
GO

-- EventTemplate
IF NOT EXISTS ( SELECT * FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'PO_Fax_Failure_Notification')
				)
BEGIN
	INSERT INTO EventTemplate (EventID,TemplateID, IsDefault)
	SELECT	(SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed'),
			(SELECT ID FROM Template WHERE Name = 'PO_Fax_Failure_Notification'),
			1

END
GO

-- EventSubscription

IF NOT EXISTS ( SELECT * FROM EventSubscription 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed') 				
				)
BEGIN
	INSERT INTO EventSubscription ( EventID, 
									EventCategoryID, 
									ContactMethodID, 
									EventTemplateID, 
									IsActive, 
									CreateDate, 
									CreateBy, 
									RecipientTypeID, 
									Recipient)
	SELECT	(SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed'),
			NULL,
			(SELECT ID FROM ContactMethod WHERE Name = 'DesktopNotification'),
			(SELECT ID FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'SendPOFaxFailed') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'PO_Fax_Failure_Notification') 
			),
			1,
			GETDATE(),
			'system',
			(SELECT ID FROM NotificationRecipientType WHERE Name = 'CurrentUser'),
			NULL

END
GO

	
-- NextAction - ResendPO

IF NOT EXISTS ( SELECT * FROM NextAction WHERE Name = 'ResendPO')
BEGIN
	INSERT INTO NextAction ( Name, Description, IsActive)
	SELECT 'ResendPO', ' Re-send PO', 1
END

