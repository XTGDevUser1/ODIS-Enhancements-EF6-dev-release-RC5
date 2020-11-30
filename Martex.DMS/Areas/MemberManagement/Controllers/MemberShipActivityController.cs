using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.BLL.Model;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Areas.Application.Models;
using System.Text;
using System.Xml;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    [DMSAuthorize]
    public partial class MemberController
    {
        MemberManagementFacade facade = new MemberManagementFacade();
        /// <summary>
        /// _s the membership_ activity.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.CommentType, false)]
        public ActionResult _Membership_Activity(int membershipID)
        {
            logger.InfoFormat("Inside _Membership_Activity of MemberController with member id:{0}", membershipID);

            ViewData["MembershipID"] = membershipID;
            return PartialView();
        }

        /// <summary>
        /// _s the get membership activity list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public ActionResult _GetMembershipActivityList([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, int membershipID)
        {
            logger.InfoFormat("Inside _GetMembershipActivityList of MemberController. Attempt to get all the Ativity List depending upon the GridCommand and MembershipID:{0}", membershipID);
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
            List<MembershipManagementActivityList_Result> list = facade.GetMembershipActivityList(pageCriteria, membershipID);

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
        /// Saves the membership location activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="membershipLocationID">The membership location ID.</param>
        /// <returns></returns>
        public ActionResult SaveMembershipActivityComments(int CommentType, string Comments, int membershipID)
        {
            OperationResult result = new OperationResult();
            facade.SaveMembershipLocationActivityComments(CommentType, Comments, membershipID, LoggedInUserName);

            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [ReferenceDataFilter(StaticData.ContactMethod, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult _Membership_Activity_AddContact(int membershipID)
        {
            logger.Info("Inside _Membership_Activity_AddContact() in MemberController ");
            ViewData["MembershipID"] = membershipID.ToString();
            Activity_AddContact model = new Activity_AddContact();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBERSHIP).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.ContactCategory.ToString()] = ReferenceDataRepository.GetContactCategoryForAddContact().ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            model.IsInbound = true;
            logger.Info("Returning Partial View '_Membership_Activity_AddContact'");
            return View(model);
        }

        public ActionResult SaveMembershipActivityContact(Activity_AddContact model)
        {
            logger.Info("Inside SaveMembershipActivityContact() in MemberController to save a Contact ");
            OperationResult result = new OperationResult();
            facade.SaveMembershipActivityContact(model, LoggedInUserName);
            result.Status = "Success";
            logger.Info("Contact Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
