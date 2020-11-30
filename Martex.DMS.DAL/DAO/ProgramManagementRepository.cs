using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    public class ProgramManagementRepository
    {
        /// <summary>
        /// Gets the program maintenance list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ProgramMaintainenceList_Result> GetProgramMaintenenceList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramMaintainenceList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<ProgramMaintainenceList_Result>();
            }
        }

        /// <summary>
        /// Gets the program management list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ProgramManagement_List_Result> GetProgramManagementList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagement_List(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<ProgramManagement_List_Result>();
            }
        }
        /// <summary>
        /// Gets the program configuration list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementProgramConfigurationList_Result> GetProgramConfigurationList(PageCriteria pc, int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagementProgramConfigurationList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, programID).ToList<ProgramManagementProgramConfigurationList_Result>();
            }
        }
        /// <summary>
        /// Gets the program management information.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public ProgramManagementInformation_Result GetProgramManagementInformation(int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagementInformation(programID).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the program management services list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementServicesList_Result> GetProgramManagementServicesList(PageCriteria pc, int? programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagementServicesList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, programID).ToList<ProgramManagementServicesList_Result>();
            }
        }

        /// <summary>
        /// Updates the program information data.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUserName">Name of the current user.</param>
        public void UpdateProgramInfoData(ProgramManagementInformation_Result model, string currentUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveProgramManagementInformation(model.ProgramID, model.ParentID, model.ProgramName, model.ProgramDescription, model.Code, model.IsActive, model.IsAudited, model.IsGroup, model.IsServiceGuaranteed, model.IsWebRegistrationEnabled, currentUserName);
            }
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
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveProgramConfiguration(configuration.ID, configuration.ConfigurationTypeID, configuration.ConfigurationCategoryID, configuration.ControlTypeID, configuration.DataTypeID, configuration.Name, configuration.Value, configuration.Sequence, user, modifiedon, isadd, configuration.ProgramID);
            }
        }

        /// <summary>
        /// Gets the program configuration details.
        /// </summary>
        /// <param name="programConfigurationId">The program configuration identifier.</param>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        public ProgramConfiguration GetProgramConfigurationDetails(int programConfigurationId, int programId)
        {
            ProgramConfiguration configuration = new ProgramConfiguration();
            using (DMSEntities dbContext = new DMSEntities())
            {
                ProgramConfigurationDetails_Result result = dbContext.GetProgramConfigurationDetails(programConfigurationId).ToList<ProgramConfigurationDetails_Result>()[0];
                if (result != null)
                {
                    configuration.ID = programConfigurationId;
                    configuration.ConfigurationTypeID = result.ConfigurationTypeID;
                    configuration.ConfigurationCategoryID = result.ConfigurationCategoryID;
                    configuration.ControlTypeID = result.ControlTypeID;
                    configuration.DataTypeID = result.DataTypeID;
                    configuration.Name = result.Name;
                    configuration.Value = result.Value;
                    configuration.Sequence = result.Sequence;
                    configuration.CreateBy = result.CreateBy;
                    configuration.CreateDate = result.CreateDate;
                    configuration.ModifyBy = result.ModifyBy;
                    configuration.ModifyDate = result.ModifyDate;
                    configuration.ProgramID = programId;
                }
            }
            return configuration;
        }

        /// <summary>
        /// Gets the program management service categories list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementServiceCategoriesList_Result> GetProgramManagementServiceCategoriesList(PageCriteria pc, int? programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagementServiceCategoriesList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, programID).ToList<ProgramManagementServiceCategoriesList_Result>();
            }
        }

        /// <summary>
        /// Gets the program management program service category.
        /// </summary>
        /// <param name="programServiceCategoryId">The program service category identifier.</param>
        /// <returns></returns>
        public ProgramManagementProgramServiceCategory_Result GetProgramManagementProgramServiceCategory(int programServiceCategoryId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagementProgramServiceCategory(programServiceCategoryId).FirstOrDefault();
            }
        }

        /// <summary>
        /// Saves the service category information.
        /// </summary>
        /// <param name="serviceCategory">The service category.</param>
        public void SaveServiceCategoryInformation(ProgramManagementProgramServiceCategory_Result serviceCategory)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveProgramManagementServiceCategoryInformation(serviceCategory.ID, serviceCategory.ProgramID, serviceCategory.ProductCategoryID, serviceCategory.VehicleTypeID, serviceCategory.VehicleCategoryID, serviceCategory.Sequence, serviceCategory.IsActive);
            }
        }

        /// <summary>
        /// Deletes the service category information.
        /// </summary>
        /// <param name="programServiceCategoryId">The program service category identifier.</param>
        public void DeleteServiceCategoryInformation(int programServiceCategoryId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.DeleteProgramManagementServiceCategoryInformation(programServiceCategoryId);
            }
        }

        /// <summary>
        /// Deletes the service information.
        /// </summary>
        /// <param name="programServiceId">The program service identifier.</param>
        public void DeleteServiceInformation(int programServiceId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.DeleteProgramManagementServiceInformation(programServiceId);
            }
        }

        /// <summary>
        /// Gets the program vehicle types list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementVehicleTypesList_Result> GetProgramVehicleTypesList(PageCriteria pc, int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagementVehicleTypes(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, programID).ToList<ProgramManagementVehicleTypesList_Result>();
            }
        }

        /// <summary>
        /// Gets the program vehicle type details.
        /// </summary>
        /// <param name="programVehicleTypeId">The program vehicle type identifier.</param>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        public ProgramVehicleType GetProgramVehicleTypeDetails(int programVehicleTypeId, int programId)
        {
            ProgramVehicleType vehicleType = new ProgramVehicleType();
            using (DMSEntities dbContext = new DMSEntities())
            {
                ProgramVehicleTypeDetails_Result result = dbContext.GetProgramVehicleTypeDetails(programVehicleTypeId).ToList<ProgramVehicleTypeDetails_Result>()[0];
                if (result != null)
                {
                    vehicleType.ID = result.ID;
                    vehicleType.ProgramID = programId;
                    vehicleType.IsActive = result.IsActive;
                    vehicleType.MaxAllowed = result.MaxAllowed;
                    vehicleType.VehicleTypeID = result.VehicleTypeID;
                }
            }
            return vehicleType;
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
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveProgramVehicleType(vehicletype.ID, vehicletype.VehicleTypeID, vehicletype.MaxAllowed, vehicletype.IsActive, isadd, vehicletype.ProgramID);
            }
        }

        /// <summary>
        /// Deletes the type of the program vehicle.
        /// </summary>
        /// <param name="programVehicleTypeId">The program vehicle type identifier.</param>
        public void DeleteProgramVehicleType(int programVehicleTypeId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.DeleteProgramVehcileType(programVehicleTypeId);
            }
        }

        /// <summary>
        /// Deletes the program configuration.
        /// </summary>
        /// <param name="programConfigurationId">The program configuration identifier.</param>
        public void DeleteProgramConfiguration(int programConfigurationId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.DeleteProgramConfiguration(programConfigurationId);
            }
        }


        /// <summary>
        /// Gets the phone system configuration.
        /// </summary>
        /// <param name="programId">The program identifier.</param>
        /// <returns></returns>
        public PhoneSystemConfiguration GetPhoneSystemConfiguration(int programId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var results = dbContext.PhoneSystemConfigurations.Where(a => a.ProgramID == programId).FirstOrDefault();
                return results;
            }
        }

        /// <summary>
        /// Saves the program phone system configuration information data.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveProgramPhoneSystemConfigurationInfoData(PhoneSystemConfiguration model, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveProgramPhoneSystemConfigurationInfoData(model.ID, model.IVRScriptID, model.SkillsetID, model.InboundPhoneCompanyID, model.InboundNumber, model.PilotNumber, model.IsShownOnScreen, model.IsActive, model.ProgramID, currentUser);
            }
        }

        /// <summary>
        /// Gets the program management program data item list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public List<ProgramManagementProgramDataItemList_Result> GetProgramManagementProgramDataItemList(PageCriteria pc, int? programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagementProgramDataItemList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, programID).ToList<ProgramManagementProgramDataItemList_Result>();
            }
        }

        /// <summary>
        /// Gets the program data item details.
        /// </summary>
        /// <param name="programDataItemID">The program data item identifier.</param>
        /// <returns></returns>
        public ProgramDataItem GetProgramDataItemDetails(int programDataItemID)
        {
            ProgramDataItem pdi = new ProgramDataItem();
            using (DMSEntities dbContext = new DMSEntities())
            {
                pdi = dbContext.ProgramDataItems.Where(a => a.ID == programDataItemID).FirstOrDefault();
            }
            return pdi;
        }

        /// <summary>
        /// Saves the data item information.
        /// </summary>
        /// <param name="pdi">The pdi.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveDataItemInformation(ProgramDataItem pdi, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ProgramManagementSaveDataItemInformation(pdi.ID, pdi.ProgramID, pdi.ControlTypeID, pdi.DataTypeID, pdi.Name, pdi.ScreenName, pdi.Label, pdi.MaxLength, pdi.Sequence, pdi.IsRequired, pdi.IsActive, currentUser);
            }
        }

        /// <summary>
        /// Deletes the data item information.
        /// </summary>
        /// <param name="programDataItemID">The program data item identifier.</param>
        public void DeleteDataItemInformation(int programDataItemID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ProgramManagementDeleteDataItem(programDataItemID);
            }
        }

        /// <summary>
        /// Gets the distinct vehicle types.
        /// </summary>
        /// <param name="programId">The program identifier.</param>
        /// <param name="programVehicleTypeId">The program vehicle type identifier.</param>
        /// <returns></returns>
        public List<DistinctVehicleTypesforProgram_Result> GetDistinctVehicleTypes(int programId, int? programVehicleTypeId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetDistinctVehicleTypesforProgram(programId, programVehicleTypeId).ToList<DistinctVehicleTypesforProgram_Result>();
            }
        }

        /// <summary>
        /// Gets the program management program service event limit list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<ProgramManagementProgramServiceEventLimitList_Result> GetProgramManagementProgramServiceEventLimitList(PageCriteria pc, int programID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetProgramManagementProgramServiceEventLimitList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, programID).ToList<ProgramManagementProgramServiceEventLimitList_Result>();
            }
        }

        /// <summary>
        /// Deletes the service event limit information.
        /// </summary>
        /// <param name="serviceEventLimitID">The service event limit identifier.</param>
        public void DeleteServiceEventLimitInformation(int serviceEventLimitID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ProgramManagementDeleteProgramServiceEventLimit(serviceEventLimitID);
            }
        }

        /// <summary>
        /// Saves the program management service event limit information.
        /// </summary>
        /// <param name="psel">The psel.</param>
        /// <param name="currentUser">The current user.</param>
        public void SaveProgramManagementServiceEventLimitInformation(ProgramServiceEventLimit psel, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.SaveProgramManagementServiceEventLimitInformation(psel.ID, psel.ProgramID, psel.ProductCategoryID, psel.ProductID, psel.VehicleTypeID, psel.VehicleCategoryID, psel.Description, psel.Limit, psel.LimitDuration, psel.LimitDurationUOM, psel.StoredProcedureName, currentUser, psel.IsActive);
            }
        }

        /// <summary>
        /// Gets the program management service event limit information.
        /// </summary>
        /// <param name="pselId">The psel identifier.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"> No Service Limit configured in db with id :  + pselId.ToString()</exception>
        public ProgramServiceEventLimit GetProgramManagementServiceEventLimitInformation(int pselId)
        {
            ProgramServiceEventLimit limit = new ProgramServiceEventLimit();
            using (DMSEntities dbContext = new DMSEntities())
            {
                limit = dbContext.ProgramServiceEventLimits.Where(a => a.ID == pselId).FirstOrDefault();
            }
            if (limit == null)
            {
                throw new DMSException(" No Service Limit configured in db with id : " + pselId.ToString());
            }
            return limit;
        }
    }
}
