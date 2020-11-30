using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO.Admin
{
    public class EventViewerService : IEventViewerService
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="criteria"></param>
        /// <param name="loggedInUserName"></param>
        /// <returns></returns>
        public List<EventLogList_Result> List(Common.PageCriteria criteria, string loggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetEventLogList(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection).ToList<EventLogList_Result>();
            }
        }
    }
}
