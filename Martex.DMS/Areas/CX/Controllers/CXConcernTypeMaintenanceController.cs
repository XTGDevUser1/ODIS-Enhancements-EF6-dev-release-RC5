using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.QA.Controllers
{
    [ValidateInput(false)]
    public class CXConcernTypeMaintenanceController : BaseController
    {
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_CX_CONCERN_TYPE_MAINTAINENCE)]
        public ActionResult Index()
        {
            var list = new List<QAConcernTypeList_Result>();
            return View(list);
        }

        public ActionResult _ConcernTypeList([DataSourceRequest] DataSourceRequest request)
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

            //Editing Required
            var facade = new QAFacade();
            List<QAConcernTypeList_Result> list = facade.GetQAConcernTypeList(pageCriteria);

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
        /// Deletes the Concern Type.
        /// </summary>
        /// <param name="concernTypeId">The concern type identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult DeleteConcernType(int? concernTypeId)
        {
            var result = new OperationResult
            {
                Status = OperationStatus.SUCCESS
            };
            var facade = new QAFacade();
            facade.DeleteConcernType(concernTypeId);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the Concern Type.
        /// </summary>
        /// <param name="concernTypeId">The concern type identifier.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        public ActionResult _GetConcernType(int? concernTypeId, string mode)
        {
            var concernType = new ConcernType();
            ViewData["mode"] = mode;
            if (concernTypeId.HasValue && concernTypeId.GetValueOrDefault() > 0)
            {
                var facade = new QAFacade();
                concernType = facade.GetConcernType(concernTypeId);
            }
            return PartialView("_GetConcernType", concernType);
        }

        /// <summary>
        /// Saves the Concern Type.
        /// </summary>
        /// <param name="concernType">Type of the concern.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _SaveConcernType(ConcernType concernType)
        {
            var result = new OperationResult
            {
                Status = OperationStatus.SUCCESS
            };
            var facade = new QAFacade();
            facade.SaveConcernType(concernType);
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
