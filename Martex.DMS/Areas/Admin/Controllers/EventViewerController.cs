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
using Martex.DMS.DAL.DAO.Admin;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.Areas.Admin.Controllers
{
    public class EventViewerController : BaseController
    {
        #region Message Listing

        [DMSAuthorize]
        public ActionResult Index()
        {
            logger.Info("Inside Index of Event Viewer. Attempt to call the view");
            EventViewerSearchCriteria model = null;
            model = model.GetModelForSearchCriteria();
            return View(model);
        }

        [HttpPost]
        [ReferenceDataFilter(StaticData.EventCategory)]
        [ReferenceDataFilter(StaticData.EventTypes)]
        [ReferenceDataFilter(StaticData.Events)]
        [ReferenceDataFilter(StaticData.Users)]
        [ReferenceDataFilter(StaticData.ApplicationNames)]
        public ActionResult _SearchCriteria(EventViewerSearchCriteria model)
        {
            EventViewerSearchCriteria tempModel = model;
            ModelState.Clear();
            if (model!= null && model.FilterToLoadID.HasValue)
            {
                EventViewerSearchCriteria dbModel = tempModel.GetView(model.FilterToLoadID) as EventViewerSearchCriteria;
                if (dbModel != null)
                {
                    return PartialView(dbModel);
                }
            }
            return PartialView(tempModel.GetModelForSearchCriteria());
        }

        [HttpPost]
        public ActionResult _SelectedCriteria(EventViewerSearchCriteria model)
        {
            return PartialView(model.GetModelForSearchCriteria());
        }

        [NoCache]
        [DMSAuthorize]
        public ActionResult List([DataSourceRequest] DataSourceRequest request, EventViewerSearchCriteria model)
        {
            logger.Info("Inside List() of Event Viewer Controller. Attempt to get all Message depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ID";
            string sortOrder = "DESC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = model.GetFilterClause();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.GetXML()
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }

            List<EventLogList_Result> list = new List<EventLogList_Result>();
            if (filter.Count > 0)
            {
                list = EventViewerService.List(pageCriteria, LoggedInUserName);
            }
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

    }
}
