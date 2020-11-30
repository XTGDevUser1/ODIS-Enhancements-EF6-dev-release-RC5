--
-- Setup ProgramConfiguration for MemberEligibilityApplies

DECLARE @configurationTypeID INT = (SELECT ID FROM ConfigurationType where Name='Service')
DECLARE @configurationCategoryID INT = (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation')
DECLARE @programConfigurationName NVARCHAR(100) = 'MemberEligibilityApplies'
IF EXISTS(Select * from Program where Name = 'NMC') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'NMC') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'NMC'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Pinnacle') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Pinnacle') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Pinnacle'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Horizon Card') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Horizon Card') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Horizon Card'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Safe Driver') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Safe Driver') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Safe Driver'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Coach-Net') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Coach-Net') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Coach-Net'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'CNET Auto Only - Gold') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'CNET Auto Only - Gold') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'CNET Auto Only - Gold'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'No', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Hagerty') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select TOP 1 ID from Program where Name = 'Hagerty') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select TOP 1 ID from Program where Name = 'Hagerty'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
--IF EXISTS(Select * from Program where Name = 'Ford') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Ford') AND [Name]=@programConfigurationName)
--BEGIN
--	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Ford'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
--END
IF EXISTS(Select * from Program where Name = 'PDG - Professional Dispatch Group') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'PDG - Professional Dispatch Group') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'PDG - Professional Dispatch Group'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Airstream') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Airstream') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Airstream'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Alliance Health Card') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Alliance Health Card') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Alliance Health Card'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Fleetwood') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Fleetwood') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Fleetwood'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Forest River') AND  NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Forest River') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Forest River'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Jayco') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Jayco') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Jayco'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Triple E') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select TOP 1 ID from Program where Name = 'Triple E') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select TOP 1 ID from Program where Name = 'Triple E'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Monaco') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Monaco') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Monaco'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Travel Guard') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Travel Guard') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Travel Guard'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Sea Tow - Trailer Care') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Sea Tow - Trailer Care') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Sea Tow - Trailer Care'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Universal Trailer') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Universal Trailer') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Universal Trailer'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'NIRS (National Interstate Road Service)') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'NIRS (National Interstate Road Service)') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'NIRS (National Interstate Road Service)'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'KZ RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'KZ RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'KZ RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Lamborghini') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select TOP 1  ID from Program where Name = 'Lamborghini') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select TOP 1  ID from Program where Name = 'Lamborghini'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Gulfstream RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Gulfstream RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Gulfstream RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'PCG - Travel Guard') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'PCG - Travel Guard') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'PCG - Travel Guard'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Damon RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Damon RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Damon RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Spartan Chassis') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Spartan Chassis') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Spartan Chassis'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Doubletree RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Doubletree RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Doubletree RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Atwood Level Legs (Assist Only)') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Atwood Level Legs (Assist Only)') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Atwood Level Legs (Assist Only)'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Federal Chamber of Commerce') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Federal Chamber of Commerce') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Federal Chamber of Commerce'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Starcraft RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Starcraft RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Starcraft RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = '890049 - WORLD SOURCE 1-BATTERY POWER') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = '890049 - WORLD SOURCE 1-BATTERY POWER') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = '890049 - WORLD SOURCE 1-BATTERY POWER'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Roadtrek RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Roadtrek RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Roadtrek RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'American Coach RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'American Coach RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'American Coach RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Tiffin RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Tiffin RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Tiffin RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Crossroads RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Crossroads RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Crossroads RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Dutchmen RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Dutchmen RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Dutchmen RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Four Winds RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Four Winds RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Four Winds RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Evergreen RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Evergreen RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Evergreen RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'BMS') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'BMS') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'BMS'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Benefit Logix') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Benefit Logix') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Benefit Logix'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'PreCash') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'PreCash') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'PreCash'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'American Modern') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'American Modern') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'American Modern'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Coachmen') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Coachmen') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Coachmen'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Entegra') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Entegra') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Entegra'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Winnebago') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select TOP 1 ID from Program where Name = 'Winnebago') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select TOP 1 ID from Program where Name = 'Winnebago'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Careington') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Careington') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Careington'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Health Depot') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Health Depot') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Health Depot'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Open Range') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Open Range') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Open Range'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Pacific Coachworks') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Pacific Coachworks') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Pacific Coachworks'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Augusta RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Augusta RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Augusta RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Excel RV') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Excel RV') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Excel RV'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'ONSITE Temp Housing') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'ONSITE Temp Housing') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'ONSITE Temp Housing'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END
IF EXISTS(Select * from Program where Name = 'Airstream 2 Go') AND NOT EXISTS(SELECT * FROM ProgramConfiguration where [ProgramID] = (Select ID from Program where Name = 'Airstream 2 Go') AND [Name]=@programConfigurationName)
BEGIN
	INSERT [dbo].[ProgramConfiguration] ([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy]) VALUES ((Select ID from Program where Name = 'Airstream 2 Go'), @configurationTypeID, @configurationCategoryID, NULL, NULL, @programConfigurationName, 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
END


