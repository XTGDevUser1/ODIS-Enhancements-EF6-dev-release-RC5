using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.DAL.DMSBaseException;
using System.Xml;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to manage EventLogs
    /// </summary>
    public class EventLoggerFacade
    {
        #region Protected Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(EventLoggerFacade));

        #endregion

        #region Public Methods

        /// <summary>
        /// Logs the event.
        /// </summary>
        /// <param name="source">The source.</param>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="eventDetails">The event details or description (logged as XML).</param>
        /// <param name="userId">Logged in user id.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <exception cref="DMSException">Invalid event name  + eventName</exception>
        public long LogEvent(string source, string eventName, Dictionary<string, string> eventDetails, string userId, string sessionID)
        {
            if (logger.IsDebugEnabled)
            {
                logger.DebugFormat("EventLog = [Source = {0}, event name = {1}, eventDetailsCount = {2}]", source, eventName, eventDetails != null ? eventDetails.Count : 0);
            }
            // Get the Event ID from the database.
            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(eventName);

            if (theEvent == null)
            {
                throw new DMSException("Invalid event name " + eventName);
            }

            // Create an EventLog entity to be saved to database.
            EventLog eventLog = new EventLog();
            eventLog.Source = source;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            //KB: Setting the xml values to data.
            eventLog.Data = GetXML(eventDetails);
            eventLog.Description = theEvent.Description;
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = userId;

            EventLogRepository eventLogRepository = new EventLogRepository();
            logger.InfoFormat("Trying to log the event {0}", eventName);
            eventLogRepository.Add(eventLog); 
           // logger.InfoFormat("EventLog created successfully with ID : {0}", eventLog.ID);

            return eventLog.ID;

        }

        /// <summary>
        /// Log Event
        /// </summary>
        /// <param name="source"></param>
        /// <param name="eventName"></param>
        /// <param name="categoryName"></param>
        /// <param name="eventDetails"></param>
        /// <param name="userId"></param>
        /// <param name="sessionID"></param>
        /// <returns></returns>
        public long LogEvent(string source, string eventName, string categoryName, Dictionary<string, string> eventDetails, string userId, string sessionID)
        {
            if (logger.IsDebugEnabled)
            {
                logger.DebugFormat("EventLog = [Source = {0}, event name = {1}, eventDetailsCount = {2}]", source, eventName, eventDetails != null ? eventDetails.Count : 0);
            }
            // Get the Event ID from the database.
            EventRepository eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get(eventName, categoryName);

            if (theEvent == null)
            {
                throw new DMSException(string.Format("Invalid event name {0} or category {1}", eventName, categoryName));
            }

            // Create an EventLog entity to be saved to database.
            EventLog eventLog = new EventLog();
            eventLog.Source = source;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = theEvent.Description;
            eventLog.Data = GetXML(eventDetails);
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = userId;

            EventLogRepository eventLogRepository = new EventLogRepository();
            logger.InfoFormat("Trying to log the event {0}", eventName);
            eventLogRepository.Add(eventLog);

            //logger.InfoFormat("EventLog created successfully with ID : {0}", eventLog.ID);

            return eventLog.ID;

        }

        /// <summary>
        /// Logs the event.
        /// </summary>
        /// <param name="source">The source.</param>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="eventDetails">The event details.</param>
        /// <param name="userId">The user id.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Invalid event name  + eventName</exception>
        public long LogEvent(string source, string eventName, string eventDetails, string userId, string sessionID)
        {
            // Get the Event ID from the database.
            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(eventName);

            if (theEvent == null)
            {
                throw new DMSException("Invalid event name " + eventName);
            }

            // Create an EventLog entity to be saved to database.
            EventLog eventLog = new EventLog();
            eventLog.Source = source;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = eventDetails;
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = userId;

            EventLogRepository eventLogRepository = new EventLogRepository();
            logger.InfoFormat("Trying to log the event {0}", eventName);
            eventLogRepository.Add(eventLog);

            //logger.InfoFormat("EventLog created successfully with ID : {0}", eventLog.ID);
            return eventLog.ID;
        }

        /// <summary>
        /// Creates the related log link record.
        /// </summary>
        /// <param name="eventLogID">The event log ID.</param>
        /// <param name="relatedRecordId">The related record id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="sessionID">The session ID.</param>
        public void CreateRelatedLogLinkRecord(long eventLogID, int? relatedRecordId, string entityName)
        {
            EventLogRepository eventLogRepository = new EventLogRepository();
            //logger.InfoFormat("Trying add a link for the Event Log ID : {0}, EntityName :{1}, Related Record ID : {2}", eventLogID, entityName, relatedRecordId);
            eventLogRepository.CreateLinkRecord(eventLogID, entityName, relatedRecordId);
        }

        /// <summary>
        /// Logs the event.
        /// </summary>
        /// <param name="source">The source.</param>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="eventDetails">The event details.</param>
        /// <param name="userId">The user id.</param>
        /// <param name="relatedRecordId">The related record id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Invalid event name  + eventName</exception>
        public long LogEvent(string source, string eventName, string eventDetails, string userId, int? relatedRecordId, string entityName, string sessionID = null)
        {
            if (logger.IsInfoEnabled)
            {
                logger.InfoFormat("EventLog = [Source = {0}, event Name = {1}, eventDetailsCount = {2}]", source, eventName, eventDetails);
            }
            // Get the Event ID from the database.
            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(eventName);

            if (theEvent == null)
            {
                throw new DMSException("Invalid event name " + eventName);
            }

            // Create an EventLog entity to be saved to database.
            EventLog eventLog = new EventLog();
            eventLog.Source = source;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = eventDetails;
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = userId;

            EventLogRepository eventLogRepository = new EventLogRepository();
            logger.InfoFormat("Trying to log the event {0}", eventName);
            eventLogRepository.Add(eventLog, relatedRecordId, entityName);
            if (logger.IsInfoEnabled)
            {
                logger.InfoFormat("EventLog [{0}] added successfully",eventLog.ID);
            }
            return eventLog.ID;

        }


        public long LogEvent(string source, string eventName, string description, string data, string userId, int? relatedRecordId, string entityName, string sessionID = null)
        {
            if (logger.IsInfoEnabled)
            {
                logger.InfoFormat("EventLog = [Source = {0}, eventID = {1}, description = {2}", source, eventName, description);
            }
            // Get the Event ID from the database.
            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(eventName);

            if (theEvent == null)
            {
                throw new DMSException("Invalid event name " + eventName);
            }

            // Create an EventLog entity to be saved to database.
            EventLog eventLog = new EventLog();
            eventLog.Source = source;
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = description;
            eventLog.Data = data;
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = userId;

            EventLogRepository eventLogRepository = new EventLogRepository();
            logger.InfoFormat("Trying to log the event {0}", eventName);
            eventLogRepository.Add(eventLog, relatedRecordId, entityName);
            
            return eventLog.ID;

        }

        /// <summary>
        /// Gets the name of the event by name.
        /// </summary>
        /// <param name="eventName">Name of the event.</param>
        /// <returns></returns>
        public Event GetEventByName(string eventName)
        {
            IRepository<Event> eventRepository = new EventRepository();
            Event theEvent = eventRepository.Get<string>(eventName);
            return theEvent;
        }

        public void LogManualNotificationEvent(string eventSource, string sessionID, string message, string createBy, int? recipientTypeID, int? autoCloseDelay, string toUserOrRoleIDs)
        {
            var repository = new EventLogRepository();
            repository.LogManualNotificationEvent(eventSource, sessionID, message, createBy, recipientTypeID, autoCloseDelay, toUserOrRoleIDs);
        }


        #endregion

        #region Private Methods

        /// <summary>
        /// Gets the XML from a given list of name-value pairs
        /// </summary>
        /// <param name="eventDetails">List of name-value pairs</param>
        /// <returns>
        /// XML as string
        /// </returns>
        private string GetXML(Dictionary<string, string> eventDetails)
        {   
            StringBuilder sb = new StringBuilder("");
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(sb, settings))
            {
                writer.WriteStartElement("EventDetail");
                foreach (string key in eventDetails.Keys)
                {
                    string val = eventDetails[key] as string;
                    writer.WriteElementString(key, val);
                }
                writer.WriteEndElement();

                writer.Close();
            }

            return sb.ToString();

        }

        #endregion



    }
}
