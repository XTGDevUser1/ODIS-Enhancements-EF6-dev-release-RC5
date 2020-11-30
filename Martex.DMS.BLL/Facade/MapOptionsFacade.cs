using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade Manages Map Options
    /// </summary>
    public class MapOptionsFacade
    {
        #region Public Methods
        
        /// <summary>
        /// Gets the business options.
        /// </summary>
        /// <param name="vehicleTypeId">The vehicle type id.</param>
        /// <returns></returns>
        public List<string> GetBusinessOptions(int? vehicleTypeId)
        {
            var repository = new OptionsRepository();
            var options = repository.GetBusinessOptions(vehicleTypeId);
            return options;
        }

        /// <summary>
        /// Gets the service location options.
        /// </summary>
        /// <returns></returns>
        public List<ServiceLocationOption> GetServiceLocationOptions()
        {
            var repository = new OptionsRepository();
            var options = repository.GetServiceLocationOptions();
            return options;
        }
        #endregion
    }
}
