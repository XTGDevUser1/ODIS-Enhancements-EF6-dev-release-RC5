using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Maintain Program Maintenance
    /// </summary>
    public class ProgramMaintenanceFacade
    {
        #region Public Methods
        /// <summary>
        /// Gets the mobile configuration result.
        /// </summary>
        /// <param name="programID">The program ID.</param>
        /// <param name="configurationType">Type of the configuration.</param>
        /// <param name="configurationCategory">The configuration category.</param>
        /// <param name="callbackNumber">The callback number.</param>
        /// <param name="inboundCallID">The inbound call ID.</param>
        /// <returns></returns>
        public List<MobileCallData_Result> GetMobileConfigurationResult(int programID, string configurationType, string configurationCategory, string callbackNumber, int inboundCallID, int? selectedMemberID, int? selectedMembershipID)
        {
            return new ProgramMaintenanceRepository().GetMobileConfigurationResult(programID, configurationType, configurationCategory, callbackNumber, inboundCallID, selectedMemberID, selectedMembershipID);
        }

        /// <summary>
        /// Lists the specified page criteria.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="userId">The user id.</param>
        /// <returns></returns>
        public List<Programs_List_Results> List(PageCriteria pageCriteria, Guid userId)
        {
            return new ProgramMaintenanceRepository().GetAllFor(pageCriteria, userId);
        }

        /// <summary>
        /// Gets the specified program id.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public Program Get(int programId)
        {
            return new ProgramMaintenanceRepository().Get(programId);
        }

        /// <summary>
        /// Adds the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        public void Add(Program model)
        {
            new ProgramMaintenanceRepository().Add(model);
        }

        /// <summary>
        /// Updates the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        public void Update(Program model)
        {
            new ProgramMaintenanceRepository().Update(model);
        }

        /// <summary>
        /// Deletes the specified program id.
        /// </summary>
        /// <param name="programId">The program id.</param>
        public void Delete(int programId)
        {
            new ProgramMaintenanceRepository().Delete(programId);
        }

        /// <summary>
        /// Gets the program info.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="configurationType">Type of the configuration.</param>
        /// <param name="configurationCategory">The configuration category.</param>
        /// <returns></returns>
        public List<ProgramInformation_Result> GetProgramInfo(int? programId, string configurationType, string configurationCategory)
        {
            return (new ProgramMaintenanceRepository()).GetProgramInfo(programId, configurationType, configurationCategory);
        }

        /// <summary>
        /// Gets the program services.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="productCategory">The product category.</param>
        /// <returns></returns>
        public List<ProgramServices_Result> GetProgramServices(int? programId, string productCategory)
        {
            return (new ProgramMaintenanceRepository()).GetProgramServices(programId, productCategory);
        }

        /// <summary>
        /// Gets the program dynamic fields.
        /// </summary>
        /// <param name="screenName">Name of the screen.</param>
        /// <param name="programID">The program ID.</param>
        /// <returns></returns>
        public List<DynamicFields> GetProgramDynamicFields(string screenName, int programID)
        {
            return (new ProgramMaintenanceRepository()).GetDynamicFields(screenName, programID);
        }
        #endregion
    }
}
