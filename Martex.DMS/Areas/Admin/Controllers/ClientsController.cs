using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using Martex.DMS.Models;
using log4net;
using Martex.DMS.BLL.Facade;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.Areas.Common.Controllers;
using Kendo.Mvc.UI;
using Martex.DMS.Areas.Application.Models;
using Newtonsoft.Json;

namespace Martex.DMS.Areas.Admin.Controllers
{
    /// <summary>
    /// ClientsController
    /// </summary>
    public class ClientsController : BaseController
    {

        #region Public Methods
        /// <summary>
        /// View page for Client
        /// </summary>
        /// <returns></returns>
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Index()
        {
            logger.Info("Inside Index() of ClientsController. Attempt to call the view");
            return View();

        }

        /// <summary>
        /// Search Method for Client Grid
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult List([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside List() of ClientsController. Attempt to get all Clients depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ClientName";
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
            ClientsFacade clientFacade = new ClientsFacade();
            List<SearchClients_Result> list = clientFacade.List((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);
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
        /// Retrieve the Client Details
        /// </summary>
        /// <param name="selectedClientId">The selected client id.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        [ReferenceDataFilter(StaticData.Country, true)]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.Organizations, false)]  // here client populated based on login user Id
        public ActionResult Get(string selectedClientId, string mode)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Get() of ClientsController with the selectedClientId {0} and mode {1}", selectedClientId, mode);
            Client client = null;
            Guid userId = (Guid)System.Web.Security.Membership.FindUsersByName(GetLoggedInUser().UserName)[GetLoggedInUser().UserName].ProviderUserKey;
            if (mode != "add")
            {
                logger.InfoFormat("Try to get the Client with selectedClientId {0}", selectedClientId);
                ClientsFacade clientFacade = new ClientsFacade();
                client = clientFacade.Get(selectedClientId);
                logger.InfoFormat("Got the Client with ClientId {0}", client.ID);
            }
            
            ViewData["mode"] = mode;
            logger.Info("Call the partial view '_Client' ");
            ClientModel model = SetClientModel(client ?? new Client());
            return PartialView("_ClientRegistration", model);

        }

        /// <summary>
        /// Save the Client Details
        /// </summary>
        /// <param name="clientModel">The client model.</param>
        /// <param name="hdnfldMode">The HDNFLD mode.</param>
        /// <param name="countryCode">The country code.</param>
        /// <param name="addressCountryCode">The address country code.</param>
        /// <param name="addressStateProvince">The address state province.</param>
        /// <param name="address1CountryCode">The address1 country code.</param>
        /// <param name="address1StateProvince">The address1 state province.</param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Save(ClientModel clientModel, string hdnfldMode)
        {

            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Save() of ClientsController with mode {0}", hdnfldMode);
            clientModel.Client.IsActive = clientModel.isActive;
            if (hdnfldMode == "add")
            {
                logger.InfoFormat("Try to add a new Client with Client name {0}, Data = {1}", clientModel.Client.Name, JsonConvert.SerializeObject(clientModel));
                ClientsFacade clientFacade = new ClientsFacade();
                clientFacade.Add(clientModel, clientModel.ClientOrganizationsValues, GetLoggedInUser().UserName);
                logger.Info("A new user has been created");
            }
            else
            {
                logger.InfoFormat("Try to update the Client whose ClientId is {0}, Data = {1}", clientModel.Client.ID,JsonConvert.SerializeObject(clientModel));
                ClientsFacade clientFacade = new ClientsFacade();
                clientFacade.Update(clientModel, clientModel.ClientOrganizationsValues, GetLoggedInUser().UserName);
                logger.InfoFormat("The Client has been updated", clientModel.Client.ID);
            }
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);

        }

        /// <summary>
        /// Delete Record from Database.
        /// </summary>
        /// <param name="selectedClientId">The selected client id.</param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Delete(string selectedClientId)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Delete() of ClientsController with the ClientId {0}", selectedClientId);
            ClientsFacade clientFacade = new ClientsFacade();
            clientFacade.Delete(selectedClientId);
            logger.InfoFormat("The record with clientId {0} has been Deleted", selectedClientId);
            result.OperationType = "Success";
            result.Status = "Success";
            return Json(result);

        }
        #endregion

        #region Helper Methods
        /// <summary>
        /// Sets the client model.
        /// </summary>
        /// <param name="client">The client.</param>
        /// <returns></returns>
        private ClientModel SetClientModel(Client client)
        {
            if (client == null)
            {
                return null;
            }
            ClientModel clientModel = new ClientModel();
            clientModel.Client = client;
            clientModel.isActive = client.IsActive ?? false;

            clientModel.LastUpdateInformation = string.Format("{0} {1}", client.ModifyBy, client.ModifyDate);
            if (client.OrganizationClients.Count > 0)
            {
                int[] organizationValues = new int[client.OrganizationClients.Count];
                string[] organizationStringValues = new string[client.OrganizationClients.Count];
                List<OrganizationClient> clientClientList = client.OrganizationClients.ToList();
                for (int i = 0; i < organizationValues.Count(); i++)
                {
                    organizationValues[i] = clientClientList[i].OrganizationID;
                    organizationStringValues[i] = clientClientList[i].OrganizationID.ToString();
                }
                clientModel.ClientOrganizationsValues = organizationValues;
                clientModel.ClientOrganizationsString = organizationStringValues;
            }
            return clientModel;
        }

        #endregion
    }
}
