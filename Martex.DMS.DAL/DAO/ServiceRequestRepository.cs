using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using log4net;
using System.Data.Entity;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.DAL.Entities;
using Newtonsoft.Json;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ServiceRequestRepository
    {
        #region Protected Members
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ServiceRequestRepository));

        #endregion

        /// <summary>
        /// Adds the specified request.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="status">The status.</param>
        /// <param name="priority">The priority.</param>
        /// <returns></returns>
        public int Add(ServiceRequest request, string status, string priority = null)
        {
            logger.InfoFormat("ServiceRequestRepository - Add() --> Priority : {0}, status : {1}", priority, status);
            using (DMSEntities dbContext = new DMSEntities())
            {
                var serviceRequestStatus = dbContext.ServiceRequestStatus.Where(x => x.Name == status).FirstOrDefault();
                if (!string.IsNullOrEmpty(priority))
                {
                    // CR : 1070 - Add service request at a priority.
                    var serviceRequestPriority = dbContext.ServiceRequestPriorities.Where(p => p.Name == priority).FirstOrDefault();
                    if (serviceRequestPriority != null)
                    {
                        request.ServiceRequestPriorityID = serviceRequestPriority.ID;
                        logger.InfoFormat("ServiceRequestRepository - Add() --> PriorityID : {0}, Priority : {1}", request.ServiceRequestPriorityID, serviceRequestPriority.Name);
                    }
                }
                if (serviceRequestStatus != null)
                {
                    request.ServiceRequestStatusID = serviceRequestStatus.ID;
                }

                request.TrackerID = Guid.NewGuid();
                dbContext.ServiceRequests.Add(request);

                dbContext.SaveChanges();
                logger.InfoFormat("ServiceRequestRepository - Add() --> Service Request Added  ID : {0}, ServiceRequestPriorityID : {1}", request.ID, request.ServiceRequestPriorityID);
                return request.ID;
            }
        }

        /// <summary>
        /// Update the activity tab status for the given service request ID
        /// </summary>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <param name="modifiedBy">The modified by.</param>
        public void UpdateTabStatus(int serviceRequestId, TabConstants tab, string modifiedBy, int tabValidationStatus = 1)
        {
            logger.InfoFormat("ServiceRequestRepository - UpdateTabStatus() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                serviceRequestId = serviceRequestId,
                tabName = tab,
                modifiedBy = modifiedBy,
                tabValidationStatus = tabValidationStatus
            }));
            if (serviceRequestId > 0)
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    var serviceRequest = dbContext.ServiceRequests.Where(x => x.ID == serviceRequestId).FirstOrDefault();
                    if (serviceRequest == null)
                    {
                        throw new DMSException("Invalid service request ID " + serviceRequestId);
                    }
                    switch (tab)
                    {
                        case TabConstants.StartTab:
                            serviceRequest.StartTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.MemberTab:
                            serviceRequest.MemberTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.ServiceTab:
                            serviceRequest.ServiceTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.ActivityTab:
                            serviceRequest.ActivityTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.VehicleTab:
                            serviceRequest.VehicleTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.MapTab:
                            serviceRequest.MapTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.PaymentTab:
                            serviceRequest.PaymentTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.DispatchTab:
                            serviceRequest.DispatchTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.POTab:
                            serviceRequest.POTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.FinishTab:
                            serviceRequest.FinishTabStatus = tabValidationStatus;
                            break;
                        case TabConstants.EstimateTab:
                            serviceRequest.EstimateTabStatus = tabValidationStatus;
                            break;
                        default:
                            break;
                    }

                    serviceRequest.ModifyBy = modifiedBy;
                    serviceRequest.ModifyDate = DateTime.Now;

                    dbContext.SaveChanges();
                }
            }
            else
            {
                logger.Info("Not updating tab status as the service request id is 0");
            }
        }

        /// <summary>
        /// Gets the active service request.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public ServiceRequest GetActiveServiceRequest(int memberID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from sr in dbContext.ServiceRequests.Include(x => x.ServiceRequestStatu)
                              join c in dbContext.Cases on sr.CaseID equals c.ID
                              join srs in dbContext.ServiceRequestStatus on sr.ServiceRequestStatusID equals srs.ID
                              where c.MemberID == memberID && (srs.Name != "Complete" && srs.Name != "Cancelled")
                              select sr).OrderByDescending(sr => sr.CreateDate).Include(a => a.Case).FirstOrDefault();

                return result;
            }
        }

        /// <summary>
        /// Gets the service request ID.
        /// </summary>
        /// <returns></returns>
        public int? GetServiceRequestID()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                ServiceRequestStatu srStatus = dbContext.ServiceRequestStatus.Where(s => s.Name == "Entry").FirstOrDefault<ServiceRequestStatu>();
                if (srStatus == null)
                {
                    return null;
                    //throw new DMSException("Service Request Status is null");
                }
                return srStatus.ID;
            }
        }
        /// <summary>
        /// To Display Call Summary Details 
        /// </summary>
        /// <param name="serviceRequestId"></param>
        /// <returns></returns>
        public List<CallSummary_Result> GetCallSummary(int serviceRequestId)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetCallSummary(serviceRequestId).ToList<CallSummary_Result>();
            }
        }

        /// <summary>
        /// Gets the by id.
        /// </summary>
        /// <param name="ID">The ID.</param>
        /// <returns></returns>
        public ServiceRequest GetById(int ID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ServiceRequests.Include("Case")
                                        .Include(x => x.ServiceRequestStatu)
                                        .Include(x => x.ServiceRequestPriority)
                                        .Include(x => x.NextAction)
                                        .Include(x => x.ClosedLoopStatu)
                                        .Include(x => x.Case)
                                        .Where(x => x.ID == ID).FirstOrDefault();
                return result;
            }
        }

        /// <summary>
        /// Gets the SR by case identifier.
        /// </summary>
        /// <param name="Id">The identifier.</param>
        /// <returns></returns>
        public ServiceRequest GetByCaseId(int Id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.ServiceRequests.Include("Case").Where(x => x.CaseID == Id).FirstOrDefault();
                return result;
            }
        }


        /// <summary>
        /// Logs the service request next action change.
        /// </summary>
        /// <param name="srId">The sr identifier.</param>
        /// <param name="oldNextActionID">The old next action identifier.</param>
        /// <param name="newNextActionID">The new next action identifier.</param>
        /// <param name="nextActionAssignedToUserID">The next action assigned to user identifier.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="sessionId">The session identifier.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <exception cref="DMSException">Invalid event name</exception>
        public void LogServiceRequestNextActionChange(int srId, int? oldNextActionID, int? newNextActionID, int? nextActionAssignedToUserID, DateTime? nextActionScheduleDate, string eventSource, string sessionId, string loggedInUserName, DateTime? requestOpenedTime)
        {
            EventLogRepository eventLogRepository = new EventLogRepository();

            IRepository<Event> eventRepository = new EventRepository();
            var description = string.Empty;
            Dictionary<string, string> eventDetails = new Dictionary<string, string>();
            Hashtable ht = new Hashtable();

            string oldNextAction = string.Empty;
            string newNextAction = string.Empty;
            string nextActionAssignedToUser = string.Empty;
            CommonLookUpRepository clRepository = new CommonLookUpRepository();
            NextAction nextAction = clRepository.GetNextAction(oldNextActionID.GetValueOrDefault());
            if (nextAction != null)
            {
                oldNextAction = nextAction.Description;
            }

            nextAction = clRepository.GetNextAction(newNextActionID.GetValueOrDefault());
            if (nextAction != null)
            {
                newNextAction = nextAction.Description;
            }
            if (nextActionAssignedToUserID != null)
            {
                UserRepository userRepository = new UserRepository();
                var user = userRepository.GetUserById(nextActionAssignedToUserID.GetValueOrDefault());
                if (user != null)
                {
                    nextActionAssignedToUser = string.Format("{0} {1}", user.FirstName, user.LastName);
                }
            }
            #region Record Next Action Cleared Log
            if (oldNextActionID != null)
            {
                #region Event Log For Next Action Cleared
                var eventClearedName = EventNames.NEXT_ACTION_CLEARED;
                Hashtable clearedActionHastTable = new Hashtable();
                clearedActionHastTable.Add("ServiceRequestID", srId.ToString());
                clearedActionHastTable.Add("ClearedNextAction", oldNextAction);

                description = clearedActionHastTable.GetEventDetail();

                Event theStartedEvent = eventRepository.Get<string>(eventClearedName);

                if (theStartedEvent == null)
                {
                    throw new DMSException(string.Format("{0} - Invalid event name", EventNames.NEXT_ACTION_CLEARED));
                }

                EventLog eventLog = new EventLog();
                eventLog.Source = eventSource;
                eventLog.EventID = theStartedEvent.ID;
                eventLog.SessionID = sessionId;
                eventLog.Description = description;
                eventLog.CreateDate = DateTime.Now;
                eventLog.CreateBy = loggedInUserName;

                logger.InfoFormat("Trying to log the event {0}", eventClearedName);
                long eventLogId = eventLogRepository.Add(eventLog, srId, EntityNames.SERVICE_REQUEST);

                eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.NEXT_ACTION, oldNextActionID);

                #endregion
            }
            #endregion

            #region Record Next Action Set Log if next action is not null
            if (newNextActionID != null)
            {
                ht = new Hashtable();
                var eventName = EventNames.NEXT_ACTION_SET;
                ht.Add("ServiceRequestID", srId.ToString());
                ht.Add("NextAction", newNextAction);
                ht.Add("NextActionAssignedToUser", nextActionAssignedToUser);
                if (nextActionScheduleDate != null)
                {
                    ht.Add("ScheduledDate", nextActionScheduleDate.Value.ToString("MM/dd/yyyy hh:mm:ss tt"));
                }

                description = ht.GetEventDetail();

                var theEvent = eventRepository.Get<string>(eventName);

                if (theEvent == null)
                {
                    throw new DMSException(string.Format("{0} - Invalid event name", EventNames.NEXT_ACTION_SET));
                }

                var eventLog = new EventLog();
                eventLog.Source = eventSource;
                eventLog.EventID = theEvent.ID;
                eventLog.SessionID = sessionId;
                eventLog.Description = description;
                eventLog.CreateDate = DateTime.Now;
                eventLog.CreateBy = loggedInUserName;

                logger.InfoFormat("Trying to log the event {0}", eventName);
                var eventLogId = eventLogRepository.Add(eventLog, srId, EntityNames.SERVICE_REQUEST);

                eventLogRepository.CreateLinkRecord(eventLogId, EntityNames.NEXT_ACTION, newNextActionID);
            }
            else
            {
                #region Event Log For NEXT_ACTION_STARTED for the old Next Action if it is cleared.
                //Log the event for next action started
                if (oldNextActionID != null)
                {
                    var eventStartedName = EventNames.NEXT_ACTION_STARTED;
                    ht.Add("ServiceRequestID", srId.ToString());
                    ht.Add("ClearedNextAction", oldNextAction);
                    if (requestOpenedTime != null)
                    {
                        ht.Add("NextActionStarted", requestOpenedTime.Value.ToString("MM/dd/yyyy hh:mm:ss tt"));
                    }
                    description = ht.GetEventDetail();

                    Event theEvent = eventRepository.Get<string>(eventStartedName);

                    if (theEvent == null)
                    {
                        throw new DMSException(string.Format("{0} - Invalid event name", eventStartedName));
                    }

                    EventLog eventStartedLog = new EventLog();
                    eventStartedLog.Source = eventSource;
                    eventStartedLog.EventID = theEvent.ID;
                    eventStartedLog.SessionID = sessionId;
                    eventStartedLog.Description = description;
                    eventStartedLog.CreateDate = requestOpenedTime != null ? requestOpenedTime : DateTime.Now;//TODO: Need to check
                    eventStartedLog.CreateBy = loggedInUserName;

                    logger.InfoFormat("Trying to log the event {0}", eventStartedName);
                    long eventStartedLogId = eventLogRepository.Add(eventStartedLog, srId, EntityNames.SERVICE_REQUEST);
                    eventLogRepository.CreateLinkRecord(eventStartedLogId, EntityNames.NEXT_ACTION, oldNextActionID);

                }
                #endregion
            }
            #endregion

        }
        /// <summary>
        /// Update service request on finish.
        /// </summary>
        /// <param name="sr">The service request.</param>
        public void UpdateOnFinish(ServiceRequest sr, string eventSource, string sessionId, string loggedInUserName, DateTime? requestOpenedTime)
        {
            bool logServiceRequestNextActionChange = false;
            int? oldNextActionID = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var serviceRequest = dbContext.ServiceRequests.Where(x => x.ID == sr.ID).Include(s => s.Case).FirstOrDefault();
                if (serviceRequest != null)
                {
                    if (serviceRequest.NextActionID != sr.NextActionID)
                    {
                        logServiceRequestNextActionChange = true;
                        oldNextActionID = serviceRequest.NextActionID;
                    }
                    serviceRequest.ServiceRequestStatusID = sr.ServiceRequestStatusID;
                    serviceRequest.NextActionScheduledDate = sr.NextActionScheduledDate;
                    serviceRequest.NextActionID = sr.NextActionID;
                    serviceRequest.NextActionAssignedToUserID = sr.NextActionAssignedToUserID;
                    serviceRequest.ClosedLoopNextSend = sr.ClosedLoopNextSend;
                    if (sr.ClosedLoopStatusID != 0)
                    {
                        serviceRequest.ClosedLoopStatusID = sr.ClosedLoopStatusID;
                        if (!sr.ClosedLoopNextSend.HasValue)
                        {
                            var clStatus = dbContext.ClosedLoopStatus.Where(cls => cls.Name == "Pending").FirstOrDefault<ClosedLoopStatu>();
                            if (clStatus != null && clStatus.ID == sr.ClosedLoopStatusID)
                            {
                                serviceRequest.ClosedLoopNextSend = DateTime.Now.AddMinutes(60);
                            }
                        }
                    }
                    serviceRequest.FinishTabStatus = sr.FinishTabStatus;
                    serviceRequest.ModifyBy = sr.ModifyBy;
                    serviceRequest.ModifyDate = sr.ModifyDate;
                    serviceRequest.ServiceRequestPriorityID = sr.ServiceRequestPriorityID;
                    serviceRequest.Case.AssignedToUserID = null;
                    serviceRequest.MemberPaymentTypeID = sr.MemberPaymentTypeID;
                    serviceRequest.ProviderClaimNumber = sr.ProviderClaimNumber;
                    serviceRequest.ProviderID = sr.ProviderID;
                    dbContext.SaveChanges();
                }
            }
            if (logServiceRequestNextActionChange)
            {
                LogServiceRequestNextActionChange(sr.ID, oldNextActionID, sr.NextActionID, sr.NextActionAssignedToUserID, sr.NextActionScheduledDate, eventSource, sessionId, loggedInUserName, requestOpenedTime);
            }
        }

        /// <summary>
        /// Updates the vendor location details.
        /// </summary>
        /// <param name="serviceRequestID">The service request unique identifier.</param>
        public void UpdateVendorLocationDetails(int serviceRequestID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.UpdateVendorLocationDetails(serviceRequestID);
            }
        }

        /// <summary>
        /// Updates the map details.
        /// </summary>
        /// <param name="sr">The service request</param>
        public void UpdateMapDetails(ServiceRequest sr)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var serviceRequest = dbContext.ServiceRequests.Where(x => x.ID == sr.ID).FirstOrDefault();
                if (serviceRequest != null)
                {
                    serviceRequest.ServiceLocationAddress = serviceRequest.ServiceLocationDescription = sr.ServiceLocationAddress;
                    serviceRequest.ServiceLocationStateProvince = sr.ServiceLocationStateProvince;
                    CommonLookUpRepository staticDataRepo = new CommonLookUpRepository();

                    if (!string.IsNullOrEmpty(sr.ServiceLocationCountryCode) && sr.ServiceLocationCountryCode.Length > 2)
                    {
                        Country src = staticDataRepo.GetCountryByName(sr.ServiceLocationCountryCode);
                        if (src != null)
                        {
                            sr.ServiceLocationCountryCode = src.ISOCode;
                        }
                    }
                    if (!string.IsNullOrEmpty(sr.DestinationCountryCode) && sr.DestinationCountryCode.Length > 2)
                    {
                        Country srd = staticDataRepo.GetCountryByName(sr.DestinationCountryCode);
                        if (srd != null)
                        {
                            sr.DestinationCountryCode = srd.ISOCode;
                        }
                    }
                    serviceRequest.ServiceLocationCountryCode = sr.ServiceLocationCountryCode;
                    serviceRequest.ServiceLocationCity = sr.ServiceLocationCity;
                    serviceRequest.ServiceLocationPostalCode = sr.ServiceLocationPostalCode;
                    serviceRequest.ServiceLocationLatitude = sr.ServiceLocationLatitude;
                    serviceRequest.ServiceLocationLongitude = sr.ServiceLocationLongitude;

                    serviceRequest.DestinationAddress = serviceRequest.DestinationDescription = sr.DestinationAddress;
                    serviceRequest.DestinationStateProvince = sr.DestinationStateProvince;
                    serviceRequest.DestinationCountryCode = sr.DestinationCountryCode;
                    serviceRequest.DestinationCity = sr.DestinationCity;
                    serviceRequest.DestinationPostalCode = sr.DestinationPostalCode;

                    serviceRequest.DestinationLatitude = sr.DestinationLatitude;
                    serviceRequest.DestinationLongitude = sr.DestinationLongitude;
                    serviceRequest.ServiceLocationDescription = sr.ServiceLocationDescription;
                    serviceRequest.DestinationDescription = sr.DestinationDescription;
                    serviceRequest.DestinationVendorLocationID = sr.DestinationVendorLocationID;
                    serviceRequest.ServiceMiles = sr.ServiceMiles;
                    serviceRequest.ServiceTimeInMinutes = sr.ServiceTimeInMinutes;

                    serviceRequest.MapTabStatus = 1;
                    serviceRequest.ModifyBy = sr.ModifyBy;
                    serviceRequest.ModifyDate = sr.ModifyDate;

                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Sets the is dispatch threshold reached.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        public void SetIsDispatchThresholdReached(int serviceRequestID, bool val = true)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var serviceRequest = dbContext.ServiceRequests.Where(x => x.ID == serviceRequestID).FirstOrDefault();
                if (serviceRequest != null)
                {
                    serviceRequest.IsDispatchThresholdReached = val;
                    dbContext.SaveChanges();
                }

            }
        }

        /// <summary>
        /// Updates the service request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void UpdateServiceRequest(ServiceRequest model, string userName)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ServiceRequest srDetails = entities.ServiceRequests.Where(u => u.ID == model.ID).FirstOrDefault();
                srDetails.ServiceRequestStatusID = model.ServiceRequestStatusID;
                srDetails.ClosedLoopStatusID = model.ClosedLoopStatusID;
                srDetails.ModifyDate = DateTime.Now;
                srDetails.ModifyBy = userName;
                entities.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the closed loop status.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="DMSException">Unable to retrieve the Service Request Details</exception>
        public void UpdateClosedLoopStatus(int serviceRequestID, string userName)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ServiceRequest srDetails = entities.ServiceRequests.Where(u => u.ID == serviceRequestID).FirstOrDefault();
                int closedLoopStatusID = entities.ClosedLoopStatus.Where(n => n.Name.Equals("Pending", StringComparison.OrdinalIgnoreCase)).FirstOrDefault().ID;

                if (srDetails == null)
                {
                    throw new DMSException("Unable to retrieve the Service Request Details");
                }
                srDetails.ClosedLoopStatusID = closedLoopStatusID;
                srDetails.ModifyDate = DateTime.Now;
                srDetails.ModifyBy = userName;
                entities.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the closed loop status.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="newStatus">The new status.</param>
        /// <exception cref="DMSException">Unable to retrieve the Service Request Details</exception>
        public void UpdateClosedLoopStatus(int serviceRequestID, string userName, string newStatus)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ServiceRequest srDetails = entities.ServiceRequests.Where(u => u.ID == serviceRequestID).FirstOrDefault();
                int closedLoopStatusID = entities.ClosedLoopStatus.Where(n => n.Name.Equals(newStatus, StringComparison.OrdinalIgnoreCase)).FirstOrDefault().ID;

                if (srDetails == null)
                {
                    throw new DMSException("Unable to retrieve the Service Request Details");
                }
                srDetails.ClosedLoopStatusID = closedLoopStatusID;
                srDetails.ModifyDate = DateTime.Now;
                srDetails.ModifyBy = userName;
                entities.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the service request status.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ServiceRequestStatu GetServiceRequestStatus(string name)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.ServiceRequestStatus.Where(u => u.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
            }
        }


        public void ClearExceptions(int serviceRequestID, string requestArea)
        {
            if (serviceRequestID > 0)
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    var srExceptions = dbContext.ServiceRequestExceptions.Where(x => x.ServiceRequestID == serviceRequestID && x.RequestArea == requestArea).ToList();
                    srExceptions.ForEach(x =>
                        {
                            dbContext.Entry(x).State = EntityState.Deleted;
                        });
                    dbContext.SaveChanges();
                }
            }
        }

        public void LogException(int serviceRequestID, string requestArea, string message)
        {
            if (serviceRequestID > 0)
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    var srException = new ServiceRequestException();
                    srException.RequestArea = requestArea;
                    srException.ServiceRequestID = serviceRequestID;
                    srException.ExceptionMessage = message;

                    dbContext.ServiceRequestExceptions.Add(srException);
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets all exceptions.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="requestArea">The request area.</param>
        /// <returns></returns>
        public List<ServiceRequestException> GetAllExceptions(int serviceRequestID, string requestArea = null)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var srExceptions = dbContext.ServiceRequestExceptions.Where(x => x.ServiceRequestID == serviceRequestID && (requestArea == null || x.RequestArea == requestArea)).ToList<ServiceRequestException>();
                return srExceptions;
            }
        }

        /// <summary>
        /// Adds the service request from web request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ServiceRequestApiModel AddServiceRequestFromWebRequest(ServiceRequestApiModel model)
        {
            CommonLookUpRepository lookUprepository = new CommonLookUpRepository();
            ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName(model.ServiceType);
            int? nullableValue = null;
            Product product = null;
            User user = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                product = dbContext.Products.Where(a => a.ProductCategory.Name.Equals(model.ServiceType)
                    && (a.VehicleCategoryID == null || a.VehicleCategoryID == model.VehicleCategoryID)
                    && a.ProductType.Name.Equals("Service")
                    && a.ProductSubType.Name.Equals("PrimaryService")
                    ).FirstOrDefault();

                user = dbContext.Users.Where(a => a.FirstName.Equals("Agent") && a.LastName.Equals("User")).FirstOrDefault();
            }


            var callCustomerNextAction = lookUprepository.GetNextActionByName("CallCustomer");
            ServiceRequest sr = new ServiceRequest()
            {
                ProductCategoryID = pc != null ? pc.ID : nullableValue,
                PrimaryProductID = product != null ? product.ID : nullableValue,
                CaseID = model.CaseID.GetValueOrDefault(),
                NextActionID = nullableValue,
                NextActionAssignedToUserID = nullableValue,
                VehicleCategoryID = model.VehicleCategoryID,
                IsEmergency = model.IsEmergency,
                IsAccident = model.IsAccident,
                IsPossibleTow = model.IsPossibleTow,
                ServiceLocationAddress = model.LocationAddress,
                ServiceLocationDescription = model.ServiceLocationDescription,
                ServiceLocationCity = model.LocationCity,
                ServiceLocationStateProvince = model.LocationStateProvince,
                ServiceLocationPostalCode = model.LocationPostalCode,
                ServiceLocationCountryCode = model.LocationCountryCode,
                ServiceLocationLatitude = model.LocationLatitude,
                ServiceLocationLongitude = model.LocationLongitude,

                DestinationAddress = model.DestinationAddress,
                DestinationDescription = model.DestinationDescription,
                DestinationCity = model.DestinationCity,
                DestinationStateProvince = model.DestinationStateProvince,
                DestinationPostalCode = model.DestinationPostalCode,
                DestinationCountryCode = model.DestinationCountryCode,
                DestinationLatitude = model.DestinationLatitude,
                DestinationLongitude = model.DestinationLongitude,
                NextActionScheduledDate = null,
                StartTabStatus = 1,
                CreateDate = DateTime.Now,
                CreateBy = model.CurrentUser,
                ServiceMiles = 0,
                ServiceTimeInMinutes = 0,
                IsWorkedByTech = false,
                MileageUOM = "Miles",
                CurrencyTypeID = 1

            };
            var serviceRequestPriority = model.IsEmergency == true ? "Critical" : "Normal";
            Add(sr, "Entry", serviceRequestPriority);
            model.ServiceRequestID = sr.ID;
            model.TrackerID = sr.TrackerID.ToString();
            return model;
        }


        /// <summary>
        /// Gets the API service request.
        /// </summary>
        /// <param name="srid">The srid.</param>
        /// <returns></returns>
        public List<APIServiceRequest_Result> GetAPIServiceRequest(int? srid)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetAPIServiceRequest(srid).ToList();
            }
        }

        /// <summary>
        /// Gets the API service request list.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public List<APIServiceRequestList_Result> GetAPIServiceRequestList(ServiceRequestSearchModel model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetAPIServiceRequestList(model.CustomerID, model.CustomerGroupID, model.ProgramID, model.StartDate, model.EndDate, model.userID, model.SourceSystem).ToList();
            }
        }

        /// <summary>
        /// Updates the notes and other attributes.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="sourceSystem">The source system.</param>
        /// <param name="status">The status.</param>
        /// <param name="nextAction">The next action.</param>
        /// <param name="nextActionScheduledDate">The next action scheduled date.</param>
        /// <param name="nextActionAssignedToUser">The next action assigned to user.</param>
        /// <param name="comment">The comment.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        public void UpdateNotesAndOtherAttributes(int serviceRequestID, string sourceSystem, string status, string nextAction, DateTime? nextActionScheduledDate, string nextActionAssignedToUser, string comment, string loggedInUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.UpdateServiceRequestStatusAndNotes(serviceRequestID, sourceSystem, status, nextAction, nextActionScheduledDate, nextActionAssignedToUser, comment, loggedInUser);
            }
        }

        public ServiceRequest GetByTrackerID(Guid trackerID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var serviceRequest = dbContext.ServiceRequests.Where(x => x.TrackerID == trackerID).FirstOrDefault();
                return serviceRequest;
            }
        }

        /// <summary>
        /// Gets the status history.
        /// </summary>
        /// <param name="serviceRequestId">The service request identifier.</param>
        /// <returns></returns>
        public List<ServiceRequestStatusTimeline_Result> GetStatusHistory(int serviceRequestId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var statusHistory = dbContext.GetServiceRequestStatusTimeline(serviceRequestId).ToList<ServiceRequestStatusTimeline_Result>();
                return statusHistory;
            }
        }

        /// <summary>
        /// Sets the map snapshot.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="mapSnapshot">The map snapshot.</param>
        public void SetMapSnapshot(int serviceRequestID, string mapSnapshot)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var serviceRequest = dbContext.ServiceRequests.Where(x => x.ID == serviceRequestID).FirstOrDefault();
                serviceRequest.MapSnapshot = mapSnapshot;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the service request.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <param name="serviceRequestStatus">The service request status.</param>
        /// <param name="serviceRequestPriority">The service request priority.</param>
        /// <param name="assignedToUser">The assigned to user.</param>
        /// <param name="nextAction">The next action.</param>
        /// <param name="nextActionAssignedTo">The next action assigned to.</param>
        /// <param name="nextActionScheduledDate">The next action scheduled date.</param>
        /// <param name="isEstimateAccepted">The is estimate accepted.</param>
        /// <param name="estimateDeclinedReason">The estimate declined reason.</param>
        public void UpdateServiceRequest(int serviceRequestID,
                                            string serviceRequestStatus,
                                            string serviceRequestPriority,
                                            string assignedToUser,
                                            string nextAction,
                                            string nextActionAssignedTo,
                                            DateTime? nextActionScheduledDate,
                                            bool? isEstimateAccepted,
                                            string estimateDeclinedReason,
                                            bool? isShowOnMobile
                                            )
        {

            using (DMSEntities dbContext = new DMSEntities())
            {
                var serviceRequest = dbContext.ServiceRequests.Where(x => x.ID == serviceRequestID).FirstOrDefault();
                // Set Status.
                SetStatus(serviceRequestStatus, serviceRequest);
                SetPriority(serviceRequestPriority, serviceRequest);
                SetNextAction(nextAction, nextActionAssignedTo, nextActionScheduledDate, serviceRequest);

                if (isShowOnMobile != null)
                {
                    serviceRequest.IsShowOnMobile = isShowOnMobile;
                }

                if (isEstimateAccepted != null)
                {
                    serviceRequest.IsServiceEstimateAccepted = isEstimateAccepted.GetValueOrDefault();
                    if (!serviceRequest.IsServiceEstimateAccepted.GetValueOrDefault())
                    {
                        //TODO: Need to fill the decline reason.
                    }
                }

                var caseRecord = dbContext.Cases.Where(x => x.ID == serviceRequest.CaseID).FirstOrDefault();
                if (!string.IsNullOrWhiteSpace(assignedToUser))
                {
                    var assignedToUserForID = dbContext.Users.Where(u => u.aspnet_Users.UserName == assignedToUser).FirstOrDefault();
                    if (assignedToUserForID != null)
                    {
                        caseRecord.AssignedToUserID = assignedToUserForID.ID;
                    }
                }
                else
                {
                    caseRecord.AssignedToUserID = null;
                }

                dbContext.SaveChanges();
            }

        }

        private static void SetNextAction(string nextAction, string nextActionAssignedTo, DateTime? nextActionScheduledDate, ServiceRequest serviceRequest)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (!string.IsNullOrWhiteSpace(nextAction))
                {
                    var nextActionForID = dbContext.NextActions.Where(n => n.Name == nextAction).FirstOrDefault();
                    if (nextActionForID != null)
                    {
                        serviceRequest.NextActionID = nextActionForID.ID;
                    }
                }

                if (!string.IsNullOrWhiteSpace(nextActionAssignedTo))
                {
                    var nextActionAssignedToForID = dbContext.Users.Where(u => u.aspnet_Users.UserName == nextActionAssignedTo).FirstOrDefault();
                    if (nextActionAssignedToForID != null)
                    {
                        serviceRequest.NextActionAssignedToUserID = nextActionAssignedToForID.ID;
                    }
                }
                serviceRequest.NextActionScheduledDate = nextActionScheduledDate;
            }
        }
        /// <summary>
        /// Sets the status.
        /// </summary>
        /// <param name="serviceRequestStatus">The service request status.</param>
        /// <param name="serviceRequest">The service request.</param>
        private static void SetStatus(string serviceRequestStatus, ServiceRequest serviceRequest)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (!string.IsNullOrWhiteSpace(serviceRequestStatus))
                {
                    var status = dbContext.ServiceRequestStatus.Where(s => s.Name == serviceRequestStatus).FirstOrDefault();
                    if (status != null)
                    {
                        serviceRequest.ServiceRequestStatusID = status.ID;
                    }
                }
            }
        }

        /// <summary>
        /// Sets the priority.
        /// </summary>
        /// <param name="serviceRequestPriority">The service request priority.</param>
        /// <param name="serviceRequest">The service request.</param>
        private static void SetPriority(string serviceRequestPriority, ServiceRequest serviceRequest)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (!string.IsNullOrWhiteSpace(serviceRequestPriority))
                {
                    var priority = dbContext.ServiceRequestPriorities.Where(s => s.Name == serviceRequestPriority).FirstOrDefault();
                    if (priority != null)
                    {
                        serviceRequest.ServiceRequestPriorityID = priority.ID;
                    }
                }
            }
        }

        /// <summary>
        /// Gets the contact log actions.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        public List<ContactLogActionsForServiceRequest_Result> GetContactLogActions(int serviceRequestID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetContactLogActionsForServiceRequest(serviceRequestID).ToList<ContactLogActionsForServiceRequest_Result>();
            }
        }

        public void UpdateNextActionDetails(int serviceRequestID, string nextAction, DateTime? nextActionScheduledDate, string nextActionAssignedTo, string eventSource, string sessionID, string currentUser)
        {
            var serviceRequestRepository = new ServiceRequestRepository();

            //Get NextActionID
            var nextActionRepository = new CommonLookUpRepository();
            var nextActionFromDb = nextActionRepository.GetNextActionByName(nextAction);
            int? nextActionID = null;
            int? oldNextActionID = null;
            if (nextActionFromDb != null)
            {
                nextActionID = nextActionFromDb.ID;
            }

            //Get User ID
            int? userId = null;
            if (!string.IsNullOrWhiteSpace(nextActionAssignedTo))
            {
                UserRepository userRepository = new UserRepository();
                var aspnetUser = userRepository.GetUserByName(nextActionAssignedTo);
                if (aspnetUser == null || aspnetUser.Users == null)
                {
                    throw new DMSException(string.Format("User - {0} not found in the system", nextActionAssignedTo));
                }
                var user = aspnetUser.Users.FirstOrDefault();
                userId = user.ID;
            }
            using (DMSEntities dbContext = new DMSEntities())
            {
                var serviceRequest = dbContext.ServiceRequests.Where(x => x.ID == serviceRequestID).FirstOrDefault();
                oldNextActionID = serviceRequest.NextActionID;

                serviceRequest.NextActionID = nextActionID;
                serviceRequest.NextActionScheduledDate = nextActionScheduledDate;
                serviceRequest.NextActionAssignedToUserID = userId;
                dbContext.SaveChanges();
            }
            serviceRequestRepository.LogServiceRequestNextActionChange(serviceRequestID, oldNextActionID, nextActionID, userId, nextActionScheduledDate, eventSource, sessionID, currentUser, null);
        }
    }
}
