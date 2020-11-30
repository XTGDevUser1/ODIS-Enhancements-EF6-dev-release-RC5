IF NOT EXISTS (SELECT * FROM [Event] where Name = 'NextActionStarted')
BEGIN
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'NextActionStarted',
		'Next Action Started',
		1,
		1,
		'system',
		GETDATE()
	)
END