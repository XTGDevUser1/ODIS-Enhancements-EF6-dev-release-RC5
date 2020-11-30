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
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    public partial class MemberController
    {
        /// <summary>
        /// Get Member or Membership claim list.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="memberShipID">The member ship ID.</param>
        /// <returns></returns>
        public ActionResult _MemberClaimList(int memberID, int memberShipID)
        {
            return PartialView(memberID);
        }

        /// <summary>
        /// _s the member ship claim list.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public ActionResult _MemberShipClaimList(int membershipID)
        {
            return PartialView(membershipID);
        }


        /// <summary>
        /// _s the member claims read.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        [NoCache]
        [HttpPost]
        public ActionResult _MemberClaimsRead([DataSourceRequest] DataSourceRequest request, int memberID)
        {
            MemberManagementFacade facade = new MemberManagementFacade();
            logger.Info("Inside Vendor Claim Search of Member Claim Controller. Attempt to get all Claims depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ClaimDate";
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
            List<Member_Claims_Result> list = facade.GetmemberClaims(memberID, null, pageCriteria);
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


        /// <summary>
        /// _s the member ship claims read.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        [NoCache]
        [HttpPost]
        public ActionResult _MemberShipClaimsRead([DataSourceRequest] DataSourceRequest request, int membershipID)
        {
            MemberManagementFacade facade = new MemberManagementFacade();
            logger.Info("Inside Vendor Claim Search of MemberShip Claim Controller. Attempt to get all Claims depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ClaimDate";
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
            List<Member_Claims_Result> list = facade.GetmemberClaims(null, membershipID, pageCriteria);
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
    }
}
