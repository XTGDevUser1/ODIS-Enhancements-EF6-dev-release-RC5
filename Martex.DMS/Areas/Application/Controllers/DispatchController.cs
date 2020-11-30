using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Areas.Application.Models;
using System.Text;
using Martex.DMS.Common;
using Martex.DMS.DAO;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Model;
using Martex.DMS.Models;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using System.Web.Script.Serialization;
using Kendo.Mvc.UI;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.DataValidators;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class DispatchController : BaseController
    {

        #region Instance variables

        /// <summary>
        /// The dispatch facade
        /// </summary>
        protected DispatchFacade dispatchFacade = new DispatchFacade();
        #endregion

        #region Private Methods

        /// <summary>
        /// Gets the vendor list for context.
        /// </summary>
        /// <returns></returns>
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
            if (DMSCallContext.RejectVendorOnDispatch || DMSCallContext.SetVendorInContext)
            {
                // This flag is set from Queue or ActiveRequest after a pending PO is set in context.
                DMSCallContext.SetVendorInContext = false;
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

        /// <summary>
        /// Checks the index of ISP.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        private bool CheckIndexOfISP(int vendorID, int vendorLocationID)
        {
            int i = 0;
            bool found = false;
            var list = DMSCallContext.ISPs;
            for (int l = list.Count; i < l; i++)
            {
                var x = list[i];
                if (x.VendorID == vendorID && x.VendorLocationID == vendorLocationID)
                {
                    found = true;
                    break;
                }
            }
            return found;
        }

        /// <summary>
        /// Gets the index of ISP.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
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

        /// <summary>
        /// Gets the index of not called ISP.
        /// </summary>
        /// <param name="startingFrom">The starting from.</param>
        /// <returns></returns>
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

        /// <summary>
        /// Gets the index of not not called ISP.
        /// </summary>
        /// <param name="startingFrom">The starting from.</param>
        /// <returns></returns>
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

        /// <summary>
        /// Calculates the permissions.
        /// </summary>
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

        /// <summary>
        /// Determines whether [has exceeded calls threshold].
        /// </summary>
        /// <returns>
        ///   <c>true</c> if [has exceeded calls threshold]; otherwise, <c>false</c>.
        /// </returns>
        private bool HasExceededCallsThreshold()
        {
            string thresholdConfig = AppConfigRepository.GetValue(AppConfigConstants.THRESHOLD_NUMBER_OF_CALLS);
            logger.InfoFormat("AppConfig.{0} = {1}", AppConfigConstants.THRESHOLD_NUMBER_OF_CALLS, thresholdConfig);
            logger.InfoFormat("Calls made so far = {0}", DMSCallContext.CallsMadeSoFar);
            int callThreshold = 0;
            int.TryParse(thresholdConfig, out callThreshold);

            return DMSCallContext.CallsMadeSoFar >= callThreshold;
        }

        /// <summary>
        /// Determines whether [has exceeded miles threshold] [the specified enroute miles].
        /// </summary>
        /// <param name="enrouteMiles">The enroute miles.</param>
        /// <returns>
        ///   <c>true</c> if [has exceeded miles threshold] [the specified enroute miles]; otherwise, <c>false</c>.
        /// </returns>
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
        /// <summary>
        /// Checks the required attributes.
        /// </summary>
        /// <returns></returns>
        protected List<string> CheckRequiredAttributes()
        {
            List<string> missingFields = new List<string>();
            if (DMSCallContext.ProductCategoryName != "Home Locksmith" && DMSCallContext.VehicleTypeID == null)
            {
                missingFields.Add("Vehicle (Vehicle tab)");
            }
            if (DMSCallContext.ProductCategoryName != "Home Locksmith" && DMSCallContext.VehicleCategoryID == null)
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

            //PAY-AS-YOU-GO
            if (DMSCallContext.AllowEstimateProcessing && DMSCallContext.ServiceEstimateFee.GetValueOrDefault() == 0)
            {
                missingFields.Add("Must provide customer an estimate before selecting an ISP");
            }
            return missingFields;
        }

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
            logger.InfoFormat("DispatchController - Index()");
            var loggedInUser = LoggedInUserName;
            logger.Info("Creating event log and link records for enter dispatch tab");


            // 2. Determine if show options should be enabled.

            var errors = CheckRequiredAttributes();

            if (logger.IsInfoEnabled)
            {
                logger.InfoFormat("DispatchController - Index() - Missing Required attributes - {0}", errors.Count);
                var index = 1;
                if (errors.Count > 0)
                {
                    logger.InfoFormat("DispatchController - Index() - Unable to provide the ISP list. Missing Required Attributes are");
                    foreach (var error in errors)
                    {
                        logger.InfoFormat("{0} - {1}", index, error);
                        index++;
                    }
                }
            }

            ViewData[StringConstants.REQUIRED_FIELDS_FOR_DISPATCH] = errors;
            ViewData[StringConstants.SHOW_OPTIONS] = false;
            ViewData[StringConstants.ENABLE_ADD_VENDOR] = false;
            //CR: 1115
            ViewData[StringConstants.PRODUCT_OPTIONS] = DispatchFacade.GetProductOptions(DMSCallContext.ProductCategoryID, DMSCallContext.VehicleTypeID, DMSCallContext.VehicleCategoryID);
            if (errors.Count == 0)
            {
                // 3. Enable or disable options [ previous, next, add vendor and show/hide options]
                logger.Info("DispatchController - Index() - Determine permissions");

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
                ViewData["VendorList"] = GetVendorListForContext();
                if (DMSCallContext.VendorIndexInList >= 0 && DMSCallContext.ISPs.Count > 0)
                {
                    var isp = DMSCallContext.ISPs[DMSCallContext.VendorIndexInList];
                    VendorFacade facade = new VendorFacade();
                    ViewData["VendorNotes"] = facade.GetVendorNotes(isp.VendorLocationID);
                    logger.InfoFormat("DispatchController - Index() - VendorNotes {0}", ViewData["VendorNotes"]);
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

            //TFS:163
            SetTabValidationStatus(RequestArea.DISPATCH);
            logger.InfoFormat("DispatchController - Index() - Returning _Index() view.");
            return PartialView("_Index", DMSCallContext.ISPs);
        }

        /// <summary>
        /// Rejects the vendor.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult RejectVendor()
        {
            logger.InfoFormat("DispatchController - RejectVendor()");
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
            ViewData["ContactActionsForTalkedTo"] = json;
            logger.InfoFormat("DispatchController - RejectVendor() - ContactActionsForTalkedTo {0}", ViewData["ContactActionsForTalkedTo"]);

            return PartialView("_RejectVendor");
        }

        /// <summary>
        /// Rejects the vendor.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        public ActionResult RejectVendor(RejectVendorModel model)
        {
            logger.InfoFormat("DispatchController - RejectVendor() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                RejectVendorModel = model
            }));

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            logger.Info("Processing Reject");

            var loggedInUser = LoggedInUserName;
            var LastVendercontactID = DMSCallContext.LastVendorContactLogID.GetValueOrDefault();
            
            DispatchFacade.Reject(model, loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, LastVendercontactID);
            DMSCallContext.LastVendorContactLogID = null;
            var item = DMSCallContext.ISPs[DMSCallContext.VendorIndexInList] as ISPs_Result;

            // Update the item in the cached list.
            item.CallStatus = model.PossibleRetry.GetValueOrDefault() ? "Called" : "Rejected";
            item.RejectReason = Request.Form["ContactAction_input"];
            item.RejectComment = model.RejectComments;
            //TFS: 449
            //item.Comment = model.RejectComments;
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
                    facade.PODisable(DMSCallContext.CurrentPurchaseOrder.ID, LoggedInUserName);
                    DMSCallContext.CurrentPurchaseOrder = null;
                    DMSCallContext.CurrentPODetails = null;
                }

            }

            DMSCallContext.RejectVendorOnDispatch = false;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the get vendor list.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetVendorList()
        {
            logger.InfoFormat("DispatchController - _GetVendorList()");
            var list = GetVendorListForContext();
            logger.InfoFormat("Returning vendor list : {0}", list.Count);
            return PartialView("_VendorList", list);
        }

        /// <summary>
        /// _s the get vendor info.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult _GetVendorInfo()
        {
            logger.InfoFormat("DispatchController - _GetVendorInfo()");
            ViewData[StringConstants.REJECT_VENDOR_ON_DISPATCH] = DMSCallContext.RejectVendorOnDispatch;
            if (DMSCallContext.ISPs != null && DMSCallContext.ISPs.Count > 0)
            {
                logger.Info("Returning vendor info");
                var isp = DMSCallContext.ISPs[DMSCallContext.VendorIndexInList];
                VendorFacade facade = new VendorFacade();
                ViewData["VendorNotes"] = facade.GetVendorNotes(isp.VendorLocationID);
                logger.InfoFormat("DispatchController - _GetVendorInfo() - Returns :  {0}", JsonConvert.SerializeObject(new
                {
                    isp = isp
                }));
                return PartialView("_VendorInfo", isp);
            }
            logger.Info("Returning blank vendor info");

            return PartialView("_VendorInfo", null);
        }


        /// <summary>
        /// Nexts the vendor.
        /// </summary>
        /// <param name="currentIndex">Index of the current.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult NextVendor(int currentIndex)
        {
            logger.InfoFormat("DispatchController - NextVendor() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                currentIndex = currentIndex
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            bool entryFound = false;
            var list = DMSCallContext.ISPs;
            ServiceFacade facade = new ServiceFacade();

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
        /// Applies the filters.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult ApplyFilters(VendorSearchFilters model)
        {
            logger.InfoFormat("DispatchController - ApplyFilters() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                VendorSearchFilters = model
            }));
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
                DMSCallContext.ISPs = dispatchFacade.GetISPs(DMSCallContext.ServiceRequestID, DMSCallContext.ServiceMiles, DMSCallContext.VehicleTypeID.GetValueOrDefault(), DMSCallContext.VehicleCategoryID.GetValueOrDefault(), model.Radius, model.ShowDoNotUse, model.From, DMSCallContext.ServiceLocationLatitude, DMSCallContext.ServiceLocationLongitude, model.ShowCalled, model.ShowNotCalled, model.ProductOptions);
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
        /// Loads the vendor.
        /// </summary>
        /// <param name="itemIndex">Index of the item.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult LoadVendor(int itemIndex)
        {
            logger.InfoFormat("DispatchController - LoadVendor() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                itemIndex = itemIndex
            }));
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
        /// Tracks the call to vendor.
        /// </summary>
        /// <param name="isCallMade">The is call made.</param>
        /// <param name="phoneNumber">The phone number.</param>
        /// <param name="phoneType">Type of the phone.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult TrackCallToVendor(bool? isCallMade, string phoneNumber, string phoneType)
        {
            logger.InfoFormat("DispatchController - TrackCallToVendor() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                isCallMade = isCallMade,
                phoneNumber = phoneNumber,
                phoneType = phoneType
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.InfoFormat("Set IsCallMade to vendor to : {0}", isCallMade.GetValueOrDefault());
            DMSCallContext.IsCallMadeToVendor = isCallMade ?? false;
            if (isCallMade.GetValueOrDefault())
            {
                DMSCallContext.VendorPhoneNumber = phoneNumber;
                DMSCallContext.VendorPhoneType = phoneType;

                IncrementCallCounts(AgentTimeCounts.DISPATCH_CALL);

            }
            else
            {
                DMSCallContext.VendorPhoneNumber = DMSCallContext.VendorPhoneType = null;
            }
            return Json(result);
        }

        /// <summary>
        /// Adds the vendor.
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
        /// Adds the vendor.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult AddVendor(VendorInfo model)
        {
            logger.InfoFormat("DispatchController - AddVendor() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                VendorInfo = model
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.Info("Processing add vendor");
            var currentUser = LoggedInUserName;
            var facade = new VendorFacade();
            var srFacade = new ServiceFacade();
            //NP:4/7

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortColumn = "VendorID",
                SortDirection = "ASC",
                PageSize = 10
            };
            List<GetVendorInfoSearch_Result> MatchedVendorsList = facade.GetVendorMatch(pageCriteria, model.VendorDispatchNumber, model.VendorOfficeNumber, model.VendorName);
            logger.InfoFormat("Matched Vendors Count is: {0}", MatchedVendorsList.Count);
            if (MatchedVendorsList.Count > 0)
            {

                int totalRows = 0;
                if (MatchedVendorsList[0].TotalRows.HasValue)
                {
                    totalRows = MatchedVendorsList[0].TotalRows.Value;
                }
                logger.Info("Returning the Partial View _MatchedUserList with the Matched Vendor List");
                return PartialView("_MatchedUserList", MatchedVendorsList);
            }

            var product = srFacade.GetPrimaryProduct(DMSCallContext.ServiceRequestID);
            logger.InfoFormat("Adding Vendor");
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
                ServiceMiles = DMSCallContext.ServiceMiles,
                Latitude = model.LatLong != null ? model.LatLong.Latitude : null,
                Longitude = model.LatLong != null ? model.LatLong.Longitude : null

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
        /// _s the list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult _List([DataSourceRequest] DataSourceRequest request, VendorInfo model)
        {
            logger.InfoFormat("DispatchController - _List() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                DataSourceRequest = request,
                VendorInfo = model
            }));
            //logger.Info("Inside List() of DispatchController. Attempt to get all Users depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "VendorID";
            string sortOrder = "ASC";
            ViewData["formData"] = model;
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            UsersFacade userFacade = new UsersFacade();
            var facade = new VendorFacade();
            List<GetVendorInfoSearch_Result> list = facade.GetVendorMatch(pageCriteria, model.VendorDispatchNumber, model.VendorOfficeNumber, model.VendorName);
            logger.InfoFormat("Matched Vendors Count is: {0}", list.Count);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            return Json(result);
        }

        /// <summary>
        /// Adds the vendor forcebly.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult AddVendorForcebly(VendorInfo model)
        {
            logger.InfoFormat("DispatchController - AddVendorForcebly() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                VendorInfo = model
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.Info("Processing add vendor");
            var currentUser = LoggedInUserName;
            var facade = new VendorFacade();
            var srFacade = new ServiceFacade();
            var product = srFacade.GetPrimaryProduct(DMSCallContext.ServiceRequestID);
            //  Add Event log record for Rejecting Existing Vendor.
            var eventLoggerFacade = new EventLoggerFacade();
            logger.Info("Logging an event for Create temporary vendor");
            eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.REJECT_EXISTING_VENDOR, "Reject Existing Vendor", currentUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
            // Event Log REcored Added
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
                ServiceMiles = DMSCallContext.ServiceMiles,
                Latitude = model.LatLong != null ? model.LatLong.Latitude : null,
                Longitude = model.LatLong != null ? model.LatLong.Longitude : null

            };

            result.Data = model.VendorDispatchNumber;

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
            logger.Info("Forcibly Added vendor successfully");

            return Json(result);
        }

        /// <summary>
        /// Gets the selected vendor.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public ActionResult GetSelectedVendor(int vendorID, int vendorLocationID)
        {
            logger.InfoFormat("DispatchController - GetSelectedVendor() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                vendorID = vendorID,
                vendorLocationID = vendorLocationID
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            VendorFacade facade = new VendorFacade();
            var currentUser = LoggedInUserName;
            logger.Info("Checking the details of Selected Vendor");
            bool found = CheckIndexOfISP(vendorID, vendorLocationID);
            if (found == true)
            {
                int i = GetIndexOfISP(vendorID, vendorLocationID);
                logger.InfoFormat("The Selected Vendor is in the ISP list at {0} index", i);
                DMSCallContext.VendorIndexInList = i;
                result.Data = DMSCallContext.ISPs[i].DispatchPhoneNumber;
            }
            else
            {
                logger.Info("The selected vendor is not present in the ISP list, Adding to the list");
                var srFacade = new ServiceFacade();
                var product = srFacade.GetPrimaryProduct(DMSCallContext.ServiceRequestID);
                CommonLookUpRepository lookupRepository = new CommonLookUpRepository();
                VendorInfo model = facade.VendorDetails(vendorID, vendorLocationID, DMSCallContext.ServiceRequestID, DMSCallContext.OldDispatchSearchFilters.From);
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
                    ServiceMiles = DMSCallContext.ServiceMiles,
                    EnrouteMiles = model.enrouteMiles

                };

                result.Data = model.VendorDispatchNumber;

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
                logger.Info("Using the existing Vendor");
            }

            EventLoggerFacade eventLogfacade = new EventLoggerFacade();
            long eventlogId = eventLogfacade.LogEvent(Request.RawUrl, EventNames.USE_EXISTING_VENDOR, "UseExistingVendor", currentUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
            eventLogfacade.CreateRelatedLogLinkRecord(eventlogId, vendorLocationID, EntityNames.VENDOR_LOCATION);

            return Json(result);
        }

        /// <summary>
        /// Goes to PO.
        /// </summary>
        /// <param name="gotoPOModel">The goto PO model.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GoToPO(GoToPOModel gotoPOModel)
        {
            logger.InfoFormat("DispatchController - GoToPO() - Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                GoToPOModel = gotoPOModel
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            // If the current PO is not in pending status, let the user create a new PO.
            var currentPO = DMSCallContext.CurrentPurchaseOrder;
            if ((currentPO != null && currentPO.PurchaseOrderStatu != null && !"pending".Equals(currentPO.PurchaseOrderStatu.Name, StringComparison.InvariantCultureIgnoreCase)) || (currentPO != null && currentPO.ID == 0))
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
                    bool isPrimaryProductCovered = sr.IsPrimaryOverallCovered ?? false;
                    bool isSecondaryProductCovered = sr.IsSecondaryOverallCovered ?? true;

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

                    try
                    {
                        /* BING Route Service integration to get actual miles and minutes from BING */
                        var routeFacade = new RouteFacade();
                        EnrouteData enrouteData = routeFacade.CalculateEnrouteMilesAndTime(isps.Latitude, isps.Longitude, DMSCallContext.ServiceLocationLatitude, DMSCallContext.ServiceLocationLongitude);

                        isps.EnrouteMiles = enrouteData.Distance;
                        isps.EnrouteTimeMinutes = (int)enrouteData.Time / 60;
                    }
                    catch (Exception ex)
                    {
                        EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                        Dictionary<string, string> eventDetails = new Dictionary<string, string>();
                        eventDetails.Add("Service", "Bing Route Service Down");
                        eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.BING_MAP_SERVICE_DOWN, eventDetails, LoggedInUserName, HttpContext.Session.SessionID);
                        logger.Warn(ex.Message, ex);
                    }

                    po.EnrouteMiles = isps.EnrouteMilesRounded;
                    po.EnrouteTimeMinutes = isps.EnrouteTimeMinutes;
                    po.ServiceMiles = isps.ServiceMilesRounded;
                    po.ServiceTimeMinutes = sr.ServiceTimeInMinutes;
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
                //Bug 1621: Admin Score must be 0
                po.AdminstrativeRating = 0;

                po.IsVendorAdvised = false;
                po.IsGOA = false;
                po.CreateBy = userName;
                po.ModifyBy = userName;


                //KB: Set the eligibility fields
                po.ServiceEligibilityMessage = sr.PrimaryServiceEligiblityMessage;
                po.IsServiceCovered = sr.IsPrimaryOverallCovered;
                po.CoverageLimit = sr.PrimaryCoverageLimit;
                po.CoverageLimitMileage = sr.PrimaryCoverageLimitMileage;
                po.MileageUOM = sr.MileageUOM;
                po.IsServiceCoverageBestValue = sr.IsServiceCoverageBestValue;

                //PAY-AS-YOU-GO
                po.ServiceEstimate = sr.ServiceEstimate;
                po.EstimatedTimeCost = sr.EstimatedTimeCost;
                po.IsOverageApproved = null; //TFS: 1219

                po.PartsAndAccessoryCode = sr.PartsAndAccessoryCode;
                po.IsDirectTowDealer = sr.IsDirectTowDealer;

                logger.InfoFormat("Add or update PO");

                // Set the selection order. This is done on demand as there is no point updating the selection order each time we get the ISP selection list. This is for better for performance.
                // Updating Vendor Index in List with incrementing by 1
                int vendorIndexInList = DMSCallContext.VendorIndexInList + 1;
                isps.SelectionOrder = vendorIndexInList;
                PORepository repository = new PORepository();
                Program program = ReferenceDataRepository.GetProgramByID(DMSCallContext.ProgramID);
                po.ThresholdPercentage = repository.GetPOThresholdPercentage(DMSCallContext.VehicleCategoryID.GetValueOrDefault(), DMSCallContext.ProductCategoryID.GetValueOrDefault(), isps.VendorID, program.ClientID, DMSCallContext.ProgramID);
                po = facade.AddOrUpdatePO(po, "GoToPo", null, isps, DMSCallContext.ProgramID, Request.RawUrl, Session.SessionID, gotoPOModel.VendorID);

                var LastVendorcontactID = DMSCallContext.LastVendorContactLogID.GetValueOrDefault();
                DMSCallContext.ContactLogID = facade.CreateGotoPOContactLog(gotoPOModel, userName, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, LastVendorcontactID);
                DMSCallContext.LastVendorContactLogID = null;
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
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            EventLoggerFacade facade = new EventLoggerFacade();
            string loggedInUser = LoggedInUserName;
            facade.LogEvent(Request.RawUrl, eventName, description, loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, HttpContext.Session.SessionID);

            logger.Info("Event log created successfully for EnterTechTab");

            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

        /// <summary>
        /// Leaves the tab.
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult LeaveTab()
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            var currentUser = LoggedInUserName;
            DispatchFacade.Save(Request.RawUrl, currentUser, Session.SessionID, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST);
            return Json(result);
        }
    }
}
