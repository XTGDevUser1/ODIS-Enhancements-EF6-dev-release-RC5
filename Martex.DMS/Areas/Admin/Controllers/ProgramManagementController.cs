using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.ActionFilters;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Kendo.Mvc.UI;
using Martex.DMS.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.Models;
using Martex.DMS.DAL.Entities;

/// <summary>
/// 
/// </summary>
namespace Martex.DMS.Areas.Admin.Controllers
{
    /// <summary>
    /// Program Management Controller
    /// </summary>
    public class ProgramManagementController : BaseController
    {
        #region Private Methods
        /// <summary>
        /// The facade
        /// </summary>
        private ProgramManagementFacade facade = new ProgramManagementFacade();
        #endregion

        #region Public Methods
        #region Program Maintenance Region
        /// <summary>
        /// Indexes this instance.
        /// </summary>
        /// <returns></returns>
        [DMSAuthorize(Securable = DMSSecurityProviderFriendlyName.MENU_LEFT_ADMIN_PROGRAM_MANAGEMENT)]
        public ActionResult Index()
        {
            return View();
        }

        /// <summary>
        /// Gets the program list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult _GetProgramList([DataSourceRequest] DataSourceRequest request, ProgramManagementSearchCriteria model)
        {
            logger.Info("Inside _GetProgramList of ProgramManagementController. Attempt to get all Programs List depending upon the GridCommand");

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
            if (request.Sorts.Count > 0)
            {
                sortColumn = request.Sorts[0].Member;
                sortOrder = (request.Sorts[0].SortDirection == System.ComponentModel.ListSortDirection.Ascending) ? "ASC" : "DESC";
            }

            List<NameValuePair> filter = model.GetFilterClause();

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
            List<ProgramManagement_List_Result> list = new List<ProgramManagement_List_Result>();
            //if (filter.Count > 0)
            //{
            //    list = facade.GetProgramMaintenenceList(pageCriteria);
            //}
            list = facade.GetProgramManagementList(pageCriteria);
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
        /// Gets the search criteria.
        /// </summary>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.SearchFilterTypes, true)]
        [ReferenceDataFilter(StaticData.Clients, true)]
        [HttpPost]
        public ActionResult _SearchCriteria(ProgramManagementSearchCriteria model)
        {
            ProgramManagementSearchCriteria tempModel = model;
            ModelState.Clear();
            ViewData[StaticData.ProgramsForClient.ToString()] = ReferenceDataRepository.GetProgramByClient(model.ClientID.GetValueOrDefault()).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true);
            if (model.FilterToLoadID.HasValue)
            {
                ProgramManagementSearchCriteria dbModel = tempModel.GetView(model.FilterToLoadID) as ProgramManagementSearchCriteria;
                if (dbModel != null)
                {
                    ViewData[StaticData.ProgramsForClient.ToString()] = ReferenceDataRepository.GetProgramByClient(dbModel.ClientID.GetValueOrDefault()).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true);
                    return PartialView(dbModel);
                }
            }
            return PartialView(tempModel.GetModelForSearchCriteria());
        }

        public ActionResult GetPrograms(int? clientID)
        {
            List<Program> list = ReferenceDataRepository.GetProgramByClient(clientID.GetValueOrDefault(), true);
            return Json(list.ToSelectListItem(x => x.ID.ToString(), y => y.Description, true), JsonRequestBehavior.AllowGet);
        }
        /// <summary>
        /// Gets the selected criteria.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _SelectedCriteria(ProgramManagementSearchCriteria model)
        {
            return PartialView(model.GetModelForSearchCriteria());
        }

        /// <summary>
        /// Gets the program maintenance tabs.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramMaintenanceTabs(int programID, string pageMode)
        {
            ViewData["mode"] = pageMode;
            Program programDetails = new ProgramMaintenanceFacade().Get(programID);
            return PartialView(programDetails);
        }
        #endregion

        #region Program Information Region
        /// <summary>
        /// Gets the program information.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramInformation(int programID, string pageMode)
        {
            logger.InfoFormat("Trying to retrieve Program Information Details for Program ID {0}", programID);
            ProgramManagementFacade facade = new ProgramManagementFacade();
            ProgramManagementInformation_Result result = facade.GetProgramManagementInformation(programID);

            ViewData[StaticData.Programs.ToString()] = ReferenceDataRepository.GetParentProgramsForProgram((Guid)GetLoggedInUser().ProviderUserKey, programID.ToString()).ToSelectListItem<ProgramsList>(x => x.ID.ToString(), y => string.Format("{0} - {1}", y.ID, y.Name), true);
            var programList = ReferenceDataRepository.GetProgramByClient(result.ClientID).ToSelectListItem<Program>(x => x.ID.ToString().ToString(), y => y.Description, true);


            programList = programList.Where(u => u.Value != programID.ToString()).ToList();

            ViewData[StaticData.ProgramsForClient.ToString()] = programList;
            ViewData["ProgramID"] = programID;
            result.PageMode = pageMode;
            return PartialView(result);
        }

        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveProgramInfoData(ProgramManagementInformation_Result model)
        {
            OperationResult result = new OperationResult();
            logger.Info("Executing Save Program Information Section");
            ProgramManagementFacade facade = new ProgramManagementFacade();
            facade.SaveProgramInfoData(model, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Finished Save Program Information Section");
            return Json(result);
        }
        #endregion

        #region Program Services Region
        /// <summary>
        /// Gets the program services.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramServices(int programID, string pageMode)
        {
            logger.InfoFormat("Trying to retrieve Program Services Details for Program ID {0}", programID);
            ViewData["mode"] = pageMode;
            return PartialView(programID);
        }

        /// <summary>
        /// Gets the program management services list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public ActionResult _GetProgramManagementServicesList([DataSourceRequest] DataSourceRequest request, int programID)
        {
            logger.InfoFormat("Inside _GetProgramManagementServicesList of ProgramManagementController. Attempt to get all Program Services List depending upon the GridCommand for Program ID {0}", programID);

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
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
            List<ProgramManagementServicesList_Result> list = facade.GetProgramManagementServicesList(pageCriteria, programID);

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
        /// Deletes the service information.
        /// </summary>
        /// <param name="programServiceId">The program service identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _DeleteServiceInformation(int? programServiceId)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside _DeleteServiceInformation() of ProgramManagementController with ID : {0}", programServiceId);
            facade.DeleteServiceInformation(programServiceId.GetValueOrDefault());
            logger.Info("Deleted Program Service successfully");
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }
        #endregion

        #region Program Rules Region
        /// <summary>
        /// Gets the program rules.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramRules(int programID, string pageMode)
        {
            logger.InfoFormat("Trying to retrieve Program Rule Details for Program ID {0}", programID);
            ViewData["mode"] = pageMode;
            return PartialView(programID);
        }

        /// <summary>
        /// _s the get program management program service event limit list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public ActionResult _GetProgramManagementProgramServiceEventLimitList([DataSourceRequest] DataSourceRequest request, int programID)
        {
            logger.InfoFormat("Inside _GetProgramManagementProgramServiceEventLimitList of ProgramManagementController. Attempt to get all Program Services Event Limits List depending upon the GridCommand for Program ID {0}", programID);

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
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
            List<ProgramManagementProgramServiceEventLimitList_Result> list = facade.GetProgramManagementProgramServiceEventLimitList(pageCriteria, programID);

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
        /// Deletes the service event limit information.
        /// </summary>
        /// <param name="serviceEventLimitID">The service event limit identifier.</param>
        /// <returns></returns>
        public ActionResult _DeleteServiceEventLimitInformation(int serviceEventLimitID)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Inside _DeleteServiceEventLimitInformation() of ProgramManagementController with ID:{0}", serviceEventLimitID);

            try
            {
                facade.DeleteServiceEventLimitInformation(serviceEventLimitID);
                logger.Info("Deleted Successfully");
                result.Status = OperationStatus.SUCCESS;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message);
                result.Status = OperationStatus.ERROR;
                result.Data = ex.Message.ToString();
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Gets the program management service event limit information.
        /// </summary>
        /// <param name="pselID">The psel identifier.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Programs, true)]
        [ReferenceDataFilter(StaticData.ProductCategoryForRules, true)]
        [ReferenceDataFilter(StaticData.VehicleType, true)]
        [ReferenceDataFilter(StaticData.VehicleCategory, true)]
        [ReferenceDataFilter(StaticData.WarrantyPeriodUOM, true)]
        [ReferenceDataFilter(StaticData.Product, true)]
        public ActionResult _GetProgramManagementServiceEventLimitInformation(int? pselID, string mode, int? programId)
        {
            logger.InfoFormat("Inside GetProgramManagementServiceEventLimitInformation() of ProgramManagementController with ID:{0}", pselID);

            ProgramServiceEventLimit psel = new ProgramServiceEventLimit();
            ViewData["mode"] = mode;
            if (pselID != null && pselID > 0)
            {
                psel = facade.GetProgramManagementServiceEventLimitInformation(pselID.Value);
                logger.Info("Retrieved ProgramServiceEventLimit successfully");
            }
            else
            {
                psel.ID = 0;
            }
            logger.Info("Return View");
            return View(psel);
        }

        /// <summary>
        /// Saves the program management service event limit information.
        /// </summary>
        /// <param name="psel">The psel.</param>
        /// <returns></returns>

        public ActionResult _SaveProgramManagementServiceEventLimitInformation(ProgramServiceEventLimit psel)
        {
            logger.InfoFormat("Inside SaveProgramManagementServiceEventLimitInformation() of ProgramManagementController.");
            OperationResult result = new OperationResult();

            try
            {
                facade.SaveProgramManagementServiceEventLimitInformation(psel, LoggedInUserName);
                logger.Info("Saved Successfully");
                result.Status = OperationStatus.SUCCESS;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message);
                result.Status = OperationStatus.ERROR;
                logger.InfoFormat("ProgramServiceEventLimit Info not saved. Exception: {0}", ex.Message.ToString());
                result.Data = ex.Message.ToString();
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion

        #region Program Phone System Configuration Region
        /// <summary>
        /// Gets the program phone system configuration.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [ReferenceDataFilter(StaticData.Programs, true)]
        [ReferenceDataFilter(StaticData.IvrScript, true)]
        [ReferenceDataFilter(StaticData.InBoundPhoneCompany, true)]
        [ReferenceDataFilter(StaticData.SkillSet, true)]
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramPhoneSystemConfiguration(int programID, string pageMode)
        {
            logger.InfoFormat("Trying to retrieve Program Phone System Configuration Details for Program ID {0}", programID);

            OperationResult result = new OperationResult();

            Martex.DMS.DAL.PhoneSystemConfiguration phoneSystemConfigurationModel = new Martex.DMS.DAL.PhoneSystemConfiguration();
            logger.InfoFormat("Inside _ProgramPhoneSystemConfiguration() of ProgramManagementController with the Id {0} and mode {1}", programID, pageMode);

            if (pageMode != "add")
            {
                logger.InfoFormat("Try to get the phone system configuration with Id {0}", programID);
                phoneSystemConfigurationModel = facade.GetPhoneSystemConfiguration(programID);
                logger.InfoFormat("Get the Phone System Configuration with Id {0}", programID);
            }
            else
            {
                phoneSystemConfigurationModel.ID = 0;
            }

            ViewData["mode"] = pageMode;
            ViewData["ProgramID"] = programID;
            logger.Info("Call the partial view '_PhoneSystemConfiguration' ");
            return PartialView(phoneSystemConfigurationModel);
        }

        /// <summary>
        /// Saves the program phone system configuration information data.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [HttpPost]
        public ActionResult SaveProgramPhoneSystemConfigurationInfoData(PhoneSystemConfiguration model)
        {
            OperationResult result = new OperationResult();
            logger.Info("Executing Save Program Phone System Configuration Information Section");
            ProgramManagementFacade facade = new ProgramManagementFacade();
            facade.SaveProgramPhoneSystemConfigurationInfoData(model, LoggedInUserName);
            result.Status = OperationStatus.SUCCESS;
            logger.Info("Finished Save Program Phone System Configuration Information Section");
            return Json(result);
        }
        #endregion

        #region Program Data Item Region
        /// <summary>
        /// _s the program data item.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramDataItem(int programID, string pageMode)
        {
            logger.InfoFormat("Trying to retrieve Program Phone System Configuration Details for Program ID {0}", programID);
            ViewData["mode"] = pageMode;
            return PartialView(programID);
        }

        /// <summary>
        /// Gets the program management program data items list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _GetProgramManagementProgramDataItemsList([DataSourceRequest] DataSourceRequest request, int programID)
        {
            logger.InfoFormat("Inside _GetProgramManagementProgramDataItemsList of ProgramManagementController. Attempt to get all Program Data Items List depending upon the GridCommand for Program ID {0}", programID);

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
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
            List<ProgramManagementProgramDataItemList_Result> list = facade.GetProgramManagementProgramDataItemList(pageCriteria, programID);

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
        /// Gets the program data item information.
        /// </summary>
        /// <param name="programDataItemId">The program data item identifier.</param>
        /// <param name="mode">The mode.</param>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.ControlType, true)]
        [ReferenceDataFilter(StaticData.DataType, true)]
        [ReferenceDataFilter(StaticData.Programs, true)]
        public ActionResult _ProgramDataItemInformation(int? programDataItemId, string mode, int? programId)
        {
            ProgramDataItem dataItem = new ProgramDataItem();
            ProgramManagementFacade facade = new ProgramManagementFacade();
            if (programDataItemId.HasValue)
            {
                dataItem = facade.GetProgramDataItemDetails(programDataItemId.Value, programId.Value);
            }
            else
            {
                dataItem.ID = 0;
            }

            ViewData["mode"] = mode;
            ViewData["programId"] = programId;
            return PartialView(dataItem);
        }

        /// <summary>
        /// Saves the data item information.
        /// </summary>
        /// <param name="pdi">The pdi.</param>
        /// <returns></returns>
        public ActionResult _SaveDataItemInformation(ProgramDataItem pdi)
        {
            OperationResult result = new OperationResult();
            logger.Info("Inside _SaveDataItemInformation of ProgramManagementController");
            facade.SaveDataItemInformation(pdi, LoggedInUserName);
            logger.Info("Saved Successfully");
            result.Status = OperationStatus.SUCCESS;
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Deletes the data item information.
        /// </summary>
        /// <param name="programDataItemID">The program data item identifier.</param>
        /// <returns></returns>
        public ActionResult _DeleteDataItemInformation(int programDataItemID)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside DeleteDataItemInformation() of ProgramManagementController with ProgramDatItemID:{0}", programDataItemID);

            try
            {
                facade.DeleteDataItemInformation(programDataItemID);
                logger.Info("Deleted Successfully");
                result.Status = OperationStatus.SUCCESS;
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message);
                result.Status = OperationStatus.ERROR;
                result.Data = ex.Message.ToString();
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

        #region Program Configuration Region
        /// <summary>
        /// Gets the program configuration.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramConfiguration(int programID, string pageMode)
        {
            logger.InfoFormat("Trying to retrieve Program Configuration Details for Program ID {0}", programID);
            ViewData["mode"] = pageMode;
            return PartialView(programID);
        }

        /// <summary>
        /// Gets the program configuration.
        /// </summary>
        /// <param name="programConfigurationId">The program configuration identifier.</param>
        /// <param name="mode">The mode.</param>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.ConfigurationCategory, true)]
        [ReferenceDataFilter(StaticData.ConfigurationType, true)]
        [ReferenceDataFilter(StaticData.ControlType, true)]
        [ReferenceDataFilter(StaticData.DataType, true)]
        public ActionResult GetProgramConfiguration(int? programConfigurationId, string mode, int? programId)
        {
            ProgramConfiguration configuration = new ProgramConfiguration();
            ProgramManagementFacade facade = new ProgramManagementFacade();
            if (programConfigurationId.HasValue)
            {
                configuration = facade.GetProgramConfigurationDetails(programConfigurationId.Value, programId.Value);
            }
            if (mode.ToLower() == "edit")
            {
                configuration.ID = programConfigurationId.Value;
            }
            ViewData["mode"] = mode;
            ViewData["programId"] = programId;
            return PartialView("_ProgramConfigurationInformation", configuration);
        }
        /// <summary>
        /// Saves the configuration.
        /// </summary>
        /// <param name="configuration">The configuration.</param>
        /// <param name="pagemode">The pagemode.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _SaveConfiguration(ProgramConfiguration configuration, string pagemode)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside SaveConfiguration() of ProgramManagementController with mode {0}", pagemode);
            bool isadd = (pagemode.ToLower() == "add") ? true : false;
            facade.SaveProgramConfiguration(configuration, isadd, LoggedInUserName, DateTime.Now);
            logger.Info("Saved Program Configuration successfully");
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        /// <summary>
        /// Deletes the program configuration.
        /// </summary>
        /// <param name="programConfigurationId">The program configuration identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _DeleteProgramConfiguration(int? programConfigurationId)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside _DeleteProgramConfiguration() of ProgramManagementController with ID : {0}", programConfigurationId);
            facade.DeleteProgramConfiguration(programConfigurationId.GetValueOrDefault());
            logger.Info("Deleted Program Configuration successfully");
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="request"></param>
        /// <param name="programID"></param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult _GetProgramConfigurationList([DataSourceRequest] DataSourceRequest request, int? programID)
        {
            logger.Info("Inside _GetProgram Configuration List of ProgramManagementController. Attempt to get all Programs List depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
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
            List<ProgramManagementProgramConfigurationList_Result> list = facade.GetProgramConfigurationList(pageCriteria, programID.GetValueOrDefault());

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
        #endregion

        #region Program Service Categories Region
        /// <summary>
        /// Gets the program service categories.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramServiceCategories(int programID, string pageMode)
        {
            logger.InfoFormat("Trying to retrieve Program Service Categories for Program ID {0}", programID);
            ViewData["mode"] = pageMode;
            return PartialView(programID);
        }

        /// <summary>
        /// Gets the program management service categories list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public ActionResult _GetProgramManagementServiceCategoriesList([DataSourceRequest] DataSourceRequest request, int programID)
        {
            logger.InfoFormat("Inside _GetProgramManagementServiceCategoriesList of ProgramManagementController. Attempt to get all Program Service Categories List depending upon the GridCommand for Program ID {0}", programID);

            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
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
            List<ProgramManagementServiceCategoriesList_Result> list = facade.GetProgramManagementServiceCategoriesList(pageCriteria, programID);

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
        /// Gets the program service category information.
        /// </summary>
        /// <param name="programServiceCategoryId">The program service category identifier.</param>
        /// <param name="mode">The mode.</param>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        [ReferenceDataFilter(StaticData.VehicleCategory, true)]
        [ReferenceDataFilter(StaticData.VehicleType, true)]
        public ActionResult _ProgramServiceCategoryInformation(int? programServiceCategoryId, string mode, int? programId)
        {
            ProgramManagementFacade facade = new ProgramManagementFacade();
            ProgramManagementProgramServiceCategory_Result serviceCategory = new ProgramManagementProgramServiceCategory_Result();
            List<ProductCategory> pcListSorted = ReferenceDataRepository.GetProductCategories();
            List<ProductCategory> pcList = ReferenceDataRepository.GetProductCategories();
            PageCriteria pageCriteria = new PageCriteria()
            {
                StartInd = 1,
                EndInd = 100,
                PageSize = 100,
                SortDirection = "",
                SortColumn = "",
                WhereClause = null
            };
            List<ProgramManagementServiceCategoriesList_Result> list = facade.GetProgramManagementServiceCategoriesList(pageCriteria, programId);
            int totalRows = list.Count;

            if (programServiceCategoryId.HasValue)
            {
                serviceCategory = facade.GetProgramManagementProgramServiceCategory(programServiceCategoryId.GetValueOrDefault());
            }
            else
            {
                serviceCategory = facade.GetProgramManagementProgramServiceCategory(0);
            }
            if (serviceCategory.ProgramID > 0)
            {
                serviceCategory.ProgramID = programId.GetValueOrDefault();
            }

            for (int i = 0; i < totalRows; i++)
            {
                foreach (var pc in pcList)
                {
                    if (list[i].ProductCategoryID == pc.ID)
                    {

                        var onlyMatch = pcListSorted.Single(s => s.ID == pc.ID);
                        if (mode == "add")
                        {
                            pcListSorted.Remove(onlyMatch);
                        }
                        else
                        {
                            if (pc.ID != serviceCategory.ProductCategoryID)
                            {
                                pcListSorted.Remove(onlyMatch);
                            }
                        }
                    }
                }
            }
            ViewData[StaticData.ProductCategory.ToString()] = pcListSorted.ToSelectListItem(x => x.ID.ToString(), y => y.Name, false);
            if (!programServiceCategoryId.HasValue)
            {
                if (pcListSorted.Count > 0)
                {
                    serviceCategory.ProductCategoryID = pcListSorted[0].ID;
                }
            }
            if (pcList.Count > 0)
            {
                serviceCategory.MaxSequnceNumber = pcList.Count;
            }
            ViewData["mode"] = mode;
            ViewData["programId"] = programId;
            return PartialView(serviceCategory);
        }

        /// <summary>
        /// Saves the service category information.
        /// </summary>
        /// <param name="serviceCategory">The service category.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _SaveServiceCategoryInformation(ProgramManagementProgramServiceCategory_Result serviceCategory)
        {
            OperationResult result = new OperationResult();
            logger.Info("Inside _SaveServiceCategoryInformation() of ProgramManagementController");
            facade.SaveServiceCategoryInformation(serviceCategory);
            logger.Info("Saved Program Service Category successfully");
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        /// <summary>
        /// Deletes the service category information.
        /// </summary>
        /// <param name="programServiceCategoryId">The program service category identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _DeleteServiceCategoryInformation(int? programServiceCategoryId)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside _DeleteServiceCategoryInformation() of ProgramManagementController with ID : {0}", programServiceCategoryId);
            facade.DeleteServiceCategoryInformation(programServiceCategoryId.GetValueOrDefault());
            logger.Info("Deleted Program Service Category successfully");
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }
        #endregion

        #region Program VehicleTypes Region
        /// <summary>
        /// Gets the program vehicle types.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <param name="pageMode">The page mode.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult _ProgramVehicleTypes(int programID, string pageMode)
        {
            logger.InfoFormat("Trying to retrieve Program Vehicle Types for Program ID {0}", programID);
            ViewData["mode"] = pageMode;
            return PartialView(programID);
        }

        /// <summary>
        /// Gets the program management vehicle types list.
        /// </summary>
        /// <param name="request">The request.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        public ActionResult _GetProgramManagementVehicleTypesList([DataSourceRequest] DataSourceRequest request, int? programID)
        {
            logger.Info("Inside _GetProgramManagementVehicleTypesList of ProgramManagementController. Attempt to get all vehicle types List depending upon the GridCommand");
            GridUtil gridUtil = new GridUtil();
            string sortColumn = "";
            string sortOrder = "";
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
            List<ProgramManagementVehicleTypesList_Result> list = facade.GetProgramVehicleTypesList(pageCriteria, programID.GetValueOrDefault());

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
        /// Gets the type of the program vehicle.
        /// </summary>
        /// <param name="programVehicleTypeId">The program vehicle type identifier.</param>
        /// <param name="mode">The mode.</param>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        [DMSAuthorize]
        [NoCache]
        public ActionResult GetProgramVehicleType(int? programVehicleTypeId, string mode, int? programId)
        {
            ProgramVehicleType vehicleType = new ProgramVehicleType();
            ProgramManagementFacade facade = new ProgramManagementFacade();
            if (programVehicleTypeId.HasValue)
            {
                vehicleType = facade.GetProgramVehicleTypeDetails(programVehicleTypeId.Value, programId.Value);
            }
            if (mode.ToLower() == "edit")
            {
                vehicleType.ID = programVehicleTypeId.Value;
            }
            List<DistinctVehicleTypesforProgram_Result> list = facade.GetDistinctVehicleTypes(programId.Value, programVehicleTypeId);
            ViewData[StaticData.VehicleType.ToString()] = list.ToSelectListItem<DistinctVehicleTypesforProgram_Result>(x => x.ID.ToString(), y => y.Descipriton, true);
            ViewData["mode"] = mode;
            ViewData["programId"] = programId;
            return PartialView("_ProgramVehicleTypeInformation", vehicleType);
        }

        /// <summary>
        /// Saves the type of the program vehicle.
        /// </summary>
        /// <param name="vehicleType">Type of the vehicle.</param>
        /// <param name="pagemode">The pagemode.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _SaveProgramVehicleType(ProgramVehicleType vehicleType, string pagemode)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside _SaveProgramVehicleType() of ProgramManagementController with mode {0}", pagemode);
            bool isadd = (pagemode.ToLower() == "add") ? true : false;
            facade.SaveProgramVehicleType(vehicleType, isadd, LoggedInUserName, DateTime.Now);
            logger.Info("Saved Program Vehicle Type successfully");
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }

        /// <summary>
        /// Deletes the type of the vehicle.
        /// </summary>
        /// <param name="vehicleTypeId">The vehicle type identifier.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult _DeleteVehicleType(int? vehicleTypeId)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Inside _DeleteVehicleType() of ProgramManagementController with ID : {0}", vehicleTypeId);
            facade.DeleteProgramVehicleType(vehicleTypeId.GetValueOrDefault());
            logger.Info("Deleted Vehicle Type successfully");
            result.OperationType = "Success";
            result.Status = OperationStatus.SUCCESS;
            return Json(result);
        }
        #endregion
        #endregion
    }
}
