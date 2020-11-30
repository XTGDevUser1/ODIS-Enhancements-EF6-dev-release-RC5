IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Notification_History_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Notification_History_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Notification_History_Get] 'demouser'
CREATE PROCEDURE [dbo].[dms_Notification_History_Get](
@userName NVARCHAR(100)
)
AS
BEGIN

	DECLARE @notificationHistoryDisplayHours INT = 48 -- Default value is set to 48.

	SELECT @notificationHistoryDisplayHours = CONVERT(INT,Value) FROM ApplicationConfiguration WHERE Name = 'NotificationHistoryDisplayHours'
	

	SELECT	CL.*
	FROM	CommunicationLog CL WITH (NOLOCK)
	JOIN	ContactMethod CM WITH (NOLOCK) ON CL.ContactMethodID = CM.ID
	WHERE	CL.NotificationRecipient = @userName
	AND		CM.Name = 'DesktopNotification'
	AND		DATEDIFF(HH,CL.CreateDate,GETDATE()) <= @notificationHistoryDisplayHours
	AND		CL.Status = 'SUCCESS'
	ORDER BY CL.CreateDate DESC

END
GO