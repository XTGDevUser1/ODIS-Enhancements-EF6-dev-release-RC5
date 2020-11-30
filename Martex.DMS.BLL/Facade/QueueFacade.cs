using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using System.Transactions;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.DAL.DMSBaseException;
using log4net;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.Entities;
using System.Collections;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Maintain Queue
    /// </summary>
    public class QueueFacade
    {
        #region Private Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(QueueFacade));
        #endregion

        #region Public Methods
        /// <summary>
        /// get the queue list of the specific user.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pc">The page criteria.</param>
        /// <returns>
        /// List of queues
        /// </returns>
        public List<Queue_Result> List(Guid userId, PageCriteria pc)
        {
            logger.InfoFormat("QueueFacade - List(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                userId = userId,
                PageCriteria = pc
            }));
            QueueRepository repository = new QueueRepository();
            return repository.Search(userId, pc);
        }

        /// <summary>
        /// Gets the question answer for service request.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<QuestionAnswer_ServiceRequest_Result> GetQuestionAnswerForServiceRequest(int serviceRequestID, string sourceSystemName = SourceSystemName.DISPATCH)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetQuestionAnswerServiceRequest(serviceRequestID, sourceSystemName).ToList();
            }
        }

        /// <summary>
        /// Gets the specified service request
        /// </summary>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <param name="fromStartCall">if set to <c>true</c> [from start call].</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns>
        /// Service Request
        /// </returns>
        /// <exception cref="DMSException"></exception>
        public List<ServiceRequest_Result> Get(string loggedInUserName, string eventSource, int? inboundCallId, string serviceRequestId, bool fromStartCall, string sessionID)
        {
            if (string.IsNullOrEmpty(serviceRequestId))
            {
                return null;
            }
            else
            {
                int requestId = int.Parse(serviceRequestId);
                if (fromStartCall)
                {
                    using (TransactionScope tran = new TransactionScope())
                    {
                        //For Event Log
                        EventLogRepository eventLogRepository = new EventLogRepository();
                        IRepository<Event> eventRepository = new EventRepository();
                        Event theEvent = eventRepository.Get<string>(EventNames.OPEN_SERVICE_REQUEST);

                        if (theEvent == null)
                        {
                            throw new DMSException(string.Format("Invalid event name : {0}", EventNames.OPEN_SERVICE_REQUEST));
                        }
                        EventLog eventLog = new EventLog();
                        eventLog.Source = eventSource;
                        eventLog.EventID = theEvent.ID;
                        eventLog.SessionID = sessionID;
                        eventLog.Description = "Open Service Request";
                        eventLog.CreateDate = DateTime.Now;
                        eventLog.CreateBy = loggedInUserName;
                        logger.InfoFormat("Trying to log the event {0}", EventNames.OPEN_SERVICE_REQUEST);
                        long eventLogId = eventLogRepository.Add(eventLog, inboundCallId, EntityNames.INBOUND_CALL);
                        eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.SERVICE_REQUEST, requestId);
                        tran.Complete();
                       // logger.Info("Created event log and two link records successfully");
                    }
                }
                logger.InfoFormat("Get service request details from db for SR ID {0}",requestId);
                QueueRepository repository = new QueueRepository();
                return repository.GetServiceRequest(requestId);
            }
        }

        /// <summary>
        /// Gets the user depending on the user id.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <returns></returns>
        public User getUser(string userId)
        {
            if (!string.IsNullOrEmpty(userId))
            {
                UserRepository userRepository = new UserRepository();
                return userRepository.GetUser(new Guid(userId));
            }
            else
            {
                return null;
            }
        }

        /// <summary>
        /// Gets the case.
        /// </summary>
        /// <param name="caseId">The case id.</param>
        /// <returns></returns>
        public Case GetCase(string caseId)
        {
            if (!string.IsNullOrEmpty(caseId))
            {
                QueueRepository repository = new QueueRepository();
                return repository.GetCase(int.Parse(caseId));
            }
            else
            {
                return null;
            }
        }

        /// <summary>
        /// Updates the case.
        /// </summary>
        /// <param name="caseRecord">The case record.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="eventDetails">The event details.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <exception cref="System.Exception">Invalid event name</exception>
        public void UpdateCase(Case caseRecord,int serviceRequestID,int? newAssignedTo, string eventSource, string eventName, string eventDetails, string userName, string sessionID, ServiceRequestAgentTime srAgentTime)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                QueueRepository repository = new QueueRepository();
                repository.UpdateCase(caseRecord, newAssignedTo);

                EventLog eventLog = new EventLog();
                eventLog.CreateBy = userName;
                eventLog.CreateDate = DateTime.Now;
                eventLog.Description = eventDetails;
                eventLog.Source = eventSource;
                eventLog.SessionID = sessionID;

                IRepository<Event> eventRepository = new EventRepository();
                Event theEvent = eventRepository.Get<string>(eventName);

                if (theEvent == null)
                {
                    throw new Exception("Invalid event name");
                }

                eventLog.EventID = theEvent.ID;

                EventLogRepository eventLogRepository = new EventLogRepository();
                long eventLogId = eventLogRepository.Add(eventLog, caseRecord.ID, EntityNames.CASE);
                eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.SERVICE_REQUEST, serviceRequestID);

                eventLogRepository.LogEventForServiceRequestStatus(serviceRequestID, EventNames.DISPATCH_IN_PROCESS, eventSource, null, sessionID, userName);
                logger.InfoFormat("Logged service request status event {0}", EventNames.DISPATCH_IN_PROCESS);

                var srAgentTimeRepository = new SRAgentTimeRepository();
                if (srAgentTime.BeginDate == null)
                {
                    srAgentTime.BeginDate = DateTime.Now;
                }
                srAgentTime.BeginEventLogID = eventLogId;
                srAgentTime.ServiceRequestID = serviceRequestID;
                srAgentTime.UserName = userName;

                srAgentTimeRepository.Create(srAgentTime);

                tran.Complete();
            }
        }

        //Lakshmi - Queue Color

        public void ResetQueueStatusList()
        {
            QueueRepository.GetQueueStatusList();
        }

        public void SaveServiceRequestLockedComments(int servicerequestId, string comments, bool sendnotification, string currentUser, string eventSource, string sessionID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    var commentFacade = new CommentFacade();
                    commentFacade.Save(CommentTypeNames.LOCKED_REQUEST, EntityNames.SERVICE_REQUEST, servicerequestId, comments, currentUser);

                    if (sendnotification)
                    {
                        EventLoggerFacade eventfacade = new EventLoggerFacade();

                        Hashtable ht = new Hashtable();
                        ht.Add("CommentType", "Locked Request Comment");
                        ht.Add("SentFrom", currentUser);
                        ht.Add("MessageText", comments);
                        ht.Add("RequestNumber", servicerequestId.ToString());

                        long eventId = eventfacade.LogEvent(eventSource, EventNames.LOCKED_REQUEST_COMMENT, ht.GetMessageData(), currentUser, sessionID);

                        //Event log link for service request
                        eventfacade.CreateRelatedLogLinkRecord(eventId, servicerequestId, EntityNames.SERVICE_REQUEST);
                        QueueRepository repository = new QueueRepository();
                        int? assignedtouserId = repository.GetAssignedToUserId(servicerequestId);
                        if (assignedtouserId != null)
                        {
                            eventfacade.CreateRelatedLogLinkRecord(eventId, assignedtouserId, EntityNames.USER);
                        }

                    }
                    tran.Complete();
                }
                catch (Exception ex)
                {
                    logger.Warn("Error while saving data during SaveServiceRequestLockedComments", ex);
                    throw ex;
                }

            }
        }

        #endregion
    }
}
