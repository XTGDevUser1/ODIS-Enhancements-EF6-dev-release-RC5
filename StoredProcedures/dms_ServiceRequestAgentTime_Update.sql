/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestAgentTime_Update]    Script Date: 04/21/2015 14:13:56 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_ServiceRequestAgentTime_Update]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_ServiceRequestAgentTime_Update]
GO

/****** Object:  StoredProcedure [dbo].[dms_ServiceRequestAgentTime_Update]    Script Date: 04/21/2015 14:13:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- EXEC [dbo].[dms_ServiceRequestAgentTime_Update]

-- EXEC [dbo].[dms_ServiceRequestAgentTime_Update]


CREATE PROCEDURE [dbo].[dms_ServiceRequestAgentTime_Update] (
	@StartDate datetime = NULL,
	@EndDate datetime = NULL
)
AS
BEGIN


	--DECLARE @StartDate Datetime = '1/16/2015'
	--DECLARE @EndDate Datetime = '1/17/2015'
	
	IF @StartDate IS NULL 
		SET @StartDate = Convert(datetime, Convert(varchar, DATEADD(dd,-30,GetDate()),101))
		
	IF @EndDate IS NULL
		SET @EndDate = Convert(datetime, Convert(varchar, DATEADD(dd,1,GetDate()),101))	
	
	DECLARE @srEntityID INT,
			@CaseEntityID INT,
			@VendorLocationEntityID INT,
			@SRCompleteID int,
			@SRCancelledID int,
			@EnterDispatchTabEventID int
	SELECT @srEntityID = ID FROM Entity WHERE Name = 'ServiceRequest'
	SELECT @CaseEntityID = ID FROM Entity WHERE Name = 'Case'
	SELECT @VendorLocationEntityID = ID FROM Entity WHERE Name = 'VendorLocation'
	SELECT @SRCompleteID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Complete')
	SELECT @SRCancelledID = (SELECT ID FROM ServiceRequestStatus WHERE Name = 'Cancelled')
	SELECT @EnterDispatchTabEventID = (SELECT ID from [Event] where name = 'EnterDispatchTab')
	
	Declare @ContactCategoryID_VendorSelection int,
		@ContactActionID_Negotiate int,
		@ContactCategoryID_ServiceLocationSelection int
	Set @ContactCategoryID_VendorSelection = (Select ID From ContactCategory Where Name = 'VendorSelection')
	Set @ContactActionID_Negotiate = (Select ID From ContactAction Where Name = 'Negotiate')
	Set @ContactCategoryID_ServiceLocationSelection = (Select ID From ContactCategory Where Name = 'ServiceLocationSelection')

	DECLARE @TimeTypeFrontEnd int,
			@TimeTypeBackEnd int,
			@TimeTypeTech int
	SELECT @TimeTypeFrontEnd = (SELECT ID FROM TimeType WHERE NAME = 'FrontEnd')
	SELECT @TimeTypeBackEnd = (SELECT ID FROM TimeType WHERE NAME = 'BackEnd')
	SELECT @TimeTypeTech = (SELECT ID FROM TimeType WHERE NAME = 'Tech')

	DECLARE @TechLeadTimeLimitSeconds int
	SET @TechLeadTimeLimitSeconds = 43200  --(12 hrs in seconds)
	
		/* Tech Users list */
	DECLARE @TechUsers Table (Username nvarchar(50))
	
	/*
	INSERT INTO @TechUsers (Username) VALUES ('lwendt')
	INSERT INTO @TechUsers (Username) VALUES ('kcarichner')
	INSERT INTO @TechUsers (Username) VALUES ('kgold')
	INSERT INTO @TechUsers (Username) VALUES ('lpintado')
	INSERT INTO @TechUsers (Username) VALUES ('ilewis')
	INSERT INTO @TechUsers (Username) VALUES ('ecausley')
	INSERT INTO @TechUsers (Username) VALUES ('kgriffis')
	INSERT INTO @TechUsers (Username) VALUES ('pscammel')
	INSERT INTO @TechUsers (Username) VALUES ('jenglish')
	INSERT INTO @TechUsers (Username) VALUES ('pwilliams')
	INSERT INTO @TechUsers (Username) VALUES ('doliver')
	INSERT INTO @TechUsers (Username) VALUES ('mharris')
	--INSERT INTO @TechUsers (Username) VALUES ('glindsey')
	*/
	INSERT INTO @TechUsers (Username)
	Select u.UserName
	From aspnet_Users u
	Join aspnet_Applications app on app.ApplicationId = u.ApplicationId
	Join aspnet_UsersInRoles uir on u.UserId = uir.UserId
	Join aspnet_Roles r on r.RoleId = uir.RoleId
	Where app.ApplicationName = 'DMS'
	and r.RoleName = 'RVTech'


	IF OBJECT_ID('tempdb..#tmpClickToCallEvents') IS NOT NULL
		Drop table #tmpClickToCallEvents
	IF OBJECT_ID('tempdb..#tmpSREvents') IS NOT NULL
		Drop table #tmpSREvents
	IF OBJECT_ID('tempdb..#tmpSRTime') IS NOT NULL
		Drop table #tmpSRTime
	IF OBJECT_ID('tempdb..#tmpSRTimeDispatch') IS NOT NULL
		Drop table #tmpSRTimeDispatch
	IF OBJECT_ID('tempdb..#tmpSRTTech') IS NOT NULL
		Drop table #tmpSRTTech


	Select el.CreateDate, el.CreateBy
	Into #tmpClickToCallEvents
	From EventLog el (NOLOCK)
	Join [Event] e (NOLOCK) on e.ID = el.EventID
	where e.Name = 'ClickToCall'
	and el.CreateDate  BETWEEN @StartDate AND @EndDate

	Create Index IDX_tmpClickToCallEvents ON #tmpClickToCallEvents(CreateDate, CreateBy)

	---- Get all completed and cancelled service requests within the date range
	;WITH wSRs
	AS
	(
	SELECT     
		c.ID CaseID
		,c.ProgramID
		,sr.id ServiceRequestID
		,pc.name AS ProductCategoryName
	FROM  ServiceRequest sr (NOLOCK)
	JOIN  [Case] c (NOLOCK) ON c.ID = sr.CaseID
	JOIN  Program p (NOLOCK) ON p.ID = c.ProgramID
	JOIN  Client cl (NOLOCK) ON cl.ID = p.ClientID
	LEFT JOIN   ProductCategory pc (NOLOCK) ON pc.ID = sr.ProductCategoryID
	WHERE 
	(sr.ServiceRequestStatusID = @SRCompleteID OR sr.ServiceRequestStatusID = @SRCancelledID)
	AND sr.CreateDate BETWEEN @StartDate AND @EndDate 
	)


	---- SR Events - Attempting to get call center events only
	SELECT      W.CaseID
				,W.ProgramID
				,W.ServiceRequestID 
				,el.ID EventLogID
				,CAST(NULL as int) MatchEventLogID
				,Case WHEN el.CreateDate < '3/1/2015' AND e.Name IN ('LeaveFinishTab','SaveFinishTab') THEN 'Close'
					WHEN e.Name = 'SaveFinishTab' THEN 'Close'  
					Else 'Open' END ActionType
				--,Case WHEN e.Name = 'SaveFinishTab' THEN 'Close' Else 'Open' END ActionType
				,e.Name EventName
				,el.SessionID
				,el.CreateBy
				,el.CreateDate
				,0 IsInboundCall
				,0 IsBeginMatchedToEnd
				,CASE WHEN e.Name IN ('StartServiceRequest','OpenActiveRequest','CreateServiceRequestForInfoCall') THEN 1 ELSE 0 END IsCheckForInboundCall
				,CAST(NULL as int) InboundCallID
	INTO #tmpSREvents
	FROM  wSRs W (NOLOCK)
	JOIN  EventLogLink ell (NOLOCK) ON (ell.EntityID = @srEntityID AND ell.RecordID = W.ServiceRequestID) 
	JOIN  EventLog el (NOLOCK) ON (el.ID = ell.EventLogID) 
	JOIN [Event] e (NOLOCK) ON e.ID = el.EventID 
		AND  (e.Name IN (
			'StartServiceRequest','OpenServiceRequest','CreateServiceRequestForInfoCall' --,'ManagerOverrideOpenCase'
			,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','SaveFinishTab')
			OR
			-- ODIS Release on 3/1 introduced SaveFinishTab which is more reliable
			(el.CreateDate < '3/1/2015' AND e.Name = 'LeaveFinishTab'))
		--,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','LeaveFinishTab','SaveFinishTab')
	WHERE 
	(
	el.CreateBy IN (SELECT Username FROM @TechUsers)
	OR 
	NOT EXISTS (SELECT * FROM aspnet_Users au (NOLOCK)
	   JOIN aspnet_Applications a (NOLOCK) ON a.ApplicationId = au.ApplicationId AND a.ApplicationName = 'DMS'
	   JOIN aspnet_UsersInRoles uir (NOLOCK) ON uir.UserId = au.UserId
	   JOIN aspnet_Roles r (NOLOCK) ON r.RoleId = uir.RoleId
	   WHERE au.Username = el.CreateBy
	   AND r.RoleName IN (
			'VendorMgr'
			,'VendorRep'
			,'ClientRelationsMgr'
			,'ClientRelations'
			,'DispatchAdmin'
			,'ClaimsMgr'
			,'Claims'
			,'Accounting'
			,'InvoiceEntry'
			,'SysAdmin'
			,'AccountingMgr')
	  )
	)
	
	/*  TOOK OUT CASE EVENTS GOING FORWARD DUE TO CODE FIX
	---- Case Events - Attempting to get call center events only
	---- Most events are related to just the SR, but some are linked to Case
	UNION
	SELECT      W.CaseID
				,W.ProgramID
				,W.ServiceRequestID 
				,el.ID EventLogID
				,CAST(NULL as int) MatchEventLogID
				,Case WHEN e.Name IN ('LeaveFinishTab','SaveFinishTab') THEN 'Close' Else 'Open' END ActionType
				--,Case WHEN e.Name = 'SaveFinishTab' THEN 'Close' Else 'Open' END ActionType
				,e.Name EventName
				,el.SessionID
				,el.CreateBy
				,el.CreateDate
				,0 IsInboundCall
				,0 IsBeginMatchedToEnd
				,CASE WHEN e.Name IN ('StartServiceRequest','OpenActiveRequest') THEN 1 ELSE 0 END IsCheckForInboundCall
				,CAST(NULL as int) InboundCallID
	FROM  wSRs W (NOLOCK)
	JOIN  EventLogLink ell (NOLOCK) ON (ell.EntityID = @CaseEntityID AND ell.RecordID = W.CaseID)
	JOIN  EventLog el (NOLOCK) ON (el.ID = ell.EventLogID) 
	JOIN [Event] e (NOLOCK) ON e.ID = el.EventID 
		AND  (e.Name IN (
			'StartServiceRequest','OpenServiceRequest','CreateServiceRequestForInfoCall' --,'ManagerOverrideOpenCase'
			,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','SaveFinishTab')
			OR
			-- ODIS Release on 3/1 introduced SaveFinishTab which is more reliable
			(el.CreateDate < '3/1/2015' AND e.Name = 'LeaveFinishTab'))
		--,'OpenActiveRequest','OpenedLockedRequestBecauseNotOnline','LeaveFinishTab','SaveFinishTab')
	WHERE 
	(
	el.CreateBy IN (SELECT Username FROM @TechUsers)
	OR 
	NOT EXISTS (SELECT * FROM aspnet_Users au (NOLOCK)
	   JOIN aspnet_Applications a (NOLOCK) ON a.ApplicationId = au.ApplicationId AND a.ApplicationName = 'DMS'
	   JOIN aspnet_UsersInRoles uir (NOLOCK) ON uir.UserId = au.UserId
	   JOIN aspnet_Roles r (NOLOCK) ON r.RoleId = uir.RoleId
	   WHERE au.Username = el.CreateBy
	   AND r.RoleName IN (
			'VendorMgr'
			,'VendorRep'
			,'ClientRelationsMgr'
			,'ClientRelations'
			,'DispatchAdmin'
			,'ClaimsMgr'
			,'Claims'
			,'Accounting'
			,'InvoiceEntry'
			,'SysAdmin'
			,'AccountingMgr')
	  )
	)
	*/
	
	ORDER BY ServiceRequestID, CreateDate

	CREATE NONCLUSTERED INDEX IDX_tmpSREvents ON #tmpSREvents (ServiceRequestID, ActionType, CreateDate)
	CREATE NONCLUSTERED INDEX IDX_tmpSREvents_EventLogID ON #tmpSREvents (EventLogID)


	---- Adjust the OPEN event to the related Inbound call 
	Update sre1 SET InboundCallID = InBoundCallMatch.InboundCallID
	From #tmpSREvents sre1
	Join (
		Select sre.EventLogID, MAX(ic.ID) InboundCallID
		FROM #tmpSREvents sre
		Join InboundCall ic (NOLOCK) on ic.CaseID = sre.CaseID and ic.CreateBy = sre.CreateBy and ic.CreateDate < sre.CreateDate and DATEDIFF(mi, ic.CreateDate, sre.CreateDate) < 20
		Where sre.IsCheckForInboundCall = 1
		Group By sre.EventLogID
		) InBoundCallMatch ON sre1.EventLogID = InBoundCallMatch.EventLogID

	Update sre SET CreateDate = ic.CreateDate, IsInboundCall = 1	
	From #tmpSREvents sre
	Join InboundCall ic on ic.ID = sre.InboundCallID


	---- Link Open to Close
	UPDATE sre1 
	SET MatchEventLogID = 
			(SELECT MIN(sre2.EventLogID) 
			FROM #tmpSREvents sre2 
			WHERE sre2.ServiceRequestID = sre1.ServiceRequestID 
			AND sre2.CreateBy = sre1.CreateBy
			AND sre2.EventLogID > sre1.EventLogID) 
	From #tmpSREvents sre1 
	WHERE sre1.ActionType = 'OPEN' 

	-- Set IsBeginMatchedToEnd if the identified event was a Close event
	-- Need to insure that the agent did not drop out without saving and then got back in
	UPDATE sre1
	SET IsBeginMatchedToEnd = 1
	From #tmpSREvents sre1 
	JOIN #tmpSREvents sre2 ON sre2.EventLogID = sre1.MatchEventLogID AND sre2.ActionType = 'CLOSE'
	WHERE sre1.ActionType = 'OPEN'
	AND sre1.MatchEventLogID IS NOT NULL

	-- If the matched event for the same person was not a close, then clear the match and let the next step simply pair the event with the next access (below)
	UPDATE sre1
	SET MatchEventLogID = NULL, IsBeginMatchedToEnd = 0
	From #tmpSREvents sre1 
	JOIN #tmpSREvents sre2 ON sre2.EventLogID = sre1.MatchEventLogID AND sre2.ActionType <> 'CLOSE'
	WHERE sre1.ActionType = 'OPEN'
	AND sre1.MatchEventLogID IS NOT NULL


	---- Flatten out events and add TimeType based on distinct user list
	SELECT 
		sre1.ProgramID
		,sre1.ServiceRequestID
		,sre1.EventLogID BeginEventLogID
		,sre1.CreateDate BeginDate
		,sre1.CreateBy BeginUser
		,sre2.EventLogID EndEventLogID
		,sre2.CreateDate EndDate
		,sre2.CreateBy EndUser
		,CASE WHEN sre2.CreateDate IS NOT NULL THEN DATEDIFF(ss, sre1.CreateDate, sre2.CreateDate) ELSE 0 END EventSeconds
		,NULL as TechLeadTimeSeconds
		,Case WHEN sre1.CreateBy IN (SELECT Username FROM @TechUsers) THEN @TimeTypeTech ELSE @TimeTypeBackEnd END TimeTypeID
		,sre1.IsInboundCall
		--,Case WHEN sre1.CreateBy IN (SELECT Username FROM @TechUsers) THEN 1 ELSE 0 END IsTech
		,sre1.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	Into #tmpSRTime
	From #tmpSREvents sre1
	Left Outer Join #tmpSREvents sre2 on sre1.MatchEventLogID = sre2.EventLogID
	Where sre1.ActionType = 'OPEN'
	
	CREATE NONCLUSTERED INDEX IDX_tmpSRTime_SRID ON #tmpSRTime (ServiceRequestID)

		
	--update all the first entries for each SR as FrontEnd time type
	--make sure that first entry is in the temp table, may not be if adding to prior days entries
	UPDATE SRT
	SET SRT.TimeTypeID = @TimeTypeFrontEnd
	FROM #tmpSRTime SRT
	JOIN ServiceRequest SR (nolock) on SR.ID = SRT.ServiceRequestID
	WHERE 
	SRT.BeginDate <= SR.CreateDate
	AND SRT.BeginEventLogID = (SELECT Top 1 (BeginEventlogID) FROM #tmpSRTime tSRT where tSRT.ServiceRequestID = SRT.ServiceRequestID Order by BeginDate, EndDate)

	
	--Search for first time entry for each SR.  Within that timeframe search for 'EnterDispatchTab' event
	--and create new record to split the time between FrontEnd and Dispatch. If 'EnterDispatchTab' event not
	--found then don't need to split
	SELECT SRT.ProgramID
	,SRT.ServiceRequestID
		,SRT.BeginEventLogID 
		,SRT.BeginDate 
		,SRT.BeginUser 
		,SRT.EndEventLogID
		,SRT.EndDate
		,SRT.EndUser
		,EL.ID DispatchEventLogID
		,EL.CreateDate DispatchDate
		,EL.CreateBy DispatchUser
		,SRT.EventSeconds
		,NULL as TechLeadTimeSeconds
		,SRT.TimeTypeID
		,SRT.IsInboundCall
		,SRT.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	INTO #tmpSRTimeDispatch 
	FROM #tmpSRTime SRT 
	JOIN EventLogLink ell (NOLOCK) ON (ell.EntityID = @srEntityID AND ell.RecordID = SRT.ServiceRequestID) 
	JOIN  EventLog el (NOLOCK) ON 
	(el.ID = ell.EventLogID AND el.CreateBy = SRT.BeginUser AND el.createdate between SRT.BeginDate and SRT.EndDate
	and el.createdate = (SELECT Min(CreateDate) from EventLog el2 (NOLOCK)
	JOIN EventLogLink ell2 (NOLOCK) on ell2.EntityID = @srEntityID AND ell2.RecordID = SRT.ServiceREquestID 
	WHERE el2.ID = ell2.EventLogID and el2.CreateBy = SRT.BeginUser AND el.createdate between SRT.BeginDate and SRT.EndDate
	AND el2.EventID = @EnterDispatchTabEventID))
	JOIN [Event] e (NOLOCK) ON E.ID = el.EventID and el.EventID = @EnterDispatchTabEventID
	WHERE SRT.TimeTypeID = @TimeTypeFrontEnd 
	AND SRT.EndEventLogID <> EL.ID
	
	--Update first record of SR to end when EnterDispatchTab Event occurred; recalc EventSeconds
	UPDATE SRT
	SET SRT.EndEventLogID = SRTD.DispatchEventLogID,
	SRT.EndUser = SRTD.DispatchUser,
	SRT.EndDate = SRTD.DispatchDate,
	SRT.EventSeconds = CASE WHEN SRTD.DispatchDate IS NOT NULL THEN DATEDIFF(ss, SRT.BeginDate, SRTD.DispatchDate) ELSE 0 END 
	FROM #tmpSRTime SRT
	JOIN #tmpSRTimeDispatch SRTD ON SRTD.ServiceRequestID = SRT.ServiceRequestID AND SRTD.BeginEventLogID = SRT.BeginEventLogID
	
	
    --Insert new record for each dispatch event found, set type to BackEnd, calc EventSeconds
    INSERT INTO #tmpSRTime
    SELECT 
		SRTD.ProgramID
		,SRTD.ServiceRequestID
		,SRTD.DispatchEventLogID BeginEventLogID
		,SRTD.DispatchDate BeginDate
		,SRTD.DispatchUser BeginUser
		,SRTD.EndEventLogID
		,SRTD.EndDate
		,SRTD.EndUser
		,CASE WHEN SRTD.EndDate IS NOT NULL THEN DATEDIFF(ss, SRTD.DispatchDate, SRTD.EndDate) ELSE 0 END EventSeconds
		,NULL as TechLeadTimeSeconds
		,@TimeTypeBackEnd TimeTypeID
		,SRTD.IsInboundCall
		,SRTD.IsBeginMatchedToEnd
		,NULL as IssuedPOCount
		,NULL as DispatchISPCallCount
		,NULL as ServiceFacilityCallCount
		,NULL as  ClickToCallCount
	From #tmpSRTimeDispatch SRTD
		
	
	--Find every timetype = 'Tech', find prior record and calc difference between prior event end time
	--and tech record begin time.  If greater than 12 hours then TechLeadTimeSeconds = 0.  If prior record 
	--timetype = 'Tech' then TechLeadTimeSeconds = 0, else calc TechLeadTimeSeconds
	SELECT 
		SRT.ServiceRequestID ServiceRequestID
		,SRT.BeginEventLogID BeginEventLogID
		,SRT.BeginDate BeginDate
		,SRT.BeginUser BeginUser
		,SRT.EndEventLogID EndEventLogID
		,SRT.EndDate EndDate
		,SRT.EndUser EndUser
		,(SELECT MAX(SRTemp.EndDate) FROM #tmpSRTime SRTemp WHERE
			SRTemp.ServiceRequestID = SRT.ServiceRequestID 
			AND SRTemp.EndDate is not null 
			AND SRTemp.EndDate <= SRT.BeginDate
			AND SRTemp.TimeTypeID <> @TimeTypeTech) as PriorEventEndDate
	INTO #tmpSRTTech
	FROM #tmpSRTime SRT
	WHERE SRT.TimeTypeID = @TimeTypeTech
	AND SRT.EndDate is not null
	AND SRT.TechLeadTimeSeconds is null
	AND (SELECT Top 1 TimeTypeID FROM #tmpSRTime SRTemp WHERE
			SRTemp.ServiceRequestID = SRT.ServiceRequestID 
			AND SRTemp.EndDate is not null 
			AND SRTemp.EndDate <= SRT.BeginDate
			ORDER BY SRTemp.EndDate DESC) <> @TimeTypeTech
	
	
	
	UPDATE SRT
	SET TechLeadTimeSeconds = CASE WHEN SRTTech.PriorEventEndDate is not null AND (DATEDIFF(ss, ISNULL(SRTTech.PriorEventEndDate,'1/1/1900'), SRTTech.BeginDate)) < @TechLeadTimeLimitSeconds 
								THEN DATEDIFF(ss, SRTTech.PriorEventEndDate, SRTTech.BeginDate) 
								ELSE 0 END
	FROM #tmpSRTime SRT
	JOIN #tmpSRTTech SRTTech on SRTTech.ServiceRequestID = SRT.ServiceRequestID and SRTTech.BeginEventLogID = SRT.BeginEventLogID
	
	
	
	--Update counts
	UPDATE SRT
	SET IssuedPOCount = (SELECT Count(*) 
			FROM PurchaseOrder PO (NOLOCK)
			WHERE PO.ServiceRequestID = SRT.ServiceRequestID 
			AND PO.IsActive = 1 
			AND PO.PurchaseOrderNumber IS NOT NULL 
			AND PO.CreateDate between SRT.BeginDate and SRT.EndDate
			) 
		, DispatchISPCallCount = (Select Count(*) 
			From (
				Select sr.ID ServiceRequestID, cll_ISP.RecordID, cl.CreateBy, MAX(cl.CreateDate) CreateDate
				From ServiceRequest SR (NOLOCK) 
				Join ContactLogLink cll (NOLOCK) on cll.EntityID = @srEntityID and cll.RecordID = sr.ID 
				Join ContactLog cl (NOLOCK) on cl.ID = cll.ContactLogID
				Left Outer Join ContactLogLink cll_ISP (NOLOCK) on cll_ISP.ContactLogID =cl.ID and cll_ISP.EntityID = @VendorLocationEntityID 
				Join ContactLogAction cla (NOLOCK) on cla.ContactLogID = cl.ID
				Join ContactAction ca (NOLOCK) on ca.ID = cla.ContactActionID
				Join ContactCategory cc (NOLOCK) on cc.ID = cl.ContactCategoryID
				Join ContactType ct (NOLOCK) on ct.ID = cl.ContactTypeID
				Where sr.ID = SRT.ServiceRequestID
				and cl.ContactCategoryID = @ContactCategoryID_VendorSelection
				and cla.ContactActionID <> @ContactActionID_Negotiate
				Group By sr.ID, cll_ISP.RecordID, cl.CreateBy
				--Order by sr.ID, cl.ID
				) X
			Where X.ServiceRequestID = SRT.ServiceRequestID AND
				X.CreateDate BETWEEN SRT.BeginDate and SRT.EndDate
			) 
		,ServiceFacilityCallCount = (Select Count(*) 
			From (
				Select sr.ID ServiceRequestID, cll_ISP.RecordID, cl.CreateBy, MAX(cl.CreateDate) CreateDate
				From ServiceRequest SR (NOLOCK) 
				Join ContactLogLink cll (NOLOCK) on cll.EntityID = @srEntityID and cll.RecordID = sr.ID 
				Join ContactLog cl	(NOLOCK) on cl.ID = cll.ContactLogID
				Left Outer Join ContactLogLink cll_ISP (NOLOCK) on cll_ISP.ContactLogID =cl.ID and cll_ISP.EntityID = @VendorLocationEntityID 
				Join ContactLogAction cla (NOLOCK) on cla.ContactLogID = cl.ID
				Join ContactAction ca (NOLOCK) on ca.ID = cla.ContactActionID
				Join ContactCategory cc (NOLOCK) on cc.ID = cl.ContactCategoryID
				Join ContactType ct (NOLOCK) on ct.ID = cl.ContactTypeID
				Where sr.ID = SRT.ServiceRequestID
				and cl.ContactCategoryID = @ContactCategoryID_ServiceLocationSelection
				and cll_ISP.RecordID IS NOT NULL
				Group By sr.ID, cll_ISP.RecordID, cl.CreateBy
				--Order by sr.ID, cl.ID
				) X
			Where X.ServiceRequestID = SRT.ServiceRequestID AND
				X.CreateDate BETWEEN SRT.BeginDate and SRT.EndDate
			)
		,ClicktoCallcount = ISNULL((Select Count(*) ClickToCallCount
			From #tmpClickToCallEvents ctc 
			Where ctc.CreateBy = SRT.BeginUser and ctc.CreateDate between SRT.BeginDate and SRT.EndDate
			),0) 
		FROM #tmpSRTime SRT
	
	
		
	INSERT INTO dbo.ServiceRequestAgentTime
		([ProgramID]
		,[ServiceRequestID]
		,[BeginEventLogID]
		,[BeginDate]
		,[BeginUser]
		,[EndEventLogID]
		,[EndDate]
		,[EndUser]
		,[EventSeconds]
		,[TechLeadTimeSeconds]
		,[TimeTypeID]
		,[IsInboundCall]
		,[IsBeginMatchedToEnd]
		,[IssuedPOCount]
		,[DispatchISPCallCount]
		,[ServiceFacilityCallCount]
		,[ClickToCallCount])
	Select 
		[ProgramID]
		,[ServiceRequestID]
		,[BeginEventLogID]
		,[BeginDate]
		,[BeginUser]
		,[EndEventLogID]
		,[EndDate]
		,[EndUser]
		,[EventSeconds]
		,[TechLeadTimeSeconds]
		,[TimeTypeID]
		,[IsInboundCall]
		,[IsBeginMatchedToEnd]
		,[IssuedPOCount]
		,[DispatchISPCallCount]
		,[ServiceFacilityCallCount]
		,[ClickToCallCount]
	From #tmpSRTime tmpSrt
	WHERE NOT EXISTS (
		SELECT *
		FROM ServiceRequestAgentTime srt
		WHERE srt.ServiceRequestID = tmpSrt.ServiceRequestID
		AND srt.BeginEventLogID = tmpSrt.BeginEventLogID
		)
	ORDER BY tmpSRT.BeginDate
		
	--Select 
		--[ProgramID] = tmpSRT.ProgramID
		--,[ServiceRequestID] = tmpSrt.ServiceRequestID,
	UPDATE srt SET
		[BeginEventLogID] = tmpSrt.BeginEventLogID
		,[BeginDate] = tmpSrt.BeginDate
		,[BeginUser] = tmpSrt.BeginUser
		,[EndEventLogID] = tmpSrt.EndEventLogID
		,[EndDate] = tmpSrt.EndDate
		,[EndUser] = tmpSrt.EndUser
		,[EventSeconds] = tmpSrt.EventSeconds
		,[IsInboundCall] = tmpSrt.IsInboundCall
		,[TechLeadTimeSeconds] = tmpSrt.TechLeadTimeSeconds
		,[TimeTypeID] = tmpSrt.TimeTypeID
		,[IsBeginMatchedToEnd] = tmpSrt.IsBeginMatchedToEnd
		,[IssuedPOCount] = tmpSrt.IssuedPOCount
		,[DispatchISPCallCount] = tmpSrt.DispatchISPCallCount
		,[ServiceFacilityCallCount] = tmpSrt.ServiceFacilityCallCount
		,[ClickToCallCount] = tmpSrt.ClickToCallCount
	FROM #tmpSRTime tmpSRT
	JOIN ServiceRequestAgentTime srt on srt.ServiceRequestID = tmpSrt.ServiceRequestID AND srt.BeginEventLogID = tmpSrt.BeginEventLogID
		and srt.AccountingInvoiceBatchID IS NULL

END
GO

