using System;
using System.Collections.Generic;
using System.Linq;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.BLL.Communication;
using System.Transactions;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Collections;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class CommunicationServiceFacade
    {
        #region Protected Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(CommunicationServiceFacade));

        /// <summary>
        /// The communication queue repository
        /// </summary>
        CommunicationQueueRepository communicationQueueRepository = new CommunicationQueueRepository();


        /// <summary>
        /// The contact methods
        /// Cache ContactMethod records to avoid re-querying while processing queue.
        /// </summary>
        protected static List<ContactMethod> contactMethods;

        #endregion

        #region Private Methods

        /// <summary>
        /// Creates the contact log action and update close loop status.
        /// </summary>
        /// <param name="contactLogID">The contact log ID.</param>
        /// <param name="closeLoopstatus">The close loopstatus.</param>
        /// <param name="contactAction">The contact action.</param>
        /// <exception cref="DMSException">Contact Action is not setup in the system</exception>
        private void CreateContactLogActionAndUpdateCloseLoopStatus(int? contactLogID, string closeLoopstatus, string contactAction, int contactMethodId)
        {
            // Sanghi : New Request.
            if (contactLogID.HasValue)
            {
                ContactLogRepository cLogRepository = new ContactLogRepository();
                ContactLogActionRepository cLogActionRepository = new ContactLogActionRepository();                
                ContactStaticDataRepository cStaticRepo = new ContactStaticDataRepository();
                ServiceRequestRepository srRepository = new ServiceRequestRepository();

                ContactAction contactActionEntity = cStaticRepo.GetContactActionByName(contactAction);
                if (contactActionEntity == null)
                {
                    throw new DMSException("Contact Action is not setup in the system");
                }
                // Create New Contact Log Action Record.
                ContactLogAction contactLogAction = new ContactLogAction();
                contactLogAction.ContactLogID = contactLogID.Value;
                contactLogAction.ContactActionID = contactActionEntity.ID;

                cLogActionRepository.Save(contactLogAction, "system");
                logger.InfoFormat("Successfully created contact log action record with status {0} at ID {1}", contactAction, contactLogAction.ID);


                // Update the Closed Loop Status only for closedloop category
                logger.InfoFormat("Attempting to update closedloopstatus on ServiceRequest");
                if (ClosedLoopStatusName.SENT.Equals(closeLoopstatus) && contactMethodId == 5)//IVR ContactMethod
                {
                    // Get the Current Service Request Details.
                    int? srID = cLogActionRepository.GetServiceRequestID(contactLogID.Value);
                    if (srID != null)
                    {
                        logger.InfoFormat("Retrieved SR ID : {0}", srID.Value);
                        ServiceRequest serviceRequest = srRepository.GetById(srID.Value);
                        if (serviceRequest != null)
                        {
                            srRepository.UpdateClosedLoopStatus(serviceRequest.ID, "system", closeLoopstatus);
                        }

                    }

                }
                else
                {
                    cLogRepository.UpdateClosedLoopStatus(contactLogID.Value);
                }
                logger.InfoFormat("Updated closedloopstatus on ServiceRequest");
            }
        }

        /// <summary>
        /// Updates the communication fax details.
        /// </summary>
        private void UpdateCommunicationFaxDetails()
        {
            CommunicationQueueRepository repository = new CommunicationQueueRepository();
            repository.UpdateCommunicationFaxDetails("system");
        }

        /// <summary>
        /// Prepares the content using a template.
        /// </summary>
        /// <param name="communicationQueue">The communication queue.</param>
        private void PrepareContentFromTemplate(CommunicationQueue communicationQueue)
        {
            // Check to see if there is a template defined.
            // If yes
            //      Grab the template and use it to prepare subject and body of the message using the MessageData in communication queue.
            // If no
            //      If message text/subject is null, then just do a nvp on messagedata (if it exists)
            //      If message text and subject are available and message data is also there, then use formatting
            //      If both are null, then leave it as blank for now.

            Template t = null;
            if (communicationQueue.TemplateID != null)
            {
                t = new TemplateRepository().GetTemplateByID(communicationQueue.TemplateID.Value);
            }
            string subject = "DMS system message";
            string body = string.Empty;
            Hashtable ht = new Hashtable();
            if (!string.IsNullOrEmpty(communicationQueue.MessageData))
            {
                ht = communicationQueueRepository.XMLToKeyValuePairs(communicationQueue.MessageData);
            }
            /*KB: Scenarios:
             *          1. Template ID is available. This means that the subject and messagetext can be extracted from the template.
             *          2. Template ID is not available but the messagetext and subject are available on the queue record. This means, that it might require a bit more processing to fill the substitutables in the messagetext and subject.
             *          3. Template is null as well as the subject and messagetext are null. In this case, the messagebody is just going to be in the format {Name = Value} where name-value pair information comes from the MessageData XML.
            */
            if (t != null)
            {
                if (!string.IsNullOrEmpty(t.Subject))
                {
                    subject = TemplateUtil.ProcessTemplate(t.Subject, ht);
                }

                if (!string.IsNullOrEmpty(t.Body))
                {
                    body = TemplateUtil.ProcessTemplate(t.Body, ht);
                }
            }
            else
            {
                if (!string.IsNullOrEmpty(communicationQueue.Subject))
                {
                    subject = TemplateUtil.ProcessTemplate(communicationQueue.Subject, ht);
                }
                if (!string.IsNullOrEmpty(communicationQueue.MessageText))
                {
                    body = TemplateUtil.ProcessTemplate(communicationQueue.MessageText, ht);
                }
                else
                {
                    StringBuilder sb = new StringBuilder();
                    foreach (var item in ht.Keys)
                    {
                        sb.AppendFormat("{0} = {1}", item, ht[item]).AppendLine();
                    }
                    body = sb.ToString();
                }
            }

            communicationQueue.Subject = subject;
            communicationQueue.MessageText = body;
        }

        #endregion

        #region Public Methods

        /// <summary>
        /// Send notification of unprocessed communication queue
        /// </summary>
        /// <exception cref="DMSException">No notifier available in the system to process the queue record</exception>
        public void SendNotification()
        {
            try
            {
                logger.InfoFormat("Inside SendNotification method");
                CommunicationQueueRepository communicationQueueRepository = new CommunicationQueueRepository();
                // Get all the UnProcessed communication queue
                logger.InfoFormat("Try to retrieve all unprocessed communication queue");
                List<CommunicationQueue> communicationQueueList = communicationQueueRepository.GetQueue();
                logger.InfoFormat("Retrieved total {0} number of unprocessed communication queue", communicationQueueList.Count());
                // We have temporarily used one break at the end of this foreach block to prevent the application
                // from multiple itterations. It is for testing purpose. Remove that after full implementation
                foreach (CommunicationQueue communicationQueue in communicationQueueList)
                {
                    // we have to regenerate the edmx for contactLogAction
                    CommunicationLog communicationLog = new CommunicationLog();
                    communicationLog.ContactLogID = communicationQueue.ContactLogID;
                    communicationLog.ContactMethodID = communicationQueue.ContactMethodID;
                    communicationLog.TemplateID = communicationQueue.TemplateID;
                    
                    communicationLog.NotificationRecipient = communicationQueue.NotificationRecipient;
                    communicationLog.EventLogID = communicationQueue.EventLogID;
                    
                    communicationLog.CreateDate = communicationQueue.CreateDate;
                    communicationLog.CreateBy = communicationQueue.CreateBy;

                    // Prepare content for messages
                    PrepareContentFromTemplate(communicationQueue);
                    communicationLog.Subject = communicationQueue.Subject;
                    communicationLog.MessageText = communicationQueue.MessageText;
                    
                       // Retieved contact method 
                    logger.InfoFormat("Retrieved ConctactMethodID : {0}", communicationQueue.ContactMethodID);
                    int contactMethodId = Convert.ToInt16(communicationQueue.ContactMethodID);

                    try
                    {
                        //using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, new TransactionOptions { IsolationLevel = IsolationLevel.Snapshot }))
                        TransactionOptions tranOptions = new TransactionOptions();
                        tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
                        tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;

                        int communicationLogID = 0;
                        logger.InfoFormat("Try to get all notifier object for the communication queue Id {0}", communicationQueue.ID);

                        INotifier notifier = NotifierFactory.GetNotifiers(communicationQueue);
                        if (notifier != null && notifier.GetType() != typeof(TwilioFaxNotifier))
                        {
                            logger.InfoFormat("Processing messages via {0}", notifier.GetType().ToString());
                            notifier.Notify(communicationQueue);

                            //Add a CommunicationLog record with status to SUCCESS and 
                            //delete the Communication Queue record after sending all success notifications.
                            logger.InfoFormat("Add a new Communication Log for succeed Queue ID : {0}", communicationQueue.ID);
                            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
                            {
                                communicationLog.Status = AppConfigConstants.SUCCESS;
                                communicationLogID = communicationQueueRepository.AddCommunicationLog(communicationLog);
                                //CreateContactLogActionAndUpdateCloseLoopStatus(communicationQueue.ContactLogID, ClosedLoopStatusName.SENT, ContactActionName.SENT);
                                CreateContactLogActionAndUpdateCloseLoopStatus(communicationQueue.ContactLogID, ClosedLoopStatusName.SENT, ContactActionName.SENT, contactMethodId);//Passing contactMethodId
                                communicationQueueRepository.DeleteCommunication(communicationQueue.ID);
                                logger.InfoFormat("Delete the Queue ID : {0}", communicationQueue.ID);
                                tran.Complete();
                            }

                        }
                        else if (notifier != null && notifier.GetType() == typeof(TwilioFaxNotifier))
                        {
                            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
                            {
                                //Add a CommunicationLog record with status to Pending and 
                                //delete the Communication Queue record after sending all success notifications.
                                logger.InfoFormat("Add a new Communication Log with status [pending] - Queue ID : {0}", communicationQueue.ID);
                                communicationLog.Status = AppConfigConstants.PENDING;
                                communicationLogID = communicationQueueRepository.AddCommunicationLog(communicationLog);
                                communicationQueue.CommunicationLogID = communicationLogID;
                                //KB: The following call is just going to create files on the disk and it is assumed to be faster.
                                notifier.Notify(communicationQueue);
                                communicationQueueRepository.DeleteCommunication(communicationQueue.ID);
                                logger.InfoFormat("Delete the Queue ID : {0}", communicationQueue.ID);
                                tran.Complete();
                            }
                        }
                        else
                        {
                            throw new DMSException("No notifier available in the system to process the queue record");
                        }

                        
                    }
                    catch (Exception ex)
                    {
                        logger.Info(ex.Message);
                        //using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, new TransactionOptions { IsolationLevel = IsolationLevel.Snapshot }))
                        TransactionOptions tranOptions = new TransactionOptions();
                        tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
                        tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
                        using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
                        {
                            // IF the attempts value is null, make it 0
                            if (communicationQueue.Attempts == null)
                            {
                                communicationQueue.Attempts = 0;
                            }
                            string maxNumberOfAttempts = AppConfigRepository.GetValue(AppConfigConstants.COMMUNICATION_QUEUE_ATTEMPTS);
                            if (!string.IsNullOrEmpty(maxNumberOfAttempts))
                            {
                                // If attempt is less than CommunicationQueueAttempts increase the Attempts of Communication Queue by 1 ,
                                //else delete the queued record
                                if (communicationQueue.Attempts < int.Parse(maxNumberOfAttempts))
                                {
                                    communicationQueue.Attempts += 1;
                                    communicationQueueRepository.UpdateCommunication(communicationQueue);
                                    logger.InfoFormat("Update the attempt number for failure Queue ID : {0}", communicationQueue.ID);
                                }
                                else
                                {
                                    //Delete the Communication Queue record failure to notify after the maximum number of attempts.
                                    communicationQueueRepository.DeleteCommunication(communicationQueue.ID);
                                    logger.InfoFormat("Delete the Queue ID : {0} after {1} number of attempts", communicationQueue.ID, maxNumberOfAttempts);
                                    INotifier notifier = NotifierFactory.GetNotifiers(communicationQueue);

                                    if (notifier != null)
                                    {
                                        //Log failure for all types of notifiers
                                        CreateContactLogActionAndUpdateCloseLoopStatus(communicationQueue.ContactLogID, ClosedLoopStatusName.SEND_FAILURE, ContactActionName.SEND_FAILURE,contactMethodId);
                                    }
                                }
                                //Add a CommunicationLog record with status to FAIL
                                communicationLog.Status = AppConfigConstants.FAIL;
                                // Create new object for Communciation Log 
                                CommunicationLog cLog = new CommunicationLog();
                                cLog.Comments = ex.Message; //communicationLog.Comments;
                                cLog.ContactLogActionDate = communicationLog.ContactLogActionDate;
                                cLog.ContactLogID = communicationLog.ContactLogID;
                                cLog.ContactMethodID = communicationLog.ContactMethodID;
                                cLog.CreateBy = communicationLog.CreateBy;
                                cLog.CreateDate = communicationLog.CreateDate;
                                cLog.NotificationRecipient = communicationLog.NotificationRecipient;
                                cLog.MessageText = communicationLog.MessageText;
                                cLog.ModifyBy = communicationLog.ModifyBy;
                                cLog.ModifyDate = communicationLog.ModifyDate;
                                cLog.EventLogID = communicationLog.EventLogID;
                                cLog.Status = communicationLog.Status;
                                cLog.Subject = communicationLog.Subject;
                                cLog.TemplateID = communicationLog.TemplateID;

                                communicationQueueRepository.AddCommunicationLog(cLog);
                                logger.InfoFormat("Add a new Communication Log for failure Queue ID : {0}", communicationQueue.ID);
                                
                            }

                            logger.WarnFormat("Error while processing notifcations for Queue ID : {0}", communicationQueue.ID);
                            logger.Error(ex.Message, ex);                            

                            tran.Complete();
                        }

                    }


                }
                logger.InfoFormat("Before Updating all Fax Results.");
                RefreshPendingTwilioFaxStatuses();
                UpdateCommunicationFaxDetails();
                logger.InfoFormat("Finished Updating all Fax Results.");

            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
            }

        }

        private void RefreshPendingTwilioFaxStatuses()
        {
            var twilioFaxService = new TwilioFaxNotifier();
            twilioFaxService.RefreshPendingFaxStatuses();
        }

        /// <summary>
        /// Gets the notification history.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public List<NotificationHistory_Result> GetNotificationHistory(string userName)
        {
            var repository = new CommunicationQueueRepository();

            return repository.GetNotificationHistory(userName);
        }

        #endregion


    }
}
