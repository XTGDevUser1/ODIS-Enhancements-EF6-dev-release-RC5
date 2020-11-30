--
-- Setup to make fields on Vehicle Tab program driven 
-- Warranty Terms: time and mileage

-- Add program configuration item 
DECLARE @ProgramID INT

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Commercial Truck')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END


SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Commercial Truck')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford RV - Rental')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END
	
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford RV')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford Transport')
IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'DefaultWarrantyTermsFromVehicle')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID, (SELECT ID FROM ConfigurationType WHERE Name = 'Vehicle'), (SELECT ID FROM ConfigurationCategory WHERE Name = 'Validation'), NULL, NULL, 'DefaultWarrantyTermsFromVehicle', 'Yes', 1, 1, getdate(), 'System', NULL, NULL)
	END

-- ENDS HERE