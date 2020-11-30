IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_closedloop_status_update]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_closedloop_status_update] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
 -- EXEC [dbo].[dms_closedloop_status_update] 
 
 CREATE PROCEDURE [dbo].[dms_closedloop_status_update](@contactLogID INT)
 AS
 BEGIN

	/*
		If the ContactLog -> ContactCategory is Closedloop
			Set SR ->	NextAction = ManualClosedloop
						ClosedLoopStatus = SendFailure
						NextScheduleDate = Calculated based on NextAction
	*/
	DECLARE @serviceRequestID INT = NULL,
			@manualClosedLoopNextActionID INT = NULL,
			@nextActionScheduledDate DATETIME = GETDATE(),
			@defaultScheduleDateUOM VARCHAR(50) = NULL,
			@defaultScheduleDateInterval INT = NULL,
			@nextActionAssignedToUserID INT = NULL,
			@sendFailureClosedLoopStatusID INT = NULL

	SET @serviceRequestID = (SELECT RecordID 
							FROM	ContactLogLink 
							WHERE	EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest') 
							AND		ContactLogID = @contactLogID)
	SET @manualClosedLoopNextActionID =  (SELECT ID FROM NextAction WHERE Name = 'ManualClosedLoop')
	SET @sendFailureClosedLoopStatusID = (SELECT ID FROM ClosedLoopStatus WHERE Name = 'SendFailure')
		
	SELECT	@defaultScheduleDateUOM = NA.DefaultScheduleDateIntervalUOM,
			@defaultScheduleDateInterval = NA.DefaultScheduleDateInterval,
			@nextActionAssignedToUserID = NA.DefaultAssignedToUserID
	FROM	NextAction NA
	WHERE	NA.ID = @manualClosedLoopNextActionID

	IF ( @defaultScheduleDateUOM IS NOT NULL )
	BEGIN
		SET @defaultScheduleDateInterval = ISNULL(@defaultScheduleDateInterval,0)
		SET @nextActionScheduledDate = ( SELECT CASE @defaultScheduleDateUOM 
													WHEN 'seconds' THEN DATEADD(SECOND,@defaultScheduleDateInterval,@nextActionScheduledDate)
													WHEN 'minutes' THEN DATEADD(MINUTE,@defaultScheduleDateInterval,@nextActionScheduledDate)
													WHEN 'hours' THEN DATEADD(HOUR,@defaultScheduleDateInterval,@nextActionScheduledDate)
													WHEN 'days' THEN DATEADD(DAY,@defaultScheduleDateInterval,@nextActionScheduledDate)
													WHEN 'months' THEN DATEADD(MONTH,@defaultScheduleDateInterval,@nextActionScheduledDate)
													ELSE @nextActionScheduledDate END )

	END


	IF ( (SELECT CC.Name FROM ContactLog CL JOIN ContactCategory CC ON CL.ContactCategoryID = CC.ID WHERE CL.ID = @contactLogID) = 'Closedloop')
	BEGIN
	
		UPDATE	ServiceRequest
		SET		ClosedLoopStatusID = @sendFailureClosedLoopStatusID,
				NextActionID = @manualClosedLoopNextActionID,
				NextActionScheduledDate = @nextActionScheduledDate,
				NextActionAssignedToUserID = @nextActionAssignedToUserID,
				ModifyDate = GETDATE(),
				ModifyBy = 'system'
		WHERE	ID = @serviceRequestID

	END

 END

 GO