IF NOT EXISTS (SELECT * FROM [Event] where Name = 'NextActionSet')
BEGIN
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'NextActionSet',
		'Next Action Set',
		1,
		1,
		'system',
		GETDATE()
	)
END
IF NOT EXISTS (SELECT * FROM [Event] where Name = 'NextActionCleared')
BEGIN
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'NextActionCleared',
		'Next Action Cleared',
		1,
		1,
		'system',
		GETDATE()
	)
END

IF NOT EXISTS(SELECT * FROM Entity where Name='NextAction')
BEGIN
	INSERT INTO Entity(Name,IsAudited)
	VALUES (
				'NextAction',
				0
			)
END
