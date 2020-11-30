using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Kendo.Mvc.UI;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    [DMSAuthorize]
    public partial class MemberController
    {
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Membership_Products(int membershipID)
        {
            logger.InfoFormat("Inside _Membership_Products of MemberManagement with membership id:{0}", membershipID);

            ViewData["MembershipID"] = membershipID;
            return PartialView();
        }


        [NoCache]
        [HttpPost]
        public ActionResult _MembershipProductsList([DataSourceRequest] DataSourceRequest request, int membershipID)
        {
            MemberManagementFacade facade = new MemberManagementFacade();
            logger.Info(string.Format("Inside _MembershipProductsList in MemberManagement Controller. Attempt to get membership products for membership id {0}", membershipID));
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Product";
            string sortOrder = "ASC";
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
            List<MemberShipProducts_Result> list = facade.GetMembershipProducts(membershipID, pageCriteria);
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

        [DMSAuthorize]
        [NoCache]
        public ActionResult _Member_Products(int memberID)
        {
            logger.InfoFormat("Inside _Members_Products of MemberManagement with member id:{0}", memberID);

            ViewData["MemberID"] = memberID;
            return PartialView();
        }

    }
}
