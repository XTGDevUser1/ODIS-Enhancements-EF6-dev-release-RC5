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
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.Admin.Controllers
{
    /// <summary>
    /// DataGroupsController
    /// </summary>
    public class DataGroupsController : BaseController
    {

        #region Public Methods
        
        /// <summary>
        /// View page for the Data Group
        /// </summary>
        /// <returns></returns>
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Index()
        {
            logger.Info("Inside Index() of DataGroupController. Attempt to call the view");
            return View();
        }

        /// <summary>
        /// Lists the specified request.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [NoCache]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult List([DataSourceRequest] DataSourceRequest request)
        {
            logger.Info("Inside List() of DataGroupController. Attempt to get all DataGroups depending upon the GridCommand");
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
            DataGroupFacade dataGroupFacade = new DataGroupFacade();
            List<DataGroupList> list = dataGroupFacade.List((Guid)GetLoggedInUser().ProviderUserKey, pageCriteria);
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
        /// Retrieve Single record for the data group either in view or edit mode
        /// </summary>
        /// <param name="selectedDataGroupId">The selected data group id.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Get(string selectedDataGroupId, string mode)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Get() of DataGroupController with the selectedDataGroupId {0} and mode {1}", selectedDataGroupId, mode);
            DataGroup dataGroup = null;
            Guid userId = (Guid)System.Web.Security.Membership.FindUsersByName(GetLoggedInUser().UserName)[GetLoggedInUser().UserName].ProviderUserKey;
            if (mode != "add")
            {
                logger.InfoFormat("Try to get the DataGroup with selectedDataGroupId {0}", selectedDataGroupId);
                DataGroupFacade dataGroupFacade = new DataGroupFacade();
                dataGroup = dataGroupFacade.Get(selectedDataGroupId);
                logger.InfoFormat("Got the DataGroup with DataGroupId {0}", dataGroup.ID);
            }
            ViewData[StaticData.Organizations.ToString()] = ReferenceDataRepository.GetOrganizations(userId).ToSelectListItem<dms_users_organizations_List>(x => x.ID.ToString(), y => y.Name, true);
            ViewData[StaticData.Programs.ToString()] = ReferenceDataRepository.GetDataGroupPrograms(userId,string.Empty).ToSelectListItem<ProgramsList>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID, y.Name), false);
            ViewData["mode"] = mode;
            ViewData["UserId"] = userId;
            logger.Info("Call the partial view '_DataGroup' ");
            return PartialView("_DataGroupRegistration", SetDataGroupModel(dataGroup ?? new DataGroup()));

        }

        /// <summary>
        /// Save the Data Group Details into database.
        /// </summary>
        /// <param name="dataGroupModel">The data group model.</param>
        /// <param name="hdnfldMode">The HDNFLD mode.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Save(DataGroupModel dataGroupModel, string hdnfldMode)
        {
            OperationResult result = new OperationResult();
            if (ModelState.IsValid)
            {
                logger.InfoFormat("Inside Save() of DataGroupController with mode {0}", hdnfldMode);

                if (hdnfldMode == "add")
                {
                    logger.InfoFormat("Try to add a new DataGroup with DataGroup name {0}", dataGroupModel.DataGroup.Name);
                    DataGroupFacade dataGroupFacade = new DataGroupFacade();
                    dataGroupFacade.Add(dataGroupModel.DataGroup, dataGroupModel.DataGroupProgramValues, GetLoggedInUser().UserName);
                    logger.Info("A new user has been created");
                }
                else
                {
                    logger.InfoFormat("Try to update the DataGroup whose DataGroupId is {0}", dataGroupModel.DataGroup.ID);
                    DataGroupFacade dataGroupFacade = new DataGroupFacade();
                    dataGroupFacade.Update(dataGroupModel.DataGroup, dataGroupModel.DataGroupProgramValues, GetLoggedInUser().UserName);
                    logger.InfoFormat("The DataGroup {0} has been updated", dataGroupModel.DataGroup.ID);
                }
                result.OperationType = "Success";
                result.Status = OperationStatus.SUCCESS;
                return Json(result);
            }
            var errorList = GetErrorsFromModelStateAsString();
            logger.Error(errorList);
            throw new DMSException(errorList);

        }
        /// <summary>
        /// Delete data group from database.
        /// </summary>
        /// <param name="selectedDataGroupId">The selected data group id.</param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        public ActionResult Delete(string selectedDataGroupId)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Delete() of DataGroupController with the DataGroupId {0}", selectedDataGroupId);
            DataGroupFacade dataGroupFacade = new DataGroupFacade();
            dataGroupFacade.Delete(selectedDataGroupId);
            logger.InfoFormat("The record with dataGroupId {0} has been Deleted", selectedDataGroupId);
            result.OperationType = "Success";
            result.Status = "Success";
            return Json(result);

        }
        #endregion

        #region Helper Methods
        /// <summary>
        /// Sets the data group model.
        /// </summary>
        /// <param name="dataGroup">The data group.</param>
        /// <returns></returns>
        private DataGroupModel SetDataGroupModel(DataGroup dataGroup)
        {
            DataGroupModel dataGroupModel = new DataGroupModel();
            if (dataGroup == null)
            {
                return dataGroupModel;
            }
            dataGroupModel.DataGroup = dataGroup;
            dataGroupModel.LastUpdateInformation = string.Format("{0} {1}", dataGroup.ModifyBy, dataGroup.ModifyDate);
            if (dataGroup.DataGroupPrograms != null)
            {
                List<DataGroupProgram> dataGroupProgram = dataGroup.DataGroupPrograms.ToList();
                dataGroupModel.DataGroupProgramValues = new int[dataGroup.DataGroupPrograms.Count];
                for (int i = 0; i < dataGroup.DataGroupPrograms.Count; i++)
                {
                    dataGroupModel.DataGroupProgramValues[i] = dataGroupProgram[i].ProgramID;
                }
            }
            return dataGroupModel;
        }

        #endregion
    }
}
