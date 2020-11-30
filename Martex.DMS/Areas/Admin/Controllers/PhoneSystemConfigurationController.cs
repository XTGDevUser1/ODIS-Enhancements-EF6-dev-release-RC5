using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.ActionFilters;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.Models;
using Martex.DMS.Common;
using System.Web.Helpers;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.DMSBaseException;
using Kendo.Mvc.UI;
using Martex.DMS.Areas.Application.Models;

namespace Martex.DMS.Areas.Admin.Controllers
{
    /// <summary>
    /// Phone System Configuration Controller
    /// </summary>
    public class PhoneSystemConfigurationController : BaseController
    {

        #region Public Methods
        /// <summary>
        /// View page for the Phone System Configuration
        /// </summary>
        /// <returns></returns>
        //[DMSAuthorize]
        [NoCache]
        public ActionResult Index()
        {
            logger.Info("Inside Index() of PhoneSystemConfigurationController. Attempt to call the view");
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
            PhoneSystemConfigurationFacade facade = new PhoneSystemConfigurationFacade();
            List<PhoneSystemConfigurationList> list = facade.List(pageCriteria, GetLoggedInUserId());
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
        /// Used to get the specific phone system configuration details based on the given id
        /// </summary>
        /// <param name="phoneSystemConfigurationId">The phone system configuration id.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Programs, true)]
        [ReferenceDataFilter(StaticData.IvrScript, true)]
        [ReferenceDataFilter(StaticData.InBoundPhoneCompany, true)]
        [ReferenceDataFilter(StaticData.SkillSet, true)]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        [HttpPost]
        [NoCache]
        public ActionResult Get(string phoneSystemConfigurationId, string mode)
        {

            OperationResult result = new OperationResult();

            Martex.DMS.DAL.PhoneSystemConfiguration phoneSystemConfigurationModel = new Martex.DMS.DAL.PhoneSystemConfiguration();
            logger.InfoFormat("Inside Get() of PhoneSystemConfigurationControlloer with the Id {0} and mode {1}", phoneSystemConfigurationId, mode);

            if (mode != "add")
            {
                logger.InfoFormat("Try to get the phone system configuration with Id {0}", phoneSystemConfigurationId);
                phoneSystemConfigurationModel = (new PhoneSystemConfigurationFacade().Get(int.Parse(phoneSystemConfigurationId)));
                logger.InfoFormat("Get the Phone System Configuration with Id {0}", phoneSystemConfigurationId);
            }

            ViewData["mode"] = mode;
            logger.Info("Call the partial view '_PhoneSystemConfiguration' ");
            return PartialView("_PhoneSystemConfiguration", phoneSystemConfigurationModel);

        }

        /// <summary>
        /// Delete phone system configuration details from database.
        /// </summary>
        /// <param name="phoneSystemConfigurationId">The phone system configuration id.</param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        [NoCache]
        public ActionResult Delete(int phoneSystemConfigurationId)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Delete() of PhoneSystemConfigurationController with the Id {0}", phoneSystemConfigurationId);
            PhoneSystemConfigurationFacade facade = new PhoneSystemConfigurationFacade();
            facade.Delete(phoneSystemConfigurationId);
            logger.InfoFormat("The record with Id {0} has been Deleted", phoneSystemConfigurationId);
            result.OperationType = "Success";
            result.Status = "Success";
            return Json(result);

        }
        /// <summary>
        /// Save the phone system configuration details into database.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="hdnfldMode">The HDNFLD mode.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        [NoCache]
        public ActionResult Save(Martex.DMS.DAL.PhoneSystemConfiguration model, string hdnfldMode)
        {
            OperationResult result = new OperationResult();

            if (ModelState.IsValid)
            {
                PhoneSystemConfigurationFacade facade = new PhoneSystemConfigurationFacade();
                logger.InfoFormat("Inside Save() of PhoneSystemConfigurationControlloer with mode {0}", hdnfldMode);
                model.ModifyBy = GetLoggedInUser().UserName;
                model.ModifyDate = DateTime.Now;

                if (hdnfldMode == "add")
                {
                    logger.InfoFormat("Try to add a new Phone System Configuration with Program ID {0}", model.ProgramID);
                    model.CreateBy = GetLoggedInUser().UserName;
                    model.CreateDate = DateTime.Now;
                    facade.Add(model);
                    logger.Info("A Phone System Configuration has been created");
                }
                else
                {
                    logger.InfoFormat("Try to update the Phone System Configuration with ID {0}", model.ID);
                    facade.Update(model);
                    logger.InfoFormat("The Phone System Configuration has been updated", model.ID);
                }
                result.OperationType = "Success";
                result.Status = OperationStatus.SUCCESS;
                return Json(result);
            }
            var errorList = GetErrorsFromModelStateAsString();
            logger.Warn(errorList);
            throw new DMSException(errorList);
        }
        #endregion

        #region Helper Methods
        /// <summary>
        /// Used to get the program name based on the ID
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns>
        /// Program Name
        /// </returns>
        [HttpPost]
        //[DMSAuthorize]
        [NoCache]
        public ActionResult GetProgramName(string programId)
        {
            OperationResult operationResult = new OperationResult();

            string programName = new PhoneSystemConfigurationFacade().GetProgramName(int.Parse(programId));
            operationResult.Status = OperationStatus.SUCCESS;
            operationResult.Data = programName;
            return Json(operationResult);

        }
        /// <summary>
        /// Used in telerik Grid to get the id of a selected row.
        /// </summary>
        /// <param name="Id">The id.</param>
        /// <returns>
        /// Phone System Configuration ID
        /// </returns>
        public ActionResult GetPhoneSystemConfigurationID(string Id)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside GetPhoneSystemConfigurationID() of PhoneSystemConfigurationController. Call by the grid with the userId {0}, try to returns the Jeson object", Id);
            return Json(new { IdValue = Id }, JsonRequestBehavior.AllowGet);

        }
        #endregion


    }
}
