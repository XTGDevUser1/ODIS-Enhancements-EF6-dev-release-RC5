using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Martex.DMS.Models;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.BLL.Model;
using Martex.DMS.Areas.Application.Models;
using Kendo.Mvc.Extensions;
using Martex.DMS.DAL.DAO; //Lakshmi
using System.Text; //Lakshmi
using System.Xml;
using Newtonsoft.Json; //Lakshmi

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class HistoryController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_HISTORY)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaIDSectionType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameSectionType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameSectionUser, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameFilterType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaDatePreset, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaVehicleType, true)]
        [ReferenceDataFilter(StaticData.Clients, false)]
        public ActionResult Index()
        {
            HistorySearchCriteria model = null;
            if (Session["HistorySearchCriteria"] != null)
            {
                model = Session["HistorySearchCriteria"] as HistorySearchCriteria;
            }
            else
            {
                model = new HistorySearchCriteria();
            }
            return View(GetModel(model));
        }

        /// <summary>
        /// Gets the search criteria restore.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaIDSectionType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameSectionType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameSectionUser, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameFilterType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaDatePreset, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaVehicleType, true)]
        [ReferenceDataFilter(StaticData.Clients, false)]
        public ActionResult GetSearchCriteriaRestore(HistorySearchCriteria model)
        {
            model = GetModel(model);
            Session["HistorySearchCriteria"] = model;
            return View("_SearchCriteria", model);
        }

        /// <summary>
        /// Gets the PO details.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult serviceRequestID(int serviceRequestID)
        {
            logger.InfoFormat("HistoryController - serviceRequestID(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                serviceRequestID = serviceRequestID
            }));
            return View("_PODetails");
        }

        /// <summary>
        /// Gets the selected search criteria.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult GetSelectedSearchCriteria(HistorySearchCriteria model)
        {
            logger.InfoFormat("HistoryController - GetSelectedSearchCriteria(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                HistorySearchCriteria = model
            }));
            model = GetModel(model);
            Session["HistorySearchCriteria"] = model;
            return View("_SelectedCriteria", model);
        }

        /// <summary>
        /// Gets the search criteria right.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaIDSectionType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameSectionType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameSectionUser, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaNameFilterType, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaDatePreset, true)]
        [ReferenceDataFilter(StaticData.HistorySearchCriteriaVehicleType, true)]
        [ReferenceDataFilter(StaticData.Clients, false)]
        public ActionResult GetSearchCriteriaRight(HistorySearchCriteria model)
        {
            logger.InfoFormat("HistoryController - GetSearchCriteriaRight(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                HistorySearchCriteria = model
            }));
            model = GetModel(model);
            ModelState.Clear();
            Session["HistorySearchCriteria"] = model;
            return View("_SearchCriteriaRight", model);
        }

        /// <summary>
        /// Gets the filter clause.
        /// </summary>
        /// <returns></returns>
        private List<NameValuePair> GetFilterClause()
        {
            HistorySearchCriteria searchCriteria = Session["HistorySearchCriteria"] as HistorySearchCriteria;
            searchCriteria = GetModel(searchCriteria);
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (searchCriteria != null)
            {
                // ID Section
                if (searchCriteria.IDSectionType.HasValue)
                {
                    filterList.Add(new NameValuePair() { Name = "IDType", Value = searchCriteria.IDSectionTypeValue });
                }
                if (!string.IsNullOrEmpty(searchCriteria.IDSectionID))
                {
                    filterList.Add(new NameValuePair() { Name = "IDValue", Value = searchCriteria.IDSectionID });
                }
                // Name Section
                if (searchCriteria.NameSectionType.HasValue)
                {
                    filterList.Add(new NameValuePair() { Name = "NameType", Value = searchCriteria.NameSectionTypeValue });
                }
                if (!string.IsNullOrEmpty(searchCriteria.NameSectionTypeISP))
                {
                    filterList.Add(new NameValuePair() { Name = "NameValue", Value = searchCriteria.NameSectionTypeISP });
                }
                if (!string.IsNullOrEmpty(searchCriteria.NameSectionTypeUser))
                {
                    filterList.Add(new NameValuePair() { Name = "NameValue", Value = searchCriteria.NameSectionTypeUser });
                }
                if (!string.IsNullOrEmpty(searchCriteria.NameSectionTypeMemberFirstName))
                {
                    filterList.Add(new NameValuePair() { Name = "NameValue", Value = searchCriteria.NameSectionTypeMemberFirstName });
                }
                if (!string.IsNullOrEmpty(searchCriteria.NameSectionTypeMemberLastName))
                {
                    filterList.Add(new NameValuePair() { Name = "LastName", Value = searchCriteria.NameSectionTypeMemberLastName });
                }
                if (searchCriteria.NameSectionFilter.HasValue)
                {
                    filterList.Add(new NameValuePair() { Name = "FilterType", Value = searchCriteria.NameSectionFilterValue });
                }
                //Date Range Section
                if (searchCriteria.DateSectionFromDate.HasValue)
                {
                    filterList.Add(new NameValuePair() { Name = "FromDate", Value = searchCriteria.DateSectionFromDate.Value.ToShortDateString() });
                }
                if (searchCriteria.DateSectionToDate.HasValue)
                {
                    filterList.Add(new NameValuePair() { Name = "ToDate", Value = searchCriteria.DateSectionToDate.Value.ToShortDateString() });
                }
                if (searchCriteria.DateSectionPreset.HasValue)
                {
                    filterList.Add(new NameValuePair() { Name = "Preset", Value = searchCriteria.DateSectionPresetValue });
                }
                // Client Section
                if (searchCriteria.ClientID != null && searchCriteria.ClientID.Count() > 0)
                {
                    var result = string.Join(",", searchCriteria.ClientID);
                    filterList.Add(new NameValuePair() { Name = "Clients", Value = result });
                }
                if (searchCriteria.ProgramID != null && searchCriteria.ProgramID.Count() > 0)
                {
                    var result = string.Join(",", searchCriteria.ProgramID);
                    filterList.Add(new NameValuePair() { Name = "Programs", Value = result });
                }

                // Service Request Section
                if (searchCriteria.ServiceRequestStatus != null && searchCriteria.ServiceRequestStatus.Count > 0)
                {
                    List<CheckBoxLookUp> result = searchCriteria.ServiceRequestStatus.Where(u => u.Selected == true).ToList();
                    if (result != null && result.Count > 0)
                    {
                        var serviceRequest = result.ToDelimitedString(u => u.ID);
                        filterList.Add(new NameValuePair() { Name = "ServiceRequestStatuses", Value = serviceRequest });
                    }
                }

                //Service Type Section
                if (searchCriteria.ServiceType != null && searchCriteria.ServiceType.Count > 0)
                {
                    List<CheckBoxLookUp> result = searchCriteria.ServiceType.Where(u => u.Selected == true).ToList();
                    if (result != null && result.Count > 0)
                    {
                        var serviceType = result.ToDelimitedString(u => u.ID);
                        filterList.Add(new NameValuePair() { Name = "ServiceTypes", Value = serviceType });
                    }
                }

                //Special Section
                if (searchCriteria.SpecialList != null && searchCriteria.SpecialList.Count == 4)
                {
                    if (searchCriteria.SpecialList[0].Selected == true)
                    {
                        filterList.Add(new NameValuePair() { Name = "IsGOA", Value = "true" });
                    }
                    if (searchCriteria.SpecialList[1].Selected == true)
                    {
                        filterList.Add(new NameValuePair() { Name = "IsRedispatched", Value = "true" });
                    }
                    if (searchCriteria.SpecialList[2].Selected == true)
                    {
                        filterList.Add(new NameValuePair() { Name = "IsPossibleTow", Value = "true" });
                    }
                }

                //Vehicle Section
                if (searchCriteria.VehicleType.HasValue)
                {
                    filterList.Add(new NameValuePair() { Name = "VehicleType", Value = searchCriteria.VehicleType.Value.ToString() });
                }
                if (!string.IsNullOrEmpty(searchCriteria.VehicleYear))
                {
                    filterList.Add(new NameValuePair() { Name = "VehicleYear", Value = searchCriteria.VehicleYear });
                }
                if (!string.IsNullOrEmpty(searchCriteria.VehicleMake))
                {
                    filterList.Add(new NameValuePair() { Name = "VehicleMake", Value = searchCriteria.VehicleMake });

                    if (!string.IsNullOrEmpty(searchCriteria.VehicleMakeOther))
                    {
                        filterList.Add(new NameValuePair() { Name = "VehicleMakeOther", Value = searchCriteria.VehicleMakeOther });
                    }
                }
                if (!string.IsNullOrEmpty(searchCriteria.VehicleModel))
                {

                    filterList.Add(new NameValuePair() { Name = "VehicleModel", Value = searchCriteria.VehicleModel });
                    if (!string.IsNullOrEmpty(searchCriteria.VehicleModelOther))
                    {
                        filterList.Add(new NameValuePair() { Name = "VehicleModelOther", Value = searchCriteria.VehicleModelOther });
                    }
                }
                //Payment Type Section

                if (searchCriteria.PaymentType != null && searchCriteria.PaymentType.Count == 3)
                {
                    if (searchCriteria.PaymentType[0].Selected == true)
                    {
                        filterList.Add(new NameValuePair() { Name = "PaymentByCheque", Value = "true" });
                    }
                    if (searchCriteria.PaymentType[1].Selected == true)
                    {
                        filterList.Add(new NameValuePair() { Name = "PaymentByCard", Value = "true" });
                    }
                    if (searchCriteria.PaymentType[2].Selected == true)
                    {
                        filterList.Add(new NameValuePair() { Name = "MemberPaid", Value = "true" });
                    }
                }

                //Purchase Order Section  
                if (searchCriteria.PurchaseOrderStatus != null && searchCriteria.PurchaseOrderStatus.Count > 0)
                {
                    List<CheckBoxLookUp> result = searchCriteria.PurchaseOrderStatus.Where(u => u.Selected == true).ToList();
                    if (result != null && result.Count > 0)
                    {
                        var purchaseOrder = result.ToDelimitedString(u => u.ID);
                        filterList.Add(new NameValuePair() { Name = "POStatuses", Value = purchaseOrder });
                    }
                }
            }


            return filterList;
        }

        /// <summary>
        /// Lists the specified request.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult List([DataSourceRequest] DataSourceRequest request)
        {
            logger.InfoFormat("HistoryController - List(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                DataSourceRequest = request
            }));
            logger.Info("Inside List() of History.");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "RequestNumber";
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
                WhereClause = string.Empty
            };

            ServiceFacade facade = new ServiceFacade();

            var filterClause = GetFilterClause();
            List<ServiceRequestHistoryList_Result> listResult = new List<ServiceRequestHistoryList_Result>();
            if (filterClause.Count > 0)
            {
                listResult = facade.GetServiceRequestHistory(pageCriteria, (Guid)GetLoggedInUser().ProviderUserKey, filterClause);
            }

            logger.InfoFormat("Call the view by sending {0} number of records", listResult.Count);
            int totalRows = 0;
            if (listResult.Count > 0)
            {
                totalRows = listResult.ElementAt(0).TotalRows.Value;
            }
            var result = new DataSourceResult()
            {
                Data = listResult,
                Total = totalRows
            };

            return Json(result);
        }



        #region PO Related Methods

        /// <summary>
        /// Determines whether [is dollar limit enable].
        /// </summary>
        /// <returns>
        ///   <c>true</c> if [is dollar limit enable]; otherwise, <c>false</c>.
        /// </returns>
        private bool IsDollarLimitEnable()
        {
            bool returnValue = false;
            string roles = ReferenceDataRepository.GetRolesThatCanChangeDollarLimit();

            roles.Split(',').ForEach(x =>
            {
                if (User.IsInRole(x))
                {
                    returnValue = true;
                }
            });
            return returnValue;
        }

        /// <summary>
        /// Determines whether [is service coverage limit enable] [the specified po].
        /// </summary>
        /// <param name="po">The po.</param>
        /// <returns></returns>
        private bool IsServiceCoverageLimitEnable(PurchaseOrder po)
        {
            decimal? coverageLimit = po.CoverageLimit ?? 0;
            bool isDollarLimitEnable = IsDollarLimitEnable();
            bool textDollarLimitReadWrite = (DMSSecurityProvider.GetAccessType(DMSSecurityProviderFriendlyName.TEXT_DOLLAR_LIMIT) == Martex.DMS.Areas.Application.Models.AccessType.ReadWrite);
            bool isServiceCoverageLimitEnable = false;
            if (coverageLimit != null && coverageLimit > 0)
            {
                if (isDollarLimitEnable)
                {
                    isServiceCoverageLimitEnable = true;
                }
            }
            else
            {
                if (textDollarLimitReadWrite)
                {
                    isServiceCoverageLimitEnable = true;
                }
            }
            return isServiceCoverageLimitEnable;
        }

        /// <summary>
        /// POs the details.
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.VehicleCategory, false)]
        [ReferenceDataFilter(StaticData.SendType, false)]
        [ReferenceDataFilter(StaticData.PODetailsProduct, true)]
        [ReferenceDataFilter(StaticData.ETA)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.MemberPayType, false)]
        [ReferenceDataFilter(StaticData.CurrencyType, false)]
        [ReferenceDataFilter(StaticData.PODetailsUOM, false)]
        [ReferenceDataFilter(StaticData.PurchaseOrderPayStatusCode, false)]
        [ReferenceDataFilter(StaticData.CommentType, false)]
        [NoCache]
        public ActionResult PODetails(int poId, string pageMode)
        {
            POFacade facade = new POFacade();
            ViewBag.PageMode = pageMode;
            ViewBag.Mode = pageMode;
            ViewBag.Client = ReferenceDataRepository.GetBillTo("Client");
            ViewBag.Member = ReferenceDataRepository.GetBillTo("Member");
            ViewBag.IsPosAvailable = true;
            PurchaseOrder po = facade.GetPOById(poId);

            //NP: 4/29 - Bug 346 - Dispatch - Request - PO - Run Service Eligibility logic upon opening a Pending PO
            if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Pending"))
            {
                po = ServiceEligibilityCheckForPO(po);
            }

            ServiceRequest serviceDetails = new ServiceFacade().GetServiceRequestById(po.ServiceRequestID);

            string loggedInUserName = GetLoggedInUser().UserName;
            QueueFacade queueFacade = new QueueFacade();
            List<ServiceRequest_Result> serviceRequestResult = queueFacade.Get(loggedInUserName, Request.RawUrl, null, po.ServiceRequestID.ToString(), false, HttpContext.Session.SessionID);
            if (serviceRequestResult != null && serviceRequestResult.Count > 0)
            {
                ViewData["AssignedTo"] = serviceRequestResult[0].AssignedTo;
                ViewData["AssignedToID"] = serviceRequestResult[0].AssignedToID;
                ViewData["CaseId"] = serviceRequestResult[0].CaseID;
                ViewData["RequestNumber"] = serviceRequestResult[0].RequestNumber;
            }
            int programID = 0;
            if (serviceDetails != null)
            {
                Case caseDetails = new CaseFacade().GetCaseById(serviceDetails.CaseID);
                if (caseDetails != null)
                {
                    programID = caseDetails.ProgramID.GetValueOrDefault();
                }
            }

            #region Setting mode and resend and reissue button visibility
            //Setting mode
            string mode = pageMode;
            ViewBag.Mode = mode;
            VendorInvoice vendorInvoice = null;
            string displayMode = mode;
            if (po.VendorInvoices.Count > 0)
            {
                vendorInvoice = facade.GetVendorInvoices(poId)[0];
            }
            if (po.AccountingInvoiceBatchID.HasValue || (vendorInvoice != null && vendorInvoice.AccountingInvoiceBatchID.HasValue))
            {
                displayMode = "view";
            }
            else if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Pending"))
            {
                displayMode = "edit";
            }
            else if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Cancelled"))
            {
                displayMode = "view";
            }
            else if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Issued" || po.PurchaseOrderStatu.Name == "Issued-Paid"))
            {
                if (vendorInvoice != null)
                {
                    displayMode = "view";
                    if (vendorInvoice.VendorInvoiceStatusID.HasValue)
                    {
                        VendorInvoiceStatu statu = ReferenceDataRepository.GetVendorInvoiceStatusById(vendorInvoice.VendorInvoiceStatusID.Value);
                        if (statu.Name.ToLower() != "paid")
                        {
                            displayMode = "edit";
                        }
                    }
                }
                else
                {
                    displayMode = "edit";
                }
            }
            ViewBag.Mode = displayMode;

            if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name != "Pending" && po.PurchaseOrderStatu.Name != "Cancelled"))
            {
                ViewBag.CanReSend = true;

            }
            else
            {
                ViewBag.CanReSend = false;
            }

            if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Issued"))
            {
                bool isReissueCC = facade.CanReissueCC(po.ID);
                ViewBag.CanReIssueCC = isReissueCC;
            }

            #endregion

            VendorInformation_Result vendorInfoResult = facade.GetVendorInformation(po.VendorLocationID.GetValueOrDefault(), po.ServiceRequestID);
            vendorInfoResult.VendorTaxID = po.VendorTaxID;
            if (po.Email != null)
            {
                vendorInfoResult.Email = po.Email;
            }
            vendorInfoResult.ContractStatus = po.ContractStatus;

            if (string.IsNullOrEmpty(po.FaxPhoneNumber) && vendorInfoResult != null)
            {
                po.FaxPhoneNumber = vendorInfoResult.FaxPhoneNumber;
            }
            ViewBag.IsOverLimit = po.TotalServiceAmount > po.CoverageLimit ? "Over limit" : string.Empty;
            ViewBag.MemberPays = po.MemberServiceAmount;
            ViewBag.CoachNetServiceAmount = po.CoachNetServiceAmount;
            ViewBag.VendorInfo = vendorInfoResult;
            ViewBag.MemberDispatchFee = facade.GetMemberPayDispatchFee(programID);
            ViewBag.InternalDispatchFee = "0";
            ViewBag.ClientDispatchFee = "0";
            ViewBag.CreditCardProcessingFee = "0";
            
            ViewBag.DispatchFeeAgentMinutes = "0";
            ViewBag.DispatchFeeTechMinutes = "0";
            ViewBag.DispatchFeeTimeCost = "0";

            ViewBag.CurrentPOrderId = po.ID;
            ViewBag.TaxAmount = po.TaxAmount;
            ViewBag.ServiceTotal = po.TotalServiceAmount;
            ViewBag.IsDealerTow = facade.IsDealTow(programID);
            ViewBag.IsPrimaryServiceCovered = po.IsServiceCovered;
            ViewBag.ServiceCoverageLimit = po.CoverageLimit ?? 0;
            ViewBag.IsDollarLimtEnable = IsDollarLimitEnable();
            ViewBag.SubTotal = po.TotalServiceAmount - po.TaxAmount;
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            if (po.IsServiceCovered.HasValue)
            {
                ViewBag.IsPrimaryServiceCovered = po.IsServiceCovered;
            }


            // NP 24/7: Added to get the count of Vendor Rates, editing strtd here
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 50,
                SortColumn = "Name",
                SortDirection = "ASC",
                PageSize = 50
            };
            int vendorLocation = po.VendorLocationID.GetValueOrDefault();


            List<VendorRates_Result> vendorRatesList = facade.GetVendorRate(pageCriteria, vendorLocation);
            string visibility = "hidden";
            if (vendorRatesList.Count > 0)
            {
                visibility = "visible";
            }
            ViewBag.visibleVendorRates = visibility;


            bool isPaymentAllowed = facade.IsPaymentAllowed(programID);
            ViewBag.IsPaymentAllowed = isPaymentAllowed;
            if (DMSCallContext.CurrentHistoryPODetails.ContainsKey(poId))
            {
                DMSCallContext.CurrentHistoryPODetails.Remove(poId);
            }
            if (po.PurchaseOrderStatu != null)
            {
                logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
            }

            //TFS Bug 219
            int? billtoId = ReferenceDataRepository.GetBillTo("Member");
            if (billtoId.HasValue && po.DispatchFeeBillToID.HasValue && billtoId.Value == po.DispatchFeeBillToID)
            {
                ViewBag.IsDispatchFeeChecked = true;
            }
            else
            {
                ViewBag.IsDispatchFeeChecked = false;
            }
            var up = GetProfile();
            bool isPoPaymentEditAllowed = facade.IsPoPaymentEditAllowed(po.ID, up.UserRoles);
            ViewBag.isPoPaymentEditAllowed = mode.ToLower() == "view" ? false : isPoPaymentEditAllowed;


            ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
            var programResult = programMaintenanceRepository.GetProgramInfo(programID, "Application", "Rule");

            var calculateMemberPayDispatchFee = programResult.Where(x => (x.Name.Equals("MemberPayDispatchFee", StringComparison.InvariantCultureIgnoreCase) && x.DataType != null && x.DataType.Equals("Query", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (calculateMemberPayDispatchFee != null)
            {
                PO_MemberPayDispatchFee_Result pOMemberPayDispatchFeeResult = ReferenceDataRepository.CalculateMemberPayDispatchFee(po.ID, po.PurchaseOrderAmount, calculateMemberPayDispatchFee.Value);
                if (pOMemberPayDispatchFeeResult != null)
                {
                    ViewBag.MemberDispatchFee = pOMemberPayDispatchFeeResult.DispatchFee.ToString();
                    ViewBag.InternalDispatchFee = pOMemberPayDispatchFeeResult.InternalDispatchFee.ToString();
                    ViewBag.ClientDispatchFee = pOMemberPayDispatchFeeResult.ClientDispatchFee.ToString();
                    ViewBag.CreditCardProcessingFee = pOMemberPayDispatchFeeResult.CreditCardProcessingFee.ToString();

                    ViewBag.DispatchFeeAgentMinutes = pOMemberPayDispatchFeeResult.DispatchFeeAgentMinutes.ToString();
                    ViewBag.DispatchFeeTechMinutes = pOMemberPayDispatchFeeResult.DispatchFeeTechMinutes.ToString();
                    ViewBag.DispatchFeeTimeCost = pOMemberPayDispatchFeeResult.DispatchFeeTimeCost.ToString();
                }
            }

            #region TFS 1214 -  Add logic to check ProgramConfiguration for how to set Mbr Pays ISP radio buttons
            var memberPaysISPDefault = programResult.Where(x => (x.Name.Equals("MemberPaysISPDefault", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (memberPaysISPDefault != null && !(string.IsNullOrEmpty(memberPaysISPDefault.Value)) && po.IsMemberAmountCollectedByVendor == null)
            {
                if (memberPaysISPDefault.Value.Equals("Yes", StringComparison.InvariantCultureIgnoreCase))
                {
                    po.IsMemberAmountCollectedByVendor = true;
                }
                else if (memberPaysISPDefault.Value.Equals("No", StringComparison.InvariantCultureIgnoreCase))
                {
                    po.IsMemberAmountCollectedByVendor = false;
                }
            }
            #endregion

            return PartialView("_PODetails", po);
        }


        public PurchaseOrder ServiceEligibilityCheckForPO(PurchaseOrder po, bool isServiceCoveredOverridden = false, bool isServiceCoverageLimitEnable = true)
        {
            POFacade poFacade = new POFacade();

            logger.InfoFormat("Service Covered Override for PO : {0}, ServiceCovered : {1}", po.ID, po.IsServiceCovered);
            //KB: Determine service eligibility and update the po attributes.
            ServiceRequest serviceDetails = poFacade.GetSRByPO(po.ID);
            Case caseObj = poFacade.GetCaseForPO(po.ID);
            int? towCategoryId = null;
            if (serviceDetails.IsPossibleTow.GetValueOrDefault())
            {
                ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                if (pc != null)
                {
                    towCategoryId = pc.ID;
                }
            }
            if (isServiceCoverageLimitEnable)
            {
                isServiceCoverageLimitEnable = IsServiceCoverageLimitEnable(po);
            }
            po.IsCoverageLimitEnabled = isServiceCoverageLimitEnable;
            var serviceFacade = new ServiceFacade();
            var serviceEligibilityModel = serviceFacade.GetServiceEligibilityModel(caseObj.ProgramID, serviceDetails.ProductCategoryID, po.ProductID, caseObj.VehicleTypeID, po.VehicleCategoryID, towCategoryId, serviceDetails.ID, caseObj.ID, SourceSystemName.DISPATCH, true, true);
            if (isServiceCoveredOverridden)
            {
                po.IsServiceCoveredOverridden = true;
                po.ServiceEligibilityMessage = "Overridden"; // TFS : 311
            }
            if (po.IsServiceCovered.GetValueOrDefault())
            {
                po.IsServiceCovered = true;

                if (serviceEligibilityModel.ServiceBenefit.Count > 0)
                {
                    var vpb = serviceEligibilityModel.ServiceBenefit.Where(x => x.IsPrimary == 1).FirstOrDefault();
                    if (vpb != null)
                    {
                        if (!isServiceCoverageLimitEnable)
                        {
                            po.CoverageLimit = vpb.ServiceCoverageLimit;
                        }
                        po.CurrencyTypeID = vpb.CurrencyTypeID;
                        po.CoverageLimitMileage = vpb.ServiceMileageLimit;
                        po.MileageUOM = vpb.ServiceMileageLimitUOM;
                        po.IsServiceCoverageBestValue = vpb.IsServiceCoverageBestValue;
                        //po.ServiceCoverageDescription = vpb.ServiceCoverageDescription;
                        po.ServiceEligibilityMessage = serviceEligibilityModel.PrimaryServiceEligiblityMessage;
                    }
                }
            }
            else
            {
                po.IsServiceCovered = false;
                if (!isServiceCoverageLimitEnable)
                {
                    //NP 7/18: TFS 311
                    po.CoverageLimit = 0;
                }
            }

            poFacade.UpdatePOServiceEligibility(po);
            return po;
        }

        [NoCache]
        [HttpPost]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.PO_BUTTON_EDIT_CCNUMBER)]
        public ActionResult SaveNewCompanyCC(int poId, string newCCValue)
        {
            JsonResult result = new JsonResult();
            POFacade facade = new POFacade();
            facade.UpdateCompanyCCNumber(poId, newCCValue, LoggedInUserName, Session.SessionID, Request.Url.AbsoluteUri);
            return Json(result);
        }

        [HttpPost]
        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.PO_BUTTON_PO_SERVICECOVERED_EDIT)]
        public ActionResult SaveServiceCovered(int poId, bool? serviceCovered, string serviceCoveredOverridenInstructions)
        {
            logger.Info("Inside SaveServiceCovered() of HistoryController.");
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            POFacade facade = new POFacade();
            facade.SaveServiceCovered(poId, serviceCovered.Value, LoggedInUserName, Request.RawUrl, Session.SessionID, serviceCoveredOverridenInstructions);
            return Json(result);
        }

        /// <summary>
        /// _s the select PO details.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="poID">The po ID.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult _SelectPODetails([DataSourceRequest] DataSourceRequest request, int? poID)
        {
            logger.Info("PO Details Retrieving for: " + poID.GetValueOrDefault().ToString());
            List<PurchaseOrderDetailsModel> poDetailsModel = new List<PurchaseOrderDetailsModel>();
            List<PODetailItemByPOId_Result> poDetails = new List<PODetailItemByPOId_Result>();
            POFacade facade = new POFacade();
            if (poID.HasValue)
            {
                poDetails = facade.GetPurchaseOrderDetails(poID.Value);
                foreach (PODetailItemByPOId_Result item in poDetails)
                {
                    PurchaseOrderDetailsModel model = new PurchaseOrderDetailsModel(item);
                    poDetailsModel.Add(model);
                }
                if (DMSCallContext.CurrentHistoryPODetails.ContainsKey(poID.Value))
                {
                    DMSCallContext.CurrentHistoryPODetails[poID.Value] = poDetailsModel;
                }
                else
                {
                    Dictionary<int, List<PurchaseOrderDetailsModel>> details = DMSCallContext.CurrentHistoryPODetails;
                    details.Add(poID.Value, poDetailsModel);
                    DMSCallContext.CurrentHistoryPODetails = details;
                }

                return Json(new DataSourceResult()
                {
                    Data = poDetailsModel.Where(po => po.Mode != "Deleted").Select(x => new
                    {
                        x.ID,
                        x.PurchaseOrderID,
                        x.ProductID,
                        x.Sequence,
                        Product = new { ID = x.Product.ID, Name = x.Product.Name },
                        x.ProductRateID,
                        RateType = new { ID = x.RateType.ID, Description = x.RateType.Description },
                        x.Quantity,
                        x.UnitOfMeasure,
                        x.Rate,
                        x.IsMemberPay,
                        x.ExtendedAmount
                    })
                });
            }
            logger.Info("PO Details Retrived for " + poID.GetValueOrDefault().ToString());
            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetail>() });
        }

        /// <summary>
        /// Inserts the PO details.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="poID">The po ID.</param>
        /// <returns></returns>
        [NoCache]
        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _InsertPODetails([DataSourceRequest] DataSourceRequest request, int? poID)
        {
            List<PurchaseOrderDetailsModel> poDetailsList = new List<PurchaseOrderDetailsModel>();
            if (DMSCallContext.CurrentHistoryPODetails.ContainsKey(poID.Value))
            {
                poDetailsList = DMSCallContext.CurrentHistoryPODetails[poID.Value];
            }
            else
            {
                Dictionary<int, List<PurchaseOrderDetailsModel>> details = DMSCallContext.CurrentHistoryPODetails;
                details.Add(poID.Value, poDetailsList);
                DMSCallContext.CurrentHistoryPODetails = details;
            }
            try
            {
                PurchaseOrderDetailsModel poOrderDetails = new PurchaseOrderDetailsModel();
                POFacade facade = new POFacade();
                poOrderDetails.Product = new Product();

                if (TryUpdateModel<PurchaseOrderDetailsModel>(poOrderDetails))
                {
                    var itemInList = poDetailsList.Where(x => x.Sequence == poOrderDetails.Sequence).FirstOrDefault();
                    poOrderDetails.Product = facade.GetProductByID(poOrderDetails.ProductID.Value);
                    if (poOrderDetails.ProductRateID.HasValue)
                    {
                        poOrderDetails.RateType = facade.GetRatetypeByID(poOrderDetails.ProductRateID.Value);
                    }
                    else
                    {
                        poOrderDetails.RateType = new RateType();
                        poOrderDetails.RateType.Description = string.Empty;
                    }
                    poOrderDetails.UserName = LoggedInUserName;
                    poOrderDetails.Mode = "Insert";
                    poOrderDetails.PurchaseOrderID = poID.Value;
                    if (itemInList == null)
                    {
                        poDetailsList.Add(poOrderDetails);
                        DMSCallContext.CurrentHistoryPODetails[poID.Value] = poDetailsList;
                    }
                    else
                    {
                        poDetailsList.Remove(itemInList);
                        poDetailsList.Add(poOrderDetails);
                        DMSCallContext.CurrentHistoryPODetails[poID.Value] = poDetailsList;
                    }
                    return Json(new[] { new { 
                    
                         ID = poOrderDetails.ID,
                                PurchaseOrderID = poOrderDetails.PurchaseOrderID,
                                ProductID = poOrderDetails.ProductID,
                                Sequence = poOrderDetails.Sequence,
                                Product = new { ID = poOrderDetails.Product.ID, Name = poOrderDetails.Product.Name },
                                ProductRateID = poOrderDetails.ProductRateID,
                                RateType = new { ID = poOrderDetails.RateType.ID, Description = poOrderDetails.RateType.Description },
                                Quantity = poOrderDetails.Quantity,
                                UnitOfMeasure = poOrderDetails.UnitOfMeasure,
                                Rate = poOrderDetails.Rate,
                                IsMemberPay = poOrderDetails.IsMemberPay,
                                ExtendedAmount = poOrderDetails.ExtendedAmount
                    } }.ToDataSourceResult(request, ModelState));
                }
            }
            catch (Exception)
            {

            }

            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetailsModel>() });
        }

        /// <summary>
        /// Updates the PO details.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="id">The id.</param>
        /// <param name="sequence">The sequence.</param>
        /// <returns></returns>
        [NoCache]
        [AcceptVerbs(HttpVerbs.Post)]
        public ActionResult _UpdatePODetails([DataSourceRequest] DataSourceRequest request, int id, int sequence, int PurchaseOrderID)
        {

            List<PurchaseOrderDetailsModel> poDetailsList = new List<PurchaseOrderDetailsModel>();
            poDetailsList = DMSCallContext.CurrentHistoryPODetails[PurchaseOrderID];
            try
            {
                PurchaseOrderDetailsModel poOrderDetails = new PurchaseOrderDetailsModel();

                POFacade facade = new POFacade();
                poOrderDetails = poDetailsList.Where(p => p.ID == id && p.Sequence == sequence).FirstOrDefault<PurchaseOrderDetailsModel>();
                poDetailsList.Remove(poOrderDetails);
                if (TryUpdateModel<PurchaseOrderDetailsModel>(poOrderDetails))
                {
                    poOrderDetails.UserName = LoggedInUserName;
                    if (poOrderDetails.Mode != "Insert")
                    {
                        poOrderDetails.Mode = "Update";
                    }
                    poOrderDetails.Product = facade.GetProductByID(poOrderDetails.ProductID.Value);
                    if (poOrderDetails.ProductRateID.HasValue)
                    {
                        poOrderDetails.RateType = facade.GetRatetypeByID(poOrderDetails.ProductRateID.Value);
                    }
                    else
                    {
                        poOrderDetails.RateType = new RateType();
                    }
                    poDetailsList.Add(poOrderDetails);
                    DMSCallContext.CurrentHistoryPODetails[PurchaseOrderID] = poDetailsList;
                    return Json(ModelState.ToDataSourceResult());
                }
            }
            catch (Exception)
            {

            }

            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetailsModel>() });
        }

        /// <summary>
        /// Deletes the PO details.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="poID">The po ID.</param>
        /// <param name="poDetailsModel">The po details model.</param>
        /// <returns></returns>
        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _DeletePODetails([DataSourceRequest] DataSourceRequest request, int? poID, PurchaseOrderDetailsModel poDetailsModel)
        {
            List<PurchaseOrderDetailsModel> poDetailsList = new List<PurchaseOrderDetailsModel>();
            poDetailsList = DMSCallContext.CurrentHistoryPODetails[poID.Value];
            try
            {
                POFacade facade = new POFacade();
                PurchaseOrderDetailsModel poOrderDetails = poDetailsList.Where(p => p.ID == poDetailsModel.ID && p.Sequence == poDetailsModel.Sequence).FirstOrDefault<PurchaseOrderDetailsModel>();
                poDetailsList.Remove(poOrderDetails);
                if (poOrderDetails.Mode != "Insert")
                {
                    poOrderDetails.Mode = "Deleted";
                    poDetailsList.Add(poOrderDetails);
                }
                DMSCallContext.CurrentHistoryPODetails[poID.Value] = poDetailsList;
                return Json(ModelState.ToDataSourceResult());
            }
            catch (Exception)
            {

            }

            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetailsModel>() });
        }

        public ActionResult _ReIssueCC(int poId)
        {
            POFacade facade = new POFacade();
            facade.ReIssueCC(poId, Request.RawUrl, LoggedInUserName, Session.SessionID);
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            return Json(result, JsonRequestBehavior.AllowGet);
        }



        /// <summary>
        /// Add or updates the PO.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="mode">The mode.</param>
        /// <param name="action">The action.</param>
        /// <param name="TalkedTo">The talked to.</param>
        /// <param name="VendorName">Name of the vendor.</param>
        /// <param name="ETAHours">The ETA hours.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult AddOrUpdate(PurchaseOrder po, string mode, string action, string TalkedTo, string VendorName, int? ETAHours, string ServiceCoveredOverridenInstructions, string IsPoPaymentEditAllowed)
        {
            POFacade facade = new POFacade();
            string purchaseOrderPayStatusCodeName = string.Empty;
            PurchaseOrder originalpo = facade.GetPOById(po.ID);
            List<PurchaseOrderDetailsModel> podetails = new List<PurchaseOrderDetailsModel>();
            if (DMSCallContext.CurrentHistoryPODetails.ContainsKey(po.ID))
            {
                podetails = DMSCallContext.CurrentHistoryPODetails[po.ID];
            }

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            bool isPayStatusCodeValid = true;
            string errorMessage = string.Empty;

            #region Validations and setting paystatus code

            //For issue&send and save button click. do validaitons first and set paystatus code
            if (action != "ReSendPO")
            {
                var currentPayStatusCode = ReferenceDataRepository.GetPurchaseOrderPayStatusCodeByID(po.PayStatusCodeID.GetValueOrDefault());
                var currentPayStatusCodeName = PurchaseOrderPayStatusCodeNames.PAY_BY_CC;
                if (currentPayStatusCode != null)
                {
                    currentPayStatusCodeName = currentPayStatusCode.Name;
                }
                if (currentPayStatusCodeName != PurchaseOrderPayStatusCodeNames.ON_HOLD)
                {
                    if (po.IsPayByCompanyCreditCard.HasValue && po.IsPayByCompanyCreditCard.Value == true && po.PurchaseOrderAmount.HasValue && po.PurchaseOrderAmount.Value == 0)
                    {
                        isPayStatusCodeValid = false;
                        errorMessage = "Set Pay By CC to ‘No’ when PO Amount = $0.00";
                    }

                    if (isPayStatusCodeValid && po.MemberServiceAmount > 0 && !po.IsMemberAmountCollectedByVendor.HasValue)
                    {
                        isPayStatusCodeValid = false;
                        errorMessage = "Mbr Pays ISP is required";
                    }
                }
                //If starting validations pass then execute further
                if (isPayStatusCodeValid)
                {
                    if (currentPayStatusCodeName != PurchaseOrderPayStatusCodeNames.ON_HOLD)
                    {
                        if (po.IsPayByCompanyCreditCard.HasValue && po.IsPayByCompanyCreditCard.Value == true && po.PurchaseOrderAmount.HasValue && po.PurchaseOrderAmount.Value > 0)
                        {
                            purchaseOrderPayStatusCodeName = PurchaseOrderPayStatusCodeNames.PAY_BY_CC;
                        }
                        else if (po.IsMemberAmountCollectedByVendor.HasValue && po.IsMemberAmountCollectedByVendor.Value && (po.MemberServiceAmount == po.TotalServiceAmount) && (po.PurchaseOrderAmount.HasValue && po.PurchaseOrderAmount.Value == 0))
                        {
                            purchaseOrderPayStatusCodeName = PurchaseOrderPayStatusCodeNames.PAID_BY_MEMBER;
                        }
                        else
                        {
                            purchaseOrderPayStatusCodeName = PurchaseOrderPayStatusCodeNames.PAY_TO_VENDOR;
                        }
                    }
                    if (po.PayStatusCodeID.HasValue)
                    {
                        //NMC TFS Bug 94

                        //string currentpaystatuscodename = ReferenceDataRepository.GetPurchaseOrderPayStatusCodes().Where(x => x.ID == po.PayStatusCodeID.Value).Select(x => x.Name).FirstOrDefault();

                        //Bug 157:If OnhOld don't do any validaitons.If aged not 90 days throw error.If status code other than two do other validations.
                        if (currentPayStatusCodeName == PurchaseOrderPayStatusCodeNames.ON_HOLD || currentPayStatusCodeName == PurchaseOrderPayStatusCodeNames.AGED)
                        {
                            if (currentPayStatusCodeName == PurchaseOrderPayStatusCodeNames.AGED)
                            {
                                if (originalpo.IssueDate.HasValue)
                                {
                                    TimeSpan ts = DateTime.Now - originalpo.IssueDate.Value;
                                    if (ts.TotalDays < 90)
                                    {
                                        isPayStatusCodeValid = false;
                                        errorMessage = "It has not been 90 days since the PO Issue Date so the Pay Status Code cannot be set to Over 90 Day";
                                    }

                                }
                            }
                        }
                        else
                        {
                            if (currentPayStatusCodeName != purchaseOrderPayStatusCodeName)
                            {
                                isPayStatusCodeValid = false;
                                if (purchaseOrderPayStatusCodeName == PurchaseOrderPayStatusCodeNames.PAY_BY_CC)
                                {
                                    errorMessage = "When Pay By CC = Yes then Pay Status Code must be set to Paid by company CC";
                                }
                                else if (purchaseOrderPayStatusCodeName == PurchaseOrderPayStatusCodeNames.PAID_BY_MEMBER)
                                {
                                    errorMessage = "Pay status code must be set to Paid By Member";
                                }
                                else if (purchaseOrderPayStatusCodeName == PurchaseOrderPayStatusCodeNames.PAY_TO_VENDOR)
                                {
                                    errorMessage = "Pay status code must be set to Pay To Vendor";
                                }
                            }

                        }
                    }
                    else
                    {
                        //Set pay status if not set by user.
                        if (!string.IsNullOrEmpty(purchaseOrderPayStatusCodeName))
                        {
                            po.PayStatusCodeID = ReferenceDataRepository.GetPurchaseOrderPayStatusCodeByName(purchaseOrderPayStatusCodeName).ID;
                        }
                    }
                }

                if (isPayStatusCodeValid == false)
                {
                    result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                    result.Data = "PayStatusInValid";
                    result.ErrorMessage = errorMessage;
                    return Json(result);
                }

            }

            #endregion

            string userName = LoggedInUserName;
            po.ModifyBy = userName;
            po.ModifyDate = DateTime.Now;


            if (ETAHours.HasValue)
            {
                po.ETAMinutes = po.ETAMinutes.HasValue ? (po.ETAMinutes.Value + (60 * ETAHours.Value)) : (60 * ETAHours.Value);
            }

            Case caseObj = facade.GetCaseForPO(po.ID);

            if (action != "ReSendPO")
            {
                if ("servicecoveredoverride".Equals(action))
                {
                    //logger.InfoFormat("Service Covered Override for PO : {0}, ServiceCovered : {1}", po.ID, po.IsServiceCovered);
                    ////KB: Determine service eligibility and update the po attributes.
                    //ServiceRequest serviceDetails = facade.GetSRByPO(po.ID);
                    ////Case caseobj = new CaseFacade().GetCaseById(serviceDetails.CaseID);
                    //int? towCategoryId = null;
                    //if (serviceDetails.IsPossibleTow.GetValueOrDefault())
                    //{
                    //    ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                    //    if (pc != null)
                    //    {
                    //        towCategoryId = pc.ID;
                    //    }
                    //}

                    //var serviceFacade = new ServiceFacade();
                    //var serviceEligibilityModel = serviceFacade.GetServiceEligibilityModel(caseObj.ProgramID, serviceDetails.ProductCategoryID, po.ProductID, caseObj.VehicleTypeID, po.VehicleCategoryID, towCategoryId, serviceDetails.ID, caseObj.ID, true);

                    //po.IsServiceCoveredOverridden = true;

                    //if (po.IsServiceCovered.GetValueOrDefault())
                    //{
                    //    po.IsServiceCovered = true;

                    //    if (serviceEligibilityModel.ServiceBenefit.Count > 0)
                    //    {
                    //        var vpb = serviceEligibilityModel.ServiceBenefit.Where(x => x.IsPrimary == 1).FirstOrDefault();
                    //        if (vpb != null)
                    //        {
                    //            po.CoverageLimit = vpb.ServiceCoverageLimit;
                    //            po.CurrencyTypeID = vpb.CurrencyTypeID;
                    //            po.CoverageLimitMileage = vpb.ServiceMileageLimit;
                    //            po.MileageUOM = vpb.ServiceMileageLimitUOM;
                    //            po.IsServiceCoverageBestValue = vpb.IsServiceCoverageBestValue;
                    //            //po.ServiceCoverageDescription = vpb.ServiceCoverageDescription;
                    //            po.ServiceEligibilityMessage = serviceEligibilityModel.PrimaryServiceEligiblityMessage;
                    //        }
                    //    }
                    //}
                    //else
                    //{
                    //    po.IsServiceCovered = false;
                    //}
                    //NP: 4/29 - Bug 346 - Dispatch - Request - PO - Run Service Eligibility logic upon opening a Pending PO

                    po = ServiceEligibilityCheckForPO(po, true, po.IsCoverageLimitEnabled.GetValueOrDefault());
                }
                bool isPoPaymentEditUpdateAllowed = false;
                if ("true".Equals(IsPoPaymentEditAllowed.ToLower()))
                {
                    isPoPaymentEditUpdateAllowed = true;
                }
                po = facade.AddOrUpdatePO(po, mode, podetails, null, caseObj.ProgramID.Value, Request.RawUrl, Session.SessionID, null, isPoPaymentEditUpdateAllowed);
                facade.UpdatePOPaymentStatus(po.ID, po.PayStatusCodeID);
            }
            //DMSCallContext.TalkedTo = TalkedTo;
            bool isSendPO = false;
            if (action == "SendPO" || action == "ReSendPO")
            {
                string status = "Issued";
                int? contactLogId = facade.GetVendorSelectionContactLog(po.ServiceRequestID, po.VendorLocationID);
                // NP : 01/07: TODO : Get MemberID, ClientName

                //var sr = facade.GetSRByPO(po.ID);
                //var caseRecord = new CaseFacade().GetCaseById(sr.CaseID);

                //var productCategory = ReferenceDataRepository.GetProductCategoryById(sr.ProductCategoryID.GetValueOrDefault());
                facade.SendPO(po, status, TalkedTo, VendorName, contactLogId, userName, Request.RawUrl, Session.SessionID);//, caseRecord != null ? caseRecord.MemberID.GetValueOrDefault() : 0, caseRecord != null && caseRecord.Program != null ? caseRecord.Program.Name : string.Empty, productCategory != null ? productCategory.Name : string.Empty);
                isSendPO = true;

            }
            logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
            if (DMSCallContext.CurrentHistoryPODetails.ContainsKey(po.ID))
            {
                DMSCallContext.CurrentHistoryPODetails.Remove(po.ID);
            }
            result.Data = new { id = po.ID, isSendPOSuccess = isSendPO };

            if ("servicecoveredoverride".Equals(action))
            {
                SaveServiceCovered(po.ID, po.IsServiceCovered, ServiceCoveredOverridenInstructions);
            }

            return Json(result);
        }

        /// <summary>
        /// Determines whether [is member payment balance].
        /// </summary>
        /// <returns></returns>
        public ActionResult IsMemberPaymentBalance(int serviceRequestId)
        {
            POFacade facade = new POFacade();
            bool value = facade.IsMemberPaymentBalance(serviceRequestId);
            return Json(new { Data = value }, JsonRequestBehavior.AllowGet);


        }

        /// <summary>
        /// Cancels the PO.
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.POCancelReason, true)]
        [NoCache]
        public ActionResult _CancelPO(int poId)
        {
            logger.InfoFormat("HistoryController - _CancelPO(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poId
            }));
            var po = new PORepository().GetPOById(poId);
            return PartialView(po);
        }

        /// <summary>
        /// Cancels the PO.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult CancelPO(PurchaseOrder po)
        {
            var loggedInUser = LoggedInUserName;
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            po.ModifyBy = loggedInUser;
            po.ModifyDate = DateTime.Now;
            POFacade facade = new POFacade();
            facade.CancelPO(po, loggedInUser, Request.RawUrl, Session.SessionID);
            return Json(result);
        }

        /// <summary>
        /// Adds the GOA.
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.GOAReason, true)]
        public ActionResult _AddGOA(int poId)
        {
            POFacade facade = new POFacade();

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            bool isAlreadyGOA = facade.IsAlreadyGOA(poId);
            if (isAlreadyGOA)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                return Json(result, JsonRequestBehavior.AllowGet);
            }
            else
            {
                PurchaseOrder po = new PurchaseOrder();
                po.ID = poId;
                return PartialView("_AddGOA", po);
            }
        }

        /// <summary>
        /// Adds the GOA.
        /// </summary>
        /// <param name="currentPO">The current PO.</param>
        /// <returns></returns>
        public ActionResult AddGOA(PurchaseOrder currentPO)
        {
            POFacade facade = new POFacade();
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            PurchaseOrder goaPO = facade.AddGOA(currentPO, this.GetProfile().UserName, Request.RawUrl, Session.SessionID);
            result.Data = new { id = goaPO.ID };
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Copies the PO.
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <returns></returns>
        public ActionResult _CopyPO(int poId)
        {
            POFacade facade = new POFacade();
            PurchaseOrder po = new PurchaseOrder();
            po = facade.GetPOById(poId);
            ServiceRequest serviceDetails = new ServiceFacade().GetServiceRequestById(po.ServiceRequestID);
            Case caseDetails = new CaseFacade().GetCaseById(serviceDetails.CaseID);
            int? vehicleTypeId = caseDetails.VehicleTypeID;
            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(vehicleTypeId.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);
            return PartialView("_CopyPO", po);
        }

        /// <summary>
        /// Gets the copy PO product.
        /// </summary>
        /// <param name="weightId">The weight id.</param>
        /// <returns></returns>
        public JsonResult GetCopyPOProduct(int? weightId, int? poId)
        {
            POFacade facade = new POFacade();
            PurchaseOrder po = new PurchaseOrder();
            po = facade.GetPOById(poId.Value);
            ServiceRequest serviceDetails = new ServiceFacade().GetServiceRequestById(po.ServiceRequestID);
            Case caseDetails = new CaseFacade().GetCaseById(serviceDetails.CaseID);
            int? vehicleTypeId = caseDetails.VehicleTypeID;
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetPOCopyProduct(vehicleTypeId.Value, weightId, caseDetails.ProgramID).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Copies the PO.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="copyServiceType">Type of the copy service.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult CopyPO(PurchaseOrder po, int? copyServiceType)
        {
            var loggedInUser = LoggedInUserName;
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            POFacade facade = new POFacade();
            // Get Old po
            PurchaseOrder oldPo = facade.GetPOById(po.ID);
            ServiceRequest serviceDetails = new ServiceFacade().GetServiceRequestById(oldPo.ServiceRequestID);
            //Case caseDetails = new CaseFacade().GetCaseById(serviceDetails.CaseID);

            // Copy OlPo into New PO
            PurchaseOrder newPO = CopyPo(oldPo);

            newPO.VehicleCategoryID = po.VehicleCategoryID;
            newPO.ProductID = copyServiceType;
            newPO.CreateBy = loggedInUser;
            newPO.ModifyBy = loggedInUser;
            ISPs_Result isps = new ISPs_Result();
            isps.ProductID = copyServiceType;
            isps.VendorLocationID = newPO.VendorLocationID.Value;
            isps.SelectionOrder = newPO.SelectionOrder;

            Product p = ReferenceDataRepository.GetProductById(copyServiceType.GetValueOrDefault());
            int? productCategoryId = p.ProductCategoryID;
            int? towCategoryId = null;
            if (serviceDetails.IsPossibleTow.GetValueOrDefault())
            {
                ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                if (pc != null)
                {
                    towCategoryId = pc.ID;
                }
            }

            Case caseobj = new CaseFacade().GetCaseById(serviceDetails.CaseID);
            ServiceEligibilityModel model = new ServiceFacade().GetServiceEligibilityModel(caseobj.ProgramID, productCategoryId, newPO.ProductID, caseobj.VehicleTypeID, newPO.VehicleCategoryID, towCategoryId, newPO.ServiceRequestID, caseobj.ID, SourceSystemName.DISPATCH, false, true);
            newPO.IsServiceCovered = model.IsPrimaryOverallCovered;
            newPO.CoverageLimit = model.PrimaryCoverageLimit;
            newPO.CoverageLimitMileage = model.PrimaryCoverageLimitMileage;
            newPO.MileageUOM = model.MileageUOM;
            newPO.IsServiceCoverageBestValue = model.IsServiceCoverageBestValue;
            newPO.ServiceEligibilityMessage = model.PrimaryServiceEligiblityMessage;

            PORepository repository = new PORepository();
            Program program = ReferenceDataRepository.GetProgramByID(caseobj.ProgramID.GetValueOrDefault());
            VendorRepository vRepo = new VendorRepository();
            var vendorLocation = vRepo.GetVendorLocationByID(newPO.VendorLocationID.GetValueOrDefault());
            newPO.ThresholdPercentage = repository.GetPOThresholdPercentage(newPO.VehicleCategoryID.GetValueOrDefault(), productCategoryId.GetValueOrDefault(), vendorLocation != null ? vendorLocation.VendorID : 0, program != null ? program.ClientID : null, caseobj.ProgramID);
            
            po = facade.AddOrUpdatePO(newPO, "CopyPO", null, isps, caseobj.ProgramID.Value, Request.RawUrl, Session.SessionID);
            result.Data = po.ID;
            return Json(result);
        }
        /// <summary>
        /// Copies the po.
        /// </summary>
        /// <param name="oldPo">The old po.</param>
        /// <returns></returns>
        private PurchaseOrder CopyPo(PurchaseOrder oldPo)
        {
            PurchaseOrder copyPO = new PurchaseOrder();

            #region Assigining Values to PO
            copyPO.ServiceRequestID = oldPo.ServiceRequestID;
            copyPO.OriginalPurchaseOrderID = oldPo.ID;
            copyPO.ContactMethodID = oldPo.ContactMethodID;
            copyPO.VehicleCategoryID = oldPo.VehicleCategoryID;
            copyPO.VendorLocationID = oldPo.VendorLocationID;
            copyPO.BillingAddressTypeID = oldPo.BillingAddressTypeID;
            copyPO.BillingAddressLine1 = oldPo.BillingAddressLine1;
            copyPO.BillingAddressLine2 = oldPo.BillingAddressLine2;
            copyPO.BillingAddressLine3 = oldPo.BillingAddressLine3;
            copyPO.BillingAddressCity = oldPo.BillingAddressCity;
            copyPO.BillingAddressStateProvince = oldPo.BillingAddressStateProvince;
            copyPO.BillingAddressPostalCode = oldPo.BillingAddressPostalCode;
            copyPO.BillingAddressCountryCode = oldPo.BillingAddressCountryCode;
            copyPO.FaxPhoneTypeID = oldPo.FaxPhoneTypeID;
            copyPO.FaxPhoneNumber = oldPo.FaxPhoneNumber;
            copyPO.Email = oldPo.Email;
            copyPO.DealerIDNumber = oldPo.DealerIDNumber;
            copyPO.EnrouteMiles = oldPo.EnrouteMiles;
            copyPO.EnrouteTimeMinutes = oldPo.EnrouteTimeMinutes;
            copyPO.EnrouteFreeMiles = oldPo.EnrouteFreeMiles;
            copyPO.ServiceFreeMiles = oldPo.ServiceFreeMiles;
            copyPO.ServiceMiles = oldPo.ServiceMiles;
            copyPO.ServiceTimeMinutes = oldPo.ServiceTimeMinutes;
            copyPO.ReturnMiles = oldPo.ReturnMiles;
            copyPO.ReturnTimeMinutes = oldPo.ReturnTimeMinutes;
            copyPO.IsServiceCovered = oldPo.IsServiceCovered;
            copyPO.MemberServiceAmount = 0;
            copyPO.MemberPaymentTypeID = oldPo.MemberPaymentTypeID;
            copyPO.IsMemberAmountCollectedByVendor = oldPo.IsMemberAmountCollectedByVendor;
            copyPO.DispatchFee = 0;
            copyPO.IsPayByCompanyCreditCard = oldPo.IsPayByCompanyCreditCard;
            copyPO.IsVendorAdvised = oldPo.IsVendorAdvised;
            copyPO.IsActive = oldPo.IsActive;
            copyPO.CreateDate = oldPo.CreateDate;
            copyPO.DispatchPhoneNumber = oldPo.DispatchPhoneNumber;
            copyPO.DispatchPhoneTypeID = oldPo.DispatchPhoneTypeID;
            copyPO.CurrencyTypeID = oldPo.CurrencyTypeID;
            copyPO.TaxAmount = 0;
            copyPO.TotalServiceAmount = 0;
            copyPO.CoachNetServiceAmount = 0;
            copyPO.MemberAmountDueToCoachNet = 0;
            copyPO.PurchaseOrderAmount = 0;
            copyPO.IsGOA = false;

            // NP 10/03: Bug 1621:
            copyPO.ServiceRating = oldPo.ServiceRating;
            copyPO.AdminstrativeRating = oldPo.AdminstrativeRating;
            copyPO.ContractStatus = oldPo.ContractStatus;
            copyPO.SelectionOrder = oldPo.SelectionOrder;
            // NP : End

            copyPO.PayStatusCodeID = null;
            copyPO.DispatchFee = oldPo.DispatchFee;
            copyPO.DispatchFeeBillToID = oldPo.DispatchFeeBillToID;

            //TFS #1288
            copyPO.PartsAndAccessoryCode = oldPo.PartsAndAccessoryCode;
            copyPO.IsDirectTowDealer = oldPo.IsDirectTowDealer;

            //TFS #1292
            copyPO.CostPlusPercentage = oldPo.CostPlusPercentage;
            #endregion

            return copyPO;
        }

        /// <summary>
        /// _s the type of the select rate.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult _SelectRateType(int? id)
        {
            var productRates = ReferenceDataRepository.GetProdctRate(id).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            return Json(productRates.Select(x => new
            {
                x.Value,
                x.Text
            }), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the sequence.
        /// </summary>
        /// <returns></returns>
        public ActionResult GetSquence(int poId)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            int maxSequenceNumber = 0;
            if (DMSCallContext.CurrentHistoryPODetails.ContainsKey(poId))
            {
                maxSequenceNumber = DMSCallContext.CurrentHistoryPODetails[poId].Max(p => p.Sequence).GetValueOrDefault();
            }
            result.Data = ++maxSequenceNumber;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult PONewRowDelete(int poId, int sequence)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            if (DMSCallContext.CurrentHistoryPODetails.ContainsKey(poId))
            {
                List<PurchaseOrderDetailsModel> podetails = DMSCallContext.CurrentHistoryPODetails[poId];
                PurchaseOrderDetailsModel detail = DMSCallContext.CurrentHistoryPODetails[poId].Where(x => x.Sequence == sequence).FirstOrDefault<PurchaseOrderDetailsModel>();
                podetails.Remove(detail);
                DMSCallContext.CurrentHistoryPODetails[poId] = podetails;
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }
        public ActionResult GetVendorRate(int poId)
        {
            logger.Info("Inside GetVendorRate() of POController. Attempt to call the VendorRate view");
            List<VendorRates_Result> vendorRatesList = new List<VendorRates_Result>();
            POFacade facade = new POFacade();
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 50,
                SortColumn = "Name",
                SortDirection = "ASC",
                PageSize = 50
            };
            PurchaseOrder po = facade.GetPOById(poId);
            if (po.VendorLocationID.HasValue)
            {
                vendorRatesList = facade.GetVendorRate(pageCriteria, po.VendorLocationID.Value);
            }
            ViewBag.CurrentPOId = poId;
            return PartialView("_GetVendorRate", vendorRatesList);
        }

        public ActionResult VendorRatesList([DataSourceRequest] DataSourceRequest request, int? poId)
        {
            logger.Info("Inside GetVendorRate() of POController. Attempt to call the VendorRate view");
            List<VendorRates_Result> vendorRatesList = new List<VendorRates_Result>();
            POFacade facade = new POFacade();
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
                SortColumn = sortColumn,
                SortDirection = sortOrder,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (pageCriteria.WhereClause == "")
            {
                pageCriteria.WhereClause = null;
            }
            PurchaseOrder po = facade.GetPOById(poId.Value);
            if (po.VendorLocationID.HasValue)
            {
                vendorRatesList = facade.GetVendorRate(pageCriteria, po.VendorLocationID.Value);
            }
            ViewBag.CurrentPOId = poId;

            int totalRows = 0;
            if (vendorRatesList.Count > 0)
            {
                totalRows = vendorRatesList[0].TotalRows.Value;
            }
            var result = new DataSourceResult()
            {
                Data = vendorRatesList,
                Total = totalRows
            };
            return Json(result);
        }

        /// <summary>
        /// Sends the PO history.
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult _SendPOHistory(int? poId)
        {
            POFacade facade = new POFacade();
            List<SendPOHistory_Result> sendPOList = new List<SendPOHistory_Result>();
            if (poId.HasValue)
            {
                sendPOList = facade.GetSendPOHistory(poId.Value);
            }
            return PartialView(sendPOList);
        }
        #endregion

        /// <summary>
        /// Gets the model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public HistorySearchCriteria GetModel(HistorySearchCriteria model)
        {
            #region Service Request Status
            List<CheckBoxLookUp> statusHistory = new List<CheckBoxLookUp>();
            List<ServiceRequestStatu> serviceRequestlist = ReferenceDataRepository.ServiceRequestStatus();

            if (model.ServiceRequestStatus == null)
            {
                foreach (ServiceRequestStatu status in serviceRequestlist)
                {
                    statusHistory.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.ServiceRequestStatus = statusHistory;
            }
            #endregion

            #region Service Type
            List<CheckBoxLookUp> listProductCategoryLookup = new List<CheckBoxLookUp>();
            List<ProductCategory> listProductCategory = ReferenceDataRepository.GetProductCategories(false);
            if (model.ServiceType == null)
            {
                foreach (ProductCategory status in listProductCategory)
                {
                    listProductCategoryLookup.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.ServiceType = listProductCategoryLookup;
            }

            #endregion

            #region Special List
            List<DropDownEntity> specialList = ReferenceDataRepository.GetHistorySearchCriteriaSpecial();
            List<CheckBoxLookUp> specialListLookUp = new List<CheckBoxLookUp>();
            if (model.SpecialList == null)
            {
                foreach (DropDownEntity status in specialList)
                {
                    specialListLookUp.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.SpecialList = specialListLookUp;
            }
            #endregion

            #region Purchase Order Status
            List<PurchaseOrderStatu> listPurchaseOrder = ReferenceDataRepository.GetPurchaseOrderStatus();
            List<CheckBoxLookUp> listPurchaseOrderLookUp = new List<CheckBoxLookUp>();
            if (model.PurchaseOrderStatus == null)
            {
                foreach (PurchaseOrderStatu status in listPurchaseOrder)
                {
                    listPurchaseOrderLookUp.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.PurchaseOrderStatus = listPurchaseOrderLookUp;
            }
            #endregion

            #region Payment
            List<DropDownEntity> listPaymentType = ReferenceDataRepository.GetHistorySearchCriteriaPaymentType();
            List<CheckBoxLookUp> listPaymentTypeLookUp = new List<CheckBoxLookUp>();
            if (model.PaymentType == null)
            {
                foreach (DropDownEntity status in listPaymentType)
                {
                    listPaymentTypeLookUp.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.PaymentType = listPaymentTypeLookUp;
            }
            #endregion

            #region Name Section
            if (model.NameSectionType.HasValue)
            {
                if (model.NameSectionType.Value == 1) // ISP
                {
                    model.NameSectionTypeMemberFirstName = string.Empty;
                    model.NameSectionTypeMemberLastName = string.Empty;
                    model.NameSectionTypeUser = string.Empty;
                }
                else if (model.NameSectionType.Value == 2) // Member
                {
                    model.NameSectionTypeISP = string.Empty;
                    model.NameSectionTypeUser = string.Empty;
                }
                else if (model.NameSectionType.Value == 3) // User
                {
                    model.NameSectionTypeISP = string.Empty;
                    model.NameSectionTypeMemberFirstName = string.Empty;
                    model.NameSectionTypeMemberLastName = string.Empty;
                }
            }
            else
            {
                model.NameSectionTypeISP = string.Empty;
                model.NameSectionTypeMemberFirstName = string.Empty;
                model.NameSectionTypeMemberLastName = string.Empty;
                model.NameSectionTypeUser = string.Empty;
            }
            #endregion

            #region Vehicle Section
            if (!model.VehicleType.HasValue)
            {
                model.VehicleYear = string.Empty;
                model.VehicleMake = string.Empty;
                model.VehicleModel = string.Empty;
                model.VehicleModelOther = string.Empty;
                model.VehicleMakeOther = string.Empty;
            }
            if (string.IsNullOrEmpty(model.VehicleYear))
            {
                model.VehicleMake = string.Empty;
                model.VehicleModel = string.Empty;
                model.VehicleModelOther = string.Empty;
                model.VehicleMakeOther = string.Empty;

            }
            if (string.IsNullOrEmpty(model.VehicleMake))
            {
                model.VehicleModel = string.Empty;
                model.VehicleModelOther = string.Empty;
                model.VehicleMakeOther = string.Empty;
            }
            else if (!model.VehicleMake.Equals("Other"))
            {
                model.VehicleMakeOther = string.Empty;
            }

            if (string.IsNullOrEmpty(model.VehicleModel))
            {
                model.VehicleModelOther = string.Empty;
            }
            else if (!model.VehicleModel.Equals("Other"))
            {
                model.VehicleModelOther = string.Empty;
            }



            #endregion
            logger.InfoFormat("HistoryController - HistorySearchCriteria(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                HistorySearchCriteria = model
            }));
            return model;
        }

        /// <summary>
        /// Searches the records.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SearchRecords(HistorySearchCriteria model)
        {
            OperationResult result = new OperationResult();
            model = GetModel(model);
            Session["HistorySearchCriteria"] = model;
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "RequestNumber";
            string sortOrder = "DESC";

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 100,
                PageSize = 100,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = string.Empty
            };

            ServiceFacade facade = new ServiceFacade();

            List<ServiceRequestHistoryList_Result> listResult = facade.GetServiceRequestHistory(pageCriteria, (Guid)GetLoggedInUser().ProviderUserKey, GetFilterClause());

            logger.InfoFormat("Call the view by sending {0} number of records", listResult.Count);
            int totalRows = 0;
            if (listResult.Count > 0)
            {
                totalRows = listResult.ElementAt(0).TotalRows.Value;
            }

            if (totalRows == 0)
            {
                result.Data = "0";
                return Json(result, JsonRequestBehavior.AllowGet);
            }

            return PartialView("_List", listResult);

        }

        /// <summary>
        /// Gets the make.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <param name="vehicleYear">The vehicle year.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public JsonResult GetMake(string vehicleType)
        {
            int vehicleTypeID = 0;
            int.TryParse(vehicleType, out vehicleTypeID);

            //double vehicleYearDouble = 0;
            //double.TryParse(vehicleYear, out vehicleYearDouble);

            return Json(ReferenceDataRepository.GetHistorySearchCriteriaMake(vehicleTypeID), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the model for vehicle.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <param name="make">The make.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public JsonResult GetModelForVehicle(string vehicleType, string make)
        {
            int vehicleTypeID = 0;
            int.TryParse(vehicleType, out vehicleTypeID);
            return Json(ReferenceDataRepository.GetHistorySearchCriteriaModel(vehicleTypeID, make), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the years.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public JsonResult GetYears(string vehicleType)
        {
            List<SelectListItem> list = null;
            int vehicleTypeID = 0;
            int.TryParse(vehicleType, out vehicleTypeID);
            list = GetConstantYears();
            //switch (vehicleTypeID)
            //{
            //    case 1:
            //        return Json(ReferenceDataRepository.GetHistorySearchCriteriaVehicleMakeModelYear(), JsonRequestBehavior.AllowGet);
            //    case 2:
            //        list = GetConstantYears();
            //        break;
            //    case 3:
            //        list = GetConstantYears();
            //        break;
            //    case 4:
            //        list = GetConstantYears();
            //        break;
            //    default:
            //        list = new List<SelectListItem>();
            //        break;
            //}
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the constant years.
        /// </summary>
        /// <returns></returns>
        public List<SelectListItem> GetConstantYears()
        {
            List<SelectListItem> years = new List<SelectListItem>();
            int currentYear = DateTime.Now.Year + 1;
            string sYear = string.Empty;
            for (int i = 0; i <= 50; i++)
            {
                sYear = currentYear.ToString();
                years.Add(new SelectListItem() { Text = sYear, Value = sYear });
                currentYear -= 1;
            }

            return years;
        }

        /// <summary>
        /// Gets the programs.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public JsonResult GetPrograms(string id)
        {
            List<SelectListItem> blist = new List<SelectListItem>();
            if (!string.IsNullOrEmpty(id))
            {
                string[] list = id.Split(',');
                int[] convertedItems = Array.ConvertAll<string, int>(list, int.Parse);
                return Json(ReferenceDataRepository.GetHistorySearchCriteriaPrograms(convertedItems).ToSelectListItem(x => x.ID.ToString(), y => y.Name, false), JsonRequestBehavior.AllowGet);
            }
            else
            {
                return Json(blist, JsonRequestBehavior.AllowGet);
            }
        }

        /// <summary>
        /// _s the PO for service request.
        /// </summary>
        /// <param name="command">The command.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult _POForServiceRequest([DataSourceRequest] DataSourceRequest command, int serviceRequestID)
        {
            string sortColumn = "PODate";
            string sortOrder = "DESC";
            if (command.Sorts.Count > 0)
            {
                sortColumn = command.Sorts[0].Member;
                sortOrder = (command.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            POFacade facade = new POFacade();
            List<POForServiceRequest_Result> list = facade.GetPOForServiceRequest(serviceRequestID, sortColumn, sortOrder);

            return Json(new DataSourceResult() { Data = list });
        }

        /// <summary>
        /// Gets the service request details.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult GetServiceRequestDetails(int serviceRequestID, bool isShowAction = true)
        {
            logger.InfoFormat("Trying to retrieve Service Request Details for the ID {0}", serviceRequestID);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            string loggedInUserName = GetLoggedInUser().UserName;
            QueueFacade queueFacade = new QueueFacade();
            List<ServiceRequest_Result> serviceRequestResult = queueFacade.Get(loggedInUserName, Request.RawUrl, null, serviceRequestID.ToString(), false, HttpContext.Session.SessionID);

            List<QuestionAnswer_ServiceRequest_Result> listQuestionAnswer = queueFacade.GetQuestionAnswerForServiceRequest(serviceRequestID,serviceRequestResult[0].SourceSystemName);
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

            //Lakshmi -Changes for Orphaned Service Request Enhancement 
            var programs = ProgramMaintenanceRepository.GetProgramsForCall((Guid)GetLoggedInUser().ProviderUserKey);
            ViewData["Programs"] = programs.ToSelectListItem(x => x.Id.ToString(), y => y.Name, true);
            ViewData["memberno"] = serviceRequestResult[0].MembershipNumber;
            //end

            logger.Info("Details retrieving finished");

            ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
            var programResult = programMaintenanceRepository.GetProgramInfo(serviceRequestResult[0].ProgramID, "Service", "Validation");
            bool memberEligibleApllies = false;

            var item = programResult.Where(x => (x.Name.Equals("MemberEligibilityApplies", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (item != null)
            {
                memberEligibleApllies = true;
            }
            ViewData["MemberEligibilityApplies"] = memberEligibleApllies;
            ViewData["IsShowAction"] = isShowAction;
            return View("_ServiceRequestDetails", serviceRequestResult);
        }



        [ReferenceDataFilter(StaticData.ContactMethod, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult _PO_Activity_AddContact(int ServiceRequestID, int POID)
        {
            logger.Info("Inside _Vendor_Location_Activity_AddContact() in VendorHomeController ");
            ViewData["ServiceRequestID"] = ServiceRequestID.ToString();
            ViewData["POID"] = POID.ToString();
            Activity_AddContact model = new Activity_AddContact();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR_LOCATION).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.ContactCategory.ToString()] = ReferenceDataRepository.GetContactCategoryForAddContact().ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);

            model.IsInbound = true;
            logger.Info("Returning Partial View '_PO_Activity_AddContact'");
            return View(model);
        }

        public ActionResult SaveSRActivityContact(Activity_AddContact model)
        {
            logger.Info("Inside SaveVendorLocationActivityContact() in VendorHomeController to save a Contact ");
            OperationResult result = new OperationResult();
            POFacade facade = new POFacade();
            facade.SaveSRActivityContact(model, LoggedInUserName);
            result.Status = "Success";
            logger.Info("Contact Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult SaveSRActivityComments(int CommentType, string Comments, int ServiceRequestID)
        {
            OperationResult result = new OperationResult();
            POFacade facade = new POFacade();
            facade.SaveSRActivityComments(CommentType, Comments, ServiceRequestID, LoggedInUserName);

            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult _POHistory(int id, bool isShowAction)
        {
            ViewData["ServiceRequestId"] = id;
            ViewData["IsShowAction"] = isShowAction;
            return PartialView();
        }
        #region Orphaned Service Request Enhancement
        //Lakshmi - Implemented below functions for Orphaned Service Request Enhancement 
        //Begin
        /// <summary>
        /// Perform Search on Member
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _AddMemberNumber(string MemberNo, string ProgramID, string serviceRequestID)
        {
            MemberSearchCriteria searchCriteria = new MemberSearchCriteria();
            searchCriteria.MemberNumber = MemberNo;
            searchCriteria.ProgramID = Convert.ToInt32(ProgramID);

            MemberFacade facade = new MemberFacade();
            OperationResult result = new OperationResult();
            List<SearchMember_Result> list = new List<SearchMember_Result>();
            int totalRows = 0;
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Name";
            string sortOrder = "ASC";


            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                PageSize = 10,
                SortColumn = sortColumn,
                SortDirection = sortOrder,
                WhereClause = GetWhereClauseXML(searchCriteria)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause) || !string.IsNullOrEmpty(searchCriteria.CommaSepratedMemberIDList))
            {
                pageCriteria.WhereClause = null;
            }

            if (string.IsNullOrEmpty(searchCriteria.FirstName) &&
               string.IsNullOrEmpty(searchCriteria.LastName) &&
               searchCriteria.MemberID == 0 &&
               string.IsNullOrEmpty(searchCriteria.MemberNumber) &&
                string.IsNullOrEmpty(searchCriteria.Phone) &&
                string.IsNullOrEmpty(searchCriteria.State) &&
                string.IsNullOrEmpty(searchCriteria.VIN) &&
                string.IsNullOrEmpty(searchCriteria.ZipCode)
                )
            {
                logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
                return Json(result, JsonRequestBehavior.AllowGet);
            }

            if (!string.IsNullOrEmpty(searchCriteria.FirstName) ||
                !string.IsNullOrEmpty(searchCriteria.LastName) ||
                searchCriteria.MemberID > 0 ||
                !string.IsNullOrEmpty(searchCriteria.MemberNumber) ||
                !string.IsNullOrEmpty(searchCriteria.Phone) ||
                !searchCriteria.MemberProgramID.HasValue ||
                !string.IsNullOrEmpty(searchCriteria.State) ||
                !string.IsNullOrEmpty(searchCriteria.VIN) ||
                !string.IsNullOrEmpty(searchCriteria.ZipCode) ||
                (searchCriteria.ProgramID > 0)
                )
            {
                logger.Info("Inside SearchList() of Member Controller");
                int inboundCallId = DMSCallContext.InboundCallID;
                string loggedInUserName = GetLoggedInUser().UserName;
                var userId = GetLoggedInUserId();

                list = facade.SearchMember(loggedInUserName, Request.RawUrl, inboundCallId, pageCriteria, searchCriteria.ProgramID, HttpContext.Session.SessionID);


                if (list.Count > 0)
                {
                    totalRows = list[0].TotalRows.Value;
                }
            }

            logger.InfoFormat("Call the view (_MemberInfo) by sending {0} number of records", totalRows);
            if (!searchCriteria.MemberFoundFromMobile)
            {
                DMSCallContext.MobileCallForServiceRecord = null;
            }
            if (totalRows == 0)
            {
                result.Data = "0";
                return Json(result, JsonRequestBehavior.AllowGet);
            }
            ViewData["SearchMemberNo"] = searchCriteria.MemberNumber;
            ViewData["SearchProgramID"] = searchCriteria.ProgramID;
            ViewData["ServiceRequestID"] = serviceRequestID.ToString();

            return PartialView("_MemberInfo", list);
        }

        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _searchMember([DataSourceRequest] DataSourceRequest request, MemberSearchCriteria searchCriteria)
        {
            MemberFacade facade = new MemberFacade();
            List<SearchMember_Result> list = new List<SearchMember_Result>();
            int totalRows = 0;
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Name";
            string sortOrder = "ASC";
            if (request.Sorts != null && request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortColumn = sortColumn,
                SortDirection = sortOrder,
                WhereClause = GetWhereClauseXML(searchCriteria)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause) || !string.IsNullOrEmpty(searchCriteria.CommaSepratedMemberIDList))
            {
                pageCriteria.WhereClause = null;
            }

            //Sanghi : Integration Added when we found multiple members for a given call back number
            //Idea is not to distrub existing SP and Flow, so added new SP 
            if (!string.IsNullOrEmpty(searchCriteria.CommaSepratedMemberIDList))
            {
                List<StartCallMemberSelections_Result> tempResult = facade.SearchMember(pageCriteria, searchCriteria.CommaSepratedMemberIDList).ToList();
                if (tempResult != null && tempResult.Count > 0)
                {
                    tempResult.ForEach(x =>
                    {
                        list.Add(new SearchMember_Result()
                        {
                            MemberID = x.MemberID,
                            MembershipID = x.MembershipID,
                            MemberNumber = x.MembershipNumber,
                            Name = x.MemberName,
                            Address = x.Address,
                            PhoneNumber = x.PhoneNumber,
                            ProgramID = x.ProgramID,
                            Program = x.Program,
                            VIN = x.VIN,
                            MemberStatus = x.MemberStatus,
                            POCount = x.POCount
                        });
                    });
                    totalRows = tempResult.Count();
                    logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
                    return Json(new DataSourceResult() { Data = list, Total = totalRows });
                }
            }

            if (string.IsNullOrEmpty(searchCriteria.FirstName) &&
               string.IsNullOrEmpty(searchCriteria.LastName) &&
               searchCriteria.MemberID == 0 &&
               string.IsNullOrEmpty(searchCriteria.MemberNumber) &&
                string.IsNullOrEmpty(searchCriteria.Phone) &&
                string.IsNullOrEmpty(searchCriteria.State) &&
                string.IsNullOrEmpty(searchCriteria.VIN) &&
                string.IsNullOrEmpty(searchCriteria.ZipCode)
                )
            {
                logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
                return Json(new DataSourceResult() { Data = list, Total = totalRows });
            }

            if (!string.IsNullOrEmpty(searchCriteria.FirstName) ||
                !string.IsNullOrEmpty(searchCriteria.LastName) ||
                searchCriteria.MemberID > 0 ||
                !string.IsNullOrEmpty(searchCriteria.MemberNumber) ||
                !string.IsNullOrEmpty(searchCriteria.Phone) ||
                !searchCriteria.MemberProgramID.HasValue ||
                !string.IsNullOrEmpty(searchCriteria.State) ||
                !string.IsNullOrEmpty(searchCriteria.VIN) ||
                !string.IsNullOrEmpty(searchCriteria.ZipCode) ||
                (searchCriteria.ProgramID > 0)
                )
            {
                logger.Info("Inside SearchList() of Member Controller");
                int inboundCallId = DMSCallContext.InboundCallID;
                string loggedInUserName = GetLoggedInUser().UserName;
                var userId = GetLoggedInUserId();

                list = facade.SearchMember(loggedInUserName, Request.RawUrl, inboundCallId, pageCriteria, searchCriteria.ProgramID, HttpContext.Session.SessionID);
            }

            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }
            logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
            if (!searchCriteria.MemberFoundFromMobile)
            {
                DMSCallContext.MobileCallForServiceRecord = null;
            }
            return Json(new DataSourceResult() { Data = list, Total = totalRows });
        }


        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult UpdateMembershipNoInCase(string svcReq, int memberID, string membershipno)
        {
            OperationResult result = new OperationResult();
            string loggedInUserName = GetLoggedInUser().UserName;
            CaseFacade casefacede = new CaseFacade();
            casefacede.updateCaseMemberNo(Convert.ToInt32(svcReq), memberID, membershipno, loggedInUserName, HttpContext.Session.SessionID);
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the where clause XML.
        /// </summary>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        private string GetWhereClauseXML(MemberSearchCriteria searchCriteria)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");

                // Append operator and values
                if (!string.IsNullOrEmpty(searchCriteria.MemberNumber))
                {
                    writer.WriteAttributeString("MemberNumberOperator", "2");
                    writer.WriteAttributeString("MemberNumberValue", searchCriteria.MemberNumber);
                }
                if (!string.IsNullOrEmpty(searchCriteria.LastName))
                {
                    writer.WriteAttributeString("LastNameOperator", "4");
                    writer.WriteAttributeString("LastNameValue", searchCriteria.LastName);
                }
                if (!string.IsNullOrEmpty(searchCriteria.FirstName))
                {
                    writer.WriteAttributeString("FirstNameOperator", "4");
                    writer.WriteAttributeString("FirstNameValue", searchCriteria.FirstName);
                }
                if (searchCriteria.MemberProgramID > 0)
                {
                    string programName = ReferenceDataRepository.GetProgramByID(searchCriteria.MemberProgramID.Value).Code;
                    writer.WriteAttributeString("ProgramOperator", "2");
                    writer.WriteAttributeString("ProgramValue", programName);
                }
                if (!string.IsNullOrEmpty(searchCriteria.Phone))
                {
                    writer.WriteAttributeString("PhoneNumberOperator", "6");
                    writer.WriteAttributeString("PhoneNumberValue", searchCriteria.Phone);
                }
                if (!string.IsNullOrEmpty(searchCriteria.VIN))
                {
                    writer.WriteAttributeString("VINOperator", "6");
                    writer.WriteAttributeString("VINValue", searchCriteria.VIN);
                }
                if (!string.IsNullOrEmpty(searchCriteria.State))
                {
                    writer.WriteAttributeString("StateOperator", "2");
                    writer.WriteAttributeString("StateValue", searchCriteria.State);
                }
                if (!string.IsNullOrEmpty(searchCriteria.ZipCode))
                {
                    writer.WriteAttributeString("ZipCodeOperator", "4");
                    writer.WriteAttributeString("ZipCodeValue", searchCriteria.ZipCode);
                }
                if (searchCriteria.MemberID > 0)
                {
                    writer.WriteAttributeString("MemberIDOperator", "2");
                    writer.WriteAttributeString("MemberIDValue", searchCriteria.MemberID.ToString());
                }

                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }
            return whereClauseXML.ToString();
        }

        //End
        #endregion
    }

    /// <summary>
    /// 
    /// </summary>
    public class TempData
    {
        public int ServiceRequestID { get; set; }
        public string Program { get; set; }
        public string Member { get; set; }
        public DateTime Created { get; set; }
        public string VehicleType { get; set; }
        public string ServiceType { get; set; }
        public string Status { get; set; }
        public string ISP { get; set; }
        public int PO { get; set; }
        public string POStatus { get; set; }
        public double POAmount { get; set; }

        /// <summary>
        /// Gets the data.
        /// </summary>
        /// <returns></returns>
        public List<TempData> GetData()
        {
            List<TempData> list = new List<TempData>();
            list.Add(new TempData()
            {
                ServiceRequestID = 1368,
                Program = "NMCA",
                Member = "Smith, John",
                Created = DateTime.Now,
                VehicleType = "Auto",
                ServiceType = "Tow",
                Status = "Completed",
                ISP = "Joe's Towing",
                PO = 7801234,
                POStatus = "Issued",
                POAmount = 245


            });
            list.Add(new TempData()
            {
                ServiceRequestID = 1377,
                Program = "Winnebago",
                Member = "Jones, Dave",
                Created = DateTime.Now,
                VehicleType = "RV",
                ServiceType = "Jump",
                Status = "Cancelled",
                ISP = "Kelly Towing",
                PO = 7801209,
                POStatus = "Issued",
                POAmount = 35.25

            });
            list.Add(new TempData()
            {
                ServiceRequestID = 1250,
                Program = "NMCA",
                Member = "Smith, John",
                Created = DateTime.Now,
                VehicleType = "Auto",
                ServiceType = "Tow",
                Status = "Completed",
                ISP = "Joe's Towing",
                PO = 7801234,
                POStatus = "Issued",
                POAmount = 245


            });
            list.Add(new TempData()
            {
                ServiceRequestID = 1362,
                Program = "NMCA",
                Member = "Smith, John",
                Created = DateTime.Now,
                VehicleType = "Auto",
                ServiceType = "Tow",
                Status = "Completed",
                ISP = "Joe's Towing",
                PO = 7801234,
                POStatus = "Issued",
                POAmount = 245


            });
            return list;
        }
    }
}
