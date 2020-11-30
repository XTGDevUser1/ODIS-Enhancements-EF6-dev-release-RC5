ALTER TABLE [User]
ADD ManagerID INT NULL REFERENCES [User](ID)


ALTER TABLE ProductProvider Add IsCaptureClaimNumber bit null

ALTER TABLE ServiceRequest Add ProviderClaimNumber nvarchar(50) null


Update ProductProvider SET IsCaptureClaimNumber = 1 where Name = 'SouthwestRe'


IF NOT EXISTS (SELECT * FROM EventCategory WHERE Name = 'CoachingConcern')
BEGIN
	INSERT EventCategory (Name, Description, [Sequence], IsActive)
	VALUES ( 'CoachingConcern', 'Coaching Concern', 17, 1)
END

IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'AddCoachingConcern')
BEGIN
	INSERT Event (EventTypeID, EventCategoryID, Name, Description, IsShownOnScreen, IsActive, CreateBy, CreateDate)
	VALUES ( (SELECT ID FROM EventType WHERE Name = 'User'), (SELECT ID FROM EventCategory WHERE Name = 'CoachingConcern')
	, 'AddCoachingConcern', 'Add coaching concern', 0, 1, 'system', getdate()
	)
END

IF NOT EXISTS (SELECT * FROM Event WHERE Name = 'UpdateCoachingConcern')
BEGIN
	INSERT Event (EventTypeID, EventCategoryID, Name, Description, IsShownOnScreen, IsActive, CreateBy, CreateDate)
	VALUES ( (SELECT ID FROM EventType WHERE Name = 'User'), (SELECT ID FROM EventCategory WHERE Name = 'CoachingConcern')
	, 'UpdateCoachingConcern', 'Update coaching concern', 0, 1, 'system', getdate()
	)
END

