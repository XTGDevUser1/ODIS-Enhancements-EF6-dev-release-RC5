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

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    public class ClientInvoiceBatchesController : BaseController
    {
        protected ClientsFacade facade = new ClientsFacade();

        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CLIENT_INVOICEBATCHES)]
        public ActionResult Index()
        {
            return View();
        }

        /// <summary>
        /// Gets the clients_ payment_ runs.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.BatchStatus, false)]
        public ActionResult _Clients_Payment_Runs()
        {
            ViewData["HistorySearchCriteriaDatePreset"] = ReferenceDataRepository.GetHistorySearchCriteriaDatePreset().ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            List<ClientBatchList_Result> list = new List<ClientBatchList_Result>();
            return View(list);
        }

        public ActionResult _GetClientInvoiceBatchList([DataSourceRequest] DataSourceRequest request, VendorInvoicePaymentRunsCriteria searchCriteria)
        {
            logger.Info("Inside _GetClientInvoiceBatchList of ClientInvoiceBatchesController. Attempt to get all Vendor Batch List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "CreateDate";
            string sortOrder = "DESC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<ClientBatchList_Result> list = new List<ClientBatchList_Result>();
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
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
            list = facade.GetClientBatchList(pageCriteria);

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

        /// <summary>
        /// Gets the filter clause.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public List<NameValuePair> GetFilterClause(VendorInvoicePaymentRunsCriteria model)
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

        public ActionResult GetBatchPaymentRunsList([DataSourceRequest] DataSourceRequest request, int BatchID)
        {
            logger.Info("Inside GetBatchPaymentRunsList of ClientInvoiceBatchesController. Attempt to get all Client Batch Payment Runs List depending upon the GridCommand");

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
            List<ClientBatchPaymentRunsList_Result> list = facade.GetClientBatchPaymentRunsList(pageCriteria, BatchID);

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
