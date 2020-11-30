using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using log4net;

namespace Martex.DMS.BLL.Facade
{
    public class ProgramManagementFacade
    {
        #region Private Methods
        private ProgramManagementRepository repository = new ProgramManagementRepository();
        #endregion

        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(MemberFacade));
        #endregion

        #region Public Methods
        /// <summary>
        /// Gets the program maintenance list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ProgramMaintainenceList_Result> GetProgramMaintenenceList(PageCriteria pc)
        {
            return repository.GetProgramMaintenenceList(pc);
        }

        /// <summary>
        /// Gets the program management list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ProgramManagement_List_Result> GetProgramManagementList(PageCriteria pc)
        {
            return repository.GetProgramManagementList(pc);
        }

        /// <summary>
        /// Gets the program configuration list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementProgramConfigurationList_Result> GetProgramConfigurationList(PageCriteria pc, int programID)
        {
            return repository.GetProgramConfigurationList(pc, programID);
        }

        /// <summary>
        /// Gets the program management information.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public ProgramManagementInformation_Result GetProgramManagementInformation(int programID)
        {
            return repository.GetProgramManagementInformation(programID);
        }

        /// <summary>
        /// Gets the program management services list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementServicesList_Result> GetProgramManagementServicesList(PageCriteria pc, int? programID)
        {
            return repository.GetProgramManagementServicesList(pc, programID);
        }

        /// <summary>
        /// Deletes the service information.
        /// </summary>
        /// <param name="programServiceId">The program service identifier.</param>
        public void DeleteServiceInformation(int programServiceId)
        {
            repository.DeleteServiceInformation(programServiceId);
        }

        /// <summary>
        /// Saves the program information data.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUserName">Name of the current user.</param>
        public void SaveProgramInfoData(ProgramManagementInformation_Result model, string currentUserName)
        {
            logger.Info("Updating Program Info");
            repository.UpdateProgramInfoData(model, currentUserName);
            logger.Info("Updated Program Info Successfully");
        }

        /// <summary>
        /// Saves the program configuration.
        /// </summary>
        /// <param name="configuration">The configuration.</param>
        /// <param name="isadd">if set to <c>true</c> [isadd].</param>
        /// <param name="user">The user.</param>
        /// <param name="modifiedon">The modifiedon.</param>
        public void SaveProgramConfiguration(ProgramConfiguration configuration, bool isadd, string user, DateTime modifiedon)
        {
            repository.SaveProgramConfiguration(configuration, isadd, user, modifiedon);
        }

        /// <summary>
        /// Gets the program configuration details.
        /// </summary>
        /// <param name="programConfigurationId">The program configuration identifier.</param>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        public ProgramConfiguration GetProgramConfigurationDetails(int programConfigurationId, int programId)
        {
            return repository.GetProgramConfigurationDetails(programConfigurationId, programId);
        }

        /// <summary>
        /// Gets the program management program service category.
        /// </summary>
        /// <param name="programConfigurationId">The program configuration identifier.</param>
        /// <returns></returns>
        public ProgramManagementProgramServiceCategory_Result GetProgramManagementProgramServiceCategory(int programConfigurationId)
        {
            return repository.GetProgramManagementProgramServiceCategory(programConfigurationId);
        }

        /// <summary>
        /// Gets the program management service categories list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementServiceCategoriesList_Result> GetProgramManagementServiceCategoriesList(PageCriteria pc, int? programID)
        {
            return repository.GetProgramManagementServiceCategoriesList(pc, programID);
        }

        /// <summary>
        /// Saves the service category information.
        /// </summary>
        /// <param name="serviceCategory">The service category.</param>
        /// <param name="user">The user.</param>
        public void SaveServiceCategoryInformation(ProgramManagementProgramServiceCategory_Result serviceCategory)
        {
            repository.SaveServiceCategoryInformation(serviceCategory);
        }

        /// <summary>
        /// Deletes the service category information.
        /// </summary>
        /// <param name="programServiceCategoryId">The program service category identifier.</param>
        public void DeleteServiceCategoryInformation(int programServiceCategoryId)
        {
            repository.DeleteServiceCategoryInformation(programServiceCategoryId);
        }

        /// <summary>
        /// Gets the program vehicle types list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementVehicleTypesList_Result> GetProgramVehicleTypesList(PageCriteria pc, int programID)
        {
            return repository.GetProgramVehicleTypesList(pc, programID);
        }

        /// <summary>
        /// Gets the program vehicle type details.
        /// </summary>
        /// <param name="programVehicleTypeId">The program vehicle type identifier.</param>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        public ProgramVehicleType GetProgramVehicleTypeDetails(int programVehicleTypeId, int programId)
        {
            return repository.GetProgramVehicleTypeDetails(programVehicleTypeId, programId);
        }

        /// <summary>
        /// Saves the type of the program vehicle.
        /// </summary>
        /// <param name="vehicletype">The vehicletype.</param>
        /// <param name="isadd">if set to <c>true</c> [isadd].</param>
        /// <param name="user">The user.</param>
        /// <param name="modifiedon">The modifiedon.</param>
        public void SaveProgramVehicleType(ProgramVehicleType vehicletype, bool isadd, string user, DateTime modifiedon)
        {
            repository.SaveProgramVehicleType(vehicletype, isadd, user, modifiedon);
        }

        /// <summary>
        /// Deletes the type of the program vehicle.
        /// </summary>
        /// <param name="programVehicleTypeId">The program vehicle type identifier.</param>
        public void DeleteProgramVehicleType(int programVehicleTypeId)
        {
            repository.DeleteProgramVehicleType(programVehicleTypeId);
        }

        /// <summary>
        /// Deletes the program configuration.
        /// </summary>
        /// <param name="programConfigurationId">The program configuration identifier.</param>
        public void DeleteProgramConfiguration(int programConfigurationId)
        {
            repository.DeleteProgramConfiguration(programConfigurationId);
        }

        /// <summary>
        /// Gets the phone system configuration.
        /// </summary>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        public PhoneSystemConfiguration GetPhoneSystemConfiguration(int programId)
        {
            return repository.GetPhoneSystemConfiguration(programId);
        }

        /// <summary>
        /// Saves the program phone system configuration information data.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveProgramPhoneSystemConfigurationInfoData(PhoneSystemConfiguration model, string currentUser)
        {
            logger.Info("Updating Program Phone System Configuration Info");
            repository.SaveProgramPhoneSystemConfigurationInfoData(model, currentUser);
            logger.Info("Updated Program Phone System Configuration Info Successfully");
        }

        /// <summary>
        /// Gets the program management program data item list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementProgramDataItemList_Result> GetProgramManagementProgramDataItemList(PageCriteria pc, int? programID)
        {
            return repository.GetProgramManagementProgramDataItemList(pc, programID);
        }

        /// <summary>
        /// Gets the program data item details.
        /// </summary>
        /// <param name="programDataItemID">The program data item identifier.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public ProgramDataItem GetProgramDataItemDetails(int programDataItemID, int programID)
        {
            return repository.GetProgramDataItemDetails(programDataItemID);
        }

        /// <summary>
        /// Saves the data item information.
        /// </summary>
        /// <param name="pdi">The pdi.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveDataItemInformation(ProgramDataItem pdi, string currentUser)
        {
            repository.SaveDataItemInformation(pdi, currentUser);
        }

        /// <summary>
        /// Deletes the data item information.
        /// </summary>
        /// <param name="programDataItemID">The program data item identifier.</param>
        public void DeleteDataItemInformation(int programDataItemID)
        {
            repository.DeleteDataItemInformation(programDataItemID);
        }

        /// <summary>
        /// Gets the distinct vehicle types.
        /// </summary>
        /// <param name="programId">The program identifier.</param>
        /// <param name="programVehicleTypeId">The program vehicle type identifier.</param>
        /// <returns></returns>
        public List<DistinctVehicleTypesforProgram_Result> GetDistinctVehicleTypes(int programId,int? programVehicleTypeId)
        {
            return repository.GetDistinctVehicleTypes(programId, programVehicleTypeId);
        }

        /// <summary>
        /// Gets the program management program service event limit list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ProgramManagementProgramServiceEventLimitList_Result> GetProgramManagementProgramServiceEventLimitList(PageCriteria pc, int programID)
        {
            return repository.GetProgramManagementProgramServiceEventLimitList(pc,programID);
        }


        /// <summary>
        /// Deletes the service event limit information.
        /// </summary>
        /// <param name="serviceEventLimitID">The service event limit identifier.</param>
        public void DeleteServiceEventLimitInformation(int serviceEventLimitID)
        {
            repository.DeleteServiceEventLimitInformation(serviceEventLimitID);
        }

        /// <summary>
        /// Saves the program management service event limit information.
        /// </summary>
        /// <param name="psel">The psel.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveProgramManagementServiceEventLimitInformation(ProgramServiceEventLimit psel, string currentUser)
        {
            repository.SaveProgramManagementServiceEventLimitInformation(psel, currentUser);
        }

        /// <summary>
        /// Gets the program management service event limit information.
        /// </summary>
        /// <param name="pselId">The psel identifier.</param>
        /// <returns></returns>
        public ProgramServiceEventLimit GetProgramManagementServiceEventLimitInformation(int pselId)
        {
            return repository.GetProgramManagementServiceEventLimitInformation(pselId);
        }
        #endregion

        
    }
}
