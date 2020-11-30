using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Models;
using Martex.DMS.Areas.ClientManagement.Models;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities.Clients;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Model.Clients;

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    public partial class ClientInvoiceProcessingController : BaseController
    {
        protected ClientsFacade facade = new ClientsFacade();

        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CLIENT_INVOICEPROCESSING)]
        [ReferenceDataFilter(StaticData.POProductsForClientInvoice, false)]
        [ReferenceDataFilter(StaticData.BillingInvoiceLineStatus, false)]
        [ReferenceDataFilter(StaticData.BillingInvoiceDetailStatusPendingReady)]
        [ReferenceDataFilter(StaticData.BillingInvoiceDetailDisposition)]
        public ActionResult Index()
        {
            return View();
        }

        public ActionResult _InvoiceList()
        {
            ViewData["processingMode"] = "history";
            return PartialView();
        }



        [HttpPost]
        [DMSAuthorize]
        public ActionResult _GetClientInvoiceProcessingList([DataSourceRequest] DataSourceRequest request, ClientBillableInvoiceSearchCriteria model)
        {
            logger.Info("Inside _GetClientInvoiceProcessingList of ClientInvoiceProcessing Controller. Attempt to get all Client Invoices depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ClientName";
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
            List<BillingManageInvoicesList_Result> list = new List<BillingManageInvoicesList_Result>();
            // string status = (isHistoryMode.HasValue ? isHistoryMode.Value : false) ? "CLOSED" : "Open";
            if (!string.IsNullOrEmpty(model.Status))
            {
                list = facade.GetBillingManageInvoicesList(pageCriteria, model.Status);
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

        [HttpPost]
        [DMSAuthorize]
        public ActionResult _GetClientInvoiceLinesList([DataSourceRequest] DataSourceRequest request, int? billingInvoiceID, ClientBillableInvoiceSearchCriteria model)
        {
            logger.Info("Inside _GetClientInvoiceLinesList of ClientInvoiceProcessing Controller. Attempt to get all Client Invoices depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Sequence";
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

            List<BillingInvoiceLinesList_Result> list = new List<BillingInvoiceLinesList_Result>();
            list = facade.GetBillingInvoiceLinesList(pageCriteria, billingInvoiceID);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            return Json(result);
        }

        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _InsertClientInvoiceLines([DataSourceRequest] DataSourceRequest request, int? billingInvoiceID, BillingInvoiceLinesList_Result billingInvoiceLine)
        {
            OperationResult result = new OperationResult();
            facade.InsertVendorInvoiceLine(billingInvoiceLine, LoggedInUserName, billingInvoiceID.GetValueOrDefault(), Request.RawUrl, Session.SessionID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [AcceptVerbs(HttpVerbs.Post)]
        [NoCache]
        public ActionResult _DeleteClientInvoiceLines([DataSourceRequest] DataSourceRequest request, int? billingInvoiceID, BillingInvoiceLinesList_Result billingInvoiceLine)
        {
            OperationResult result = new OperationResult();
            result.Status = "Success";
            facade.DeleteVendorInvoiceLine(billingInvoiceLine, LoggedInUserName, billingInvoiceID.GetValueOrDefault(), Request.RawUrl, Session.SessionID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult _RefreshBillingInvoice(int? invoiceID, int? scheduleTypeID, int? scheduleDateTypeID, int? scheduleRangeTypeID, int? billingDefinitionInvoiceID)
        {
            logger.InfoFormat("Trying to refresh Billing Invoice for Invoice ID {0} Billing Definition Invoice ID {1}", invoiceID, billingDefinitionInvoiceID);
            OperationResult result = new OperationResult();
            facade.RefreshBillingInvoice(billingDefinitionInvoiceID, scheduleTypeID, scheduleDateTypeID, scheduleRangeTypeID, LoggedInUserName, Session.SessionID, Request.RawUrl);
            result.Status = "Success";
            logger.InfoFormat("Execution Completed for _RefreshBillingInvoice Invoice ID {0} Billing Definition Invoice ID {1}",invoiceID,billingDefinitionInvoiceID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult _RefreshAllBillingInvoices()
        {
            OperationResult result = new OperationResult();
            facade.RefreshAllBillingInvoices(LoggedInUserName, Session.SessionID, Request.RawUrl);
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);

        }

        public ActionResult _ClientBillableEventProcessingList(int? billingInvoiceLineID, string invoiceDescription, string invoiceLineDescription, string mode)
        {
            BillingVendorInvoiceNavigateModel model = new BillingVendorInvoiceNavigateModel();
            ViewData["CloseOpen"] = mode;
            model.BillingInvoiceLineID = billingInvoiceLineID;
            model.InvoiceDescription = invoiceDescription;
            model.InvoiceLineDescription = invoiceLineDescription;
            return View(model);
        }

        public ActionResult _GetClientBillableEventProcessingList([DataSourceRequest] DataSourceRequest request, int? billingInvoiceLineID)
        {
            logger.Info("Inside _GetClientBillableEventProcessingList of ClientInvoiceProcessing Controller. Attempt to get all Events depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "BillingInvoiceDetailID";
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
            ClientsFacade facade = new ClientsFacade();
            List<ClientInvoiceEventProcessingList_Result> list = new List<ClientInvoiceEventProcessingList_Result>();

            list = facade.GetClientInvoiceEventProcessingList(pageCriteria, billingInvoiceLineID);

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

        [HttpPost]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.BillingEvent, true)]
        //[ReferenceDataFilter(StaticData.BillingScheduleType, true)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        public ActionResult _SearchCriteria(ClientBillableInvoiceSearchCriteria model)
        {
            ClientBillableInvoiceSearchCriteria tempModel = model;
            ModelState.Clear();
            ViewData[StaticData.BillingDefinitionInvoice.ToString()] = ReferenceDataRepository.GetBillingDefinitionInvoice(model.ClientID.GetValueOrDefault()).ToSelectListItem(u => u.ID.ToString(), y => y.Description, true).ToList();

            if (model.FilterToLoadID.HasValue)
            {
                ClientBillableInvoiceSearchCriteria dbModel = tempModel.GetView(model.FilterToLoadID) as ClientBillableInvoiceSearchCriteria;
                if (dbModel != null)
                {
                    return PartialView(dbModel);
                }
            }
            return PartialView(tempModel.GetModelForSearchCriteria());
        }

        [HttpPost]
        [DMSAuthorize]
        public ActionResult _SelectedCriteria(ClientBillableInvoiceSearchCriteria model)
        {
            return PartialView(model.GetModelForSearchCriteria());
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _BillingDefinitionInvoiceLine(int? recordID)
        {
            // WHERE recordID = BillingDefinitionInvoiceID
            ClientBillableInvoiceSearchCriteriaPartial model = new ClientBillableInvoiceSearchCriteriaPartial();
            List<CheckBoxLookUp> line = new List<CheckBoxLookUp>();
            List<BillingDefinitionInvoiceLine> lineDetails = ReferenceDataRepository.GetBillingDefinitionInvoiceLine(recordID.GetValueOrDefault());
            if (model.BillingDefinitionInvoiceLine == null)
            {
                foreach (var status in lineDetails)
                {
                    line.Add(new CheckBoxLookUp()
                    {
                        ID = status.ID,
                        Name = status.Name,
                        Selected = false
                    });
                }
                model.BillingDefinitionInvoiceLine = line;
            }
            return PartialView(model);
        }

        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.BillingInvoiceDetailStatusPendingReady)]
        public ActionResult _BillingEventDetailStatusUpdate(BillingEventDetailStatus billingEventDetailStatus)
        {
            return PartialView(billingEventDetailStatus);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _UpdateSelectedBillingEventDetailStatus(int ToStatus, string ElementsToBeUpadted, string FromStatusText, string ToStatusText)
        {
            OperationResult result = new OperationResult();
            int[] elemntsList = null;
            try
            {
                if (ElementsToBeUpadted != null && ElementsToBeUpadted != "")
                {
                    elemntsList = Array.ConvertAll(ElementsToBeUpadted.Split(','), s => int.Parse(s));
                    int totalRecordsToProcess = elemntsList.Count();
                    facade.UpdateSelectedBillingEventDetailStatus(ToStatus, elemntsList, FromStatusText, ToStatusText, LoggedInUserName, Session.SessionID, Request.RawUrl);
                    result.Status = "Success";
                    result.Data = totalRecordsToProcess + " Record(s) moved from the status " + FromStatusText.ToUpper() + " to " + ToStatusText.ToUpper() + " status.";
                }
                else
                {
                    result.Status = "Failure";
                    result.Data = "Please select one or more event details to be updated with the status: " + FromStatusText.ToUpper() + " ";
                }
            }
            catch (Exception ex)
            {
                result.Status = "Exception";
                result.Data = ex.ToString();
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.BillingInvoiceDetailDisposition)]
        public ActionResult _BillingEventDetailDispositionUpdate(BillingEventDetailDisposition billingEventDetailDisposition)
        {
            return PartialView(billingEventDetailDisposition);
        }

        [DMSAuthorize]
        [NoCache]
        public ActionResult _UpdateSelectedBillingEventDetailDisposition(int ToDisposition, string ElementsToBeUpadted, string FromDispositionText, string ToDispositionText)
        {
            OperationResult result = new OperationResult();
            int[] elemntsList = null;
            if (ElementsToBeUpadted != null && ElementsToBeUpadted != "")
            {
                elemntsList = Array.ConvertAll(ElementsToBeUpadted.Split(','), s => int.Parse(s));
                int totalRecordsToProcess = elemntsList.Count();
                facade.UpdateSelectedBillingEventDetailDisposition(ToDisposition, elemntsList, FromDispositionText, ToDispositionText, LoggedInUserName, Session.SessionID, Request.RawUrl);
                result.Status = "Success";
                result.Data = totalRecordsToProcess + " Record(s) moved from the disposition " + FromDispositionText.ToUpper() + " to " + ToDispositionText.ToUpper() + " disposition.";
            }
            else
            {
                result.Status = "Failure";
                result.Data = "Please select one or more event details to be updated with the Disposition: " + FromDispositionText.ToUpper() + " ";
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
