using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using System.Text;
using Martex.DMS.ActionFilters;
using Martex.DMS.Models;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    /// <summary>
    /// Vendor Invoices Controller
    /// </summary>
    public partial class VendorInvoicesController
    {
        //
        // GET: /VendorManagement/VendorInvoice_Activity_Controller/
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.CommentType, false)]
        public ActionResult _Vendor_Invoices_Activity(int vendorInvoiceID, int vendorID)
        {
            logger.InfoFormat("Inside _Vendor_Invoices_Activity of VendorInvoiceController with Vendor Invoice id:{0}", vendorInvoiceID);
            ViewData["VendorInvoiceID"] = vendorInvoiceID;
            ViewData["VendorID"] = vendorID;
            logger.Info("Call view with list of Activities");
            return PartialView();
        }

        /// <summary>
        /// _s the get vendor invoice activity list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="filterColumnName">Name of the filter column.</param>
        /// <param name="filterColumnValue">The filter column value.</param>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public ActionResult _GetVendorInvoiceActivityList([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, int vendorInvoiceID)
        {
            logger.InfoFormat("Inside _GetVendorInvoiceActivityList of VendorInvoiceController. Attempt to get all the Ativity List depending upon the GridCommand and VendorInvoiceID:{0}", vendorInvoiceID);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "Type";
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

                WhereClause = GetCustomWhereClauseXml(filterColumnName, filterColumnValue)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            List<VendorInvoiceActivityList_Result> list = facade.GetVendorInvoiceActivityList(pageCriteria, vendorInvoiceID);

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

        /// <summary>
        /// Gets the custom where clause XML.
        /// </summary>
        /// <param name="columnName">Name of the column.</param>
        /// <param name="filterValue">The filter value.</param>
        /// <returns></returns>
        public string GetCustomWhereClauseXml(string columnName, string filterValue)
        {
            StringBuilder WhereClauseXml = new StringBuilder();
            if (!string.IsNullOrEmpty(columnName) && !string.IsNullOrEmpty(filterValue))
            {
                WhereClauseXml.Append("<ROW><Filter");
                string filterFinalValue = ((filterValue.Replace("&", "")).Replace("<", "")).Replace("\"", "");
                WhereClauseXml.Append(" ");
                WhereClauseXml.AppendFormat("{0}Operator=\"{1}\" ", columnName, 11);
                WhereClauseXml.AppendFormat(" {0}Value=\"{1}\"", columnName, filterFinalValue);
                WhereClauseXml.Append("></Filter></ROW>");
            }

            return WhereClauseXml.ToString();
        }

        /// <summary>
        /// Saves the vendor invoice activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="VendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public ActionResult SaveVendorInvoiceActivityComments(int CommentType, string Comments, int VendorInvoiceID)
        {
            logger.Info("Inside SaveVendorInvoiceActivityComments() in VendorInvoiceController to save a comment ");
            OperationResult result = new OperationResult();
            facade.SaveVendorInvoiceActivityComments(CommentType, Comments, VendorInvoiceID, LoggedInUserName);

            result.Status = "Success";
            logger.Info("Comment Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the vendor_ invoices_ activity_ add contact.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ContactMethod, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult _Vendor_Invoices_Activity_AddContact(int vendorInvoiceID, int vendorID)
        {
            logger.Info("Inside _Vendor_Invoices_Activity_AddContact() in VendorInvoiceController ");
            ViewData["VendorInvoiceID"] = vendorInvoiceID.ToString();
            ViewData["VendorID"] = vendorID.ToString();
            Activity_AddContact model = new Activity_AddContact();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);            
            ViewData[StaticData.ContactCategory.ToString()] = ReferenceDataRepository.GetContactCategoryForAddContact().ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
                        
            model.IsInbound = true;
            logger.Info("Returning Partial View '_Vendor_Invoices_Activity_AddContact'");
            return View(model);
        }

        /// <summary>
        /// Saves the vendor invoice activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult SaveVendorInvoiceActivityContact(Activity_AddContact model)
        {
            logger.Info("Inside SaveVendorInvoiceActivityContact() in VendorInvoiceController to save a Contact ");
            OperationResult result = new OperationResult();
            facade.SaveVendorInvoiceActivityContact(model,LoggedInUserName);
            result.Status = "Success";
            logger.Info("Contact Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
