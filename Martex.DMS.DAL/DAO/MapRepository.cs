using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class MapRepository
    {
        /// <summary>
        /// Gets the service facilities.
        /// </summary>
        /// <param name="serviceLocationLatitude">The service location latitude.</param>
        /// <param name="serviceLocationLongitude">The service location longitude.</param>
        /// <param name="productList">The product list.</param>
        /// <param name="searchRadiusMiles">The search radius miles.</param>
        /// <returns></returns>
        public List<GetServiceFacilitySelection_Result> GetServiceFacilities(int? programID, decimal serviceLocationLatitude, decimal serviceLocationLongitude, string productList, int searchRadiusMiles)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetServiceFacilitySelection(programID, serviceLocationLatitude, serviceLocationLongitude, productList, searchRadiusMiles).ToList();
            }
        }

        
    }
}
