 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dms_API_ServiceRequest_Notes_Update]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[dms_API_ServiceRequest_Notes_Update]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO 

-- EXEC [dms_API_ServiceRequest_Notes_Update] 571543,'MemberMobile','Submitted','Dispatch',NULL,'sysadmin','TEST','sysadmin'
CREATE PROC [dbo].[dms_API_ServiceRequest_Notes_Update](@serviceRequestID INT
, @sourceSystem NVARCHAR(100)
, @serviceRequestStatus NVARCHAR(100) = NULL
, @nextAction NVARCHAR(100) = NULL
, @nextActionScheduledDate DATETIME = NULL
, @nextActionAssignedToUser NVARCHAR(50) = NULL
, @note NVARCHAR(MAX) = NULL
, @userName NVARCHAR(100) = NULL
)
AS  
BEGIN  

		DECLARE @caseID INT = NULL,
				@sourceSystemID INT = NULL,
				@nextActionID INT = NULL,
				@nextActionAssignedToUserID INT = NULL,
				@serviceRequestStatusID INT = NULL,
				@priorityID INT = NULL,
				@highPriorityID INT = NULL,
				@criticalPriorityID INT = NULL,
				@commentTypeID INT = NULL

		SELECT	@commentTypeID = ID 
		FROM	CommentType WITH (NOLOCK) 
		WHERE	(@sourceSystem = 'MemberMobile' AND Name = 'MobileServiceRequest')
		OR
				(@sourceSystem <> 'MemberMobile' AND Name = 'ServiceRequest')

		SELECT @caseID = CaseID FROM [ServiceRequest] SR WITH (NOLOCK) WHERE ID = @serviceRequestID
		SELECT @sourceSystemID = ID FROM SourceSystem WITH (NOLOCK) WHERE Name = @sourceSystem
		SELECT @serviceRequestStatusID = ID FROM ServiceRequestStatus WITH (NOLOCK) WHERE Name = @serviceRequestStatus
		SELECT	@nextActionID = ID,
				@priorityID = DefaultPriorityID
		FROM	NextAction WITH (NOLOCK) WHERE Name = @nextAction

		SELECT	@nextActionAssignedToUserID = U.ID
		FROM	aspnet_users AU WITH (NOLOCK)
		JOIN	[User] U WITH (NOLOCK) ON AU.UserID = U.aspnet_UserID
		JOIN	[aspnet_Applications] A ON A.ApplicationId = AU.ApplicationId
		WHERE	AU.UserName = @nextActionAssignedToUser
		AND		A.ApplicationName = 'DMS'

		SELECT @highPriorityID = ID FROM ServiceRequestPriority where Name = 'High'
		SELECT @criticalPriorityID = ID FROM ServiceRequestPriority where Name = 'Critical'

		UPDATE	[Case]
		SET		SourceSystemID = @sourceSystemID
		WHERE	ID = @caseID

		
		UPDATE	ServiceRequest
		SET		ServiceRequestStatusID =  CASE	WHEN @serviceRequestStatusID	IS NULL 
												THEN ServiceRequestStatusID 
												ELSE @serviceRequestStatusID 
											END,
				NextActionID = @nextActionID,
				NextActionAssignedToUserID = @nextActionAssignedToUserID,
				NextActionScheduledDate = CASE	WHEN @nextActionID IS NOT NULL AND @nextActionScheduledDate IS NOT NULL
												THEN @nextActionScheduledDate
												ELSE GETDATE()
												END,
				ServiceRequestPriorityID = CASE WHEN @priorityID IS NOT NULL AND ServiceRequestPriorityID NOT IN (@highPriorityID,@criticalPriorityID)
												THEN @priorityID
												ELSE ServiceRequestPriorityID
												END
		WHERE	ID = @serviceRequestID


		-- Comments
		IF @note IS NOT NULL
		BEGIN
			INSERT INTO Comment (CommentTypeID, EntityID, RecordID, Description, CreateDate, CreateBy)
			SELECT	@commentTypeID,
					(SELECT ID FROM Entity WITH (NOLOCK) WHERE Name = 'ServiceRequest'),
					@serviceRequestID,
					@note,
					GETDATE(),
					@userName
		END
END