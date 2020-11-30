using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using System.Transactions;
using log4net;
using Martex.DMS.BLL.Facade.EventProcessors;
using System.Configuration;
using System.Net.Http;
using Newtonsoft.Json.Linq;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade Manages Event Notifications
    /// </summary>
    public class EventNotificationFacade
    {
        #region Protected Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(EventNotificationFacade));
        protected static readonly string API_URL = ConfigurationManager.AppSettings["EVENT_NOTIFICATION_API_URL"];
        #endregion

        #region Public Methods

        /// <summary>
        /// Process the events based on the queue status event log records and event subscriptions.
        /// </summary>
        public void ProcessEvents()
        {
            // Get all unprocessed eventlogs
            // foreach unprocessed eventlog record - find out if there are any subscriptions
            // foreach subscription, call CommunicationQueue repository to enqueue messages for Communication service.
            EventLogRepository eventLogRepository = new EventLogRepository();
            EventSubscriptionRepository eventSubscriptionRepository = new EventSubscriptionRepository();
            var eventLogs = eventLogRepository.GetUnprocessedLogs();
            logger.InfoFormat("About to process {0} event logs", eventLogs.Count);
            var client = new HttpClient();
            foreach (EventLog log in eventLogs)
            {
                #region OLD: Synchronous processing of Event Logs.
                try
                {
                    var eventSubscriptionRecipients = eventSubscriptionRepository.GetRecipients(log.ID);
                    logger.InfoFormat("Retrieved {0} subscription Recipients for eventlog ID {1} ", eventSubscriptionRecipients.Count, log.ID);

                    TransactionOptions tranOptions = new TransactionOptions();
                    tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
                    tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
                    using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
                    {
                        try
                        {
                            eventSubscriptionRecipients.ForEach(x =>
                            {
                                IEventProcessor eventProcessor = new DefaultEventProcessor();

                                if (EventNames.SEND_SURVEY.Equals(log.Event.Name, StringComparison.InvariantCultureIgnoreCase))
                                {
                                    eventProcessor = new SendSurveyEventProcessor();
                                }

                                eventProcessor.ProcessEventLog(log, x);
                            });
                            logger.InfoFormat("Update the notification queue date on Event Log : {0}", log.ID);
                            eventLogRepository.UpdateQueueDate(log);
                            tran.Complete();
                        }
                        catch (Exception ex)
                        {
                            logger.ErrorFormat("Error while processing eventlog ID {0} :", log.ID);
                            logger.Error(ex.Message, ex);
                        }
                    }
                }
                catch (Exception ex)
                {
                    logger.ErrorFormat("Error while processing event Log {0} - {1}", log.ID, ex.Message);
                }
                #endregion

                #region New Asynchronous processing of Event Logs.
                /*var task = client.GetAsync(string.Format(API_URL, log.ID));
                task.ContinueWith(async x =>
                {
                    if (x.IsFaulted || (x.Result != null && x.Result.StatusCode != System.Net.HttpStatusCode.OK))
                    {
                        logger.Warn("Error while accessing API", x.Exception);
                        logger.InfoFormat("Resetting Queue Date of EventLogID : {0}", log.ID);
                        eventLogRepository.ResetQueueDate(log);
                    }
                    else
                    {
                        var httpContent = x.Result.Content;
                        var responseAsString = httpContent.ReadAsStringAsync();
                        responseAsString.Wait();
                        // Important: The response would be of type OperationResult if the API processed the request. 
                        // Handle the scenario where the request didn't reach the API.                    
                        logger.DebugFormat("RESPONSE: {0}", responseAsString.Result);
                        if (!responseAsString.Result.Contains("OperationResult"))
                        {
                            logger.InfoFormat("Resetting Queue Date of EventLogID : {0}", log.ID);
                            eventLogRepository.ResetQueueDate(log);
                        }                        
                    }
                    
                });
                eventLogRepository.UpdateQueueDate(log);
                */
                #endregion

            }
        }

        #endregion

    }
}
