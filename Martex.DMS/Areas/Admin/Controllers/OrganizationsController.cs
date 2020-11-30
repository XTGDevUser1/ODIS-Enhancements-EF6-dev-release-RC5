using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.Models;
using log4net;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.DAO;
using Kendo.Mvc.UI;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.Admin.Controllers
{
    /// <summary>
    /// Organizations Controller
    /// </summary>
    public class OrganizationsController : BaseController
    {
        #region Public Methods

        /// <summary>
        /// View page for the organization list.
        /// </summary>
        /// <returns></returns>
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Index()
        {
            logger.Info("Inside Index() of OrganizationController. Attempt to call the view");
            return View();
        }

        /// <summary>
        /// Search Method for Organization Grid
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult List([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside List() of OrganizationsController. Attempt to get all Organizations depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "OrganizationName";
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
                SortDirection = sortOrder,
                SortColumn = sortColumn,
                WhereClause = gridUtil.GetWhereClauseXml_Kendo(request.Filters)
            };
            if (string.IsNullOrEmpty(pageCriteria.WhereClause))
            {
                pageCriteria.WhereClause = null;
            }

            OrganizationsFacade orgFacade = new OrganizationsFacade();
            List<SearchOrganizations_Result> list = orgFacade.List((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows;
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }

        /// <summary>
        /// Get the particular Organization details which can be edit or view.
        /// </summary>
        /// <param name="selectedOrganizationId">The selected organization id.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [HttpPost]
        [ReferenceDataFilter(StaticData.Organizations, false)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.CallType, false)]
        [ReferenceDataFilter(StaticData.Language, false)]
        [ReferenceDataFilter(StaticData.Country, false)]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Get(string selectedOrganizationId, string mode)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Get() of OrganizationController with the selectedOrganizationId {0} and mode {1}", selectedOrganizationId, mode);
            Organization organization = null;
            Guid userId = GetLoggedInUserId();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.ORGANIZATION).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            if (mode != "add")
            {
                logger.InfoFormat("Try to get the Organization with selectedOrganizationId {0}", selectedOrganizationId);
                OrganizationsFacade organizationFacade = new OrganizationsFacade();
                organization = organizationFacade.Get(selectedOrganizationId);
                ViewData[StaticData.UserRoles.ToString()] = ReferenceDataRepository.GetUserRoles(organization.ParentOrganizationID).ToSelectListItem<DropDownRoles>(x => x.RoleID.ToString(), y => y.RoleName, false);
                if (organization.ParentOrganizationID != null)
                {
                    ViewData[StaticData.Clients.ToString()] = organizationFacade.GetOrganizationClients(organization.ParentOrganizationID.Value).ToSelectListItem<Client>(x => x.ID.ToString(), y => y.Name, false);
                }
                else
                {
                    ViewData[StaticData.Clients.ToString()] = ReferenceDataRepository.GetClients(userId).ToSelectListItem<Clients_Result>(x => x.ClientID.ToString(), y => y.ClientName, false);
                }
                logger.InfoFormat("Got the Organization with OrganizationId {0}", organization.ID);
            }
            else
            {
                ViewData[StaticData.Address1Province.ToString()] = ViewData[StaticData.AddressProvince.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.Abbreviation.Trim(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
                ViewData[StaticData.UserRoles.ToString()] = ReferenceDataRepository.GetUserRoles(null).ToSelectListItem<DropDownRoles>(x => x.RoleID.ToString(), y => y.RoleName, false);
                ViewData[StaticData.Clients.ToString()] = ReferenceDataRepository.GetClients(userId).ToSelectListItem<Clients_Result>(x => x.ClientID.ToString(), y => y.ClientName, false);
            }
            ViewData["mode"] = mode;
            ViewData["isUserAdmin"] = System.Web.Security.Roles.IsUserInRole(GetLoggedInUser().UserName, RoleConstants.SysAdmin);
            ViewData["UserId"] = userId;
            logger.Info("Call the partial view '_Organization' ");
            ViewData[StaticData.Address1Province.ToString()] = ViewData[StaticData.AddressProvince.ToString()] = ReferenceDataRepository.GetStateProvinces(1).ToSelectListItem<StateProvince>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.Abbreviation.Trim(), y.Name.Trim()), true);
            ViewData["AddressType"] = ReferenceDataRepository.GetAddressTypes(EntityNames.ORGANIZATION).ToSelectListItem<AddressType>(x => x.ID.ToString(), y => y.Name, true);
            return PartialView("_OrganizationRegistration", SetOrganizationalModel(organization ?? new Organization()));

        }
        /// <summary>
        /// Save the organization details into database.
        /// </summary>
        /// <param name="organizationModel">The organization model.</param>
        /// <param name="ParentOrganizationID">The parent organization ID.</param>
        /// <param name="hdnfldMode">The HDNFLD mode.</param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Save(OrganizationModel organizationModel, string ParentOrganizationID, string hdnfldMode)
        {

            OperationResult result = new OperationResult();
            var loggedInUser = GetLoggedInUser().UserName;
            logger.InfoFormat("Inside Save() of OrganizationController with mode {0}", hdnfldMode);
            if (!string.IsNullOrEmpty(ParentOrganizationID) && !ParentOrganizationID.Equals("Select"))
            {
                organizationModel.Organization.ParentOrganizationID = int.Parse(ParentOrganizationID);
            }
            if (hdnfldMode == "add")
            {
                logger.InfoFormat("Try to add a new Organization with Organization name {0}", organizationModel.Organization.Name);
                OrganizationsFacade organizationFacade = new OrganizationsFacade();
                organizationFacade.Add(organizationModel,
                                        loggedInUser);
                logger.Info("A new organization has been created");
            }
            else
            {
                logger.InfoFormat("Try to update the Organization whose OrganizationId is {0}", organizationModel.Organization.ID);
                OrganizationsFacade organizationFacade = new OrganizationsFacade();
                organizationFacade.Update(organizationModel, loggedInUser);
                logger.InfoFormat("The Organization has been updated", organizationModel.Organization.ID);
            }
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);


        }

        /// <summary>
        /// Delete Organization details from database.
        /// </summary>
        /// <param name="selectedOrganizationId">The selected organization id.</param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Delete(string selectedOrganizationId)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Delete() of OrganizationController with the OrganizationId {0}", selectedOrganizationId);
            OrganizationsFacade organizationFacade = new OrganizationsFacade();
            organizationFacade.Delete(selectedOrganizationId);
            logger.InfoFormat("The record with organizationId {0} has been Deleted", selectedOrganizationId);
            result.OperationType = "Success";
            result.Status = "Success";
            return Json(result);

        }
        #endregion

        #region Helper Methods
        /// <summary>
        /// Sets the organizational model.
        /// </summary>
        /// <param name="organization">The organization.</param>
        /// <returns></returns>
        private OrganizationModel SetOrganizationalModel(Organization organization)
        {
            if (organization == null)
            {
                return null;
            }
            OrganizationModel organizationModel = new OrganizationModel();
            organizationModel.Organization = organization;
            organizationModel.LastUpdateInformation = string.Format("{0} {1}", organization.ModifyBy, organization.ModifyDate);
            if (organization.OrganizationClients.Count > 0)
            {
                int[] clientValues = new int[organization.OrganizationClients.Count];
                List<OrganizationClient> organizationClientList = organization.OrganizationClients.ToList();
                for (int i = 0; i < clientValues.Count(); i++)
                {
                    clientValues[i] = organizationClientList[i].ClientID;
                }
                organizationModel.OrganizationClientsValues = clientValues;
            }
            if (organization.OrganizationRoles.Count > 0)
            {
                Guid[] roleValues = new Guid[organization.OrganizationRoles.Count];
                List<OrganizationRole> organizationRoleList = organization.OrganizationRoles.ToList();
                for (int i = 0; i < roleValues.Count(); i++)
                {
                    roleValues[i] = organizationRoleList[i].RoleID;
                }
                organizationModel.OrganizationRolesValues = roleValues;
            }
            return organizationModel;
        }

        #endregion        
    }
}
