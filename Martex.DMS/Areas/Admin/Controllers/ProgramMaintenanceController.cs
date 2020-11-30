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
using Martex.DMS.DAO;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using Martex.DMS.Areas.Admin.Models;
using Kendo.Mvc.UI;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.Areas.Admin.Controllers
{
    /// <summary>
    /// Program Maintenance Controller
    /// </summary>
    public class ProgramMaintenanceController : BaseController
    {

        #region Public Methods
        /// <summary>
        /// Returns list of program
        /// </summary>
        /// <returns></returns>
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        [NoCache]
        public ActionResult Index()
        {
            logger.Info("Inside Index() of Program Maintenance. Attempt to call the view");
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
            ProgramMaintenanceFacade facade = new ProgramMaintenanceFacade();
            List<Programs_List_Results> list = facade.List(pageCriteria, (Guid)GetLoggedInUser().ProviderUserKey);
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
        /// Retrieve details about program based on the given id
        /// </summary>
        /// <param name="programMaintenanceId">The program maintenance id.</param>
        /// <param name="mode">The mode.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Clients, true)]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        [HttpPost]
        [NoCache]
        public ActionResult Get(string programMaintenanceId, string mode)
        {
            OperationResult result = new OperationResult();

            Program model = new Program();
            model.IsActive = true;
            logger.InfoFormat("Inside Get() of Program Maintenance with the Id {0} and mode {1}", programMaintenanceId, mode);
            //ViewData[StaticData.Programs.ToString()] = ReferenceDataRepository.GetParentProgramsForProgram((Guid)GetLoggedInUser().ProviderUserKey, programMaintenanceId).ToSelectListItem<ProgramsList>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID, y.Name), true);
            //CR 270
            if (mode != "add")
            {
                logger.InfoFormat("Try to get the Program Details with Id {0}", programMaintenanceId);
                model = (new ProgramMaintenanceFacade().Get(int.Parse(programMaintenanceId)));
                logger.InfoFormat("Get the Program Maintenance with Id {0}", programMaintenanceId);
            }

            List<Program> list = ReferenceDataRepository.GetProgramByClientOrderByID(model.ClientID.GetValueOrDefault());
            List<SelectListItem> items = new List<SelectListItem>();
            items.Add(new SelectListItem() { Selected = true, Text = "Select", Value = string.Empty });
            list.ForEach(x =>
            {
                items.Add(new SelectListItem()
                {
                    Text = x.IsGroup ? x.Name + " (Group)" : x.Name,
                    Value = x.ID.ToString()
                });
            });
            ViewData[StaticData.Programs.ToString()] = items;

            ViewData["mode"] = mode;
            logger.Info("Call the partial view '_ProgramMaintenance' ");
            return PartialView("_ProgramMaintenance", model);

        }
        /// <summary>
        /// Delete a particualr record from database based on the given id
        /// </summary>
        /// <param name="programMaintenanceId"></param>
        /// <returns></returns>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        [NoCache]
        public ActionResult Delete(int programMaintenanceId)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside Delete() of Program with the Id {0}", programMaintenanceId);
            ProgramMaintenanceFacade facade = new ProgramMaintenanceFacade();
            facade.Delete(programMaintenanceId);
            logger.InfoFormat("The record with Id {0} has been Deleted", programMaintenanceId);
            result.OperationType = "Success";
            result.Status = "Success";
            return Json(result);

        }
        /// <summary>
        /// Save the record into database for program
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="hdnfldMode">The HDNFLD mode.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        [HttpPost]
        //[DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_DISPATCH_ADMIN)]
        [NoCache]
        public ActionResult Save(Program model, string hdnfldMode)
        {
            OperationResult result = new OperationResult();

            if (ModelState.IsValid)
            {
                ProgramMaintenanceFacade facade = new ProgramMaintenanceFacade();
                logger.InfoFormat("Inside Save() of Program Maintenanance Controller with mode {0}", hdnfldMode);
                model.ModifyBy = GetLoggedInUser().UserName;
                model.ModifyDate = DateTime.Now;

                if (hdnfldMode == "add")
                {
                    logger.InfoFormat("Try to add a new Program with Program Code {0}", model.Code);
                    model.CreateBy = GetLoggedInUser().UserName;
                    model.CreateDate = DateTime.Now;
                    facade.Add(model);
                    logger.Info("A Program has been created");
                }
                else
                {
                    logger.InfoFormat("Try to update the Program with ID {0}", model.ID);
                    facade.Update(model);
                    logger.InfoFormat("The Program has been updated", model.ID);
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
        /// Used to Retrieve the program information by passing Program ID
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public ActionResult GetProgramInformationDuringCall(int? programId,bool isCoverageInfoVisible = true)
        {
            logger.InfoFormat("ProgramMaintenanceController - GetProgramInformationDuringCall() - programId : {0}, isCoverageInfoVisible : {1}", programId.GetValueOrDefault(), isCoverageInfoVisible);
            MemberFacade memberFacade = new MemberFacade();
            ProgramInfoModel model = new ProgramInfoModel();
            //KB: TFS : 452
            //DMSCallContext.MemberProgramID = programId.GetValueOrDefault();
            var facade = new ProgramMaintenanceFacade();
            List<ProgramInformation_Result> info = facade.GetProgramInfo(programId, "ProgramInfo", null);
            List<ProgramServices_Result> services = new List<ProgramServices_Result>();// CR: 625 - Commented out this call. facade.GetProgramServices(programId, "Service");
            model.ProgramInformation = info;
            model.ProgramServices = services;
            model.IsCoverageInfoVisible = isCoverageInfoVisible;
            model.ProgramServiceEventLimit = memberFacade.GetProgramServiceEventLimit(programId.GetValueOrDefault());

            string vinNumber = string.Empty;
            if (DMSCallContext.CaseID > 0)
            {
                CaseFacade caseFacade = new CaseFacade();
                Case caseDetails = caseFacade.GetCaseById(DMSCallContext.CaseID);
                vinNumber = caseDetails == null ? string.Empty : caseDetails.VehicleVIN;
            }
            MemberManagementFacade memberManagefacade = new MemberManagementFacade();
            model.MemberProducts = memberManagefacade.GetMemberProducts(DMSCallContext.MemberID, DMSCallContext.ProductCategoryID, vinNumber);

            return PartialView("_ProgramInfo", model);
        }
        /// <summary>
        /// Used to retrieve Call Scripts for the given program.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public ActionResult GetCallScripts(int? programId)
        {
            logger.InfoFormat("ProgramMaintenanceController - GetCallScripts() - programId : {0}", programId.GetValueOrDefault());
            var facade = new ProgramMaintenanceFacade();
            List<ProgramInformation_Result> data = facade.GetProgramInfo(programId, "CallScript", "Welcome");
            OperationResult result = new OperationResult();
            result.Status = OperationStatus.SUCCESS;
            result.Data = data;
            return Json(result);
        }
        /// <summary>
        /// Used to get Program ID based on the row selected in telerik grid.
        /// </summary>
        /// <param name="Id">The id.</param>
        /// <returns></returns>
        public ActionResult GetProgramMaintenanceID(string Id)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside GetProgramMaintenanceID() of Program Maintenance Controller. Call by the grid with the Id {0}, try to returns the Jeson object", Id);
            return Json(new { IdValue = Id }, JsonRequestBehavior.AllowGet);

        }

        /// <summary>
        /// Gets the program configuration.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="configurationType">Type of the configuration.</param>
        /// <param name="configurationCategory">The configuration category.</param>
        /// <returns></returns>
        public ActionResult GetProgramConfig(int programID, string configurationType, string configurationCategory, string name)
        {
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(programID, configurationType, configurationCategory);
            if (!string.IsNullOrEmpty(name))
            {
                result = result.Where(x => x.Name == name).ToList();
            }
            
            logger.InfoFormat("Returning Program configuration data for Program ID = {0}, ConfigurationType = {1}, ConfigurationCategory = {2}, name = {3}", programID, configurationType, configurationCategory, name);
            OperationResult operationResult = new OperationResult();
            operationResult.Data = result;
            return Json(operationResult);

        }
        #endregion
    }
}
