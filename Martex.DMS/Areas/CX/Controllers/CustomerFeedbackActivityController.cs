using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.DAL.Common;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using System.Text;
using Martex.DMS.DAO;

namespace Martex.DMS.Areas.QA.Controllers
{
    /// <summary>
    /// CustomerFeedback Controller
    /// </summary>
    public partial class CXCustomerFeedbackController
    {
        //
        // GET: /CX/CustomerFeedbackActivity/
        [ReferenceDataFilter(StaticData.CommentType, false)]
        public ActionResult _CustomerFeedback_Activity(int? id)
        {
            logger.InfoFormat("Inside _CustomerFeedback_Activity of CustomerFeedbackController with Customer Feedback id:{0}", id);
            ViewData["CustomerFeedbackID"] = id.GetValueOrDefault().ToString(); 
            logger.Info("Call view with list of Activities");
            return PartialView();
        }


        /// <summary>
        /// _s the get customerFeedback activity list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="filterColumnName">Name of the filter column.</param>
        /// <param name="filterColumnValue">The filter column value.</param>
        /// <param name="suffixCustomerFeedbackID">The suffix CustomerFeedback ID.</param>
        /// <returns></returns>
        public ActionResult _GetCustomerFeedbackActivityList([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, int suffixCustomerFeedbackID)
        {
            logger.InfoFormat("Inside _GetCustomerFeedbackActivityList of CustomerFeedbackController. Attempt to get all the Ativity List depending upon the GridCommand and CustomerFeedbackID:{0}", suffixCustomerFeedbackID);
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
            List<CustomerFeedbackActivityList_Result> list = facade.GetCustomerFeedbackActivityList(pageCriteria, suffixCustomerFeedbackID);

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
        /// Saves the claim activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="claimID">The claim ID.</param>
        /// <returns></returns>
        public ActionResult SaveCustomerFeedbackActivityComments(int CommentType, string Comments, int customerFeedbackId)
        {
            logger.Info("Inside SaveCustomerFeedbackActivityComments() in CXCustomerFeedbackController to save a comment ");
            OperationResult result = new OperationResult();
            facade.SaveCustomerFeedbackActivityComments(CommentType, Comments, customerFeedbackId, LoggedInUserName);

            result.Status = "Success";
            logger.Info("Comment Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the _CustomerFeedback_Activity_Add contact.
        /// </summary>
        /// <param name="customerFeedbackId">The customerFeedback Id.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ContactMethod, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]        
        public ActionResult _CustomerFeedback_Activity_AddContact(int customerFeedbackId)
        {
            logger.Info("Inside _CustomerFeedback_Activity_AddContact() in CXCustomerFeedbackController ");
            ViewData["CustomerFeedbackID"] = customerFeedbackId.ToString();
            Activity_AddContact model = new Activity_AddContact();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.CUSTOMER_FEEDBACK).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.ContactCategory.ToString()] = ReferenceDataRepository.GetContactCategoryForAddContact().ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            model.IsInbound = true;
            logger.Info("Returning Partial View '_CustomerFeedback_Activity_AddContact'");
            return View(model);
        }

        /// <summary>
        /// Saves the claim activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult SaveCustomerFeedbackActivityContact(Activity_AddContact model)
        {
            logger.Info("Inside SaveCustomerFeedbackActivityContact() in CXCustomerFeedbackController to save a Contact ");
            OperationResult result = new OperationResult();
            facade.SaveCustomerFeedbackActivityContact(model, LoggedInUserName);
            result.Status = "Success";
            logger.Info("Contact Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
