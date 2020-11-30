using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Text;
using Martex.DMS.BLL.Facade;
using log4net;
using log4net.Config;

namespace ClosedLoopResultsService
{
    // NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "Service1" in code, svc and config file together.
    public class ClosedLoopResultsService : IClosedLoopResultsService
    {
        protected static ILog logger = LogManager.GetLogger(typeof(ClosedLoopResultsService));
        public bool UpdateClosedLoopCallResults(string callStatus, string serviceStatus, string entryID)
        {
            logger.Info("Start Executing ClosedLoopResultsService");
            ClosedLoopFacade facade = new ClosedLoopFacade();
            if (facade.UpdateClosedLoopCallResults(callStatus, serviceStatus, entryID))
            {
                logger.Info("Finished executon of ClosedLoopResultsService Successfully.");
                return true;
            }
            else
            {
                logger.Info("Finished executon of ClosedLoopResultsService Failed.");
                return false;
            }

        }

    }
}
