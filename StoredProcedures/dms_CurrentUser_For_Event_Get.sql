IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_CurrentUser_For_Event_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_CurrentUser_For_Event_Get] 72237,4
CREATE PROCEDURE [dbo].[dms_CurrentUser_For_Event_Get](
	@eventLogID INT,
	@eventSubscriptionID INT
)
AS
BEGIN
 
	/*
		Assumption : This stored procedure would be executed for DesktopNotifications.
		Logic : 
		If the event is SendPOFaxFailure - Determine the current user as follows:
			1.	Parse EL.Data and pull out <ServiceRequest><SR.ID>  </ServiceRequest>
			2.	Join to Case from that SR.ID and get Case.AssignedToUserID
			3.	Insert one CommunicatinQueue record
			4.	If this value is blank try next one
			iv.	If no current user assigned
			1.	Parse EL.Data and pull out <CreateByUser><username></CreateByUser>
			2.	Check to see if that <username> is online
			3.	If online then Insert one CommunicatinQueue record for that user
			v.	If still no user found or online, then check the Service Request and if the NextAction fields are blank.  If blank then:
			1.	Update the associated ServiceRequest next action fields.  These will be displayed on the Queue prompting someone to take action and re-send the PO
			a.	Set ServiceRequest.NextActionID = Re-send PO
			b.	Set ServiceRequest.NextActionAssignedToUserID = ‘Agent User’

		If the event is ManualNotification, determine the curren user(s) as follows: 
			1. Get the associated EventLogLinkRecords.
			2. For each of the link records:
				2.1 If the related entity on the link record is a user and the user is online, add the user details to the list.
				
		If the event is not SendPOFaxFailure - CurrentUser = ServiceRequest.Case.AssignedToUserID.
	*/

	DECLARE @eventName NVARCHAR(255),
			@eventData XML,
			@PONumber NVARCHAR(100),
			@ServiceRequest INT,
			@FaxFailureReason NVARCHAR(MAX),
			@CreateByUser NVARCHAR(50),

			@assignedToUserIDOnCase INT,
			@nextActionIDOnSR INT,
			@nextActionAssignedToOnSR INT,
			@resendPONextActionID INT,
			@agentUserID INT,
			@nextActionPriorityID INT = NULL,
			@defaultScheduleDateInterval INT = NULL,
			@defaultScheduleDateIntervalUOM NVARCHAR(50) = NULL

	DECLARE @tmpCurrentUser TABLE
			(
				UserId UNIQUEIDENTIFIER NULL,
				UserName NVARCHAR(100) NULL
			)
	

	SELECT  @resendPONextActionID = ID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'
	SELECT	@nextActionPriorityID = DefaultPriorityID FROM NextAction WITH (NOLOCK) WHERE Name = 'ResendPO'

	IF (@nextActionPriorityID IS NULL)
	BEGIN
		SELECT @nextActionPriorityID = (SELECT ID FROM ServiceRequestPriority WITH (NOLOCK) WHERE Name = 'Normal')
	END


	SELECT	@defaultScheduleDateInterval	= ISNULL(DefaultScheduleDateInterval,0),
			@defaultScheduleDateIntervalUOM = DefaultScheduleDateIntervalUOM
	FROM	NextAction WITH (NOLOCK)
	WHERE	ID = @resendPONextActionID


	--SELECT	@agentUserID = U.ID
	--FROM	[User] U WITH (NOLOCK) 
	--JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
	--JOIN	aspnet_Applications A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
	--WHERE	AU.UserName = 'Agent'
	--AND		A.ApplicationName = 'DMS'

	SELECT	@eventData = EL.Data
	FROM	EventLog EL WITH (NOLOCK)
	JOIN	Event E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	EL.ID = @eventLogID

	SELECT	@eventName = E.Name
	FROM	EventSubscription ES WITH (NOLOCK) 
	JOIN	Event E WITH (NOLOCK) ON ES.EventID = E.ID
	WHERE	ES.ID = @eventSubscriptionID	
	
	

	SELECT	@PONumber = (SELECT  T.c.value('.','NVARCHAR(100)') FROM @eventData.nodes('/MessageData/PONumber') T(c)),
		@ServiceRequest = (SELECT  T.c.value('.','INT') FROM @eventData.nodes('/MessageData/ServiceRequest') T(c)),
		@FaxFailureReason = (SELECT  T.c.value('.','NVARCHAR(MAX)') FROM @eventData.nodes('/MessageData/FaxFailureReason') T(c)),
		@CreateByUser = (SELECT  T.c.value('.','NVARCHAR(50)') FROM @eventData.nodes('/MessageData/CreateByUser') T(c))
		
	SELECT	@assignedToUserIDOnCase = C.AssignedToUserID
	FROM	[Case] C WITH (NOLOCK)
	JOIN	[ServiceRequest] SR WITH (NOLOCK) ON SR.CaseID = C.ID
	WHERE	SR.ID = @ServiceRequest

	IF (@eventName = 'SendPOFaxFailed')
	BEGIN	
				
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN
			PRINT 'AssignedToUserID On Case is not null'
			-- Return the user details.
			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.UserName
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	U.ID = @assignedToUserIDOnCase

		END
		ELSE 
		BEGIN
			-- TFS: 390
			--IF ( (SELECT [dbo].[fnIsUserConnected](@CreateByUser) ) = 1)
			--BEGIN
				
			--	INSERT INTO @tmpCurrentUser
			--	SELECT	AU.UserId,
			--			AU.UserName
			--	FROM	aspnet_Users AU WITH (NOLOCK) 
			--	JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId			
			--	WHERE	AU.UserName = @CreateByUser
			--	AND		A.ApplicationName = 'DMS'
				
			--END
			--ELSE
			--BEGIN
			PRINT 'AssignedToUserID On Case is null'
				SELECT	@nextActionIDOnSR = SR.NextActionID,
						@nextActionAssignedToOnSR = SR.NextActionAssignedToUserID
				FROM	ServiceRequest SR WITH (NOLOCK) 
				WHERE ID = @ServiceRequest 

				--IF @nextActionAssignedToOnSR IS NULL AND @nextActionIDOnSR IS NULL
				BEGIN
					PRINT 'Setting service request attributes'
					UPDATE	ServiceRequest
					SET		NextActionID = @resendPONextActionID,
							--TFS : 390
							NextActionAssignedToUserID = (SELECT DefaultAssignedToUserID FROM NextAction 
															WHERE ID = @resendPONextActionID 
														 ),
							ServiceRequestPriorityID = @nextActionPriorityID,
							NextActionScheduledDate =  CASE WHEN @defaultScheduleDateIntervalUOM = 'days'
																THEN DATEADD(dd,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'hours'
																THEN DATEADD(hh,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'minutes'
																THEN DATEADD(mi,@defaultScheduleDateInterval,GETDATE())
															WHEN @defaultScheduleDateIntervalUOM = 'seconds'
																THEN DATEADD(ss,@defaultScheduleDateInterval,GETDATE())
															ELSE NULL
															END
														
					WHERE	ID = @ServiceRequest

					; WITH wManagers
					AS
					(
						SELECT	DISTINCT AU.UserId,
								AU.UserName,
								[dbo].[fnIsUserConnected](AU.UserName) AS IsConnected
						FROM	aspnet_Users AU WITH (NOLOCK) 
						JOIN	aspnet_Applications A WITH (NOLOCK) ON AU.ApplicationId = A.ApplicationId
						JOIN	aspnet_Membership M WITH (NOLOCK) ON M.ApplicationId = A.ApplicationId AND ISNULL(M.IsApproved,0) = 1 AND ISNULL(M.IsLockedOut,0) = 0 AND M.UserID = AU.UserID
						JOIN	aspnet_UsersInRoles UR WITH (NOLOCK) ON UR.UserId = AU.UserId
						JOIN	aspnet_Roles R WITH (NOLOCK) ON UR.RoleId = R.RoleId AND R.ApplicationId = A.ApplicationId
						WHERE	A.ApplicationName = 'DMS'
						AND		R.RoleName = 'Manager'					
					)
					INSERT INTO @tmpCurrentUser (UserId, UserName)
					SELECT  W.UserId,
							W.UserName							
					FROM	wManagers W
					WHERE	ISNULL(W.IsConnected,0) = 1
			
				END				
		END	
	END
	
	ELSE IF (@eventName = 'ManualNotification' OR @eventName = 'LockedRequestComment')
	BEGIN
		
		DECLARE @userEntityID INT

		SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')
		;WITH wUsersFromEventLogLinks
		AS
		(
			SELECT	AU.UserId,
					AU.UserName,
					[dbo].[fnIsUserConnected](AU.UserName) IsConnected				
			FROM	EventLogLink ELL WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON ELL.RecordID = U.ID AND ELL.EntityID = @userEntityID
			JOIN	aspnet_Users AU WITH (NOLOCK) ON U.aspnet_UserID = AU.UserId
			WHERE	ELL.EventLogID = @eventLogID
		)

		INSERT INTO @tmpCurrentUser (UserId, UserName)
		SELECT	W.UserId, W.UserName
		FROM	wUsersFromEventLogLinks W
		WHERE	ISNULL(W.IsConnected,0) = 1


	END	
	ELSE
	BEGIN
		
		IF (@assignedToUserIDOnCase IS NOT NULL)
		BEGIN

			INSERT INTO @tmpCurrentUser ( UserId, UserName)
			SELECT	AU.UserId,
					AU.Username
			FROM	aspnet_Users AU WITH (NOLOCK) 
			JOIN	[User] U WITH (NOLOCK) ON AU.UserId = U.aspnet_UserID
			JOIN	[aspnet_Applications] A WITH (NOLOCK) ON A.ApplicationId = AU.ApplicationId
			WHERE	A.ApplicationName = 'DMS'
			AND		U.ID = @assignedToUserIDOnCase

		END
			
	END	

	

	SELECT UserId, Username from @tmpCurrentUser

END

GO

