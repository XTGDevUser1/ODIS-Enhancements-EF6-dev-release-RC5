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
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.Areas.MemberManagement.Controllers
{
    [DMSAuthorize]
    public partial class MemberController
    {
        #region Public Methods

        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable=DMSSecurityProviderFriendlyName.MENU_LEFT_MEMBER_MAINTENANCE)]
        public ActionResult Index()
        {
            return View();
        }

        /// <summary>
        /// Perform Search on Member
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="searchCriteria">The search criteria.</param>
        /// <returns></returns>
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _Search([DataSourceRequest] DataSourceRequest request, MemberManagementSearchCriteria searchCriteria)
        {
            logger.Info("Inside Search of Member Search. Attempt to get all Vendors depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "MemberNumber";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = searchCriteria.GetFilterClause();

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            var facade = new MemberManagementFacade();
            List<MemberManagementSearch_Result> list = new List<MemberManagementSearch_Result>();
            if (filter.Count > 0)
            {
                list = facade.Search(pageCriteria);
            }
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
        /// Membership duplicate records.
        /// </summary>
        /// <returns></returns>
        public ActionResult _MembershipDuplicateRecords(string phoneNumber)
        {
            return PartialView("_MembershipDuplicateRecords", phoneNumber);
        }

        /// <summary>
        /// Gets the duplicate records.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="phoneNumber">The phone number.</param>
        /// <returns></returns>
        [NoCache]
        [ValidateInput(false)]
        public ActionResult _DuplicateRecords([DataSourceRequest] DataSourceRequest request, string phoneNumber)
        {
            logger.Info("Inside Search of Duplicate Records. Attempt to get all records depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "MemberNumber";
            string sortOrder = "ASC";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = new List<NameValuePair>();
            filter.Add(new NameValuePair() { Name = "PhoneNumberValue", Value = phoneNumber });
            filter.Add(new NameValuePair() { Name = "PhoneNumberOperator", Value = "6" });

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = request.PageSize * (request.Page - 1) + 1,
                EndInd = request.PageSize * request.Page,
                PageSize = request.PageSize,
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }
            var facade = new MemberManagementFacade();
            List<MemberManagementSearch_Result> list = facade.Search(pageCriteria);
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
        /// Determines whether is membership phone number found for the specified phone number.
        /// </summary>
        /// <param name="phoneNumber">The phone number.</param>
        /// <returns></returns>
        public ActionResult IsMembershipPhoneNumberFound(string phoneNumber)
        {
            logger.InfoFormat("Trying to find duplicate records while adding membership for the given phone Number {0}", phoneNumber);
            OperationResult result = new OperationResult();

            List<NameValuePair> filter = new List<NameValuePair>();
            filter.Add(new NameValuePair() { Name = "PhoneNumberValue", Value = phoneNumber });
            filter.Add(new NameValuePair() { Name = "PhoneNumberOperator", Value = "6" });

            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 500,
                PageSize = 20,
                WhereClause = filter.Count > 0 ? filter.GetXML() : string.Empty
            };
            var facade = new MemberManagementFacade();
            List<MemberManagementSearch_Result> list = facade.Search(pageCriteria);
            if (list != null && list.Count > 0)
            {
                result.Status = OperationStatus.SUCCESS;
            }
            else
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the member container.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        [NoCache]
        public ActionResult _MemberContainer(int membershipID)
        {
            logger.InfoFormat("Loading Membership Container Tab with Membership ID {0}", membershipID);
            var facade = new MemberManagementFacade();
            ViewData[StaticData.MemberManagementMembers.ToString()] = facade.GetMembersByMembershipID(membershipID).ToSelectListItem(x => x.Value, y => y.Text);
            MemberShipInfoDetails info = facade.GetMemberShipInfoDetails(membershipID);
            return PartialView(info);
        }

        #region Tabs
        /// <summary>
        /// Gets the member tabs.
        /// </summary>
        /// <param name="memberID">The member ID.</param>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public ActionResult _MemberTabs(int memberID, int membershipID)
        {
            ViewData["MembershipID"] = membershipID;
            return PartialView(memberID);

        }

        /// <summary>
        /// Gets the membership tabs.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public ActionResult _MembershipTabs(int membershipID)
        {
            return PartialView(membershipID);
        }

        #endregion

        /// <summary>
        /// _s the search criteria.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [ReferenceDataFilter(StaticData.VendorSearchCriteriaNameFilterType, true)]
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        [HttpPost]
        public ActionResult _SearchCriteria(MemberManagementSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SearchCriteria() of Member with Model:{0}", model);
            List<SelectListItem> programList = ReferenceDataRepository.GetProgramByClient(0).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true).ToList();
            if (programList.Count > 1)
            {
                programList.Insert(1, new SelectListItem()
                {
                    Text = "ALL",
                    Value = "-1"
                });
            }
            ViewData[StaticData.ProgramsForClient.ToString()] = programList;
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);

            var tempHoldModel = model.GetModelForSearchCriteria();
            ModelState.Clear();
            if (model.FilterToLoadID.HasValue)
            {
                logger.InfoFormat("Member Search trying to Load Pre Defined Views with an ID {0}", model.FilterToLoadID.Value);
                MemberManagementSearchCriteria dbModel = model.GetView(model.FilterToLoadID.Value) as MemberManagementSearchCriteria;
                if (dbModel != null)
                {
                    if (dbModel.SearchClientID.HasValue)
                    {
                        List<SelectListItem> programListFiltered = ReferenceDataRepository.GetProgramByClient(dbModel.SearchClientID.Value).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true).ToList();
                        if (programListFiltered.Count > 1)
                        {
                            programListFiltered.Insert(1, new SelectListItem()
                            {
                                Text = "ALL",
                                Value = "-1"
                            });
                        }
                        ViewData[StaticData.ProgramsForClient.ToString()] = programListFiltered;
                    }
                    if (dbModel.CountryID.HasValue)
                    {
                        ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(dbModel.CountryID.Value).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
                    }
                    return PartialView(dbModel);
                }

            }
            logger.Info("Returns the View");
            return PartialView(tempHoldModel);
        }

        /// <summary>
        /// Gets the selected criteria.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [HttpPost]
        public ActionResult _SelectedCriteria(MemberManagementSearchCriteria model)
        {
            logger.InfoFormat("Inside the _SelectedCriteria() model in Member List Controller with Model:{0}", model);
            logger.Info("Returns the View");
            return View(model.GetModelForSearchCriteria());
        }

        /// <summary>
        /// Gets the programs.
        /// </summary>
        /// <param name="clientID">The client ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult GetPrograms(int? clientID)
        {
            List<Program> list = ReferenceDataRepository.GetProgramByClient(clientID.GetValueOrDefault(), true);
            return Json(list.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true), JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the programs using all.
        /// </summary>
        /// <param name="clientID">The client ID.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult GetProgramsUsingAll(int? clientID)
        {
            List<SelectListItem> list = ReferenceDataRepository.GetProgramByClient(clientID.GetValueOrDefault(), true).ToSelectListItem(x => x.ID.ToString(), y => y.Description, true).ToList();
            if (list != null && list.Count > 1)
            {
                list.Insert(1, new SelectListItem()
                {
                    Value = "-1",
                    Text = "ALL"
                });
            }
            return Json(list, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// _s the add member.
        /// </summary>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.AllActiveClients, true)]
        [ReferenceDataFilter(StaticData.Prefix, true)]
        [ReferenceDataFilter(StaticData.Suffix, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        public ActionResult _AddMember()
        {
            PhoneRepository lookUp = new PhoneRepository();
            MembershipAddModel model = new MembershipAddModel();
            model.AddressInformation = new AddressEntity();
            model.MemberInformation = new Member();
            model.MembershipInformation = new Membership();
            model.PhoneInfomation = new PhoneEntity();
            ViewData[StaticData.ProgramsForClient.ToString()] = ReferenceDataRepository.GetProgramByClient(0).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true);

            string[] excludedItems = new string[] { 
                PhoneTypeNames.Other, 
            };
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.MEMBER, excludedItems).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.AddressTypes.ToString()] = ReferenceDataRepository.GetAddressTypes(EntityNames.MEMBER).ToSelectListItem(u => u.ID.ToString(), y => y.Description, false);
            ViewData[StaticData.ProvinceAbbreviation.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            PhoneType phoneType = lookUp.GetPhoneTypeByName(PhoneTypeNames.Home);
            model.PhoneInfomation.PhoneTypeID = phoneType == null ? (int?)null : phoneType.ID;
            return PartialView(model);
        }

        /// <summary>
        /// Creates the membership.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult CreateMembership(MembershipAddModel model)
        {
            OperationResult result = new OperationResult();
            logger.Info("Trying to create Membership");
            var facade = new MemberManagementFacade();
            facade.CreateMembership(model, LoggedInUserName, HttpContext.Session.SessionID);
            result.Status = OperationStatus.SUCCESS;
            result.Data = new
            {
                MemberID = model.MemberInformation.ID,
                MembershipID = model.MembershipInformation.ID,
                MembershipNumber = model.MembershipInformation.MembershipNumber,
                MemberName = string.Join(" ", model.MemberInformation.FirstName, model.MemberInformation.MiddleName, model.MemberInformation.LastName)
            };
            logger.Info("Executed successfully");
            return Json(result);
        }

        #endregion
    }
}
