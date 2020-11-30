-- NOTE : Update the <ProgramID> in the below SQL statement.
INSERT INTO ProgramConfiguration (ProgramID,ConfigurationTypeID,ConfigurationCategoryID,Name,Value,IsActive,CreateDate,CreateBy)
SELECT <ProgramID>,	(SELECT ID FROM ConfigurationType WHERE Name = 'Application'),
			(SELECT ID FROM ConfigurationCategory WHERE Name = 'Rule'),
			'InsertMembershipNumber',
			'YES',
			1,
			GETDATE(),
			'system'