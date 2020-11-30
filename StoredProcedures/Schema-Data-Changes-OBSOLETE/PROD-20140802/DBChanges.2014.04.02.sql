ALTER TABLE ProgramServiceEventLimit ADD StoredProcedureName nvarchar(255) NULL


ALTER TABLE [dbo].[ProgramProduct]  WITH CHECK ADD  CONSTRAINT [FK_ProgramProduct_CurrencyType] FOREIGN KEY([CurrencyTypeID])
REFERENCES [dbo].[CurrencyType] ([ID])
GO

ALTER TABLE [dbo].[ProgramProduct] CHECK CONSTRAINT [FK_ProgramProduct_CurrencyType]
GO

ALTER TABLE ServiceRequest
ADD PrimaryServiceCoverageDescription  NVARCHAR(2000) NULL

ALTER TABLE ServiceRequest
ADD SecondaryServiceCoverageDescription NVARCHAR(2000) NULL

ALTER TABLE ServiceRequest
ADD PrimaryServiceEligiblityMessage NVARCHAR(255) NULL

ALTER TABLE ServiceRequest
ADD SecondaryServiceEligiblityMessage NVARCHAR(255) NULL

ALTER TABLE [dbo].[ServiceRequest]  WITH CHECK ADD  CONSTRAINT [FK_ServiceRequest_CurrencyType] FOREIGN KEY([CurrencyTypeID])
REFERENCES [dbo].[CurrencyType] ([ID])
GO

ALTER TABLE [dbo].[ServiceRequest] CHECK CONSTRAINT [FK_ServiceRequest_CurrencyType]
GO

-- Setup Edit CC Securable and Event
DECLARE @EditCCNumber INT
DECLARE @RoleID UNIQUEIDENTIFIER
DECLARE @AccessTypeID INT

IF NOT EXISTS (SELECT * FROM Securable WHERE FriendlyName = 'BUTTON_EDIT_CCNUMBER')
	BEGIN
      INSERT INTO [dbo].[Securable]([FriendlyName],[ParentID],[SecurityContext])
		VALUES('BUTTON_EDIT_CCNUMBER',NULL,NULL) 
	END

SET @EditCCNumber = (SELECT TOP 1 ID FROM Securable WHERE FriendlyName = 'BUTTON_EDIT_CCNUMBER')

SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='sysadmin')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @EditCCNumber AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@EditCCNumber,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='Accounting')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @EditCCNumber AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@EditCCNumber,@RoleID,@AccessTypeID)
	END
	
SET @RoleID = (SELECT R.RoleId FROM aspnet_Roles R	JOIN aspnet_Applications  A ON R.ApplicationId = A.ApplicationId 
				WHERE A.ApplicationName = 'DMS' AND R.RoleName ='VendorRep')
SET @AccessTypeID = (SELECT TOP 1 ID FROM AccessType WHERE Name = 'ReadWrite')

IF NOT EXISTS (SELECT * FROM AccessControlList WHERE SecurableID = @EditCCNumber AND RoleID = @RoleID)
	BEGIN  
      INSERT [dbo].[AccessControlList] ([SecurableID], [RoleID], [AccessTypeID]) VALUES(@EditCCNumber,@RoleID,@AccessTypeID)
	END	

GO



-- Setup Event for EditCCNumber
IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'EditCCNumberOnPO')
	BEGIN
		INSERT INTO [dbo].[Event] (EventTypeID, EventCategoryID, Name, Description, IsShownOnScreen, IsActive, CreateBy, CreateDate)
		VALUES (
			(SELECT ID FROM EventType WHERE Name = 'User')
			, (SELECT ID FROM EventCategory WHERE Name = 'PurchaseOrder')
			, 'EditCCNumberOnPO'
			, 'Edit CC Number on PO'
			, 1
			, 1
			, 'System'
			, getdate()
			)
	END
GO


-- Template for ManualNotification
IF NOT EXISTS ( SELECT * FROM Template WHERE Name = 'LockedRequestComment' )
BEGIN
	INSERT INTO Template (Name, Subject, Body, IsActive)
	SELECT 'LockedRequestComment',
			NULL,
			'${SentFrom} - ${RequestNumber} : ${MessageText}',
			1
END
GO

-- EventTemplate - ManualNotification
IF NOT EXISTS ( SELECT * FROM EventTemplate 
				WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'LockedRequestComment') 
				AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'LockedRequestComment')
				)
BEGIN
	INSERT INTO EventTemplate (EventID,TemplateID, IsDefault)
	SELECT	(SELECT ID FROM Event WHERE Name = 'LockedRequestComment'),
			(SELECT ID FROM Template WHERE Name = 'LockedRequestComment'),
			1

END
GO

UPDATE	EventSubscription
SET		EventTemplateID = (SELECT ID FROM EventTemplate 
							WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'LockedRequestComment') 
							AND		TemplateID = (SELECT ID FROM Template WHERE Name = 'LockedRequestComment')
						)
WHERE	EventID = (SELECT ID FROM Event WHERE Name = 'LockedRequestComment') 

GO
