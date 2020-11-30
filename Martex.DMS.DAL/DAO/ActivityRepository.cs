using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ActivityRepository
    {
        /// <summary>
        /// Searches the specified service request ID.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<dms_activity_list_Result> Search(int? serviceRequestID, PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetActivityList(serviceRequestID, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList();
            }
                
        }
    }
}
