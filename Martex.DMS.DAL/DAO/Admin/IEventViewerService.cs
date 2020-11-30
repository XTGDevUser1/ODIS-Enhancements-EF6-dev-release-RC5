using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO.Admin
{
    public interface IEventViewerService
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="criteria"></param>
        /// <param name="loggedInUserName"></param>
        /// <returns></returns>
        List<EventLogList_Result> List(PageCriteria criteria, string loggedInUserName);
    }
}
