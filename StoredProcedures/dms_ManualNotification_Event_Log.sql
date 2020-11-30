IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_ManualNotification_Event_Log]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_ManualNotification_Event_Log] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_ManualNotification_Event_Log] 'SSMS','SSMS','Manual notification','kbanda',1,'AE05306D-492D-4944-B8BA-8E90BE11F393,BEB5FA18-50CE-499D-BB62-FFB9585242AB'
CREATE PROCEDURE [dbo].[dms_ManualNotification_Event_Log](
	@eventSource NVARCHAR(255) = NULL,
	@sessionID NVARCHAR(255) = NULL,
	@message NVARCHAR(MAX) = NULL,
	@createBy NVARCHAR(50) = NULL,
	@recipientTypeID INT = NULL,
	@autoCloseDelay INT = 0,
	@toUserOrRoleIDs NVARCHAR(MAX) = NULL -- CSV of ASPNET_UserIds / RoleIds
)
AS
BEGIN
 
	DECLARE @tmpUsers TABLE
	(
		ID INT IDENTITY(1,1),
		UserID INT NULL,
		aspnet_UserID UNIQUEIDENTIFIER NULL
	)

	DECLARE @eventLogID INT,
			@idx INT = 1,
			@maxRows INT = 0,
			@userEntityID INT

	SET @userEntityID = (SELECT ID FROM Entity WHERE Name = 'User')

	SET @message =	REPLACE( REPLACE( REPLACE(REPLACE(@message,'&','&amp;'),'<','&lt;'), '>','&gt;'),'''','&quot;')

	IF ( @recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'User') )
	BEGIN
		
		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_Users AU WITH (NOLOCK) ON T.item = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId
		

	END
	ELSE IF (@recipientTypeID = (SELECT ID FROM NotificationRecipientType WHERE Name = 'Role'))
	BEGIN

		INSERT INTO @tmpUsers (UserID, aspnet_UserID)
		SELECT	DISTINCT U.ID,
				AU.UserId
		FROM	[dbo].[fnSplitString](@toUserOrRoleIDs,',') T
		JOIN	aspnet_UsersInRoles UIR WITH (NOLOCK) ON T.item = UIR.RoleId
		JOIN	aspnet_Users AU WITH (NOLOCK) ON UIR.UserId = AU.UserId
		JOIN	[User] U WITH (NOLOCK) ON  U.aspnet_UserID = AU.UserId

	END


	INSERT INTO EventLog (	EventID,
							SessionID,
							[Source],
							[Description],
							Data,
							NotificationQueueDate,
							CreateDate,
							CreateBy
						)
	SELECT	(SELECT ID FROM [Event] WHERE Name = 'ManualNotification'),
			@sessionID,
			@eventSource,
			(SELECT [Description] FROM [Event] WHERE Name = 'ManualNotification'),
			'<MessageData><SentFrom>' + ISNULL(@createBy,'') + '</SentFrom><MessageText>' + ISNULL(@message,'') + '</MessageText><AutoClose>' + CONVERT(NVARCHAR(100),ISNULL(@autoCloseDelay,0))  + '</AutoClose></MessageData>',
			NULL,
			GETDATE(),
			@createBy

	SET @eventLogID = SCOPE_IDENTITY()
	SELECT @maxRows = MAX(ID) FROM @tmpUsers

	-- Create EventLogLinks
	WHILE (@idx <= @maxRows)
	BEGIN

		INSERT INTO EventLogLink(	EntityID,
									EventLogID,
									RecordID
								)
		SELECT	@userEntityID,
				@eventLogID,
				T.UserID
		FROM	@tmpUsers T WHERE T.ID = @idx

		SET @idx = @idx + 1

	END

END

