using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using System.Text;
using System.Collections;
using Martex.DMS.Models;
using System.Web.Security;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Model;
using System.Xml;
using Newtonsoft.Json;
using Martex.DMS.DAL.DMSBaseException;


namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class QueueController : BaseController
    {
        #region Action
        /// <summary>
        /// Present the queue listing
        /// </summary>
        /// <returns>
        /// Queue list
        /// </returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_QUEUE)]
        [ReferenceDataFilter(StaticData.QueueFilterItems, false)]
        [ReferenceDataFilter(StaticData.NextAction, false)]
        [ReferenceDataFilter(StaticData.ClosedLoopStatus, false)]
        [ReferenceDataFilter(StaticData.ServiceType, false)]
        [ReferenceDataFilter(StaticData.Priorities, false)]
        [ReferenceDataFilter(StaticData.Clients, false)]
        [NoCache]
        public ActionResult Index()
        {

            logger.Info("Inside Index() of QueueController. Attempt to call the view");
            DMSCallContext.Reset();
            QueueFacade queueFacade = new QueueFacade();
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 100,
                PageSize = 100,
                SortDirection = "",
                SortColumn = ""
            };
            List<Queue_Result> list = queueFacade.List((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);

            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows;
            }
            ViewData["RefreshTime"] = AppConfigRepository.GetValue(AppConfigConstants.QUEUE_REFRESH_SECONDS);
            ViewData["QueueDisplayHours"] = AppConfigRepository.GetValue(AppConfigConstants.QUEUE_DISPLAY_HOURS);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            return View(list);

        }

        /// <summary>
        /// Lists the Queue.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="filterColumnName">Name of the filter column.</param>
        /// <param name="filterColumnValue">The filter column value.</param>
        /// <param name="statusValues">The status values.</param>
        /// <returns>
        /// Queue list
        /// </returns>
        [NoCache]
        [DMSAuthorize]
        [ValidateInput(false)]
        public ActionResult List([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, string statusValues)
        {
            logger.InfoFormat("QueueController - List(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                DataSourceRequest = request,
                filterColumnName = filterColumnName,
                filterColumnValue = filterColumnValue,
                statusValues = statusValues
            }));
            logger.Info("Inside List() of QueueController. Attempt to get Queue depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            List<NameValuePair> filterParams = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(filterColumnName))
            {
                filterParams.Add(new NameValuePair() { Name = filterColumnName, Value = filterColumnValue });
            }
            if (!string.IsNullOrEmpty(statusValues))
            {
                filterParams.Add(new NameValuePair() { Name = "Status", Value = statusValues });
            }
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = GetCustomWhereClauseXml(filterParams)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            QueueFacade queueFacade = new QueueFacade();
            queueFacade.ResetQueueStatusList();             //Lakshmi - Queue Color
            List<Queue_Result> list = queueFacade.List((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);
            logger.InfoFormat("QueueController - List() - Got {0} records from [QueueFacade - List()]", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows;
            }
            //logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            logger.InfoFormat("QueueController - List(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                ListCount = list.Count
            }));
            return Json(new DataSourceResult() { Data = list, Total = totalRows });

        }

        /// <summary>
        /// Gets the queue id.
        /// </summary>
        /// <param name="queueId">The queue id.</param>
        /// <returns>
        /// queue Id
        /// </returns>
        public ActionResult GetQueueId(string queueId)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside GetQueueId( {0} ) of QueueController.", queueId);
            return Json(new { queueIdValue = queueId }, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// Gets the specified Service Request details.
        /// </summary>
        /// <param name="queueId">The queue id.</param>
        /// <param name="fromStartCall">From start call.</param>
        /// <param name="isEditRequired">The is edit required.</param>
        /// <returns>
        /// ServiceRequest_Result
        /// </returns>
        [HttpPost]
        [DMSAuthorize]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult Get(string queueId, bool? fromStartCall, bool? isEditRequired, bool? fromLockedRequest = false)
        {
            logger.InfoFormat("QueueController - Get(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                CaseNumber = queueId,
                fromStartCall = fromStartCall,
                isEditRequired = isEditRequired,
                fromLockedRequest = fromLockedRequest
            }));
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;

            // logger.InfoFormat("Inside Get( {0} ) of QueueController.", queueId);
            ViewData["CaseNumber"] = queueId;
            int inboundCallId = DMSCallContext.InboundCallID;
            string loggedInUserName = GetLoggedInUser().UserName;
            QueueFacade queueFacade = new QueueFacade();
            List<ServiceRequest_Result> serviceRequestResult = queueFacade.Get(loggedInUserName, Request.RawUrl, inboundCallId, queueId, fromStartCall ?? false, HttpContext.Session.SessionID);
            int serviceRequestID = 0;
            int.TryParse(queueId, out serviceRequestID);
            DMSCallContext.ServiceRequestID = serviceRequestID;
            DMSCallContext.RequestOpenedTime = DateTime.Now;
            List<QuestionAnswer_ServiceRequest_Result> listQuestionAnswer = queueFacade.GetQuestionAnswerForServiceRequest(serviceRequestID, serviceRequestResult[0].SourceSystemName);
            ViewData["SRQuestionAnswers"] = listQuestionAnswer;

            ViewData["FromLockedRequest"] = fromLockedRequest;

            ViewData["AssignedTo"] = string.Empty;
            ViewData["isLockRequired"] = true;
            ViewData["MemberEligibilityApplies"] = false;
            ViewData["MemberProductsRelatedCoverage"] = new List<MemberProductsUsingCategory_Result>();
            if (serviceRequestResult != null && serviceRequestResult.Count > 0)
            {
                ViewData["AssignedTo"] = serviceRequestResult[0].AssignedTo;
                ViewData["AssignedToID"] = serviceRequestResult[0].AssignedToID;
                if (serviceRequestResult[0].AssignedToID == null)
                {
                    ViewData["isLockRequired"] = false;
                }

                DMSCallContext.ClientName = serviceRequestResult.ElementAt(0).Client;
                ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
                var programResult = programMaintenanceRepository.GetProgramInfo(serviceRequestResult[0].ProgramID, "Service", "Validation");
                bool memberEligibleApllies = false;

                var item = programResult.Where(x => (x.Name.Equals("MemberEligibilityApplies", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                if (item != null)
                {
                    memberEligibleApllies = true;
                }
                ViewData["MemberEligibilityApplies"] = memberEligibleApllies;

                int? memberID = serviceRequestResult[0].MemberID;
                MemberManagementFacade memberFacade  = new MemberManagementFacade();
                ViewData["MemberProductsRelatedCoverage"] = memberFacade.GetMemberProducts(memberID, null, null);
            }

            ViewBag.FromStartCall = fromStartCall;
            ViewBag.IsEditRequired = isEditRequired;
            logger.InfoFormat("Call the partial view _Queue");
            return PartialView("_NewServiceRequestDetails", serviceRequestResult);

        }

        /// <summary>
        /// Edits the service request.
        /// </summary>
        /// <param name="assignTo">The assign to.</param>
        /// <param name="assignToID">The assign to ID.</param>
        /// <param name="caseId">The case id.</param>
        /// <param name="serRequest">The ser request.</param>
        /// <param name="isFromStartCall">if set to <c>true</c> [is from start call].</param>
        /// <param name="isOpenClicked">if set to <c>true</c> [is open clicked].</param>
        /// <param name="isFromHistory">if set to <c>true</c> [is from history].</param>
        /// <param name="POID">The POID.</param>
        /// <returns>
        /// _AccessRequest
        /// </returns>
        [HttpPost]
        [DMSAuthorize]
        [ValidateInput(false)]
        public ActionResult Edit(string assignTo, int? assignToID, string caseId, int serRequest, bool isFromStartCall = false, bool isOpenClicked = false, bool isFromHistory = false, int? POID = null)
        {
            logger.InfoFormat("QueueController - Edit(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                assignTo = assignTo,
                assignToID = assignToID,
                caseId = caseId,
                srId = serRequest,
                isFromStartCall = isFromStartCall,
                isOpenClicked = isOpenClicked,
                isFromHistory = isFromHistory,
                POID = POID
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            //logger.InfoFormat("Inside Edit( {0} ) of QueueController.", assignTo);
            ViewData["isAssignedToUserValid"] = false;
            QueueFacade queueFacade = new QueueFacade();

            // Current Active User
            User user = queueFacade.getUser(GetLoggedInUser().ProviderUserKey.ToString());

            // Get the assignToID from DB
            Case tempCaseRecord = queueFacade.GetCase(caseId);
            assignToID = tempCaseRecord.AssignedToUserID;

            //int userID = user.ID;
            //if (isOpenClicked)
            //{
            //    userID = assignToID.Value;
            //}
            bool isEditLocked = false;

            if (assignToID.HasValue && assignToID.Value != user.ID)
            {
                isEditLocked = true;

                #region TFS 373 : Check whether the Assigned User is On-line or not if no then allow to open service request

                logger.Info("Trying to check configuration for Open For EditCheck On-line Status");

                string appConfiguration = AppConfigRepository.GetValue("OpenForEditCheckOnlineStatus");

                if (string.IsNullOrEmpty(appConfiguration))
                {
                    logger.Info("Unable to retrieve application configuration for OpenForEditCheckOnlineStatus");
                }
                else if (appConfiguration.ToLower().Equals("yes"))
                {
                    DesktopNotificationFacade desktopFacade = new DesktopNotificationFacade();
                    UsersFacade userfacade = new UsersFacade();
                    User lockeduser = userfacade.GetById(assignToID.Value);
                    aspnet_Users userobj = userfacade.Get(lockeduser.aspnet_UserID);
                    logger.InfoFormat("Trying to check whether user is on-line or not {0}", userobj.UserName);
                    var connectedusers = desktopFacade.GetUserLiveConnections(userobj.UserName);
                    if (connectedusers.Count() > 0)
                    {
                        logger.InfoFormat("User is on-line so service request {0} is still locked", serRequest);
                        isEditLocked = true;
                        assignTo = lockeduser.FirstName + ' ' + lockeduser.LastName;
                    }
                    else
                    {
                        logger.InfoFormat("User is off-line so service request {0} will not be locked", serRequest);
                        isEditLocked = false;
                        EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                        eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.OPENED_LOCKED_REQUEST_BECAUSE_NOT_ONLINE, "Opened Locked Request Because Not On-line", LoggedInUserName, serRequest, EntityNames.SERVICE_REQUEST, Session.SessionID);
                    }
                }
                else
                {
                    logger.Info("OpenForEditCheckOnlineStatus is turned off");
                }

                #endregion
            }




            if (!isEditLocked)
            {
                ViewData["isAssignedToUserValid"] = true;
                Case caseRecord = queueFacade.GetCase(caseId);
                ServiceRequestRepository sf = new ServiceRequestRepository();
                ServiceRequest sr = sf.GetById(serRequest);

                if (caseRecord != null && user != null)
                {
                    // Update case with AssignedToUserID
                    //caseRecord.AssignedToUserID = user.ID;
                    var timeType = ReferenceDataRepository.GetTimeTypeByName(GetTimeType());
                    var srAgentTime = new ServiceRequestAgentTime()
                    {
                        IsInboundCall = false,
                        ProgramID = caseRecord.ProgramID,
                        TimeTypeID = timeType != null ? timeType.ID : (int?)null
                    };
                    queueFacade.UpdateCase(caseRecord, serRequest,user.ID, Request.RawUrl, EventNames.OPEN_SERVICE_REQUEST, "Open Service Request", GetLoggedInUser().UserName, HttpContext.Session.SessionID, srAgentTime);
                    //TFS: 1362 - Cache the SourceSystem.
                    if (caseRecord.SourceSystem != null)
                    {
                        DMSCallContext.SourceSystemFromCase = caseRecord.SourceSystem.Name;
                    }
                    DMSCallContext.SRAgentTime = srAgentTime;
                    DMSCallContext.ContactFirstName = caseRecord.ContactFirstName;
                    DMSCallContext.ContactLastName = caseRecord.ContactLastName;
                    DMSCallContext.ContactEmail = caseRecord.ContactEmail;
                    // CR: 1239 - DeliveryDriver
                    DMSCallContext.IsDeliveryDriver = caseRecord.IsDeliveryDriver;

                    if(sr.NextAction != null)
                    {
                        DMSCallContext.NextAction = sr.NextAction.Name;
                    }

                    if (!caseRecord.MemberID.HasValue)
                    {
                        throw new Exception(string.Format("Terminating Process because Member ID not have value in Case ID {0}", caseRecord.ID));
                    }

                    DMSCallContext.CaseID = caseRecord.ID;
                    DMSCallContext.MemberID = caseRecord.MemberID.HasValue ? caseRecord.MemberID.Value : 0;
                    DMSCallContext.MemberStatus = caseRecord.MemberStatus;
                    DMSCallContext.ProgramID = caseRecord.ProgramID.HasValue ? caseRecord.ProgramID.Value : 0;

                    if (DMSCallContext.ProgramID > 0)
                    {
                        // CR : 1294 : Enable / disable payment tab.
                        ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
                        var presult = repository.GetProgramInfo(DMSCallContext.ProgramID, "Application", "Rule");
                        bool allowPayment = false;
                        var item = presult.Where(x => (x.Name.Equals("AllowPaymentProcessing", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                        if (item != null)
                        {
                            allowPayment = true;
                        }
                        DMSCallContext.AllowPaymentProcessing = allowPayment;

                        bool allowEstimate = false; //AllowEstimateProcessing
                        var itemallowEstimateProcessing = presult.Where(x => (x.Name.Equals("AllowEstimateProcessing", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                        if (itemallowEstimateProcessing != null)
                        {
                            allowEstimate = true;
                        }
                        DMSCallContext.AllowEstimateProcessing = allowEstimate;


                        logger.InfoFormat("Program {0} allows payment processing : {1}", DMSCallContext.ProgramID, allowPayment);
                    }

                    DMSCallContext.VehicleTypeID = caseRecord.VehicleTypeID;
                    if (caseRecord.VehicleTypeID != null)
                    {

                        DMSCallContext.LastUpdatedVehicleType = GetVehicleTypeNameById(caseRecord.VehicleTypeID.Value);
                    }
                    DMSCallContext.VehicleMake = caseRecord.VehicleMake;
                    DMSCallContext.VehicleYear = caseRecord.VehicleYear;
                    if (caseRecord.Member != null)
                    {
                        DMSCallContext.MembershipID = caseRecord.Member.MembershipID;
                    }

                    CallInformation ci = new CallInformation();
                    ci.ContactPhoneNumber = caseRecord.ContactPhoneNumber;
                    ci.ContactPhoneTypeID = caseRecord.ContactPhoneTypeID;
                    ci.ContactAltPhoneNumber = caseRecord.ContactAltPhoneNumber;
                    ci.ContactAltPhoneTypeID = caseRecord.ContactAltPhoneTypeID;
                    if (DMSCallContext.InboundCallID != 0)
                    {
                        ci.InboundCallId = DMSCallContext.InboundCallID;
                        InboundCall currentCall = CallFacade.GetInboundCallById(ci.InboundCallId);
                        currentCall.CaseID = caseRecord.ID;
                        currentCall.ContactAltPhoneNumber = ci.ContactAltPhoneNumber;
                        currentCall.ContactAltPhoneTypeID = ci.ContactAltPhoneTypeID;
                        currentCall.ContactPhoneNumber = ci.ContactPhoneNumber;
                        currentCall.ContactPhoneTypeID = ci.ContactPhoneTypeID;
                        CallFacade.Save(currentCall);
                    }
                    DMSCallContext.StartCallData = ci;
                }

                DMSCallContext.ServiceRequestID = serRequest;
                DMSCallContext.RequestOpenedTime = DateTime.Now;

                // From Service request.
                DMSCallContext.ServiceLocationLatitude = sr.ServiceLocationLatitude;
                DMSCallContext.ServiceLocationLongitude = sr.ServiceLocationLongitude;
                DMSCallContext.DestinationLatitude = sr.DestinationLatitude;
                DMSCallContext.DestinationLongitude = sr.DestinationLongitude;
                DMSCallContext.ServiceMiles = sr.ServiceMiles;

                DMSCallContext.ProductCategoryID = sr.ProductCategoryID;
                DMSCallContext.PrimaryProductID = sr.PrimaryProductID;
                DMSCallContext.SecondaryProductID = sr.SecondaryProductID;
                DMSCallContext.ServiceEstimateFee = sr.ServiceEstimate;
                if (sr.ProductCategoryID != null)
                {
                    var pc = ReferenceDataRepository.GetProductCategoryById(sr.ProductCategoryID.Value);
                    if (pc != null)
                    {
                        DMSCallContext.ProductCategoryName = pc.Name;
                    }
                }

                DMSCallContext.IsPossibleTow = sr.IsPossibleTow ?? false;
                DMSCallContext.MemberPaymentTypeID = sr.MemberPaymentTypeID;
                DMSCallContext.VehicleCategoryID = sr.VehicleCategoryID;
                // Cache Hagerty programs
                DMSCallContext.HagertyChildPrograms = ReferenceDataRepository.GetChildPrograms("Hagerty");

                DMSCallContext.IsDispatchThresholdReached = sr.IsDispatchThresholdReached ?? false;

                DMSCallContext.IsSMSAvailable = caseRecord.IsSMSAvailable ?? false;

                if (caseRecord.VehicleTypeID != null)
                {

                    DMSCallContext.LastUpdatedVehicleType = GetVehicleTypeNameById(caseRecord.VehicleTypeID.Value);
                }

                if (isFromStartCall)
                {
                    DMSCallContext.StartingPoint = StringConstants.START;
                }
                else
                {
                    DMSCallContext.StartingPoint = StringConstants.QUEUE;
                }

                // Sanghi : 04 June 2013
                // Create Event Log if we are processing the request from History
                DMSCallContext.IsFromHistoryList = isFromHistory;
                if (POID.HasValue)
                {
                    DMSCallContext.IsFromHistoryListPOID = POID.Value;
                }


                //KB: Set the isCallMade flag in session to true if there exists a Pending PO for the current SR.
                PORepository poRepository = new PORepository();
                var pendingPOs = poRepository.GetPOsByStatus(DMSCallContext.ServiceRequestID, "Pending");

                if (pendingPOs.Count() > 0)
                {
                    DMSCallContext.IsCallMadeToVendor = true;
                    var po = pendingPOs.FirstOrDefault();
                    DMSCallContext.CurrentPurchaseOrder = poRepository.GetPOById(po.ID);
                    DMSCallContext.VendorLocationID = po.VendorLocationID.GetValueOrDefault();
                    DMSCallContext.SetVendorInContext = true;

                    var callLog = poRepository.GetRecentCallDetails(po.ID);
                    if (callLog != null)
                    {
                        DMSCallContext.VendorPhoneNumber = callLog.PhoneNumber;
                        DMSCallContext.TalkedTo = callLog.TalkedTo;
                        DMSCallContext.VendorPhoneType = callLog.PhoneType;
                    }
                }

                if (isFromHistory)
                {
                    var loggedInUser = LoggedInUserName;
                    EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                    eventLoggerFacade.LogEvent("History", EventNames.MANAGER_OVERRIDE_OPEN_CASE, "SR Edit From History", loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
                }
            }
            else
            {
                result.Status = OperationStatus.ERROR;
            }
            ViewData["UserName"] = assignTo;
            ViewData["isManager"] = System.Web.Security.Roles.IsUserInRole(GetLoggedInUser().UserName, RoleConstants.Manager);
            ViewData["CaseId"] = caseId;
            logger.InfoFormat("Call the partial view _AccessControl");
            if (result.Status == OperationStatus.SUCCESS)
            {
                result.Data = new { AllowPaymentProcessing = DMSCallContext.AllowPaymentProcessing, AllowEstimateProcessing = DMSCallContext.AllowEstimateProcessing };
                return Json(result, JsonRequestBehavior.AllowGet);
            }

            return PartialView("_AccessControl", serRequest);

        }

        /// <summary>
        /// Edits the manager override.
        /// </summary>
        /// <param name="caseId">The case id.</param>
        /// <returns></returns>
        [HttpPost]
        [DMSAuthorize]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult EditManagerOverride(string caseId)
        {
            logger.InfoFormat("QueueController - EditManagerOverride(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                caseId = caseId
            }));
            OperationResult result = new OperationResult();

            //logger.InfoFormat("Inside EditManagerOverride for caseId ( {0} ) of QueueController.", caseId);
            ViewData["isAssignedToUserValid"] = false;
            QueueFacade queueFacade = new QueueFacade();
            User user = queueFacade.getUser(GetLoggedInUser().ProviderUserKey.ToString());
            Case caseRecord = queueFacade.GetCase(caseId);
            ServiceRequestRepository sf = new ServiceRequestRepository();
            ServiceRequest sr = sf.GetByCaseId(int.Parse(caseId));
            if (caseRecord != null && sr != null && user != null)
            {
                // Update case with AssignedToUserID
                //caseRecord.AssignedToUserID = null;
                var timeType = ReferenceDataRepository.GetTimeTypeByName(GetTimeType());
                var srAgentTime = new ServiceRequestAgentTime()
                {
                    IsInboundCall = false,
                    ProgramID = caseRecord.ProgramID,
                    TimeTypeID = timeType != null ? timeType.ID : (int?)null
                };
                queueFacade.UpdateCase(caseRecord, sr.ID,null, Request.RawUrl, EventNames.MANAGER_OVERRIDE_OPEN_CASE, "Manage Override", GetLoggedInUser().UserName, HttpContext.Session.SessionID, srAgentTime);

            }
            result.Status = OperationStatus.SUCCESS;
            return Json(result);

        }

        [HttpPost]
        [DMSAuthorize]
        [ValidateInput(false)]
        public ActionResult SaveLockedServiceRequestComments(int serviceRequestId, string srComments, bool sendNotification)
        {
            logger.InfoFormat("QueueController - SaveLockedServiceRequestComments(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                serviceRequestId = serviceRequestId,
                srComments = srComments,
                sendNotification = sendNotification
            }));
            OperationResult result = new OperationResult();
            // logger.InfoFormat("Inside SaveLockedServiceRequestComments for serviceRequestId ( {0} ) of QueueController.", serviceRequestId);
            QueueFacade queueFacade = new QueueFacade();
            queueFacade.SaveServiceRequestLockedComments(serviceRequestId, srComments, sendNotification, GetLoggedInUser().UserName, Request.RawUrl, HttpContext.Session.SessionID);
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        #endregion

        #region Helper method
        /// <summary>
        /// Gets the custom where clause XML. Its a helper method
        /// </summary>
        /// <param name="filterParams">The filter params.</param>
        /// <returns>
        /// WhereClauseXml
        /// </returns>
        public string GetCustomWhereClauseXml(List<NameValuePair> filterParams)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            // Hash-table has been used to ensure that is column name got change in DB, then also we don't require
            // to change the column name value in ComboBox (ReferenceDataRepository).
            // We require only to change the value in this hash table.
            //TODO: Remove case and handle ClosedLoopStatus. Just remove the condition for case in the below if and that's it.
            Hashtable hashTable = new Hashtable();

            hashTable["RequestNumber"] = "RequestNumber";
            hashTable["PONumber"] = "PONumber";
            hashTable["Member"] = "Member";
            hashTable["CreateBy"] = "CreateBy";
            hashTable["ISPName"] = "ISPName";
            hashTable["ServiceType"] = "ServiceType";
            hashTable["Status"] = "Status";
            hashTable["ClosedLoop"] = "ClosedLoop";
            hashTable["NextAction"] = "NextAction";
            hashTable["AssignedTo"] = "AssignedTo";
            hashTable["MemberNumber"] = "MemberNumber";
            hashTable["Priority"] = "Priority";
            hashTable["Client"] = "Client";

            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");
                filterParams.ForEach(f =>
                    {
                        string columnName = f.Name;
                        string filterValue = f.Value;
                        if (!string.IsNullOrEmpty(columnName) && !string.IsNullOrEmpty(filterValue))
                        {
                            if (columnName.Equals("RequestNumber") ||
                                columnName.Equals("PONumber") || columnName.Equals("NextAction") || columnName.Equals("ClosedLoop")
                                || columnName.Equals("ServiceType") || columnName.Equals("MemberNumber") || columnName.Equals("Priority")
                                || columnName.Equals("Client")
                                )
                            {
                                writer.WriteAttributeString(string.Format("{0}Operator", hashTable[columnName]), "2");
                            }
                            else if (columnName.Equals("Status"))
                            {
                                writer.WriteAttributeString(string.Format("{0}Operator", hashTable[columnName]), "11");
                            }
                            else
                            {
                                writer.WriteAttributeString(string.Format("{0}Operator", hashTable[columnName]), "6");
                            }
                            writer.WriteAttributeString(string.Format("{0}Value", hashTable[columnName]), filterValue);

                        }
                    });
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }
            return whereClauseXML.ToString();

        }

        /// <summary>
        /// Resets the SR.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult ResetSR(int? serviceRequestID)
        {
            DMSCallContext.ServiceRequestID = serviceRequestID ?? 0;
            return Json(new OperationResult() { Status = OperationStatus.SUCCESS });
        }
        #endregion
    }
}
