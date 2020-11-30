using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class DispatchRepository
    {
        /// <summary>
        /// Gets the dispatch processing list.
        /// </summary>
        /// <returns></returns>
        public List<DispatchProcessingList_Result> GetDispatchProcessingList()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetDispatchProcessingList().ToList();
            }
        }
        /// <summary>
        /// Gets the IS ps.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="actualServiceMiles">The actual service miles.</param>
        /// <param name="vehicleTypeID">The vehicle type ID.</param>
        /// <param name="vehicleCategoryID">The vehicle category ID.</param>
        /// <param name="searchRadiusMiles">The search radius miles.</param>
        /// <param name="adminWeight">The admin weight.</param>
        /// <param name="performanceWeight">The performance weight.</param>
        /// <param name="costWeight">The cost weight.</param>
        /// <param name="includeDoNotUse">if set to <c>true</c> [include do not use].</param>
        /// <param name="searchFrom">The search from.</param>
        /// <param name="showCalled">if set to <c>true</c> [show called].</param>
        /// <param name="showNotCalled">if set to <c>true</c> [show not called].</param>
        /// <param name="productIDs">The product I ds.</param>
        /// <returns></returns>
        public List<ISPs_Result> GetISPs(
            
            int serviceRequestID,
            decimal? actualServiceMiles,            
            int vehicleTypeID,
            int vehicleCategoryID,
            int searchRadiusMiles,
            decimal adminWeight,
            decimal performanceWeight,
            decimal costWeight,
            bool includeDoNotUse, 
            string searchFrom,
            bool showCalled = true,
            bool showNotCalled = false,
            string productIDs = null)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
               //showCalled,
               //showNotCalled
                var result = dbContext.GetISPs(
                    serviceRequestID,
                    actualServiceMiles,                    
                    vehicleTypeID,
                    vehicleCategoryID,
                    searchRadiusMiles,
                    adminWeight,
                    performanceWeight,
                    costWeight,
                    includeDoNotUse,
                    searchFrom,
                    productIDs
                    ).ToList<ISPs_Result>();
                return result;

            }
        }
    }
}
