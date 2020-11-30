using log4net;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DMSBaseException;
using Newtonsoft.Json;
using ODIS.Closedloop.API.ActionFilters;
using ODIS.Closedloop.API.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace ODIS.Closedloop.API.Controllers
{
    [HeaderValidatorFilter]
    [RoutePrefix("api/closeloop")]
    public class CloseLoopController : ApiController
    {
        protected static ILog logger = LogManager.GetLogger(typeof(CloseLoopController));

        [HttpPost]
        [Route("")]
        public OperationResult UpdateClosedloopStatus([FromBody] ClosedloopCallResult closedLoopCallResult)
        {
            var result = new OperationResult();

            logger.InfoFormat("Start Executing ClosedLoopResultsService with parameters :: {0}", JsonConvert.SerializeObject(closedLoopCallResult));

            ValidateInput(closedLoopCallResult);

            var facade = new ClosedLoopFacade();
            result.Data = facade.UpdateClosedLoopCallResults(closedLoopCallResult.ServiceStatus, closedLoopCallResult.ServiceStatus, closedLoopCallResult.ODISUniqueID);

            logger.Info("Finished executon of ClosedLoopResultsService.");


            return result;
        }

        private void ValidateInput(ClosedloopCallResult closedLoopCallResult)
        {
            if(string.IsNullOrWhiteSpace(closedLoopCallResult.ODISUniqueID))
            {
                throw new ArgumentException("Missing value for ODISUniqueID");
            }

            if(string.IsNullOrWhiteSpace(closedLoopCallResult.ServiceStatus))
            {
                throw new ArgumentException("Missing value for Service Status");
            }
        }
    }
}
