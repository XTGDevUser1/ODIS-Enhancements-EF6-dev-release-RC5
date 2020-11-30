
IF NOT EXISTS(SELECT * FROM Event WHERE Name = 'UpdateMemberInfoInCase')
      BEGIN
            INSERT INTO [dbo].[Event]
           ([EventTypeID]
           ,[EventCategoryID]
           ,[Name]
           ,[Description]
           ,[IsShownOnScreen]
           ,[IsActive]
           ,[CreateBy]
           ,[CreateDate])
            VALUES
           ((select [ID] from [dbo].[EventType] where Name='User')
           ,(select [ID] from [dbo].[EventCategory] where Name='ServiceRequest')
           ,'UpdateMemberInfoInCase'
           ,'Update Member Info In Case'
           ,1
           ,1
           ,NULL
           ,GETDATE())
      END
GO
