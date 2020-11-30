using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;
using Martex.DMS.Models;
using Martex.DMS.DAL.Entities;
using System.Globalization;
using System.Threading;
using System.Xml;
using Kendo.Mvc.UI;
using Kendo.Mvc.Extensions;
using Martex.DMS.BLL.DataValidators;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.DMSBaseException;
using Newtonsoft.Json;
using System.Web.Script.Serialization;

namespace Martex.DMS.Areas.Application.Controllers
{
    /// <summary>
    /// 
    /// </summary>
    public class POController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// Searches this instance.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Users, true)]
        [ReferenceDataFilter(StaticData.POSearchTimeFilter, true)]
        [NoCache]
        public ActionResult Search()
        {
            return PartialView("_Search");
        }

        /// <summary>
        /// Gets the request ID.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public ActionResult GetRequestID(string id)
        {
            logger.InfoFormat("Inside GetMemberID() of Memebr. Call by the grid with the request {0}, try to returns the Json object", id);
            return Json(new { IdValue = id }, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// _s the search.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _Search([DataSourceRequest] DataSourceRequest request, POSearchCriteria searchCriteria)
        {
            logger.InfoFormat("POController - _Search(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                request = request,
                searchCriteria = searchCriteria
            }));
            int totalRows = 0;
            List<SearchPO_Result> list = new List<SearchPO_Result>();

            if (!string.IsNullOrEmpty(searchCriteria.PONumber) ||
                !string.IsNullOrEmpty(searchCriteria.VendorNumber) ||
                !string.IsNullOrEmpty(searchCriteria.Time) ||
                !string.IsNullOrEmpty(searchCriteria.UserName)
                )
            {
                logger.Info("Inside _Search of PO Controller");
                GridUtil gridUtil = new GridUtil();
                string sortColumn = "Date";
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
                    SortColumn = sortColumn,
                    SortDirection = sortOrder,
                    WhereClause = GetWhereClauseXML(searchCriteria)
                };
                POFacade facade = new POFacade();
                if (string.IsNullOrEmpty(pageCriteria.WhereClause))
                {
                    pageCriteria.WhereClause = null;
                }
                int inboundCallId = DMSCallContext.InboundCallID;
                string loggedInUserName = GetLoggedInUser().UserName;
                var userId = GetLoggedInUserId(); ;
                list = facade.Search(loggedInUserName, Request.RawUrl, inboundCallId, pageCriteria, userId, HttpContext.Session.SessionID);


                if (list.Count > 0)
                {
                    totalRows = list[0].TotalRows.Value;
                }
            }

            return Json(new DataSourceResult() { Data = list, Total = totalRows });
        }

        /// <summary>
        /// _s the index.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.VehicleCategory, false)]
        [ReferenceDataFilter(StaticData.SendType, false)]
        [ReferenceDataFilter(StaticData.PODetailsProduct, false)]
        [ReferenceDataFilter(StaticData.ETA)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.MemberPayType, false)]
        [ReferenceDataFilter(StaticData.CurrencyType, false)]
        [ReferenceDataFilter(StaticData.PODetailsUOM, false)]
        [ReferenceDataFilter(StaticData.PurchaseOrderPayStatusCode, false)]
        [NoCache]
        [DMSAuthorize]
        public ActionResult _Index()
        {
            logger.Info("Inside _Index of PO Controller");
            var loggedInUser = LoggedInUserName;
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            PurchaseOrder po = new PurchaseOrder();
            POFacade facade = new POFacade();

            VendorInformation_Result vendorInfoResult = new VendorInformation_Result();
            List<POForServiceRequest_Result> list = new List<POForServiceRequest_Result>();
            ViewBag.MemberDispatchFee = facade.GetMemberPayDispatchFee(DMSCallContext.ProgramID);
            ViewBag.InternalDispatchFee = "0";
            ViewBag.ClientDispatchFee = "0";
            ViewBag.CreditCardProcessingFee = "0";

            ViewBag.DispatchFeeAgentMinutes = "0";
            ViewBag.DispatchFeeTechMinutes = "0";
            ViewBag.DispatchFeeTimeCost = "0";

            po.ServiceRequestID = DMSCallContext.ServiceRequestID;
            ServiceFacade srfacade = new ServiceFacade();
            ServiceRequest sr = srfacade.GetServiceRequestById(DMSCallContext.ServiceRequestID);
            // Determine Service covered as follows:
            /*
             *  If MemberStatus = Inactive Then set Service Covered =  No
             *  If MemberStatus = Active
             *      Check service eligibility
             *          If IsPrimaryProductCovered = Yes
             *              and IsSecondaryProductCovered = Yes or null
             *          Then ServiceCovered = Yes
             *          Else ServiceCovered = No
             * 
             */
            bool isServiceCovered = false;
            if (DMSCallContext.MemberStatus.Equals("active", StringComparison.InvariantCultureIgnoreCase))
            {
                bool isPrimaryProductCovered = sr.IsPrimaryProductCovered ?? false;
                bool isSecondaryProductCovered = sr.IsSecondaryProductCovered ?? true;

                if (isPrimaryProductCovered && isSecondaryProductCovered)
                {
                    isServiceCovered = true;
                }
            }
            DMSCallContext.IsPrimaryServiceCovered = isServiceCovered;
            ViewBag.IsPrimaryServiceCovered = isServiceCovered;
            po.IsServiceCovered = isServiceCovered;

            ViewBag.Client = ReferenceDataRepository.GetBillTo("Client");
            ViewBag.Member = ReferenceDataRepository.GetBillTo("Member");

            ViewBag.ServiceCoverageLimit = 0;
            ViewBag.IsDealerTow = facade.IsDealTow(DMSCallContext.ProgramID);

            list = facade.GetPOForServiceRequest(DMSCallContext.ServiceRequestID, null, null);
            ViewBag.TalkedTo = DMSCallContext.TalkedTo;
            ViewBag.IsPosAvailable = false;
            ViewBag.IsDollarLimtEnable = IsDollarLimitEnable();

            if (DMSCallContext.CurrentPurchaseOrder != null)
            {
                ViewBag.IsPosAvailable = true;
                po = DMSCallContext.CurrentPurchaseOrder;
                if (po.VendorLocationID.HasValue)
                {
                    vendorInfoResult = facade.GetVendorInformation(po.VendorLocationID.Value, po.ServiceRequestID);

                }
                else
                {
                    vendorInfoResult = facade.GetVendorInformation(DMSCallContext.VendorLocationID, DMSCallContext.ServiceRequestID);
                }
                if (po.Email != null)
                {
                    vendorInfoResult.Email = po.Email;
                }
            }
            else if (DMSCallContext.IsFromHistoryList && DMSCallContext.IsFromHistoryListPOID > 0)
            {
                ViewBag.IsPosAvailable = true;
                po = facade.GetPOById(DMSCallContext.IsFromHistoryListPOID);
                if (po.VendorLocationID.HasValue)
                {
                    vendorInfoResult = facade.GetVendorInformation(po.VendorLocationID.Value, po.ServiceRequestID);
                }
                logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
                DMSCallContext.CurrentPurchaseOrder = po;
            }
            else if (list.Count > 0)
            {
                ViewBag.IsPosAvailable = true;
                po = facade.GetPOById(list[0].ID);
                if (po.VendorLocationID.HasValue)
                {
                    vendorInfoResult = facade.GetVendorInformation(po.VendorLocationID.Value, po.ServiceRequestID);
                }
                logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
                DMSCallContext.CurrentPurchaseOrder = po;
            }
            //NP: 4/29 - Bug 346 - Dispatch - Request - PO - Run Service Eligibility logic upon opening a Pending PO

            if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Pending"))
            {
                po = ServiceEligibilityCheckForPO(po);
            }
            DMSCallContext.CurrentPurchaseOrder = po;

            #region Setting mode and resend and reissue button visibility
            //Setting mode
            string mode = "edit";
            ViewBag.Mode = mode;
            VendorInvoice vendorInvoice = null;
            string displayMode = mode;
            if (po.VendorInvoices.Count > 0)
            {
                vendorInvoice = facade.GetVendorInvoices(po.ID)[0];
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
            //ViewBag.Mode = displayMode;
            ViewBag.Mode = mode != null && mode.ToLower() == "view" ? "view" : displayMode;

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


            //KB: The lines above already set this value.
            if (po.IsServiceCovered.HasValue)
            {
                ViewBag.IsPrimaryServiceCovered = po.IsServiceCovered;
            }


            if (string.IsNullOrEmpty(po.FaxPhoneNumber))
            {
                po.FaxPhoneNumber = vendorInfoResult.FaxPhoneNumber;

            }

            if (DMSCallContext.ProgramID > 0 && po.VehicleCategoryID.HasValue)
            {
                ServiceFacade servfacade = new ServiceFacade();
                List<ServiceLimits_Result> data = servfacade.GetServiceLimits(DMSCallContext.ProgramID, po.VehicleCategoryID.Value);
            }
            ViewBag.ServiceCoverageLimit = po.CoverageLimit ?? 0;
            logger.InfoFormat("Coverage limit for PO - {0} is {1}", po.ID, po.CoverageLimit);
            vendorInfoResult.VendorTaxID = po.VendorTaxID;
            ViewBag.VendorInfo = vendorInfoResult;
            ViewBag.TaxAmount = po.TaxAmount;
            ViewBag.CurrentPOrderId = po.ID;
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
            DMSCallContext.VendorLocationID = vendorLocation;

            List<VendorRates_Result> vendorRatesList = facade.GetVendorRate(pageCriteria, vendorLocation);
            string visibility = "hidden";
            if (vendorRatesList.Count > 0)
            {
                visibility = "visible";
            }
            ViewBag.visibleVendorRates = visibility;
            //Editing ends here
            logger.Info("PO ID: " + po.ID.ToString());

            SetTabValidationStatus(RequestArea.PO);

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
            var programResult = programMaintenanceRepository.GetProgramInfo(DMSCallContext.ProgramID, "Application", "Rule");
            /*
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
            */
            ViewBag.MemberDispatchFee = po.DispatchFee.GetValueOrDefault().ToString();
            ViewBag.InternalDispatchFee = po.InternalDispatchFee.GetValueOrDefault().ToString();
            ViewBag.ClientDispatchFee = po.ClientDispatchFee.GetValueOrDefault().ToString();
            ViewBag.CreditCardProcessingFee = po.CreditCardProcessingFee.GetValueOrDefault().ToString();

            ViewBag.DispatchFeeAgentMinutes = po.DispatchFeeAgentMinutes.GetValueOrDefault().ToString();
            ViewBag.DispatchFeeTechMinutes = po.DispatchFeeTechMinutes.GetValueOrDefault().ToString();
            ViewBag.DispatchFeeTimeCost = po.DispatchFeeTimeCost.GetValueOrDefault().ToString();
            
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
            ViewBag.PO = po;

            return PartialView(list);
        }

        /// <summary>
        /// Calculates the dispatch fee.
        /// </summary>
        /// <param name="poId">The po identifier.</param>
        /// <param name="poAmount">The po amount.</param>
        /// <returns></returns>
        public ActionResult CalculateDispatchFee(int poId, decimal? poAmount)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.InfoFormat("Recalculating Dispatch fee for PO ID {0} and Amount {1}", poId, poAmount);
            POFacade facade = new POFacade();
            PurchaseOrder po = facade.GetPOById(poId);
            ServiceRequest serviceDetails = new ServiceFacade().GetServiceRequestById(po.ServiceRequestID);
            int programID = 0;
            if (serviceDetails != null)
            {
                Case caseDetails = new CaseFacade().GetCaseById(serviceDetails.CaseID);
                if (caseDetails != null)
                {
                    programID = caseDetails.ProgramID.GetValueOrDefault();
                }
            }

            PO_MemberPayDispatchFee_Result pOMemberPayDispatchFeeResult = new PO_MemberPayDispatchFee_Result()
            {
                StringDispatchFee = facade.GetMemberPayDispatchFee(programID),
                InternalDispatchFee = 0,
                ClientDispatchFee = 0,
                CreditCardProcessingFee = 0,

                DispatchFeeAgentMinutes = 0,
                DispatchFeeTechMinutes = 0,
                DispatchFeeTimeCost = 0
            };
            ProgramMaintenanceRepository programMaintenanceRepository = new ProgramMaintenanceRepository();
            var programResult = programMaintenanceRepository.GetProgramInfo(programID, "Application", "Rule");

            var calculateMemberPayDispatchFee = programResult.Where(x => (x.Name.Equals("MemberPayDispatchFee", StringComparison.InvariantCultureIgnoreCase) && x.DataType != null && x.DataType.Equals("Query", StringComparison.InvariantCultureIgnoreCase))).FirstOrDefault();
            if (calculateMemberPayDispatchFee != null)
            {
                pOMemberPayDispatchFeeResult = ReferenceDataRepository.CalculateMemberPayDispatchFee(poId, poAmount, calculateMemberPayDispatchFee.Value);
            }
            result.Data = pOMemberPayDispatchFeeResult;

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Adds the PO.
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <param name="mode">The mode.</param>
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
        [NoCache]
        public ActionResult _AddPO(int poId, string mode)
        {
            logger.InfoFormat("POController - _AddPO(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poId,
                mode = mode
            }));

            POFacade facade = new POFacade();
            ViewBag.Client = ReferenceDataRepository.GetBillTo("Client");
            ViewBag.Member = ReferenceDataRepository.GetBillTo("Member");
            ViewBag.IsPosAvailable = true;
            PurchaseOrder po = facade.GetPOById(poId);


            //NP: 4/29 - Bug 346 - Dispatch - Request - PO - Run Service Eligibility logic upon opening a Pending PO
            if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Pending"))
            {
                ServiceEligibilityCheckForPO(po);
                po = facade.GetPOById(poId);
            }


            #region Setting mode and resend and reissue button visibility
            //Setting mode
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
            ViewBag.Mode = mode != null && mode.ToLower() == "view" ? "view" : displayMode;

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
            //Bug 161
            vendorInfoResult.ContractStatus = po.ContractStatus;
            if (string.IsNullOrEmpty(po.FaxPhoneNumber))
            {
                po.FaxPhoneNumber = vendorInfoResult.FaxPhoneNumber;
            }
            ViewBag.VendorInfo = vendorInfoResult;
            ViewBag.MemberDispatchFee = facade.GetMemberPayDispatchFee(DMSCallContext.ProgramID);
            ViewBag.InternalDispatchFee = "0";
            ViewBag.ClientDispatchFee = "0";
            ViewBag.CreditCardProcessingFee = "0";

            ViewBag.DispatchFeeAgentMinutes = "0";
            ViewBag.DispatchFeeTechMinutes = "0";
            ViewBag.DispatchFeeTimeCost = "0";

            ViewBag.CurrentPOrderId = po.ID;
            ViewBag.TaxAmount = po.TaxAmount;
            ViewBag.IsDealerTow = facade.IsDealTow(DMSCallContext.ProgramID);
            ViewBag.IsPrimaryServiceCovered = po.IsServiceCovered;
            ViewBag.TalkedTo = DMSCallContext.TalkedTo;
            ViewBag.ServiceCoverageLimit = po.CoverageLimit ?? 0;
            logger.InfoFormat("Coverage limit for PO - {0} is {1}", po.ID, po.CoverageLimit);
            ViewBag.IsDollarLimtEnable = IsDollarLimitEnable();
            // NP 24/7: Added to get the count of Vendor Rates, editing strtd here
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 50,
                SortColumn = "Name",
                SortDirection = "ASC",
                PageSize = 50
            };
            DMSCallContext.VendorLocationID = po.VendorLocationID.GetValueOrDefault();
            int vendorLocation = DMSCallContext.VendorLocationID;
            List<VendorRates_Result> vendorRatesList = facade.GetVendorRate(pageCriteria, vendorLocation);
            string visibility = "hidden";
            if (vendorRatesList.Count > 0)
            {
                visibility = "visible";
            }
            ViewBag.visibleVendorRates = visibility;
            //Edit end here
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
            DMSCallContext.CurrentPurchaseOrder = po;
            DMSCallContext.CurrentPODetails = null;
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
            var programResult = programMaintenanceRepository.GetProgramInfo(DMSCallContext.ProgramID, "Application", "Rule");

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
            return PartialView(po);
        }


        /// <summary>
        /// Gets the PO id.
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <param name="poStatus">The po status.</param>
        /// <param name="poDataTransferDate">The po data transfer date.</param>
        /// <param name="ajaxDataTransfer">The ajax data transfer.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult GetPOId(int poId, string poStatus, DateTime? poDataTransferDate, string ajaxDataTransfer)
        {
            string datatransfer = null;
            if (!poDataTransferDate.HasValue && !string.IsNullOrEmpty(ajaxDataTransfer))
            {
                datatransfer = ajaxDataTransfer;
            }
            else if (poDataTransferDate.HasValue)
            {
                datatransfer = poDataTransferDate.Value.ToString();
            }
            return Json(new { poIdValue = poId, poStatusValue = poStatus, poDataTransferDateValue = datatransfer }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the re issue cc.
        /// </summary>
        /// <param name="poId">The po identifier.</param>
        /// <returns></returns>
        public ActionResult _ReIssueCC(int poId)
        {
            logger.InfoFormat("POController - _ReIssueCC(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poId
            }));

            POFacade facade = new POFacade();
            facade.ReIssueCC(poId, Request.RawUrl, LoggedInUserName, Session.SessionID);
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// Adds the GOA.
        /// </summary>
        /// <param name="currentPO">The current PO.</param>
        /// <returns></returns>
        public ActionResult AddGOA(PurchaseOrder currentPO)
        {
            logger.InfoFormat("POController - AddGOA(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = currentPO.ID
            }));

            logger.InfoFormat("Inside AddGOA() in POController with POID : {0}", currentPO.ID);
            POFacade facade = new POFacade();
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            logger.Info("Adding GOA for PO");
            PurchaseOrder goaPO = facade.AddGOA(currentPO, this.GetProfile().UserName, Request.RawUrl, Session.SessionID);
            logger.InfoFormat("Created GOA for the PO : {0}, the newly created GOA PO's ID is : {1}", currentPO.ID, goaPO.ID);
            result.Data = new { id = goaPO.ID };
            DMSCallContext.CurrentPODetails = null;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Determines whether [is member payment balance].
        /// </summary>
        /// <returns></returns>
        public ActionResult IsMemberPaymentBalance()
        {
            logger.Info("Inside IsMemberPaymentBalance of PO Controller");
            var facade = new POFacade();
            bool value = facade.IsMemberPaymentBalance(DMSCallContext.ServiceRequestID);
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
            logger.InfoFormat("POController - _CancelPO(), Parameters:  {0}", JsonConvert.SerializeObject(new
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
            logger.InfoFormat("POController - CancelPO(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = po.ID
            }));
            var loggedInUser = LoggedInUserName;
            var result = new OperationResult() { Status = OperationStatus.SUCCESS };
            po.ModifyBy = loggedInUser;
            po.ModifyDate = DateTime.Now;
            var facade = new POFacade();
            facade.CancelPO(po, loggedInUser, Request.RawUrl, Session.SessionID);
            return Json(result);
        }

        /// <summary>
        /// Copies the PO.
        /// </summary>
        /// <param name="poId">The po id.</param>
        /// <returns></returns>
        public ActionResult _CopyPO(int poId)
        {
            logger.InfoFormat("POController - _CopyPO(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poId
            }));
            int? vehicleTypeId = DMSCallContext.VehicleTypeID;
            POFacade facade = new POFacade();

            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(vehicleTypeId.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);
            PurchaseOrder po = new PurchaseOrder();
            po = facade.GetPOById(poId);

            return PartialView("_CopyPO", po);
        }

        public ActionResult _ChangeService(int poId, bool? isFromHistory)
        {
            logger.InfoFormat("POController - _ChangeService(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poId,
                isFromHistory = isFromHistory
            }));
            int? vehicleTypeId = DMSCallContext.VehicleTypeID;
            if (isFromHistory.GetValueOrDefault())
            {
                var poFacade = new POFacade();
                var sr = poFacade.GetSRByPO(poId);
                vehicleTypeId = sr.Case.VehicleTypeID;
            }

            POFacade facade = new POFacade();

            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(vehicleTypeId.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);
            PurchaseOrder po = new PurchaseOrder();
            po = facade.GetPOById(poId);
            ViewData["IsFromHistory"] = isFromHistory;
            return PartialView("_ChangeService", po);
        }

        [ValidateInput(false)]
        [NoCache]
        public ActionResult ChangeService(PurchaseOrder po, int? copyServiceType)
        {
            logger.InfoFormat("POController - ChangeService(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = po.ID,
                copyServiceType = copyServiceType,
                vehicleCategoryID = po.VehicleCategoryID
            }));
            var loggedInUser = LoggedInUserName;
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            POFacade facade = new POFacade();
            // Get Old po
            PurchaseOrder oldPo = facade.GetPOById(po.ID);

            ServiceRequest serviceDetails = new ServiceFacade().GetServiceRequestById(oldPo.ServiceRequestID);
            Case caseobj = new CaseFacade().GetCaseById(serviceDetails.CaseID);

            DMSCallContext.VehicleCategoryID = po.VehicleCategoryID;

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
            DMSCallContext.ProductCategoryID = productCategoryId;
            int? towCategoryId = null;
            if (serviceDetails.IsPossibleTow.GetValueOrDefault())
            {
                ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                if (pc != null)
                {
                    towCategoryId = pc.ID;
                }
            }
            ServiceEligibilityModel model = new ServiceFacade().GetServiceEligibilityModel(caseobj.ProgramID, productCategoryId, newPO.ProductID, caseobj.VehicleTypeID, newPO.VehicleCategoryID, towCategoryId, newPO.ServiceRequestID, caseobj.ID, SourceSystemName.DISPATCH, false, true);
            newPO.IsServiceCovered = model.IsPrimaryOverallCovered;
            newPO.CoverageLimit = model.PrimaryCoverageLimit;
            newPO.CoverageLimitMileage = model.PrimaryCoverageLimitMileage;
            newPO.MileageUOM = model.MileageUOM;
            newPO.IsServiceCoverageBestValue = model.IsServiceCoverageBestValue;
            newPO.ServiceEligibilityMessage = model.PrimaryServiceEligiblityMessage;
            po = facade.AddOrUpdatePO(newPO, "POChangeService", null, isps, caseobj.ProgramID.Value, Request.RawUrl, Session.SessionID);

            facade.PODelete(oldPo.ID, LoggedInUserName);
            facade.POLogChangeService(oldPo, newPO, Request.RawUrl, LoggedInUserName, Session.SessionID);

            result.Data = po.ID;
            return Json(result);
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
            logger.InfoFormat("POController - CopyPO(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = po.ID,
                copyServiceType = copyServiceType
            }));
            var loggedInUser = LoggedInUserName;
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            POFacade facade = new POFacade();
            // Get Old po
            PurchaseOrder oldPo = facade.GetPOById(po.ID);
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
            if (DMSCallContext.IsPossibleTow)
            {
                ProductCategory pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                if (pc != null)
                {
                    towCategoryId = pc.ID;
                }
            }
            ServiceEligibilityModel model = new ServiceFacade().GetServiceEligibilityModel(DMSCallContext.ProgramID, productCategoryId, newPO.ProductID, DMSCallContext.VehicleTypeID, newPO.VehicleCategoryID, towCategoryId, newPO.ServiceRequestID, DMSCallContext.CaseID, SourceSystemName.DISPATCH, false, true);
            newPO.IsServiceCovered = model.IsPrimaryOverallCovered;
            newPO.CoverageLimit = model.PrimaryCoverageLimit;
            newPO.CoverageLimitMileage = model.PrimaryCoverageLimitMileage;
            newPO.MileageUOM = model.MileageUOM;
            newPO.IsServiceCoverageBestValue = model.IsServiceCoverageBestValue;
            newPO.ServiceEligibilityMessage = model.PrimaryServiceEligiblityMessage;
            po = facade.AddOrUpdatePO(newPO, "CopyPO", null, isps, DMSCallContext.ProgramID, Request.RawUrl, Session.SessionID);
            result.Data = po.ID;
            return Json(result);
        }

        /// <summary>
        /// Gets the copy PO product.
        /// </summary>
        /// <param name="weightId">The weight id.</param>
        /// <returns></returns>
        public JsonResult GetCopyPOProduct(int? weightId)
        {
            logger.InfoFormat("POController - GetCopyPOProduct(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                weightId = weightId
            }));
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetPOCopyProduct(DMSCallContext.VehicleTypeID, weightId, DMSCallContext.ProgramID).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the PO for service request.
        /// </summary>
        /// <param name="command">The command.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult _POForServiceRequest([DataSourceRequest] DataSourceRequest command)
        {
            string sortColumn = "PODate";
            string sortOrder = "DESC";
            if (command.Sorts.Count > 0)
            {
                sortColumn = command.Sorts[0].Member;
                sortOrder = (command.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            POFacade facade = new POFacade();
            List<POForServiceRequest_Result> list = facade.GetPOForServiceRequest(DMSCallContext.ServiceRequestID, sortColumn, sortOrder);

            return Json(new DataSourceResult() { Data = list });
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
        /// Selects the PO details.
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
                if (DMSCallContext.CurrentPODetails.Count > 0)
                {
                    if (DMSCallContext.CurrentPODetails[0].PurchaseOrderID != poID.Value)
                    {
                        DMSCallContext.CurrentPODetails = null;
                    }
                }
                if (DMSCallContext.CurrentPODetails.Count == 0)
                {
                    poDetails = facade.GetPurchaseOrderDetails(poID.Value);
                    foreach (PODetailItemByPOId_Result item in poDetails)
                    {
                        PurchaseOrderDetailsModel model = new PurchaseOrderDetailsModel(item);
                        poDetailsModel.Add(model);
                    }
                }
                else
                {
                    poDetailsModel = DMSCallContext.CurrentPODetails;
                }

                DMSCallContext.CurrentPODetails = poDetailsModel;
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
                }, JsonRequestBehavior.AllowGet);
            }
            logger.Info("PO Details Retrived for " + poID.GetValueOrDefault().ToString());
            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetail>() }, JsonRequestBehavior.AllowGet);
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
            poDetailsList = DMSCallContext.CurrentPODetails;
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
                        DMSCallContext.CurrentPODetails = poDetailsList;
                    }
                    else
                    {
                        poDetailsList.Remove(itemInList);
                        poDetailsList.Add(poOrderDetails);
                        DMSCallContext.CurrentPODetails = poDetailsList;
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
        public ActionResult _UpdatePODetails([DataSourceRequest] DataSourceRequest request, int id, int sequence)
        {
            List<PurchaseOrderDetailsModel> poDetailsList = new List<PurchaseOrderDetailsModel>();
            poDetailsList = DMSCallContext.CurrentPODetails;
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
                    DMSCallContext.CurrentPODetails = poDetailsList;
                    return Json(ModelState.ToDataSourceResult());
                }
            }
            catch (Exception)
            {

            }

            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetailsModel>() });
        }

        /// <summary>
        /// Sends the PO.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="TalkedTo">The talked to.</param>
        /// <param name="VendorName">Name of the vendor.</param>
        /// <param name="ETAHours">The ETA hours.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SendPO(PurchaseOrder po, string TalkedTo, string VendorName, int? ETAHours)
        {
            logger.InfoFormat("POController - SendPO(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = po.ID,
                TalkedTo = TalkedTo,
                VendorName = VendorName,
                ETAHours = ETAHours
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            POFacade facade = new POFacade();
            string status = "Issued";
            if (po.MemberAmountDueToCoachNet == po.TotalServiceAmount || !string.IsNullOrEmpty(po.CompanyCreditCardNumber))
            {
                status = "Issued-Paid";
            }
            if (ETAHours.HasValue)
            {
                po.ETAMinutes = +(60 * ETAHours.Value);
            }
            var currentUser = LoggedInUserName;

            facade.SendPO(po, status, TalkedTo, VendorName, DMSCallContext.ContactLogID, currentUser, Request.RawUrl, Session.SessionID);//, DMSCallContext.MemberID, DMSCallContext.ClientName,DMSCallContext.ProductCategoryName);

            IncrementCallCounts(AgentTimeCounts.PO);
            return Json(result);
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
            poDetailsList = DMSCallContext.CurrentPODetails;
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
                DMSCallContext.CurrentPODetails = poDetailsList;
                return Json(ModelState.ToDataSourceResult());
            }
            catch (Exception)
            {

            }

            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetailsModel>() });
        }

        public ActionResult PONewRowDelete(int sequence)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            List<PurchaseOrderDetailsModel> poDetailsList = new List<PurchaseOrderDetailsModel>();
            poDetailsList = DMSCallContext.CurrentPODetails;

            if (poDetailsList != null && poDetailsList.Count() > 0)
            {
                PurchaseOrderDetailsModel detail = poDetailsList.Where(x => x.Sequence == sequence).FirstOrDefault<PurchaseOrderDetailsModel>();
                poDetailsList.Remove(detail);
                DMSCallContext.CurrentPODetails = poDetailsList;
            }

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
            logger.InfoFormat("POController - AddOrUpdate(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = po.ID,
                mode = mode,
                action = action,
                TalkedTo = TalkedTo,
                VendorName = VendorName,
                ETAHours = ETAHours,
                ServiceCoveredOverridenInstructions = ServiceCoveredOverridenInstructions
            }));
            string purchaseOrderPayStatusCodeName = string.Empty;
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            string userName = LoggedInUserName;
            po.ModifyBy = userName;
            po.ModifyDate = DateTime.Now;

            if (mode == "Add")
            {
                po.VendorLocationID = DMSCallContext.VendorLocationID;
                po.PayStatusCodeID = null;
            }
            POFacade facade = new POFacade();
            if (ETAHours.HasValue)
            {
                po.ETAMinutes = po.ETAMinutes.HasValue ? (po.ETAMinutes.Value + (60 * ETAHours.Value)) : (60 * ETAHours.Value);
            }

            bool isPayStatusCodeValid = true;
            string errorMessage = string.Empty;

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

                if (isPayStatusCodeValid)
                {
                    if (currentPayStatusCodeName != PurchaseOrderPayStatusCodeNames.ON_HOLD)
                    {
                        //Setting paystatuscodeId value tfs item 2392.For save and issue-send actions
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

                        if (!string.IsNullOrEmpty(purchaseOrderPayStatusCodeName))
                        {
                            po.PayStatusCodeID = ReferenceDataRepository.GetPurchaseOrderPayStatusCodeByName(purchaseOrderPayStatusCodeName).ID;
                        }
                    }

                    if ("servicecoveredoverride".Equals(action))
                    {
                        po = ServiceEligibilityCheckForPO(po, true, po.IsCoverageLimitEnabled.GetValueOrDefault());
                    }
                    bool isPoPaymentEditUpdateAllowed = false;
                    if ("true".Equals(IsPoPaymentEditAllowed.ToLower()))
                    {
                        isPoPaymentEditUpdateAllowed = true;
                    }
                    po = facade.AddOrUpdatePO(po, mode, DMSCallContext.CurrentPODetails, null, DMSCallContext.ProgramID, Request.RawUrl, Session.SessionID, null, isPoPaymentEditUpdateAllowed);
                }
                else
                {
                    result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                    result.Data = "PayStatusInValid";
                    result.ErrorMessage = errorMessage;
                    return Json(result);
                }
            }
            DMSCallContext.TalkedTo = TalkedTo;
            bool isSendPO = false;
            if (action == "SendPO" || action == "ReSendPO")
            {
                string status = "Issued";
                facade.SendPO(po, status, TalkedTo, VendorName, DMSCallContext.ContactLogID, userName, Request.RawUrl, Session.SessionID);//, DMSCallContext.MemberID, DMSCallContext.ClientName, DMSCallContext.ProductCategoryName);
                isSendPO = true;

            }
            logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
            DMSCallContext.CurrentPurchaseOrder = po;
            DMSCallContext.CurrentPODetails = null;
            result.Data = new { id = po.ID, isSendPOSuccess = isSendPO };
            if (isSendPO)
            {
                DMSCallContext.IsCallMadeToVendor = false;
                // Set the call status of the vendor in context to "Accepted".
                if (DMSCallContext.ISPs != null && DMSCallContext.ISPs.Count > 0 && DMSCallContext.VendorIndexInList >= 0)
                {
                    DMSCallContext.ISPs[DMSCallContext.VendorIndexInList].CallStatus = "Accepted";
                    // Update this item in the original list too.
                    DMSCallContext.UpdateItemInOriginalISPList(DMSCallContext.ISPs[DMSCallContext.VendorIndexInList]);
                }
            }

            if ("servicecoveredoverride".Equals(action))
            {
                SaveServiceCovered(po.ID, po.IsServiceCovered, ServiceCoveredOverridenInstructions);
            }
            return Json(result);
        }


        public PurchaseOrder ServiceEligibilityCheckForPO(PurchaseOrder po, bool isServiceCoveredOverridden = false, bool isServiceCoverageLimitEnable = true)
        {
            logger.InfoFormat("POController - ServiceEligibilityCheckForPO(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = po.ID,
                isServiceCoveredOverridden = isServiceCoveredOverridden,
                isServiceCoverageLimitEnable = isServiceCoverageLimitEnable
            }));
            POFacade poFacade = new POFacade();
            //KB: Determine service eligibility and update the po attributes.
            ServiceRequest serviceDetails = new ServiceFacade().GetServiceRequestById(DMSCallContext.ServiceRequestID);
            //Case caseobj = new CaseFacade().GetCaseById(serviceDetails.CaseID);
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
            ClientRepository clientRepository = new ClientRepository();
            Product product = clientRepository.GetProduct(po.ProductID);
            var serviceEligibilityModel = serviceFacade.GetServiceEligibilityModel(DMSCallContext.ProgramID, product != null ? product.ProductCategoryID : DMSCallContext.ProductCategoryID, po.ProductID, DMSCallContext.VehicleTypeID, po.VehicleCategoryID, towCategoryId, DMSCallContext.ServiceRequestID, DMSCallContext.CaseID, SourceSystemName.DISPATCH, true, true);
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
                        /* KB: The following block of code is commented out for the following reasons:
                         * 1. Setting CurrencyTypeID requires a load on the reference property - CurrencyType.
                         * 2. The value currencyTypeID is not considered while updating the service eligibility.
                        //po.CurrencyTypeID = vpb.CurrencyTypeID;
                        //TFS#432 : The above statement triggers a change to the CurrencyType reference. 
                        //          It is important to set the CurrencyType Object as this reference gets disposed and requires an active connection.

                        //var currencyTypes = ReferenceDataRepository.GetCurrencyTypes();
                        /*if (po.CurrencyTypeID != null)
                        {
                            po.CurrencyType = currencyTypes.Where(c => c.ID == po.CurrencyTypeID).FirstOrDefault();
                        }
                        */
                        // End for fix related to TFS#432.
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
        /// <summary>
        /// Gets the sequence.
        /// </summary>
        /// <returns></returns>
        public ActionResult GetSquence()
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            int maxSequenceNumber = DMSCallContext.CurrentPODetails.Max(p => p.Sequence).GetValueOrDefault();
            result.Data = ++maxSequenceNumber;
            return Json(result, JsonRequestBehavior.AllowGet);
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

        /// <summary>
        /// Rejects and clears the PO.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult RejectAndClear(PurchaseOrder po)
        {
            logger.InfoFormat("POController - RejectAndClear(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = po.ID
            }));
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            //TFS: 1423 - Rejecting and Vendor on the dispatch tab.
            /*if (po.ID > 0)
            {
                POFacade facade = new POFacade();
                facade.PODisable(po.ID, LoggedInUserName);
                logger.Info("PO ID:" + po.ID.ToString() + "is rejected !");
            }
            DMSCallContext.CurrentPurchaseOrder = null;
            DMSCallContext.CurrentPODetails = null;*/

            DMSCallContext.RejectVendorOnDispatch = true;
            // Need this item on Dispatch tab
            DMSCallContext.VendorLocationID = po.VendorLocationID.GetValueOrDefault();
            return Json(result);
        }

        /// <summary>
        /// Leaves the tab.
        /// </summary>
        /// <param name="po">The po.</param>
        /// <param name="mode">The mode.</param>
        /// <param name="ETAHours">The ETA hours.</param>
        /// <returns></returns>
        [HttpPost]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult LeaveTab(PurchaseOrder po, string mode, int? ETAHours)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            var currentUser = LoggedInUserName;
            if (mode == "Edit")
            {
                string userName = LoggedInUserName;
                po.ModifyBy = userName;
                po.ModifyDate = DateTime.Now;
                POFacade facade = new POFacade();
                if (ETAHours.HasValue)
                {
                    po.ETAMinutes = po.ETAMinutes.HasValue ? (po.ETAMinutes.Value + (60 * ETAHours.Value)) : (60 * ETAHours.Value);
                }
                po = facade.AddOrUpdatePO(po, mode, DMSCallContext.CurrentPODetails, null, DMSCallContext.ProgramID, Request.RawUrl, Session.SessionID);

                po = facade.GetPOById(po.ID);
                logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
                if (!DMSCallContext.RejectVendorOnDispatch)
                {
                    DMSCallContext.CurrentPurchaseOrder = po;
                }
                DMSCallContext.CurrentPODetails = null;
            }
            logger.Info("Processing leave tab");
            POFacade.POLeaveTab(Request.RawUrl, currentUser, Session.SessionID, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST);
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
            logger.InfoFormat("POController - _AddGOA(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poId
            }));
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

        public ActionResult GetVendorRate(int? vendorLocationID)
        {
            logger.InfoFormat("Inside GetVendorRate() of POController. Attempt to call the VendorRate view. VendorLocationID : {0}", vendorLocationID);
            POFacade facade = new POFacade();
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 50,
                SortColumn = "Name",
                SortDirection = "ASC",
                PageSize = 50
            };
            int vendorLocation = vendorLocationID.HasValue ? vendorLocationID.GetValueOrDefault() : DMSCallContext.VendorLocationID;
            return PartialView("_GetVendorRate", vendorLocation);
        }


        public ActionResult VendorRatesList([DataSourceRequest] DataSourceRequest request, int? vendorLocationID)
        {
            logger.Info("Inside GetVendorRate() of POController. Attempt to call the VendorRate view");
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
            int vendorLocation = vendorLocationID.HasValue ? vendorLocationID.GetValueOrDefault() : DMSCallContext.VendorLocationID;
            List<VendorRates_Result> vendorRatesList = facade.GetVendorRate(pageCriteria, vendorLocation);
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

        [HttpPost]
        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.PO_BUTTON_PO_SERVICECOVERED_EDIT)]
        public ActionResult SaveServiceCovered(int poId, bool? serviceCovered, string serviceCoveredOverridenInstructions)
        {
            logger.InfoFormat("POController - SaveServiceCovered() - Parameters : {0}", JsonConvert.SerializeObject(new
            {
                poId = poId,
                serviceCovered = serviceCovered,
                serviceCoveredOverridenInstructions = serviceCoveredOverridenInstructions
            }));

            // logger.Info("Inside SaveServiceCovered() of POController.");
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            POFacade facade = new POFacade();
            facade.SaveServiceCovered(poId, serviceCovered.Value, LoggedInUserName, Request.RawUrl, Session.SessionID, serviceCoveredOverridenInstructions);
            return Json(result);
        }

        public ActionResult _ViewPODocument(PurchaseOrder po, string mode, string action, string TalkedTo, string VendorName, int? ETAHours)
        {
            logger.InfoFormat("POController - _ViewPODocument() - Parameters : {0}", JsonConvert.SerializeObject(new
            {
                ServiceRequestID = DMSCallContext.ServiceRequestID,
                PurchaseOrder = po,
                mode = mode,
                action = action,
                TalkedTo = TalkedTo,
                VendorName = VendorName,
                ETAHours = ETAHours
            }));
            POFacade facade = new POFacade();
            string document = facade.ViewPODocument(po, TalkedTo, VendorName);
            //"<html>  <head>  <meta charset=\"utf-8\">  <title>Fax P.O.</title>  <style>   body{font:10pt/11pt Courier, monospace;}   </style>    </head>    <body>  <div>  <table width=\"600\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\">    <tr>      <td>TO:</td>      <td>${TalkedTo}</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>COMPANY:</td>      <td>${VendorName}</td>      <td>${VendorNumber}</td>    </tr>    <tr>      <td>FAX:</td>      <td>${VendorFax}</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>FROM:</td>      <td>${POFaxFrom}</td>      <td>${IssueDateTime}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td colspan=\"2\">&quot;THE GOLDEN RULE&quot;: This PO covers ONLY the service type     and dollar amount stated during the dispatch conversation. If the amount of services should need to be changed,     please call for AUTHORIZATION while the driver is still on the scene with the member.</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td colspan=\"2\">=========================================================================</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>PO      #      :</td>      <td>${PurchaseOrderNumber}</td>      <td>&nbsp;&nbsp;&nbsp;Opened      By: ${CreateBy}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>SERVICE:</td>      <td>${ProductCategoryName}</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>ETA:</td>      <td colspan=\"2\">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;${ETAMinutes}      Minutes &nbsp;&nbsp; Safe:&nbsp;&nbsp;${Safe} Member Pay:&nbsp;&nbsp;${MemberPay}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td colspan=\"2\">========================= CUSTOMER      and LOCATION&nbsp;=========================</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Name:</td>      <td>${MemberName}</td>      <td>Member #:&nbsp;&nbsp;&nbsp;&nbsp;${MembershipNumber}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Telephone#:</td>      <td colspan=\"2\">${ContactNumber}&nbsp;&nbsp;&nbsp;Alternate: ${AlternateContact}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Loc:</td>      <td>${ServiceLocationDescription}</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Cross:</td>      <td>${ServiceLocationAddress}</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>City:</td>      <td colspan=\"2\">${ServiceLocationCityState} Zip: ${ServiceLocationPostalCode}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td colspan=\"2\">========================= DESTINATION INFORMATION&nbsp;=======================</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Dest:</td>      <td>${DestinationDescription}</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Address:</td>      <td>${DestinationAddress}</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>City:</td>      <td colspan=\"2\">${DestinationCityState} Zip: ${DestinationPostalCode}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td colspan=\"2\">========================= VEHICLE INFORMATION&nbsp;===========================</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Year:</td>      <td colspan=\"2\">${VehicleYear}&nbsp;&nbsp;&nbsp;&nbsp;Make: ${VehicleMake} Model: ${VehicleModel}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Desc:</td>      <td>${VehicleDescription}</td>      <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Color: ${VehicleColor}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>License:</td>      <td colspan=\"2\">${VehicleStateLicense}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Vin#: ${VehicleVin}</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>Chassis:</td>      <td colspan=\"2\"><table width=\"512\" border=\"0\" cellpadding=\"0\" cellspacing=\"0\">        <tr>          <td>${VehicleChassis}&nbsp;&nbsp;&nbsp;</td>          <td>Length:&nbsp;&nbsp;&nbsp;${VehicleLength}</td>          <td>Eng:&nbsp;&nbsp;&nbsp;${VehicleEngine}</td>          <td>Class:&nbsp;&nbsp;&nbsp;${VehicleClass}</td>        </tr>      </table></td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td colspan=\"2\">=========================================================================</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td colspan=\"3\">For questions about this dispatch, please  call ${VendorCallback} Option 1. For Billing questions, call ${VendorBilling}, or if you submit claims online at vendor.coach-net.com, you can also check your payment status online.</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td>&nbsp;</td>      <td>&nbsp;</td>      <td>&nbsp;</td>    </tr>    <tr>      <td colspan=\"3\">*** END OF TRANSMISSION*** SENT BY ${POFaxFrom} ${IssueDateTime}</td>    </tr>  </table>  </div>  </body>  </html> ";
            return PartialView("_ViewPODocument", document);
        }


        /// <summary>
        /// _s the call log.
        /// </summary>
        /// <returns></returns>
        public ActionResult _GetApproval()
        {
            logger.Info("POController _GetApproval Started");
            const string category = "MemberPayEstimate";

            logger.InfoFormat("POController _GetApproval Retrieving Contact Action by Category {0}", category);
            var actions = ReferenceDataRepository.GetContactAction(category);
            // CR : 1262 - Using Description instead of Name.
            ViewData[StaticData.ContactActions.ToString()] = actions.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);

            var contactActionsForTalkedTo = (from n in actions
                                             select new NameValuePair()
                                             {
                                                 Name = n.ID.ToString(),
                                                 Value = n.IsTalkedToRequired != null ? n.IsTalkedToRequired.ToString().ToLower() : "false"
                                             }).ToList<NameValuePair>();

            JavaScriptSerializer ser = new JavaScriptSerializer();

            string json = ser.Serialize(contactActionsForTalkedTo);
            ViewData["ContactActionsForTalkedTo"] = json;

            var programFacade = new ProgramMaintenanceFacade();
            List<ProgramInformation_Result> estimateInstructions = programFacade.GetProgramInfo(DMSCallContext.ProgramID, "InstructionScript", "EstimateOverage").OrderBy(x => x.Sequence).ToList();

            ViewBag.EstimateInstructions = estimateInstructions.Where(a => a.Name == "EstimateApprovalInstructions").ToList();

            logger.Info("POController _GetApproval Completed");
            return PartialView("_GetApproval");
        }



        public ActionResult _GetManagerApproval(int poId)
        {
            logger.Info("POController _GetManagerApproval Started");

            return PartialView("_GetManagerApproval", poId);
        }

        public ActionResult SubmitManagerApproval(int poId, bool isManagerApprovedThreshold, int ManagerApprovalPIN, string ManagerApprovalComments, decimal? serviceTotal, decimal? serviceMax)
        {
            logger.InfoFormat("POController - SubmitManagerApproval(), Parameters:  {0}", JsonConvert.SerializeObject(new
            {
                poID = poId,
                isManagerApprovedThreshold = isManagerApprovedThreshold,
                ManagerApprovalPIN = ManagerApprovalPIN,
                serviceTotal = serviceTotal,
                serviceMax = serviceMax
            }));
            OperationResult result = new OperationResult();
            var userRepository = new UserRepository();
            List<UserNameByPIN_Result> matchingUserNames = userRepository.GetUserNameByPin(ManagerApprovalPIN);
            if (matchingUserNames != null && matchingUserNames.Count > 0)
            {
                POFacade poFacade = new POFacade();
                poFacade.SubmitManagerApprovalThreshold(poId, isManagerApprovedThreshold, ManagerApprovalPIN, ManagerApprovalComments, matchingUserNames[0].UserID, matchingUserNames[0].Username, serviceTotal, serviceMax, LoggedInUserName, Request.RawUrl, Session.SessionID);
            }
            else
            {
                throw new DMSException("PIN number is not valid");
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// _s the call log.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [ValidateInput(true)]
        [HttpPost]
        public ActionResult SubmitApproval(EstimateApprovalModel model)
        {
            logger.Info("POController SubmitApproval Post Started");
            logger.InfoFormat("POController SubmitApproval for Service Request ID {0}", DMSCallContext.ServiceRequestID);

            var poFacade = new POFacade();
            //model.PhoneNumberCalled = DMSCallContext.StartCallData.ContactPhoneNumber;
            //model.PhoneTypeID = DMSCallContext.StartCallData.ContactPhoneTypeID;

            poFacade.UpdatePOOnApproval(DMSCallContext.CurrentPurchaseOrder.ID, DMSCallContext.ServiceRequestID, model, LoggedInUserName);

            if (DMSCallContext.CurrentPurchaseOrder != null)
            {
                DMSCallContext.CurrentPurchaseOrder.IsOverageApproved = model.IsApproved;
            }

            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            result.Data = model;
            logger.Info("POController SubmitApproval Post Completed");
            return Json(result);
        }
        #endregion

        #region Private Methods

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
        /// Gets the where clause XML.
        /// </summary>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        private string GetWhereClauseXML(POSearchCriteria searchCriteria)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");
                // PO Number
                if (!string.IsNullOrEmpty(searchCriteria.PONumber))
                {
                    writer.WriteAttributeString("PONumberOperator", "6");
                    writer.WriteAttributeString("PONumberValue", searchCriteria.PONumber);
                }
                // UserName
                if (!string.IsNullOrEmpty(searchCriteria.UserName))
                {
                    writer.WriteAttributeString("UserNameOperator", "2");
                    writer.WriteAttributeString("UserNameValue", searchCriteria.UserName);
                }
                // VendorNumber
                if (!string.IsNullOrEmpty(searchCriteria.VendorNumber))
                {
                    writer.WriteAttributeString("VendorNumberOperator", "6");
                    writer.WriteAttributeString("VendorNumberValue", searchCriteria.VendorNumber);
                }
                // Time
                if (!string.IsNullOrEmpty(searchCriteria.Time))
                {
                    writer.WriteAttributeString("TimeOperator", "2");
                    writer.WriteAttributeString("TimeValue", searchCriteria.Time);
                }

                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }
            return whereClauseXML.ToString();
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
            //TFS : 618
            copyPO.IsPreferredVendor = oldPo.IsPreferredVendor;
            PORepository repository = new PORepository();
            Program program = ReferenceDataRepository.GetProgramByID(DMSCallContext.ProgramID);
            VendorRepository vRepo = new VendorRepository();
            var vendorLocation = vRepo.GetVendorLocationByID(oldPo.VendorLocationID.GetValueOrDefault());
            copyPO.ThresholdPercentage = repository.GetPOThresholdPercentage(DMSCallContext.VehicleCategoryID.GetValueOrDefault(), DMSCallContext.ProductCategoryID.GetValueOrDefault(), vendorLocation != null ? vendorLocation.VendorID : 0, program.ClientID, DMSCallContext.ProgramID);
            #endregion

            return copyPO;
        }
        #endregion

    }
}
