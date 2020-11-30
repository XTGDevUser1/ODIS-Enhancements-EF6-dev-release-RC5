-- REQUEST_MEMBER_ADD_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_MEMBER_ADD_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'REQUEST_MEMBER_ADD_BEGIN',
		'Begin processing Member Add API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- REQUEST_MEMBER_ADD_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_MEMBER_ADD_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'REQUEST_MEMBER_ADD_END',
		'End processing Member Add API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- REQUEST_MEMBER_UPDATE_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_MEMBER_UPDATE_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'REQUEST_MEMBER_UPDATE_BEGIN',
		'Begin processing Member Update API request',
		1,
		1,
		'system',
		GETDATE()
	)

END
-- REQUEST_MEMBER_UPDATE_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_MEMBER_UPDATE_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'REQUEST_MEMBER_UPDATE_END',
		'End processing Member Update API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- REQUEST_MEMBER_DELETE_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_MEMBER_DELETE_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'REQUEST_MEMBER_DELETE_BEGIN',
		'Begin processing Member Delete API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- REQUEST_MEMBER_DELETE_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_MEMBER_DELETE_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'REQUEST_MEMBER_DELETE_END',
		'End processing Member Delete API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- REQUEST_MEMBER_SEARCH_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_MEMBER_SEARCH_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'REQUEST_MEMBER_SEARCH_BEGIN',
		'Begin processing Member Search API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- REQUEST_MEMBER_SEARCH_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_MEMBER_SEARCH_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'REQUEST_MEMBER_SEARCH_END',
		'End processing Member Search API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- REQUEST_SERVICEREQUEST_ADD_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_SERVICEREQUEST_ADD_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'REQUEST_SERVICEREQUEST_ADD_BEGIN',
		'Begin processing ServiceRequest Add API request',
		1,
		1,
		'system',
		GETDATE()
	)

END
-- REQUEST_SERVICEREQUEST_ADD_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'REQUEST_SERVICEREQUEST_ADD_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'REQUEST_SERVICEREQUEST_ADD_END',
		'End processing ServiceRequest Add API request',
		1,
		1,
		'system',
		GETDATE()
	)

END



