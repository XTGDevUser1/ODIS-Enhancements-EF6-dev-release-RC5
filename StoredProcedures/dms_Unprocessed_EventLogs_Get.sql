IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Unprocessed_EventLogs_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Unprocessed_EventLogs_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
-- EXEC [dbo].[dms_Unprocessed_EventLogs_Get] 
CREATE PROCEDURE [dbo].[dms_Unprocessed_EventLogs_Get]
AS
BEGIN

	SELECT	EL.ID,
			EventID,
			SessionID,
			Source,
			EL.[Description],
			[Data],
			NotificationQueueDate,
			EL.CreateDate,
			EL.CreateBy,			
			EventTypeID,
			EventCategoryID,
			E.Name,
			E.[Description] AS EventDescription
	FROM	[EventLog] EL WITH (NOLOCK) 
	JOIN	[Event] E WITH (NOLOCK) ON EL.EventID = E.ID
	WHERE	NotificationQueueDate IS NULL
	ORDER BY CreateDate ASC
	

END