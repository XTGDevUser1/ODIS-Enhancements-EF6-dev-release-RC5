using log4net;
using Martex.DMS.BLL.Facade.EventProcessors;
using Martex.DMS.DAO;
using ODIS.API.Notification.Services.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;

namespace ODIS.API.Notification.Services.Controllers
{
    [RoutePrefix("api/EventLogs")]
    public class EventLogsController : ApiController
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(EventLogsController));

        [Route("{eventLogId}/Process")]
        [HttpGet]
        public async Task<OperationResult> Process(long eventLogId)
        {
            logger.InfoFormat("START : Processing EventLog ID = {0}", eventLogId);
            var eventSubscriptionRepository = new EventSubscriptionRepository();
            var eventLogRepository = new EventLogRepository();
            var log = eventLogRepository.Get<long>(eventLogId);
            try
            {
                var eventSubscriptionRecipients = eventSubscriptionRepository.GetRecipients(eventLogId);
                logger.InfoFormat("Retrieved {0} subscription Recipients for eventlog ID {1} ", eventSubscriptionRecipients.Count, eventLogId);

                eventSubscriptionRecipients.ForEach(x =>
                  {
                      IEventProcessor eventProcessor = new DefaultEventProcessor();
                      eventProcessor.ProcessEventLog(log, x);
                  });
            }
            catch (Exception ex)
            {
                logger.WarnFormat("Error while processing EventLogID - {0} , {1}", eventLogId, ex.ToString());
                //Reset NotificationQueueDate.
                eventLogRepository.ResetQueueDate(log);
            }

            logger.InfoFormat("STOP : Processing EventLog ID = {0}", eventLogId);
            return new OperationResult() { Data = eventLogId };
        }
    }
}