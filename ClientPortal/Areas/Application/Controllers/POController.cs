using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Areas.Common.Controllers;
using Martex.DMS.DAL;
using ClientPortal.ActionFilters;
using ClientPortal.Areas.Application.Models;
using ClientPortal.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using System.Text;
using Martex.DMS.DAO;
using ClientPortal.Models;
using Martex.DMS.DAL.Entities;
using System.Globalization;
using System.Threading;
using System.Xml;
using Kendo.Mvc.UI;
using Kendo.Mvc.Extensions;

namespace ClientPortal.Areas.Application.Controllers
{
    public class POController : BaseController
    {
        #region Public Methods
        /// <summary>
        /// 
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
        /// 
        /// </summary>
        /// <param name="id"></param>
        /// <returns></returns>
        public ActionResult GetRequestID(string id)
        {
            logger.InfoFormat("Inside GetMemberID() of Memebr. Call by the grid with the request {0}, try to returns the Json object", id);
            return Json(new { IdValue = id }, JsonRequestBehavior.AllowGet);

        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
        /// <param name="searchCriteria"></param>
        /// <returns></returns>
        [DMSAuthorize]

        [NoCache]
        [ValidateInput(false)]
        public ActionResult _Search([DataSourceRequest] DataSourceRequest request, POSearchCriteria searchCriteria)
        {
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
        /// 
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
        [NoCache]
        [DMSAuthorize]
        // [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.TAB_DISPATCH_REQUEST_PO)]
        public ActionResult _Index()
        {
            var loggedInUser = LoggedInUserName;
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.ENTER_PO_TAB, "Enter PO Tab", loggedInUser, DMSCallContext.ServiceRequestID, EntityNames.SERVICE_REQUEST, Session.SessionID);
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            PurchaseOrder po = new PurchaseOrder();
            POFacade facade = new POFacade();

            VendorInformation_Result vendorInfoResult = new VendorInformation_Result();
            List<POForServiceRequest_Result> list = new List<POForServiceRequest_Result>();
            ViewBag.MemberDispatchFee = facade.GetMemberPayDispatchFee(DMSCallContext.ProgramID);
            ViewBag.Mode = "view";
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
            //facade.GetServiceCoverageLimit(DMSCallContext.ProgramID);

            ViewBag.IsDealerTow = facade.IsDealTow(DMSCallContext.ProgramID);

            list = facade.GetPOForServiceRequest(DMSCallContext.ServiceRequestID, null, null);
            ViewBag.TalkedTo = DMSCallContext.TalkedTo;
            ViewBag.IsPosAvailable = false;
            ViewBag.IsDollarLimtEnable = IsDollarLimitEnable();
            
            if (DMSCallContext.CurrentPurchaseOrder != null)
            {
                ViewBag.IsPosAvailable = true;
                ViewBag.Mode = "Edit";
                po = DMSCallContext.CurrentPurchaseOrder;
                if (po.VendorLocationID.HasValue)
                {
                    vendorInfoResult = facade.GetVendorInformation(po.VendorLocationID.Value, po.ServiceRequestID);

                }
                else
                {
                    vendorInfoResult = facade.GetVendorInformation(DMSCallContext.VendorLocationID, DMSCallContext.ServiceRequestID);
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
            if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Issued" || po.PurchaseOrderStatu.Name == "Issued-Paid"
                    || po.PurchaseOrderStatu.Name == "Pending") && po.DataTransferDate == null)
            {
                ViewBag.Mode = "Edit";
            }
            else if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Issued" ||
                po.PurchaseOrderStatu.Name == "Issued-Paid") && po.DataTransferDate != null)
            {
                ViewBag.Mode = "Re-SendPOEdit";
            }
            else
            {
                ViewBag.Mode = "view";
            }
            //KB: The lines above already set this value.
            if (po.IsServiceCovered.HasValue)
            {
                ViewBag.IsPrimaryServiceCovered = po.IsServiceCovered;
            }
            if (!ViewBag.IsPrimaryServiceCovered)
            {
                if (ViewBag.IsDealerTow)
                {
                    if (!string.IsNullOrEmpty(DMSCallContext.DealerIDNumber))
                    {
                        po.DispatchFee = po.DispatchFee.HasValue ? po.DispatchFee.Value : 0.00m;
                        po.DealerIDNumber = DMSCallContext.DealerIDNumber;

                        po.DipatchFeeBillToID = (int?)ViewBag.Client;
                    }
                    else
                    {
                        //if (!po.DispatchFee.HasValue)
                        //{
                        //    po.DispatchFee = string.IsNullOrEmpty(ViewBag.MemberDispatchFee) ? 0.00m : decimal.Parse(ViewBag.MemberDispatchFee);
                        //}
                        po.DipatchFeeBillToID = (int?)ViewBag.Member;
                    }
                }
                //else
                //{
                //    if (!po.DispatchFee.HasValue)
                //    {
                //        po.DispatchFee = string.IsNullOrEmpty(ViewBag.MemberDispatchFee) ? 0.00m : decimal.Parse(ViewBag.MemberDispatchFee);
                //    }
                //}
            }
            else
            {
                po.DispatchFee = po.DispatchFee.HasValue ? po.DispatchFee.Value : 0.00m;
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
            ViewBag.VendorInfo = vendorInfoResult;
            ViewBag.PO = po;
            ViewBag.TaxAmount = po.TaxAmount;
            ViewBag.CurrentPOrderId = po.ID;
            logger.Info("PO ID: " + po.ID.ToString());
            return PartialView(list);
        }

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
        /// 
        /// </summary>
        /// <param name="poId"></param>
        /// <param name="mode"></param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.VehicleCategory, false)]
        [ReferenceDataFilter(StaticData.SendType, false)]
        [ReferenceDataFilter(StaticData.PODetailsProduct, true)]
        [ReferenceDataFilter(StaticData.ETA)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.MemberPayType, false)]
        [ReferenceDataFilter(StaticData.CurrencyType, false)]
        [ReferenceDataFilter(StaticData.PODetailsUOM, false)]
        [NoCache]
        public ActionResult _AddPO(int poId, string mode)
        {
            POFacade facade = new POFacade();
            ViewBag.Client = ReferenceDataRepository.GetBillTo("Client");
            ViewBag.Member = ReferenceDataRepository.GetBillTo("Member");
            ViewBag.IsPosAvailable = true;
            PurchaseOrder po = facade.GetPOById(poId);

            VendorInformation_Result vendorInfoResult = facade.GetVendorInformation(po.VendorLocationID.GetValueOrDefault(), po.ServiceRequestID);
            if (string.IsNullOrEmpty(po.FaxPhoneNumber))
            {
                po.FaxPhoneNumber = vendorInfoResult.FaxPhoneNumber;
            }
            ViewBag.VendorInfo = vendorInfoResult;
            ViewBag.Mode = mode;
            if (po.PurchaseOrderStatu != null && (po.PurchaseOrderStatu.Name == "Issued" ||
               po.PurchaseOrderStatu.Name == "Issued-Paid") && po.DataTransferDate != null)
            {
                ViewBag.Mode = "Re-SendPOEdit";
            }
            ViewBag.ServiceCoverageLimit = facade.GetServiceCoverageLimit(DMSCallContext.ProgramID);
            ViewBag.MemberDispatchFee = facade.GetMemberPayDispatchFee(DMSCallContext.ProgramID);
            ViewBag.CurrentPOrderId = po.ID;
            ViewBag.TaxAmount = po.TaxAmount;
            ViewBag.IsDealerTow = facade.IsDealTow(DMSCallContext.ProgramID);
            ViewBag.IsPrimaryServiceCovered = po.IsServiceCovered;
            ViewBag.TalkedTo = DMSCallContext.TalkedTo;
            ViewBag.ServiceCoverageLimit = po.CoverageLimit ?? 0;
            ViewBag.IsDollarLimtEnable = IsDollarLimitEnable();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
            DMSCallContext.CurrentPurchaseOrder = po;
            DMSCallContext.CurrentPODetails = null;
            return PartialView(po);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="poId"></param>
        /// <param name="poStatus"></param>
        /// <param name="poDataTransferDate"></param>
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
        /// 
        /// </summary>
        /// <param name="poId"></param>
        /// <returns></returns>
        public ActionResult AddGOA(PurchaseOrder currentPO)
        {
            POFacade facade = new POFacade();
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            //bool isAlreadyGOA = facade.IsAlreadyGOA(poId);
            //if (!isAlreadyGOA)
            //{
            //   PurchaseOrder po= facade.AddGOA(poId, this.GetProfile().UserName, Request.RawUrl, Session.SessionID);
            //    result.Data = new { id = po.ID };
            //}
            //else
            //{
            //    result.Status = OperationStatus.BUSINESS_RULE_FAIL;
            //}
            PurchaseOrder goaPO = facade.AddGOA(currentPO, this.GetProfile().UserName, Request.RawUrl, Session.SessionID);
            result.Data = new { id = goaPO.ID };
            DMSCallContext.CurrentPODetails = null;
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <returns></returns>
        public ActionResult IsMemberPaymentBalance()
        {
            POFacade facade = new POFacade();
            bool value = facade.IsMemberPaymentBalance(DMSCallContext.ServiceRequestID);
            return Json(new { Data = value }, JsonRequestBehavior.AllowGet);


        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="poId"></param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.POCancelReason, true)]
        [NoCache]
        public ActionResult _CancelPO(int poId)
        {
            PurchaseOrder po = new PurchaseOrder();
            po.ID = poId;
            return PartialView(po);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="po"></param>
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

        public ActionResult _CopyPO(int poId)
        {
            int? vehicleTypeId = DMSCallContext.VehicleTypeID;
            POFacade facade = new POFacade();

            ViewData[StaticData.VehicleCategory.ToString()] = ReferenceDataRepository.GetVehicleCategories(vehicleTypeId.GetValueOrDefault()).ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);
            PurchaseOrder po = new PurchaseOrder();
            po = facade.GetPOById(poId);

            return PartialView("_CopyPO", po);
        }

        [ValidateInput(false)]
        [NoCache]
        public ActionResult CopyPO(PurchaseOrder po, int? copyServiceType)
        {
            var loggedInUser = LoggedInUserName;
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            POFacade facade = new POFacade();
            PurchaseOrder oldPo = facade.GetPOById(po.ID);
            PurchaseOrder newPO = CopyPo(oldPo);
            //NP 9/18: Added due to Bug 1612
            newPO.AdminstrativeRating = oldPo.AdminstrativeRating;
            newPO.SelectionOrder = oldPo.SelectionOrder;
            newPO.ContractStatus = oldPo.ContractStatus;
            newPO.ServiceRating = oldPo.ServiceRating;
            //End
            newPO.VehicleCategoryID = po.VehicleCategoryID;
            newPO.ProductID = copyServiceType;
            newPO.CreateBy = loggedInUser;
            newPO.ModifyBy = loggedInUser;
            ISPs_Result isps = new ISPs_Result();
            isps.ProductID = copyServiceType;
            isps.VendorLocationID = newPO.VendorLocationID.Value;

            po = facade.AddOrUpdatePO(newPO, "CopyPO", null, isps, DMSCallContext.ProgramID, Request.RawUrl, Session.SessionID);
            result.Data = po.ID;
            return Json(result);
        }

        public JsonResult GetCopyPOProduct(int? weightId)
        {
            IEnumerable<SelectListItem> list = ReferenceDataRepository.GetPOCopyProduct(DMSCallContext.VehicleTypeID, weightId).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            //ViewData[StaticData.POCopyProduct.ToString()] = list;
            return Json(list, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="command"></param>
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
        /// 
        /// </summary>
        /// <param name="id"></param>
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
        /// 
        /// </summary>
        /// <param name="poID"></param>
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
                });
            }
            logger.Info("PO Details Retrived for " + poID.GetValueOrDefault().ToString());
            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetail>() });
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="poID"></param>
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

                //poID.Value;
                if (TryUpdateModel<PurchaseOrderDetailsModel>(poOrderDetails))
                {
                    //poOrderDetails.CreateBy = this.GetProfile().UserName;
                    //poOrderDetails.CreateDate = DateTime.Now;
                    //poOrderDetails.ModifyBy = this.GetProfile().UserName;
                    //poOrderDetails.ModifyDate = DateTime.Now;
                    var itemInList = poDetailsList.Where(x => x.Sequence == poOrderDetails.Sequence).FirstOrDefault();
                    if (itemInList == null)
                    {
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
                        poDetailsList.Add(poOrderDetails);
                        //   facade.Add(poOrderDetails);
                        // poDetailsList = facade.GetPurchaseOrderDetails(poID.Value);
                        DMSCallContext.CurrentPODetails = poDetailsList;
                    }
                    else
                    {
                        poOrderDetails = itemInList;
                    }

                    /*return Json(new DataSourceResult()
                    {
                        Data = poDetailsList.Where(po => po.Mode != "Deleted").OrderBy(po => po.Sequence).Select(x => new
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
                    });*/
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
        /// 
        /// </summary>
        /// <param name="id"></param>
        /// <param name="sequence"></param>
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
                // poOrderDetails = facade.GetPODetailsByID(id);
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
                    //poOrderDetails.ModifyBy = this.GetProfile().UserName;
                    //poOrderDetails.ModifyDate = DateTime.Now;
                    //facade.PODetailUpdate(poOrderDetails);
                    //poDetailsList = facade.GetPurchaseOrderDetails(poOrderDetails.PurchaseOrderID);
                    DMSCallContext.CurrentPODetails = poDetailsList;
                    /*return Json(new DataSourceResult()
                    {
                        Data = poDetailsList.Where(po => po.Mode != "Deleted").OrderBy(po => po.Sequence).Select(x => new
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
                    }
                    );*/
                    return Json(ModelState.ToDataSourceResult());
                }
            }
            catch (Exception)
            {

            }

            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetailsModel>() });
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="po"></param>
        /// <param name="TalkedTo"></param>
        /// <param name="VendorName"></param>
        /// <param name="ETAHours"></param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SendPO(PurchaseOrder po, string TalkedTo, string VendorName, int? ETAHours)
        {
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
            facade.SendPO(po, status, TalkedTo, VendorName, DMSCallContext.ContactLogID, currentUser, Request.RawUrl, Session.SessionID);



            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="currentID"></param>
        /// <param name="poID"></param>
        /// <param name="sequence"></param>
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
                // facade.PODetailsDetete(currentID);
                // poDetailsList = facade.GetPurchaseOrderDetails(2);
                PurchaseOrderDetailsModel poOrderDetails = poDetailsList.Where(p => p.ID == poDetailsModel.ID && p.Sequence == poDetailsModel.Sequence).FirstOrDefault<PurchaseOrderDetailsModel>();
                poDetailsList.Remove(poOrderDetails);
                if (poOrderDetails.Mode != "Insert")
                {
                    poOrderDetails.Mode = "Deleted";
                    poDetailsList.Add(poOrderDetails);
                }
                DMSCallContext.CurrentPODetails = poDetailsList;
                /*return Json(new DataSourceResult()
                {
                    Data = poDetailsList.Where(po => po.Mode != "Deleted").Select(x => new
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
                }
                );*/
                return Json(ModelState.ToDataSourceResult());

            }
            catch (Exception)
            {

            }

            return Json(new DataSourceResult() { Data = new List<PurchaseOrderDetailsModel>() });
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="po"></param>
        /// <param name="mode"></param>
        /// <param name="action"></param>
        /// <param name="TalkedTo"></param>
        /// <param name="VendorName"></param>
        /// <param name="ETAHours"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult AddOrUpdate(PurchaseOrder po, string mode, string action, string TalkedTo, string VendorName, int? ETAHours)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            string userName = LoggedInUserName;
            po.CreateBy = userName;
            po.ModifyBy = userName;
            po.CreateDate = DateTime.Now;
            po.ModifyDate = DateTime.Now;
            if (mode == "Add")
            {
                po.VendorLocationID = DMSCallContext.VendorLocationID;
            }
            POFacade facade = new POFacade();
            if (ETAHours.HasValue)
            {
                po.ETAMinutes = po.ETAMinutes.HasValue ? (po.ETAMinutes.Value + (60 * ETAHours.Value)) : (60 * ETAHours.Value);
            }
            if (mode != "Re-SendPOEdit")
            {
                po = facade.AddOrUpdatePO(po, mode, DMSCallContext.CurrentPODetails, null, DMSCallContext.ProgramID, Request.RawUrl, Session.SessionID);
            }
            DMSCallContext.TalkedTo = TalkedTo;
            bool isSendPO = false;
            if (action == "SendPO")
            {
                // && po.PurchaseOrderStatu.Name == "Pending"
                string status = "Issued";
                /* Set the status to Issued-Paid in the following situations:
                 * Pay by company credit card
                 * ServiceTotalAmount = MemberPortion
                 * member is paying the ISP for the full amount
                 * Old Logic
                 */
                /* If ISNULL(CompanyCreditCardNumber,' ') <> ' '  Then 'Issued-Paid'
                   If IsServiceCovered=0 AND IsMemberAmountCollectedByVendor=1 AND MemberServiceAmount=TotalServiceAmount Then 'Issued-Paid'
                    Else 'Issued'
                 */

                //if ( (po.IsMemberAmountCollectedByVendor.HasValue && po.IsMemberAmountCollectedByVendor.Value) || 
                //        po.MemberAmountDueToCoachNet == po.TotalServiceAmount || 
                //        (po.MemberServiceAmount == po.TotalServiceAmount &&
                //        !string.IsNullOrEmpty(po.CompanyCreditCardNumber)))
                //{
                //    status = "Issued-Paid";
                //}
                if ((po.IsServiceCovered.HasValue && !po.IsServiceCovered.Value &&
                    po.IsMemberAmountCollectedByVendor.HasValue && po.IsMemberAmountCollectedByVendor.Value && (po.MemberServiceAmount == po.TotalServiceAmount))
                    || (po.IsPayByCompanyCreditCard ?? false)) // !string.IsNullOrEmpty(po.CompanyCreditCardNumber) - no need to check if the value exists.
                {
                    status = "Issued-Paid";
                }

                facade.SendPO(po, status, TalkedTo, VendorName, DMSCallContext.ContactLogID, userName, Request.RawUrl, Session.SessionID);
                isSendPO = true;

            }
            logger.InfoFormat("Status of PO : {0}", po.PurchaseOrderStatu.Name);
            DMSCallContext.CurrentPurchaseOrder = po;
            DMSCallContext.CurrentPODetails = null;
            result.Data = new { id = po.ID, isSendPOSuccess = isSendPO };
            // Reset the IsCallMadeToVendor flag to allow users to navigate through the list.Do this if only the PO is issued. - TFS : 1348
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
            return Json(result);
        }
        /// <summary>
        /// 
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
        /// 
        /// </summary>
        /// <param name="poId"></param>
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
        /// 
        /// </summary>
        /// <param name="po"></param>
        /// <returns></returns>
        [ValidateInput(false)]
        [NoCache]
        public ActionResult RejectAndClear(PurchaseOrder po)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            if (po.ID > 0)
            {
                POFacade facade = new POFacade();
                facade.PODisable(po.ID);
                logger.Info("PO ID:" + po.ID.ToString() + "is rejected !");
            }
            DMSCallContext.CurrentPurchaseOrder = null;
            DMSCallContext.CurrentPODetails = null;
            DMSCallContext.RejectVendorOnDispatch = true;
            // Need this item on Dispatch tab
            DMSCallContext.VendorLocationID = po.VendorLocationID.GetValueOrDefault();
            return Json(result);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="po"></param>
        /// <param name="mode"></param>
        /// <param name="ETAHours"></param>
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
                //po = facade.GetPOById(poId);
                return PartialView("_AddGOA", po);
            }
        }


        #endregion

        #region Private Methods
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

        private PurchaseOrder CopyPo(PurchaseOrder oldPo)
        {
            PurchaseOrder copyPO = new PurchaseOrder();
            copyPO.ServiceRequestID = oldPo.ServiceRequestID;
            copyPO.OriginalPurchaseOrderID = oldPo.ID;
            copyPO.ContactMethodID = oldPo.ContactMethodID;
            //copyPO.PurchaseOrderNumber = nextNumber.GetValueOrDefault().ToString();
            // copyPO.PurchaseOrderStatusID = poStatus.ID;
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
            //copyPO.CreateBy = currentUser;
            //copyPO.CreateDate = DateTime.Now;
            //copyPO.ModifyDate = DateTime.Now;
            //copyPO.ModifyBy = currentUser;

            return copyPO;
        }
        #endregion

    }
}
