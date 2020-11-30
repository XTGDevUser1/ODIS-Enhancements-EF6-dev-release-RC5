IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'PayClaim')
BEGIN
INSERT INTO [Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (2, (SELECT TOP 1 ID FROM EventCategory WHERE Name LIKE 'Claim%'), 'PayClaim', 'Pay Claim', 1, 1, NULL, NULL)
END

IF NOT EXISTS (SELECT * FROM [ApplicationConfiguration] WHERE Name = 'ClaimGLExpenseAccount')
BEGIN
INSERT INTO [ApplicationConfiguration]
           ([ApplicationConfigurationTypeID]
           ,[ApplicationConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           (1, NULL, NULL, NULL, 'ClaimGLExpenseAccount','1110-000-00',NULL,NULL,NULL,NULL)
END

--Pavan document table changes
IF NOT EXISTS(SELECT * FROM DocumentCategory WHERE Name = 'Feedback')
BEGIN
INSERT INTO [DocumentCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Feedback', 'Feedback', 5, 1)
END

ALTER TABLE [dbo].[Document] DROP Column DocumentTypeID
GO
DROP TABLE [dbo].[DocumentType]
GO