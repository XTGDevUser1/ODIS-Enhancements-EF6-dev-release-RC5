using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Models;
using Martex.DMS.DAO;
using Martex.DMS.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Model;
using System.Text;
using Martex.DMS.Areas.Application.Models;
using System.Xml;
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;


namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    public class MemberMergeController : BaseController
    {

        protected MemberMergeFacade facade = new MemberMergeFacade();

        #region Private Methods

        /// <summary>
        /// Gets the member by membership number.
        /// </summary>
        /// <param name="membershipNumber">The membership number.</param>
        /// <returns></returns>
        public List<SelectListItem> GetMemberByMembershipNumber(string membershipNumber)
        {
            List<DropDownEntity> list = ReferenceDataRepository.GetMembersByMembershipNumber(membershipNumber);
            List<SelectListItem> listItem = null;
            if (list != null)
            {
                listItem = list.ToSelectListItem(x => x.ID.ToString(), y => y.Name).ToList();
            }
            if (listItem == null)
            {
                listItem = new List<SelectListItem>();
            }
            return listItem;
        }

        /// <summary>
        /// Gets the where clause XML.
        /// </summary>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        private string GetWhereClauseXML(MemberSearchCriteria searchCriteria)
        {
            StringBuilder whereClauseXML = new StringBuilder();
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(whereClauseXML, settings))
            {
                writer.WriteStartElement("ROW");
                writer.WriteStartElement("Filter");

                // Append operator and values
                if (!string.IsNullOrEmpty(searchCriteria.MemberNumber))
                {
                    writer.WriteAttributeString("MemberNumberOperator", "2");
                    writer.WriteAttributeString("MemberNumberValue", searchCriteria.MemberNumber);
                }
                if (!string.IsNullOrEmpty(searchCriteria.LastName))
                {
                    writer.WriteAttributeString("LastNameOperator", "4");
                    writer.WriteAttributeString("LastNameValue", searchCriteria.LastName);
                }
                if (!string.IsNullOrEmpty(searchCriteria.FirstName))
                {
                    writer.WriteAttributeString("FirstNameOperator", "4");
                    writer.WriteAttributeString("FirstNameValue", searchCriteria.FirstName);
                }
                if (searchCriteria.MemberProgramID > 0)
                {
                    string programName = ReferenceDataRepository.GetProgramByID(searchCriteria.MemberProgramID.Value).Code;
                    writer.WriteAttributeString("ProgramOperator", "2");
                    writer.WriteAttributeString("ProgramValue", programName);
                }
                if (!string.IsNullOrEmpty(searchCriteria.Phone))
                {
                    writer.WriteAttributeString("PhoneNumberOperator", "6");
                    writer.WriteAttributeString("PhoneNumberValue", searchCriteria.Phone);
                }
                if (!string.IsNullOrEmpty(searchCriteria.VIN))
                {
                    writer.WriteAttributeString("VINOperator", "6");
                    writer.WriteAttributeString("VINValue", searchCriteria.VIN);
                }
                if (!string.IsNullOrEmpty(searchCriteria.State))
                {
                    writer.WriteAttributeString("StateOperator", "2");
                    writer.WriteAttributeString("StateValue", searchCriteria.State);
                }
                if (!string.IsNullOrEmpty(searchCriteria.ZipCode))
                {
                    writer.WriteAttributeString("ZipCodeOperator", "4");
                    writer.WriteAttributeString("ZipCodeValue", searchCriteria.ZipCode);
                }
                if (searchCriteria.MemberID > 0)
                {
                    writer.WriteAttributeString("MemberIDOperator", "2");
                    writer.WriteAttributeString("MemberIDValue", searchCriteria.MemberID.ToString());
                }

                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Close();
            }
            return whereClauseXML.ToString();
        }


        #endregion

        #region Public Methods

        /// <summary>
        /// Indexes the specified member unique identifier.
        /// </summary>
        /// <param name="memberId">The member unique identifier.</param>
        /// <returns></returns>
        [DMSAuthorize(Securable=DMSSecurityProviderFriendlyName.MENU_LEFT_MEMBER_MERGE)]
        public ActionResult Index(int? memberId)
        {
            if (memberId != null)
            {
                ViewData["MemberIdFromList"] = memberId.ToString();
            }
            return View();
        }

        /// <summary>
        /// Perform Search on member.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.Province, false)]
        [NoCache]
        public ActionResult Search()
        {
            logger.Info("Inside Search() of Member Merge Controller");
            var programs = ProgramMaintenanceRepository.GetProgramsForCall((Guid)GetLoggedInUser().ProviderUserKey);
            ViewData["Programs"] = programs.ToSelectListItem(x => x.Id.ToString(), y => y.Name, true);
            
            return PartialView("_SearchMember");
        }

        /// <summary>
        /// Perform Search on Member
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _Search([DataSourceRequest] DataSourceRequest request, MemberSearchCriteria searchCriteria)
        {

            //List<SearchMember_Result> list = new List<SearchMember_Result>();
            int totalRows = 0;
            PageCriteria pageCriteria = null;

            if (searchCriteria.MemberID == 0)
            {
                if (string.IsNullOrEmpty(searchCriteria.FirstName) &&
                   string.IsNullOrEmpty(searchCriteria.LastName) &&
                   searchCriteria.MemberID == 0 &&
                   string.IsNullOrEmpty(searchCriteria.MemberNumber) &&
                    string.IsNullOrEmpty(searchCriteria.Phone) &&
                    string.IsNullOrEmpty(searchCriteria.State) &&
                    string.IsNullOrEmpty(searchCriteria.VIN) &&
                    string.IsNullOrEmpty(searchCriteria.ZipCode)
                    )
                {
                    logger.InfoFormat("Call the view by sending {0} number of records", totalRows);
                    return Json(new DataSourceResult() { Data = new List<SearchMember_Result>(), Total = totalRows });
                }
                else
                {
                    logger.Info("Inside SearchList() of Member Merge Controller");
                    searchCriteria.MemberProgramID = 0;
                    if (!string.IsNullOrEmpty(searchCriteria.FirstName) ||
                        !string.IsNullOrEmpty(searchCriteria.LastName) ||
                        searchCriteria.MemberID > 0 ||
                        !string.IsNullOrEmpty(searchCriteria.MemberNumber) ||
                        !string.IsNullOrEmpty(searchCriteria.Phone) ||
                        !searchCriteria.MemberProgramID.HasValue ||
                        !string.IsNullOrEmpty(searchCriteria.State) ||
                        !string.IsNullOrEmpty(searchCriteria.VIN) ||
                        !string.IsNullOrEmpty(searchCriteria.ZipCode) ||
                        (searchCriteria.ProgramID > 0)
                        )
                    {
                        logger.Info("Inside SearchList() of MemberMerge Controller");
                        searchCriteria.MemberProgramID = 0;
                        GridUtil gridUtil = new GridUtil();
                        string sortColumn = "Name";
                        string sortOrder = "ASC";
                        if (request.Sorts.Count > 0)
                        {
                            sortColumn = request.Sorts[0].Member;
                            sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
                        }

                        pageCriteria = new PageCriteria()
                        {
                            StartInd = request.PageSize * (request.Page - 1) + 1,
                            EndInd = request.PageSize * request.Page,
                            PageSize = request.PageSize,
                            SortColumn = sortColumn,
                            SortDirection = sortOrder,
                            WhereClause = GetWhereClauseXML(searchCriteria)
                        };

                        if (string.IsNullOrEmpty(pageCriteria.WhereClause))
                        {
                            pageCriteria.WhereClause = null;
                        }

                        string loggedInUserName = GetLoggedInUser().UserName;
                        var userId = GetLoggedInUserId();
                        int? programId = null;
                        if (searchCriteria.ProgramID > 0)
                        {
                            programId = searchCriteria.ProgramID;
                        }
                        //ReUsing member search procedure of Member in Application area
                        List<SearchMember_Result> list = facade.SearchMemberMerge(loggedInUserName, Request.RawUrl, pageCriteria, programId, HttpContext.Session.SessionID);

                        if (list.Count > 0)
                        {
                            totalRows = list[0].TotalRows.Value;
                        }
                        logger.InfoFormat("Call the view by sending {0} number of records", totalRows);

                        return Json(new DataSourceResult() { Data = list, Total = totalRows });
                    }

                }
            }
            else
            {
                logger.Info("Inside SearchList() By Find Match of MemberMerge Controller");
                searchCriteria.MemberProgramID = 0;
                GridUtil gridUtil = new GridUtil();
                string sortColumn = "Name";
                string sortOrder = "ASC";
                if (request.Sorts.Count > 0)
                {
                    sortColumn = request.Sorts[0].Member;
                    sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
                }

                pageCriteria = new PageCriteria()
                {
                    StartInd = request.PageSize * (request.Page - 1) + 1,
                    EndInd = request.PageSize * request.Page,
                    PageSize = request.PageSize,
                    SortColumn = sortColumn,
                    SortDirection = sortOrder,
                    WhereClause = null
                };
                                
                string loggedInUserName = GetLoggedInUser().UserName;
                var userId = GetLoggedInUserId();
                List<MatchedMembers_Result> list = facade.SearchMemberByFindMatch(loggedInUserName, Request.RawUrl, pageCriteria, searchCriteria.MemberID, HttpContext.Session.SessionID);
                if (list.Count > 0)
                {
                    totalRows = list[0].TotalRows.Value;
                }
                logger.InfoFormat("Call the view by sending {0} number of records", totalRows);

                return Json(new DataSourceResult() { Data = list, Total = totalRows });
            }

            return Json(new DataSourceResult() { Data = new List<SearchMember_Result>(), Total = totalRows });
            
        }

        /// <summary>
        /// Display Member Details
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMemberDetails(int memberID, int membershipID)
        {
            logger.InfoFormat("Loading member {0} details", memberID);

            DMSCallContext.MemberID = memberID;
            DMSCallContext.MembershipID = membershipID;

            MemberFacade facade = new MemberFacade();
            MemberSearchDetails model = new MemberSearchDetails();
            model.Vehicle = facade.GetVehicleInformation(memberID, membershipID);
            //model.ServiceRequest = facade.GetServiceRequestHistory(membershipID);
            model.MemberInformation = facade.GetMemberInformation(memberID);
            
            return PartialView("_SearchDetailsPopUp", model);
        }

        //TODO: Action method to get member details for source and target areas
        /// <summary>
        /// Get member details.
        /// </summary>
        /// <param name="memberID">The member unique identifier.</param>
        /// <param name="mergeSection">The merge section. [ Source or Target ]</param>
        /// <returns></returns>
        [HttpPost]
        [ValidateInput(false)]
        [NoCache]
        public ActionResult GetMergeMemberDetails(int? memberID, string mergeSection)
        {
            logger.InfoFormat("Loading merge {0} member {1} details",mergeSection,memberID);
            
            MemberMergeDetails model = facade.GetMemberDetails(memberID.Value,"Type","ASC");
            ViewData["mergeSection"] = mergeSection;
            ViewData["MemberId"] = model.MemberId;
            List<SelectListItem> membersList = new List<SelectListItem>();
            if (!string.IsNullOrEmpty(model.MemberDetailsResult.MembershipNumber))
            {
                membersList = GetMemberByMembershipNumber(model.MemberDetailsResult.MembershipNumber);
            }
            ViewData[StaticData.MemberShipMembers.ToString()] = membersList;
            return PartialView("_MemberMergeDetails", model);
            
        }

        /// <summary>
        /// search transactions.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="memberId">The member unique identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _SearchTransactions([DataSourceRequest] DataSourceRequest request, string memberId)
        {

            int totalRows = 0;
            string sortColumn = "Name";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }
            
            List<MemberManagementTransactions_Result> list = facade.GetTransactions(sortColumn, sortOrder, int.Parse(memberId));
            if (list.Count > 0)
            {
                totalRows = list.Count;
            }
            return Json(new DataSourceResult() { Data = list, Total = totalRows });
        }

        
        /// <summary>
        /// Merges the specified source member unique identifier.
        /// </summary>
        /// <param name="sourceMemberID">The source member unique identifier.</param>
        /// <param name="targetMemberID">The target member unique identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult Merge(int? sourceMemberID, int? targetMemberID)
        {
            // Write facade and repositories to perform merge and purge.
            OperationResult result = new OperationResult();
            if (sourceMemberID == targetMemberID)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = "Source and Target should be different";
            }
            else if (sourceMemberID == null || targetMemberID == null)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = "Must specify both a source member and target member before you can Merge";
            }
            else
            {
                logger.InfoFormat("Attempting to merge {0} -> {1}", sourceMemberID, targetMemberID);
                facade.Merge(sourceMemberID.Value, targetMemberID.Value, Request.RawUrl, LoggedInUserName, Session.SessionID);
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion
    }

   
}
