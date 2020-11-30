--Events for Temporary CC Post screen
DECLARE @EventCategoryID INT
DECLARE @EventTypeID INT
SET @EventCategoryID = (SELECT ID FROM EventCategory WHERE Name = 'VendorInvoice')
SET @EventTypeID = (SELECT ID FROM EventType WHERE Name = 'User')

-- Insert New Events
IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'ImportTempCCFile')
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
           (@EventTypeID
           ,@EventCategoryID
           ,'ImportTempCCFile'
           ,'Import Temporary Credit Card File'
           ,0
           ,1
           ,'system'
           ,getdate()
           )
    END
    
IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'MatchTempCC')
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
           (@EventTypeID
           ,@EventCategoryID
           ,'MatchTempCC'
           ,'Match Temporary Credit Card Records'
           ,0
           ,1
           ,'system'
           ,getdate()
           )
    END


IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'PostTempCC')
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
           (@EventTypeID
           ,@EventCategoryID
           ,'PostTempCC'
           ,'Post Temporary Credit Card Records'
           ,0
           ,1
           ,'system'
           ,getdate()
           )
    END


IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'SearchTempCCHistory')
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
           (@EventTypeID
           ,@EventCategoryID
           ,'SearchTempCCHistory'
           ,'Search Temporary Credit Card History'
           ,0
           ,1
           ,'system'
           ,getdate()
           )
    END

GO
