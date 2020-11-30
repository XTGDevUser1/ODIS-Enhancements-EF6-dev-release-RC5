using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;

namespace Martex.DMS.Areas.Claims.Controllers
{
    public partial class ClaimsPaymentHistoryController : BaseController
    {
        protected ClaimsFacade facade = new ClaimsFacade();

        public ActionResult Index()
        {
            return View();
        }

        [ReferenceDataFilter(StaticData.BatchStatus, false)]
        public ActionResult _Claim_Payment_Runs()
        {
            ViewData["HistorySearchCriteriaDatePreset"] = ReferenceDataRepository.GetHistorySearchCriteriaDatePreset().ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            List<ClaimBatchList_Result> list = new List<ClaimBatchList_Result>();
            return View(list);
        }

        public ActionResult _GetClaimBatchList([DataSourceRequest] DataSourceRequest request, VendorInvoicePaymentRunsCriteria searchCriteria)
        {
            logger.Info("Inside _GetVendorInvoiceBatchList of ClaimsPaymentHistoryController. Attempt to get all Claim Batch List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "CreateDate";
            string sortOrder = "DESC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<ClaimBatchList_Result> list = new List<ClaimBatchList_Result>();
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
            list = facade.GetClaimBatchList(pageCriteria);

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

        public ActionResult GetBatchPaymentRunsList([DataSourceRequest] DataSourceRequest request, int batchID)
        {
            logger.Info("Inside GetBatchPaymentRunsList of ClaimsPaymentHistoryController. Attempt to get all Claim Batch Payment Runs List depending upon the GridCommand");

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
            List<ClaimBatchPaymentRunsList_Result> list = facade.GetClaimBatchPaymentRunsList(pageCriteria, batchID);
            
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
