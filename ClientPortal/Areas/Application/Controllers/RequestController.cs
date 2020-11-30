using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.ActionFilters;
using ClientPortal.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;
using ClientPortal.Areas.Common.Controllers;
using ClientPortal.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using ClientPortal.Areas.Application.Models;

namespace ClientPortal.Areas.Application.Controllers
{
    public class RequestController : BaseController
    {

        #region Private Methods
        /// <summary>
        /// 
        /// </summary>
        /// <param name="up"></param>
        private static void CheckSessionValidity(RegisterUserModel up)
        {
            if (up == null)
            {
                throw new DMSException("Session got reset, please reload the page by hitting Ctrl+F5. Contact administrator if the issue persists.");
            }
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        [ControlDisplayManager(ControlConstants.ShowStickyNotes, ControlConstants.ShowComments, ControlConstants.ShowCallTimer)]
        [NoCache]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_START)]
        public ActionResult Index(string id)
        {
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
                logger.InfoFormat("Program allows payment processing : {0}", allowPayment);
            }

            return View();
        }

        public ActionResult IsCalledFromQueue()
        {
            return Content("");
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.CallType, false)]
        [ReferenceDataFilter(StaticData.Language, false)]
        [NoCache]
        public ActionResult _Start()
        {

            var programs = ProgramMaintenanceRepository.GetProgramsForCall((Guid)GetLoggedInUser().ProviderUserKey);
            ViewData["Programs"] = programs.ToSelectListItem(x => x.Id.ToString(), y => y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return PartialView("_Start");
        }

        /// <summary>
        /// Starts the call.Creates inbound call and event log records.
        /// </summary>
        /// <returns></returns>
        ///  
        [NoCache]
        public ActionResult StartCall()
        {
            logger.Info("Attempting to initalize/initiate a call");
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
        /// 
        /// </summary>
        /// <param name="programID"></param>
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
            result.OperationType = OperationStatus.SUCCESS;
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        private CasePhoneLocation HandleMobileLookUp(string callbackNumber)
        {
            List<PhoneType> phoneTypes = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER);
            var cellType = phoneTypes.Where(x => x.Name == "Cell").FirstOrDefault();
            logger.InfoFormat("Trying to execute Waldo Web Service for the given Call Back number {0}", callbackNumber);
            EmergencyAssistanceFacade facade = new EmergencyAssistanceFacade();
            CasePhoneLocation casePhoneLocation = facade.WSGetPhoneLocation(callbackNumber, -1);
            if (casePhoneLocation != null && casePhoneLocation.CivicLatitude.HasValue && casePhoneLocation.CivicLongitude.HasValue)
            {
                logger.InfoFormat("Finished execution of Waldo Web Service found Latitude {0} Longitude {1} ", casePhoneLocation.CivicLatitude, casePhoneLocation.CivicLongitude);
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
                logger.Info("Case Phone Location Created");
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
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMemberFromCase(string callbackNumber, string typeID)
        {
            DMSCallContext.CallbackNumber = callbackNumber;
            int contactPhoneTypeID = 0;
            int.TryParse(typeID, out contactPhoneTypeID);
            DMSCallContext.ContactPhoneTypeID = contactPhoneTypeID;

            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;

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

            logger.InfoFormat("Program {0} IsMobileEnabled - {1}", DMSCallContext.ProgramID, DMSCallContext.IsMobileEnabled);
           
            logger.InfoFormat("Trying to call mobile configuration SP with following program Id {0} callback number {1} inbound call id {2}. The sp considers IsMobileEnabled flag and tries to get a record from mobile_callforservice or Case tables.", DMSCallContext.ProgramID, DMSCallContext.CallbackNumber, DMSCallContext.InboundCallID);
            List<MobileCallData_Result> info = progFacade.GetMobileConfigurationResult(DMSCallContext.ProgramID, "service", "rule", callbackNumber, DMSCallContext.InboundCallID);
            if (info == null || info.Count == 0)
            {
                logger.Info("No mobile record found and no member data found from previous cases too !");
                DMSCallContext.MobileCallForServiceRecord = null;
                HandleMobileLookUp(callbackNumber);
            }

            else if(info != null && info.Count > 0)
            {
                logger.Info("Found one record - checking to see if it is from mobile or Case");
                MobileCallData_Result resultMobile = info.ElementAt(0);
                // Reset mobile record in session.
                DMSCallContext.MobileCallForServiceRecord = null;
                if (resultMobile.PKID.HasValue)
                {
                    logger.InfoFormat("Mobile record found, checking to see if there is location information", resultMobile.PKID.Value);
                    DMSCallContext.MobileCallForServiceRecord = resultMobile;
                    if (!string.IsNullOrEmpty(resultMobile.locationLatitude) && !string.IsNullOrEmpty(resultMobile.locationLongtitude))
                    {
                        logger.Info("Location information found on the mobile record.");                        
                    }
                    else
                    {
                        logger.Info("Mobile record doesn't have location information, therefore invoking Waldo service");
                        CasePhoneLocation location =  HandleMobileLookUp(callbackNumber);
                        if (location != null && location.CivicLatitude.HasValue && location.CivicLongitude.HasValue)
                        {
                            logger.Info("Set Mobile Result into Session");
                            resultMobile.locationLatitude = location.CivicLatitude.ToString();
                            resultMobile.locationLongtitude = location.CivicLongitude.ToString();
                            DMSCallContext.MobileCallForServiceRecord = resultMobile;
                        }
                        else
                        {
                            logger.Info("No location information returned by the Waldo service !");
                        }
                    }
                }
                else
                {
                    logger.Info("Member found from a previous case, trying to retrieve location information.");
                    HandleMobileLookUp(callbackNumber);
                }
                
                if (resultMobile.MemberID != null && resultMobile.MembershipID != null)
                {
                    result.Data = new { memberID = resultMobile.MemberID, membershipID = resultMobile.MembershipID };
                }
            }
            #region Old Code with multiple db calls
            //List<ProgramInformation_Result> info = progFacade.GetProgramInfo(DMSCallContext.ProgramID, "service", "rule");

            //var config = info.Where(x => x.Name == "IsMobileEnabled").FirstOrDefault();
            //if (config != null)
            //{
            //    if ("yes".Equals(config.Value, StringComparison.InvariantCultureIgnoreCase))
            //    {
            //        DMSCallContext.IsMobileEnabled = true;


            //    }
            //}

            //logger.InfoFormat("Program {0} IsMobileEnabled - {1}", DMSCallContext.ProgramID, DMSCallContext.IsMobileEnabled);
            //var facade = new MemberFacade();
            //if (DMSCallContext.IsMobileEnabled)
            //{
            //    /*
            //     * 1. Check to see if there is a record in Mobile_CallForService in the last 30 mins
            //     * 2. Insert a record in CasePhoneLocation (after step # 1 is a success).
            //     * 3. If so, then grab the member number, get the member ID and membershipID and return it back to the view so that it presents the details of the member automatically.                 
            //     * 
            //     */
            //    string formattednumber = callbackNumber.Split('x')[0];
            //    string[] tokens = formattednumber.Split(' ');
            //    formattednumber = tokens[0];
            //    if(tokens.Length > 1)
            //    {
            //        formattednumber = tokens[1];
            //    }
            //    Mobile_CallForService record = facade.GetMobileCallForService(formattednumber);
            //    if (record != null && !string.IsNullOrEmpty (record.locationLatitude) && !string.IsNullOrEmpty(record.locationLongtitude) )
            //    {
            //        logger.InfoFormat("Found a mobile record @ PKID = {0}", record.PKID);
            //        CasePhoneLocation phoneLocation = new CasePhoneLocation();
            //        phoneLocation.CaseID = null;
            //        phoneLocation.PhoneNumber = callbackNumber;
            //        phoneLocation.CivicLatitude = record.LocationLatitudeDecimal;
            //        phoneLocation.CivicLongitude = record.LocationLongitudeDecimal;
            //        phoneLocation.IsSMSAvailable = true;
            //        phoneLocation.LocationDate = record.DateTime;
            //        phoneLocation.LocationAccuracy = "mobile";
            //        phoneLocation.InboundCallID = DMSCallContext.InboundCallID;
            //        List<PhoneType> phoneTypes=  ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER);
            //        var cellType = phoneTypes.Where(x=>x.Name == "Cell").FirstOrDefault();
            //        if (cellType != null)
            //        {
            //            phoneLocation.PhoneTypeID = cellType.ID;
            //        }


            //        Member member = facade.GetMemberByNumber(record.MemberNumber);
            //        if (member != null)
            //        {
            //            logger.InfoFormat("Found a member with the given member number -- {0}", record.MemberNumber);
            //            result.Data = new { memberID = member.ID, membershipID = member.MembershipID };
            //        }

            //        MobileCallForServiceFacade callForServiceFacade = new MobileCallForServiceFacade();
            //        callForServiceFacade.UpdateRelevantData(phoneLocation, DMSCallContext.InboundCallID, (member == null) ? (int?)null : member.ID, record.PKID);

            //        logger.InfoFormat("Created and updated CasePhoneLocation and InboundCall records");
            //        DMSCallContext.MobileCallForServiceRecord = record;
            //        return Json(result);                   

            //    }

            //}            

            //var memberFromCase = facade.GetMemberFromCase(callbackNumber, contactPhoneTypeID);
            //if (memberFromCase != null)
            //{
            //    logger.InfoFormat("Found a member with the given callback number from cases -- {0}", memberFromCase.ID);
            //    result.Data = new { memberID = memberFromCase.ID, membershipID = memberFromCase.MembershipID };
            //}

            #endregion
            return Json(result);
        }

        // Save Inbound call details
        /// <summary>
        /// Saves the inbound call.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="callTypeId">The call type id.</param>
        /// <param name="languageId">The language id.</param>
        /// <param name="callbackNumber">The callback number.</param>
        /// <param name="alternateNumber">The alternate number.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult NewRequest(CallInformation ci)
        {
            DMSCallContext.ServiceTechComments = string.Empty;
            RegisterUserModel up = Session[StringConstants.LOGGED_IN_USER] as RegisterUserModel;
            CheckSessionValidity(up);
            ci.UserProfile = new KeyValuePair<string, int?>(up.UserName, up.ID);
            ci.InboundCallId = DMSCallContext.InboundCallID;
            ci.EventSource = Request.RawUrl;

            int caseID = 0;
            int serviceRequestID = 0;
            CallFacade.NewRequest(ci, out caseID, out serviceRequestID, Session.SessionID, DMSCallContext.MemberProgramID, DMSCallContext.MobileCallForServiceRecord);
            // Set the Case Id, Service Request id and member id in the call context (session).
            logger.Info("Created a new request with the following IDs");
            logger.InfoFormat("Case ID : {0}, Service request id : {1} for member.membership {2}->{3} and Program {4}", caseID, serviceRequestID, ci.MemberId, ci.MembershipId, ci.ProgramId);

            DMSCallContext.CaseID = caseID;
            DMSCallContext.ServiceRequestID = serviceRequestID;
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

            DMSCallContext.ProgramID = ci.ProgramId.GetValueOrDefault();
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

            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="ci"></param>
        /// <returns></returns>
        [NoCache]
        public ActionResult ActiveRequest(CallInformation ci)
        {
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

            logger.InfoFormat("Call information : {0}", ci.ToString());
            ci.MemberProgramID = DMSCallContext.MemberProgramID;

            // Check to see if the record is already being worked on by some other user.
            int? srOpenedBy = CallFacade.GetUserWorkingOnActiveServiceRequest(ci.MemberId.Value);

            if (srOpenedBy == null || srOpenedBy == up.ID)
            {

                CallFacade.ActiveRequest(ci, out caseID, out serviceRequestID);

                DMSCallContext.CaseID = caseID;
                DMSCallContext.ServiceRequestID = serviceRequestID;
                DMSCallContext.MemberID = ci.MemberId.GetValueOrDefault();
                DMSCallContext.MembershipID = ci.MembershipId.GetValueOrDefault();
                DMSCallContext.StartCallData = ci;


                //DMSCallContext.ProgramID = ci.ProgramId.GetValueOrDefault();
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

                // Update the case with current user
                // Update the case record.
                caseRecord.AssignedToUserID = up.ID;

                queueFacade.UpdateCase(caseRecord, Request.RawUrl, EventNames.OPEN_ACTIVE_REQUEST, "User opened Active Request for edit", up.UserName, HttpContext.Session.SessionID);

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
                DMSCallContext.VehicleTypeID = caseRecord.VehicleTypeID;
                DMSCallContext.VehicleMake = caseRecord.VehicleMake;
                DMSCallContext.VehicleYear = caseRecord.VehicleYear;

                DMSCallContext.IsDispatchThresholdReached = sr.IsDispatchThresholdReached ?? false;

                DMSCallContext.ContactFirstName = caseRecord.ContactFirstName;
                DMSCallContext.ContactLastName = caseRecord.ContactLastName;
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
            }
            else
            {
                result.Status = OperationStatus.ERROR;
                UsersFacade uFacade = new UsersFacade();
                User lockedBy = uFacade.GetById(srOpenedBy.GetValueOrDefault());
                if (lockedBy != null)
                {
                    result.Data = string.Join(" ", lockedBy.FirstName, lockedBy.LastName);
                }
            }

            // Cache Hagerty programs
            DMSCallContext.HagertyChildPrograms = ReferenceDataRepository.GetChildPrograms("Hagerty");

            return Json(result);
        }



        /// <summary>
        /// 
        /// </summary>
        /// <param name="ci"></param>
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
            //if (ci.ProgramId.HasValue)
            //{
            //    DMSCallContext.ProgramID = ci.ProgramId.Value;
            //}
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
        /// 
        /// </summary>
        /// <param name="screenName"></param>
        /// <param name="programID"></param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult GetProgramDynamicFields(string screenName, int programID)
        {
            List<DynamicFields> list = new ProgramMaintenanceFacade().GetProgramDynamicFields(screenName, programID);
            return PartialView("_ProgramDynamicFields", list);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [HttpPost]
        public ActionResult GetCallSummary()
        {
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            CallFacade facade = new CallFacade();
            return View("_CallSummary", facade.GetCallSummary(DMSCallContext.ServiceRequestID));
        }
        #endregion
    }

}
