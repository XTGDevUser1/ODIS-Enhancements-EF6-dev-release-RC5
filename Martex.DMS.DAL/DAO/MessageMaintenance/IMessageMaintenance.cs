using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO.MessageMaintenance
{
    /// <summary>
    /// 
    /// </summary>
    public interface IMessageMaintenance
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="criteria"></param>
        /// <returns></returns>
        List<MessageList_Result> MessageList(PageCriteria criteria);
        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="createIfNotExists"></param>
        /// <returns></returns>
        Message Get(int recordID, bool createIfNotExists = false);

        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <param name="LoggedInUserName"></param>
        void SaveMessageDetails(Message model, string LoggedInUserName);

        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="LoggedInUserName"></param>
        void DeleteMessage(int recordID, string LoggedInUserName);
    }
}
