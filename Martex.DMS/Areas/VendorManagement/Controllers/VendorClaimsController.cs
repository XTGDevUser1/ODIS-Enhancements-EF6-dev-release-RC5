using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Facade;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    [DMSAuthorize]
    public class VendorClaimsController : BaseController
    {

        /// <summary>
        /// _s the vendor claims.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public ActionResult _VendorClaims(int vendorID)
        {
            logger.InfoFormat("Executing Vendor Claims for the Vendor ID {0}", vendorID);
            return PartialView(vendorID);
        }

        /// <summary>
        /// _s the vendor claims read.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [NoCache]
        [HttpPost]
        public ActionResult _VendorClaimsRead([DataSourceRequest] DataSourceRequest request,int vendorID)
        {
            VendorManagementFacade facade = new VendorManagementFacade();
            logger.Info("Inside Vendor Claim Search of Vendor Claim Controller. Attempt to get all Claims depending upon the GridCommand");
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
            List<Vendor_Claims_Result> list = facade.GetVendorClaims(pageCriteria, vendorID);
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
