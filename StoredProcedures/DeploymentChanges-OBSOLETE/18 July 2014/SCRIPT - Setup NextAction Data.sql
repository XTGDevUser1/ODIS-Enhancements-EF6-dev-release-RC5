--
-- DATA UPDATE SCRIPT
-- Setup NextAction data tables
--


-- Insert/Update Re-send PO
IF NOT EXISTS (SELECT * FROM NextAction WHERE Name = 'ResendPO')
	BEGIN
		INSERT NextAction (ContactCategoryID, Name, Description, DefaultPriorityID, IsActive, Sequence, DefaultScheduleDateInterval, DefaultScheduleDateIntervalUOM, DefaultAssignedToUserID)
		VALUES (NULL, 'ResendPO', 'Re-send PO', 4, 1, NULL, 0, 'Seconds', (SELECT ID FROM [User] WHERE FirstName = 'Agent' and LastName = 'User') )
	END

IF EXISTS (SELECT * FROM NextAction WHERE Name = 'ResendPO')
	BEGIN
		UPDATE NextAction SET Description='Re-send PO', DefaultPriorityID = 4, DefaultScheduleDateInterval=0, DefaultScheduleDateIntervalUOM='Seconds', defaultAssignedTouserID=(SELECT ID FROM [User] WHERE FirstName = 'Agent' and LastName = 'User') WHERE  ID = (SELECT ID FROM NextAction WHERE Name = 'ResendPO')
	END

-- Update Credit Card Needed
IF NOT EXISTS (SELECT * FROM NextAction WHERE Name = 'CreditCardNeeded')
	BEGIN
		INSERT NextAction (ContactCategoryID, Name, Description, DefaultPriorityID, IsActive, Sequence, DefaultScheduleDateInterval, DefaultScheduleDateIntervalUOM, DefaultAssignedToUserID)
		VALUES (NULL, 'CreditCardNeeded', 'Credit Card Needed', 4, 1, NULL, 0, 'Seconds', (SELECT ID FROM [User] WHERE FirstName = 'Manager' and LastName = 'User') )
	END

IF EXISTS (SELECT * FROM NextAction WHERE Name = 'CreditCardNeeded')
	BEGIN
		UPDATE NextAction SET DefaultPriorityID = 4, DefaultScheduleDateInterval=0, DefaultScheduleDateIntervalUOM='Seconds', defaultAssignedTouserID=(SELECT ID FROM [User] WHERE FirstName = 'Manager' and LastName = 'User') WHERE  ID = (SELECT ID FROM NextAction WHERE Name = 'CreditCardNeeded')
	END

-- Set DefaultAssignedToUserID where needed
IF EXISTS (SELECT * FROM NextAction WHERE Name = 'ManagerApproval')
	BEGIN
		UPDATE NextAction SET DefaultPriorityID = 4, DefaultScheduleDateInterval=0, DefaultScheduleDateIntervalUOM='Seconds', defaultAssignedTouserID=(SELECT ID FROM [User] WHERE FirstName = 'Manager' and LastName = 'User') WHERE  ID = (SELECT ID FROM NextAction WHERE Name = 'ManagerApproval')
	END

IF EXISTS (SELECT * FROM NextAction WHERE Name = 'Escalation')
	BEGIN
		UPDATE NextAction SET DefaultPriorityID = 4, DefaultScheduleDateInterval=0, DefaultScheduleDateIntervalUOM='Seconds', defaultAssignedTouserID=(SELECT ID FROM [User] WHERE FirstName = 'Manager' and LastName = 'User') WHERE  ID = (SELECT ID FROM NextAction WHERE Name = 'Escalation')
	END
	

IF EXISTS (SELECT * FROM NextAction WHERE Name = 'Escalation')
	BEGIN
		UPDATE NextAction SET DefaultPriorityID = 4, DefaultScheduleDateInterval=0, DefaultScheduleDateIntervalUOM='Seconds', defaultAssignedTouserID=(SELECT ID FROM [User] WHERE FirstName = 'Manager' and LastName = 'User') WHERE  ID = (SELECT ID FROM NextAction WHERE Name = 'Escalation')
	END


-- Setup NextAction Roles
IF NOT EXISTS (SELECT * FROM NextActionRole WHERE NextActionID = (SELECT ID FROM NextAction WHERE Name = 'FordTech') )
	BEGIN
		INSERT NextActionRole (NextActionID, RoleID)
		VALUES ( (SELECT ID FROM NextAction WHERE Name = 'FordTech'), (SELECT RoleID FROM aspnet_Roles WHERE RoleName = 'RVTech') )
	END
	
IF NOT EXISTS (SELECT * FROM NextActionRole WHERE NextActionID = (SELECT ID FROM NextAction WHERE Name = 'ManagerApproval') )
	BEGIN
		INSERT NextActionRole (NextActionID, RoleID)
		VALUES ( (SELECT ID FROM NextAction WHERE Name = 'ManagerApproval'), (SELECT RoleID FROM aspnet_Roles WHERE RoleName = 'Manager') )
	END

IF NOT EXISTS (SELECT * FROM NextActionRole WHERE NextActionID = (SELECT ID FROM NextAction WHERE Name = 'RVTech') )
	BEGIN
		INSERT NextActionRole (NextActionID, RoleID)
		VALUES ( (SELECT ID FROM NextAction WHERE Name = 'RVTech'), (SELECT RoleID FROM aspnet_Roles WHERE RoleName = 'RVTech') )
	END

IF NOT EXISTS (SELECT * FROM NextActionRole WHERE NextActionID = (SELECT ID FROM NextAction WHERE Name = 'Escalation') )
	BEGIN
		INSERT NextActionRole (NextActionID, RoleID)
		VALUES ( (SELECT ID FROM NextAction WHERE Name = 'Escalation'), (SELECT RoleID FROM aspnet_Roles WHERE RoleName = 'Manager') )
	END
	
IF NOT EXISTS (SELECT * FROM NextActionRole WHERE NextActionID = (SELECT ID FROM NextAction WHERE Name = 'CreditCardNeeded') )
	BEGIN
		INSERT NextActionRole (NextActionID, RoleID)
		VALUES ( (SELECT ID FROM NextAction WHERE Name = 'CreditCardNeeded'), (SELECT RoleID FROM aspnet_Roles WHERE RoleName = 'Manager') )
	END


