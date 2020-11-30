using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using ClientPortal.Areas.Common.Controllers;
using ClientPortal.Areas.Application.Models;
using System.Text;
using ClientPortal.Common;
using Martex.DMS.DAO;
using ClientPortal.ActionFilters;
using Martex.DMS.BLL.Model;
using ClientPortal.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using System.Web.Script.Serialization;
using log4net;
using Martex.DMS.Areas.Application.Models;

namespace ClientPortal.Areas.Application.Controllers
{
    public class DispatchController : BaseController
    {

        #region Instance variables

        protected DispatchFacade dispatchFacade = new DispatchFacade();
        #endregion

        #region Private Methods

        private List<ISPs_Result> GetVendorListForContext()
        {
            // If the user is a super user.
            //      Present the first not called item
            //      Populate the list on the left hand side with a list of all vendors.
            // If the user is not a super user
            //      Filter out items with callstatus <> 'NotCalled' and populate the list on the left hand-side.
            //      If the above list is emtpy
            //          Present the first not called item
            //      Else
            //          Present the first item in the filtered list.
            List<ISPs_Result> vendorList = null;


            if (DMSCallContext.IsDispatchThresholdReached || DMSCallContext.IsAllowedToSeeISPNotCalled)
            {
                vendorList = DMSCallContext.ISPs;
                if (DMSCallContext.VendorIndexInList == -1)
                {
                    DMSCallContext.VendorIndexInList = 0;
                }

            }
            else if (!DMSCallContext.IsDispatchThresholdReached || !DMSCallContext.IsAllowedToSeeISPNotCalled)
            {
                vendorList = DMSCallContext.ISPs.Where(a => a.CallStatus != "NotCalled").ToList<ISPs_Result>();

                // Update the number of calls made so far.                
                var rejectedVendors = DMSCallContext.RejectedVendors;
                bool vendorAlreadyRejected = false;
                vendorList.ForEach(model =>
                {
                    rejectedVendors.ForEach(x =>
                    {
                        if (x.VendorID == model.VendorID && x.VendorLocationID == model.VendorLocationID)
                        {
                            vendorAlreadyRejected = true;
                        }

                    });
                    if (!vendorAlreadyRejected)
                    {
                        DMSCallContext.CallsMadeSoFar = DMSCallContext.CallsMadeSoFar + 1;
                        DMSCallContext.RejectedVendors.Add(model);
                    }
                    vendorAlreadyRejected = false;
                });

                logger.InfoFormat("Calls made so far :: {0}", DMSCallContext.CallsMadeSoFar);

                if (vendorList.Count == 0)
                {
                    // Get the index of the first not called entry.
                    logger.InfoFormat("There are no called vendors in the list, so getting the next not called vendor");
                    DMSCallContext.VendorIndexInList = GetIndexOfNotCalledISP(0);
                    // If the first item happens to violate threshold, then promote to super user
                    if (DMSCallContext.VendorIndexInList == -1)
                    {
                        logger.InfoFormat("First vendor happened to violate threshold so returning full list after promoting to super user mode");
                        DMSCallContext.IsDispatchThresholdReached = true;
                        vendorList = DMSCallContext.ISPs;
                        DMSCallContext.VendorIndexInList = 0;
                    }

                }
                else
                {
                    // Get the index of the first item {vendorid and vendor location id} from the ISPs list.
                    if (DMSCallContext.VendorIndexInList == -1)
                    {
                        ISPs_Result isp = vendorList[0]; // Get the first called vendor.
                        DMSCallContext.VendorIndexInList = GetIndexOfISP(isp.VendorID, isp.VendorLocationID);

                    }
                }
            }

            // If we are coming from PO without going to dispatch, then calculate the index of the vendor being rejected.
            if (DMSCallContext.RejectVendorOnDispatch)
            {
                var vendorLocationID = DMSCallContext.VendorLocationID;
                // Iterate over the full list.                
                logger.InfoFormat("Came to Dispatch via PO -> Reject, Vendorlocation ID = {0}", vendorLocationID);
                int idx = 0;
                for (int i = 0, l = DMSCallContext.ISPs.Count; i < l; i++)
                {
                    if (DMSCallContext.ISPs[i].VendorLocationID == vendorLocationID)
                    {
                        idx = i;
                        break;
                    }
                }
                DMSCallContext.VendorIndexInList = idx;
            }

            logger.InfoFormat("Number of vendors found - {0} and VendorIndexInList = {1} ", vendorList.Count, DMSCallContext.VendorIndexInList);
            return vendorList;
        }

        private int GetIndexOfISP(int vendorID, int vendorLocationID)
        {
            int i = 0;
            var list = DMSCallContext.ISPs;
            for (int l = list.Count; i < l; i++)
            {
                var x = list[i];
                if (x.VendorID == vendorID && x.VendorLocationID == vendorLocationID)
                {
                    break;
                }
            }
            //NP: Placed the logger before returning the value
            logger.InfoFormat("Index of selected ISP = {0} ", i);

            return i;

            
        }

        private int GetIndexOfNotCalledISP(int startingFrom)
        {
            int index = -1;
            int i = startingFrom;
            var list = DMSCallContext.ISPs;
            int len = list.Count;

            if (i >= (len - 1))
            {
                return -1;
            }
            for (; i < len; i++)
            {
                var x = list[i];
                if (x.CallStatus == "NotCalled")
                {
                    if ((DMSCallContext.IsAllowedToSeeISPNotCalled || DMSCallContext.IsDispatchThresholdReached) || !HasExceededMilesThreshold(x.EnrouteMiles.GetValueOrDefault()))
                    {
                        index = i;
                    }
                    break;
                }
            }

            return index;
        }

        private int GetIndexOfNotNotCalledISP(int startingFrom)
        {
            int index = -1;
            int i = startingFrom;
            var list = DMSCallContext.ISPs;
            int len = list.Count;

            if (i >= (len - 1))
            {
                return -1;
            }
            for (; i < len; i++)
            {
                var x = list[i];
                if (x.CallStatus != "NotCalled")
                {
                    index = i;
                    break;
                }
            }

            return index;
        }

        private void CalculatePermissions()
        {
            var appConfigValue = AppConfigRepository.GetValue(AppConfigConstants.ROLES_THAT_SHOW_ISP_NOTCALLED);

            if (!string.IsNullOrEmpty(appConfigValue))
            {
                string[] tokens = appConfigValue.Split(',');
                var up = GetProfile();
                bool roleMatchFound = false;
                foreach (var role in up.UserRoles)
                {
                    if (tokens.Contains(role))
                    {
                        roleMatchFound = true;
                        break;
                    }
                }
                ViewData[StringConstants.SHOW_OPTIONS] = roleMatchFound;
                DMSCallContext.IsAllowedToSeeISPNotCalled = roleMatchFound;
                // CR : 1198 - Allow to see all ISPs if the program configuration - FullDispatchEnabled is turned on for the current program.
                ProgramMaintenanceFacade progFacade = new ProgramMaintenanceFacade();

                List<ProgramInformation_Result> info = progFacade.GetProgramInfo(DMSCallContext.ProgramID, "service", "rule");

                var config = info.Where(x => x.Name == StringConstants.FULL_DISPATCH_ENABLED).FirstOrDefault();
                if (config != null)
                {
                    if ("yes".Equals(config.Value, StringComparison.InvariantCultureIgnoreCase))
                    {
                        logger.InfoFormat("Enabling full dispatch for the program {0}", DMSCallContext.ProgramID);
                        DMSCallContext.IsAllowedToSeeISPNotCalled = true;
                    }
                }
                logger.InfoFormat("Is allowed to see ISPs not called {0} and IsDispatchThreshold reached {1}", roleMatchFound, DMSCallContext.IsDispatchThresholdReached);
            }
        }

        private bool HasExceededCallsThreshold()
        {
            string thresholdConfig = AppConfigRepository.GetValue(AppConfigConstants.THRESHOLD_NUMBER_OF_CALLS);
            logger.InfoFormat("AppConfig.{0} = {1}", AppConfigConstants.THRESHOLD_NUMBER_OF_CALLS, thresholdConfig);
            logger.InfoFormat("Calls made so far = {0}", DMSCallContext.CallsMadeSoFar);
            int callThreshold = 0;
            int.TryParse(thresholdConfig, out callThreshold);

            return DMSCallContext.CallsMadeSoFar >= callThreshold;
        }

        private bool HasExceededMilesThreshold(double enrouteMiles)
        {
            string thresholdConfig = AppConfigRepository.GetValue(AppConfigConstants.THRESHOLD_ENROUTE_MILES);

            logger.InfoFormat("AppConfig.{0} = {1}", AppConfigConstants.THRESHOLD_ENROUTE_MILES, thresholdConfig);
            logger.InfoFormat("Miles to compare - {0}", enrouteMiles);

            double milesThreshold = 0;
            double.TryParse(thresholdConfig, out milesThreshold);

            return enrouteMiles >= milesThreshold;
        }
        #endregion

        #region Protected Members
        protected List<string> CheckRequiredAttributes()
        {
            List<string> missingFields = new List<string>();
            if (DMSCallContext.VehicleTypeID == null)
            {
                missingFields.Add("Vehicle (Vehicle tab)");
            }
            if (DMSCallContext.VehicleCategoryID == null)
            {
                missingFields.Add("Vehicle Category (Vehicle tab)");
            }
            if (DMSCallContext.ProductCategoryID == null)
            {
                missingFields.Add("Service Type (Service tab)");
            }

            if (DMSCallContext.ServiceLocationLatitude == null || DMSCallContext.ServiceLocationLongitude == null)
            {
                missingFields.Add("Location (Map tab)");
            }

            if (DMSCallContext.ProductCategoryName == "Tow" && (DMSCallContext.DestinationLatitude == null || DMSCallContext.DestinationLongitude == null))
            {
                missingFields.Add("Destination (Map tab)");
            }
            return missingFields;
        }

        #endregion

        #region Public Methods
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_DISPATCH)]
        public ActionResult Index()
        {
            var loggedInUser = LoggedInUserName;
            logger.Info("Creating event log and link records for enter dispatch tab");

            // 1. Eventlog for entering the tab.
            EventLoggerFacade eventLogfacade = new EventLoggerFacade();
            eventLogfacade.LogEvent(Request.RawUrl, EventNames.ENTER_DISPATCH_TAB, "Enter Dispatch Tab", loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);

            // 2. Determine if show options should be enabled.

            var errors = CheckRequiredAttributes();

            if (logger.IsInfoEnabled)
            {
                logger.InfoFormat("Missing Required attributes - {0}", errors.Count);
            }

            ViewData[StringConstants.REQUIRED_FIELDS_FOR_DISPATCH] = errors;
            ViewData[StringConstants.SHOW_OPTIONS] = false;
            ViewData[StringConstants.ENABLE_ADD_VENDOR] = false;
            //CR: 1115
            ViewData[StringConstants.PRODUCT_OPTIONS] = DispatchFacade.GetProductOptions(DMSCallContext.ProductCategoryID, DMSCallContext.VehicleTypeID, DMSCallContext.VehicleCategoryID);
            if (errors.Count == 0)
            {
                // 3. Enable or disable options [ previous, next, add vendor and show/hide options]
                logger.Info("Determine permissions");

                CalculatePermissions();

                ViewData[AppConfigConstants.SEARCH_RADIUS_MILES] = AppConfigRepository.GetValue(AppConfigConstants.SEARCH_RADIUS_MILES);

                // CR 1201 : Dispatch Tab - add warning message if service type is Tech, Info, Concierge
                var serviceType = DMSCallContext.ProductCategoryName;
                if ("Tech".Equals(serviceType, StringComparison.InvariantCultureIgnoreCase) ||
                    "Info".Equals(serviceType, StringComparison.InvariantCultureIgnoreCase) ||
                    "Concierge".Equals(serviceType, StringComparison.InvariantCultureIgnoreCase))
                {
                    ViewData["DispatchNA"] = true;
                }


                // 4. Load ISP List into session, if one doesn't exist.
                if (DMSCallContext.ISPs == null)
                {

                    DMSCallContext.ISPs = dispatchFacade.GetISPs(DMSCallContext.ServiceRequestID, DMSCallContext.ServiceMiles, DMSCallContext.VehicleTypeID.GetValueOrDefault(), DMSCallContext.VehicleCategoryID.GetValueOrDefault(), null, false, "Location", DMSCallContext.ServiceLocationLatitude, DMSCallContext.ServiceLocationLongitude, true, false, null);

                    DMSCallContext.OrginalISPs = DMSCallContext.ISPs.ToList<ISPs_Result>();
                    DMSCallContext.VendorIndexInList = -1; // It will be recalculated later.
                }
                /* Let's go with the index at which the agent was operating. */
                //else
                //{
                //    DMSCallContext.VendorIndexInList = 0;
                //}
                ViewData["VendorList"] = GetVendorListForContext();
                if (DMSCallContext.VendorIndexInList >= 0 && DMSCallContext.ISPs.Count > 0)
                {
                    var isp = DMSCallContext.ISPs[DMSCallContext.VendorIndexInList];
                    VendorFacade facade = new VendorFacade();
                    //ViewData["VendorCallHistory"] = facade.GetVendorCallHistory(DMSCallContext.ServiceRequestID, isp.VendorLocationID);
                    ViewData["VendorNotes"] = facade.GetVendorNotes(isp.VendorLocationID);
                }
            }
            ViewData[StringConstants.REJECT_VENDOR_ON_DISPATCH] = DMSCallContext.RejectVendorOnDispatch;
            VendorSearchFilters defaultFilters = new VendorSearchFilters()
            {
                From = "Location",
                Radius = 50,
                ShowCalled = true,
                ShowNotCalled = DMSCallContext.IsAllowedToSeeISPNotCalled,
                ShowDoNotUse = false

            };
            DMSCallContext.OldDispatchSearchFilters = defaultFilters;
            return PartialView("_Index", DMSCallContext.ISPs);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult RejectVendor()
        {
            var list = ReferenceDataRepository.GetContactAction("VendorSelection").Where(x => (x.Name.Trim() != "Accepted" && x.Name.Trim() != "Negotiate")).ToList<ContactAction>();
            ViewData[StaticData.ContactActions.ToString()] = list.ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);

            var contactActionsForTalkedTo = (from n in list
                                             select new NameValuePair()
                                             {
                                                 Name = n.ID.ToString(),
                                                 Value = n.IsTalkedToRequired != null ? n.IsTalkedToRequired.ToString().ToLower() : "false"
                                             }).ToList<NameValuePair>();

            JavaScriptSerializer ser = new JavaScriptSerializer();

            string json = ser.Serialize(contactActionsForTalkedTo);
            ViewData["ContactActionsForTalkedTo"] = json ;

            return PartialView("_RejectVendor");
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public ActionResult RejectVendor(RejectVendorModel model)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            logger.Info("Processing Reject");

            var loggedInUser = LoggedInUserName;
            DispatchFacade.Reject(model, loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST);

            var item = DMSCallContext.ISPs[DMSCallContext.VendorIndexInList] as ISPs_Result;

            // Update the item in the cached list.
            item.CallStatus = model.PossibleRetry.GetValueOrDefault() ? "Called" : "Rejected";
            item.RejectReason = Request.Form["ContactAction-input"];
            item.RejectComment = model.RejectComments;
            item.Comment = model.RejectComments;
            item.IsPossibleCallback = model.PossibleRetry;

            // Update this item in the original list too.
            DMSCallContext.UpdateItemInOriginalISPList(item);

            //Increment the number of calls made so far.
            var rejectedVendors = DMSCallContext.RejectedVendors;
            bool vendorAlreadyRejected = false;
            rejectedVendors.ForEach(x =>
                {
                    if (x.VendorID == model.VendorID && x.VendorLocationID == model.VendorLocationID)
                    {
                        vendorAlreadyRejected = true;
                    }

                });
            if (!vendorAlreadyRejected)
            {
                DMSCallContext.CallsMadeSoFar = DMSCallContext.CallsMadeSoFar + 1;
                DMSCallContext.RejectedVendors.Add(item);
            }
            logger.InfoFormat("Total calls made so far : {0} for SR - {1}", DMSCallContext.CallsMadeSoFar, DMSCallContext.ServiceRequestID);
            logger.Info("Execute Reject and clear PO");

            if (DMSCallContext.CurrentPurchaseOrder != null)
            {
                var po = DMSCallContext.CurrentPurchaseOrder;
                if (po.ID > 0 && po.PurchaseOrderStatu.Name.Equals("pending", StringComparison.InvariantCultureIgnoreCase))
                {
                    logger.InfoFormat("Disabling the current po as it is in {0} status ", po.PurchaseOrderStatu.Name);
                    POFacade facade = new POFacade();
                    facade.PODisable(DMSCallContext.CurrentPurchaseOrder.ID);
                    DMSCallContext.CurrentPurchaseOrder = null;
                }

            }

            DMSCallContext.RejectVendorOnDispatch = false;
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetVendorList()
        {

            var list = GetVendorListForContext();
            logger.InfoFormat("Returning vendor list : {0}", list.Count);
            return PartialView("_VendorList", list);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetVendorInfo()
        {
            ViewData[StringConstants.REJECT_VENDOR_ON_DISPATCH] = DMSCallContext.RejectVendorOnDispatch;
            if (DMSCallContext.ISPs != null && DMSCallContext.ISPs.Count > 0)
            {
                logger.Info("Returning vendor info");
                var isp = DMSCallContext.ISPs[DMSCallContext.VendorIndexInList];
                VendorFacade facade = new VendorFacade();
                //ViewData["VendorCallHistory"] = facade.GetVendorCallHistory(DMSCallContext.ServiceRequestID, isp.VendorLocationID);
                ViewData["VendorNotes"] = facade.GetVendorNotes(isp.VendorLocationID);
                return PartialView("_VendorInfo", isp);
            }
            logger.Info("Returning blank vendor info");

            return PartialView("_VendorInfo", null);
        }


        /// <summary>
        /// 
        /// </summary>
        /// <param name="currentIndex"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult NextVendor(int currentIndex)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            bool entryFound = false;
            var list = DMSCallContext.ISPs;
            // If in super user mode- get the next not called vendor.
            if (DMSCallContext.IsAllowedToSeeISPNotCalled || DMSCallContext.IsDispatchThresholdReached)
            {
                // Get the next vendor greater than current index and callstaus = 
                if (currentIndex < list.Count - 1)
                {
                    DMSCallContext.VendorIndexInList = currentIndex + 1;
                    entryFound = true;
                }
            }
            else // Check for call violation.
            {
                bool exceededCallsThreshold = HasExceededCallsThreshold();
                bool thresholdViolated = exceededCallsThreshold;
                logger.InfoFormat("Call threshold exceeded ? {0}", exceededCallsThreshold);
                if (!exceededCallsThreshold)
                {
                    // Get the next vendor greater than current index and callstaus = 
                    if (currentIndex < list.Count - 1)
                    {
                        for (int i = currentIndex + 1, l = list.Count; i < l; i++)
                        {
                            var item = list[i];
                            if (!item.CallStatus.Equals("NotCalled", StringComparison.InvariantCultureIgnoreCase))
                            {
                                // check for the milesthreshold violation.
                                bool exceededMilesThreshold = HasExceededMilesThreshold(item.EnrouteMiles.GetValueOrDefault());
                                logger.InfoFormat("Miles threshold exceeded ? {0}", exceededMilesThreshold);
                                if (!exceededMilesThreshold)
                                {
                                    //Set the next vendor in session.                            
                                    DMSCallContext.VendorIndexInList = i;
                                    entryFound = true;
                                }
                                else
                                {
                                    thresholdViolated = true;
                                }
                                break;
                            }
                        }

                        if (!entryFound)
                        {
                            for (int i = currentIndex + 1, l = list.Count; i < l; i++)
                            {
                                var item = list[i];
                                if (item.CallStatus.Equals("NotCalled", StringComparison.InvariantCultureIgnoreCase))
                                {
                                    // check for the milesthreshold violation.
                                    bool exceededMilesThreshold = HasExceededMilesThreshold(item.EnrouteMiles.GetValueOrDefault());
                                    logger.InfoFormat("Miles threshold exceeded ? {0}", exceededMilesThreshold);
                                    if (!exceededMilesThreshold)
                                    {
                                        //Set the next vendor in session.                            
                                        DMSCallContext.VendorIndexInList = i;
                                        entryFound = true;
                                    }
                                    else
                                    {
                                        thresholdViolated = true;
                                    }
                                    break;
                                }
                            }
                        }
                    }
                    else
                    {
                        thresholdViolated = true;
                    }
                }

                ServiceFacade facade = new ServiceFacade();
                if (thresholdViolated)
                {
                    result.Status = OperationStatus.ERROR;
                    result.Data = "OverThreshold";
                    result.ErrorMessage = "Search options are now available. You can click on “show options” and adjust the search and filter options.  Or you can search outside the system and use the Add Vendor button to add a temporary vendor.";
                    DMSCallContext.IsDispatchThresholdReached = true;
                    facade.SetIsDispatchThresholdReached(DMSCallContext.ServiceRequestID);
                }
                else if (!entryFound)
                {
                    result.Status = OperationStatus.ERROR;
                    result.Data = "NoRecords";
                    result.ErrorMessage = "There are no more vendors in the list.  You can click on Show Options and adjust the search and try again.  Or you can search outside the system and use the Add Vendor button to add a temporary vendor.";
                    DMSCallContext.IsDispatchThresholdReached = true;
                    facade.SetIsDispatchThresholdReached(DMSCallContext.ServiceRequestID);
                }
            }

            logger.InfoFormat("FullDispatchEnabled = {0}", (DMSCallContext.IsDispatchThresholdReached || DMSCallContext.IsAllowedToSeeISPNotCalled));

            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult ApplyFilters(VendorSearchFilters model)
        {
            //Elevate the privileges of the user.
            DMSCallContext.IsDispatchThresholdReached = true;

            ServiceFacade facade = new ServiceFacade();
            facade.SetIsDispatchThresholdReached(DMSCallContext.ServiceRequestID);

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.InfoFormat("Applying filters : {0} ", model.ToString());

            bool retrieveFromDB = true;
            VendorSearchFilters previewsFilters = DMSCallContext.OldDispatchSearchFilters;
            if (DMSCallContext.OrginalISPs.Count > 0 && previewsFilters.From == model.From &&
                previewsFilters.Radius == model.Radius && previewsFilters.ShowDoNotUse == model.ShowDoNotUse && previewsFilters.ProductOptions == model.ProductOptions)
            {
                retrieveFromDB = false;
            }
            if (retrieveFromDB)
            {
                DMSCallContext.ISPs = dispatchFacade.GetISPs(DMSCallContext.ServiceRequestID, DMSCallContext.ServiceMiles, DMSCallContext.VehicleTypeID.GetValueOrDefault(), DMSCallContext.VehicleCategoryID.GetValueOrDefault(), model.Radius, model.ShowDoNotUse, model.From, DMSCallContext.ServiceLocationLatitude, DMSCallContext.ServiceLocationLongitude, model.ShowCalled, model.ShowNotCalled,model.ProductOptions);
                DMSCallContext.OrginalISPs = DMSCallContext.ISPs.ToList<ISPs_Result>();

            }

            if (DMSCallContext.OrginalISPs.Count > 0)
            {
                var bigList = DMSCallContext.OrginalISPs;
                DMSCallContext.ISPs.Clear();
                if (model.ShowCalled)
                {
                    var called = bigList.Where(x => x.CallStatus != "NotCalled").ToList<ISPs_Result>();
                    DMSCallContext.ISPs.AddRange(called);
                }
                if (model.ShowNotCalled)
                {
                    var notCalled = bigList.Where(x => x.CallStatus == "NotCalled").ToList<ISPs_Result>();
                    DMSCallContext.ISPs.AddRange(notCalled);
                }
                if (model.ShowDoNotUse)
                {
                    var donotUse = bigList.Where(x => x.CallStatus == "DoNotUse").ToList<ISPs_Result>();
                    DMSCallContext.ISPs.AddRange(donotUse);
                }
            }

            DMSCallContext.VendorIndexInList = 0;
            DMSCallContext.OldDispatchSearchFilters = model;
            return Json(result);

        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="itemIndex"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult LoadVendor(int itemIndex)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            logger.Info("Set current vendor in context");
            if (DMSCallContext.IsDispatchThresholdReached || DMSCallContext.IsAllowedToSeeISPNotCalled)
            {
                DMSCallContext.VendorIndexInList = itemIndex;
            }
            else
            {
                bool exceededCallsThreshold = HasExceededCallsThreshold();
                bool exceedMilesThreshold = HasExceededMilesThreshold(DMSCallContext.ISPs[itemIndex].EnrouteMiles.GetValueOrDefault());
                if (exceededCallsThreshold || exceedMilesThreshold)
                {
                    result.Status = OperationStatus.ERROR;
                    result.Data = "OverThreshold";
                    result.ErrorMessage = "Search options are now available. You can click on “show options” and adjust the search and filter options.  Or you can search outside the system and use the Add Vendor button to add a temporary vendor.";
                    DMSCallContext.IsDispatchThresholdReached = true;
                }
                else
                {
                    DMSCallContext.VendorIndexInList = itemIndex;
                }
            }

            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="isCallMade"></param>
        /// <param name="phoneNumber"></param>
        /// <param name="phoneType"></param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult TrackCallToVendor(bool? isCallMade, string phoneNumber, string phoneType)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.InfoFormat("Set IsCallMade to vendor to : {0}", isCallMade.GetValueOrDefault());
            DMSCallContext.IsCallMadeToVendor = isCallMade ?? false;
            if (isCallMade.GetValueOrDefault())
            {
                DMSCallContext.VendorPhoneNumber = phoneNumber;
                DMSCallContext.VendorPhoneType = phoneType;
            }
            else
            {
                DMSCallContext.VendorPhoneNumber = DMSCallContext.VendorPhoneType = null;
            }
            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult AddVendor()
        {
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            logger.InfoFormat("Attempting to add a vendor");
            return PartialView("_AddVendor");
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult AddVendor(VendorInfo model)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.Info("Processing add vendor");

            var currentUser = LoggedInUserName;
            var facade = new VendorFacade();
            var srFacade = new ServiceFacade();
            var product = srFacade.GetPrimaryProduct(DMSCallContext.ServiceRequestID);
            facade.AddTemporaryVendor(model, Request.RawUrl, DMSCallContext.ServiceRequestID, currentUser, Session.SessionID);
            CommonLookUpRepository lookupRepository = new CommonLookUpRepository();

            ISPs_Result newVendor = new ISPs_Result()
            {
                Address1 = model.VendorAddress1,
                Address2 = model.VendorAddress2,
                CallStatus = "NotCalled",
                City = model.VendorCity,
                DispatchPhoneNumber = model.VendorDispatchNumber,
                FaxPhoneNumber = model.VendorFaxNumber,
                OfficePhoneNumber = model.VendorOfficeNumber,
                PostalCode = model.VendorPostalCode,
                VendorName = model.VendorName,
                ContractStatus = "Not Contracted",
                StateProvince = model.VendorState != null ? lookupRepository.GetStateProvince(model.VendorState.Value).Abbreviation : string.Empty, // TODO: Get Two letter code using ID
                CountryCode = model.VendorCountry != null ? lookupRepository.GetCountry(model.VendorCountry.Value).ISOCode : string.Empty,// TODO : Get two letter ISO code using ID
                VendorID = model.VendorID,
                VendorLocationID = model.VendorLocationID,
                ServiceMiles = DMSCallContext.ServiceMiles               
                
            };

            if (product != null)
            {
                newVendor.ProductID = product.ID;
                newVendor.ProductName = product.Name;
            }
            
            if (DMSCallContext.ISPs == null)
            {
                DMSCallContext.ISPs = new List<ISPs_Result>();
            }
            DMSCallContext.ISPs.Add(newVendor);
            DMSCallContext.VendorIndexInList = DMSCallContext.ISPs.Count - 1;

            logger.Info("Added vendor successfully");

            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="gotoPOModel"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GoToPO(GoToPOModel gotoPOModel)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            // If the current PO is not in pending status, let the user create a new PO.
            var currentPO = DMSCallContext.CurrentPurchaseOrder;
            if (currentPO != null && currentPO.PurchaseOrderStatu != null && !"pending".Equals(currentPO.PurchaseOrderStatu.Name, StringComparison.InvariantCultureIgnoreCase))
            {
                DMSCallContext.CurrentPurchaseOrder = null;
            }

            if (DMSCallContext.CurrentPurchaseOrder == null)
            {
                logger.Info("Processing Go to PO");

                string userName = LoggedInUserName;
                POFacade facade = new POFacade();
                PurchaseOrder po = new PurchaseOrder();
                po.ServiceRequestID = DMSCallContext.ServiceRequestID;
                DMSCallContext.VendorLocationID = gotoPOModel.VendorLocationID.HasValue ? gotoPOModel.VendorLocationID.Value : 0;
                po.VendorLocationID = DMSCallContext.VendorLocationID;
                po.VehicleCategoryID = DMSCallContext.VehicleCategoryID == 0 ? null : DMSCallContext.VehicleCategoryID;

                if (DMSCallContext.MemberPaymentTypeID != 0)
                {
                    po.MemberPaymentTypeID = DMSCallContext.MemberPaymentTypeID;
                }

                ServiceFacade srfacade = new ServiceFacade();
                ServiceRequest sr = srfacade.GetServiceRequestById(DMSCallContext.ServiceRequestID);
                po.ProductID = sr.PrimaryProductID;
                bool isServiceCovered = false;
                if ("active".Equals(DMSCallContext.MemberStatus, StringComparison.InvariantCultureIgnoreCase))
                {
                    bool isPrimaryProductCovered = sr.IsPrimaryProductCovered ?? false;
                    bool isSecondaryProductCovered = sr.IsSecondaryProductCovered ?? true;

                    if (isPrimaryProductCovered && isSecondaryProductCovered)
                    {
                        isServiceCovered = true;
                    }
                }

                DMSCallContext.IsPrimaryServiceCovered = isServiceCovered;
                po.IsServiceCovered = isServiceCovered;
                DMSCallContext.TalkedTo = gotoPOModel.TalkedTo;
                DMSCallContext.Company = gotoPOModel.VendorName;
                ISPs_Result isps = new ISPs_Result();
                if (DMSCallContext.ISPs != null && DMSCallContext.ISPs.Count > 0)
                {
                    isps = DMSCallContext.ISPs[DMSCallContext.VendorIndexInList];
                    po.EnrouteMiles = isps.EnrouteMilesRounded;
                    po.EnrouteTimeMinutes = isps.EnrouteTimeMinutes;
                    po.ServiceMiles = isps.ServiceMilesRounded;
                    po.ServiceTimeMinutes = sr.ServiceTimeInMinutes;
                    //isps.ServiceTimeMinutes;
                    if (isps.ContractStatus == "Contracted")
                    {
                        po.ServiceFreeMiles = isps.ServiceFreeMiles;
                        po.EnrouteFreeMiles = isps.EnrouteFreeMiles;
                    }
                    else
                    {
                        po.ServiceFreeMiles = 0;
                        po.EnrouteFreeMiles = 0;
                    }
                    po.ReturnMiles = isps.ReturnMilesRounded;
                    po.ReturnTimeMinutes = isps.ReturnTimeMinutes;
                    po.FaxPhoneNumber = isps.FaxPhoneNumber;
                    po.DispatchPhoneNumber = isps.DispatchPhoneNumber;
                    po.VendorLocationID = isps.VendorLocationID;
                }

                po.IsPayByCompanyCreditCard = false;
                po.IsVendorAdvised = false;
                po.IsGOA = false;
                po.CreateBy = userName;
                po.ModifyBy = userName;
                //po.CoverageLimit
                logger.InfoFormat("Add or update PO");
                po = facade.AddOrUpdatePO(po, "GoToPo", null, isps,DMSCallContext.ProgramID,  Request.RawUrl, Session.SessionID,gotoPOModel.VendorID);
                if (DMSCallContext.ContactLogID == null)
                {
                    DMSCallContext.ContactLogID = facade.CreateGotoPOContactLog(gotoPOModel, userName, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST);
                }
                ContactLogFacade clfacade = new ContactLogFacade();
                if (po.PurchaseOrderStatu != null)
                {
                    logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
                }
                DMSCallContext.CurrentPurchaseOrder = po;
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult LeaveTab()
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.Info("Processing leave tab");
            var currentUser = LoggedInUserName;
            DispatchFacade.Save(Request.RawUrl, currentUser, Session.SessionID, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST);
            return Json(result);
        }
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

            logger.Info("Event log created successfully for EnterTechTab");

            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion
    }
}
