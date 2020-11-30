IF EXISTS (SELECT * FROM dbo.sysobjects 
WHERE id = object_id(N'[dbo].[dms_contactlog_actions_service_request_get]')   		AND type in (N'P', N'PC')) 
BEGIN
DROP PROCEDURE [dbo].[dms_contactlog_actions_service_request_get]
END 
GO  
SET ANSI_NULLS ON 
GO 
SET QUOTED_IDENTIFIER ON 
GO 
-- EXEC [dbo].[dms_contactlog_actions_service_request_get] 664653
CREATE PROC [dbo].[dms_contactlog_actions_service_request_get](
	@serviceRequestID INT
)
AS
BEGIN

	DECLARE @isActiveRequest BIT = 0

	SET @isActiveRequest = (	SELECT	COUNT(*) 
								FROM	ServiceRequest SR WITH (NOLOCK)
								JOIN	ServiceRequestStatus SRS WITH (NOLOCK) ON SR.ServiceRequestStatusID = SRS.ID
								WHERE	SR.ID = @serviceRequestID 
								AND		SRS.Name NOT IN ('Complete','Cancelled')
							)

	SELECT	CA.Name AS ContactAction, 
			CR.Name AS ContactReason, 
			CLL.ContactLogID,
			CM.Name AS ContactMethodName			
	FROM	Contactloglink CLL
	JOIN	ContactLogAction CLA WITH (NOLOCK) ON CLL.ContactLogID = CLA.ContactLogID
	JOIN	ContactLog CL WITH (NOLOCK) ON CLL.ContactLogID = CL.ID
	JOIN	ContactMethod CM WITH (NOLOCK) ON CL.ContactMethodID = CM.ID
	LEFT JOIN ContactLogReason CLR WITH (NOLOCK) ON CLL.ContactLogID = CLR.ContactLogID
	LEFT JOIN ContactReason CR WITH (NOLOCK) ON CLR.ContactReasonID = CR.ID
	JOIN	ContactAction CA WITH (NOLOCK) ON CLA.ContactActionID = CA.ID
	WHERE	Entityid = (SELECT ID FROM Entity where name = 'ServiceRequest') 
	AND		RecordID = @serviceRequestID
	AND		CA.Name IN ('Sent','SendFailure','ServiceArrived','ServiceNotArrived','NoAnswer')
	AND		@isActiveRequest = 1
	ORDER BY CLL.ContactLogID DESC

END
