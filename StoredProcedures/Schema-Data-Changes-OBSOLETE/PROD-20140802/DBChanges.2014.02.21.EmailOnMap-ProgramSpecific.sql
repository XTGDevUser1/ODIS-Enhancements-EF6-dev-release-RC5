IF (select count(*) from [dbo].[ProgramConfiguration] where Name='ShowSurveyEmail')= 0
BEGIN
INSERT INTO [dbo].[ProgramConfiguration]
           ([ProgramID]
           ,[ConfigurationTypeID]
           ,[ConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[IsActive]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ((select ID from dbo.Program where Name='NMC')
           ,(select ID from dbo.ConfigurationType where Name='Application')
           ,(select ID from dbo.ConfigurationCategory where Name='Rule')
           ,NULL
           ,NULL
           ,'ShowSurveyEmail'
           ,'Yes'
           ,1
           ,1
           ,GetDate()
           ,'system'
           ,NULL
           ,NULL)

INSERT INTO [dbo].[ProgramConfiguration]
           ([ProgramID]
           ,[ConfigurationTypeID]
           ,[ConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[IsActive]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ((select ID from dbo.Program where Name='Coach-Net')
           ,(select ID from dbo.ConfigurationType where Name='Application')
           ,(select ID from dbo.ConfigurationCategory where Name='Rule')
           ,NULL
           ,NULL
           ,'ShowSurveyEmail'
           ,'Yes'
           ,1
           ,1
           ,GetDate()
           ,'system'
           ,NULL
           ,NULL)

INSERT INTO [dbo].[ProgramConfiguration]
           ([ProgramID]
           ,[ConfigurationTypeID]
           ,[ConfigurationCategoryID]
           ,[ControlTypeID]
           ,[DataTypeID]
           ,[Name]
           ,[Value]
           ,[IsActive]
           ,[Sequence]
           ,[CreateDate]
           ,[CreateBy]
           ,[ModifyDate]
           ,[ModifyBy])
     VALUES
           ((select ID from dbo.Program where Name='Ford')
           ,(select ID from dbo.ConfigurationType where Name='Application')
           ,(select ID from dbo.ConfigurationCategory where Name='Rule')
           ,NULL
           ,NULL
           ,'ShowSurveyEmail'
           ,'Yes'
           ,1
           ,1
           ,GetDate()
           ,'system'
           ,NULL
           ,NULL)

END