using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.ActionFilters;
using ClientPortal.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using ClientPortal.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using ClientPortal.Areas.Application.Models;
using ClientPortal.Areas.Application.Controllers;

namespace ClientPortal.Areas.Common.Controllers
{
    class CustomCasePhoneLocation : CasePhoneLocation
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public int? MemberID { get; set; }
        public int? MembershipID { get; set; }
    }
  
    public class EmergencyAssistanceController : VehicleBaseController
    {
        #region Private Members
        const string EMERGENCY_ASSISTANCE_CONTACT_CATEGORY = "EmergencyAssistance";
        protected EmergencyAssistanceFacade facade = new EmergencyAssistanceFacade();

        #endregion

        #region Public Methods

        private CasePhoneLocation DoServiceLookUp(string callbackNumber)
        {
            List<PhoneType> phoneTypes = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER);
            var cellType = phoneTypes.Where(x => x.Name == "Cell").FirstOrDefault();

            EmergencyAssistanceFacade facade = new EmergencyAssistanceFacade();
            CasePhoneLocation casePhoneLocation = null;
            logger.InfoFormat("Trying to execute Waldo Web Service for the given Call Back number {0}", callbackNumber);
            casePhoneLocation = facade.WSGetPhoneLocation(callbackNumber, -1);
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

        private void PopulateCustomCasePhoneLocation(ref CustomCasePhoneLocation detailsRecord, ref CasePhoneLocation locationResult)
        {

            if (locationResult != null)
            {
                detailsRecord.CivicLatitude = locationResult.CivicLatitude;
                detailsRecord.CivicLongitude = locationResult.CivicLongitude;
                detailsRecord.CivicStreet = locationResult.CivicStreet;
                detailsRecord.CivicCity = locationResult.CivicCity;
                detailsRecord.CivicState = locationResult.CivicState;
                detailsRecord.CivicZip = locationResult.CivicZip;
                detailsRecord.CrossStreet = locationResult.CrossStreet;
                detailsRecord.CrossDirection = locationResult.CrossDirection;
                detailsRecord.IntersectionStreet1 = locationResult.IntersectionStreet1;
                detailsRecord.IntersectionStreet2 = locationResult.IntersectionStreet2;
                detailsRecord.IntersectionDirection = locationResult.IntersectionDirection;
                detailsRecord.LocationAccuracy = locationResult.LocationAccuracy;
            }

        }

        private CustomCasePhoneLocation HandleMobileIntegration(string callbackNumber, int? contactPhoneTypeID)
        {
            DMSCallContext.CallbackNumber = callbackNumber;
            DMSCallContext.ContactPhoneTypeID = contactPhoneTypeID;
            CustomCasePhoneLocation detailsRecord = new CustomCasePhoneLocation();
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
                CasePhoneLocation locationResult = DoServiceLookUp(callbackNumber);
                PopulateCustomCasePhoneLocation(ref detailsRecord, ref locationResult);
                DMSCallContext.MobileCallForServiceRecord = null;
            }
            else if (info != null && info.Count > 0)
            {
                //Clear previous values if any.
                DMSCallContext.MobileCallForServiceRecord = null;
                logger.Info("Found one record - checking to see if it is from mobile or Case");
                MobileCallData_Result resultMobile = info.ElementAt(0);
                detailsRecord.FirstName = resultMobile.FirstName;
                detailsRecord.LastName = resultMobile.LastName;
                detailsRecord.MemberID = resultMobile.MemberID;
                detailsRecord.MembershipID = resultMobile.MembershipID;

                if (resultMobile.PKID.HasValue)
                {
                    logger.InfoFormat("Mobile record found, checking to see if there is location information", resultMobile.PKID.Value);
                    DMSCallContext.MobileCallForServiceRecord = resultMobile;

                    if (!string.IsNullOrEmpty(resultMobile.locationLatitude) && !string.IsNullOrEmpty(resultMobile.locationLongtitude))
                    {
                        logger.Info("Location information found on the mobile record.");
                        
                        decimal latitude = 0;
                        decimal longitude = 0;
                        decimal.TryParse(resultMobile.locationLatitude, out latitude);
                        decimal.TryParse(resultMobile.locationLongtitude, out longitude);
                        detailsRecord.CivicLatitude = latitude;
                        detailsRecord.CivicLongitude = longitude;
                        
                    }
                    else
                    {
                        logger.Info("Mobile record doesn't have location information, therefore invoking Waldo service");
                        CasePhoneLocation location = DoServiceLookUp(callbackNumber);
                        if (location != null && location.CivicLatitude.HasValue && location.CivicLongitude.HasValue)
                        {
                            logger.Info("Set Mobile Result into Session");
                            resultMobile.locationLatitude = location.CivicLatitude.ToString();
                            resultMobile.locationLongtitude = location.CivicLongitude.ToString();
                            DMSCallContext.MobileCallForServiceRecord = resultMobile;
                            PopulateCustomCasePhoneLocation(ref detailsRecord, ref location);
                        }
                        else
                        {
                            logger.Info("No location information returned by the Waldo service !");
                        }
                    }
                }
                else
                {
                    // Set the member details if found from previous cases
                    detailsRecord.MemberID = resultMobile.MemberID;
                    detailsRecord.MembershipID = resultMobile.MembershipID;

                    logger.Info("Member found from a previous case, trying to retrieve location information.");
                    CasePhoneLocation location = DoServiceLookUp(callbackNumber);
                    if (location != null && location.CivicLatitude.HasValue && location.CivicLongitude.HasValue)
                    {
                        PopulateCustomCasePhoneLocation(ref detailsRecord, ref location);
                    }
                    else
                    {
                        logger.Info("No location information returned by the Waldo service !");
                    }
                }
            }
            return detailsRecord;
            #region Old Code
            //Mobile_CallForService record = null;
            ///* Mobile Integration */
            //logger.InfoFormat("Trying to see if there exists a case with the given callbacknumber {0} . {1}", contactPhoneTypeID, callbackNumber);
            //DMSCallContext.CallbackNumber = callbackNumber;
            //DMSCallContext.ContactPhoneTypeID = contactPhoneTypeID;

            //// CR : 1127 Mobile integration
            //ProgramMaintenanceFacade progFacade = new ProgramMaintenanceFacade();
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
            //    if (tokens.Length > 1)
            //    {
            //        formattednumber = tokens[1];
            //    }
            //    record = facade.GetMobileCallForService(formattednumber);
            //    if (record != null && !string.IsNullOrEmpty(record.locationLatitude) && !string.IsNullOrEmpty(record.locationLongtitude))
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
            //        List<PhoneType> phoneTypes = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER);
            //        var cellType = phoneTypes.Where(x => x.Name == "Cell").FirstOrDefault();
            //        if (cellType != null)
            //        {
            //            phoneLocation.PhoneTypeID = cellType.ID;
            //        }


            //        Member member = facade.GetMemberByNumber(record.MemberNumber);
            //        if (member != null)
            //        {
            //            logger.InfoFormat("Found a member with the given member number -- {0}", record.MemberNumber);
            //        }

            //        MobileCallForServiceFacade callForServiceFacade = new MobileCallForServiceFacade();
            //        callForServiceFacade.UpdateRelevantData(phoneLocation, DMSCallContext.InboundCallID, (member == null) ? (int?)null : member.ID, record.PKID);

            //        logger.InfoFormat("Created and updated CasePhoneLocation and InboundCall records");
            //        //DMSCallContext.MobileCallForServiceRecord = record;

            //    }
            //}
            #endregion

        }

        /// <summary>
        /// Use to Store Call Back Number into Session
        /// </summary>
        /// <param name="callbackNumber"></param>
        /// <param name="typeID"></param>
        /// <returns></returns>
        public JsonResult SavePhoneNumberIntoSession(string callbackNumber, string typeID)
        {
            DMSCallContext.CallbackNumber = callbackNumber;
            int contactPhoneTypeID = 0;
            int.TryParse(typeID, out contactPhoneTypeID);
            DMSCallContext.ContactPhoneTypeID = contactPhoneTypeID;
            OperationResult result = new OperationResult();
            result.OperationType = OperationStatus.SUCCESS;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        // GET: /Common/Map/
        /// <summary>
        /// Get the view with BING Map.
        /// Load the view if there exists an emergency record for the given case ID
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.VehicleType, false)]
        [ReferenceDataFilter(StaticData.ProvinceAbbreviation, true)]
        [ReferenceDataFilter(StaticData.EmergencyAssistanceReason, true)]
        //[ReferenceDataFilter(StaticData.Colors, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        public ActionResult Index()
        {
            #region Dummy Drop Down Values
            List<SelectListItem> voidYearlist = new List<SelectListItem>();
            voidYearlist.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            ViewData[StaticData.VehicleModelYear.ToString()] = voidYearlist;
            ViewData[StaticData.VehicleMake.ToString()] = voidYearlist;
            ViewData[StaticData.VehicleModel.ToString()] = voidYearlist;
            #endregion

            #region Session Variables for InboundCall ID and Callback Number and CaseID
            string callBackNumberFromSession = string.Empty;
            int inBoundCallID = 0;
            int caseID = 0;
            int phoneTypeID = 0;

            //Get the callback Number from Session and if it's available call the web service.
            if (DMSCallContext.CallbackNumber != null)
            {
                callBackNumberFromSession = DMSCallContext.CallbackNumber;
            }
            // Get Inbound Call ID
            if (DMSCallContext.InboundCallID != 0)
            {
                inBoundCallID = DMSCallContext.InboundCallID;
            }
            // Get Case ID from Session
            if (DMSCallContext.CaseID != 0)
            {
                caseID = DMSCallContext.CaseID;
            }

            if (inBoundCallID == 0)
            {
                InboundCall _callDetails = new InboundCallRepository().GetInboundCallByCaseId(caseID);
                if (_callDetails == null)
                {
                    throw new DMSException("InBoundCallID is not supplied.");
                }
                else
                {
                    DMSCallContext.InboundCallID = _callDetails.ID;
                }

            }

            if (DMSCallContext.ContactPhoneTypeID != null && DMSCallContext.ContactPhoneTypeID.Value != 0)
            {
                phoneTypeID = DMSCallContext.ContactPhoneTypeID.Value;
            }
            #endregion

            logger.InfoFormat("Executing Map Controller for case id : {0}", caseID);

            ViewData[StaticData.ContactActions.ToString()] = ReferenceDataRepository.GetContactAction(EMERGENCY_ASSISTANCE_CONTACT_CATEGORY).ToSelectListItem(x => x.ID.ToString(), y => y.Description, false);
            ViewData[StaticData.ContactSources.ToString()] = ReferenceDataRepository.GetContactSource(EMERGENCY_ASSISTANCE_CONTACT_CATEGORY).ToSelectListItem(x => x.ID.ToString(), y => y.Description, false);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.Colors.ToString()] = ReferenceDataRepository.GetColors();

            EmergencyAssistanceModel model = facade.GetEmergencyAssistance(inBoundCallID, callBackNumberFromSession, caseID, DMSCallContext.ServiceRequestID);
            if (model.EmergencyAssistance.VehicleTypeID.HasValue)
            {
                double? year = null;
                if (!string.IsNullOrEmpty(model.EmergencyAssistance.VehicleYear))
                {
                    double yearValue = 0;
                    double.TryParse(model.EmergencyAssistance.VehicleYear, out yearValue);
                    if (yearValue > 0)
                    {
                        year = yearValue;
                    }
                }
                ViewData[StaticData.VehicleModelYear.ToString()] = GetVehicleYears(model.EmergencyAssistance.VehicleTypeID.Value);
                ViewData[StaticData.VehicleMake.ToString()] = GetVehicleMake(model.EmergencyAssistance.VehicleYear, model.EmergencyAssistance.VehicleTypeID.Value);
                ViewData[StaticData.VehicleModel.ToString()] = GetVehicleModel(model.EmergencyAssistance.VehicleMake, year, model.EmergencyAssistance.VehicleTypeID.Value);
            }
            logger.InfoFormat("Finished retrieving details.");
            model.EmergencyAssistance.ContactPhoneTypeID = phoneTypeID;

            EventLoggerFacade eventLogfacade = new EventLoggerFacade();
            eventLogfacade.LogEvent(Request.RawUrl, EventNames.ENTER_EMERGENCY_TAB, "Enter emergency tab", GetLoggedInUser().UserName, null, EntityNames.EMERGENCY_ASSISTANCE, HttpContext.Session.SessionID);

            return PartialView("_Map", model);
        }


        /// <summary>
        /// Get Phone location by calling the phone location web service.
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
        /// <param name="caseId">The case id.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        [ValidateInput(false)]
        public JsonResult WSGetPhoneLocation(string phoneNumber, string caseId)
        {
            OperationResult result = new OperationResult();

            int intCaseID = 0;
            int.TryParse(caseId, out intCaseID);
            logger.InfoFormat("Retrieving WS Phone Location for given Phone Number {0} and Case ID {1}", phoneNumber, caseId);

            CustomCasePhoneLocation mobileResult = HandleMobileIntegration(DMSCallContext.CallbackNumber, DMSCallContext.ContactPhoneTypeID);
            if (mobileResult != null && mobileResult.CivicLatitude.HasValue && mobileResult.CivicLongitude.HasValue)
            {
                result.Status = OperationStatus.SUCCESS;
                result.Data = new
                {
                    Latitude = mobileResult.CivicLatitude.Value,
                    Longitude = mobileResult.CivicLongitude.Value,
                    ResultType = (int)PhoneLocationResultType.SUCCESS,
                    SearchLocation = mobileResult.ToString(),
                    ResultTypeMessage = string.Empty,
                    CivicStreet = mobileResult.CivicStreet,
                    CivicCity = mobileResult.CivicCity,
                    CivicState = mobileResult.CivicState,
                    CivicZip = mobileResult.CivicZip,
                    CrossStreet = mobileResult.CrossStreet,
                    CrossDirection = mobileResult.CrossDirection,
                    IntersectionStreet1 = mobileResult.IntersectionStreet1,
                    IntersectionStreet2 = mobileResult.IntersectionStreet2,
                    IntersectionDirecton = mobileResult.IntersectionDirection,
                    LocationAccuracy = mobileResult.LocationAccuracy,
                    FirstName = mobileResult.FirstName,
                    LastName = mobileResult.LastName,
                    MemberID = mobileResult.MemberID,
                    MembershipID = mobileResult.MembershipID
                };
            }
            else
            {
                result.Status = OperationStatus.ERROR;
                result.Data = new
                {
                    ResultType = (int)PhoneLocationResultType.NO_RECORDS_FOUND,
                    ResultTypeMessage = "There is no location information for this phone number."
                };
            }

            //CasePhoneLocation phoneLocation = emergencyFacade.WSGetPhoneLocation(DMSCallContext.InboundCallID);
            //if (phoneLocation == null)
            //{
            //    logger.InfoFormat("Phone location not found via InboundCallID, so going by case");
            //    phoneLocation = facade.WSGetPhoneLocation(phoneNumber, intCaseID);
            //}
            //if (phoneLocation == null)
            //{

            //    logger.Error("Phone Location is NULL");
            //}
            //else
            //{
            //    result.Status = OperationStatus.SUCCESS;
            //    result.Data = new
            //    {
            //        SearchLocation = phoneLocation.ToString(),
            //        Latitude = phoneLocation.CivicLatitude,
            //        Longitude = phoneLocation.CivicLongitude,
            //        ResultType = (int)PhoneLocationResultType.SUCCESS,
            //        ResultTypeMessage = string.Empty,
            //        CivicStreet = phoneLocation.CivicStreet,
            //        CivicCity = phoneLocation.CivicCity,
            //        CivicState = phoneLocation.CivicState,
            //        CivicZip = phoneLocation.CivicZip,
            //        CrossStreet = phoneLocation.CrossStreet,
            //        CrossDirection = phoneLocation.CrossDirection,
            //        IntersectionStreet1 = phoneLocation.IntersectionStreet1,
            //        IntersectionStreet2 = phoneLocation.IntersectionStreet2,
            //        IntersectionDirecton = phoneLocation.IntersectionDirection,
            //        LocationAccuracy = phoneLocation.LocationAccuracy
            //    };
            //    logger.Info("Retrieving Phone Location success");
            //}
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// Creates the emergency assistance record.
        /// This method is invoked when the sound icons are clicked on the pop up.
        /// A check is made to see if an emergency record already exists.A new record is created if none exists or the existing one is updated, otherwise.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public ActionResult SaveEmergencyAssistance(EmergencyAssistanceModel model, int? selectedVehicleTypeID)
        {

            var ea = model.EmergencyAssistance;

            if (!string.IsNullOrEmpty(ea.VehicleYear) && ea.VehicleYear.Equals("Select"))
            {
                ea.VehicleYear = string.Empty;
            }
            if (!string.IsNullOrEmpty(ea.VehicleMake) && ea.VehicleMake.Equals("Select"))
            {
                ea.VehicleMake = string.Empty;
            }
            if (!string.IsNullOrEmpty(ea.VehicleModel) && ea.VehicleModel.Equals("Select"))
            {
                ea.VehicleModel = string.Empty;
            }

            if (!string.IsNullOrEmpty(ea.VehicleModel) && !ea.VehicleModel.Equals("other", StringComparison.OrdinalIgnoreCase))
            {
                ea.VehicleModelOther = string.Empty;
            }
            if (!string.IsNullOrEmpty(ea.VehicleMake) && !ea.VehicleMake.Equals("other", StringComparison.OrdinalIgnoreCase))
            {
                ea.VehicleMakeOther = string.Empty;
            }

            if (!string.IsNullOrEmpty(ea.VehicleYear) && ea.VehicleYear.Equals("select year", StringComparison.InvariantCultureIgnoreCase))
            {
                ea.VehicleYear = null;
            }
            if (!string.IsNullOrEmpty(ea.VehicleMake) && ea.VehicleMake.Equals("select make", StringComparison.InvariantCultureIgnoreCase))
            {
                ea.VehicleMake = null;
            }
            if (!string.IsNullOrEmpty(ea.VehicleModel) && ea.VehicleModel.Equals("select model", StringComparison.InvariantCultureIgnoreCase))
            {
                ea.VehicleModel = null;
            }
            if (!string.IsNullOrEmpty(ea.VehicleLicenseState) && ea.VehicleLicenseState.Equals("select", StringComparison.InvariantCultureIgnoreCase))
            {
                ea.VehicleLicenseState = null;
            }


            // Session Variables
            int caseId = 0;
            string callBackNumberFromSession = string.Empty;
            int inBoundCallID = 0;

            //Get the callback Number from Session and if it's available call the web service.
            if (DMSCallContext.CallbackNumber != null)
            {
                callBackNumberFromSession = DMSCallContext.CallbackNumber;
            }
            // Get Inbound Call ID
            if (DMSCallContext.InboundCallID != 0)
            {
                inBoundCallID = DMSCallContext.InboundCallID;
            }
            // Get Case ID
            if (DMSCallContext.CaseID != 0)
            {
                caseId = DMSCallContext.CaseID;
            }

            if (model.EmergencyAssistance == null || model.ContactLog == null)
            {
                logger.ErrorFormat("Emergency Assistance for Case {0} Model is NULL", model.EmergencyAssistance.CaseID);
                throw new DMSException("Model is not Null");
            }
            // Set the vehicletype ID on emergency assistance
            model.EmergencyAssistance.VehicleTypeID = selectedVehicleTypeID;
            DMSCallContext.VehicleTypeID = selectedVehicleTypeID;

            if (model.EmergencyAssistance.VehicleTypeID.HasValue)
            {
                DMSCallContext.LastUpdatedVehicleType = GetVehicleTypeNameById(model.EmergencyAssistance.VehicleTypeID.Value);

            }

            DMSCallContext.ServiceLocationLatitude = model.EmergencyAssistance.Latitude;
            DMSCallContext.ServiceLocationLongitude = model.EmergencyAssistance.Longitude;

            OperationResult oResult = new OperationResult();
            model.EmergencyAssistance.CaseID = caseId;
            logger.InfoFormat("Saving Emergency Assistance for Case {0}", model.EmergencyAssistance.CaseID);

            if (inBoundCallID != 0)
            {
                model.EmergencyAssistance.InboundCallID = inBoundCallID;
            }
            if (caseId != 0)
            {
                model.EmergencyAssistance.CaseID = caseId;
            }
            // Save Emergency Assistance details
            PreviousCallList currentCallDetails = facade.SaveEmergencyAssistance(model, GetLoggedInUser().UserName, Request.RawUrl, HttpContext.Session.SessionID);

            logger.Info("Saving Emergency success");

            List<PreviousCallList> recentCall = new List<PreviousCallList>();
            if (currentCallDetails != null)
            {
                recentCall.Add(new PreviousCallList()
                {
                    ContactSourceName = currentCallDetails.ContactSourceName,
                    Company = currentCallDetails.Company,
                    PhoneNumber = currentCallDetails.PhoneNumber,
                    TalkedTo = currentCallDetails.TalkedTo,
                    CreateDate = currentCallDetails.CreateDate,
                    CreateBy = currentCallDetails.CreateBy,
                    ContactActionName = currentCallDetails.ContactActionName
                });
            }

            return PartialView("_PreviousCallList", recentCall);
        }

        /// <summary>
        /// Saves the comment against Emergency.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [DMSAuthorize]
        [ValidateInput(false)]
        public JsonResult SaveComment(Comment model)
        {
            OperationResult oResult = new OperationResult();

            logger.InfoFormat("Save Comment for ID {0}", model.ID);
            CommentFacade commentFacade = new CommentFacade();
            commentFacade.Save(model, GetLoggedInUser().UserName);
            oResult.Status = OperationStatus.SUCCESS;
            logger.Info("Save success");


            return Json(oResult, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the PSAP number.
        /// </summary>
        /// <param name="latitude">The latitude.</param>
        /// <param name="longitude">The longitude.</param>
        /// <returns></returns>
        [HttpPost]
        [DMSAuthorize]
        [ValidateInput(false)]
        public JsonResult GetPSAPNumber(string latitude, string longitude)
        {
            OperationResult oResult = new OperationResult();

            logger.InfoFormat("Retrieving PSAP Number for given latitude {0} and longitude {1}", latitude, longitude);
            ContactEmergencyAssistance result = facade.WSGetPSAPNumber(latitude, longitude);
            if (result.IsError)
            {
                oResult.Status = OperationStatus.ERROR;
                result.ErrorMessage = "The PSP lookup service is temporarily unavailable. Please try again";
            }
            else
            {
                oResult.Status = OperationStatus.SUCCESS;
            }
            oResult.Data = result;
            logger.Info("Retrieving PSAP finished");
            EventLoggerFacade eventLogfacade = new EventLoggerFacade();
            eventLogfacade.LogEvent(Request.RawUrl, EventNames.EMERGENCY_USEPSAP, "Executed get PSAP", GetLoggedInUser().UserName, null, EntityNames.EMERGENCY_ASSISTANCE, HttpContext.Session.SessionID);
            return Json(oResult, JsonRequestBehavior.AllowGet);
        }

        #endregion

        #region Cascading Drop Down

        public JsonResult _GetVehicleYears(string vehicleTypeID)
        {

            JsonResult result = new JsonResult();
            int vehicleTypeInt = 0;
            int.TryParse(vehicleTypeID, out vehicleTypeInt);
            result.Data = GetVehicleYears(vehicleTypeInt);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Get Vehicle make values for the given vehicle year
        /// </summary>
        /// <param name="VehicleYear">The vehicle year.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public JsonResult _GetComboVehicleMake(string Year, string vehicleType)
        {

            int vehicleTypeID = 0;
            int.TryParse(vehicleType, out vehicleTypeID);
            return Json(GetVehicleMake(Year, vehicleTypeID), JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// Get Vehicle models for the given vehicle make
        /// </summary>
        /// <param name="VehicleMake">The vehicle make.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public JsonResult _GetComboVehicleModel(string make, double? year, string vehicleType)
        {

            int vehicleTypeID = 0;
            int.TryParse(vehicleType, out vehicleTypeID);
            return Json(GetVehicleModel(make, year, vehicleTypeID), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Get Combo Vehicles
        /// </summary>
        /// <param name="make"></param>
        /// <param name="year"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public JsonResult _GetComboVehicleStringModel(string make, double? year)
        {
            logger.InfoFormat("Retrieving Combo Vehicle Model for given Vehicle Make {0} ", make);


            GenericIEqualityComparer<VehicleMakeModel> modelDistinct = GetIEqualityComparerForVehicleModel();

            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetVehicleModel(make, year.GetValueOrDefault()).Distinct(modelDistinct).OrderBy(a => a.Model).ToSelectListItem(x => x.Model.ToString(), y => y.Model.ToString());
            logger.Info("Retrieving Finished for Combo Vehicle Model");
            return Json(list, JsonRequestBehavior.AllowGet);
        }

      
        #endregion

    }
}
