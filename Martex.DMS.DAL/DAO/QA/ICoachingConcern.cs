using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO.QA
{
    public interface ICoachingConcern
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="criteria"></param>
        /// <param name="loggedInUserName"></param>
        /// <returns></returns>
        List<CoachingConcerns_List_Result> List(PageCriteria criteria, string loggedInUserName);

        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="createIfNotExists"></param>
        /// <returns></returns>
        CoachingConcern Get(int recordID, bool createIfNotExists = false);
        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="LoggedInUserName"></param>
        void Delete(int recordID, string LoggedInUserName);
        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <param name="LoggedInUserName"></param>
        void SaveDetails(CoachingConcern model, string LoggedInUserName, string pageSource, string sessionID);
    }
}
