using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Manage Phone System Configuration
    /// </summary>
    public class PhoneSystemConfigurationFacade
    {
        #region Public Methods
        /// <summary>
        /// Lists the specified page criteria.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="userId">The user id.</param>
        /// <returns></returns>
        public List<PhoneSystemConfigurationList> List(PageCriteria pageCriteria,Guid? userId)
        {
            return new PhoneSystemConfigurationRepository().GetAllFor(pageCriteria, userId);
        }

        /// <summary>
        /// Gets the specified phone system configuration id.
        /// </summary>
        /// <param name="phoneSystemConfigurationId">The phone system configuration id.</param>
        /// <returns></returns>
        public PhoneSystemConfiguration Get(int phoneSystemConfigurationId)
        {
            return new PhoneSystemConfigurationRepository().Get(phoneSystemConfigurationId);
        }

        /// <summary>
        /// Deletes the specified phone system configuration id.
        /// </summary>
        /// <param name="phoneSystemConfigurationId">The phone system configuration id.</param>
        public void Delete(int phoneSystemConfigurationId)
        {
            new PhoneSystemConfigurationRepository().Delete(phoneSystemConfigurationId);
        }

        /// <summary>
        /// Adds the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        public void Add(PhoneSystemConfiguration model)
        {
            new PhoneSystemConfigurationRepository().Add(model);
        }

        /// <summary>
        /// Updates the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        public void Update(PhoneSystemConfiguration model)
        {
            new PhoneSystemConfigurationRepository().Update(model);
        }

        /// <summary>
        /// Gets the name of the program.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public string GetProgramName(int programId)
        {
            return new PhoneSystemConfigurationRepository().GetProgramName(programId);
        }

        public string GetParentProgramName(int programId)
        {
            return new PhoneSystemConfigurationRepository().GetParentProgramName(programId);
        }
        #endregion
        
    }
}
