CREATE VIEW [dbo].[vw_EventLogs]
AS
SELECT EL.ID EventLogID,
	   EL.EventID,
	   E.Description EventDescription,
	   EC.ID EventCategoryID,
	   EC.Description EventCategoryDescription,
	   EL.SessionID,
	   EL.Source,
	   EL.Description,
	   EL.Data,
	   EL.NotificationQueueDate,
	   EL.CreateDate,
	   EL.CreateBy,
	   SR_ELL.RecordID ServiceRequestID
 FROM	   EventLog		 EL WITH(NOLOCK)
 LEFT JOIN Event		 E  WITH(NOLOCK) ON EL.EventID = E.ID
 LEFT JOIN EventCategory EC WITH(NOLOCK) ON E.EventCategoryID = EC.ID
 LEFT OUTER JOIN EventLogLink SR_ell ON SR_ell.EventLogID = EL.ID AND SR_ell.EntityID = (SELECT ID FROM Entity WHERE Name = 'ServiceRequest')
GO

