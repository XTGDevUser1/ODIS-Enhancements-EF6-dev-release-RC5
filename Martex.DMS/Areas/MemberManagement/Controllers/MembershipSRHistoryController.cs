using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.BLL.Model;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Areas.Application.Models;
using System.Text;
using System.Xml;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using Martex.DMS.Areas.Application.Controllers;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    [DMSAuthorize]
    public partial class MemberController
    {

        public ActionResult _Membership_SRHistory(int membershipID)
        {
            logger.InfoFormat("Inside _Membership_SRHistory of MemberController with member id:{0}", membershipID);
            
            List<MemberShipManagementSRHistory_Result> list = new List<MemberShipManagementSRHistory_Result>();
            ViewData["MembershipID"] = membershipID;
            logger.Info("Call view with list of SRs");
            return PartialView(list);
        }

        public ActionResult _GetMembershipSRHistory([DataSourceRequest] DataSourceRequest request, int membershipID)
        {
            logger.InfoFormat("Inside _GetMembershipSRHistory of MemberController. Attempt to get all the SR's List depending upon the GridCommand and MembershipID:{0}", membershipID);
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
            List<MemberShipManagementSRHistory_Result> list = facade.GetMemberShipManagementSRHistory(pageCriteria, membershipID);

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
