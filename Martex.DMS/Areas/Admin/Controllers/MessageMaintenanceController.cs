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
using Martex.DMS.DAL.DAO.MessageMaintenance;
using Martex.DMS.DAL;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.Admin.Controllers
{
    public class MessageMaintenanceController : BaseController
    {
        #region Message Listing

        [DMSAuthorize]
        public ActionResult Index()
        {
            logger.Info("Inside Index of Message Maintenance. Attempt to call the view");
            return View();
        }

        [NoCache]
        [DMSAuthorize]
        public ActionResult MessageList([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside Message List() of MessageMaintenanceController. Attempt to get all Message depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "MessageID";
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

            List<MessageList_Result> list = MessageMaintenanceService.MessageList(pageCriteria);
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

        #endregion

        #region Message CRUD

        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.MessageType, false)]
        [ReferenceDataFilter(StaticData.MessageScope, false)]
        public ActionResult MessageDetails(int? recordID, string mode)
        {
            ViewBag.PageMode = mode;
            Message message = MessageMaintenanceService.Get(recordID.GetValueOrDefault(), true);
            return PartialView(message);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveMessageDetails(Message model)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Trying to Insert or Update Message record for ID {0}", model.ID);
            MessageMaintenanceService.SaveMessageDetails(model, LoggedInUserName);
            logger.InfoFormat("Message Insert or Update success for ID {0}", model.ID);
            return Json(result);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult DeleteMessage(int recordID)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Trying to delete Message record for ID {0}", recordID);
            MessageMaintenanceService.DeleteMessage(recordID, LoggedInUserName);
            logger.InfoFormat("Message record deleted for ID {0}", recordID);
            return Json(result);
        }
        #endregion
    }
}
