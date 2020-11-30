using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Models;
using Martex.DMS.BLL.Facade;
using ClientPortal.Areas.Common.Controllers;
using ClientPortal.Areas.Application.Models;
using Martex.DMS.DAL.Common;
using Kendo.Mvc.UI;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using ClientPortal.Common;
using ClientPortal.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Common;

namespace ClientPortal.Areas.Application.Controllers
{
    public class MapController : BaseController
    {
        #region Private Members
        EventLoggerFacade eventLogFacade = new EventLoggerFacade();
        #endregion

        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_MAP)]
        public ActionResult Index()
        {
            var loggedInUser = LoggedInUserName;
            eventLogFacade.LogEvent(Request.RawUrl, EventNames.ENTER_MAP_TAB, "Enter Map Tab", loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, HttpContext.Session.SessionID);

            var serviceRequestRepository = new ServiceRequestRepository();
            logger.InfoFormat("Trying to retrieve details from Service Request with ID {0}", DMSCallContext.ServiceRequestID);
            ServiceRequest serviceRequest = serviceRequestRepository.GetById(DMSCallContext.ServiceRequestID);
            ViewData["ServiceLocationLatitude"] = serviceRequest.ServiceLocationLatitude.GetValueOrDefault();
            ViewData["ServiceLocationLongitude"] = serviceRequest.ServiceLocationLongitude.GetValueOrDefault();
            ViewData["ServiceLocationAddress"] = serviceRequest.ServiceLocationAddress;
            ViewData["ServiceLocationDescription"] = serviceRequest.ServiceLocationDescription;

            logger.InfoFormat("Details retrieved from Service Request with Latitude {0} Longitude {1}", serviceRequest.ServiceLocationLatitude.GetValueOrDefault(), serviceRequest.ServiceLocationLongitude.GetValueOrDefault());

            if (serviceRequest.ServiceLocationLatitude == null && serviceRequest.ServiceLocationLongitude == null)
            {
                string latitude = string.Empty;
                string longitude = string.Empty;
                string locationAddress = string.Empty;

                logger.InfoFormat("Location details are not available against SR so trying to see if there is data in CasePhoneLocation for inbound call ID {0}", DMSCallContext.InboundCallID);

                var emergencyFacade = new EmergencyAssistanceFacade();

                CasePhoneLocation phoneLocation = emergencyFacade.WSGetPhoneLocation(DMSCallContext.InboundCallID);

                if (phoneLocation != null)
                {
                    logger.InfoFormat("Details retrieved from Web Service Call with Latitude {0} Longitude {1}", phoneLocation.CivicLatitude.ToString(), phoneLocation.CivicLongitude.ToString());
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
                    logger.InfoFormat("No Case phone location record found for callbacknumber {0}", DMSCallContext.CallbackNumber);
                }
                ViewData["ServiceLocationLatitude"] = latitude;
                ViewData["ServiceLocationLongitude"] = longitude;
                ViewData["ServiceLocationAddress"] = locationAddress;
            }

            ViewData["DestinationLatitude"] = serviceRequest.DestinationLatitude.GetValueOrDefault();
            ViewData["DestinationLongitude"] = serviceRequest.DestinationLongitude.GetValueOrDefault();
            ViewData["DestinationAddress"] = serviceRequest.DestinationAddress;
            ViewData["DestinationDescription"] = serviceRequest.DestinationDescription;

            return PartialView("_Index");
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult GetBusinessInformation()
        {
            return PartialView("_BusinessInformationPOPUp");
        }

        [NoCache]
        [DMSAuthorize]
        public ActionResult GetCallHistory()
        {
            logger.InfoFormat("Trying to retrieve Call Histroy for Service Request ID {0}", DMSCallContext.ServiceRequestID);
            MapFacade facade = new MapFacade();
            return PartialView("_CallHistory", facade.GetCallHistory(DMSCallContext.ServiceRequestID));
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="optionsFor"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetOptionsView(string optionsFor)
        {

            if (optionsFor.Equals("business", StringComparison.InvariantCultureIgnoreCase))
            {
                var facade = new MapOptionsFacade();
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
            return null;
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetBusinessOptions()
        {

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
        /// 
        /// </summary>
        [NoCache]
        public void PopulateDealerOptions()
        {
            VehicleTypes vehicleType = VehicleTypes.Auto;
            IEnumerable<SelectListItem> listOfVehicleMakes = new List<SelectListItem>();

            if (!string.IsNullOrEmpty(DMSCallContext.LastUpdatedVehicleType))
            {
                Enum.TryParse(DMSCallContext.LastUpdatedVehicleType, out vehicleType);
                switch (vehicleType)
                {
                    case VehicleTypes.Auto:
                        double vehicleYear = 0;
                        double.TryParse(DMSCallContext.VehicleYear, out vehicleYear);
                        listOfVehicleMakes = ReferenceDataRepository.GetVehicleMake(vehicleYear, false).ToSelectListItem(x => x.Make, y => y.Make);
                        break;
                    case VehicleTypes.Motorcycle:
                        listOfVehicleMakes = ReferenceDataRepository.GetMotorCycleMake(false).ToSelectListItem(x => x.Make, y => y.Make);
                        break;
                    case VehicleTypes.RV:
                        listOfVehicleMakes = ReferenceDataRepository.GetRVMake(false).ToSelectListItem(x => x.Make, y => y.Make);
                        break;
                    case VehicleTypes.Trailer:
                        listOfVehicleMakes = ReferenceDataRepository.GetTrailerMake(false).ToSelectListItem(x => x.Make, y => y.Make);
                        break;
                }
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
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        
        //[ValidateInput(false)]
        //[NoCache]
        //public ActionResult _GetServiceOptions()
        //{

        //    var facade = new MapOptionsFacade();
        //    List<ServiceLocationOption> serviceOptions = facade.GetServiceLocationOptions();
        //    List<TreeViewItem> treeNodes = new List<TreeViewItem>();
        //    // Get all the nodes where parent node is null (or value is null).
        //    OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
        //    var rootNodes = serviceOptions.GroupBy(a => a.ProductSubTypeName).Select(grp => grp.FirstOrDefault()).ToList<ServiceLocationOption>();

        //    foreach (var item in rootNodes)
        //    {
        //        TreeViewItem node = new TreeViewItem();
        //        node.Text = item.ProductSubTypeName;
        //        treeNodes.Add(node);

        //        PopulateChildren(node, serviceOptions);
        //    }
        //    result.Data = treeNodes;
            
        //    return Json(result, JsonRequestBehavior.AllowGet);
        //}
        /// <summary>
        /// 
        /// </summary>
        /// <param name="eventName"></param>
        /// <param name="description"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult LogEvent(string eventName, string description)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            EventLoggerFacade facade = new EventLoggerFacade();
            string loggedInUser = LoggedInUserName;
            facade.LogEvent(Request.RawUrl, eventName, description, loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, HttpContext.Session.SessionID);

            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
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

        private decimal? RoundTo7Decimals(decimal? val)
        {
            if (val != null)
            {
                return Math.Round(val.Value, 7);
            }
            return null;
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveDetails(ServiceRequest model)
        {
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

            var facade = new MapFacade();
            facade.UpdateServiceRequest(Request.RawUrl, loggedInUser, model, HttpContext.Session.SessionID);
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

            }

            DMSCallContext.ServiceMiles = model.ServiceMiles;
            DMSCallContext.ServiceTimeInMinutes = model.ServiceTimeInMinutes;

            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="serviceLocationLatitude"></param>
        /// <param name="serviceLocationLongitude"></param>
        /// <param name="productList"></param>
        /// <param name="radiusMiles"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _ServiceFacilitySelection(decimal serviceLocationLatitude, decimal serviceLocationLongitude, string productList, int radiusMiles)
        {
            // 32.780122m, -96.801412m, "Jump Start - HD", 50
            // Ignore the parameter and use the one from AppConfig.
            
            string searchRadiusMiles = AppConfigRepository.GetValue(AppConfigConstants.SERVICE_LOCATION_SEARCH_RADIUS_MILES);
            int iSearchRadiusMiles = 50;
            int.TryParse(searchRadiusMiles, out iSearchRadiusMiles);

            List<GetServiceFacilitySelection_Result> lstServicesFacilitySelections = new MapRepository().GetServiceFacilities(serviceLocationLatitude, serviceLocationLongitude, productList, iSearchRadiusMiles);

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            List<string> lstServicesLocations = new List<string>();

            result.Data = lstServicesFacilitySelections;
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        public ActionResult _CallLog()
        {
            const string category = "ServiceLocationSelection";
            var actions = ReferenceDataRepository.GetContactAction(category);
            // CR : 1262 - Using Description instead of Name.
            ViewData[StaticData.ContactActions.ToString()] = actions.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            var reasons = ReferenceDataRepository.GetContactReasons(category);
            ViewData[StaticData.ContactReasons.ToString()] = reasons.ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return PartialView("_CallLog");
        }

        [ValidateInput(false)]
        [HttpPost]
        public ActionResult _CallLog(CallLog model)
        {
            logger.InfoFormat("Logging call : {0}", model.ToString());
            CallLogFacade.LogCall(model, DMSCallContext.ServiceRequestID, LoggedInUserName);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        #endregion

        #region Private Members
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
        #endregion
    }
}
