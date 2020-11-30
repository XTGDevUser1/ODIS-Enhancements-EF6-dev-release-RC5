using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;
using log4net;
using System.Transactions;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class ActivityFacade
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ActivityFacade));

        /// <summary>
        /// Lists the specified service request ID.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<dms_activity_list_Result> List(int? serviceRequestID, PageCriteria pc)
        {
            ActivityRepository repository = new ActivityRepository();
            return repository.Search(serviceRequestID, pc);
        }

        /// <summary>
        /// Logs the activity.
        /// </summary>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="eventName">Name of the event.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <exception cref="DMSException">Invalid event name :  + eventName</exception>
        public void LogActivity(int serviceRequestId, string loggedInUserName)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                try
                {
                    // 1. Update service request to set ActivityTabStatus = 1
                    var serviceRequestRepository = new ServiceRequestRepository();
                    serviceRequestRepository.UpdateTabStatus(serviceRequestId,TabConstants.ActivityTab ,loggedInUserName);
                    logger.Info("Updated activity tab status on service request");
                    tran.Complete();
                }
                catch (Exception)
                {
                    throw;
                }
            }

        }
    }
}
