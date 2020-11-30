using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.Common;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    public partial class MemberController
    {
        [DMSAuthorize]
        public ActionResult _Member_SRHistory(int memberID, int memberShipID)
        {
            logger.InfoFormat("Inside _Member_SRHistory of MemberController with member id:{0}", memberID);
            
            List<MemberManagementSRHistory_Result> list = new List<MemberManagementSRHistory_Result>();
            ViewData["MemberID"] = memberID;
            logger.Info("Call view with list of SRs");
            return PartialView(list);
        }

        public ActionResult _GetMemberSRHistory([DataSourceRequest] DataSourceRequest request, int memberID)
        {
            logger.InfoFormat("Inside _GetMemberSRHistory of MemberController. Attempt to get all the SR's List depending upon the GridCommand and MemberID:{0}", memberID);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "RequestNumber";
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
            List<MemberManagementSRHistory_Result> list = facade.GetMemberManagementSRHistory(pageCriteria, memberID);

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
            return Json(result, JsonRequestBehavior.AllowGet);

        }
    }
}
