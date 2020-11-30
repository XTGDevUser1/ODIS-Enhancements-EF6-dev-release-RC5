using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.DAL.Common;
using Martex.DMS.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.QA.Controllers
{
    [ValidateInput(false)]
    public class CXConcernMaintenanceController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CX_CONCERN_MAINTAINENCE)]
        [ReferenceDataFilter(StaticData.ConcernTypes, true)]
        public ActionResult Index()
        {
            var list = new List<QAConcernList_Result>();
            return View();
        }


        /// <summary>
        /// _s the concern list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="concernTypeId">The concern type identifier.</param>
        /// <returns></returns>
        public ActionResult _ConcernList([DataSourceRequest] DataSourceRequest request, int? concernTypeId)
        {
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ID";// Provide Default Sort Column
            string sortOrder = "ASC";// Provide Default Sort Order E.g: ASC or DESC
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

            var facade = new QAFacade();
            var list = facade.GetQAConcernList(pageCriteria, concernTypeId);

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

        /// <summary>
        /// Deletes the concern.
        /// </summary>
        /// <param name="concernId">The concern identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult DeleteConcern(int? concernId)
        {
            var result = new OperationResult
            {
                Status = OperationStatus.SUCCESS
            };
            var facade = new QAFacade();
            facade.DeleteConcern(concernId);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the concern.
        /// </summary>
        /// <param name="concernId">The concern identifier.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ConcernTypes, true)]
        public ActionResult _GetConcern(int? concernId, string mode)
        {
            var concern = new Concern();
            ViewData["mode"] = mode;
            if (concernId.HasValue && concernId.GetValueOrDefault() > 0)
            {
                var facade = new QAFacade();
                concern = facade.GetConcern(concernId);
            }
            return PartialView("_GetConcern", concern);
        }

        /// <summary>
        /// Saves the concern.
        /// </summary>
        /// <param name="concern">The concern.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _SaveConcern(Concern concern)
        {
            var result = new OperationResult
            {
                Status = OperationStatus.SUCCESS
            };
            var facade = new QAFacade();
            facade.SaveConcern(concern);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
