Update ApplicationConfiguration set Value='1 8002854977' where Name='VendorServicesPhoneNumber'
Update ApplicationConfiguration set Value='1 8003311145' where Name='VendorServicesFaxNumber'

--INSERT INTO [ApplicationConfiguration] 
-- ([ApplicationConfigurationTypeID], [ApplicationConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
-- VALUES
-- (1, NULL, NULL, NULL, 'ClaimRoadsideGLExpenseAccount', '6300-310-00',NULL,NULL,NULL,NULL)
--INSERT INTO [ApplicationConfiguration] 
-- ([ApplicationConfigurationTypeID], [ApplicationConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
-- VALUES
-- (1, NULL, NULL, NULL, 'ClaimDamageGLExpenseAccount', '6302-310-00',NULL,NULL,NULL,NULL)
--INSERT INTO [ApplicationConfiguration] 
-- ([ApplicationConfigurationTypeID], [ApplicationConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
-- VALUES
-- (1, NULL, NULL, NULL, 'ClaimACESGLClearingExpenseAccount', '1110-000-00',NULL,NULL,NULL,NULL)
--INSERT INTO [ApplicationConfiguration] 
-- ([ApplicationConfigurationTypeID], [ApplicationConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
-- VALUES
-- (1, NULL, NULL, NULL, 'ClaimQFCGLClearingExpenseAccount', '1110-000-00',NULL,NULL,NULL,NULL)
--GO

--declare @Ford int = (select id from Program where code = 'FORD_MAIN')
--declare @Hagerty int = (select id from Program where code = 'HAGERTY_MAIN')
--INSERT INTO [ProgramConfiguration]
--([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
--VALUES (@Ford, 1, NULL, NULL, NULL, 'ClaimRoadsideGLExpenseAccount', '6305-310-00', 1, 1, NULL, NULL, NULL, NULL)
--INSERT INTO [ProgramConfiguration]
--([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
--VALUES (@Hagerty, 1, NULL, NULL, NULL, 'ClaimRoadsideGLExpenseAccount', '6304-310-00', 1, 1, NULL, NULL, NULL, NULL)
--GO

