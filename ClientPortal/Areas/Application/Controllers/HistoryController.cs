using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Areas.Common.Controllers;
using ClientPortal.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using ClientPortal.Models;
using Kendo.Mvc.UI;
using ClientPortal.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.BLL.Model;

namespace ClientPortal.Areas.Application.Controllers
{
    public class HistoryController : BaseController
    {
        [DMSAuthorize]
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
        [DMSAuthorize]
        public ActionResult GetPODetails(int serviceRequestID)
        {
            return View("_PODetails");
        }

        public ActionResult GetSelectedSearchCriteria(HistorySearchCriteria model)
        {
            model = GetModel(model);
            Session["HistorySearchCriteria"] = model;
            return View("_SelectedCriteria", model);
        }
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
            model = GetModel(model);
            Session["HistorySearchCriteria"] = model;
            return View("_SearchCriteriaRight", model);
        }
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
        [DMSAuthorize]
        public ActionResult List([DataSourceRequest] DataSourceRequest request)
        {
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

            List<ServiceRequestHistoryList_Result> listResult = facade.GetServiceRequestHistory(pageCriteria, (Guid)GetLoggedInUser().ProviderUserKey, GetFilterClause());

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

        [ReferenceDataFilter(StaticData.VehicleCategory, false)]
        [ReferenceDataFilter(StaticData.SendType, false)]
        [ReferenceDataFilter(StaticData.PODetailsProduct, true)]
        [ReferenceDataFilter(StaticData.ETA)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.MemberPayType, false)]
        [ReferenceDataFilter(StaticData.CurrencyType, false)]
        [ReferenceDataFilter(StaticData.PODetailsUOM, false)]
        [NoCache]
        public ActionResult PODetails(int poId)
        {
            POFacade facade = new POFacade();
            ViewBag.Client = ReferenceDataRepository.GetBillTo("Client");
            ViewBag.Member = ReferenceDataRepository.GetBillTo("Member");
            ViewBag.IsPosAvailable = true;
            PurchaseOrder po = facade.GetPOById(poId);
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
            VendorInformation_Result vendorInfoResult = facade.GetVendorInformation(po.VendorLocationID.GetValueOrDefault(), po.ServiceRequestID);
            if (string.IsNullOrEmpty(po.FaxPhoneNumber))
            {
                po.FaxPhoneNumber = vendorInfoResult.FaxPhoneNumber;
            }
            ViewBag.IsOverLimit = po.TotalServiceAmount > po.CoverageLimit ? "Over limit" : string.Empty;
            ViewBag.MemberPays = po.MemberServiceAmount;
            ViewBag.CoachNetServiceAmount = po.CoachNetServiceAmount;
            ViewBag.VendorInfo = vendorInfoResult;
            ViewBag.ServiceCoverageLimit = facade.GetServiceCoverageLimit(programID);
            ViewBag.MemberDispatchFee = facade.GetMemberPayDispatchFee(programID);
            ViewBag.CurrentPOrderId = po.ID;
            ViewBag.TaxAmount = po.TaxAmount;
            ViewBag.ServiceTotal = po.TotalServiceAmount;
            ViewBag.IsDealerTow = facade.IsDealTow(programID);
            ViewBag.IsPrimaryServiceCovered = po.IsServiceCovered;
            // ViewBag.TalkedTo = DMSCallContext.TalkedTo;
            ViewBag.ServiceCoverageLimit = po.CoverageLimit ?? 0;
            ViewBag.IsDollarLimtEnable = IsDollarLimitEnable();
            ViewBag.SubTotal = po.TotalServiceAmount - po.TaxAmount;
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
            return PartialView("_PODetails", po);
        }

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

        #endregion

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

            return model;
        }

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

        [DMSAuthorize]
        public JsonResult GetMake(string vehicleType, string vehicleYear)
        {
            int vehicleTypeID = 0;
            int.TryParse(vehicleType, out vehicleTypeID);

            double vehicleYearDouble = 0;
            double.TryParse(vehicleYear, out vehicleYearDouble);

            return Json(ReferenceDataRepository.GetHistorySearchCriteriaMake(vehicleTypeID, vehicleYearDouble), JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        public JsonResult GetModelForVehicle(string vehicleType, string make)
        {
            int vehicleTypeID = 0;
            int.TryParse(vehicleType, out vehicleTypeID);
            return Json(ReferenceDataRepository.GetHistorySearchCriteriaModel(vehicleTypeID, make), JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        public JsonResult GetYears(string vehicleType)
        {
            List<SelectListItem> list = null;
            int vehicleTypeID = 0;
            int.TryParse(vehicleType, out vehicleTypeID);
            switch (vehicleTypeID)
            {
                case 1:
                    return Json(ReferenceDataRepository.GetHistorySearchCriteriaVehicleMakeModelYear(), JsonRequestBehavior.AllowGet);
                case 2:
                    list = GetConstantYears();
                    break;
                case 3:
                    list = GetConstantYears();
                    break;
                case 4:
                    list = GetConstantYears();
                    break;
                default:
                    list = new List<SelectListItem>();
                    break;


            }
            return Json(list, JsonRequestBehavior.AllowGet);
        }

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

        [DMSAuthorize]
        public ActionResult GetServiceRequestDetails(int serviceRequestID)
        {
            logger.InfoFormat("Trying to retrieve Service Request Details for the ID {0}", serviceRequestID);
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            string loggedInUserName = GetLoggedInUser().UserName;
            QueueFacade queueFacade = new QueueFacade();
            List<ServiceRequest_Result> serviceRequestResult = queueFacade.Get(loggedInUserName, Request.RawUrl, null, serviceRequestID.ToString(), false, HttpContext.Session.SessionID);

            List<NameValuePair> listQuestionAnswer = queueFacade.GetQuestionAnswerForServiceRequest(serviceRequestID);
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
            logger.Info("Details retrieving finished");
            return View("_ServiceRequestDetails", serviceRequestResult);
        }

    }


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
