using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.Areas.Application.Models;
using System.Configuration;
using Kendo.Mvc.UI;
using System.Web.Script.Serialization;
using System.Text;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    ///
    /// </summary>
    public class RequestController : BaseController
    {

        #region Private Methods
        /// <summary>
        /// Checks the session validity.
        /// </summary>
        /// <param name="up">Up.</param>
        /// <exception cref="DMSException">Session got reset, please reload the page by hitting Ctrl+F5. Contact administrator if the issue persists.</exception>
        private static void CheckSessionValidity(RegisterUserModel up)
        {
            if (up == null)
            {
                throw new DMSException("Session got reset, please reload the page by hitting Ctrl+F5. Contact administrator if the issue persists.");
            }
        }

        private static bool IsAHagertyProgram(int programID)
        {
            bool isAHagertyProgram = false;
            var list = DMSCallContext.HagertyChildPrograms;
            if (list != null && list.Count > 0)
            {
                int count = list.Where(x => x.ProgramID == programID).Count();
                return count > 0;
            }
            return isAHagertyProgram;
        }

        //Lakshmi - Hagerty Integration
        /// <summary>
        /// Hagerty service call will be made and save membership information in Data base if Hagerty Membership number id found.
        /// </summary>
        /// <param name="MembershipID">The membership ID.</param>
        /// <param name="MemberID">The member ID.</param>
        private bool SaveHagertyMemberDetails(int MembershipID, int MemberID)
        {
            bool IsSuccess = false;
            MemberRepository memberResp = new MemberRepository();
            // Begin : Call Hagerty Web service and Get Member information. Added on 11/15/2013

            MemberFacade memberFacade = new MemberFacade();
            string memberNumber = memberResp.GetMemberNumber(MembershipID);
            logger.InfoFormat("Retrieved membership number for the ID {0} as {1}", MembershipID, memberNumber);
            if (!string.IsNullOrWhiteSpace(memberNumber))
            {
                IsSuccess = memberFacade.GetMemberInformationFromHagerty(Convert.ToString(memberNumber), DMSCallContext.IsAHagertyParentProgram, null, string.Empty, LoggedInUserName, Request.RawUrl,
                    DMSCallContext.InboundCallID, DMSCallContext.ProgramID, HttpContext.Session.SessionID);  //DMSCallContext.IsAHagertyProgram
                return IsSuccess;
            }
            return IsSuccess;
            // End
        }
        #endregion

        #region Public Methods

        /// <summary>
        /// Indexes the specified id. Checks if member information came from connect and passes the data to the view.
        /// </summary>
        /// <param name="id">The id</param>
        /// <param name="isFromConnect">True or False</param>
        /// <param name="memberPhoneNumber">Customer Phone Number (expecting area code plus number ex.1 8001112222 format)</param>
        /// <param name="inBoundNumber">Number the member called to (expecting area code plus number ex.1 8001112222 format)</param>
        /// <returns></returns>
        [ControlDisplayManager(ControlConstants.ShowStickyNotes, ControlConstants.ShowComments, ControlConstants.ShowCallTimer)]
        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_REQUEST)]
        public ActionResult Index(string id, bool isFromConnect = false, string memberPhoneNumber = "", string inBoundNumber = "")
        {
            logger.InfoFormat("RequestController - Index(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                id = id
            }));
            if (!string.IsNullOrEmpty(id))
            {
                ViewBag.StartTab = id;
            }
            else
            {
                ViewBag.StartTab = "start";
            }
            // Fresh request.
            if (ViewBag.StartTab == "start" || ViewBag.StartTab == "startCall")
            {
                DMSCallContext.Reset();
            }

            // If the user is coming from Queue page, ProgramID exists in DMSCallContext.
            if (DMSCallContext.ProgramID > 0)
            {
                // CR : 1294 : Enable / disable payment tab.
                ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
                var result = repository.GetProgramInfo(DMSCallContext.ProgramID, "Application", "Rule");
                bool allowPayment = false;
                var item = result.Where(x => (x.Name.Equals("AllowPaymentProcessing", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                if (item != null)
                {
                    allowPayment = true;
                }
                DMSCallContext.AllowPaymentProcessing = allowPayment;

                bool allowEstimate = false; //AllowEstimateProcessing
                var itemallowEstimateProcessing = result.Where(x => (x.Name.Equals("AllowEstimateProcessing", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
                if (itemallowEstimateProcessing != null)
                {
                    allowEstimate = true;
                }
                DMSCallContext.AllowEstimateProcessing = allowEstimate;
                logger.InfoFormat("RequestController - Index(),Program allows payment processing : {0} for the Program  ID : {1}", allowPayment, DMSCallContext.ProgramID.ToString());
            }

            if (DMSCallContext.ServiceRequestID > 0)
            {
                ViewData[StringConstants.TAB_VALIDATION_STATUS] = GetTabValidationStatusAsJson(DMSCallContext.ServiceRequestID);
            }
            if (isFromConnect == true)
            {
                ProgramMaintenanceRepository programDetail = new ProgramMaintenanceRepository();
                var programs = programDetail.GetPrograms(inBoundNumber);
                var infoFromConnect = new ConnectModel() { memberPhoneNumber = memberPhoneNumber, inBoundNumber = inBoundNumber, isFromConnect = true, programs = programs};
                return View(infoFromConnect);
            }
            else
            {
                ProgramMaintenanceRepository programDetail = new ProgramMaintenanceRepository();
                var infoFromConnect = new ConnectModel() { isFromConnect = false };
                return View(infoFromConnect);
            }

        }

        private string GetTabValidationStatusAsJson(int serviceRequestID)
        {
            var tabValidationStatuses = CallFacade.GetAllTabValidationStatuses(serviceRequestID);
            JavaScriptSerializer jsonSerializer = new JavaScriptSerializer();
            StringBuilder sb = new StringBuilder();
            jsonSerializer.Serialize(tabValidationStatuses, sb);
            return sb.ToString();
        }

        #region Unused Code
        //[NoCache]
        //[DMSAuthorize]
        //public ActionResult _StartCallMemberSelection(string memberIDList,string membershipIDList)
        //{
        //    Dictionary<string, string> list = new Dictionary<string, string>();
        //    list.Add("MemberIDList", memberIDList);
        //    list.Add("MemberShipIDList", membershipIDList);
        //    return PartialView(list);
        //}

        //[NoCache]
        //[DMSAuthorize]
        //[HttpPost]
        //public ActionResult _StartCallMemberSelectionList([DataSourceRequest] DataSourceRequest request, string memberIDList, string membershipIDList)
        //{
        //    logger.Info("Inside _StartCallMemberSelectionList of Request. Attempt to get all Member depending upon the GridCommand");
        //    GridUtil gridUtil = new GridUtil();
        //    string sortColumn = string.Empty;
        //    string sortOrder = string.Empty;

        //    if (request.Sorts.Count > 0)
        //    {
        //        sortColumn = request.Sorts[0].Member;
        //        sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
        //    }
        //    PageCriteria pageCriteria = new PageCriteria()
        //    {
        //        StartInd = request.PageSize * (request.Page - 1) + 1,
        //        EndInd = request.PageSize * request.Page,
        //        PageSize = request.PageSize,
        //        SortDirection = sortOrder,
        //        SortColumn = sortColumn,
        //        WhereClause = string.Empty
        //    };
        //    if (string.IsNullOrEmpty(pageCriteria.WhereClause))
        //    {
        //        pageCriteria.WhereClause = null;
        //    }
        //    MemberFacade facade = new MemberFacade();
        //    List<StartCallMemberSelections_Result> list = facade.SearchMember(pageCriteria, memberIDList, membershipIDList);
        //    logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
        //    int totalRows = 0;
        //    if (list != null && list.Count > 0)
        //    {
        //        totalRows = list.ElementAt(0).TotalRows.GetValueOrDefault();
        //    }
        //    var result = new DataSourceResult()
        //    {
        //        Data = list,
        //        Total = totalRows
        //    };
        //    return Json(result);
        //}

        #endregion

        public ActionResult SetAttributeSession (string AmazonConnectID)
        {
            DMSCallContext.AmazonConnectID = AmazonConnectID;
            return Json(true);
        }
        /// <summary>
        /// Gets the ServiceRequestID
        /// </summary>
        /// <returns></returns>
        public ActionResult GetServiceRequestId ()
        {
            return Json(DMSCallContext.ServiceRequestID);
        }

        public ActionResult UpdateServiceRequestOutboundCall (string PhoneNumber, string amazonConnectID, int? contactCategoryID, int? contactTypeID, int? serviceRequestID, bool clickToDial = false)
        {
            var memberID = DMSCallContext.MemberID;
            ContactLog contactLog = new ContactLog();
            ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
            contactLog.ContactCategoryID = contactCategoryID;
            ContactMethod method = staticDataRepo.GetMethodByName("Phone");
            contactLog.ContactMethodID = method.ID;
            contactLog.ContactTypeID = contactTypeID;
            contactLog.ContactSourceID = null;
            contactLog.TalkedTo = null;
            contactLog.Company = null;
            contactLog.PhoneNumber = PhoneNumber;
            contactLog.Direction = "Outbound";
            contactLog.CreateBy = contactLog.ModifyBy = LoggedInUserName;
            contactLog.CreateDate = contactLog.ModifyDate = DateTime.Now;
            contactLog.ContactLogConnectData = new ContactLogConnectData
            {
                ConnectContactID = amazonConnectID,
                CreateBy = "AWS",
                CreateDate = DateTime.Now,
                ModifyBy = "AWS",
                ModifyDate = DateTime.Now
            };
            FinishFacade facade = new FinishFacade();
            
            if (clickToDial)
            {
                facade.updateServiceRequestOutboundCall(contactLog, LoggedInUserName, serviceRequestID, memberID);

                if (contactCategoryID == 3 && contactLog.ID != 0)
                {
                    DMSCallContext.LastVendorContactLogID = contactLog.ID;
                }
            } else
            {
                facade.updateServiceRequestOutboundCall(contactLog, LoggedInUserName, DMSCallContext.ServiceRequestID, memberID);
            }
           
            return Json(true);
        }

        /// <summary>
        /// Determines whether [is called from queue].
        /// </summary>
        /// <returns></returns>
        public ActionResult IsCalledFromQueue()
        {
            return Content("");
        }

        /// <summary>
        /// _s the start. Input fields to select a program and retrieve program information.
        /// </summary>
        /// <param name="memberPhoneNumber">The customer phone number.</param>
        /// <param name="inBoundNumber">The number that the member called to.</param>
        /// <param name="isFromConnect">True or False.</param>
        /// <param name="programFound">The parent program based on the inbound number.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.CallType, false)]
        [ReferenceDataFilter(StaticData.Language, false)]
        [NoCache]
        public ActionResult _Start(string memberPhoneNumber, string inBoundNumber, bool isFromConnect, List<Program> programFound)
        {
            if (isFromConnect == true)
            {
                var programs = ProgramMaintenanceRepository.GetProgramsForCall((Guid)GetLoggedInUser().ProviderUserKey);
                ViewData["Programs"] = programs.ToSelectListItem(x => x.Id.ToString(), y => y.Name, true);
                ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
                var infoFromConnect = new ProgramModel() { memberPhoneNumber = memberPhoneNumber, inBoundNumber = inBoundNumber, isFromConnect = isFromConnect, programs = programFound };
                return PartialView("_Start", infoFromConnect);

            }
            else
            {
                var programs = ProgramMaintenanceRepository.GetProgramsForCall((Guid)GetLoggedInUser().ProviderUserKey);
                ViewData["Programs"] = programs.ToSelectListItem(x => x.Id.ToString(), y => y.Name, true);
                ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
                var infoFromConnect = new ProgramModel() { isFromConnect = false };
                return PartialView("_Start", infoFromConnect);
            }

        }

        /// <summary>
        /// Starts the call.Creates inbound call and event log records.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult StartCall()
        {
            logger.Info("Attempting to initialize/initiate a call");
            DMSCallContext.Reset();
            int inboundCallId = CallFacade.StartCall(GetLoggedInUserId(), Request.RawUrl, HttpContext.Session.SessionID);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            DMSCallContext.InboundCallID = inboundCallId;
            DMSCallContext.StartingPoint = StringConstants.START;

            logger.InfoFormat("Call initiated @ {0}", inboundCallId);
            return Json(result);
        }

        /// <summary>
        /// Sets the program ID.
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SetProgramID(string programID)
        {
            OperationResult result = new OperationResult();
            int iProgramId = 0;
            int.TryParse(programID, out iProgramId);
            DMSCallContext.ProgramID = iProgramId;
            logger.InfoFormat("RequestController - SetProgramID() - Setting {0} in session", JsonConvert.SerializeObject(new
            {
                programID = iProgramId
            }));
            string clientName = ReferenceDataRepository.GetClientNameForProgram(iProgramId);
            result.Data = new { ClientName = clientName };
            logger.InfoFormat("RequestController - SetProgramID(), {0}", JsonConvert.SerializeObject(new { ClientName = clientName }));
            result.OperationType = OperationStatus.SUCCESS;
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        /// <summary>
        /// Handles the mobile look up.
        /// </summary>
        /// <param name="callbackNumber">The callback number.</param>
        /// <returns></returns>
        private CasePhoneLocation HandleMobileLookUp(string callbackNumber)
        {
            List<PhoneType> phoneTypes = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER);
            var cellType = phoneTypes.Where(x => x.Name == "Cell").FirstOrDefault();
            logger.InfoFormat("Trying to execute Waldo Web Service for the given Call Back number {0}", callbackNumber);
            EmergencyAssistanceFacade facade = new EmergencyAssistanceFacade();
            CasePhoneLocation casePhoneLocation = facade.WSGetPhoneLocation(callbackNumber, -1);
            if (casePhoneLocation != null && casePhoneLocation.CivicLatitude.HasValue && casePhoneLocation.CivicLongitude.HasValue)
            {
                //logger.InfoFormat("Finished execution of Waldo Web Service found Latitude {0} Longitude {1} ", casePhoneLocation.CivicLatitude, casePhoneLocation.CivicLongitude);
                logger.InfoFormat("RequestController - SetProgramID() - Finished execution of Waldo Web Service found : {0}", JsonConvert.SerializeObject(new
                {
                    Latitude = casePhoneLocation.CivicLatitude,
                    Longitude = casePhoneLocation.CivicLongitude
                }));
                logger.Info("Trying to create Case Phone Location Record");
                CasePhoneLocation newPhoneLocationRecord = new CasePhoneLocation()
                {
                    CaseID = null,
                    InboundCallID = DMSCallContext.InboundCallID,
                    PhoneNumber = callbackNumber,
                    LocationDate = casePhoneLocation.LocationDate,
                    IsSMSAvailable = true,
                    LocationAccuracy = casePhoneLocation.LocationAccuracy,
                    GeoAccuracy = null,
                    CivicLatitude = casePhoneLocation.CivicLatitude,
                    CivicLongitude = casePhoneLocation.CivicLongitude
                };
                if (cellType != null)
                {
                    newPhoneLocationRecord.PhoneTypeID = cellType.ID;
                }
                new CasePhoneLocationFacade().Save(newPhoneLocationRecord);
                logger.InfoFormat("Case Phone Location Created Values : {0}", JsonConvert.SerializeObject(new
                {
                    CaseID = newPhoneLocationRecord.CaseID,
                    InboundCallID = DMSCallContext.InboundCallID,
                    PhoneNumber = callbackNumber,
                    CivicLatitude = casePhoneLocation.CivicLatitude,
                    CivicLongitude = casePhoneLocation.CivicLongitude
                }));
            }
            else
            {
                logger.Info("Finished execution of Waldo Web Service, No record found");
            }

            return casePhoneLocation;
        }

        /// <summary>
        /// Gets the member from case for the given callback number.
        /// </summary>
        /// <param name="callbackNumber">The callback number.</param>
        /// <param name="typeID">The type ID.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMemberFromCase(string callbackNumber, string typeID, int? selectedMemberID, int? selectedMembershipID)
        {
            logger.InfoFormat("RequestController - GetMemberFromCase() - callbackNumber : {0}, typeID : {1}, selectedMemberID :{2}, selectedMembershipID:{3}", callbackNumber, typeID, selectedMemberID, selectedMembershipID);
            DMSCallContext.CallbackNumber = callbackNumber;
            int contactPhoneTypeID = 0;
            int.TryParse(typeID, out contactPhoneTypeID);
            DMSCallContext.ContactPhoneTypeID = contactPhoneTypeID;

            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            DMSCallContext.HagertyChildPrograms = ReferenceDataRepository.GetChildPrograms("Hagerty");
            bool isAHagertyProgram = false;
            int memberProgramId = 0;
            // CR : 1127 Mobile integration
            ProgramMaintenanceFacade progFacade = new ProgramMaintenanceFacade();
            List<ProgramInformation_Result> pinfo = progFacade.GetProgramInfo(DMSCallContext.ProgramID, "service", "rule");
            var config = pinfo.Where(x => x.Name == "IsMobileEnabled").FirstOrDefault();
            if (config != null)
            {
                if ("yes".Equals(config.Value, StringComparison.InvariantCultureIgnoreCase))
                {
                    DMSCallContext.IsMobileEnabled = true;
                }
            }

            logger.InfoFormat("RequestController - GetMemberFromCase() - Program {0} IsMobileEnabled - {1}", DMSCallContext.ProgramID, DMSCallContext.IsMobileEnabled);

            logger.InfoFormat("RequestController - GetMemberFromCase() - Trying to call mobile configuration SP with following program Id {0} callback number {1} inbound call id {2}. The sp considers IsMobileEnabled flag and tries to get a record from mobile_callforservice or Case tables.", DMSCallContext.ProgramID, DMSCallContext.CallbackNumber, DMSCallContext.InboundCallID);
            List<MobileCallData_Result> info = progFacade.GetMobileConfigurationResult(DMSCallContext.ProgramID, "service", "rule", callbackNumber, DMSCallContext.InboundCallID, selectedMemberID, selectedMembershipID);
            if (info == null || info.Count == 0)
            {
                logger.Info("RequestController - GetMemberFromCase() - No mobile record found and no member data found from previous cases too !");
                DMSCallContext.MobileCallForServiceRecord = null;
                HandleMobileLookUp(callbackNumber);
            }
            // Case When we get Single Matching Records
            else if (info != null && info.Count == 1)
            {
                logger.Info("RequestController - GetMemberFromCase() - Found one record - checking to see if it is from mobile or Case");
                MobileCallData_Result resultMobile = info.ElementAt(0);
                // Reset mobile record in session.
                DMSCallContext.MobileCallForServiceRecord = null;
                if (resultMobile.PKID.HasValue)
                {
                    logger.InfoFormat("RequestController - GetMemberFromCase() - Mobile record found, checking to see if there is location information", resultMobile.PKID.Value);
                    DMSCallContext.MobileCallForServiceRecord = resultMobile;
                    if (!string.IsNullOrEmpty(resultMobile.locationLatitude) && !string.IsNullOrEmpty(resultMobile.locationLongtitude))
                    {
                        logger.Info("RequestController - GetMemberFromCase() - Location information found on the mobile record.");
                    }
                    else
                    {
                        logger.Info("RequestController - GetMemberFromCase() - Mobile record doesn't have location information, therefore invoking Waldo service");
                        CasePhoneLocation location = HandleMobileLookUp(callbackNumber);
                        if (location != null && location.CivicLatitude.HasValue && location.CivicLongitude.HasValue)
                        {
                            logger.Info("RequestController - GetMemberFromCase() - Set Mobile Result into Session");
                            resultMobile.locationLatitude = location.CivicLatitude.ToString();
                            resultMobile.locationLongtitude = location.CivicLongitude.ToString();
                            DMSCallContext.MobileCallForServiceRecord = resultMobile;
                        }
                        else
                        {
                            logger.Info("RequestController - GetMemberFromCase() - No location information returned by the Waldo service !");
                        }
                    }
                }
                else
                {
                    logger.Info("RequestController - GetMemberFromCase() - Member found from a previous case, trying to retrieve location information.");
                    CasePhoneLocation location = HandleMobileLookUp(callbackNumber);
                    if (location != null && location.CivicLatitude.HasValue && location.CivicLongitude.HasValue)
                    {
                        logger.Info("RequestController - GetMemberFromCase() - Set Mobile Result into Session");
                        resultMobile.locationLatitude = location.CivicLatitude.ToString();
                        resultMobile.locationLongtitude = location.CivicLongitude.ToString();
                        DMSCallContext.MobileCallForServiceRecord = resultMobile;
                    }
                }

                if (resultMobile.MemberID != null && resultMobile.MembershipID != null)
                {

                    //Lakshmi - Hagerty Integration
                    // Check Whether it is Hagerty Program
                    if (DMSCallContext.HagertyIntegrationConfigFlag)
                    {
                        memberProgramId = resultMobile.MemberProgramID.GetValueOrDefault();
                        isAHagertyProgram = IsAHagertyProgram(memberProgramId);

                        logger.InfoFormat("RequestController - GetMemberFromCase() - Is the current program a Hagerty Program : {0}", isAHagertyProgram);

                        int membershipID = Convert.ToInt32(resultMobile.MembershipID);
                        int memberID = Convert.ToInt32(resultMobile.MemberID);
                        if (isAHagertyProgram)
                        {
                            if (SaveHagertyMemberDetails(membershipID, memberID))
                            {
                                logger.Info("RequestController - GetMemberFromCase() - Hagerty Member Information has been saved into Database.");
                            }
                            else
                            {
                                logger.Info("RequestController - GetMemberFromCase() - Hagerty Member Information has not been saved into Database.");
                            }

                        }
                    }
                    //End

                    result.Data = new { memberID = resultMobile.MemberID, membershipID = resultMobile.MembershipID, RecordCount = 1 };
                }
            }
            else // Case Where we get Multiple Members for a given call back number
            {
                logger.Info("RequestController - GetMemberFromCase() - Found Multiple record - Provide Grid to user so that they can select a member");

                //Lakshmi - Hagerty Integration
                // Check Whether it is Hagerty Program
                logger.InfoFormat("RequestController - GetMemberFromCase() - Is the current program a Hagerty Program : {0}", DMSCallContext.IsAHagertyParentProgram);

                foreach (MobileCallData_Result callinfo in info)
                {
                    int membershipID = Convert.ToInt32(callinfo.MembershipID != null ? callinfo.MembershipID.Value : 0);
                    int memberID = Convert.ToInt32(callinfo.MemberID != null ? callinfo.MemberID.Value : 0);
                    //Need to find this member program is a hagerty program.
                    MemberFacade memberfacade = new MemberFacade();
                    int? memberparentPgmID = memberfacade.GetMemberParentProgrambyID(memberID);
                    memberProgramId = Convert.ToInt32(callinfo.MemberProgramID.GetValueOrDefault());
                    isAHagertyProgram = IsAHagertyProgram(memberProgramId);
                    if (DMSCallContext.IsAHagertyParentProgram || ((memberparentPgmID != null) && (DMSCallContext.ProgramID == memberparentPgmID)))
                    {
                        if (SaveHagertyMemberDetails(membershipID, memberID))
                        {
                            logger.Info("RequestController - GetMemberFromCase() - Hagerty Member Information has been saved into Database.");
                        }
                        else
                        {
                            logger.Info("RequestController - GetMemberFromCase() - Hagerty Member Information has not been saved into Database.");
                        }

                    }
                }
                //End

                result.Data = new { RecordCount = info.Count, MemberIDList = string.Join(",", info.Select(u => u.MemberID)), MemberShipIDList = string.Join(",", info.Select(u => u.MembershipID)) };
            }

            return Json(result);
        }

        /// <summary>
        /// Saves the inbound call details.
        /// </summary>
        /// <param name="ci">The ci.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult NewRequest(CallInformation ci)
        {
            logger.InfoFormat("RequestController - NewRequest() - Call Information ID : {0}", DMSCallContext.InboundCallID);
            DMSCallContext.ServiceTechComments = string.Empty;
            RegisterUserModel up = Session[StringConstants.LOGGED_IN_USER] as RegisterUserModel;
            CheckSessionValidity(up);
            ci.UserProfile = new KeyValuePair<string, int?>(up.UserName, up.ID);
            ci.InboundCallId = DMSCallContext.InboundCallID;
            ci.EventSource = Request.RawUrl;
            //TFS: 452
            ci.ProgramId = DMSCallContext.MemberProgramID;

            var inboundCallRepository = new InboundCallRepository();
            var inboundCall = inboundCallRepository.GetInboundCallById(ci.InboundCallId);

            int caseID = 0;
            int serviceRequestID = 0;
            var timeType = ReferenceDataRepository.GetTimeTypeByName(TimeTypes.FRONTEND);
            var srAgentTime = new ServiceRequestAgentTime()
            {
                IsInboundCall = true,
                ProgramID = ci.ProgramId,
                TimeTypeID = timeType != null ? timeType.ID : (int?)null,
                UserName = ci.UserProfile.Key,
                BeginDate = inboundCall != null ? inboundCall.CreateDate : (DateTime?)null
            };

            CallFacade.NewRequest(ci, out caseID, out serviceRequestID, Session.SessionID, DMSCallContext.MemberProgramID, srAgentTime, DMSCallContext.MobileCallForServiceRecord);
            // Set the Case Id, Service Request id and member id in the call context (session).
            logger.Info("RequestController - NewRequest() - Created a new request with the following IDs");
            logger.InfoFormat("Case ID : {0}, Service request id : {1} for member.membership {2}->{3} and Program {4}", caseID, serviceRequestID, ci.MemberId, ci.MembershipId, DMSCallContext.MemberProgramID);
            logger.InfoFormat("Logged SR Agent time record {0}", srAgentTime.ID);
            DMSCallContext.SRAgentTime = srAgentTime;

            DMSCallContext.CaseID = caseID;
            DMSCallContext.SourceSystemFromCase = SourceSystemName.DISPATCH; //TFS 1362: Set SourceSystem = Dispatch for Cases created via ODIS.
            DMSCallContext.ServiceRequestID = serviceRequestID;
            DMSCallContext.RequestOpenedTime = DateTime.Now;
            DMSCallContext.MemberID = ci.MemberId.GetValueOrDefault();
            DMSCallContext.MembershipID = ci.MembershipId.GetValueOrDefault();
            DMSCallContext.StartCallData = ci;
            if (DMSCallContext.MobileCallForServiceRecord != null)
            {
                logger.Info("Setting details from mobile into session");
                var mobileRecord = DMSCallContext.MobileCallForServiceRecord;
                DMSCallContext.ContactFirstName = mobileRecord.FirstName;
                DMSCallContext.ContactLastName = mobileRecord.LastName;
                DMSCallContext.ServiceLocationLatitude = Convert.ToDecimal(mobileRecord.locationLatitude);
                DMSCallContext.ServiceLocationLongitude = Convert.ToDecimal(mobileRecord.locationLongtitude);

                var pc = CallFacade.GetProductCategoryByNameFromMobile(mobileRecord.serviceType);
                if (pc != null)
                {
                    DMSCallContext.ProductCategoryID = pc.ID;
                    DMSCallContext.ProductCategoryName = pc.Name;
                }
            }
            //TFS : 452
            //DMSCallContext.ProgramID = ci.ProgramId.GetValueOrDefault();

            DMSCallContext.ClientName = ci.ClientName;

            if (ci.CallTypeId.HasValue)
            {

                int? ccID = CallFacade.GetContactCategoryID(ci.CallTypeId.Value);
                DMSCallContext.ContactCategoryID = ccID ?? 0;
            }
            OperationResult result = new OperationResult()
            {
                Status = OperationStatus.SUCCESS
            };
            // Sanghi : Use Member Program ID through out the processing.
            // Request #920
            DMSCallContext.ProgramID = DMSCallContext.MemberProgramID;
            // Cache Hagerty programs
            DMSCallContext.HagertyChildPrograms = ReferenceDataRepository.GetChildPrograms("Hagerty");
            //QueueFacade queueFacade = new QueueFacade();
            //Case caseRecord = queueFacade.GetCase(caseID.ToString());

            return Json(result);
        }

        /// <summary>
        /// Actives the request.
        /// </summary>
        /// <param name="ci">The ci.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult ActiveRequest(CallInformation ci)
        {
            logger.InfoFormat("RequestController - ActiveRequest() - Call Information ID : {0}", DMSCallContext.InboundCallID);
            OperationResult result = new OperationResult()
            {
                Status = OperationStatus.SUCCESS
            };

            DMSCallContext.ServiceTechComments = string.Empty;
            RegisterUserModel up = GetProfile() as RegisterUserModel;
            CheckSessionValidity(up);
            ci.UserProfile = new KeyValuePair<string, int?>(up.UserName, up.ID);
            ci.InboundCallId = DMSCallContext.InboundCallID;
            int caseID = 0;
            int serviceRequestID = 0;
            var inboundCallRepository = new InboundCallRepository();
            var inboundCall = inboundCallRepository.GetInboundCallById(ci.InboundCallId);

            ci.MemberProgramID = DMSCallContext.MemberProgramID;
            //KB: TFS: 452
            ci.ProgramId = DMSCallContext.MemberProgramID;
            logger.InfoFormat("Call information : {0}", ci.ToString());
            // Check to see if the record is already being worked on by some other user.
            int? srOpenedBy = CallFacade.GetUserWorkingOnActiveServiceRequest(ci.MemberId.Value);
            bool isEditLocked = false;

            if (srOpenedBy.HasValue && srOpenedBy.Value != up.ID)
            {
                //Bug 213
                DesktopNotificationFacade desktopFacade = new DesktopNotificationFacade();
                UsersFacade userfacade = new UsersFacade();
                User lockeduser = userfacade.GetById(srOpenedBy.Value);
                aspnet_Users userobj = userfacade.Get(lockeduser.aspnet_UserID);
                var connectedusers = desktopFacade.GetUserLiveConnections(userobj.UserName);
                if (connectedusers.Count() > 0)
                {
                    isEditLocked = true;
                }
            }

            if (!isEditLocked)
            {

                CallFacade.ActiveRequest(ci, out caseID, out serviceRequestID);

                DMSCallContext.CaseID = caseID;
                DMSCallContext.ServiceRequestID = serviceRequestID;
                DMSCallContext.RequestOpenedTime = DateTime.Now;
                DMSCallContext.MemberID = ci.MemberId.GetValueOrDefault();
                DMSCallContext.MembershipID = ci.MembershipId.GetValueOrDefault();
                DMSCallContext.StartCallData = ci;

                DMSCallContext.ProgramID = DMSCallContext.MemberProgramID;
                DMSCallContext.ClientName = ci.ClientName;

                if (ci.CallTypeId.HasValue)
                {

                    int? ccID = CallFacade.GetContactCategoryID(ci.CallTypeId.Value);
                    DMSCallContext.ContactCategoryID = ccID ?? 0;
                }

                QueueFacade queueFacade = new QueueFacade();
                Case caseRecord = queueFacade.GetCase(caseID.ToString());

                ServiceRequestRepository sf = new ServiceRequestRepository();
                ServiceRequest sr = sf.GetById(serviceRequestID);

                if (sr.NextAction != null)
                {
                    DMSCallContext.NextAction = sr.NextAction.Name;
                }

                // Update the case with current user
                // Update the case record.
                //caseRecord.AssignedToUserID = up.ID;
                var timeType = ReferenceDataRepository.GetTimeTypeByName(TimeTypes.FRONTEND);
                var srAgentTime = new ServiceRequestAgentTime()
                {
                    IsInboundCall = true,
                    ProgramID = caseRecord.ProgramID,
                    TimeTypeID = timeType != null ? timeType.ID : (int?)null,
                    BeginDate = inboundCall != null ? inboundCall.CreateDate : (DateTime?)null
                };
                queueFacade.UpdateCase(caseRecord, serviceRequestID, up.ID, Request.RawUrl, EventNames.OPEN_ACTIVE_REQUEST, "User opened Active Request for edit", up.UserName, HttpContext.Session.SessionID, srAgentTime);
                //TFS: 1362 - Cache the SourceSystem.
                if (caseRecord.SourceSystem != null)
                {
                    DMSCallContext.SourceSystemFromCase = caseRecord.SourceSystem.Name;
                }
                DMSCallContext.SRAgentTime = srAgentTime;
                // From Service request.
                DMSCallContext.ServiceLocationLatitude = sr.ServiceLocationLatitude;
                DMSCallContext.ServiceLocationLongitude = sr.ServiceLocationLongitude;
                DMSCallContext.DestinationLatitude = sr.DestinationLatitude;
                DMSCallContext.DestinationLongitude = sr.DestinationLongitude;
                DMSCallContext.ServiceMiles = sr.ServiceMiles;
                DMSCallContext.ServiceEstimateFee = sr.ServiceEstimate;
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
                DMSCallContext.VehicleTypeID = caseRecord.VehicleTypeID;
                DMSCallContext.VehicleMake = caseRecord.VehicleMake;
                DMSCallContext.VehicleYear = caseRecord.VehicleYear;

                DMSCallContext.IsDispatchThresholdReached = sr.IsDispatchThresholdReached ?? false;

                DMSCallContext.ContactFirstName = caseRecord.ContactFirstName;
                DMSCallContext.ContactLastName = caseRecord.ContactLastName;
                DMSCallContext.ContactEmail = caseRecord.ContactEmail;

                // CR: 1239 - DeliveryDriver
                DMSCallContext.IsDeliveryDriver = caseRecord.IsDeliveryDriver;

                DMSCallContext.StartCallData.ContactPhoneNumber = caseRecord.ContactPhoneNumber;
                DMSCallContext.StartCallData.ContactPhoneTypeID = caseRecord.ContactPhoneTypeID;
                DMSCallContext.StartCallData.ContactAltPhoneNumber = caseRecord.ContactAltPhoneNumber;
                DMSCallContext.StartCallData.ContactAltPhoneTypeID = caseRecord.ContactAltPhoneTypeID;



                DMSCallContext.IsSMSAvailable = caseRecord.IsSMSAvailable ?? false;

                if (caseRecord.VehicleTypeID != null)
                {

                    DMSCallContext.LastUpdatedVehicleType = GetVehicleTypeNameById(caseRecord.VehicleTypeID.Value);
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

                //TFS:163
                result.Data = GetTabValidationStatusAsJson(serviceRequestID);

            }
            else
            {
                result.Status = OperationStatus.ERROR;
                UsersFacade uFacade = new UsersFacade();
                User lockedBy = uFacade.GetById(srOpenedBy.GetValueOrDefault());
                int? srId = CallFacade.GetActiveServiceRequestId(ci);
                string lockedUser = string.Empty;
                if (lockedBy != null)
                {
                    lockedUser = string.Join(" ", lockedBy.FirstName, lockedBy.LastName);
                }
                logger.InfoFormat("RequestController - ActiveRequest() - isEditLocked : {0},LockedUser : {1}", isEditLocked, lockedUser);
                result.Data = new { ServiceRequestID = srId, LockedUser = lockedUser, LockedUserId = lockedBy.ID };

            }

            // Cache Hagerty programs
            DMSCallContext.HagertyChildPrograms = ReferenceDataRepository.GetChildPrograms("Hagerty");
            logger.InfoFormat("RequestController - ActiveRequest() - Opened SR ID : {0}", DMSCallContext.ServiceRequestID);
            return Json(result);
        }

        [NoCache]
        [HttpPost]
        public ActionResult SaveLockedServiceRequestData(int? serviceRequestId, int? lockedUserId)
        {
            OperationResult result = new OperationResult()
            {
                Status = OperationStatus.SUCCESS
            };
            DMSCallContext.ActiveRequestLocked = true;
            DMSCallContext.ActiveRequestLockedByUser = lockedUserId;
            DMSCallContext.ActiveServiceRequestId = serviceRequestId;
            return Json(result);
        }

        /// <summary>
        /// Saves the inbound call.
        /// </summary>
        /// <param name="ci">The ci.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveInboundCall(CallInformation ci)
        {
            if (ci.CallTypeId.HasValue)
            {
                int? ccID = CallFacade.GetContactCategoryID(ci.CallTypeId.Value);
                DMSCallContext.ContactCategoryID = ccID ?? 0;
            }
            if (ci.MemberId.HasValue)
            {
                DMSCallContext.MemberID = ci.MemberId.Value;
            }
            //DMSCallContext.StartCallData = ci;
            RegisterUserModel up = Session[StringConstants.LOGGED_IN_USER] as RegisterUserModel;
            CheckSessionValidity(up);
            ci.UserProfile = new KeyValuePair<string, int?>(up.UserName, up.ID);
            ci.InboundCallId = DMSCallContext.InboundCallID;
            ci.EventSource = Request.RawUrl;
            //KB: TFS : 452
            if (ci.ProgramId != DMSCallContext.ProgramID)
            {
                ci.ProgramId = DMSCallContext.ProgramID;
            }
            ci.CaseID = DMSCallContext.CaseID;

            CallFacade.SaveInboundCall(ci);
            logger.InfoFormat("Saved inbound call details for id : {0}", ci.InboundCallId);

            OperationResult result = new OperationResult()
            {
                Status = OperationStatus.SUCCESS
            };

            return Json(result);
        }

        /// <summary>
        /// Gets the program dynamic fields.
        /// </summary>
        /// <param name="screenName">Name of the screen.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult GetProgramDynamicFields(string screenName, int programID)
        {
            logger.InfoFormat("RequestController - GetProgramDynamicFields() - screenName : {0}, programID : {1}", screenName, programID);
            List<DynamicFields> list = new ProgramMaintenanceFacade().GetProgramDynamicFields(screenName, programID);
            return PartialView("_ProgramDynamicFields", list);
        }

        /// <summary>
        /// Gets the call summary.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [HttpPost]
        public ActionResult GetCallSummary()
        {
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(DMSCallContext.ProgramID, "Service", "Validation");
            bool memberEligibleApllies = false;

            var item = result.Where(x => (x.Name.Equals("MemberEligibilityApplies", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (item != null)
            {
                memberEligibleApllies = true;
            }

            ViewData["MemberEligibilityApplies"] = memberEligibleApllies;
            CallFacade facade = new CallFacade();
            return View("_CallSummary", facade.GetCallSummary(DMSCallContext.ServiceRequestID));
        }
        #endregion


        /// <summary>
        /// Get service request exceptions.
        /// </summary>
        /// <param name="tabName">Name of the tab.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _GetServiceRequestExceptions(string tabName)
        {
            RequestArea requestArea;
            List<ServiceRequestException> listOfExceptions = null;
            if (!string.IsNullOrEmpty(tabName))
            {
                Enum.TryParse<RequestArea>(tabName, out requestArea);
                listOfExceptions = CallFacade.GetAllExceptions(DMSCallContext.ServiceRequestID, requestArea);
                ViewData[StringConstants.SERVICE_REQUEST_EXCEPTIONS] = listOfExceptions;
            }
            else
            {
                listOfExceptions = CallFacade.GetAllExceptions(DMSCallContext.ServiceRequestID, null);
                ViewData[StringConstants.SERVICE_REQUEST_EXCEPTIONS] = listOfExceptions;
            }

            TabValidationStatus tabValidationStatus = TabValidationStatus.NOT_VISITED;

            if (listOfExceptions != null && listOfExceptions.Count > 0)
            {
                tabValidationStatus = TabValidationStatus.VISITED_WITH_ERRORS;
            }
            ViewData[StringConstants.TAB_VALIDATION_STATUS] = tabValidationStatus;

            return PartialView("_ServiceRequestExceptions");
        }
    }

}
