using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.Entities.Claims;
using Martex.DMS.ActionFilters;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.Models;
using System.Text;

namespace Martex.DMS.Areas.Claims.Controllers
{
    /// <summary>
    /// Claim Controller
    /// </summary>
    public partial class ClaimController
    {

        /// <summary>
        /// _s the claims_ activity.
        /// </summary>
        /// <param name="suffixClaimID">The suffix claim ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.CommentType, false)]
        public ActionResult _Claims_Activity(int? suffixClaimID)
        {
            logger.InfoFormat("Inside _Claims_Activity of ClaimController with Claim id:{0}", suffixClaimID);
            ViewData["ClaimID"] = suffixClaimID;
            logger.Info("Cal view with list of Activities");
            return PartialView();
        }

        /// <summary>
        /// _s the get claim activity list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="filterColumnName">Name of the filter column.</param>
        /// <param name="filterColumnValue">The filter column value.</param>
        /// <param name="suffixClaimID">The suffix claim ID.</param>
        /// <returns></returns>
        public ActionResult _GetClaimActivityList([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, int suffixClaimID)
        {
            logger.InfoFormat("Inside _GetClaimActivityList of ClaimController. Attempt to get all the Ativity List depending upon the GridCommand and ClaimID:{0}", suffixClaimID);
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
            List<ClaimActivityList_Result> list = facade.GetClaimActivityList(pageCriteria, suffixClaimID);

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
        public ActionResult SaveClaimActivityComments(int CommentType, string Comments, int claimID)
        {
            logger.Info("Inside SaveClaimActivityComments() in ClaimController to save a comment ");
            OperationResult result = new OperationResult();
            facade.SaveClaimActivityComments(CommentType, Comments, claimID, LoggedInUserName);

            result.Status = "Success";
            logger.Info("Comment Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }


        /// <summary>
        /// _s the claim_ activity_ add contact.
        /// </summary>
        /// <param name="claimID">The claim ID.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.ContactMethod, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult _Claim_Activity_AddContact(int claimID)
        {
            logger.Info("Inside _Claim_Activity_AddContact() in ClaimController ");
            ViewData["ClaimID"] = claimID.ToString();
            Activity_AddContact model = new Activity_AddContact();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.CLAIM).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.ContactCategory.ToString()] = ReferenceDataRepository.GetContactCategoryForAddContact().ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            model.IsInbound = true;
            logger.Info("Returning Partial View '_Claim_Activity_AddContact'");
            return View(model);
        }

        /// <summary>
        /// Saves the claim activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult SaveClaimActivityContact(Activity_AddContact model)
        {
            logger.Info("Inside SaveClaimActivityContact() in ClaimController to save a Contact ");
            OperationResult result = new OperationResult();
            facade.SaveClaimActivityContact(model, LoggedInUserName);
            result.Status = "Success";
            logger.Info("Contact Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
