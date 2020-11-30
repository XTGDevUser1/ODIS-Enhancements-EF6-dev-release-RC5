
IF NOT EXISTS(SELECT * FROM [Event] where Name='EnterStartTab')
BEGIN
	INSERT INTO [Event](
		EventTypeID,
		EventCategoryID,
		Name,
		[Description],
		IsShownOnScreen,
		IsActive,
		CreateBy,
		CreateDate
	)
	VALUES(
		(SELECT ID FROM EventType where Name='System'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'EnterStartTab',
		'Enter Start Tab',
		0,
		1,
		'system',
		GETDATE()
	)
END
IF NOT EXISTS(SELECT * FROM [Event] where Name='LeaveStartTab')
BEGIN
	INSERT INTO [Event](
		EventTypeID,
		EventCategoryID,
		Name,
		[Description],
		IsShownOnScreen,
		IsActive,
		CreateBy,
		CreateDate
	)
	VALUES(
		(SELECT ID FROM EventType where Name='System'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'LeaveStartTab',
		'Leave Start Tab',
		0,
		1,
		'system',
		GETDATE()
	)
END

IF NOT EXISTS(SELECT * FROM [Event] where Name='SaveMemberTab')
BEGIN
	INSERT INTO [Event](
		EventTypeID,
		EventCategoryID,
		Name,
		[Description],
		IsShownOnScreen,
		IsActive,
		CreateBy,
		CreateDate
	)
	VALUES(
		(SELECT ID FROM EventType where Name='System'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'SaveMemberTab',
		'Saving Member Tab Details',
		0,
		1,
		'system',
		GETDATE()
	)
END

IF NOT EXISTS(SELECT * FROM [Event] where Name='SaveVehicleTab')
BEGIN
	INSERT INTO [Event](
		EventTypeID,
		EventCategoryID,
		Name,
		[Description],
		IsShownOnScreen,
		IsActive,
		CreateBy,
		CreateDate
	)
	VALUES(
		(SELECT ID FROM EventType where Name='System'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'SaveVehicleTab',
		'Saving Vehcile Tab Details',
		0,
		1,
		'system',
		GETDATE()
	)
END

IF NOT EXISTS(SELECT * FROM [Event] where Name='SaveFinishTab')
BEGIN
	INSERT INTO [Event](
		EventTypeID,
		EventCategoryID,
		Name,
		[Description],
		IsShownOnScreen,
		IsActive,
		CreateBy,
		CreateDate
	)
	VALUES(
		(SELECT ID FROM EventType where Name='System'),
		(SELECT ID FROM EventCategory where Name='ServiceRequest'),
		'SaveFinishTab',
		'Saving Finish Tab Details',
		0,
		1,
		'system',
		GETDATE()
	)
END