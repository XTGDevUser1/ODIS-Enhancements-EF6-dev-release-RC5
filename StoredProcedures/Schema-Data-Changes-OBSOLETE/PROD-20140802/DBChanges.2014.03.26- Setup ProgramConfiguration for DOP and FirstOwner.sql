--
-- Setup to make fields on Vehicle Tab program driven 
-- Date of Purchase and First Owner



-- Add program configuration item 
DECLARE @ProgramID INT
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'Ford')

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowDateOfPurchase')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')  
			, NULL
			, NULL
			, 'ShowDateOfPurchase'
			, 'No'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowFirstOwner')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')  
			, NULL
			, NULL
			, 'ShowFirstOwner'
			, 'No'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
GO


DECLARE @ProgramID INT
SET @ProgramID = (SELECT ID FROM Program WHERE Name = 'NMC')

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowDateOfPurchase')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')  
			, NULL
			, NULL
			, 'ShowDateOfPurchase'
			, 'Yes'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END

IF NOT EXISTS (SELECT * FROM ProgramConfiguration WHERE ProgramID = @ProgramID AND Name = 'ShowFirstOwner')
	BEGIN
		INSERT [dbo].[ProgramConfiguration]
			([ProgramID],[ConfigurationTypeID],[ConfigurationCategoryID],[ControlTypeID],[DataTypeID],[Name],[Value],[IsActive],[Sequence],[CreateDate],[CreateBy],[ModifyDate],[ModifyBy])
		VALUES 
			(@ProgramID
			, (SELECT ID FROM ConfigurationType WHERE Name = 'Application')
			, (SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule')  
			, NULL
			, NULL
			, 'ShowFirstOwner'
			, 'Yes'
			, 1
			, 1
			, getdate()
			, 'System'
			, NULL
			, NULL
			)
	END
GO