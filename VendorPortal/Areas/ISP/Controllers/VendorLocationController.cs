using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.DAL.Common;
using VendorPortal.Common;
using VendorPortal.ActionFilters;
using VendorPortal.Models;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Model;

namespace VendorPortal.Areas.ISP.Controllers
{
    public partial class VendorLocationController : BaseController
    {
        #region Vendor Location
        [DMSAuthorize]
        [NoCache]
        public ActionResult _Vendor_Locations(int? vendorID)
        {
            if (vendorID == null)
            {
                logger.Warn("Executing _Vendor_Locations in VendorLocationController, vendorID is null");
            }
            return PartialView(vendorID.GetValueOrDefault());
        }

        /// <summary>
        /// Binds the vendor locations.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public ActionResult BindVendorLocations(int vendorID)
        {
            logger.InfoFormat("Get Vendor Locations related to the Vendor whose ID is :{0} ", vendorID);
            VendorManagementFacade facade = new VendorManagementFacade();
            IEnumerable<SelectListItem> list = facade.GetVendorLocationsList(vendorID).OrderBy(x => x.VendorLocationID).ToSelectListItem(x => x.VendorLocationID.ToString(), y => y.LocationAddress, false);
            logger.InfoFormat("Get the Vendor Locations of count:{0}", list.Count());
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the vendor location address.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public ActionResult GetVendorLocationAddress(int vendorLocationID)
        {
            logger.InfoFormat("Inside the GetVendorLocationAddress() method with Vendor Location ID:{0}", vendorLocationID);
            OperationResult result = new OperationResult();
            VendorManagementFacade facade = new VendorManagementFacade();
            result.Data = facade.GetVendorLocationAddress(vendorLocationID);
            result.Status = "Success";
            logger.InfoFormat("Gets the Address of Vendor Location ID:{0}", vendorLocationID);
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Saves the vendor location.
        /// </summary>
        /// <param name="VendorLocation">The vendor location.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult SaveVendorLocation(VendorLocationModel VendorLocation)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Adding a vendor location with Name:{0}", VendorLocation.LocationName);
            int VendorID = VendorLocation.VendorID;
            var currentUser = LoggedInUserName;
            VendorManagementFacade facade = new VendorManagementFacade();
            int VendorLocationID = facade.SaveVendorLocationAddress(VendorLocation, VendorID, currentUser);

            //  Add Event log record for Add Vendor.
            result.Data = VendorLocationID;
            var eventLoggerFacade = new EventLoggerFacade();
            long eventlogId = eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.ADD_VENDOR_LOCATION, "Add Vendor Location", currentUser, VendorLocationID, EntityNames.VENDOR_LOCATION, Session.SessionID);
            eventLoggerFacade.CreateRelatedLogLinkRecord(eventlogId, VendorID, EntityNames.VENDOR);
            // Event Log Adding Completed.

            logger.InfoFormat("Added Vendor Location Added successfully with Vendor ID:{0} and Vendor Location ID:{1} ", VendorID, VendorLocationID);
            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Deletes the vendor location.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public ActionResult DeleteVendorLocation(int vendorLocationID)
        {
            OperationResult result = new OperationResult();
            VendorManagementFacade facade = new VendorManagementFacade();
            logger.InfoFormat("Inside DeleteVendorLocation() of Vendor Lcoation Controller with the vendorLocationID {0}", vendorLocationID);
            if (ModelState.IsValid)
            {
                // delete data                    
                facade.DeleteVendorLocation(vendorLocationID);
                logger.InfoFormat("The record with vendorLocationID {0} has been Deleted", vendorLocationID);
                result.OperationType = "Success";
                result.Status = "Success";
                return Json(result, JsonRequestBehavior.AllowGet);
            }
            var errorList = GetErrorsFromModelStateAsString();
            logger.Error(errorList);
            throw new DMSException(errorList);
        }

        /// <summary>
        /// Adds the vendor location.
        /// </summary>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult AddVendorLocation(int? VendorID)
        {
            logger.Info("Attempting to add a vendor location");
            ViewData["VendorId"] = VendorID;
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                SortColumn = "ID",
                SortDirection = "ASC",
                PageSize = 10
            };
            VendorManagementFacade facade = new VendorManagementFacade();

            IEnumerable<SelectListItem> list = facade.GetVendorLocations(pageCriteria, VendorID).ToSelectListItem(x => x.VendorLocation.ToString(), y => y.LocationAddress + ", " + y.StateProvince + " " + y.PostalCode + " " + y.CountryCode, true);
            ViewData[StaticData.LocationList.ToString()] = new SelectList(list, "Value", "Text");

            logger.Info("Return Partial View '_AddVendorLocation'");
            return PartialView("_AddVendorLocation");
        }

        /// <summary>
        /// Gets the vendor locations.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="VendorId">The vendor id.</param>
        /// <returns></returns>
        public ActionResult _GetVendorLocations([DataSourceRequest] DataSourceRequest request, int? VendorId)
        {
            logger.Info("Inside _GetVendorLocations() of VendorHomeController. Attempt to get all Vendor Locations depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "LocationAddress";
            string sortOrder = "ASC";
            if (request != null && request.Sorts != null && request.Sorts.Count > 0)
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
            VendorManagementFacade facade = new VendorManagementFacade();
            List<VendorLocations_Result> list = facade.GetVendorLocations(pageCriteria, VendorId);

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
        #endregion
    }
}
