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
    public partial class VendorHomeController
    {
        /// <summary>
        /// Gets the vendor_ location_ activity.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.CommentType, false)]
        public ActionResult _Vendor_Location_Activity(int vendorID, int vendorLocationID)
        {
            ViewData["VendorID"] = vendorID;
            ViewData["VendorLocationID"] = vendorLocationID;
            return PartialView();
        }

        /// <summary>
        /// Gets the vendor location activity list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="filterColumnName">Name of the filter column.</param>
        /// <param name="filterColumnValue">The filter column value.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        [NoCache]
        public JsonResult GetVendorLocationActivityList([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, string vendorLocationID)
        {
            int vendorLocationIDInt = 0;
            int.TryParse(vendorLocationID, out vendorLocationIDInt);
            logger.Info("Inside GetVendorActivityList() of VendorHomeController. Attempt to get Queue depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            ViewData["VendorLocationID"] = vendorLocationID;

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,

                WhereClause = GetCustomWhereClauseXml(filterColumnName, filterColumnValue)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            List<VendorLocationActivityList_Result> list = facade.GetVendorLocationActivityList(vendorLocationIDInt, pageCriteria);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0 && list[0].TotalRows.HasValue)
            {
                totalRows = list[0].TotalRows.Value;
            }
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            return Json(new DataSourceResult() { Data = list, Total = totalRows }, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Saves the vendor location activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public ActionResult SaveVendorLocationActivityComments(int CommentType, string Comments, int vendorLocationID)
        {
            OperationResult result = new OperationResult();
            facade.SaveVendorLocationActivityComments(CommentType, Comments, vendorLocationID, LoggedInUserName);

            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the vendor_ location_ activity_ add contact.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ContactMethod, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult _Vendor_Location_Activity_AddContact(int vendorID, int vendorLocationID)
        {
            logger.Info("Inside _Vendor_Location_Activity_AddContact() in VendorHomeController ");
            ViewData["VendorID"] = vendorID.ToString();
            ViewData["VendorLocationID"] = vendorLocationID.ToString();
            Activity_AddContact model = new Activity_AddContact();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR_LOCATION).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.ContactCategory.ToString()] = ReferenceDataRepository.GetContactCategoryForAddContact().ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);

            model.IsInbound = true;
            logger.Info("Returning Partial View '_Vendor_Activity_AddContact'");
            return View(model);
        }

        /// <summary>
        /// Saves the vendor location invoice activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult SaveVendorLocationActivityContact(Activity_AddContact model)
        {
            logger.Info("Inside SaveVendorLocationActivityContact() in VendorHomeController to save a Contact ");
            OperationResult result = new OperationResult();
            facade.SaveVendorLocationActivityContact(model, LoggedInUserName);
            result.Status = "Success";
            logger.Info("Contact Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
