using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Kendo.Mvc.UI;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.BLL.Facade;
using Martex.DMS.BLL.Model;
using Martex.DMS.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.Models;

namespace Martex.DMS.Areas.ClientManagement.Controllers
{
    public class ClientRepController : BaseController
    {

        ClientRepMaintenanceFacade facade = new ClientRepMaintenanceFacade();
        //
        // GET: /ClientManagement/ClientRep/
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult Index()
        {
            logger.Info("Inside Index of Client Rep Maintenance. Attempt to call the view");
            return View();
        }
        /// <summary>
        /// Clients the rep list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        [DMSAuthorize]
        public ActionResult ClientRepList([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside Client Rep List() of ClientRepController. Attempt to get all Message depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "ID";
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

            List<ClientRepList_Result> list = facade.ClientRepList(pageCriteria);
            logger.InfoFormat("Call the view by sending {0} number of records", list.Count);
            int totalRows = 0;
            if (list.Count > 0)
            {
                totalRows = list[0].TotalRows.GetValueOrDefault();
            }
            var result = new DataSourceResult()
            {
                Data = list,
                Total = totalRows
            };

            return Json(result);
        }

        /// <summary>
        /// Gets the ClientRep details.
        /// </summary>
        /// <param name="recordID">The record identifier.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        //[ReferenceDataFilter(StaticData.PhoneType, true)]
        public ActionResult ClientRepDetails(int? recordID, string mode)
        {
            ViewBag.PageMode = mode;
            //ViewData["Clients"] = ReferenceDataRepository.GetAllClients().Where(a => a.ClientRepID == recordID).ToSelectListItem(x => x.ID.ToString(), y => y.Name.ToString());
            var phoneTypesList = ReferenceDataRepository.GetPhoneTypes(EntityNames.CLIENT_REP).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.PhoneType.ToString()] = phoneTypesList;
            var clientRep = facade.Get(recordID.GetValueOrDefault(), true);
            ClientRepDetailsModel model = new ClientRepDetailsModel();
            model.ClientRep = clientRep;
            model.ClientsList = ReferenceDataRepository.GetAllClients().Where(a => a.ClientRepID == recordID).ToList();
            return PartialView(model);
        }

        /// <summary>
        /// Saves the client rep details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveClientRepDetails(ClientRepDetailsModel model)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Trying to Insert or Update ClientRep record for ID {0}", model.ClientRep.ID);
            facade.SaveClientRepDetails(model.ClientRep, LoggedInUserName, Request.RawUrl, HttpContext.Session.SessionID);
            logger.InfoFormat("ClientRep Insert or Update success for ID {0}", model.ClientRep.ID);
            return Json(result);
        }


        /// <summary>
        /// Deletes the client rep.
        /// </summary>
        /// <param name="recordID">The record identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult DeleteClientRep(int recordID)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Trying to delete ClientRep record for ID {0}", recordID);
            facade.DeleteClientRep(recordID, LoggedInUserName);
            logger.InfoFormat("ClientRep record deleted for ID {0}", recordID);
            return Json(result);
        }

        public ActionResult _RemoveClientRepAvatar(int clientRepID)
        {
            var result = new OperationResult();
            logger.InfoFormat("Trying to remove Avatar for the ClientRep {0}", clientRepID);
            ClientsFacade clientFacade = new ClientsFacade();
            clientFacade.UpdateAvatar(clientRepID, "ClientRep", null, GetLoggedInUser().UserName);
            logger.Info("Avatar removed successfully");
            result.Data = new { Message = "Avatar removed successfully" };
            return Json(result);
        }
    }
}
