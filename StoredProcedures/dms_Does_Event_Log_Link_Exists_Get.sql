 IF EXISTS (SELECT * FROM dbo.sysobjects 
 WHERE id = object_id(N'[dbo].[dms_Does_Event_Log_Link_Exists_Get]')   		AND type in (N'P', N'PC')) 
 BEGIN
 DROP PROCEDURE [dbo].[dms_Does_Event_Log_Link_Exists_Get] 
 END 
 GO  
 SET ANSI_NULLS ON 
 GO 
 SET QUOTED_IDENTIFIER ON 
 GO 
  -- EXEC [dms_Does_Event_Log_Link_Exists_Get] 1467,'ServiceRequest','EnteredProviderClaimNumber'
 CREATE PROCEDURE [dbo].[dms_Does_Event_Log_Link_Exists_Get](
	@recordId INT = NULL,
	@entityName NVARCHAR(100) = NULL,
	@eventName NVARCHAR(100) = NULL
)
AS 
 BEGIN  
SELECT ELL.*
FROM	EventLogLink ELL WITH (NOLOCK) 
JOIN	EventLog EL WITH(NOLOCK) ON ELL.EventLogID = EL.ID
JOIN	[Event] E WITH (NOLOCK) ON EL.EventID = E.ID
JOIN	Entity EN WITH (NOLOCK) ON ELL.EntityID = EN.ID
WHERE	E.Name = @eventName
AND		EN.Name = @entityName
AND		ELL.RecordID = @recordId

END