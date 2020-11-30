-- API_GET_MEMBER_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_GET_MEMBER_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'API_GET_MEMBER_BEGIN',
		'Begin processing Member Get API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- API_GET_MEMBER_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_GET_MEMBER_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'API_GET_MEMBER_END',
		'End processing Member GET API request',
		1,
		1,
		'system',
		GETDATE()
	)

END
-- API_POST_MEMBER_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_POST_MEMBER_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'API_POST_MEMBER_BEGIN',
		'Begin processing Member Add API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- API_POST_MEMBER_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_POST_MEMBER_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'API_POST_MEMBER_END',
		'End processing Member Add API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- API_PUT_MEMBER_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_PUT_MEMBER_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'API_PUT_MEMBER_BEGIN',
		'Begin processing Member Update API request',
		1,
		1,
		'system',
		GETDATE()
	)

END
-- API_PUT_MEMBER_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_PUT_MEMBER_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'API_PUT_MEMBER_END',
		'End processing Member Update API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- API_DELETE_MEMBER_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_DELETE_MEMBER_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'API_DELETE_MEMBER_BEGIN',
		'Begin processing Member Delete API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- API_DELETE_MEMBER_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_DELETE_MEMBER_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='Member'),
		'API_DELETE_MEMBER_END',
		'End processing Member Delete API request',
		1,
		1,
		'system',
		GETDATE()
	)

END



-- API_POST_SERVICEREQUEST_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_POST_SERVICEREQUEST_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'API_POST_SERVICEREQUEST_BEGIN',
		'Begin processing ServiceRequest Add API request',
		1,
		1,
		'system',
		GETDATE()
	)

END
-- API_POST_SERVICEREQUEST_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_POST_SERVICEREQUEST_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'API_POST_SERVICEREQUEST_END',
		'End processing ServiceRequest Add API request',
		1,
		1,
		'system',
		GETDATE()
	)

END

-- API_GET_SERVICEREQUEST_BEGIN
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_GET_SERVICEREQUEST_BEGIN')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'API_GET_SERVICEREQUEST_BEGIN',
		'Begin processing ServiceRequest Get API request',
		1,
		1,
		'system',
		GETDATE()
	)

END
-- API_GET_SERVICEREQUEST_END
IF NOT EXISTS (SELECT * FROM [Event] WHERE Name = 'API_GET_SERVICEREQUEST_END')
BEGIN
	
	INSERT INTO [Event] VALUES(
		(SELECT ID FROM EventType where Name='User'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'API_GET_SERVICEREQUEST_END',
		'End processing ServiceRequest GET API request',
		1,
		1,
		'system',
		GETDATE()
	)

END



