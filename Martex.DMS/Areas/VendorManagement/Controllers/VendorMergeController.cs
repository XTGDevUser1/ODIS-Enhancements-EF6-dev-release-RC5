using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using Martex.DMS.Areas.VendorManagement.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Model;
using System.Text;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    public class VendorMergeController : BaseController
    {
        VendorManagementFacade vMFacade = new VendorManagementFacade();
        POFacade poFacade = new POFacade();
        VendorMergeFacade facade = new VendorMergeFacade();

        /// <summary>
        /// Indexes the specified vendor ID.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_VENDOR_MERGE)]
        public ActionResult Index(int? vendorID)
        {
            logger.Info("Inside Index() of VendorMergeController");
            if (vendorID != null)
            {
                List<VendorLocationsList_Result> vlList = vMFacade.GetVendorLocationsList(vendorID.Value);
                IEnumerable<SelectListItem> list = vlList.Where(a => a.VendorLocationID > 0).OrderBy(x => x.VendorLocationID).ToSelectListItem(x => x.VendorLocationID.ToString(), y => y.LocationAddress, false);
                ViewData["VendorLocations_Source"] = new SelectList(list, "Value", "Text");
                if (vlList.Count > 1)
                {
                    int vendorLocationID = vlList[1].VendorLocationID.GetValueOrDefault();
                    ViewData["vendorDetails_Source"] = poFacade.GetVendorInformation(vendorLocationID, null);
                }
            }
            logger.Info("Returning View");
            return View();
        }

        /// <summary>
        /// _s the get vendor location transaction list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="prefixName">Name of the prefix.</param>
        /// <returns></returns>
        public ActionResult _GetVendorLocationTransactionList([DataSourceRequest] DataSourceRequest request, int vendorLocationID,string prefixName)
        {
            ReferenceDataRepository repo = new ReferenceDataRepository();
            logger.Info("Inside _GetVendorLocationTransactionList of VendorMergeController. Attempt to get all Vendor Invoices depending upon the GridCommand");
            ViewData["prefixName"] = prefixName.ToString();
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ToBePaidDate";
            string sortOrder = "DESC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<VendorLocationTransactionList_Result> list = new List<VendorLocationTransactionList_Result>();
            int totalRows = 0;
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

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
            list = repo.GetVendorLocationTransactionList(pageCriteria, vendorLocationID);

            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.Value;
            }

            result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);


            return Json(result);
        }

        /// <summary>
        /// Gets the vendor transaction data.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="prefixName">Name of the prefix.</param>
        /// <returns></returns>
        public ActionResult GetVendorTransactionData(int vendorLocationID, string prefixName)
        {
            logger.Info("Inside GetVendorTransactionData() of VendorMergeController");
            ReferenceDataRepository repo = new ReferenceDataRepository();
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortDirection = "ASC",
                PageSize = 10
            };
            List<VendorLocationTransactionList_Result> list = new List<VendorLocationTransactionList_Result>();
            list = repo.GetVendorLocationTransactionList(pageCriteria, vendorLocationID);
            ViewData["vendorLocationID"] = vendorLocationID;
            ViewData["prefixName"] = prefixName.ToString();
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            return PartialView("_VendorLocationTransactionList", list);
        }

        /// <summary>
        /// Gets the vendor details of vendor.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="prefixName">Name of the prefix.</param>
        /// <returns></returns>
        public ActionResult GetVendorDetailsOfVendor(int vendorID, string prefixName)
        {
            logger.Info("Inside GetVendorDetailsOfVendor() of VendorMergeController");
            List<VendorLocationsList_Result> vlList = vMFacade.GetVendorLocationsList(vendorID);
            IEnumerable<SelectListItem> list = vlList.Where(a => a.VendorLocationID > 0).OrderBy(x => x.VendorLocationID).ToSelectListItem(x => x.VendorLocationID.ToString(), y => y.LocationAddress, false);
            ViewData["VendorLocations"] = new SelectList(list, "Value", "Text");
            ViewData["vendorDetails_" + prefixName]="";
            ViewData["prefixName"] = prefixName;
            VendorInformation_Result result = new VendorInformation_Result();
            result.ID = 0;
            result.VendorStatus = "Inactive";
            result.VendorName = "The selected vendor is deleted";
            if (vlList.Count > 1)
            {
                int vendorLocationID = vlList[1].VendorLocationID.GetValueOrDefault();
                result = poFacade.GetVendorInformation(vendorLocationID, null);
            }
            return PartialView("_VendorDetailsList", result);
        }

        /// <summary>
        /// _s the get vendor duplicates.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public ActionResult _GetVendorDuplicates(int vendorID)
        {
            logger.InfoFormat("Inside _GetVendorDuplicates() in VendorMergeController with vendorID: {0}", vendorID);
            //PageCriteria pageCriteria = new PageCriteria()
            //{
            //    StartInd = 1,
            //    EndInd = 10,
            //    SortDirection = "ASC",
            //    PageSize = 10
            //};
            //List<DuplicateVendors_Result> list = facade.GetDuplicateVendor(pageCriteria, vendorID);
            //int totalRows = 0;
            //if(list.Count>0)
            //{
            //    totalRows = list.Count;
            //}
            //logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
            return View();
        }

        /// <summary>
        /// Gets the vendor duplicates.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult GetVendorDuplicates([DataSourceRequest] DataSourceRequest request, int vendorID)
        {
            logger.Info("Inside GetVendorDuplicates() of VendorMergeController. Attempt to get all Users depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "VendorID";
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
            UsersFacade userFacade = new UsersFacade();
            List<DuplicateVendors_Result> list = facade.GetDuplicateVendor(pageCriteria, vendorID);

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
        /// Merges the vendor.
        /// </summary>
        /// <param name="sourceVendorID">The source vendor ID.</param>
        /// <param name="targetVendorID">The target vendor ID.</param>
        /// <returns></returns>
        public ActionResult MergeVendor(int sourceVendorID, int targetVendorID,int sourceVendorLocationID, int targetVendorLocationID)
        {
            logger.InfoFormat("Inside MergeVendor() of VendorMergeController with SourceVendorID: {0} and TargetVendorID: {1}", sourceVendorID, targetVendorID);
            OperationResult result = new OperationResult();
            facade.MergeVendors(sourceVendorID, targetVendorID, sourceVendorLocationID, targetVendorLocationID,LoggedInUserName,Request.RawUrl,Session.SessionID);
            result.Status = "Success";
            logger.Info("Vendor Merged Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
