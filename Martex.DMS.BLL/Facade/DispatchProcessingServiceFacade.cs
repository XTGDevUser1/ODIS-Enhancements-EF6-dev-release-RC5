using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using System.Transactions;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class DispatchProcessingServiceFacade
    {
        #region Protected Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(DispatchProcessingServiceFacade));

        /// <summary>
        /// The dispatch service repository
        /// </summary>
        DispatchProcessingServiceRepository dispatchServiceRepository = new DispatchProcessingServiceRepository();

        /// <summary>
        /// The contact repository
        /// </summary>
        ContactLogRepository contactRepository = new ContactLogRepository();

        /// <summary>
        /// The contact log repository
        /// </summary>
        ContactLogReasonRepository contactLogRepository = new ContactLogReasonRepository();

        /// <summary>
        /// The contact log action repository
        /// </summary>
        ContactLogActionRepository contactLogActionRepository = new ContactLogActionRepository();

        /// <summary>
        /// The service request repository
        /// </summary>
        ServiceRequestRepository serviceRequestRepository = new ServiceRequestRepository();

        /// <summary>
        /// The communication repository
        /// </summary>
        CommunicationQueueRepository communicationRepository = new CommunicationQueueRepository();

        /// <summary>
        /// The program maintenance facade
        /// </summary>
        ProgramMaintenanceFacade progFacade = new ProgramMaintenanceFacade();

        #endregion

        #region Public Methods

        /// <summary>
        /// Starts the processing.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        public void StartProcessing(string userName)
        {
            try
            {
                logger.InfoFormat("Inside Dispatch Processing Service method");

                // Get all the records which is required for the processing.
                DispatchRepository dispatchRep = new DispatchRepository();
                List<DispatchProcessingList_Result> processingList = dispatchRep.GetDispatchProcessingList();
                logger.InfoFormat("Retrieved {0} records", processingList.Count);

                // Get all the ID in at one place whihc is required to do further processing.
                int contactCategoryID = dispatchServiceRepository.GetContactCategoryID();
                int contactTypeID = dispatchServiceRepository.GetContactTypeID();
                int contactSourceID = dispatchServiceRepository.GetContactSourceID();
                int contactReasonID = dispatchServiceRepository.GetContactReasonID();
                int contactActionID = dispatchServiceRepository.GetContactActionID();
                string scriptNum = null;
                SourceSystem memberMobileSourceSystem = ReferenceDataRepository.GetSourceSystemByName(SourceSystemName.MEMBER_MOBILE);
                ContactMethod mobileNotificationContactMethod = ReferenceDataRepository.GetContactMethod(ContactMethodNames.MOBILE_NOTIFICATION);
                if (mobileNotificationContactMethod == null)
                {
                    throw new DMSException(string.Format("Contact Method : {0} not set in database", ContactMethodNames.MOBILE_NOTIFICATION));
                }
                foreach (DispatchProcessingList_Result process in processingList)
                {
                    logger.InfoFormat("Processing Service Request for ID {0}", process.ServiceRequestID);

                    bool isSourceSytemMobile = false;
                    if (SourceSystemName.MEMBER_MOBILE.Equals(process.SourceSystem, StringComparison.InvariantCultureIgnoreCase))
                    {
                        isSourceSytemMobile = true;
                    }
                    // Create Contact Log Record.
                    ContactLog contactLog = new ContactLog();
                    ContactLogReason contactLogReason = new ContactLogReason();
                    ContactLogAction contactLogAction = new ContactLogAction();
                    CommunicationQueue communication = new CommunicationQueue();

                    contactLog.ContactCategoryID = contactCategoryID;
                    contactLog.ContactTypeID = contactTypeID;
                    contactLog.ContactMethodID = process.ContactMethodID;
                    contactLog.PhoneTypeID = process.ContactPhoneTypeID;
                    contactLog.ContactSourceID = contactSourceID;
                    contactLog.Company = null;
                    contactLog.TalkedTo = null;

                    contactLog.PhoneNumber = process.ContactPhoneNumber;
                    contactLog.Email = null;
                    contactLog.Direction = "Outbound";
                    contactLog.Description = "Closed Loop Call";
                    contactLog.Data = null;
                    contactLog.Comments = null;
                    contactLog.AgentRating = null;
                    contactLog.IsPossibleCallback = false;
                    contactLog.ModifyBy = userName;
                    contactLog.CreateBy = userName;
                    contactLog.ModifyDate = DateTime.Now;
                    contactLog.CreateDate = DateTime.Now;

                    // CR : 1218 - Read the program configuration for ScriptNum value.
                    scriptNum = null;
                    List<ProgramInformation_Result> info = progFacade.GetProgramInfo(process.ProgramID, "Application", "Welcome");

                    var item = info.Where(x => x.Name == "ClosedLoopScriptNumber").FirstOrDefault();

                    if (item != null)
                    {
                        scriptNum = item.Value;
                    }

                    string xmlMessageData = string.Format("<MessageData><Category>CONFIRMATION_CATEGORY</Category><PONumber>{0}</PONumber><TollFreeNumber>{1}</TollFreeNumber><ScriptNum>{2}</ScriptNum><ServiceRequestID>{3}</ServiceRequestID></MessageData>", process.PurchaseOrderNumber, process.TollFreeNumber, scriptNum, process.ServiceRequestID);
                    try
                    {
                        using (TransactionScope tran = new TransactionScope())
                        {
                            //Step 1 : Create Contact Log and Contact Log Link
                            contactRepository.Save(contactLog, userName, process.ServiceRequestID, EntityNames.SERVICE_REQUEST);

                            //Step 2 : Create Contact Log for Member
                            contactRepository.CreateLinkRecord(contactLog.ID, EntityNames.MEMBER, process.MemberID);

                            // Step 3 : Create Contact Log Reason record 
                            contactLogReason.ContactLogID = contactLog.ID;
                            contactLogReason.ContactReasonID = contactReasonID;
                            contactLogRepository.Save(contactLogReason, userName);

                            // Step 4 : Create Contact Log Action 
                            contactLogAction.ContactLogID = contactLog.ID;
                            contactLogAction.ContactActionID = contactActionID;
                            contactLogActionRepository.Save(contactLogAction, userName);

                            // Step 5 : Get Service Request and Update the Closed Loop Status
                            serviceRequestRepository.UpdateClosedLoopStatus(process.ServiceRequestID, userName);

                            // Step 6 : Create Communication Queue Record.
                            communication.ContactLogID = contactLog.ID;
                                                        
                            // If contactmethod = MobileNotification - get the relevant template.
                            if (mobileNotificationContactMethod.ID == process.ContactMethodID)
                            {
                                communication.ContactMethodID = mobileNotificationContactMethod.ID;
                                var templateRepository = new TemplateRepository();
                                var template = templateRepository.GetTemplateByName("ClosedLoopMobileNotification");
                                if (template == null)
                                {
                                    throw new DMSException("Template - ClosedLoopMobileNotification is not set up in the system");
                                }
                                communication.TemplateID = template.ID;

                                var memberRepository = new MemberRepository();
                                var member = memberRepository.Get(process.MemberID.GetValueOrDefault());

                                if (member != null)
                                {
                                    communication.NotificationRecipient = string.Format("MemberNumber:{0}", member.ClientMemberKey);
                                }
                            }
                            else
                            {
                                communication.ContactMethodID = process.ContactMethodID;
                                communication.MessageText = null;
                                communication.TemplateID = process.IsSMSAvailable ? dispatchServiceRepository.GetTemplateID(process.SourceSystem, process.TollFreeNumber) : null;
                                communication.NotificationRecipient = process.ContactPhoneNumber;
                            }
                            communication.Subject = null;
                            communication.MessageData = xmlMessageData;
                            communication.QueueARN = process.QueueARN;
                            communication.ServiceRequestID =
                                process.ServiceRequestID;

                            communication.Attempts = null;
                            communication.ScheduledDate = process.ETADate;
                            communication.CreateDate = DateTime.Now;
                            communication.CreateBy = userName;
                            communicationRepository.Save(communication);
                            tran.Complete();
                            logger.InfoFormat("Finished Processing");
                        }
                    }
                    catch (Exception ex)
                    {
                        logger.Info(ex.Message, ex);
                    }
                }
            }
            catch (Exception ex)
            {
                logger.Info(ex.Message, ex);
            }
        }

        #endregion
    }
}
