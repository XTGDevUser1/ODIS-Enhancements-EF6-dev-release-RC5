
IF NOT EXISTS(SELECT ID FROM ApplicationConfiguration WHERE Name = 'RolesInAddNotificationList')
BEGIN

      INSERT INTO [dbo].[ApplicationConfiguration]
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
     VALUES(
           (SELECT ID FROM ApplicationConfigurationType WHERE Name = 'System')
           , NULL
           , NULL
           , NULL
           , 'RolesInAddNotificationList' 
           , 'Agent,Manager'
           , getdate()
           , 'system' 
           , NULL
           , NULL)

END

GO