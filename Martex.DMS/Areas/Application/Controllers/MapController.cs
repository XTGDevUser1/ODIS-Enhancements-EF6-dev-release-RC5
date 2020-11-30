using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.DAL.Common;
using Kendo.Mvc.UI;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.Common;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Common;
using Martex.DMS.BLL.Model;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class MapController : BaseController
    {
        #region Private Members
        /// <summary>
        /// The event log facade
        /// </summary>
        EventLoggerFacade eventLogFacade = new EventLoggerFacade();
        #endregion

        #region Public Methods
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult Index()
        {
            logger.InfoFormat("MapController - Index()");
            var serviceRequestRepository = new ServiceRequestRepository();
            logger.InfoFormat("MapController - Index() - Trying to retrieve details from Service Request with ID {0}", DMSCallContext.ServiceRequestID);
            ServiceRequest serviceRequest = serviceRequestRepository.GetById(DMSCallContext.ServiceRequestID);
            ViewData["ServiceLocationLatitude"] = serviceRequest.ServiceLocationLatitude.GetValueOrDefault();
            ViewData["ServiceLocationLongitude"] = serviceRequest.ServiceLocationLongitude.GetValueOrDefault();
            ViewData["ServiceLocationAddress"] = serviceRequest.ServiceLocationAddress;
            ViewData["ServiceLocationDescription"] = serviceRequest.ServiceLocationDescription;

            logger.InfoFormat("MapController - Index() - Details retrieved from Service Request with Latitude {0} Longitude {1}", serviceRequest.ServiceLocationLatitude.GetValueOrDefault(), serviceRequest.ServiceLocationLongitude.GetValueOrDefault());

            if (serviceRequest.ServiceLocationLatitude == null && serviceRequest.ServiceLocationLongitude == null)
            {
                string latitude = string.Empty;
                string longitude = string.Empty;
                string locationAddress = string.Empty;

                logger.InfoFormat("MapController - Index() - Location details are not available against SR so trying to see if there is data in CasePhoneLocation for inbound call ID {0}", DMSCallContext.InboundCallID);

                var emergencyFacade = new EmergencyAssistanceFacade();

                CasePhoneLocation phoneLocation = emergencyFacade.WSGetPhoneLocation(DMSCallContext.InboundCallID);

                if (phoneLocation != null)
                {
                    logger.InfoFormat("MapController - Index() - Details retrieved from Web Service Call with Latitude {0} Longitude {1}", phoneLocation.CivicLatitude.ToString(), phoneLocation.CivicLongitude.ToString());
                    latitude = phoneLocation.CivicLatitude.ToString();
                    longitude = phoneLocation.CivicLongitude.ToString();
                    locationAddress = phoneLocation.CivicStreet;
                    if (!string.IsNullOrEmpty(phoneLocation.CivicCity))
                    {
                        locationAddress = locationAddress + "," + phoneLocation.CivicCity;
                    }
                    if (!string.IsNullOrEmpty(phoneLocation.CivicState))
                    {
                        locationAddress = locationAddress + "," + phoneLocation.CivicState;
                    }
                    if (!string.IsNullOrEmpty(phoneLocation.CivicCounty))
                    {
                        locationAddress = locationAddress + "," + phoneLocation.CivicCounty;
                    }
                    if (!string.IsNullOrEmpty(phoneLocation.CivicZip))
                    {
                        locationAddress = locationAddress + " " + phoneLocation.CivicZip;
                    }
                }
                else
                {
                    logger.InfoFormat("MapController - Index() - No Case phone location record found for callback number {0}", DMSCallContext.CallbackNumber);
                }
                ViewData["ServiceLocationLatitude"] = latitude;
                ViewData["ServiceLocationLongitude"] = longitude;
                ViewData["ServiceLocationAddress"] = locationAddress;
            }

            ViewData["DestinationLatitude"] = serviceRequest.DestinationLatitude.GetValueOrDefault();
            ViewData["DestinationLongitude"] = serviceRequest.DestinationLongitude.GetValueOrDefault();
            ViewData["DestinationAddress"] = serviceRequest.DestinationAddress;
            ViewData["DestinationDescription"] = serviceRequest.DestinationDescription;

            /* NP Jan 8th 2014*/
            int memberID = DMSCallContext.MemberID;
            int membershipID = DMSCallContext.MembershipID;

            MemberFacade facade = new MemberFacade();
            MemberSearchDetails model = new MemberSearchDetails();
            model.MemberInformation = facade.GetMemberInformation(memberID);

            var memberDetail = model.MemberInformation.Where(x => x.MemberID == memberID).FirstOrDefault();



            if (memberDetail != null)
            {
                DMSCallContext.MemberProgramID = memberDetail.ProgramID.Value;

            }
            ViewData["MemberID"] = memberID;
            ViewData["MembershipID"] = membershipID;
            ViewData["MemberEmail"] = string.Empty;
            ViewData["IsHagerty"] = "False";
            string client = DMSCallContext.ClientName;
            if (client == "Hagerty")
            {
                ViewData["IsHagerty"] = "True";
            }

            //Lakshmi - Email on Map tab: Begin

            bool showsurveyemail = IsShowSurveyEmail();             //Lakshmi - Code added for Program Specific survey email 
            ViewBag.ShowSurveyEmail = showsurveyemail;              //Lakshmi - Code added for Program Specific survey email 

            CaseFacade casefacade = new CaseFacade();
            Case casemodel = casefacade.GetCaseById(DMSCallContext.CaseID);

            if (casemodel != null)
            {
                if (casemodel.ReasonID != null & casemodel.ReasonID.HasValue)
                {
                    ContactEmailDeclineReason declinedReason = casefacade.GetDeclinedReasonById(casemodel.ReasonID.Value);
                    ViewData["DeclinedReason"] = declinedReason.ID.ToString();
                }
                else
                {
                    ViewData["DeclinedReason"] = string.Empty;
                }
                logger.InfoFormat("MapController - Index() - DeclinedReason {0}", ViewData["DeclinedReason"]);
                ViewData["MemberEmail"] = casemodel.ContactEmail;
                logger.InfoFormat("MapController - Index() - MemberEmail {0}", ViewData["MemberEmail"]);
            }

            ViewData[Martex.DMS.ActionFilters.StaticData.DeclinedReasons.ToString()] = ReferenceDataRepository.GetDeclineReasons().ToSelectListItem<ContactEmailDeclineReason>(x => x.ID.ToString(), y => y.Description.Trim(), true);

            //End

            //TFS:163
            SetTabValidationStatus(RequestArea.MAP);

            //TFS:537
            var progRepository = new ProgramMaintenanceRepository();
            var programConfigs = progRepository.GetProgramInfo(DMSCallContext.ProgramID, "Application", "Rule");
            bool CanWeTextYou = programConfigs.Where(p => p.Name.Equals("ShowCanWeTextYou", StringComparison.InvariantCultureIgnoreCase) && p.Value.Equals("Yes", StringComparison.InvariantCultureIgnoreCase)).Count() > 0;
            ViewData["ShowCanWeTextYou"] = CanWeTextYou;
            Member member = new MemberRepository().Get(DMSCallContext.MemberID);
            ViewData["ShowUseSellerDealerLocation"] = member != null && member.SellerVendorID != null ? true : false;
            logger.InfoFormat("MapController - Index() - ShowCanWeTextYou {0}", ViewData["ShowCanWeTextYou"]);
            logger.InfoFormat("MapController - Index() - Returning _Index() view.");
            return PartialView("_Index");
        }

        /// <summary>
        /// Gets the business information.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult GetBusinessInformation()
        {
            logger.InfoFormat("MapController - GetBusinessInformation()");
            return PartialView("_BusinessInformationPOPUp");
        }

        /// <summary>
        /// Gets the call history.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult GetCallHistory()
        {
            logger.InfoFormat("MapController - GetCallHistory()");
            logger.InfoFormat("Trying to retrieve Call Histroy for Service Request ID {0}", DMSCallContext.ServiceRequestID);
            MapFacade facade = new MapFacade();
            return PartialView("_CallHistory", facade.GetCallHistory(DMSCallContext.ServiceRequestID));
        }

        /// <summary>
        /// _s the get options view.
        /// </summary>
        /// <param name="optionsFor">The options for.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetOptionsView(string optionsFor)
        {
            logger.InfoFormat("MapController - _GetOptionsView(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                optionsFor = optionsFor
            }));
            logger.Info("MapController _GetOptionsView Started");
            if (optionsFor.Equals("business", StringComparison.InvariantCultureIgnoreCase))
            {
                var facade = new MapOptionsFacade();
                logger.InfoFormat("MapController GetBusinessOptions for VehicleTypeID {0}", DMSCallContext.VehicleTypeID.GetValueOrDefault());
                List<string> businessOptions = facade.GetBusinessOptions(DMSCallContext.VehicleTypeID.GetValueOrDefault());
                return PartialView("_BusinessOptions", businessOptions);
            }
            else if (optionsFor.Equals("dealers", StringComparison.InvariantCultureIgnoreCase))
            {
                PopulateDealerOptions();
                return PartialView("_DealerOptions");
            }
            else if (optionsFor.Equals("services", StringComparison.InvariantCultureIgnoreCase))
            {
                List<TreeViewItemModel> treeModel = _GetServiceOptionsData();
                ViewData["ServiceOptions"] = treeModel;
                return PartialView("_ServiceOptions");
            }
            logger.Info("MapController _GetOptionsView Completed");
            return null;
        }

        /// <summary>
        /// _s the get business options.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetBusinessOptions()
        {
            logger.InfoFormat("MapController - _GetBusinessOptions()");
            var facade = new MapOptionsFacade();
            List<string> businessOptions = facade.GetBusinessOptions(DMSCallContext.VehicleTypeID.GetValueOrDefault());
            List<TreeViewItem> treeNodes = new List<TreeViewItem>();
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            businessOptions.ForEach(a =>
            {
                TreeViewItem item = new TreeViewItem()
                {
                    Text = a
                };
                treeNodes.Add(item);
            });
            result.Data = treeNodes;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Populates the dealer options.
        /// </summary>
        [NoCache]
        public void PopulateDealerOptions()
        {
            logger.InfoFormat("MapController - PopulateDealerOptions()");
            VehicleTypes vehicleType = VehicleTypes.Auto;
            IEnumerable<SelectListItem> listOfVehicleMakes = new List<SelectListItem>();

            if (!string.IsNullOrEmpty(DMSCallContext.LastUpdatedVehicleType))
            {
                Enum.TryParse(DMSCallContext.LastUpdatedVehicleType, out vehicleType);
                listOfVehicleMakes = ReferenceDataRepository.GetVehicleMake((int)vehicleType, false).ToSelectListItem(x => x.Make, y => y.Make);
                //switch (vehicleType)
                //{
                //    case VehicleTypes.Auto:
                //        double vehicleYear = 0;
                //        double.TryParse(DMSCallContext.VehicleYear, out vehicleYear);
                //        listOfVehicleMakes = ReferenceDataRepository.GetVehicleMake(vehicleYear, false).ToSelectListItem(x => x.Make, y => y.Make);
                //        break;
                //    case VehicleTypes.Motorcycle:
                //        listOfVehicleMakes = ReferenceDataRepository.GetMotorCycleMake(false).ToSelectListItem(x => x.Make, y => y.Make);
                //        break;
                //    case VehicleTypes.RV:
                //        listOfVehicleMakes = ReferenceDataRepository.GetRVMake(false).ToSelectListItem(x => x.Make, y => y.Make);
                //        break;
                //    case VehicleTypes.Trailer:
                //        listOfVehicleMakes = ReferenceDataRepository.GetTrailerMake(false).ToSelectListItem(x => x.Make, y => y.Make);
                //        break;
                //}
            }

            GenericIEqualityComparer<SelectListItem> makeDistinct = new GenericIEqualityComparer<SelectListItem>(
                        (x, y) =>
                        {
                            return x.Value.Equals(y.Value);
                        },
                        (a) =>
                        {
                            return a.Value.GetHashCode();
                        }
                        );
            ViewData["SelectedVehicleMake"] = DMSCallContext.VehicleMake ?? string.Empty;
            ViewData[StaticData.VehicleMake.ToString()] = listOfVehicleMakes.Distinct(makeDistinct);

        }


        /// <summary>
        /// Logs the event.
        /// </summary>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="description">The description.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult LogEvent(string eventName, string description)
        {
            logger.InfoFormat("MapController - LogEvent(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                eventName = eventName,
                description = description
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            EventLoggerFacade facade = new EventLoggerFacade();
            string loggedInUser = LoggedInUserName;
            facade.LogEvent(Request.RawUrl, eventName, description, loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, HttpContext.Session.SessionID);

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the member home address.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMemberHomeAddress()
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            //TODO: Need to get home address of the member.

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Saves the details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveDetails(ServiceRequest model, string email = null, string DeclinedReason = null, bool? IsSMSAvailable = null)
        {
            logger.InfoFormat("MapController - SaveDetails() - Started, Parameters : {0}", JsonConvert.SerializeObject(new
            {
                email = email,
                DeclinedReason = DeclinedReason,
                ServiceRequestID = DMSCallContext.ServiceRequestID,
                IsSMSAvailable = IsSMSAvailable,
                ServiceRequest = model

            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            model.ID = DMSCallContext.ServiceRequestID;
            var loggedInUser = LoggedInUserName;
            model.ModifyBy = loggedInUser;
            model.ModifyDate = DateTime.Now;
            model.ServiceMiles = model.ServiceMiles ?? 0;
            if (model.ServiceMiles > 0 && model.ServiceMiles < 1)
            {
                model.ServiceMiles = 1;
            }
            else
            {
                model.ServiceMiles = Math.Round(model.ServiceMiles.Value);
            }

            // Apply some rounding on the latitude and longitude as the db column is just (10,7)
            model.ServiceLocationLatitude = RoundTo7Decimals(model.ServiceLocationLatitude);
            model.ServiceLocationLongitude = RoundTo7Decimals(model.ServiceLocationLongitude);
            model.DestinationLatitude = RoundTo7Decimals(model.DestinationLatitude);
            model.DestinationLongitude = RoundTo7Decimals(model.DestinationLongitude);
            int memberID = DMSCallContext.MemberID;

            var facade = new MapFacade();
            CaseFacade casefacade = new CaseFacade();
            logger.Info("MapController - SaveDetails() - UpdateServiceRequest");
            facade.UpdateServiceRequest(Request.RawUrl, loggedInUser, model, HttpContext.Session.SessionID);

            //Lakshmi - Email on Map Tab
            int? declinereasonid = null;
            if (!string.IsNullOrEmpty(DeclinedReason))
            {
                declinereasonid = Convert.ToInt32(DeclinedReason);
            }
            if (!string.IsNullOrEmpty(email))
            {
                logger.InfoFormat("MapController - SaveDetails() - UpdateMemberEmailInfo for Case ID {0} Email {1}", DMSCallContext.CaseID, email);
                facade.UpdateMemberEmailInfo(email, null, DMSCallContext.CaseID, loggedInUser);
                ViewData["DeclinedReason"] = string.Empty;
            }
            else
            {
                if (!string.IsNullOrWhiteSpace(email) || declinereasonid.HasValue)
                {
                    logger.InfoFormat("MapController - SaveDetails() - UpdateMemberEmailInfo for Case ID {0} Email {1}", DMSCallContext.CaseID, email);
                    facade.UpdateMemberEmailInfo(email, declinereasonid, DMSCallContext.CaseID, loggedInUser);
                }
                if (declinereasonid.HasValue)
                {
                    ContactEmailDeclineReason declinedReason = casefacade.GetDeclinedReasonById(declinereasonid.Value);
                    ViewData["DeclinedReason"] = declinedReason.ID.ToString();
                }
            }
            facade.SetSMSAvailable(DMSCallContext.CaseID, IsSMSAvailable);
            DMSCallContext.IsSMSAvailable = IsSMSAvailable.GetValueOrDefault();
            ViewData["MemberEmail"] = email;
            //End
            DMSCallContext.ServiceMiles = model.ServiceMiles;
            DMSCallContext.ServiceTimeInMinutes = model.ServiceTimeInMinutes;

            // Reset the ISP list if only there is a change in the location/destination values.
            if (
                DMSCallContext.ServiceLocationLatitude != model.ServiceLocationLatitude ||
                DMSCallContext.ServiceLocationLongitude != model.ServiceLocationLongitude ||
                DMSCallContext.DestinationLatitude != model.DestinationLatitude ||
                DMSCallContext.DestinationLongitude != model.DestinationLongitude

                )
            {

                DMSCallContext.ServiceLocationLatitude = model.ServiceLocationLatitude;
                DMSCallContext.ServiceLocationLongitude = model.ServiceLocationLongitude;
                DMSCallContext.DestinationLatitude = model.DestinationLatitude;
                DMSCallContext.DestinationLongitude = model.DestinationLongitude;

                logger.Info("Resetting ISPs list");
                // Clear the cached ISPs so that it gets recalculated in Dispatch tab
                DMSCallContext.ISPs = null;
                DMSCallContext.IsCallMadeToVendor = DMSCallContext.RejectVendorOnDispatch = false;

                RecalculateEstimate();                

            }



            logger.Info("MapController - SaveDetails() - Completed");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the service facility selection.
        /// </summary>
        /// <param name="serviceLocationLatitude">The service location latitude.</param>
        /// <param name="serviceLocationLongitude">The service location longitude.</param>
        /// <param name="productList">The product list.</param>
        /// <param name="radiusMiles">The radius miles.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _ServiceFacilitySelection(decimal serviceLocationLatitude, decimal serviceLocationLongitude, string productList, int radiusMiles)
        {
            logger.Info("MapController _ServiceFacilitySelection Started");

            string searchRadiusMiles = AppConfigRepository.GetValue(AppConfigConstants.SERVICE_LOCATION_SEARCH_RADIUS_MILES);
            int iSearchRadiusMiles = 50;
            int.TryParse(searchRadiusMiles, out iSearchRadiusMiles);

            logger.InfoFormat("MapController _ServiceFacilitySelection Retrieving Service Facilities for Program ID {0} Latitude {1} Longitude {2} Product List {3} iSearchRadiusMiles {4}", DMSCallContext.ProgramID, serviceLocationLatitude, serviceLocationLongitude, productList, iSearchRadiusMiles);
            List<GetServiceFacilitySelection_Result> lstServicesFacilitySelections = new MapRepository().GetServiceFacilities(DMSCallContext.ProgramID, serviceLocationLatitude, serviceLocationLongitude, productList, iSearchRadiusMiles);

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            List<string> lstServicesLocations = new List<string>();

            result.Data = lstServicesFacilitySelections;

            logger.Info("MapController _ServiceFacilitySelection Completed");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the call log.
        /// </summary>
        /// <returns></returns>
        public ActionResult _CallLog()
        {
            logger.Info("MapController _CallLog Started");
            const string category = "ServiceLocationSelection";

            logger.InfoFormat("MapController _CallLog Retrieving Contact Action by Category {0}", category);
            var actions = ReferenceDataRepository.GetContactAction(category);
            // CR : 1262 - Using Description instead of Name.
            ViewData[StaticData.ContactActions.ToString()] = actions.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);

            logger.InfoFormat("MapController _CallLog Retrieving Contact Reason by Category {0}", category);
            var reasons = ReferenceDataRepository.GetContactReasons(category);
            ViewData[StaticData.ContactReasons.ToString()] = reasons.ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);

            logger.Info("MapController _CallLog Completed");
            return PartialView("_CallLog");
        }

        /// <summary>
        /// _s the call log.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [ValidateInput(true)]
        [HttpPost]
        public ActionResult _CallLog(CallLog model)
        {
            logger.Info("MapController _CallLog Post Started");
            logger.InfoFormat("MapController _CallLog for Service Request ID {0}", DMSCallContext.ServiceRequestID);
            CallLogFacade.LogCall(model, DMSCallContext.ServiceRequestID, LoggedInUserName);
            IncrementCallCounts(AgentTimeCounts.SERVICE_FACILITY);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            logger.Info("MapController _CallLog Post Completed");
            return Json(result);
        }


        //public JsonResult _GetDeclinedReasons()
        //{
        //    MapFacade mapFacade = new MapFacade();

        //    List<ContactEmailDeclineReason> declinedResaons = mapFacade.GetDeclinedReasons();

        //    return Json(new SelectList(declinedResaons,"ID","Reason"), JsonRequestBehavior.AllowGet);
        //}

        #endregion

        #region Private Methods
        /// <summary>
        /// Rounds the to7 decimals.
        /// </summary>
        /// <param name="val">The val.</param>
        /// <returns></returns>
        private decimal? RoundTo7Decimals(decimal? val)
        {
            if (val != null)
            {
                return Math.Round(val.Value, 7);
            }
            return null;
        }

        /// <summary>
        /// Populates the children.
        /// </summary>
        /// <param name="node">The node.</param>
        /// <param name="options">The options.</param>
        private void PopulateChildren(TreeViewItemModel node, List<ServiceLocationOption> options)
        {
            var childNodes = options.Where(a => a.ProductSubTypeName == node.Text).ToList<ServiceLocationOption>();
            if (childNodes.Count > 0)
            {
                foreach (var item in childNodes)
                {
                    TreeViewItemModel childNode = new TreeViewItemModel();
                    childNode.Text = item.ProductName;
                    node.Items.Add(childNode);
                }
            }

        }

        /// <summary>
        /// Get value to show survey email in Map.
        /// </summary>
        private bool IsShowSurveyEmail()
        {
            MapFacade mapfacade = new MapFacade();
            return mapfacade.IsShowSurveyEmailAllowed(DMSCallContext.MemberProgramID, "Application", "Rule", "ShowSurveyEmail");
        }
        #endregion

        #region Protected Methods

        /// <summary>
        /// _s the get service options data.
        /// </summary>
        /// <returns></returns>
        protected List<TreeViewItemModel> _GetServiceOptionsData()
        {
            var facade = new MapOptionsFacade();
            List<ServiceLocationOption> serviceOptions = facade.GetServiceLocationOptions();
            List<TreeViewItemModel> treeNodes = new List<TreeViewItemModel>();
            // Get all the nodes where parent node is null (or value is null).            
            var rootNodes = serviceOptions.GroupBy(a => a.ProductSubTypeName).Select(grp => grp.FirstOrDefault()).ToList<ServiceLocationOption>();

            foreach (var item in rootNodes)
            {
                TreeViewItemModel node = new TreeViewItemModel();
                node.Text = item.ProductSubTypeName;
                treeNodes.Add(node);

                PopulateChildren(node, serviceOptions);
            }

            return treeNodes;
        }
        #endregion
    }
}
