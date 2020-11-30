using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;
using log4net;
using System.Data.Entity;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class EventLogRepository
    {

        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(EventLogRepository));
        #endregion

        /// <summary>
        /// Gets all.
        /// </summary>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public List<EventLog> GetAll()
        {
            throw new NotImplementedException();
        }
        /// <summary>
        /// Creates the link record.
        /// </summary>
        /// <param name="eventLogId">The event log id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="relatedRecordId">The related record id.</param>
        /// <exception cref="DMSException">Invalid Entity name supplied while logging an event :  + entityName</exception>
        public void CreateLinkRecord(long eventLogId, string entityName, int? relatedRecordId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                EventLogLink eventLogLink = new EventLogLink();
                Entity theEntity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (theEntity == null)
                {
                    throw new DMSException("Invalid Entity name supplied while logging an event : " + entityName);
                }

                eventLogLink.EntityID = theEntity.ID;
                eventLogLink.EventLogID = eventLogId;
                eventLogLink.RecordID = relatedRecordId;
                logger.InfoFormat("Trying add a link for the Event Log ID : {0}, EntityName :{1}, Related Record ID : {2}", eventLogId, entityName, relatedRecordId);
                dbContext.EventLogLinks.Add(eventLogLink);
                dbContext.SaveChanges();
                logger.InfoFormat("Added a link for the Event Log ID : {0}, EntityName :{1}, Related Record ID : {2}, Generated ID is : {3}", eventLogId, entityName, relatedRecordId, eventLogLink.ID);
            }
        }
        /// <summary>
        /// Adds the specified event log.
        /// </summary>
        /// <param name="eventLog">The event log.</param>
        /// <param name="relatedRecordID">The related record ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Invalid Entity name supplied while logging an event</exception>
        public long Add(EventLog eventLog, int? relatedRecordID = null, string entityName = null)
        {
            long eventLogID = 0;
            using (DMSEntities dbContext = new DMSEntities())
            {

                dbContext.EventLogs.Add(eventLog);
                dbContext.Entry(eventLog).State = EntityState.Added;
                dbContext.SaveChanges();
                logger.InfoFormat("EventLog created successfully with ID : {0}", eventLog.ID);
                if (relatedRecordID != null & relatedRecordID > 0 && entityName != null)
                {
                    EventLogLink eLogLink = new EventLogLink();
                    Entity theEntity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                    if (theEntity == null)
                    {
                        throw new DMSException("Invalid Entity name supplied while logging an event");
                    }
                    eLogLink.EntityID = theEntity.ID;
                    eLogLink.RecordID = relatedRecordID;
                    eLogLink.EventLog = eventLog;
                    logger.InfoFormat("Trying add a link for the Event Log ID : {0}, EntityName :{1}, Related Record ID : {2}", eventLog.ID, entityName, relatedRecordID);
                    dbContext.EventLogLinks.Add(eLogLink);
                    dbContext.SaveChanges();
                    logger.InfoFormat("Added a link for the Event Log ID : {0}, EntityName :{1}, Related Record ID : {2}, Generated ID is : {3}", eventLog.ID, entityName, relatedRecordID, eLogLink.ID);
                }

                dbContext.SaveChanges();
                eventLogID = eventLog.ID;
            }
            return eventLogID;

        }



        /// <summary>
        /// Gets the unprocessed logs sorted by CreateDate.
        /// </summary>
        /// <returns>List of unprocessed event log records</returns>
        public List<EventLog> GetUnprocessedLogs()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetUnprocessedEventLogs().ToList<GetUnprocessedEventLogs_Result>();
                var result = new List<EventLog>();

                list.ForEach(l =>
                    {
                        var eventLog = new EventLog()
                        {
                            ID = l.ID,
                            CreateBy = l.CreateBy,
                            CreateDate = l.CreateDate,
                            Data = l.Data,
                            Description = l.Description,
                            EventID = l.EventID,
                            NotificationQueueDate = l.NotificationQueueDate,
                            SessionID = l.SessionID,
                            Source = l.Source
                        };

                        var evt = new Event()
                        {
                            Description = l.EventDescription,
                            EventCategoryID = l.EventCategoryID,
                            EventTypeID = l.EventTypeID,
                            ID = l.EventTypeID,
                            Name = l.Name
                        };

                        eventLog.Event = evt;

                        result.Add(eventLog);
                    });
                return result;
            }
        }

        /// <summary>
        /// Updates the queue date on Event log record.
        /// </summary>
        /// <param name="log">The event log record to be updated</param>
        public void UpdateQueueDate(EventLog log)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var logFromDB = dbContext.EventLogs.Where(x => x.ID == log.ID).FirstOrDefault();

                if (logFromDB != null)
                {
                    logFromDB.NotificationQueueDate = DateTime.Now;
                    dbContext.Entry(logFromDB).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }
        /// <summary>
        /// Resets the queue date on Event log record.
        /// </summary>
        /// <param name="log">The event log record to be updated</param>
        public void ResetQueueDate(EventLog log)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var logFromDB = dbContext.EventLogs.Where(x => x.ID == log.ID).FirstOrDefault();

                if (logFromDB != null)
                {
                    logFromDB.NotificationQueueDate = null;
                    dbContext.Entry(logFromDB).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Updates the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <exception cref="System.NotImplementedException"></exception>
        public void Update(EventLog entity)
        {
            throw new NotImplementedException();
        }
        /// <summary>
        /// Deletes the specified id.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <exception cref="System.NotImplementedException"></exception>
        public void Delete<T1>(T1 id)
        {
            throw new NotImplementedException();
        }
        /// <summary>
        /// Gets the specified id.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public EventLog Get<T1>(T1 id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var eventLogId = (long)(object)id;
                var eventLog = dbContext.EventLogs.Include(x => x.Event).Where(e => e.ID == eventLogId).FirstOrDefault();
                return eventLog;
            }
        }

        public void LogManualNotificationEvent(string eventSource, string sessionID, string message, string createBy, int? recipientTypeID, int? autoCloseDelay, string toUserOrRoleIDs)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.LogManualNotificationEvent(eventSource, sessionID, message, createBy, recipientTypeID, autoCloseDelay, toUserOrRoleIDs);

            }
        }

        /// <summary>
        /// Does the event log link exists.
        /// </summary>
        /// <param name="recordId">The record identifier.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="eventName">Name of the event.</param>
        /// <returns></returns>
        public bool DoesEventLogLinkExists(int recordId, string entityName, string eventName)
        {
            bool eventLogLinkExists = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<DoesEventLogLinkExists_Result> list = dbContext.DoesEventLogLinkExists(recordId, entityName, eventName).ToList<DoesEventLogLinkExists_Result>();
                if (list != null && list.Count > 0)
                {
                    eventLogLinkExists = true;
                }
            }
            return eventLogLinkExists;
        }

        /// <summary>
        /// Logs the event for service request status.
        /// </summary>
        /// <param name="serviceRequestId">The service request identifier.</param>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="eventData">The event data.</param>
        /// <param name="sessionID">The session identifier.</param>
        public void LogEventForServiceRequestStatus(int serviceRequestId, string eventName, string eventSource, string eventData, string sessionID, string currentUser, int? poID = null)
        {
            using (var dbContext = new DMSEntities())
            {
                dbContext.LogEventForServiceRequestStatus(eventName, serviceRequestId, currentUser, eventData, sessionID, eventSource, poID);
            }

        }
    }
}
