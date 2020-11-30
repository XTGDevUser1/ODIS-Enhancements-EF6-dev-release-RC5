using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.Common;
using Martex.DMS.Models;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO.ListViewFilters;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    /// <summary>
    /// Vendor Invoices Controller
    /// </summary>
    public partial class VendorInvoicesController : BaseController
    {
        public VendorInvoiceFacade facade = new VendorInvoiceFacade();
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_VENDOR_INVOICES)]
        public ActionResult Index()
        {
            List<Martex.DMS.DAL.VendorInvoicesList_Result> list = new List<VendorInvoicesList_Result>();
            return View(list);
        }

        /// <summary>
        /// _s the search criteria.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.VendorSearchCriteriaNameFilterType, true)]
        [ReferenceDataFilter(StaticData.InvoiceTypes, true)]
        [ReferenceDataFilter(StaticData.ExportBatchesForInvoice,true)]
        [HttpPost]
        public ActionResult _SearchCriteria(VendorInvoiceSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SearchCriteria() model in VendorInvoicesController with Model:{0}", model);
            var tempHoldModel = model.GetModelForSearchCriteria();
            ModelState.Clear();
            logger.Info("Returns the View");
            ViewData["DefaultVendorInvoiceListDays"] = AppConfigRepository.GetValue(AppConfigConstants.DEFAULT_VENDOR_INVOICE_LIST_DAYS);
            
            if (model.FilterToLoadID.HasValue)
            {
                VendorInvoiceSearchCriteria dbModel = tempHoldModel.GetView(model.FilterToLoadID) as VendorInvoiceSearchCriteria;
                if (dbModel != null)
                {
                    return View(dbModel);
                }
            }
            return View(tempHoldModel);
        }

        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult _SelectedCriteria(VendorInvoiceSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SelectedCriteria() model in VendorInvoicesController with Model:{0}", model);
            logger.Info("Returns the View");
            return PartialView("_SelectedCriteria", model.GetModelForSearchCriteria());
        }

        /// <summary>
        /// _s the get vendor invoice list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        public ActionResult _GetVendorInvoiceList([DataSourceRequest] DataSourceRequest request, VendorInvoiceSearchCriteria searchCriteria)
        {
            logger.Info("Inside _GetVendorInvoiceList of Vendor Invoice Search. Attempt to get all Vendor Invoices depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ToBePaidDate";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = searchCriteria.GetFilterSearchCritera();

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
            List<VendorInvoicesList_Result> list = new List<VendorInvoicesList_Result>();
            if (filter.Count > 0)
            {
                list = facade.GetVendorInvoiceList(pageCriteria);
            }

            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }

        
        /// <summary>
        /// _s the delete vendor invoice.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public ActionResult _DeleteVendorInvoice(int vendorInvoiceID)
        {
            logger.InfoFormat("Inside _DeleteVendorInvoice() method in Vendor Invoice Controller with Invoice ID:{0}", vendorInvoiceID);
            OperationResult result = new OperationResult();
            facade.DeleteVendorInvoice(vendorInvoiceID);
            result.Status = "Success";
            logger.Info("Invoice Deleted Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [ReferenceDataFilter(StaticData.BatchStatus, false)]
        public ActionResult _Vendor_Invoices_Payment_Runs()
        {
            ViewData["HistorySearchCriteriaDatePreset"] = ReferenceDataRepository.GetHistorySearchCriteriaDatePreset().ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            List<VendorInvoiceBatchList_Result> list = new List<VendorInvoiceBatchList_Result>();
            return View(list);
        }

        public ActionResult _GetVendorInvoiceBatchList([DataSourceRequest] DataSourceRequest request, VendorInvoicePaymentRunsCriteria searchCriteria)
        {
            logger.Info("Inside _GetVendorInvoiceBatchList of VendorInvoiceController. Attempt to get all Vendor Batch List depending upon the GridCommand");
            
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "CreateDate";
            string sortOrder = "DESC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<VendorInvoiceBatchList_Result> list = new List<VendorInvoiceBatchList_Result>();
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            //if (string.IsNullOrEmpty(searchCriteria.PONumber) && searchCriteria.DateSectionFromDate == null && searchCriteria.DateSectionToDate == null)
            //{
            //    return Json(result);
            //}
            List<NameValuePair> filter = GetFilterClause(searchCriteria);

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
            list = facade.GetVendorInvoiceBatchList(pageCriteria);

            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }

            result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);

            return Json(result);
        }

        private List<NameValuePair> GetFilterClause(VendorInvoicePaymentRunsCriteria model)
        {
            List<NameValuePair> filterList = new List<NameValuePair>();
            if (model.BatchStatusID.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "BatchStatusID", Value = model.BatchStatusID.Value.ToString() });
            }
            if (model.DateSectionFromDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "FromDate", Value = model.DateSectionFromDate.Value.ToString() });
            }
            if (model.DateSectionToDate.HasValue)
            {
                filterList.Add(new NameValuePair() { Name = "ToDate", Value = model.DateSectionToDate.Value.AddDays(1).ToString() });
            }
            return filterList;
        }

        public ActionResult GetBatchPaymentRunsList([DataSourceRequest] DataSourceRequest request,int BatchID)
        {
            logger.Info("Inside GetBatchPaymentRunsList of VendorInvoiceController. Attempt to get all Vendor Batch Payment Runs List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "CreateDate";
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
            List<BatchPaymentRunsList_Result> list = facade.GetBatchPaymentRunsList(pageCriteria, BatchID);

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.GetValueOrDefault();
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            return Json(result);
        }
    }
}
