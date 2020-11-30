if (select @@ServerName) in ('INFHYDCRM4D\SQLR2')
begin

begin tran  -- <<<<<<<<<<<<< ONE TRANSACTION !!!!!!!!!     COMMIT AT END 
-- commit tran
-- rollback tran



	---------------------------  BillingSchedule -----------------------------------------------------------------
	delete dbo.BillingSchedule
	-- truncate table dbo.BillingSchedule
	
	-- ============   Monthly Schedules   ================
	-- Monthly-FirstDayOfMonth-PreviousMonth
	-- JANUARY
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Monthly-FirstDayOfMonth-PreviousMonth', -- Name
	 'Monthly - First Day of the Month - For Previous Month', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'FIRST_DAY_OF_MO'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_MO'), -- ScheduleRangeTypeID
	'02/01/2013', -- ScheduleDate
	'01/01/2013', -- ScheduleRangeBegin
	'01/31/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'MONTHLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'CLOSED'), -- ScheduleStatusID
	 0,  -- Sequence
	 0, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)

	-- FEBRUARY
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Monthly-FirstDayOfMonth-PreviousMonth', -- Name
	 'Monthly - First Day of the Month - For Previous Month', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'FIRST_DAY_OF_MO'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_MO'), -- ScheduleRangeTypeID
	'03/01/2013', -- ScheduleDate
	'02/01/2013', -- ScheduleRangeBegin
	'02/28/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'MONTHLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'CLOSED'), -- ScheduleStatusID
	 0,  -- Sequence
	 0, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)

	-- MARCH
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Monthly-FirstDayOfMonth-PreviousMonth', -- Name
	 'Monthly - First Day of the Month - For Previous Month', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'FIRST_DAY_OF_MO'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_MO'), -- ScheduleRangeTypeID
	'04/01/2013', -- ScheduleDate
	'03/01/2013', -- ScheduleRangeBegin
	'03/31/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'MONTHLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'CLOSED'), -- ScheduleStatusID
	 0,  -- Sequence
	 0, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)

	-- APRIL
	-- Monthly-FirstDayOfMonth-PreviousMonth
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Monthly-FirstDayOfMonth-PreviousMonth', -- Name
	 'Monthly - First Day of the Month - For Previous Month', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'FIRST_DAY_OF_MO'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_MO'), -- ScheduleRangeTypeID
	'05/01/2013', -- ScheduleDate
	'04/01/2013', -- ScheduleRangeBegin
	'04/30/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'MONTHLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'CLOSED'), -- ScheduleStatusID
	 0,  -- Sequence
	 0, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)

	-- MAY
	-- Monthly-FirstDayOfMonth-PreviousMonth
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Monthly-FirstDayOfMonth-PreviousMonth', -- Name
	 'Monthly - First Day of the Month - For Previous Month', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'FIRST_DAY_OF_MO'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_MO'), -- ScheduleRangeTypeID
	'06/01/2013', -- ScheduleDate
	'05/01/2013', -- ScheduleRangeBegin
	'05/31/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'MONTHLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'CLOSED'), -- ScheduleStatusID
	 0,  -- Sequence
	 0, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)

	-- JUNE
	-- Monthly-FirstDayOfMonth-PreviousMonth
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Monthly-FirstDayOfMonth-PreviousMonth', -- Name
	 'Monthly - First Day of the Month - For Previous Month', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'FIRST_DAY_OF_MO'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_MO'), -- ScheduleRangeTypeID
	'07/01/2013', -- ScheduleDate
	'06/01/2013', -- ScheduleRangeBegin
	'06/30/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'MONTHLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'OPEN'), -- ScheduleStatusID
	 0,  -- Sequence
	 1, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)

	-- ============   Weekly Schedules   ================
	-- WEEKLY : 6/03 - 6/09
	-- Weekly-Monday-PreviousWeek
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Weekly-Monday-PreviousWeek', -- Name
	 'Weekly - Monday - For Previous Week', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'MONDAY'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_WK'), -- ScheduleRangeTypeID
	'06/03/2013', -- ScheduleDate
	'06/09/2013', -- ScheduleRangeBegin
	'06/10/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'WEEKLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'CLOSED'), -- ScheduleStatusID
	 0,  -- Sequence
	 0, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)

	-- WEEKLY : 6/10 - 6/16
	-- Weekly-Monday-PreviousWeek
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Weekly-Monday-PreviousWeek', -- Name
	 'Weekly - Monday - For Previous Week', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'MONDAY'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_WK'), -- ScheduleRangeTypeID
	'06/10/2013', -- ScheduleDate
	'06/16/2013', -- ScheduleRangeBegin
	'06/17/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'WEEKLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'CLOSED'), -- ScheduleStatusID
	 0,  -- Sequence
	 0, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)

	-- WEEKLY : 6/17 - 6/23
	-- Weekly-Monday-PreviousWeek
	insert into dbo.BillingSchedule
	(Name,
	 [Description],
	 ScheduleDateTypeID,
	 ScheduleRangeTypeID,
	 ScheduleDate,
	 ScheduleRangeBegin,
	 ScheduleRangeEnd,
	 ScheduleTypeID,
	 ScheduleStatusID,
	 Sequence,
	 IsActive,
	 CreateDate,
	 CreateBy,
	 ModifyDate,
	 ModifyBy)
	values
	('Weekly-Monday-PreviousWeek', -- Name
	 'Weekly - Monday - For Previous Week', -- [Description]
	(select ID from dbo.BillingScheduleDateType where Name = 'MONDAY'), -- ScheduleDateTypeID
	(select ID from dbo.BillingScheduleRangeType where Name = 'PREVIOUS_WK'), -- ScheduleRangeTypeID
	'06/17/2013', -- ScheduleDate
	'06/23/2013', -- ScheduleRangeBegin
	'06/24/2013', -- ScheduleRangeEnd
	(select ID from dbo.BillingScheduleType where Name = 'WEEKLY'), -- ScheduleTypeID
	(select ID from dbo.BillingScheduleStatus where Name = 'OPEN'), -- ScheduleStatusID
	 0,  -- Sequence
	 1, -- IsActive
	 getdate(), -- CreateDate
	 'BillingSetUp', -- CreateBy
	 null, -- ModifyDate
	 null -- ModifyBy
	)



	--------------------------------- BillingDefinitionEvent ------------------------------------
	declare @Name as nvarchar(255)
	
	-- VendorInvoicesReceived
	---------------------------------------------
	select @Name = 'VendorInvoicesReceived'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Vendor Invoices Received', -- [Description]
		'dbo.dms_BillingVendorInvoicesReceived_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- PurchaseOrdersIncurred
	---------------------------------------------
	select @Name = 'PurchaseOrdersIncurred'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Purchase Orders Incurred', -- [Description]
		'dbo.dms_BillingPurchaseOrdersIncurred_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

	-- ActiveMembers
	---------------------------------------------
	select @Name = 'ActiveMembers'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Active Members', -- [Description]
		'dbo.dms_BillingActiveMembers_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- ActiveMembersAtPreviousYearEnd
	---------------------------------------------
	select @Name = 'ActiveMembersAtPreviousYearEnd'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Active Members At Previous YearEnd', -- [Description]
		'dbo.dms_BillingActiveMembersAtPreviousYearEnd_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NewRegistrations
	---------------------------------------------
	select @Name = 'NewRegistrations'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'New Registrations', -- [Description]
		'dbo.dms_BillingNewRegistrations_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

	-- NewRegistrationsSystemCreated
	---------------------------------------------
	select @Name = 'NewRegistrationsSystemCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		'NewRegistrationsSystemCreated', -- Name
		'New Registrations System Created', -- [Description]
		'dbo.dms_BillingNewRegistrationsSystemCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NewRegistrationsManuallyCreated
	---------------------------------------------
	select @Name = 'NewRegistrationsManuallyCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'New Registrations Manually Created', -- [Description]
		'dbo.dms_BillingNewRegistrationsManuallyCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

	-- IncomingCallsMotorHomeCACLineFORDCOMM_MFG
	---------------------------------------------
	select @Name = 'IncomingCallsMotorHomeCACLineFORDCOMM_MFG'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'DATAMART'), -- SystemSource
		@Name, -- Name
		'Incoming Calls Motor Home CAC Line FORDCOMM_MFG', -- [Description]
		'dbo.dms_BillingIncomingCallsMotorHomeCACLineFORDCOMM_MFG_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

	-- IncomingCallsRecallLineFORDCOMM_MFG
	---------------------------------------------
	select @Name = 'IncomingCallsRecallLineFORDCOMM_MFG'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'DATAMART'), -- SystemSource
		@Name, -- Name
		'Incoming Calls Recall Line FORDCOMM_MFG', -- [Description]
		'dbo.dms_BillingIncomingCallsRecallLineFORDCOMM_MFG_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- IncomingCallsTransportLineFORDTRNS
	---------------------------------------------
	select @Name = 'IncomingCallsTransportLineFORDTRNS'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'DATAMART'), -- SystemSource
		@Name, -- Name
		'Incoming Calls Transport Line FORDTRNS', -- [Description]
		'dbo.dms_BillingIncomingCallsTransportLineFORDTRNS_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- CallTransfersToAgeroFORD
	---------------------------------------------
	select @Name = 'CallTransfersToAgeroFORDCOMM_MFG'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'DATAMART'), -- SystemSource
		@Name, -- Name
		'Call Transfers To Agero FORDCOMM_MFG', -- [Description]
		'dbo.dms_BillingCallTransfersToAgeroFORDCOMM_MFG_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- DispatchEventsAll
	---------------------------------------------
	select @Name = 'DispatchEventsAll'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Dispatch Events All', -- [Description]
		'dbo.dms_BillingDispatchEventsAll_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- DispatchEventsAllManuallyCreated
	---------------------------------------------
	select @Name = 'DispatchEventsAllManuallyCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Dispatch Events All Manually Created', -- [Description]
		'dbo.dms_BillingDispatchEventsAllManuallyCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- DispatchEventsAllSystemCreated
	---------------------------------------------
	select @Name = 'DispatchEventsAllSystemCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Dispatch Events All System Created', -- [Description]
		'dbo.dms_BillingDispatchEventsAllSystemCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsAll
	---------------------------------------------
	select @Name = 'NonDispatchEventsAll'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events All', -- [Description]
		'dbo.dms_BillingNonDispatchEventsAll_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end



	-- NonDispatchEventsAllManuallyCreated
	---------------------------------------------
	select @Name = 'NonDispatchEventsAllManuallyCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events All Manually Created', -- [Description]
		'dbo.dms_BillingNonDispatchEventsAllManuallyCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end




	-- NonDispatchEventsAllSystemCreated
	---------------------------------------------
	select @Name = 'NonDispatchEventsAllSystemCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events All System Created', -- [Description]
		'dbo.dms_BillingNonDispatchEventsAllSystemCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsInfo
	---------------------------------------------
	select @Name = 'NonDispatchEventsInfo'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Info', -- [Description]
		'dbo.dms_BillingNonDispatchEventsInfo_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsInfoManuallyCreated
	---------------------------------------------
	select @Name = 'NonDispatchEventsInfoManuallyCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Info Manually Created', -- [Description]
		'dbo.dms_BillingNonDispatchEventsInfoManuallyCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsInfoSystemCreated
	---------------------------------------------
	select @Name = 'NonDispatchEventsInfoSystemCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Info System Created', -- [Description]
		'dbo.dms_BillingNonDispatchEventsInfoSystemCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsCustomerAssistance
	---------------------------------------------
	select @Name = 'NonDispatchEventsCustomerAssistance'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Customer Assistance', -- [Description]
		'dbo.dms_BillingNonDispatchEventsCustomerAssistance_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsCustomerAssistanceManuallyCreated
	------------------------------------------------------------
	select @Name = 'NonDispatchEventsCustomerAssistanceManuallyCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Customer Assistance Manually Created', -- [Description]
		'dbo.dms_BillingNonDispatchEventsCustomerAssistanceManuallyCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsCustomerAssistanceSystemCreated
	-------------------------------------------------------------------
	select @Name = 'NonDispatchEventsCustomerAssistanceSystemCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Customer Assistance System Created', -- [Description]
		'dbo.dms_BillingNonDispatchEventsCustomerAssistanceSystemCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsOther
	---------------------------------------------
	select @Name = 'NonDispatchEventsOther'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Other', -- [Description]
		'dbo.dms_BillingNonDispatchEventsOther_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsOtherManuallyCreated
	---------------------------------------------
	select @Name = 'NonDispatchEventsOtherManuallyCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Other Manually Created', -- [Description]
		'dbo.dms_BillingNonDispatchEventsOtherManuallyCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- NonDispatchEventsOtherSystemCreated
	---------------------------------------------
	select @Name = 'NonDispatchEventsOtherSystemCreated'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Non-Dispatch Events Other System Created', -- [Description]
		'dbo.dms_BillingNonDispatchEventsOtherSystemCreated_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- ImpoundRelease
	---------------------------------------------
	select @Name = 'ImpoundRelease'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Impound Release', -- [Description]
		'dbo.dms_BillingImpoundRelease_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

	-- AdministationFeeFlat
	---------------------------------------------
	select @Name = 'AdministationFeeFlat'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Administation Fee Flat', -- [Description]
		'dbo.dms_BillingAdministationFeeFlat_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


	-- FixedAmountQuantityAndRate
	---------------------------------------------
	select @Name = 'FixedAmountQuantityAndRate'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Fixed Amount Using Quantity And Rate', -- [Description]
		'dbo.dms_BillingFixedAmountQuantityAndRate_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

	-- Claims Processed
	---------------------------------------------
	select @Name = 'ClaimsProcessed'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Claims Processed', -- [Description]
		'dbo.dms_BillingClaimsProcessed_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

	-- Claims Paid
	---------------------------------------------
	select @Name = 'ClaimsPaid'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Claims Paid', -- [Description]
		'dbo.dms_BillingClaimsPaid_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


/*** ESP now uses generic Claims Processed
	-- Claims Processed FORDESP
	---------------------------------------------
	select @Name = 'ClaimsProcessedFORDESP'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Claims Processed FORDESP', -- [Description]
		'dbo.dms_BillingClaimsProcessedFORDESP_MFG_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

***/

/*** QFC Now uses generic Claims Processed
	-- Claims Processed FORDQFC
	---------------------------------------------
	select @Name = 'ClaimsProcessedFORDQFC'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Claims Processed FORDQFC', -- [Description]
		'dbo.dms_BillingClaimsProcessedFORDQFC_MFG_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

***/

/*** Remove - ESP will use the generic Vendor Invoices Received
	-- VendorInvoicesReceivedFORDESP
	------------------------------------------------------------
	select @Name = 'VendorInvoicesReceivedFORDESP'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Vendor Invoices Received FORDESP', -- [Description]
		'dbo.dms_BillingVendorInvoicesReceivedFORDESP_MFG_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end

***/
	-- DispatchEventsAllCashEventsFORDESP
	---------------------------------------------
	select @Name = 'DispatchEventsAllCashEventsFORDESP'
	delete dbo.BillingDefinitionEvent where Name = @Name
	if isnull((select count(*) from dbo.BillingDefinitionEvent where Name = @Name), 0) = 0
	begin
		insert into dbo.BillingDefinitionEvent
		(EventSystemSourceID,
		 Name,
		 [Description],
		 DBObject,
		 Sequence,
		 IsActive,
		 CreateDate,
		 CreateBy,
		 ModifyDate,
		 ModifyBy
		)
		select	
		(select ID from dbo.BillingEventSystemSource where name = 'ODIS'), -- SystemSource
		@Name, -- Name
		'Dispatch Events All Cash Event FORDESP', -- [Description]
		'dbo.dms_BillingDispatchEventsAllCashEventsFORDESP_MFG_Get',	-- DBObject
		0,	-- Sequence
		1,	-- IsActive
		getdate(),	-- CreateDate
		'BillingSetUp',	-- CreateBy
		null,	-- ModifyDate
		null	-- ModifyBy
	end


end


-- select * from dbo.BillingDefinitionEvent
