using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.ActionFilters;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    public class ManageVendorGeographyLocationController : BaseController
    {
        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_VENDOR_LOCATION_GEOGRAPHY)]
        public ActionResult Index()
        {
            return View();
        }

        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_VENDOR_LOCATION_GEOGRAPHY)]
        [HttpPost]
        public ActionResult _Process(int vendorLocationID)
        {
            OperationResult result = new OperationResult();
            VendorManagementFacade facade = new VendorManagementFacade();
            try
            {
                facade.UpdateLatLongForVendorLocation(vendorLocationID, LoggedInUserName);
                result.Data = new { Information = string.Format("Update Geography Location for Vendor Location ID {0}", vendorLocationID) };
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR; 
                result.ErrorMessage = ex.Message;
            }
          
            return Json(result);
        }

        [NoCache]
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_VENDOR_LOCATION_GEOGRAPHY)]
        [HttpPost]
        public ActionResult VendorGeographyLocationList([DataSourceRequest] DataSourceRequest request, string vendorLocationID)
        {

            logger.Info("Inside VendorSearch of Vendor Home Controller. Attempt to get all Vendors depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "VendorLocationID";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filterList = new List<NameValuePair>();
            if (!string.IsNullOrEmpty(vendorLocationID))
            {
                try
                {
                    List<int> locaionList = vendorLocationID.Split(',').Select(int.Parse).ToList();
                }
                catch
                {
                    throw new DMSException("Vendor Location ID should be a valid value separated with ,");
                }
     
                filterList.Add(new NameValuePair() { Name = "VendorLocationIDValue", Value = vendorLocationID });
            }

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filterList.Count > 0 ? filterList.GetXML() : string.Empty
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorLocationGeographyListManage_Result> list = facade.GetVendorLocationGeographyList(pageCriteria);
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
