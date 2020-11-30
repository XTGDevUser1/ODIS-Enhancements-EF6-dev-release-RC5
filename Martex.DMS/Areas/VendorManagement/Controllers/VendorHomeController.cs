using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.Areas.VendorManagement.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Model;
using System.Text;
using Martex.DMS.BLL.SMTPSettings;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.BLL.Common;
using System.Web.Script.Serialization;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    /// <summary>
    /// Vendor Home Controller
    /// </summary>
    public partial class VendorHomeController : BaseController
    {
        #region Private Members
        /// <summary>
        /// The Vendor Management Facade
        /// </summary>
        VendorManagementFacade facade = new VendorManagementFacade();
        #endregion

        #region Public Methods
        /// <summary>
        /// _Aes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_VENDOR_VENDOR)]
        public ActionResult Index()
        {
            logger.Info("Inside the Index() method in Vendor Home Controller");
            return View();
        }

        /// <summary>
        /// Vendors the search.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult VendorSearch([DataSourceRequest] DataSourceRequest request, VendorManagementSearchCriteria model)
        {
            logger.Info("Inside VendorSearch of Vendor Home Controller. Attempt to get all Vendors depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "VendorNumber";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = model.GetFilterSearchCritera();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorManagementList_Result> list = new List<VendorManagementList_Result>();
            if (filter.Count > 0)
            {
                list = facade.Search(pageCriteria);
            }
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
        /// Adds the vendor.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_ADD_VENDOR)]
        public ActionResult AddVendor()
        {
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.ContactSources.ToString()] = ReferenceDataRepository.GetVendorSourceTypes().ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
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
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.BUTTON_ADD_VENDOR)]
        public ActionResult AddVendor(VendorInfo model)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.Info("Processing add vendor");
            var currentUser = LoggedInUserName;
            VendorManagementFacade facade = new VendorManagementFacade();
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
            if (MatchedVendorsList.Count > 0)
            {
                logger.InfoFormat("Matched Vendors Count is: {0}", MatchedVendorsList.Count);
                int totalRows = 0;
                if (MatchedVendorsList[0].TotalRows.HasValue)
                {
                    totalRows = MatchedVendorsList[0].TotalRows.Value;
                }
                logger.Info("Returning the Partial View _MatchedUserList with the Matched Vendor List");
                return PartialView("_MatchedVendorList", MatchedVendorsList);
            }
            VendorInfo newModel = facade.AddVendor(model, Request.RawUrl, DMSCallContext.ServiceRequestID, currentUser, Session.SessionID);

            logger.Info("Added vendor successfully");
            //  Add Event log record for Add Vendor.
            var eventLoggerFacade = new EventLoggerFacade();
            long eventlogId = eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.ADD_VENDOR, "Add Vendor", currentUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
            result.Data = newModel;
            return Json(result);
        }

        /// <summary>
        /// Gets the Vendors list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult _List([DataSourceRequest] DataSourceRequest request, VendorInfo model)
        {
            logger.Info("Inside List() of VendorHomeController. Attempt to get all Vendors depending upon the GridCommand");
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
            VendorManagementFacade facade = new VendorManagementFacade();
            List<GetVendorInfoSearch_Result> list = facade.GetVendorMatch(pageCriteria, model.VendorDispatchNumber, model.VendorOfficeNumber, model.VendorName);

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
        /// Loads the search criteria.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.VendorSearchCriteriaNameFilterType, true)]
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [HttpPost]
        public ActionResult _SearchCriteria(VendorManagementSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SearchCriteria() model in VendorHomeController with Model:{0}", model);
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            var tempHoldModel = model.GetModelForSearchCriteria();
            ModelState.Clear();
            if (model.FilterToLoadID.HasValue)
            {
                VendorManagementSearchCriteria dbModel = model.GetView(model.FilterToLoadID.Value) as VendorManagementSearchCriteria;
                if (dbModel != null)
                {
                    if (dbModel.CountryID.HasValue)
                    {
                        ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(dbModel.CountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
                    }
                    return View(dbModel);
                }
            }
            logger.Info("Returns the View");
            return View(tempHoldModel);
        }

        /// <summary>
        /// Loads the selected criteria.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult _SelectedCriteria(VendorManagementSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SelectedCriteria() model in VendorHomeController with Model:{0}", model);
            logger.Info("Returns the View");
            return View(model.GetModelForSearchCriteria());
        }

        /// <summary>
        /// Gets the vendor details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="tabIndex">Index of the tab.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.CommentType, false)]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.GRID_ACTION_VENDOR_EDIT)]
        public ActionResult _VendorDetails(int vendorID)
        {
            logger.InfoFormat("Inside the _VendorDetails() method in VendorHome Controller with Vendor ID:{0}", vendorID);
            VendorDetailsModel model = new VendorDetailsModel();
            model.BasicInformation = facade.Get(vendorID);
            model.ContractStatus = facade.GetContractStatus(vendorID);
            //model.IsCoachNetDealerPartner = facade.GetIsVendorCoachNetDealerPartner(vendorID);
            model.Indicators = facade.GetVendorIndicators(EntityNames.VENDOR, vendorID);
            IEnumerable<SelectListItem> list = facade.GetVendorLocationsList(vendorID).OrderBy(x => x.VendorLocationID).ToSelectListItem(x => x.VendorLocationID.ToString(), y => y.LocationAddress, false);
            ViewData[StaticData.LocationList.ToString()] = new SelectList(list, "Value", "Text");
            logger.InfoFormat("Returns the View with Model:{0}", model);
            return View(model);
        }

        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.VendorStatus, true)]
        [ReferenceDataFilter(StaticData.VendorChangeReason, true)]
        [ReferenceDataFilter(StaticData.VendorInfoTaxClassification, true)]
        [ReferenceDataFilter(StaticData.DispatchSoftwareProduct, true)]
        //[ReferenceDataFilter(StaticData.DriverSoftwareProduct, true)]
        [ReferenceDataFilter(StaticData.DispatchGPSNetwork, true)]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.GRID_ACTION_VENDOR_SUMMARY)]
        public ActionResult _VendorSummary(int vendorID)
        {
            logger.InfoFormat("Inside the _Vendor Summary() method in VendorHome Controller with Vendor ID:{0}", vendorID);
            VendorDetailsModel model = new VendorDetailsModel();
            model.BasicInformation = facade.Get(vendorID);
            model.ContractStatus = facade.GetContractStatus(vendorID);
            //model.IsCoachNetDealerPartner = facade.GetIsVendorCoachNetDealerPartner(vendorID);
            model.Indicators = facade.GetVendorIndicators(EntityNames.VENDOR, vendorID);
            logger.InfoFormat("Returns the View with Model:{0}", model);
            return View(model);
        }

        [NoCache]
        public ActionResult _VendorSummaryLocationRates([DataSourceRequest] DataSourceRequest request, int vendorID)
        {
            logger.Info("Inside _Vendor Summary Location Rates VendorHomeController. Attempt to get all Vendors depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "VendorID";
            string sortOrder = "ASC";
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
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorSummaryLocationRates_Result> list = facade.GetVendorSummaryLocationRates(pageCriteria, vendorID);

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


        #endregion

        #region Individual Tab Load Methods for the Vendor Locations

        #region Vendor Locations
        /// <summary>
        /// Gets the vendor location tabs.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _VendorLocationTabs(int vendorID, int vendorLocationID)
        {
            logger.InfoFormat("Inside the method _VendorLocationTabs() in VendorHomeController with Vendor ID:{0} and Vendor Location ID:{1}", vendorID, vendorLocationID);
            VendorDetailsModel model = new VendorDetailsModel();
            model.BasicInformation = facade.Get(vendorID);
            model.OldVendorStatusID = model.BasicInformation.VendorStatusID;
            model.VendorLocationID = vendorLocationID;
            model.BasicInformation.ID = vendorID;
            logger.InfoFormat("Returns the View with Model:{0}", model);
            return View(model);
        }

        #endregion

        #region Vendor Location Info
        /// <summary>
        /// Gets the vendor_ location_ info.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.VendorLocationStatus, true)]
        [ReferenceDataFilter(StaticData.VendorChangeReason, true)]
        public ActionResult _Vendor_Location_Info(int vendorID, int vendorLocationID)
        {
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            logger.InfoFormat("Trying to load Vendor Location Details for Vendor Location ID {0}", vendorLocationID);
            VendorLocationInfoModel model = null;
            model = facade.GetVendorLocationInfoDetails(vendorID, vendorLocationID);
            model.Indicators = facade.GetVendorIndicators(EntityNames.VENDOR_LOCATION, vendorLocationID);
            if (model.AddressInformation != null && model.AddressInformation.CountryID.HasValue)
            {
                ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(model.AddressInformation.CountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }
            logger.InfoFormat("Execution Finished for the Vendor information Details with Vendor Location ID {0}", vendorLocationID);
            return PartialView(model);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult _Vendor_Location_Info_Save(VendorLocationInfoModel model)
        {
            logger.InfoFormat("Trying to Save Vendor Lcoation Info Details for the Vendor Location ID {0}", model.BasicInformation.ID);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            facade.SaveVendorLocationInfoDetails(model, LoggedInUserName);
            logger.Info("Record Saved successfully");
            return Json(result);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult _Vendor_Location_Info_Save_Validate(VendorLocationInfoModel model)
        {
            StringBuilder sbErros = new StringBuilder();
            sbErros.Append("In order to make location status Active the following fields are required:");
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            bool hasError = false;
            if (string.IsNullOrEmpty(model.AddressInformation.Line1))
            {
                sbErros.Append(string.Format("<br/>Address 1"));
                hasError = true;
            }
            if (string.IsNullOrEmpty(model.AddressInformation.City))
            {
                sbErros.Append(string.Format("<br/>City"));
                hasError = true;
            }
            if (!model.AddressInformation.CountryID.HasValue)
            {
                sbErros.Append(string.Format("<br/>Country"));
                hasError = true;
            }
            if (!model.AddressInformation.StateProvinceID.HasValue)
            {
                sbErros.Append(string.Format("<br/>State"));
                hasError = true;
            }
            if (string.IsNullOrEmpty(model.AddressInformation.PostalCode))
            {
                sbErros.Append(string.Format("<br/>Postal Code"));
                hasError = true;
            }
            if (!model.BasicInformation.Latitude.HasValue)
            {
                sbErros.Append(string.Format("<br/>Latitude"));
                hasError = true;
            }
            if (!model.BasicInformation.Longitude.HasValue)
            {
                sbErros.Append(string.Format("<br/>Longitude"));
                hasError = true;
            }

            //validation for Phone Types as it's a Control tht's why we need to validate by hitting DB
            var phoneFacade = new PhoneFacade();
            PhoneEntity entity = phoneFacade.Get(model.BasicInformation.ID, EntityNames.VENDOR_LOCATION, PhoneTypeNames.Dispatch);
            if (entity == null)
            {
                sbErros.Append(string.Format("<br/> Dispatch phone number"));
                hasError = true;
            }

            if (model.PaymentTypes==null || model.PaymentTypes.Where(u => u.Selected == true).Count() <= 0)
            {
                sbErros.Append(string.Format("<br/>At least 1 payment type"));
                hasError = true;
            }

            if (hasError)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = sbErros.ToString();
            }

            return Json(result);
        }
        #endregion

        #region Vendor Location PO
        /// <summary>
        /// Gets the vendor location PO history.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public ActionResult _Vendor_Location_PO_History(int vendorID, int vendorLocationID)
        {
            logger.Info("Call the View '_Vendor_Location_PO_History'");
            return View(vendorLocationID);
        }

        /// <summary>
        /// Gets the vendor Location PO List
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="VendorLocationId">The vendor location id.</param>
        /// <returns></returns>
        public ActionResult _GetVendorLocationPO([DataSourceRequest] DataSourceRequest request, int VendorLocationId)
        {
            logger.InfoFormat("Inside _GetVendorLocationPO of VendorHomeController. Attempt to get all the POs depending upon the GridCommand and VendorLocationID:{0}", VendorLocationId);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "PurchaseOrderNumber";
            string sortOrder = "ASC";
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
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorLocationPOList_Result> list = facade.GetVendorLocationPODetails(pageCriteria, VendorLocationId);

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
            return Json(result, JsonRequestBehavior.AllowGet);

        }
        #endregion

        #region Vendor Location Services
        /// <summary>
        /// Gets the vendor_ location_ service.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_Service(int vendorID, int vendorLocationID)
        {
            logger.InfoFormat("Trying to load Vendor Location Service Details for Vendor ID {0}", vendorLocationID);
            VendorLocationServiceAreaModel model = facade.GetServiceAreaDetails(vendorLocationID, vendorID);
            ViewData["VendorLocationID"] = vendorLocationID.ToString();

            logger.InfoFormat("Execution Finished for the Vendor Service Details with Vendor ID {0} and VendorLocationID {1}", vendorID, vendorLocationID);
            return PartialView(model);
        }

        [HttpPost]
        public ActionResult _SaveVendorLocationServiceArea(VendorLocationServiceAreaModel model)
        {

            logger.InfoFormat("VendorHomeController --> _SaveVendorLocationServiceArea :  {0}", JsonConvert.SerializeObject(new
            {
                VendorLocationID = model.VendorLocationID,
                IsAbleToCrossStateLines = model.IsAbleToCrossStateLines,
                IsUsingZipCodes = model.IsUsingZipCodes,
                IsAbleToCrossNationalBorders = model.IsAbleToCrossNationalBorders,
                IsVirtualLocationEnabled = model.IsVirtualLocationEnabled,
                PrimaryZipCodesAsCSV = model.PrimaryZipCodesAsCSV,
                SecondaryZipCodesAsCSV = model.SecondaryZipCodesAsCSV
            }));


            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            VendorManagementFacade facade = new VendorManagementFacade();
            if (model != null && model.VirtualLocations != null && model.VirtualLocations.Count > 0)
            {
                model.VirtualLocations.ForEach(x => 
                {
                    if (!string.IsNullOrEmpty(x.LocationAddress) && x.LocationAddress.Equals("null"))
                    {
                        x.LocationAddress = null;
                    }
                    if (!string.IsNullOrEmpty(x.LocationCity) && x.LocationCity.Equals("null"))
                    {
                        x.LocationCity = null;
                    }
                    if (!string.IsNullOrEmpty(x.LocationStateProvince) && x.LocationStateProvince.Equals("null"))
                    {
                        x.LocationStateProvince = null;
                    }
                    if (!string.IsNullOrEmpty(x.LocationCountryCode) && x.LocationCountryCode.Equals("null"))
                    {
                        x.LocationCountryCode = null;
                    }
                    if (!string.IsNullOrEmpty(x.LocationPostalCode) && x.LocationPostalCode.Equals("null"))
                    {
                        x.LocationPostalCode = null;
                    }
                });
            }
            facade.SaveServiceAreaDetails(model, LoggedInUserName);

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion

        #region Vendor Location Rates
        /// <summary>
        /// Gets the vendor_ location_ rates.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_Rates(int vendorID, int vendorLocationID)
        {
            logger.InfoFormat("Trying to load Vendor Location Rates Details for Vendor ID {0}", vendorLocationID);
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                PageSize = 10
            };
            ViewData["VendorLocationID"] = vendorLocationID.ToString();
            ViewData["VendorID"] = vendorID.ToString();
            List<VendorLocationRatesAndServices_Result> ratesList = null;
            ViewData["VendorLocationServices"] = facade.GetVendorLocationServices().ToSelectListItem<Product>(x => x.ID.ToString(), y => y.Name, true);
            ViewData["VendorContracts"] = facade.GetVendorContracts(vendorID).ToSelectListItem<Contract>(x => x.ID.ToString(), y => y.StartDate.ToString(), true);
            return PartialView(ratesList);
        }


        /// <summary>
        /// _Get vendor location rates list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public ActionResult _SelectVLRDetails([DataSourceRequest] DataSourceRequest request, int vendorLocationID, int? rateScheduleID)
        {
            logger.InfoFormat("Inside _GetVendorLocationRatesList of VendorHomeController. Attempt to get all the Rates depending upon the GridCommand and VendorLocationID:{0}", vendorLocationID);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Name";
            string sortOrder = "ASC";
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
            List<VendorServicesAndRates_Result> ratesList = new List<VendorServicesAndRates_Result>();
            if (rateScheduleID != null)
            {
                ratesList = facade.GetVendorLocationServicesAndRates(vendorLocationID, rateScheduleID.GetValueOrDefault());
            }

            ViewData["VendorLocationServices"] = facade.GetVendorLocationServices().ToSelectListItem<Product>(x => x.ID.ToString(), y => y.Name, false);
            logger.InfoFormat("Call the view by sending {0} number of records", ratesList.Count);

            var result = new DataSourceResult()
            {
                Data = ratesList
            };
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the update VLR details.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="vendorLocationRatesAndService">The vendor location rates and service.</param>
        /// <returns></returns>
        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _UpdateVLRDetails([DataSourceRequest] DataSourceRequest request, int vendorLocationID, int rateScheduleID, VendorLocationRatesAndServices_Result vendorLocationRatesAndService)
        {
            OperationResult result = new OperationResult();
            facade.UpdateVLRDetails(vendorLocationID, vendorLocationRatesAndService, LoggedInUserName, rateScheduleID);
            result.Status = "Success";

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult _VendorLocation_ViewChangeLog(int RateScheduleID, int? VendorLocationID)
        {
            ViewData["vendorLocationID"] = VendorLocationID.HasValue ? VendorLocationID.Value.ToString() : string.Empty;

            ViewData["rateScheduleID"] = RateScheduleID;
            PageCriteria pageCriteria = new PageCriteria()
            {
                PageSize = 10,
                StartInd = 1,
                EndInd = 10
            };
            List<VendorLocationContractRateScheduleProductLog_Result> list = new List<VendorLocationContractRateScheduleProductLog_Result>();

            facade.GetVendorLocationContractRateScheduleProductLog(pageCriteria, RateScheduleID, VendorLocationID);

            return View(list);
        }

        public ActionResult _GetVendorLocationViewChangeLog([DataSourceRequest] DataSourceRequest request, int? VendorLocationId, int rateScheduleID)
        {
            logger.InfoFormat("Inside _GetVendorLocationViewChangeLog of VendorHomeController. Attempt to get all the ChangeLog  depending upon the GridCommand and VendorLocationID:{0}", VendorLocationId);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ID";
            string sortOrder = "ASC";
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
            List<VendorLocationContractRateScheduleProductLog_Result> list = facade.GetVendorLocationContractRateScheduleProductLog(pageCriteria, rateScheduleID, VendorLocationId);

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
            return Json(result, JsonRequestBehavior.AllowGet);

        }
        #endregion

        #region Vendor Location Equipment
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Location_Equipment(int vendorID, int vendorLocationID)
        {
            logger.InfoFormat("Trying to load Vendor Location Equipment for Vendor ID {0}", vendorLocationID);
            return PartialView(vendorLocationID);
        }
        #endregion
        #endregion

        #region Individual Tab Load Methods for the Vendor

        #region Vendor Tabs
        /// <summary>
        /// Gets the vendor tabs.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _VendorTabs(int vendorID)
        {
            logger.InfoFormat("Inside _VendorTabs() model with Vendor ID:{0}", vendorID);
            VendorDetailsModel model = new VendorDetailsModel();
            model.BasicInformation = facade.Get(vendorID);
            model.VendorLocationID = 0;
            model.WebAccountInfo = facade.GetVendorWebAccountInformation(vendorID);
            logger.InfoFormat("Returns the View _VendorTabs with Model:{0} ", model);
            return View(model);
        }
        #endregion

        #region Vendor Information
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveVendorInformationWebAccount(VendorWebAccountInfoModel model)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Trying to Update Vendor Web Account Details for Vendor ID {0}", model.VendorID.GetValueOrDefault());
            facade.UpdateVendorWebAccount(LoggedInUserName, model);
            logger.Info("Update Vendor Web Account Details Updated");
            return Json(result);
        }


        /// <summary>
        /// _s the vendor_ information.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.VendorStatus, true)]
        [ReferenceDataFilter(StaticData.VendorChangeReason, true)]
        [ReferenceDataFilter(StaticData.VendorInfoTaxClassification, true)]
        [ReferenceDataFilter(StaticData.DispatchSoftwareProduct, true)]
        //[ReferenceDataFilter(StaticData.DriverSoftwareProduct, true)]
        [ReferenceDataFilter(StaticData.DispatchGPSNetwork, true)]
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Information(int vendorID)
        {
            logger.InfoFormat("Trying to load Vendor Information Details for Vendor ID {0}", vendorID);
            VendorDetailsModel model = new VendorDetailsModel();
            var lookUpRepository = new CommonLookUpRepository();
            model.BasicInformation = facade.Get(vendorID);
            if (model.BasicInformation.VendorRegionID.HasValue)
            {
                model.VendorRegion = lookUpRepository.GetVendorRegionByID(model.BasicInformation.VendorRegionID.Value);
            }
            model.OldVendorStatusID = model.BasicInformation.VendorStatusID;
            model.OldIsLevyActive = model.BasicInformation.IsLevyActive;
            model.VendorLocationID = 0;
            model.WebAccountInfo = facade.GetVendorWebAccountInformation(vendorID);
            logger.InfoFormat("Execution Finished for the Vendor information Details with Vendor ID {0}", vendorID);
            return PartialView(model);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _VendorInformation_WebAccount(int vendorID)
        {
            logger.InfoFormat("Trying to load Vendor Web Account Info View for Vendor ID {0}", vendorID);
            VendorDetailsModel model = new VendorDetailsModel();
            var lookUpRepository = new CommonLookUpRepository();
            model.BasicInformation = facade.Get(vendorID);
            model.WebAccountInfo = facade.GetVendorWebAccountInformation(vendorID);
            logger.InfoFormat("Execution Finished for the Vendor Web Account View Details with Vendor ID {0}", vendorID);
            return PartialView(model);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _VendorInformation_WebAccountEdit(int vendorID)
        {
            logger.InfoFormat("Trying to load Vendor Web Account Edit mode for Vendor ID {0}", vendorID);
            var lookUpRepository = new CommonLookUpRepository();
            VendorWebAccountInfoModel model = facade.GetVendorWebAccountInformation(vendorID);
            model.VendorID = vendorID;
            logger.InfoFormat("Execution Finished for the Vendor Web Account Edit Mode Details with Vendor ID {0}", vendorID);
            return PartialView(model);
        }


        /// <summary>
        /// Saves the vendor information section.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveVendorInformationSection(VendorDetailsModel model)
        {
            OperationResult result = new OperationResult();

            #region Verify Levy Address In Case Levy is Selected

            if (model.BasicInformation.IsLevyActive.GetValueOrDefault() == true)
            {
                logger.InfoFormat("Trying to check Levy Address exis or not for Vendor ID {0}", model.BasicInformation.ID);
                AddressRepository repository = new AddressRepository();
                List<AddressEntity> addressList = repository.GetAddresses(model.BasicInformation.ID, EntityNames.VENDOR, AddressTypeNames.LEVY);
                if (addressList == null || addressList.Count == 0)
                {
                    result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                    return Json(result);
                }
            }
            #endregion

            logger.Info("Executing Save Vendor Information Section");
            var facade = new VendorManagementFacade();
            facade.UpdateVendorInformation(model.BasicInformation, LoggedInUserName, model.OldVendorStatusID, model.ChangeResonID, model.ChangeReasonComments, model.ChangedReasonOther, model.VendorLocationID, model.OldIsLevyActive);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Finished Save Vendor Information Section");
            return Json(result);
        }

        #endregion

        #region Vendor ACH

        /// <summary>
        /// _s the vendor_ information_ ACH.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ACHAccountType, true)]
        [ReferenceDataFilter(StaticData.ACHStatus, true)]
        [ReferenceDataFilter(StaticData.RecieptMethodForACH, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Information_ACH(int vendorID)
        {
            logger.InfoFormat("Trying to load Vendor ACH Details for Vendor ID {0}", vendorID);
            PhoneFacade phoneFacade = new PhoneFacade();
            string[] excludedItems = new string[] { 
                
                PhoneTypeNames.Home, 
                PhoneTypeNames.Work,
                PhoneTypeNames.Cell, 
                PhoneTypeNames.Fax, 
                PhoneTypeNames.Dispatch, 
                PhoneTypeNames.Office, 
                PhoneTypeNames.Other, 
                PhoneTypeNames.Insurance, 
            };
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR, excludedItems).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            var facade = new VendorManagementFacade();
            VendorACHModel model = facade.GetVendorACHDetails(vendorID);

            #region Set Default Phone Type to Bank
            PhoneType bankPhoneType = phoneFacade.GetPhoneTypeByName(PhoneTypeNames.BANK);
            #endregion

            if (model.VendorACHDetails != null && model.VendorACHDetails.BankAddressCountryID.HasValue)
            {
                ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(model.VendorACHDetails.BankAddressCountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            }
            logger.InfoFormat("Execution Finished for the Vendor ACH Details with Vendor ID {0}", vendorID);
            return PartialView(model);
        }

        /// <summary>
        /// Saves the vendor ACH section.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveVendorACHSection(VendorACHModel model)
        {
            logger.Info("Executing Save Vendor ACH Section");
            OperationResult result = new OperationResult();
            var facade = new VendorManagementFacade();
            facade.UpdateVendorACHInformation(model, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Finished Save Vendor ACH Section");
            return Json(result);
        }

        #endregion

        #region Vendor Service
        /// <summary>
        /// _s the vendor_ service.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Service(int vendorID)
        {
            logger.InfoFormat("Trying to load Vendor Service Details for Vendor ID {0}", vendorID);
            VendorServiceModel model = new VendorServiceModel();
            model = facade.GetVendorServiceDetails(vendorID);
            logger.InfoFormat("Execution Finished for the Vendor Service Details with Vendor ID {0}", vendorID);
            return PartialView(model);
        }

        /// <summary>
        /// Saves the vendor services.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult SaveVendorServices(VendorServiceModel model)
        {
            OperationResult result = new OperationResult();
            try
            {

                logger.InfoFormat("Trying to Save Vendor Service Information with Vendor ID:{0}", model.VendorID);
                facade.SaveVendorServices(model, LoggedInUserName);
                logger.InfoFormat("Added Vendor Services and Repairs Successfully");
                result.Status = "Success";
            }
            catch (Exception Ex)
            {
                logger.Info(Ex);
                result.Status = "Failure";
                result.ErrorMessage = Ex.ToString();
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

        #region Vendor Locations
        /// <summary>
        /// Gets the vendor locations.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public ActionResult _Vendor_Locations(int vendorID)
        {
            logger.Info("Call the View '_VendorLocations'");
            return View(vendorID);
        }

        /// <summary>
        /// Gets the vendor locations.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="VendorId">The vendor id.</param>
        /// <returns></returns>
        public ActionResult _GetVendorLocations([DataSourceRequest] DataSourceRequest request, int? VendorId)
        {
            logger.Info("Inside _GetVendorLocations() of VendorHomeController. Attempt to get all Vendor Locations depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "LocationAddress";
            string sortOrder = "ASC";
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
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorLocations_Result> list = facade.GetVendorLocations(pageCriteria, VendorId);

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
        /// Deletes the vendor location.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public ActionResult DeleteVendorLocation(int vendorLocationID)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside DeleteVendorLocation() of VendorHomeController with the vendorLocationID {0}", vendorLocationID);
            if (ModelState.IsValid)
            {
                // delete data                    
                facade.DeleteVendorLocation(vendorLocationID);
                logger.InfoFormat("The record with vendorLocationID {0} has been Deleted", vendorLocationID);
                result.OperationType = "Success";
                result.Status = "Success";
                return Json(result);
            }
            var errorList = GetErrorsFromModelStateAsString();
            logger.Error(errorList);
            throw new DMSException(errorList);
        }

        /// <summary>
        /// Adds the vendor location.
        /// </summary>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult AddVendorLocation(int? VendorID)
        {
            logger.Info("Attempting to add a vendor location");
            ViewData["VendorId"] = VendorID;
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);


            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortColumn = "ID",
                SortDirection = "ASC",
                PageSize = 10
            };
            VendorManagementFacade facade = new VendorManagementFacade();

            IEnumerable<SelectListItem> list = facade.GetVendorLocations(pageCriteria, VendorID).ToSelectListItem(x => x.VendorLocation.ToString(), y => y.LocationAddress + ", " + y.StateProvince + " " + y.PostalCode + " " + y.CountryCode, true);
            ViewData[StaticData.LocationList.ToString()] = new SelectList(list, "Value", "Text");

            logger.Info("Return Partial View '_AddVendorLocation'");
            return PartialView("_AddVendorLocation");
        }

        /// <summary>
        /// Saves the vendor location.
        /// </summary>
        /// <param name="VendorLocation">The vendor location.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveVendorLocation(VendorLocationModel VendorLocation)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Adding a vendor location with Name:{0}", VendorLocation.LocationName);
            int VendorID = VendorLocation.VendorID;
            var currentUser = LoggedInUserName;
            VendorManagementFacade facade = new VendorManagementFacade();
            int VendorLocationID = facade.SaveVendorLocationAddress(VendorLocation, VendorID, currentUser);

            //  Add Event log record for Add Vendor.
            result.Data = VendorLocationID;
            var eventLoggerFacade = new EventLoggerFacade();
            long eventlogId = eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.ADD_VENDOR_LOCATION, "Add Vendor Location", currentUser, VendorLocationID, EntityNames.VENDOR_LOCATION, Session.SessionID);
            eventLoggerFacade.CreateRelatedLogLinkRecord(eventlogId, VendorID, EntityNames.VENDOR);
            // Event Log Adding Completed.

            logger.InfoFormat("Added Vendor Location Added successfully with Vendor ID:{0} and Vendor Location ID:{1} ", VendorID, VendorLocationID);

            result.Status = "Success";
            return Json(result);
        }

        /// <summary>
        /// Binds the vendor locations.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public ActionResult BindVendorLocations(int vendorID)
        {
            logger.InfoFormat("Get Vendor Locations related to the Vendor whose ID is :{0} ", vendorID);

            IEnumerable<SelectListItem> list = facade.GetVendorLocationsList(vendorID).OrderBy(x => x.VendorLocationID).ToSelectListItem(x => x.VendorLocationID.ToString(), y => y.LocationAddress, false);
            logger.InfoFormat("Get the Vendor Locations of count:{0}", list.Count());
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the vendor location address.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public ActionResult GetVendorLocationAddress(int vendorLocationID)
        {
            logger.InfoFormat("Inside the GetVendorLocationAddress() method with Vendor Location ID:{0}", vendorLocationID);
            OperationResult result = new OperationResult();
            result.Data = facade.GetVendorLocationAddress(vendorLocationID);
            result.Status = "Success";
            logger.InfoFormat("Gets the Address of Vendor Location ID:{0}", vendorLocationID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

        #region Vendor PO

        /// <summary>
        /// Gets the Vendor_ PO_ History.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public ActionResult _Vendor_PO_History(int vendorID)
        {
            logger.Info("Call the View '_Vendor_PO_History'");
            return View(vendorID);
        }

        /// <summary>
        /// Gets the vendor PO List
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="VendorId">The vendor id.</param>
        /// <returns></returns>
        public ActionResult _GetVendorPO([DataSourceRequest] DataSourceRequest request, int VendorId)
        {
            logger.InfoFormat("Inside _GetVendorPO of VendorHomeController. Attempt to get all the POs depending upon the GridCommand and Vendor ID:{0}", VendorId);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "PurchaseOrderNumber";
            string sortOrder = "ASC";
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
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorPOList_Result> list = facade.GetVendorPODetails(pageCriteria, VendorId);

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
            return Json(result, JsonRequestBehavior.AllowGet);

        }
        #endregion

        #region Vendor Contract
        /// <summary>
        /// _s the vendor_ contract.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ContractStatus, false)]
        [ReferenceDataFilter(StaticData.VendorTermAgreements, false)]
        public ActionResult _Vendor_Contract(int vendorID)
        {
            logger.Info("Call the View '_Vendor_Contract'");
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortColumn = "StartDate",
                SortDirection = "DESC",
                PageSize = 10
            };
            List<VendorContractList_Result> vendorContractList = facade.GetVendorContractList(pageCriteria, vendorID);
            int totalRows = 0;
            if (vendorContractList.Count > 0)
            {
                totalRows = vendorContractList[0].TotalRows.Value;
            }

            int latestVendorContractID = 0;
            VendorContractDetails_Result latestVendorContractDetails = new VendorContractDetails_Result();
            ViewBag.latestContract = latestVendorContractDetails;
            ViewBag.ISContractsAvailable = "false";
            if (totalRows > 0)
            {
                latestVendorContractID = vendorContractList[0].ID.Value;
                latestVendorContractDetails = facade.GetVendorContractDetails(latestVendorContractID);
                ViewBag.latestContract = latestVendorContractDetails;
                ViewBag.ISContractsAvailable = "true";
            }
            ViewBag.Mode = "View";
            ViewData["vendorID"] = vendorID.ToString();
            SetVendorTAasJSON();
            logger.InfoFormat("Calling the View with {0} records", totalRows);
            return View(vendorContractList);
        }

        /// <summary>
        /// Gets vendor contract list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="VendorId">The vendor id.</param>
        /// <returns></returns>
        public ActionResult _GetVendorContractList([DataSourceRequest] DataSourceRequest request, int VendorId)
        {
            logger.InfoFormat("Inside _GetVendorContractList of VendorHomeController. Attempt to get all the Vendor Contracts depending upon the GridCommand and Vendor ID:{0}", VendorId);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "PurchaseOrderNumber";
            string sortOrder = "ASC";
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
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorContractList_Result> list = facade.GetVendorContractList(pageCriteria, VendorId);
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
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// Gets the vendor_ contract_ details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="contractID">The contract ID.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ContractStatus, false)]
        [ReferenceDataFilter(StaticData.VendorTermAgreements, false)]
        public ActionResult _Vendor_Contract_Details(int? vendorID, int? contractID, string mode)
        {
            logger.InfoFormat("Inside _Vendor_Contract_Details() method in Vendor Home Controller to get contract details with Contract ID:{0}", contractID);
            VendorContractDetails_Result result = new VendorContractDetails_Result();
            result.ContractStatusID = facade.GetContractStatusID("Pending");
            result.VTAID = facade.GetLatestVTA();
            if (contractID > 0)
            {
                result = facade.GetVendorContractDetails(contractID.Value);
            }
            ViewData["vendorID"] = vendorID.ToString();
            SetVendorTAasJSON();
            ViewBag.Mode = mode;
            return PartialView(result);
        }

        private void SetVendorTAasJSON()
        {
            var terms = ReferenceDataRepository.GetVendorTermAgreements();
            StringBuilder jsonTerms = new StringBuilder();
            (new JavaScriptSerializer()).Serialize(terms, jsonTerms);
            ViewData["JSON_VendorTermAgreements"] = jsonTerms.ToString();
        }

        /// <summary>
        /// Saves the vendor contract details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="data">The data.</param>
        /// <returns></returns>
        public ActionResult SaveVendorContractDetails(VendorContractDetails_Result data)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside SaveVendorContractDetails() method to save the details of Vendor Contract ID:{0} ", data.ID);
            int ContractID = facade.SaveVendorContractDetails(data, LoggedInUserName);
            logger.Info("Contract Saved Successfully");
            if (data.ID <= 0)
            {
                var eventLoggerFacade = new EventLoggerFacade();
                long eventlogId = eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.ADD_CONTRACT, "Add Vendor Contract", LoggedInUserName, data.VendorID, EntityNames.VENDOR, Session.SessionID);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventlogId, ContractID, EntityNames.CONTRACT);
            }
            result.Data = ContractID;
            logger.Info("Saved Successfully");
            result.Status = "Success";

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Deletes the vendor contract.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="contractID">The contract ID.</param>
        /// <returns></returns>
        public ActionResult DeleteVendorContract(int vendorID, int contractID)
        {
            logger.InfoFormat("Inside DeleteVendorContract() method to delete the contract with ID:{1} and vendor ID:{0}", vendorID, contractID);
            OperationResult result = new OperationResult();
            facade.DeleteVendorContract(contractID);
            logger.Info("Deleted Successfully");
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortColumn = "StartDate",
                SortDirection = "DESC",
                PageSize = 10
            };
            List<VendorContractList_Result> vendorContractList = facade.GetVendorContractList(pageCriteria, vendorID);
            int totalRows = 0;
            if (vendorContractList.Count > 0)
            {
                totalRows = vendorContractList[0].TotalRows.Value;
            }
            int latestVendorContractID = 0;
            ViewBag.ISContractsAvailable = "false";
            if (totalRows > 0)
            {
                latestVendorContractID = vendorContractList[0].ID.Value;
                ViewBag.ISContractsAvailable = "true";
            }
            result.Data = latestVendorContractID;
            logger.InfoFormat("The Contract to be shown in the details pane is with ID:{0}", latestVendorContractID);
            ViewData["vendorID"] = vendorID.ToString();

            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult GetContractID(int vendorID, int contractID)
        {
            OperationResult result = new OperationResult();

            int latestVendorContractID = contractID;
            if (contractID <= 0)
            {
                PageCriteria pageCriteria = new PageCriteria()
                {
                    StartInd = 1,
                    EndInd = 10,
                    SortColumn = "StartDate",
                    SortDirection = "DESC",
                    PageSize = 10
                };
                List<VendorContractList_Result> vendorContractList = facade.GetVendorContractList(pageCriteria, vendorID);
                int totalRows = 0;
                if (vendorContractList.Count > 0)
                {
                    totalRows = vendorContractList[0].TotalRows.Value;
                }
                ViewBag.ISContractsAvailable = "false";
                if (totalRows > 0)
                {
                    latestVendorContractID = vendorContractList[0].ID.Value;
                    ViewBag.ISContractsAvailable = "true";
                }
            }
            result.Data = latestVendorContractID;
            logger.InfoFormat("The Contract to be shown in the details pane is with ID:{0}", latestVendorContractID);
            ViewData["vendorID"] = vendorID.ToString();

            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

        #region Vendor Rates


        /// <summary>
        /// Get product configuration.
        /// </summary>
        /// <param name="productID">The product ID.</param>
        /// <returns></returns>
        public JsonResult _ProductConfiguration(int? productID)
        {
            VendorServicesAndRates_Result record = new VendorServicesAndRates_Result();
            record.ProductID = productID.GetValueOrDefault();
            OperationResult result = new OperationResult();
            result.Data = record;
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// _s the vendor_ rates.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.VendorContractRateScheduleStatus, true)]
        public ActionResult _Vendor_Rates(int vendorID)
        {
            logger.InfoFormat("Trying to Load Vendor Rate Tab for the Vendor ID {0}", vendorID);
            VendorRatesModel model = facade.GetVendorRates(vendorID, null);
            model.VendorID = vendorID;
            model.Mode = "View";
            int? currentRateSchedueID = null;
            if (model.CurrentRateSchedule != null)
            {
                currentRateSchedueID = model.CurrentRateSchedule.ContractRateScheduleID;
            }
            ViewData["VendorServices"] = facade.GetVendorProducts(vendorID).ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, false);

            logger.Info("Record retrieved successfully");
            return PartialView(model);
        }

        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.VendorContractRateScheduleStatus, true)]
        public ActionResult _Vendor_Rates_Details(int vendorID, int contractRateScheduleID, string mode, int? contractID = null)
        {
            logger.InfoFormat("Trying to retrieve details for Vendor Rate and Schedules with ID {0} and mode {1}", contractRateScheduleID, mode);
            VendorRatesModel model = null;
            if (mode.Equals("Add", StringComparison.OrdinalIgnoreCase))
            {
                // Save the ContractRateSchedule with default values and load the form + the services grid.
                contractRateScheduleID = facade.CreateContractRateScheduleRecord(vendorID, contractID.Value, LoggedInUserName);
                model = facade.GetVendorRates(0, contractRateScheduleID, contractID.Value, false);

                // Get the services and rates too.

                model.Mode = "Edit"; // This is to present the form in editable mode.
                model.VendorID = vendorID;
            }
            else
            {
                model = facade.GetVendorRates(vendorID, contractRateScheduleID, contractID, false);

                model.VendorID = vendorID;
                model.Mode = mode;
            }
            ViewData["VendorServices"] = facade.GetVendorProducts(vendorID).ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, false);
            logger.Info("Record retrieved successfully");
            return PartialView(model);
        }

        public ActionResult _GetContractRateScheduleProducts(int? vendorID, int? contractRateScheduleID, int? productID)
        {

            IEnumerable<SelectListItem> list = facade.GetVendorProducts(vendorID.GetValueOrDefault(), contractRateScheduleID, productID).ToSelectListItem<DropDownEntity>(x => x.ID.ToString(), y => y.Name, false);
            return Json(list, JsonRequestBehavior.AllowGet);

        }

        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.VendorContractRateScheduleStatus, true)]
        public ActionResult _Vendor_Rates_Add(int vendorID)
        {
            VendorManagementRepository vendorManagement_Repository = new VendorManagementRepository();
            logger.InfoFormat("Trying to create Vendor Rate and Schedule for the Vendor ID {0}", vendorID);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;

            // Step 1 : Check Vendor Contract Count
            int contractCount = facade.GetVendorContractCount(vendorID);
            Contract contractDetails = facade.GetContactByVendorID(vendorID);
            if (contractCount <= 0)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.Data = new { ContractCount = contractCount };
                logger.InfoFormat("Found {0} contracts", contractCount);
            }
            else if (contractCount > 1)
            {
                // Multiple Contract Found so let the user to select a Contact ID
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.Data = new { ContractCount = contractCount };
                logger.InfoFormat("Found {0} contracts", contractCount);
            }
            else
            {
                if (contractDetails == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Contract for the Vendor ID {0}", vendorID));
                }
                result.Data = new { ContractID = contractDetails.ID };
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// _Get vendor location rates list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public ActionResult _SelectVSRDetails([DataSourceRequest] DataSourceRequest request, int? contractID, int? contractRateScheduleID)
        {
            var repository = new VendorManagementRepository();
            List<VendorServicesAndRates_Result> ratesList = repository.GetVendorServicesAndRates(contractRateScheduleID.GetValueOrDefault(), null);
            var result = new DataSourceResult()
            {
                Data = ratesList
            };
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the insert VLR details.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="vendorLocationRatesAndService">The vendor location rates and service.</param>
        /// <returns></returns>
        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _InsertVSRDetails([DataSourceRequest] DataSourceRequest request, int? contractID, int? contractRateScheduleID, VendorServicesAndRates_Result vendorServicesAndRates)
        {
            OperationResult result = new OperationResult();
            facade.InsertVendorServiceRates(vendorServicesAndRates, LoggedInUserName, contractRateScheduleID.Value);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the update VLR details.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="vendorLocationRatesAndService">The vendor location rates and service.</param>
        /// <returns></returns>
        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _UpdateVSRDetails([DataSourceRequest] DataSourceRequest request, int? contractID, int? contractRateScheduleID, VendorServicesAndRates_Result vendorServicesAndRates)
        {
            OperationResult result = new OperationResult();
            result.Status = "Success";
            facade.UpdateVendorRates(vendorServicesAndRates, LoggedInUserName, contractRateScheduleID.GetValueOrDefault());
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the delete VLR details.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="vendorLocationRatesAndService">The vendor location rates and service.</param>
        /// <returns></returns>
        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _DeleteVSRDetails([DataSourceRequest] DataSourceRequest request, int? contractID, int? contractRateScheduleID, VendorServicesAndRates_Result vendorServicesAndRates)
        {
            OperationResult result = new OperationResult();
            result.Status = "Success";
            facade.DeleteVendorRates(vendorServicesAndRates, LoggedInUserName);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Rates_ExistingContracts(int vendorID)
        {
            logger.InfoFormat("Trying to laod existing contract details for the Vendor ID {0}", vendorID);
            ViewData[StaticData.VendorRatesExistingContract.ToString()] = facade.GetExistingContractsForVendor(vendorID).ToSelectListItem(u => u.ID.ToString(), y => y.StartDate.Value.ToShortDateString(), true);
            logger.Info("Retrieved success");
            return PartialView(vendorID);
        }

        /// <summary>
        /// Deletes the vendor rate schedule.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="contractRateScheduleID">The contract rate schedule ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult DeleteVendorRateSchedule(int vendorID, int contractRateScheduleID)
        {
            logger.InfoFormat("Trying to delete Vendor Rate Schedule for Contract Rate Schedule ID {0}", contractRateScheduleID);
            OperationResult result = new OperationResult();
            try
            {
                result.Status = OperationStatus.SUCCESS;
                facade.DeleteVendorRateAndSchedules(contractRateScheduleID);
                logger.Info("Record delete successfully");
            }
            catch (DMSException ex)
            {
                result.ErrorMessage = ex.Message;
                result.Status = OperationStatus.ERROR;
                logger.InfoFormat("Error while deleting the record {0}", ex.Message);
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Saves the vendor rate schedule.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [HttpPost]
        public ActionResult SaveVendorRateSchedule(VendorRatesModel model)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat(string.Format("Trying to update Vendor Rate Schedule with ID {0}", model.CurrentRateSchedule.ContractRateScheduleID));
            facade.SaveContractRateSchedule(model, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        /// <summary>
        /// Vendors the rate and schedules list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="VendorId">The vendor id.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult VendorRateAndSchedulesList([DataSourceRequest] DataSourceRequest request, int VendorId)
        {
            logger.Info("Inside VendorRateAndSchedulesList of VendorHomeController. Attempt to get all Rate and Schedules depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "StartDate";
            string sortOrder = "DESC";
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
            VendorManagementFacade facade = new VendorManagementFacade();
            List<Vendor_Rates_Schedules_Result> list = facade.GetVendorRatesAndSchedules(pageCriteria, VendorId);

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
        #endregion
        #endregion

        #region Welcome Message
        [HttpPost]
        public ActionResult _SendWelcomeMessage(int? vendorID)
        {

            Vendor vendor = facade.Get(vendorID.GetValueOrDefault());
            VendorUser vendorUser = null;
            if (vendor.VendorUsers != null && vendor.VendorUsers.Count > 0)
            {
                vendorUser = vendor.VendorUsers.FirstOrDefault();
            }

            string contactFirstName = vendor.ContactFirstName;
            string contactLastName = vendor.ContactLastName;

            if (string.IsNullOrEmpty(contactFirstName))
            {
                if (vendorUser != null)
                {
                    contactFirstName = vendorUser.FirstName;
                }
            }

            if (string.IsNullOrEmpty(contactLastName))
            {
                if (vendorUser != null)
                {
                    contactLastName = vendorUser.LastName;
                }
            }
            
            EmailService emailService = new EmailService();
            Hashtable context = new Hashtable();
            context.Add("url", string.Format("{0}://{1}", Request.Url.Scheme, Request.Url.Authority));
            context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER).GetFormattedPhoneNumber() ?? string.Empty);
            context.Add("fax", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_FAX_NUMBER) ?? string.Empty );
            context.Add("UserFirst", contactFirstName ?? string.Empty);
            context.Add("UserLast", contactLastName ?? string.Empty);
            context.Add("user", vendor.VendorNumber);

            #region Contact Log, Action , Reason and Link

            #endregion

            //TODO:Set from name and email to vendor rep email and name
            VendorRegion vendorRep = vendor.VendorRegion;
            string toDisplayName = string.Empty;
            string fromDisplayName = string.Empty;
            string fromAddress = string.Empty;
            if (vendorRep != null)
            {
                fromDisplayName = string.Join(" ", vendorRep.ContactFirstName, vendorRep.ContactLastName);
                fromAddress = vendorRep.Email;
                context.Add("RegionName", vendorRep.Name);
                context.Add("ContactFirstName", vendorRep.ContactFirstName ?? string.Empty);
                context.Add("ContactLastName", vendorRep.ContactLastName ?? string.Empty);
                context.Add("Email", vendorRep.Email ?? string.Empty);
                context.Add("PhoneNumber", vendorRep.PhoneNumber.GetFormattedPhoneNumber());
                
            }
            else
            {
                context.Add("ContactFirstName", string.Empty);
                context.Add("ContactLastName", string.Empty);
                context.Add("Email", string.Empty);
                context.Add("PhoneNumber", string.Empty);
                context.Add("RegionName", string.Empty);
            }

            toDisplayName = string.Join(" ", vendor.ContactFirstName, vendor.ContactLastName);
            emailService.SendEmail(context, vendor.Email, TemplateNames.VENDOR_WELCOME, fromAddress, fromDisplayName, toDisplayName.Trim());
            logger.InfoFormat("Email sent to {0} successfully", vendor.Email);

            var contactLogFacade = new ContactLogFacade();
            contactLogFacade.Log(ContactCategoryNames.CONTACT_VENDOR,
                "Vendor",
                ContactMethodNames.EMAIL,
                "Outbound",
                "Send Welcome Letter",
                ContactReasonName.NEW_VENDOR,
                ContactActionName.SEND_WELCOME_LETTER,
                vendor != null ? vendor.Name : "No Vendor Present",
                vendor != null ? vendor.Email : "No Vendor Present",
                LoggedInUserName,
                vendor != null ? vendor.ID : (int?)null,
                EntityNames.VENDOR);

            logger.Info("Contact Logs created successfully");
            return Json(new OperationResult(), JsonRequestBehavior.AllowGet);

        }
        #endregion

        #region Vendor Documents

        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Documents(int vendorID)
        {
            logger.InfoFormat("Trying to load documents for the  Vendor ID {0}", vendorID);
            ViewData["VendorID"] = vendorID.ToString();
            return PartialView(vendorID);
        }

        #endregion
    }
}

