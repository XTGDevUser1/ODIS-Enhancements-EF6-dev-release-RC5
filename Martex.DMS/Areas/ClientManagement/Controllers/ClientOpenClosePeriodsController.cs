using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Models;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    public partial class ClientInvoiceProcessingController : BaseController
    {
        #region Close Period
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.CLIENT_BUTTON_CLOSEPERIOD)]
        public ActionResult _ClosePeriod()
        {
            return PartialView();
        }

        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.CLIENT_BUTTON_CLOSEPERIOD)]
        [HttpPost]
        public ActionResult _ClosePeriodList([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside _Close Period List");
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
            ClientsFacade facade = new ClientsFacade();
            List<ClientClosePeriodList_Result> list = facade.GetClientInvoiceClosePeriods(pageCriteria);
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

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.CLIENT_BUTTON_CLOSEPERIOD)]
        [HttpPost]
        public ActionResult _ProcessClosePeriodList(List<int> scheduleID)
        {
            logger.InfoFormat("Inside _ProcessClosePeriodList() method in ClientInvoiceProcessingController");
            OperationResult result = new OperationResult();
            ClientsFacade facade = new ClientsFacade();
            facade.ProcessClientCloseList(scheduleID, string.Join(",", scheduleID), LoggedInUserName, Session.SessionID, Request.RawUrl);
            logger.Info("Processed closed period list successfully.");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

        #region Open Period
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.CLIENT_BUTTON_OPENPERIOD)]
        public ActionResult _OpenPeriod()
        {
            return PartialView();
        }

        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.CLIENT_BUTTON_OPENPERIOD)]
        [HttpPost]
        public ActionResult _OpenPeriodList([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside _Open Period List");
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
            ClientsFacade facade = new ClientsFacade();
            List<ClientOpenPeriodList_Result> list = facade.GetClientInvoiceOpenPeriods(pageCriteria);
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


        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.CLIENT_BUTTON_OPENPERIOD)]
        [HttpPost]
        public ActionResult _ProcessOpenPeriodList(int billingDefinitionInvoiceID, int billingScheduleID, int billingScheduleTypeID, int billingScheduleDateTypeID, int billingScheduleRangeTypeID, string description)
        {
            OperationResult result = new OperationResult();
            ClientsFacade facade = new ClientsFacade();
            try
            {
                logger.InfoFormat("Processing Billing Definition Invoice ID {0} and Billing ScheduleID {1}", billingDefinitionInvoiceID, billingScheduleID);
                facade.ProcessClientOpenList(billingDefinitionInvoiceID, billingScheduleID, billingScheduleTypeID, billingScheduleDateTypeID, billingScheduleRangeTypeID, LoggedInUserName, Session.SessionID, Request.RawUrl);
                result.ErrorMessage = string.Format("Processing Completed for {0}", description);
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.InnerException == null ? ex.Message : ex.InnerException.Message;
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.CLIENT_BUTTON_OPENPERIOD)]
        public ActionResult _GetClientOpenPeriodToBeProcessRecords(List<int> scheduleID)
        {
            logger.Info("Trying to get the open period to be processed records.");
            OperationResult result = new OperationResult();
            ClientsFacade facade = new ClientsFacade();
            var list = facade.GetClientOpenPeriodToBeProcessRecords(string.Join(",", scheduleID));
            logger.InfoFormat("Returned with {0} rows.", list.Count);
            result.Data = list;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.CLIENT_BUTTON_OPENPERIOD)]
        [HttpPost]
        public ActionResult _CreateEventLogLinkOpenPeriodProcess(List<ClientOpenPeriodToBeProcessRecords_Result> list)
        {
            OperationResult result = new OperationResult();
            try
            {
                logger.Info("Trying to create Event Log and Event Log Link records for Open Period Process");
                ClientsFacade facade = new ClientsFacade();
                facade.CreateClientOpenPeriodProcessEventLogs(LoggedInUserName, Session.SessionID, Request.RawUrl, string.Join(",", list.Select(u => u.BillingSchedueID)), string.Join(",", list.Select(u => u.BillingDefinitionInvoiceID)));
                logger.Info("Event Log and Event Log Link records created for Open Period Process.");
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                result.Status = OperationStatus.ERROR;
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion
    }
}
