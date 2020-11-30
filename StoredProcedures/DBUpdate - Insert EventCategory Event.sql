--
-- New EventCategory and Event records
--


INSERT INTO [DMS_TEST].[dbo].[EventCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Vendor','Vendor',8,1)
GO

INSERT INTO [DMS_TEST].[dbo].[EventCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Billing','Billing',9,1)
GO

INSERT INTO [DMS_TEST].[dbo].[EventCategory]
           ([Name]
           ,[Description]
           ,[Sequence]
           ,[IsActive])
     VALUES
           ('Claims','Claims',10,1)
GO

INSERT INTO [DMS_TEST].[dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (1,8,'SubmittedWebApplication','Submitted Vendor Application from Web',1,1,'system',NULL)
GO

INSERT INTO [DMS_TEST].[dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (1,8,'WebRegistration','Submitted Web Account Registration',1,1,'system',NULL)
GO

INSERT INTO [DMS_TEST].[dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
     VALUES
           (1,8,'WebAuthentication','Authenticated Web Account',1,1,'system',NULL)
GO



