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


namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    public class VendorTemporaryCCHistoryController : BaseController
    {
        public VendorTemporaryCCHistoryFacade facade = new VendorTemporaryCCHistoryFacade();

        public ActionResult Index()
        {
            return View();
        }

        [ReferenceDataFilter(StaticData.BatchStatus, false)]
        public ActionResult _Temporary_CC_Payment_Runs()
        {
            ViewData["HistorySearchCriteriaDatePreset"] = ReferenceDataRepository.GetTemporaryCCSearchCriteriaDatePreset().ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            List<TemporaryCCBatchList_Result> list = new List<TemporaryCCBatchList_Result>();
            return View(list);
        }

        public ActionResult _GetTemporaryCCBatchList([DataSourceRequest] DataSourceRequest request, VendorInvoicePaymentRunsCriteria searchCriteria)
        {
            logger.Info("Inside _GetTemporaryCCBatchList of VendorTemporaryCCHistoryController. Attempt to get all CC Batch List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "CreateDate";
            string sortOrder = "DESC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<TemporaryCCBatchList_Result> list = new List<TemporaryCCBatchList_Result>();
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };
            logger.Info("Logging the event Search_Temp_CC_History");
            EventLoggerFacade eventLogfacade = new EventLoggerFacade();
            eventLogfacade.LogEvent(Request.RawUrl, EventNames.SEARCH_TEMP_CC_HISTORY, "Search Temporary Credit Card History", LoggedInUserName, Session.SessionID);

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
            list = facade.GetVendorCCProcessingList(pageCriteria);

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

        public ActionResult GetTemporaryCCBatchPaymentRunsList([DataSourceRequest] DataSourceRequest request, int BatchID,string GLAccountName)
        {
            logger.Info("Inside GetTemporaryCCBatchPaymentRunsList of VendorTemporaryCCHistoryController. Attempt to get all Temporary CC Batch Payment Runs List depending upon the GridCommand");

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
            List<TemporaryCCBatchPaymentRunsList_Result> list = facade.GetTemporaryCCBatchPaymentRunsList(pageCriteria, BatchID, GLAccountName);

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

        public ActionResult TempCCGLAccountList([DataSourceRequest] DataSourceRequest request, int BatchID)
        {
            logger.Info("Inside TempCCGLAccountList of VendorTemporaryCCHistoryController. Attempt to get all Temp CC GLAccount List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
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
            List<TempCCGLAccountList_Result> list = facade.TempCCGLAccountList(pageCriteria, BatchID);

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
