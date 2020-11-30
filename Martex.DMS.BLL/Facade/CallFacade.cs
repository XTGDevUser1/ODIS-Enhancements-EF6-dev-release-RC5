using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;
using System.Transactions;

using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class CallFacade
    {
        protected static ILog logger = LogManager.GetLogger(typeof(CallFacade));

        /// <summary>
        /// Starts the call.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Invalid event name</exception>
        public static int StartCall(Guid userId, string eventSource, string sessionID)
        {
            logger.InfoFormat("CallFacade - StartCall(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                userId = userId,
                eventSource = eventSource,
                sessionID = sessionID
            }));
            //using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, new TransactionOptions { IsolationLevel = IsolationLevel.Snapshot }))
            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    logger.Info("Attempting to create InboundCall and EventLog records");
                    UserRepository userRepository = new UserRepository();
                    aspnet_Users loggedInUser = userRepository.Get<Guid>(userId);

                    string loggedInUserName = loggedInUser.UserName;

                    InboundCallRepository inboundCallRepository = new InboundCallRepository();
                    int inboundCallId = inboundCallRepository.Add(new InboundCall()
                    {
                        AssignedtoUserID = loggedInUser.Users.FirstOrDefault().ID,
                        CreateBy = loggedInUserName,
                        CreateDate = DateTime.Now,
                        ModifyBy = loggedInUserName,
                        ModifyDate = DateTime.Now

                    });

                    //For Event Log
                    EventLogRepository eventLogRepository = new EventLogRepository();

                    IRepository<Event> eventRepository = new EventRepository();
                    Event theEvent = eventRepository.Get<string>(EventNames.START_CALL);

                    if (theEvent == null)
                    {
                        throw new DMSException("Invalid event name " + EventNames.START_CALL);
                    }

                    EventLog eventLog = new EventLog();
                    eventLog.Source = eventSource;
                    eventLog.EventID = theEvent.ID;
                    eventLog.SessionID = sessionID;
                    eventLog.Description = "Start Call process initiated by agent";
                    eventLog.CreateDate = DateTime.Now;
                    eventLog.CreateBy = loggedInUserName;

                    logger.InfoFormat("Trying to log the event {0}", EventNames.START_CALL);
                    long eventLogId = eventLogRepository.Add(eventLog, inboundCallId, EntityNames.INBOUND_CALL);

                    tran.Complete();
                    logger.InfoFormat("CallFacade - StartCall(), Inbound call records created : {0}", inboundCallId);
                    return inboundCallId;
                }
                catch (Exception ex)
                {
                    logger.Warn(ex.Message, ex);
                    throw ex;
                }
            }
        }

        public static void NewRequest(CallInformation ci, out int caseId, out int serviceRequestId, string sessionId, int memberProgramID, ServiceRequestAgentTime srAgentTime, MobileCallData_Result mobileRecord = null)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    var currentDate = DateTime.Now;
                    var loggedInUserName = ci.UserProfile.Key;

                    MemberRepository memberRepository = new MemberRepository();
                    Member member = memberRepository.Get(ci.MemberId.Value);

                    #region 1. Save Inbound call data.

                    SaveInboundCall(ci);

                    #endregion

                    #region 2. Create a case
                    var dispatchSourceSystem = ReferenceDataRepository.GetSourceSystemByName(SourceSystemName.DISPATCH);

                    Case c = new Case()
                    {
                        ProgramID = memberProgramID,
                        MemberID = ci.MemberId,
                        //KB: Member management : Using membership number in the place of member number.
                        MemberNumber = member.Membership != null ? member.Membership.MembershipNumber : null,
                        CallTypeID = ci.CallTypeId,
                        Language = ci.LanguageId.ToString(),
                        ContactPhoneTypeID = ci.ContactPhoneTypeID,
                        ContactPhoneNumber = ci.ContactPhoneNumber,
                        ContactAltPhoneTypeID = ci.ContactAltPhoneTypeID,
                        ContactAltPhoneNumber = ci.ContactAltPhoneNumber,
                        CreateBy = loggedInUserName,
                        CreateDate = currentDate,
                        ModifyBy = loggedInUserName,
                        ModifyDate = currentDate,
                        AssignedToUserID = ci.UserProfile.Value,
                        IsSafe = ci.isSafe,
                        MemberStatus = member.EffectiveDate.GetValueOrDefault() <= DateTime.Today && member.ExpirationDate.GetValueOrDefault() >= DateTime.Today ? "Active" : "Inactive",
                        //TFS: 1362 : Create Case with SourceSystemID = Dispatch when the case is created from ODIS.
                        SourceSystemID = dispatchSourceSystem != null ? dispatchSourceSystem.ID : (int?)null
                    };

                    if (mobileRecord != null)
                    {
                        c.ContactFirstName = mobileRecord.FirstName;
                        c.ContactLastName = mobileRecord.LastName;
                        c.IsSMSAvailable = true;
                    }
                    CaseRepository caseRepository = new CaseRepository();
                    caseId = caseRepository.Add(c, "Open");
                    logger.InfoFormat("Case {0} created with ProgramID = {1} and memberID = {2}", caseId, c.ProgramID.GetValueOrDefault(), c.MemberID.GetValueOrDefault());
                    #endregion

                    #region 3. Entity Program Data Item records

                    int currentMileage = Int32.MinValue;
                    if (ci.DynamicDataElements != null)
                    {
                        int programDataItemId = 0;
                        string[] tokens = null;
                        foreach (var item in ci.DynamicDataElements)
                        {
                            programDataItemId = 0;
                            tokens = item.Key.Split('$');
                            if ("CurrentMileage".Equals(tokens[0], StringComparison.InvariantCultureIgnoreCase))
                            {
                                int.TryParse(item.Value, out currentMileage);
                            }
                            int.TryParse(tokens[1], out programDataItemId);
                            if (programDataItemId != 0)
                            {
                                ProgramMaintenanceRepository.AddDynamicDataValue(EntityNames.CASE, caseId, programDataItemId, item.Value, loggedInUserName);
                            }
                        }
                    }

                    #endregion

                    #region 4. EventLog records for Case
                    //For Event Log
                    EventLogRepository eventLogRepository = new EventLogRepository();

                    IRepository<Event> eventRepository = new EventRepository();
                    Event theEvent = eventRepository.Get<string>(EventNames.START_CASE);

                    if (theEvent == null)
                    {
                        throw new DMSException("Invalid event name");
                    }

                    EventLog eventLog = new EventLog();
                    eventLog.Source = ci.EventSource;
                    eventLog.EventID = theEvent.ID;
                    eventLog.SessionID = sessionId;
                    eventLog.Description = "Start Case";
                    eventLog.CreateDate = currentDate;
                    eventLog.CreateBy = loggedInUserName;

                    logger.InfoFormat("Trying to log the event {0}", EventNames.START_CASE);
                    long eventLogId = eventLogRepository.Add(eventLog, caseId, EntityNames.CASE);

                    #endregion

                    #region 5. Set Case ID on inbound call
                    InboundCallRepository icRepository = new InboundCallRepository();
                    InboundCall inboundCall = GetInboundCall(ci);
                    inboundCall.CaseID = c.ID;
                    icRepository.Save(inboundCall);
                    #endregion

                    #region Set Current mileage from Program Data items (if available)

                    if (currentMileage != Int32.MinValue)
                    {
                        logger.InfoFormat("Setting VehicleCurrentMileage on Case [{0}] to {1}", caseId, currentMileage);
                        caseRepository.SetVehicleCurrentMileage(caseId, currentMileage);
                    }
                    #endregion

                    #region Set Claim Number from Program Data Items (if available)
                    logger.InfoFormat("Checking for Program Data Item {0} For Member {1}", ProgramDataItemNames.CLAIM_NUMBER, c.MemberID.GetValueOrDefault());
                    ProgramDataItemValueEntity claimNumberProgramDataItem = ProgramMaintenanceRepository.Get(EntityNames.MEMBER, c.MemberID.GetValueOrDefault(), ProgramDataItemNames.CLAIM_NUMBER);
                    if (claimNumberProgramDataItem != null && !string.IsNullOrEmpty(claimNumberProgramDataItem.Value))
                    {
                        logger.InfoFormat("Setting Claim Number on Case [{0}] to {1}", caseId, claimNumberProgramDataItem.Value);
                        caseRepository.SetClaimReferenceNumber(caseId, claimNumberProgramDataItem.Value);
                    }
                    else
                    {
                        logger.Info("Not found !");
                    }
                    #endregion

                    #region Set Case ID on CasePhoneLocation too
                    icRepository.UpdateCasePhoneLocationWithCaseID(inboundCall.ID, c.ID);
                    var casePhoneLocation = (new CasePhoneLocationRepository()).GetByInboundCallId(inboundCall.ID);
                    #endregion

                    #region 6. Emergency

                    var emergencyRepository = new EmergencyAssistanceRepository();
                    emergencyRepository.UpdateCaseDetails(ci.InboundCallId, caseId, loggedInUserName);

                    #endregion

                    #region 7. ServiceRequest

                    // Sanghi : Retrieve the details from Emergency Assistance and Assign them into Service Request
                    var emergencyRecord = emergencyRepository.GetEmergencyAssistance(ci.InboundCallId);

                    ServiceRequest request = new ServiceRequest()
                    {
                        CaseID = caseId,
                        IsEmergency = false,
                        IsAccident = false,
                        IsWorkedByTech = false, /* CR : 1023 Start Tab - set ServiceRequest.IsWorkedyTech to 0 */
                        CreateBy = loggedInUserName,
                        CreateDate = currentDate,
                        ModifyBy = loggedInUserName,
                        ModifyDate = currentDate,
                        ServiceRequestStatusID = GetServiceRequestStatisID(),
                        StartTabStatus = 1,
                        ServiceLocationAddress = emergencyRecord == null ? null : emergencyRecord.Address,
                        ServiceLocationCrossStreet1 = emergencyRecord == null ? null : emergencyRecord.CrossStreet1,
                        ServiceLocationCrossStreet2 = emergencyRecord == null ? null : emergencyRecord.CrossStreet2,
                        ServiceLocationStateProvince = emergencyRecord == null ? null : emergencyRecord.StateProvince,
                        ServiceLocationPostalCode = emergencyRecord == null ? null : emergencyRecord.PostalCode,
                        ServiceLocationCountryCode = emergencyRecord == null ? null : emergencyRecord.Country,
                        ServiceLocationLatitude = emergencyRecord == null ? null : emergencyRecord.Latitude,
                        ServiceLocationLongitude = emergencyRecord == null ? null : emergencyRecord.Longitude,

                    };

                    if (mobileRecord != null && emergencyRecord.Latitude == null && emergencyRecord.Longitude == null)
                    {
                        request.ServiceLocationLatitude = Convert.ToDecimal(mobileRecord.locationLatitude);
                        request.ServiceLocationLongitude = Convert.ToDecimal(mobileRecord.locationLongtitude);
                        var pc = GetProductCategoryByNameFromMobile(mobileRecord.serviceType);
                        if (pc != null)
                        {
                            request.ProductCategoryID = pc.ID;
                        }
                    }
                    else // Hoping that there exists a casephonelocation record with latitude and longitude information.
                    {
                        if (casePhoneLocation != null)
                        {
                            request.ServiceLocationLatitude = casePhoneLocation.CivicLatitude;
                            request.ServiceLocationLongitude = casePhoneLocation.CivicLongitude;
                        }
                    }
                    ServiceRequestRepository requestRepository = new ServiceRequestRepository();
                    serviceRequestId = requestRepository.Add(request, "Entry", "Normal");
                    #endregion

                    #region 8. EventLog records for ServiceRequest

                    theEvent = eventRepository.Get<string>(EventNames.START_SERVICE_REQUEST);

                    if (theEvent == null)
                    {
                        throw new DMSException("Invalid event name : " + EventNames.START_SERVICE_REQUEST);
                    }

                    eventLog = new EventLog();
                    eventLog.Source = ci.EventSource;
                    eventLog.EventID = theEvent.ID;
                    eventLog.SessionID = sessionId;
                    eventLog.Description = "Start Service Request";
                    eventLog.CreateDate = currentDate;
                    eventLog.CreateBy = loggedInUserName;

                    logger.InfoFormat("Trying to log the event {0}", EventNames.START_SERVICE_REQUEST);
                    eventLogId = eventLogRepository.Add(eventLog, serviceRequestId, EntityNames.SERVICE_REQUEST);
                    eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.PROGRAM, member.ProgramID);
                    eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.CLIENT, member != null && member.Program != null ? member.Program.ClientID : null);
                    #endregion

                    #region 9. ServiceRequestAgentTime

                    var srAgentTimeRepository = new SRAgentTimeRepository();

                    srAgentTime.BeginEventLogID = eventLogId;
                    srAgentTime.ServiceRequestID = serviceRequestId;
                    srAgentTime.UserName = loggedInUserName;

                    srAgentTimeRepository.Create(srAgentTime);

                    #endregion

                    tran.Complete();
                }
                catch (Exception ex)
                {
                    logger.Warn(ex.Message, ex);
                    throw ex;
                }
            }
        }


        /// <summary>
        /// Gets the product category by name from mobile.
        /// </summary>
        /// <param name="pcName">Name of the pc.</param>
        /// <returns></returns>
        public static ProductCategory GetProductCategoryByNameFromMobile(string pcName)
        {
            ProductCategory pc = null;
            switch (pcName)
            {
                case "Tow":
                    pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                    break;
                case "Flat Tire":
                    pc = ReferenceDataRepository.GetProductCategoryByName("Tire");
                    break;
                case "Lockout":
                    pc = ReferenceDataRepository.GetProductCategoryByName("Lockout");
                    break;
                case "Battery":
                    pc = ReferenceDataRepository.GetProductCategoryByName("Jump");
                    break;
                case "Fuel Delivery":
                    pc = ReferenceDataRepository.GetProductCategoryByName("Fluid");
                    break;
                default:
                    break;
            }
            return pc;
        }


        /// <summary>
        /// Actives the request.
        /// </summary>
        /// <param name="ci">The ci.</param>
        /// <param name="caseId">The case id.</param>
        /// <param name="serviceRequestId">The service request id.</param>
        public static void ActiveRequest(CallInformation ci, out int caseId, out int serviceRequestId)
        {
            caseId = 0;
            serviceRequestId = 0;
            ServiceRequestRepository repository = new ServiceRequestRepository();
            ServiceRequest sr = null;
            if (ci != null && ci.MemberId.HasValue)
            {
                sr = repository.GetActiveServiceRequest(ci.MemberId.Value);

            }
            var currentDate = DateTime.Now;
            var loggedInUserName = ci.UserProfile.Key;

            using (TransactionScope tran = new TransactionScope())
            {
                if (sr != null)
                {
                    caseId = sr.CaseID;
                    serviceRequestId = sr.ID;
                    InboundCallRepository icRepository = new InboundCallRepository();
                    InboundCall inboundCall = GetInboundCall(ci);
                    inboundCall.CaseID = sr.CaseID;
                    icRepository.Save(inboundCall);
                    int currentMileage = Int32.MinValue;
                    string[] tokens = null;
                    // CR : Save Program Dynamic elements.
                    if (ci.DynamicDataElements != null)
                    {
                        int programDataItemId = 0;
                        foreach (var item in ci.DynamicDataElements)
                        {
                            programDataItemId = 0;
                            tokens = item.Key.Split('$');
                            if ("CurrentMileage".Equals(tokens[0], StringComparison.InvariantCultureIgnoreCase))
                            {
                                int.TryParse(item.Value, out currentMileage);
                            }
                            int.TryParse(tokens[1], out programDataItemId);

                            if (programDataItemId != 0)
                            {
                                ProgramMaintenanceRepository.AddDynamicDataValue(EntityNames.CASE, caseId, programDataItemId, item.Value, loggedInUserName);
                            }
                        }
                    }


                    #region Set Current mileage from Program Data items (if available)
                    CaseRepository caseRepository = new CaseRepository();
                    //if (currentMileage != Int32.MinValue)
                    //{
                    //    logger.InfoFormat("Setting VehicleCurrentMileage on Case [{0}] to {1}", caseId, currentMileage);
                    //    //caseRepository.SetVehicleCurrentMileage(caseId, currentMileage);
                    //}
                    #endregion

                    ServiceRequestRepository serviceRepository = new ServiceRequestRepository();
                    serviceRepository.UpdateTabStatus(sr.ID, TabConstants.StartTab, loggedInUserName);

                }
                tran.Complete();
            }

        }

        public static int? GetActiveServiceRequestId(CallInformation ci)
        {
            int? serviceRequestId = null;
            ServiceRequestRepository repository = new ServiceRequestRepository();
            ServiceRequest sr = null;
            if (ci != null && ci.MemberId.HasValue)
            {
                sr = repository.GetActiveServiceRequest(ci.MemberId.Value);

            }
            if (sr != null)
            {
                serviceRequestId = sr.ID;
            }
            return serviceRequestId;
        }

        /// <summary>
        /// Gets the user working on active service request.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public static int? GetUserWorkingOnActiveServiceRequest(int memberID)
        {
            ServiceRequestRepository repository = new ServiceRequestRepository();
            ServiceRequest sr = repository.GetActiveServiceRequest(memberID);
            if (sr != null && sr.Case != null)
            {
                return sr.Case.AssignedToUserID;
            }
            return null;
        }

        /// <summary>
        /// Gets the service request statis ID.
        /// </summary>
        /// <returns></returns>
        private static int? GetServiceRequestStatisID()
        {
            ServiceRequestRepository srRepository = new ServiceRequestRepository();
            return srRepository.GetServiceRequestID();
        }

        /// <summary>
        /// Saves the inbound call.
        /// </summary>
        /// <param name="ci">The ci.</param>
        public static void SaveInboundCall(CallInformation ci)
        {
            InboundCall inboundCall = GetInboundCall(ci);
            InboundCallRepository icRepository = new InboundCallRepository();
            icRepository.Save(inboundCall);
        }

        /// <summary>
        /// Gets the inbound call.
        /// </summary>
        /// <param name="ci">The ci.</param>
        /// <returns></returns>
        private static InboundCall GetInboundCall(CallInformation ci)
        {
            var currentDate = DateTime.Now;
            var loggedInUserName = ci.UserProfile.Key;

            InboundCall inboundCall = new InboundCall()
            {
                ID = ci.InboundCallId,
                ProgramID = ci.ProgramId,
                CallTypeID = ci.CallTypeId,
                Language = ci.LanguageId,
                ContactPhoneTypeID = ci.ContactPhoneTypeID,
                ContactPhoneNumber = ci.ContactPhoneNumber,
                ContactAltPhoneTypeID = ci.ContactAltPhoneTypeID,
                ContactAltPhoneNumber = ci.ContactAltPhoneNumber,
                IsSafe = ci.isSafe,
                ModifyBy = loggedInUserName,
                ModifyDate = currentDate,
                CaseID = ci.CaseID == 0 ? null : ci.CaseID
            };
            return inboundCall;
        }

        /// <summary>
        /// Gets the contact category ID.
        /// </summary>
        /// <param name="callTypeId">The call type id.</param>
        /// <returns></returns>
        public static int? GetContactCategoryID(int callTypeId)
        {
            InboundCallRepository icRepository = new InboundCallRepository();
            return icRepository.GetContactCategoryID(callTypeId);
        }

        /// <summary>
        /// Gets the inbound call by id.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public static InboundCall GetInboundCallById(int id)
        {
            InboundCallRepository inboundCallRepository = new InboundCallRepository();
            return inboundCallRepository.GetInboundCallById(id);
        }

        /// <summary>
        /// Saves the specified call.
        /// </summary>
        /// <param name="call">The call.</param>
        public static void Save(InboundCall call)
        {
            InboundCallRepository inboundCallRepository = new InboundCallRepository();
            inboundCallRepository.Save(call);
        }

        /// <summary>
        /// Gets the call summary.
        /// </summary>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <returns></returns>
        public List<CallSummary_Result> GetCallSummary(int serviceRequestId)
        {
            ServiceRequestRepository repository = new ServiceRequestRepository();
            return repository.GetCallSummary(serviceRequestId);
        }


        /// <summary>
        /// Gets the tab validation status.
        /// </summary>
        /// <param name="serviceRequestID">The service request unique identifier.</param>
        /// <param name="tabName">Name of the tab.</param>
        /// <returns></returns>
        public static TabValidationStatus GetTabValidationStatus(int serviceRequestID, RequestArea tabName)
        {
            ServiceRequestRepository srRepository = new ServiceRequestRepository();
            var serviceRequest = srRepository.GetById(serviceRequestID);

            TabValidationStatus tabValidationStatus = TabValidationStatus.NOT_VISITED;
            if (serviceRequest != null)
            {
                switch (tabName)
                {
                    case RequestArea.START:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.StartTabStatus);
                        break;
                    case RequestArea.MEMBER:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.MemberTabStatus);
                        break;
                    case RequestArea.VEHICLE:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.VehicleTabStatus);
                        break;
                    case RequestArea.SERVICE:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.ServiceTabStatus);
                        break;
                    case RequestArea.MAP:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.MapTabStatus);
                        break;
                    case RequestArea.ESTIMATE:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.EstimateTabStatus);
                        break;
                    case RequestArea.DISPATCH:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.DispatchTabStatus);
                        break;
                    case RequestArea.PO:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.POTabStatus);
                        break;
                    case RequestArea.PAYMENT:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.PaymentTabStatus);
                        break;
                    case RequestArea.FINISH:
                        tabValidationStatus = ToTabValidationStatus(serviceRequest.FinishTabStatus);
                        break;
                }

                var srExceptions = srRepository.GetAllExceptions(serviceRequestID, tabName.ToString());

                if (srExceptions.Count > 0)
                {
                    tabValidationStatus = TabValidationStatus.VISITED_WITH_ERRORS;
                }
            }

            return tabValidationStatus;
        }

        /// <summary>
        /// Automatics the tab validation status.
        /// </summary>
        /// <param name="tabStatusFromSR">The tab status from source.</param>
        /// <returns></returns>
        private static TabValidationStatus ToTabValidationStatus(int? tabStatusFromSR)
        {
            TabValidationStatus tabValidationStatus = TabValidationStatus.NOT_VISITED;
            Enum.TryParse<TabValidationStatus>(tabStatusFromSR.GetValueOrDefault().ToString(), out tabValidationStatus);

            return tabValidationStatus;
        }

        /// <summary>
        /// Gets all tab validation statuses.
        /// </summary>
        /// <param name="serviceRequestID">The service request unique identifier.</param>
        /// <returns></returns>
        public static List<KeyValuePair<string, TabValidationStatus>> GetAllTabValidationStatuses(int serviceRequestID)
        {
            ServiceRequestRepository srRepository = new ServiceRequestRepository();
            var serviceRequest = srRepository.GetById(serviceRequestID);
            List<KeyValuePair<string, TabValidationStatus>> kvp = new List<KeyValuePair<string, TabValidationStatus>>();

            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.START.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.START)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.MEMBER.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.MEMBER)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.VEHICLE.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.VEHICLE)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.SERVICE.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.SERVICE)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.MAP.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.MAP)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.ESTIMATE.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.ESTIMATE)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.DISPATCH.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.DISPATCH)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.PO.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.PO)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.PAYMENT.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.PAYMENT)));
            kvp.Add(new KeyValuePair<string, TabValidationStatus>(RequestArea.FINISH.ToString(), GetTabValidationStatus(serviceRequestID, RequestArea.FINISH)));

            return kvp;
        }

        /// <summary>
        /// Gets all exceptions.
        /// </summary>
        /// <param name="serviceRequestID">The service request unique identifier.</param>
        /// <param name="requestArea">The request area.</param>
        /// <returns></returns>
        public static List<ServiceRequestException> GetAllExceptions(int serviceRequestID, RequestArea? requestArea)
        {
            ServiceRequestRepository srRepository = new ServiceRequestRepository();
            return srRepository.GetAllExceptions(serviceRequestID, requestArea == null ? null : requestArea.ToString());
        }
    }
}
