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
        /// <summary>
        /// _s the member_ activity history.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.CommentType, false)]
        public ActionResult _Member_ActivityHistory(int memberID, int memberShipID)
        {
            logger.InfoFormat("Inside _Member_Activity of MemberController with member id:{0}", memberID);
            ViewData["MemberID"] = memberID;
            ViewData["MembershipID"] = memberShipID;
            return PartialView();
        }

        /// <summary>
        /// _s the get member activity list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="filterColumnName">Name of the filter column.</param>
        /// <param name="filterColumnValue">The filter column value.</param>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public ActionResult _GetMemberActivityList([DataSourceRequest] DataSourceRequest request, string filterColumnName, string filterColumnValue, int memberID)
        {
            logger.InfoFormat("Inside _GetMemberActivityList of MemberController. Attempt to get all the Ativity List depending upon the GridCommand and MemberID:{0}", memberID);
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
            List<MemberManagementActivityList_Result> list = facade.GetMemberManagementActivityList(pageCriteria, memberID);

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
        /// Saves the member activity comments.
        /// </summary>
        /// <param name="CommentType">Type of the comment.</param>
        /// <param name="Comments">The comments.</param>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        public ActionResult SaveMemberActivityComments(int CommentType, string Comments, int memberID)
        {
            OperationResult result = new OperationResult();
            facade.SaveMemberLocationActivityComments(CommentType, Comments, memberID, LoggedInUserName);

            result.Status = "Success";
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the member_ activity_ add contact.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>

        [ReferenceDataFilter(StaticData.ContactMethod, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [NoCache]
        public ActionResult _Member_Activity_AddContact(int memberID, int membershipID)
        {
            logger.Info("Inside _Member_Activity_AddContact() in MemberController ");
            ViewData["MemberID"] = memberID.ToString();
            ViewData["MembershipID"] = membershipID.ToString();
            Activity_AddContact model = new Activity_AddContact();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.ContactCategory.ToString()] = ReferenceDataRepository.GetContactCategoryForAddContact().ToSelectListItem(x => x.ID.ToString(), y => y.Description, true);
            
            model.IsInbound = true;
            logger.Info("Returning Partial View '_Member_Activity_AddContact'");
            return View(model);
        }

        /// <summary>
        /// Gets the contact actions and reasons for category.
        /// </summary>
        /// <param name="contactCategoryID">The contact category ID.</param>
        /// <returns></returns>
        public ActionResult GetContactActionsAndReasonsForCategory(int? contactCategoryID)
        {
            OperationResult result = new OperationResult();
            if (contactCategoryID != null)
            {
                ContactCategory contactCategory = new ReferenceDataRepository().GetContactCategory(contactCategoryID.GetValueOrDefault());
                Activity_AddContact_ActionsAndReasons actionsAndReasons = new Activity_AddContact_ActionsAndReasons();
                var reasons = ReferenceDataRepository.GetContactReasons(contactCategory.Name);
                actionsAndReasons.contactReason = reasons.ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);

                var actions = ReferenceDataRepository.GetContactAction(contactCategory.Name);
                actionsAndReasons.contactAction = actions.ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);

                result.Data = actionsAndReasons;
                result.Status = "Success";
            }
            else
            {
                result.Status = "Failure";                
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Saves the member activity contact.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ActionResult SaveMemberActivityContact(Activity_AddContact model)
        {
            logger.Info("Inside SaveMemberActivityContact() in MemberController to save a Contact ");
            OperationResult result = new OperationResult();
            facade.SaveMemberActivityContact(model,LoggedInUserName);
            result.Status = "Success";
            logger.Info("Contact Saved Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
