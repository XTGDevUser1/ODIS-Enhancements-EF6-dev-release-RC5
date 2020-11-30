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
        /// _s the membership_ members.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public ActionResult _Membership_Members(int membershipID)
        {
            logger.InfoFormat("Loading Membership Members Tab with Membership ID {0}", membershipID);
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 10,
                PageSize = 10
            };

            List<MembershipMembersList_Result> list = facade.GetMembershipMembersList(pageCriteria, membershipID);
            ViewData["MembershipID"] = membershipID.ToString();
            logger.Info("Call view with list of SRs");
            return PartialView(list);
        }

        /// <summary>
        /// _s the get membership members.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public ActionResult _GetMembershipMembers([DataSourceRequest] DataSourceRequest request, int membershipID)
        {
            logger.InfoFormat("Inside _GetMembershipMembers of MemberController. Attempt to get all the Members List depending upon the GridCommand and MembershipID:{0}", membershipID);
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "DESC";
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
            List<MembershipMembersList_Result> list = facade.GetMembershipMembersList(pageCriteria, membershipID);

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
        /// Add member to the membership.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <returns></returns>
        [NoCache]
        [ReferenceDataFilter(StaticData.Suffix, false)]
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Prefix, false)]
        [ReferenceDataFilter(StaticData.Province, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        public ActionResult AddmembershipMember(int memberID)
        {
            logger.InfoFormat("Inside AddmembershipMember() in Member Home Controller with MemberShip ID:{0}", memberID);
            var facade = new MemberManagementFacade();
            MemberShipInfoDetails info = facade.GetMemberShipInfoDetails(memberID);
            ViewData[StaticData.ProgramsForClient.ToString()] = ReferenceDataRepository.GetProgramByClient(info.ClientID.GetValueOrDefault()).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true);

            ViewData[StaticData.AddressTypes.ToString()] = ReferenceDataRepository.GetAddressforEntity("Member").ToSelectListItem<AddressType>(x => x.ID.ToString(), y => y.Name, true);
            var phoneTypesList = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = phoneTypesList;

            ViewData["MembershipID"] = memberID.ToString();
            ViewData["MemberNumber_AM"] = "0";
            if (info.MemberShipNumber != null)
            {
                ViewData["MemberNumber_AM"] = info.MemberShipNumber;
            }

            ViewData["Client_AM"] = info.ClientName;
            logger.Info("Call the Partial View _Membership_Member_Add");
            return PartialView("_Membership_Member_Add");
        }

        /// <summary>
        /// Saves the membership member.
        /// </summary>
        /// <param name="Member">The member.</param>
        /// <returns></returns>
        public ActionResult SaveMembershipMember(MemberModel Member)
        {
            logger.Info("Inside SaveMembershipMember() in Member Home Controller");
            OperationResult result = new OperationResult();
            int MemberNumber = facade.SaveMembershipMember(Member, LoggedInUserName, Request.RawUrl);
            result.Status = "Success";
            result.Data = MemberNumber;
            logger.Info("Added Member Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        public ActionResult DeleteMembershipMember(int membershipID, int memberID)
        {
            logger.InfoFormat("Inside DeleteMembershipMember() in Member Home Controller with MemberID: {0}", memberID);
            OperationResult result = new OperationResult();
            facade.DeleteMembershipMember(memberID);
            result.Status = "Success";
            logger.Info("Member Deleted Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="membershipID"></param>
        /// <param name="memberID"></param>
        /// <returns></returns>
        public ActionResult DeleteMemberAndMemberShip(int membershipID, int memberID)
        {
            logger.InfoFormat("Inside DeleteMemberAndMemberShip() in Member Home Controller with MemberID: {0}", memberID);
            OperationResult result = new OperationResult();
            facade.DeleteMemberAndMemberShip(memberID, membershipID);
            result.Status = "Success";
            logger.Info("Member Deleted Successfully");
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Check whether last member or not
        /// </summary>
        /// <param name="membershipID"></param>
        /// <returns></returns>
        public ActionResult IsLastMember(int membershipID)
        {
            logger.InfoFormat("Checking Is Last Memeber for membership ID {0}", membershipID);
            OperationResult result = new OperationResult();
            result.Data = new
            {
                IsLastMember = facade.IsLastMember(membershipID)
            };
            result.Status = "Success";
            logger.Info("Execution Finished");
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
