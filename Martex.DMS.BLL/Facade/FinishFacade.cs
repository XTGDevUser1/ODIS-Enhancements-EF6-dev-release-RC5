using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAO;
using System.Transactions;
using log4net;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Reflection;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade Manages Finish
    /// </summary>
    public class FinishFacade
    {
        #region Protected Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(FinishFacade));

        #endregion

        #region Public Methods

        /// <summary>
        /// Gets the contact reasons.
        /// </summary>
        /// <param name="contactCategory">The contact category.</param>
        /// <returns></returns>
        public List<ContactReason> GetContactReasons(int contactCategory)
        {
            return new FinishRepository().GetContactReasons(contactCategory);
        }

        /// <summary>
        /// Gets the contact action.
        /// </summary>
        /// <param name="contactCategory">The contact category.</param>
        /// <returns></returns>
        public List<ContactAction> GetContactAction(int contactCategory)
        {
            return new FinishRepository().GetContactAction(contactCategory);
        }

        /// <summary>
        /// Gets the closed loop activities.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<ClosedLoopActivities_Result> GetClosedLoopActivities(int? serviceRequestID)
        {
            return new FinishRepository().GetClosedLoopActivities(serviceRequestID);
        }

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <param name="requestOpenedTime">The request opened time.</param>
        /// <exception cref="DMSException">Invalid event name
        /// or
        /// Invalid event name :  + EventNames.CREATE_SERVICE_REQUEST_FOR_INFO_CALL</exception>
        public void Save(FinishModel model, string eventSource, string loggedInUser, string sessionID, int? membershipID, DateTime? requestOpenedTime, ServiceRequestAgentTime srAgentTime)
        {
            logger.InfoFormat("FinishFacade - Save(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                membershipID = membershipID,
                requestOpenedTime = requestOpenedTime,
                caseId = model.CaseID,
                srId = model.ServiceRequestID
            }));

            var srAgentTimeRepository = new SRAgentTimeRepository();

            EventLogRepository eventLogRepository = new EventLogRepository();
            IRepository<Event> eventRepository = new EventRepository();
            var currentDate = DateTime.Now;
            Event theEvent = new Event();
            //using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, new TransactionOptions { IsolationLevel = IsolationLevel.Snapshot }))
            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    if (model.ServiceRequestID == 0)
                    {
                        logger.Info("There is no service request as the user went to Finish after Start call");

                        InboundCallRepository inboundCallRepository = new InboundCallRepository();
                        InboundCall inCall = inboundCallRepository.GetInboundCallById(model.InBoundCallId);

                        MemberRepository memberRepository = new MemberRepository();
                        Member member = memberRepository.Get(model.MemberID);

                        CommonLookUpRepository repository = new CommonLookUpRepository();
                        NextAction nextAction = repository.GetNextAction(model.NextAction.GetValueOrDefault());
                        var srAgentBeginDate = DateTime.Now;
                        if (inCall != null)
                        {
                            var emergencyRepository = new EmergencyAssistanceRepository();
                            EmergencyAssistance ea = emergencyRepository.GetEmergencyAssistance(inCall.ID);
                            #region 1. Create a case
                            Case c = new Case()
                            {
                                ProgramID = inCall.ProgramID,
                                CallTypeID = inCall.CallTypeID,
                                Language = inCall.Language.GetValueOrDefault().ToString(),
                                ContactPhoneTypeID = inCall.ContactPhoneTypeID,
                                ContactPhoneNumber = inCall.ContactPhoneNumber,
                                ContactAltPhoneTypeID = inCall.ContactAltPhoneTypeID,
                                ContactAltPhoneNumber = inCall.ContactAltPhoneNumber,
                                CreateBy = loggedInUser,
                                CreateDate = currentDate,
                                ModifyBy = loggedInUser,
                                ModifyDate = currentDate,
                                AssignedToUserID = inCall.AssignedtoUserID,
                                IsSafe = inCall.IsSafe,
                                ANIPhoneNumber = model.ANIPhoneNumber,
                                ANIPhoneTypeID = model.ANIPhoneTypeID
                            };
                            if (ea != null)
                            {
                                c.ContactLastName = ea.MemberLastName;
                                c.ContactFirstName = ea.MemberFirstName;
                            }
                            logger.Info("Creating a case");
                            CaseRepository caseRepository = new CaseRepository();
                            int caseID = caseRepository.Add(c, "Open");
                            model.CaseID = caseID;
                            #endregion

                            #region  2. Entity Program Data Item records
                            if (model.DynamicDataElements != null)
                            {
                                int programDataItemId = 0;
                                logger.Info("Processing dynamic elements");
                                foreach (var item in model.DynamicDataElements)
                                {
                                    programDataItemId = 0;
                                    int.TryParse(item.Key.Split('$')[1], out programDataItemId);
                                    if (programDataItemId != 0)
                                    {
                                        ProgramMaintenanceRepository.AddDynamicDataValue(EntityNames.CASE, model.CaseID, programDataItemId, item.Value, loggedInUser);
                                    }
                                }
                            }

                            #endregion

                            #region 3. EventLog records for Case
                            //For Event Log
                            // EventLogRepository eventLogRepository = new EventLogRepository();


                            theEvent = eventRepository.Get<string>(EventNames.CREATE_CASE_FOR_INFO_CALL);

                            if (theEvent == null)
                            {
                                throw new DMSException("Invalid event name");
                            }

                            EventLog eventLog = new EventLog();
                            eventLog.Source = eventSource;
                            eventLog.EventID = theEvent.ID;
                            eventLog.SessionID = sessionID;
                            eventLog.Description = "Create Case for Info call";
                            eventLog.CreateDate = currentDate;
                            eventLog.CreateBy = loggedInUser;

                            logger.Info("Event log for Create case for info call");

                            long eventLogId = eventLogRepository.Add(eventLog, caseID, EntityNames.CASE);


                            #endregion

                            #region Set Case ID on inbound call
                            if (model.MemberID > 0)
                            {
                                inCall.MemberID = model.MemberID;
                            }
                            inCall.CaseID = c.ID;
                            logger.InfoFormat("Update Case ID [ {0} ]and member ID [ {1} ]on inbound call", c.ID, model.MemberID);
                            inboundCallRepository.Save(inCall);
                            #endregion

                            #region 5. Set Case ID OnEmergency Assistance
                            logger.Info("Update Case ID on Emergency record");
                            emergencyRepository.UpdateCaseDetails(inCall.ID, caseID, loggedInUser);
                            #endregion

                            #region 6. ServiceRequest
                            ServiceRequest request = new ServiceRequest()
                            {
                                CaseID = model.CaseID,
                                IsEmergency = false,
                                IsAccident = false,
                                IsWorkedByTech = false, //CR : 1135
                                CreateBy = loggedInUser,
                                CreateDate = currentDate,
                                ModifyBy = loggedInUser,
                                ModifyDate = currentDate,
                                ServiceRequestStatusID = model.ServiceRequestStatus,
                                StartTabStatus = 1,
                                NextActionAssignedToUserID = (nextAction != null ? nextAction.DefaultAssignedToUserID : null),
                                ProviderClaimNumber = model.ProviderClaimNumber,
                                ProviderID = model.ProductProviderID

                            };
                            if (ea != null && ea.ID != 0)
                            {
                                request.IsEmergency = true;
                                if (ea.EmergencyAssistanceReasonID.HasValue)
                                {
                                    request.IsAccident = emergencyRepository.IsAccident(ea.EmergencyAssistanceReasonID.Value);
                                }
                            }
                            else
                            {
                                request.IsEmergency = false;
                            }
                            ProductCategory pCategory = ReferenceDataRepository.GetProductCategoryByName("Info");
                            if (pCategory != null)
                            {
                                request.ProductCategoryID = pCategory.ID;
                            }
                            logger.Info("Creating an SR");
                            ServiceRequestRepository requestRepository = new ServiceRequestRepository();
                            int serviceRequestId = requestRepository.Add(request, "Entry", "Normal");
                            model.ServiceRequestID = serviceRequestId;

                            theEvent = eventRepository.Get<string>(EventNames.CREATE_SERVICE_REQUEST_FOR_INFO_CALL);

                            if (theEvent == null)
                            {
                                throw new DMSException("Invalid event name : " + EventNames.CREATE_SERVICE_REQUEST_FOR_INFO_CALL);
                            }

                            eventLog = new EventLog();
                            eventLog.Source = eventSource;
                            eventLog.EventID = theEvent.ID;
                            eventLog.SessionID = sessionID;
                            eventLog.Description = "Create Service Request for Info Call";
                            eventLog.CreateDate = currentDate;
                            eventLog.CreateBy = loggedInUser;

                            logger.Info("Event log for Create Service Request for Info Call");
                            eventLogId = eventLogRepository.Add(eventLog, serviceRequestId, EntityNames.SERVICE_REQUEST);

                            // At this point, there won't be SRAgentTime in context. This happens when user comes to Finish tab from Start call directly.
                            srAgentTime = new ServiceRequestAgentTime()
                            {
                                IsInboundCall = true,
                                ProgramID = inCall.ProgramID,
                                TimeTypeID = null, //TODO: Fix the timetype value.
                                UserName = loggedInUser,
                                BeginEventLogID = eventLogId,
                                BeginDate = srAgentBeginDate,
                                ServiceRequestID = serviceRequestId
                            };

                            srAgentTimeRepository.Create(srAgentTime);
                            #endregion

                        }
                    }

                    #region 1. Update service request
                    ServiceRequestRepository serviceRequestRepository = new ServiceRequestRepository();
                    ServiceRequest sr = GetServiceRequestFromModel(model, loggedInUser);
                    logger.Info("Update SR on finish");
                    serviceRequestRepository.UpdateOnFinish(sr, eventSource, sessionID, loggedInUser, requestOpenedTime);


                    logger.Info("Process vehicle data");
                    #endregion

                    CaseRepository caseRepositoryobj = new CaseRepository();
                    //caseRepositoryobj.SetSMSAvailable(model.CaseID, model.IsSMSAvailable.Value);

                    #region 2, 3. Update Case and Vehicle.
                    ProcessVehicleData(model, membershipID);
                    #endregion

                    logger.Info("Process completed for vehicle data");
                    if (model.ContactCategory != 0)
                    {
                        logger.Info("Trying to create Contact Log and Link");
                        #region 4. Create contactlog record and link records
                        ContactLogRepository contactLogRepository = new ContactLogRepository();
                        ContactLog contactLog = new ContactLog();
                        contactLog.ContactCategoryID = model.ContactCategory;

                        ContactStaticDataRepository cmethodRepo = new ContactStaticDataRepository();
                        ContactMethod method = cmethodRepo.GetMethodByName("Phone");
                        if (method != null)
                        {
                            contactLog.ContactMethodID = method.ID;
                        }
                        // TODO: Set phone numbers and review the following line.
                        string contactTypeName = model.ContactCategory == 4 ? "Vendor" : "Member";
                        ContactType contactType = cmethodRepo.GetTypeByName(contactTypeName);
                        if (contactType != null)
                        {
                            contactLog.ContactTypeID = contactType.ID;
                        }
                        contactLog.Direction = "Inbound";
                        contactLog.CreateBy = contactLog.ModifyBy = loggedInUser;
                        contactLog.CreateDate = contactLog.ModifyDate = DateTime.Now;
                        if (model.AmazonConnectID != null)
                        {
                            contactLog.ContactLogConnectData = new ContactLogConnectData
                            {
                                ConnectContactID = model.AmazonConnectID,
                                CreateBy = "AWS",
                                CreateDate = DateTime.Now,
                                ModifyBy = "AWS",
                                ModifyDate = DateTime.Now
                            };
                        }
                     

                        logger.Info("Creating contact logs and link records");
                        contactLogRepository.Save(contactLog, loggedInUser, model.ServiceRequestID, EntityNames.SERVICE_REQUEST);


                        //contactLogRepository.CreateLinkRecord(contactLog.ID, "ServiceRequest", sr.ID);
                        //TODO:Set Vender ID Based On Contact Catagory
                        contactLogRepository.CreateLinkRecord(contactLog.ID, contactTypeName, model.MemberID);

                        ContactLogReasonRepository logReasonRepo = new ContactLogReasonRepository();
                        #endregion

                        #region 5. Create "n" ContactLogReason records
                        if (model.SelectedReasons != null)
                        {
                            model.SelectedReasons.ForEach(r =>
                            {
                                ContactLogReason reason = new ContactLogReason();
                                reason.ContactLogID = contactLog.ID;
                                reason.ContactReasonID = r;
                                logReasonRepo.Save(reason, loggedInUser);
                            });
                        }

                        #endregion

                        #region 6. Create "n" ContactLogAction records
                        ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                        if (model.SelectedActions != null)
                        {
                            model.SelectedActions.ForEach(r =>
                            {
                                ContactLogAction action = new ContactLogAction();
                                action.ContactLogID = contactLog.ID;
                                action.ContactActionID = r;
                                logActionRepo.Save(action, loggedInUser);
                            });
                        }
                        #endregion
                    }
                    #region 7. Event Log record for leaving the tab
                    ServiceRequest eventSR = serviceRequestRepository.GetById(model.ServiceRequestID);
                    if (eventSR != null)
                    {
                        EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                        Dictionary<string, string> eventData = new Dictionary<string, string>();

                        eventData.Add("ServiceRequestID", model.ServiceRequestID.ToString());
                        eventData.Add("ContactCategory", model.ContactCategory.ToString());

                        if (eventSR.ServiceRequestStatu != null)
                        {
                            eventData.Add("ServiceRequestStatus", eventSR.ServiceRequestStatu.Name);
                        }
                        if (eventSR.NextAction != null)
                        {
                            eventData.Add("NextAction", eventSR.NextAction.Name);
                        }

                        if (model.ScheduledDate.HasValue)
                        {
                            //TFS 1313:
                            eventData.Add("ScheduledDate", model.ScheduledDate.GetValueOrDefault().ToString("MM/dd/yyyy hh:mm:ss tt"));
                        }

                        if (model.AssignedTo.HasValue)
                        {
                            eventData.Add("AssignedTo", model.AssignedTo.GetValueOrDefault().ToString());
                        }

                        if (eventSR.ServiceRequestPriority != null)
                        {
                            eventData.Add("Priority", eventSR.ServiceRequestPriority.Name);
                        }

                        if (eventSR.ClosedLoopStatu != null)
                        {
                            eventData.Add("ClosedLoopStatus", eventSR.ClosedLoopStatu.Name);
                        }

                        if (model.NextSend.HasValue)
                        {
                            eventData.Add("NextSend", model.NextSend.GetValueOrDefault().ToShortDateString());
                        }

                        eventData.Add("Comments", Left(model.Comments, 1000));
                        eventData.Add("CreateBy", eventSR.CreateBy);
                        eventData.Add("ModifyBy", loggedInUser);

                        logger.Info("Event log for Leave finish tab");
                        var eventLogId = eventLogFacade.LogEvent(eventSource, EventNames.SAVE_FINISH_TAB, eventData.GetXml(), loggedInUser, model.ServiceRequestID, EntityNames.SERVICE_REQUEST, sessionID);
                        eventLogFacade.LogEvent(string.Empty, EventNames.LEAVE_FINISH_TAB, EventNames.LEAVE_FINISH_TAB, loggedInUser, model.ServiceRequestID, EntityNames.SERVICE_REQUEST, sessionID);

                        var timeElapsed = (int)(DateTime.Now - srAgentTime.BeginDate.Value).TotalSeconds;
                        srAgentTimeRepository.UpdateEvent(srAgentTime.ID, eventLogId, timeElapsed, true);
                        logger.InfoFormat("Updated SRAgentTime {0}", srAgentTime.ID);

                        //KB: Log events for ServiceRequest Status history.
                        bool updateMapSnapshot = false;

                        //NP 6/24: TFS # 1123 -->  Do not require 'Submitted' Status. Only trigger event when NextAction changed to 'Dispatch'
                        //if (ServiceRequestStatusNames.SUBMITTED.Equals(eventSR.ServiceRequestStatu.Name, StringComparison.InvariantCultureIgnoreCase))
                        if (eventSR.NextAction != null && eventSR.NextAction.Name == "Dispatch")
                        {
                            logger.InfoFormat("Logging event {0}", EventNames.SUBMITTED_FOR_DISPATCH);
                            eventLogRepository.LogEventForServiceRequestStatus(model.ServiceRequestID, EventNames.SUBMITTED_FOR_DISPATCH, eventSource, null, sessionID, loggedInUser);
                        }
                        else if (eventSR.ClosedLoopStatu != null && ClosedLoopStatusName.SERVICE_ARRIVED.Equals(eventSR.ClosedLoopStatu.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            logger.InfoFormat("Logging event {0}", EventNames.SERVICE_ARRIVED);
                            eventLogRepository.LogEventForServiceRequestStatus(model.ServiceRequestID, EventNames.SERVICE_ARRIVED, eventSource, null, sessionID, loggedInUser);
                        }
                        else if (ServiceRequestStatusNames.COMPLETE.Equals(eventSR.ServiceRequestStatu.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            logger.InfoFormat("Logging event {0}", EventNames.SERVICE_COMPLETED);
                            eventLogRepository.LogEventForServiceRequestStatus(model.ServiceRequestID, EventNames.SERVICE_COMPLETED, eventSource, null, sessionID, loggedInUser);
                            updateMapSnapshot = true;
                        }
                        if (ServiceRequestStatusNames.CANCELLED.Equals(eventSR.ServiceRequestStatu.Name, StringComparison.InvariantCultureIgnoreCase))
                        {
                            logger.InfoFormat("Logging event {0}", EventNames.SERVICE_CANCELLED);
                            eventLogRepository.LogEventForServiceRequestStatus(model.ServiceRequestID, EventNames.SERVICE_CANCELLED, eventSource, null, sessionID, loggedInUser);
                            updateMapSnapshot = true;
                        }


                        if (updateMapSnapshot)
                        {
                            logger.InfoFormat("Updating map snapshot for SR ID {0}", model.ServiceRequestID);
                            MapFacade mapFacade = new MapFacade();
                            mapFacade.SetMapSnapshot(model.ServiceRequestID);
                        }


                    }
                    else
                    {
                        logger.Info("Service Request is Null so not able to create event log");

                    }
                    #endregion

                    #region 8. Save comments
                    logger.Info("Save Comments");
                    if (!string.IsNullOrEmpty(model.Comments))
                    {
                        CommentRepository commentRepo = new CommentRepository();

                        commentRepo.Save(CommentTypeNames.SERVICE_REQUEST, EntityNames.SERVICE_REQUEST, model.ServiceRequestID, model.Comments, loggedInUser);
                    }
                    #endregion

                    #region 9. Event Log record for SR having Claim Number
                    theEvent = eventRepository.Get<string>(EventNames.ENTERED_PROVIDER_CLAIM_NUMBER);

                    if (theEvent == null)
                    {
                        throw new DMSException("Invalid event name : " + EventNames.ENTERED_PROVIDER_CLAIM_NUMBER);
                    }

                    if (!string.IsNullOrEmpty(sr.ProviderClaimNumber) && !eventLogRepository.DoesEventLogLinkExists(sr.ID, EntityNames.SERVICE_REQUEST, EventNames.ENTERED_PROVIDER_CLAIM_NUMBER))
                    {
                        EventLog eventLog = new EventLog();
                        eventLog.Source = eventSource;
                        eventLog.EventID = theEvent.ID;
                        eventLog.SessionID = sessionID;
                        eventLog.Description = "Entered provider claim number";
                        eventLog.CreateDate = currentDate;
                        eventLog.CreateBy = loggedInUser;

                        logger.Info("Event log for Entered provider claim number");

                        long eventLogId = eventLogRepository.Add(eventLog, sr.ID, EntityNames.SERVICE_REQUEST);
                    }
                    #endregion

                    #region Finish data validator

                    var dataValidator = new FinishDataValidator();
                    dataValidator.Validate(model.ServiceRequestID);

                    #endregion
                    tran.Complete();
                }
                catch (Exception ex)
                {
                    logger.Warn("Error while saving data during Finish call", ex);
                    throw ex;
                }
            }
        }

        public void updateServiceRequestOutboundCall(ContactLog contactLog, string LoggedInUserName, int? serviceRequestID, int memberID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                var contactLogRepository = new ContactLogRepository();
                contactLogRepository.Save(contactLog, LoggedInUserName, serviceRequestID, EntityNames.SERVICE_REQUEST);
                tran.Complete();
            }
        }
        public void SaveOnActiveServiceRequestLocked(FinishModel model, string eventSource, string loggedInUser, string sessionID, int? membershipID)
        {
            if (model.ContactCategory != 0)
            {
                logger.Info("Trying to create Contact Log and Link");
                #region 4. Create contactlog record and link records
                ContactLogRepository contactLogRepository = new ContactLogRepository();
                ContactLog contactLog = new ContactLog();
                contactLog.ContactCategoryID = model.ContactCategory;

                ContactStaticDataRepository cmethodRepo = new ContactStaticDataRepository();
                ContactMethod method = cmethodRepo.GetMethodByName("Phone");
                if (method != null)
                {
                    contactLog.ContactMethodID = method.ID;
                }
                // TODO: Set phone numbers and review the following line.
                string contactTypeName = model.ContactCategory == 4 ? "Vendor" : "Member";
                ContactType contactType = cmethodRepo.GetTypeByName(contactTypeName);
                if (contactType != null)
                {
                    contactLog.ContactTypeID = contactType.ID;
                }
                contactLog.Direction = "Inbound";
                contactLog.CreateBy = contactLog.ModifyBy = loggedInUser;
                contactLog.CreateDate = contactLog.ModifyDate = DateTime.Now;

                logger.Info("Creating contact logs and link records");
                contactLogRepository.Save(contactLog, loggedInUser, model.ServiceRequestID, EntityNames.SERVICE_REQUEST);

                ContactLogReasonRepository logReasonRepo = new ContactLogReasonRepository();
                #endregion

                #region 5. Create "n" ContactLogReason records
                if (model.SelectedReasons != null)
                {
                    model.SelectedReasons.ForEach(r =>
                    {
                        ContactLogReason reason = new ContactLogReason();
                        reason.ContactLogID = contactLog.ID;
                        reason.ContactReasonID = r;
                        logReasonRepo.Save(reason, loggedInUser);
                    });
                }

                #endregion

                #region 6. Create "n" ContactLogAction records
                ContactLogActionRepository logActionRepo = new ContactLogActionRepository();
                if (model.SelectedActions != null)
                {
                    model.SelectedActions.ForEach(r =>
                    {
                        ContactLogAction action = new ContactLogAction();
                        action.ContactLogID = contactLog.ID;
                        action.ContactActionID = r;
                        logActionRepo.Save(action, loggedInUser);
                    });
                }
                #endregion
            }

            var commentFacade = new CommentFacade();
            commentFacade.Save(CommentTypeNames.LOCKED_REQUEST, EntityNames.SERVICE_REQUEST, model.ServiceRequestID, model.ActiveRequestLockedComments, loggedInUser);

            if (model.SendNotification)
            {
                EventLoggerFacade eventfacade = new EventLoggerFacade();
                //StringBuilder sb = new StringBuilder("<MessageData><SentFrom>");
                //sb.Append(loggedInUser);
                //sb.Append("</SentFrom><MessageText>");
                //sb.Append(model.ActiveRequestLockedComments);
                //sb.Append("</MessageText></MessageData>");

                Hashtable ht = new Hashtable();
                ht.Add("CommentType", "Locked Request Comment");
                ht.Add("SentFrom", loggedInUser);
                ht.Add("MessageText", model.ActiveRequestLockedComments);
                ht.Add("RequestNumber", model.ServiceRequestID.ToString());

                long eventId = eventfacade.LogEvent(eventSource, EventNames.LOCKED_REQUEST_COMMENT, ht.GetMessageData(), loggedInUser, sessionID);

                //Event log link for service request
                eventfacade.CreateRelatedLogLinkRecord(eventId, model.ServiceRequestID, EntityNames.SERVICE_REQUEST);
                QueueRepository repository = new QueueRepository();
                int? assignedtouserId = repository.GetAssignedToUserId(model.ServiceRequestID);
                if (assignedtouserId != null)
                {
                    eventfacade.CreateRelatedLogLinkRecord(eventId, assignedtouserId, EntityNames.USER);
                }
            }


        }

        #endregion

        #region Private Methods

        /// <summary>
        /// Processes the vehicle data.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="membershipID">The membership ID.</param>
        private void ProcessVehicleData(FinishModel model, int? membershipID)
        {
            CaseRepository caseRepository = new CaseRepository();
            // TODO: Waiting for clarification from the client.

            //3. Update vehicle record
            // 3.1 Get the program configuration to see if the AllowVehicleUpdate is set to yes.

            bool allowVehicleUpdate = IsVehicleUpdateAllowed(model.ProgramID, "Vehicle", "AllowVehicleUpdate");
            bool allowVehicleAdd = IsVehicleUpdateAllowed(model.ProgramID, "Vehicle", "AllowVehicleInsert");

            logger.InfoFormat("AllowVehicleUpdate : {0}, AllowVehicleInsert : {1} for Program ID : {2}", allowVehicleUpdate, allowVehicleAdd, model.ProgramID);
            if (allowVehicleUpdate || allowVehicleAdd)
            {
                logger.Info("Inside ProcessVehicleData ");
                Vehicle vehicleFromCase = caseRepository.GetVehicleInformation(model.CaseID);
                logger.Info("Case Value" + model.CaseID.ToString());
                vehicleFromCase.MembershipID = membershipID;
                VehicleRepository vehicleRepository = new VehicleRepository();
                if (vehicleFromCase.ID != 0)
                {
                    if (allowVehicleUpdate)
                    {
                        Vehicle vehicleFromVehicle = vehicleRepository.GetVehicle(vehicleFromCase.ID);

                        //KB: HasDifferences seems to be redundant here!
                        //if (HasDifferences(vehicleFromCase, vehicleFromVehicle))
                        {
                            logger.InfoFormat("Updating vehicle [ Id = {0} ]", vehicleFromCase.ID);
                            vehicleRepository.AddOrUpdateVehicle(vehicleFromCase, null, false);
                        }
                    }
                }
                if (allowVehicleAdd && vehicleFromCase.ID == 0 && vehicleFromCase.VehicleCategoryID.HasValue &&
                    vehicleFromCase.VehicleTypeID.HasValue && !string.IsNullOrEmpty(vehicleFromCase.Year) && !string.IsNullOrEmpty(vehicleFromCase.Make)
                    && !string.IsNullOrEmpty(vehicleFromCase.Model))
                {
                    bool isInsertValid = true;
                    if (vehicleFromCase.Make == "Other" && string.IsNullOrEmpty(vehicleFromCase.MakeOther))
                    {
                        isInsertValid = false;
                    }
                    else if ((vehicleFromCase.Model == "Other" && string.IsNullOrEmpty(vehicleFromCase.ModelOther)))
                    {
                        isInsertValid = false;
                    }
                    if (isInsertValid)
                    {
                        logger.InfoFormat("Adding vehicle [ Case ID = {0} ]", model.CaseID);
                        vehicleRepository.AddOrUpdateVehicle(vehicleFromCase, model.CaseID, true);
                    }
                }
            }
        }

        /// <summary>
        /// Determines whether the specified vehicle from case has differences.
        /// </summary>
        /// <param name="vehicleFromCase">The vehicle from case.</param>
        /// <param name="vehicleFromVehicle">The vehicle from vehicle.</param>
        /// <returns>
        ///   <c>true</c> if the specified vehicle from case has differences; otherwise, <c>false</c>.
        /// </returns>
        private bool HasDifferences(Vehicle vehicleFromCase, Vehicle vehicleFromVehicle)
        {
            bool returnVal = false;
            if (vehicleFromCase.GetType() == vehicleFromVehicle.GetType())
            {
                FieldInfo[] fields = vehicleFromCase.GetType().GetFields(BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public);
                foreach (FieldInfo field in fields)
                {
                    if (field.Name == "_Source")
                    {
                        break;
                    }
                    string caseField = field.GetValue(vehicleFromCase) != null ? field.GetValue(vehicleFromCase).ToString() : string.Empty;
                    string vehicleField = field.GetValue(vehicleFromVehicle) != null ? field.GetValue(vehicleFromVehicle).ToString() : string.Empty;
                    if (caseField != vehicleField)
                    {
                        returnVal = true;
                        break;
                    }
                }
            }

            return returnVal;
        }

        /// <summary>
        /// Determines whether [is vehicle update allowed] [the specified program id].
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="configurationType">Type of the configuration.</param>
        /// <param name="updateKey">The update key.</param>
        /// <returns>
        ///   <c>true</c> if [is vehicle update allowed] [the specified program id]; otherwise, <c>false</c>.
        /// </returns>
        private bool IsVehicleUpdateAllowed(int programId, string configurationType, string updateKey)
        {
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(programId, configurationType, null);
            bool allowUpdate = false;
            result.ForEach(x =>
            {
                if (x.Name == updateKey)
                {
                    allowUpdate = true;
                }
            });
            return allowUpdate;
        }

        /// <summary>
        /// Gets the service request from model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        /// <returns></returns>
        private static ServiceRequest GetServiceRequestFromModel(FinishModel model, string loggedInUser)
        {
            ServiceRequest sr = new ServiceRequest();
            sr.ID = model.ServiceRequestID;
            sr.ServiceRequestStatusID = model.ServiceRequestStatus;
            sr.NextActionScheduledDate = model.ScheduledDate;
            sr.NextActionID = model.NextAction;
            sr.NextActionAssignedToUserID = model.AssignedTo;
            sr.ClosedLoopStatusID = model.ClosedLoopStatus;
            sr.ClosedLoopNextSend = model.NextSend;
            sr.ServiceRequestPriorityID = model.Priority;
            sr.FinishTabStatus = 1;
            sr.ModifyBy = loggedInUser;
            sr.ModifyDate = DateTime.Now;
            sr.MemberPaymentTypeID = model.MemberPaymentTypeID;
            sr.ProviderClaimNumber = model.ProviderClaimNumber;
            sr.ProviderID = model.ProductProviderID;
            return sr;
        }

        public string Left(string s, int number)
        {
            if (!string.IsNullOrEmpty(s) && s.Length > number)
            {
                return s.Substring(0, number);
            }
            else if (!string.IsNullOrEmpty(s) && s.Length <= number)
            {
                return s;
            }

            return s;
        }
        #endregion
    }
}
