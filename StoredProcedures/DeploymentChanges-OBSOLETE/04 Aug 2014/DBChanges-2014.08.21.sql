DECLARE @ProgramID INT
DECLARE @ConfigurationTypeID INT
DECLARE @CategoryValidation INT
DECLARE @CategoryRule INT

SET @ConfigurationTypeID = (SELECT ID FROM ConfigurationType WHERE Name = 'RegisterMember')
SET @CategoryValidation = (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation')
SET @CategoryRule = (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'NMC')


IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowEffectiveExpirationDates')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'ShowEffectiveExpirationDates', 'No', 1, 1, getdate(), 'System', NULL, NULL)
	END

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Coach-Net')

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowEffectiveExpirationDates')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, @ConfigurationTypeID, @CategoryValidation, NULL, NULL, 'ShowEffectiveExpirationDates', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
GO 


