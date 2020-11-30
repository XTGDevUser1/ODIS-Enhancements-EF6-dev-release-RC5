using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL;
using ClientPortal.ActionFilters;
using ClientPortal.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Kendo.Mvc.UI;
using ClientPortal.Common;
using System.Text;
using System.Collections;
using ClientPortal.Models;
using System.Web.Security;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using ClientPortal.Areas.Application.Models;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Model;
using System.Xml;


namespace ClientPortal.Areas.Application.Controllers
{
    public class QueueController : BaseController
    {
        #region Action
        /// <summary>
        /// Present the queue listing 
        /// </summary>
        /// <returns>Queue list</returns>
        [DMSAuthorize(Securable= DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_QUEUE)]
        [ReferenceDataFilter(StaticData.QueueFilterItems, false)]
        [ReferenceDataFilter(StaticData.NextAction, false)]
        [ReferenceDataFilter(StaticData.ClosedLoopStatus, false)]
        [ReferenceDataFilter(StaticData.ServiceType, false)]
        [ReferenceDataFilter(StaticData.Priorities, false)]
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
                SortDirection = "DESC",
                SortColumn = "Case"
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
        /// <param name="command">The command.</param>
        /// <param name="filterColumnName">Name of the filter column.</param>
        /// <param name="filterColumnValue">The filter column value.</param>
        /// <returns>Queue list</returns>
        
        [NoCache]
        [DMSAuthorize]
        [ValidateInput(false)]
        public ActionResult List([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, string statusValues)
        {

            logger.Info("Inside List() of QueueController. Attempt to get Queue depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Case";
            string sortOrder = "DESC";
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
            List<Queue_Result> list = queueFacade.List((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows;
            }
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            return Json(new DataSourceResult() { Data = list, Total = totalRows });

        }

        /// <summary>
        /// Gets the queue id.
        /// </summary>
        /// <param name="queueId">The queue id.</param>
        /// <returns>queue Id</returns>
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
        /// <param name="mode">The mode.</param>
        /// <returns>ServiceRequest_Result</returns>
        [HttpPost]
        [DMSAuthorize]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult Get(string queueId, bool? fromStartCall, bool? isEditRequired)
        {
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;

            logger.InfoFormat("Inside Get( {0} ) of QueueController.", queueId);
            ViewData["CaseNumber"] = queueId;
            int inboundCallId = DMSCallContext.InboundCallID;
            string loggedInUserName = GetLoggedInUser().UserName;
            QueueFacade queueFacade = new QueueFacade();
            List<ServiceRequest_Result> serviceRequestResult = queueFacade.Get(loggedInUserName, Request.RawUrl, inboundCallId, queueId, fromStartCall ?? false, HttpContext.Session.SessionID);
            int serviceRequestID = 0;
            int.TryParse(queueId, out serviceRequestID);
            DMSCallContext.ServiceRequestID = serviceRequestID;

            List<NameValuePair> listQuestionAnswer = queueFacade.GetQuestionAnswerForServiceRequest(serviceRequestID);
            ViewData["SRQuestionAnswers"] = listQuestionAnswer;

            ViewData["AssignedTo"] = string.Empty;
            ViewData["isLockRequired"] = true;
            if (serviceRequestResult != null && serviceRequestResult.Count > 0)
            {
                ViewData["AssignedTo"] = serviceRequestResult[0].AssignedTo;
                ViewData["AssignedToID"] = serviceRequestResult[0].AssignedToID;
                if (serviceRequestResult[0].AssignedToID == null)
                {
                    ViewData["isLockRequired"] = false;
                }
              
            }
            ViewBag.FromStartCall = fromStartCall;
            ViewBag.IsEditRequired = isEditRequired;
            logger.InfoFormat("Call the partial view _Queue");
            if (serviceRequestResult != null && serviceRequestResult.Count > 0)
            {
                DMSCallContext.ClientName = serviceRequestResult.ElementAt(0).Client;
            }
            return PartialView("_NewServiceRequestDetails", serviceRequestResult);

        }

        /// <summary>
        /// Edits the service request.
        /// </summary>
        /// <param name="assignTo">The assign to.</param>
        /// <returns>_AccessRequest</returns>
        [HttpPost]
        [DMSAuthorize]
        [ValidateInput(false)]
        public ActionResult Edit(string assignTo, int? assignToID, string caseId, int serRequest, bool isFromStartCall = false,bool isOpenClicked = false,bool isFromHistory = false,int? POID = null)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.InfoFormat("Inside Edit( {0} ) of QueueController.", assignTo);
            ViewData["isAssignedToUserValid"] = false;
            QueueFacade queueFacade = new QueueFacade();
            //if (GetLoggedInUser().UserName.Equals(assignTo))
            User user = queueFacade.getUser(GetLoggedInUser().ProviderUserKey.ToString());
            int userID =  user.ID;
            if (isOpenClicked)
            {
                userID = assignToID.Value;
            }
            if (!(assignToID.HasValue) || (assignToID.HasValue && assignToID.Value == userID))
            {
                ViewData["isAssignedToUserValid"] = true;
                Case caseRecord = queueFacade.GetCase(caseId);
                ServiceRequestRepository sf = new ServiceRequestRepository();
                ServiceRequest sr = sf.GetById(serRequest);

                if (caseRecord != null && user != null)
                {
                    // Update case with AssignedToUserID
                    caseRecord.AssignedToUserID = user.ID;
                    
                    queueFacade.UpdateCase(caseRecord, Request.RawUrl, EventNames.OPEN_SERVICE_REQUEST, "Open Service Request", GetLoggedInUser().UserName, HttpContext.Session.SessionID);

                    DMSCallContext.ContactFirstName = caseRecord.ContactFirstName;
                    DMSCallContext.ContactLastName = caseRecord.ContactLastName;
                    // CR: 1239 - DeliveryDriver
                    DMSCallContext.IsDeliveryDriver = caseRecord.IsDeliveryDriver;

                    DMSCallContext.CaseID = caseRecord.ID;
                    DMSCallContext.MemberID = caseRecord.MemberID.HasValue ? caseRecord.MemberID.Value : 0;
                    DMSCallContext.MemberStatus = caseRecord.MemberStatus;
                    DMSCallContext.ProgramID = caseRecord.ProgramID.HasValue ? caseRecord.ProgramID.Value : 0;

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


                // From Service request.
                DMSCallContext.ServiceLocationLatitude = sr.ServiceLocationLatitude;
                DMSCallContext.ServiceLocationLongitude = sr.ServiceLocationLongitude;
                DMSCallContext.DestinationLatitude = sr.DestinationLatitude;
                DMSCallContext.DestinationLongitude = sr.DestinationLongitude;
                DMSCallContext.ServiceMiles = sr.ServiceMiles;

                DMSCallContext.ProductCategoryID = sr.ProductCategoryID;
                DMSCallContext.PrimaryProductID = sr.PrimaryProductID;
                DMSCallContext.SecondaryProductID = sr.SecondaryProductID;
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
                return Json(result, JsonRequestBehavior.AllowGet);
            }

            return PartialView("_AccessControl",serRequest );

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
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside EditManagerOverride for caseId ( {0} ) of QueueController.", caseId);
            ViewData["isAssignedToUserValid"] = false;
            QueueFacade queueFacade = new QueueFacade();
            User user = queueFacade.getUser(GetLoggedInUser().ProviderUserKey.ToString());
            Case caseRecord = queueFacade.GetCase(caseId);
            if (caseRecord != null && user != null)
            {
                // Update case with AssignedToUserID
                caseRecord.AssignedToUserID = null;
                
                queueFacade.UpdateCase(caseRecord, Request.RawUrl, EventNames.MANAGER_OVERRIDE_OPEN_CASE, "Manage Override", GetLoggedInUser().UserName, HttpContext.Session.SessionID);

            }
            result.Status = OperationStatus.SUCCESS;
            return Json(result);

        }

        #endregion

        #region Helper method
        /// <summary>
        /// Gets the custom where clause XML. Its a helper method
        /// </summary>
        /// <param name="columnName">Name of the column.</param>
        /// <param name="filterValue">The filter value.</param>
        /// <returns>WhereClauseXml</returns>
        public string GetCustomWhereClauseXml(List<NameValuePair> filterParams)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            // Hashtable has been used to ensure that is column name got change in DB, then also we don't require
            // to cahnge the column name value in ComboBox (ReferenceDataRepository).
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

            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");
                //WhereClauseXml.Append("<ROW><Filter");
                filterParams.ForEach(f =>
                    {
                        string columnName = f.Name;
                        string filterValue = f.Value;
                        if (!string.IsNullOrEmpty(columnName) && !string.IsNullOrEmpty(filterValue))
                        {

                            //string filterFinalValue = ((filterValue.Replace("&", "")).Replace("<", "")).Replace("\"", "");
                            //WhereClauseXml.Append(" ");
                            if (columnName.Equals("RequestNumber") ||
                                columnName.Equals("PONumber") || columnName.Equals("NextAction") || columnName.Equals("ClosedLoop")
                                || columnName.Equals("ServiceType") || columnName.Equals("MemberNumber") || columnName.Equals("Priority")
                                )
                            {
                                //WhereClauseXml.AppendFormat("{0}Operator=\"{1}\" ", hashTable[columnName], 2); // 2 is the = operator
                                writer.WriteAttributeString(string.Format("{0}Operator", hashTable[columnName]), "2");
                            }
                            else if (columnName.Equals("Status"))
                            {
                                //WhereClauseXml.AppendFormat("{0}Operator=\"{1}\" ", hashTable[columnName], 11); // 11 is the 'in' operator
                                writer.WriteAttributeString(string.Format("{0}Operator", hashTable[columnName]), "11");
                            }
                            else
                            {
                                //WhereClauseXml.AppendFormat("{0}Operator=\"{1}\" ", hashTable[columnName], 6); // 6 is the Contains operator value
                                writer.WriteAttributeString(string.Format("{0}Operator", hashTable[columnName]), "6");
                            }
                            //WhereClauseXml.AppendFormat(" {0}Value=\"{1}\"", hashTable[columnName], filterFinalValue);
                            writer.WriteAttributeString(string.Format("{0}Value", hashTable[columnName]), filterValue);

                        }
                    });
                //WhereClauseXml.Append("></Filter></ROW>");
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }
            return whereClauseXML.ToString();

        }

        [HttpPost]
        public ActionResult ResetSR(int? serviceRequestID)
        {
            DMSCallContext.ServiceRequestID = serviceRequestID ?? 0;
            return Json(new OperationResult() { Status = OperationStatus.SUCCESS });
        }
        #endregion
    }
}
