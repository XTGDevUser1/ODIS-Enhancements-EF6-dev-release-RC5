using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DMSBaseException;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace ODISAPI.Controllers
{
    public class BaseApiController : ApiController
    {
        public const string REQUEST = "Request";
        public const string RESPONSE = "Response";
        
        EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();

        public string AuthenticatedUserName
        {
            get
            {
                return (User.Identity as System.Security.Claims.ClaimsIdentity).Claims.Where(a => a.Type.Equals("username")).Select(a => a.Value).FirstOrDefault();// UserName();
            }
        }

        /// <summary>
        /// Logs the API event.
        /// </summary>        
        /// <param name="eventName">Name of the event.</param>
        /// <param name="data">The data.</param>
        /// <param name="relatedEntityName">Name of the related entity.</param>
        /// <param name="relatedEntityID">The related entity identifier.</param>
        protected void LogAPIEvent(string eventName, object data, string relatedEntityName = null, int? relatedEntityID = null)
        {
            string source = string.Format("{0} {1}", Request.RequestUri.AbsolutePath, Request.Method);
            Dictionary<string, string> eventLogData = new Dictionary<string, string>();
            eventLogData.Add(eventName.EndsWith("BEGIN")? REQUEST : RESPONSE, JsonConvert.SerializeObject(data));
            var eventLogID = eventLoggerFacade.LogEvent(source, eventName, eventLogData, AuthenticatedUserName, null);
            if (relatedEntityID != null)
            {
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, relatedEntityID, relatedEntityName);
            }

        }

        /// <summary>
        /// Throws the exception if null.
        /// </summary>
        /// <param name="o">The o.</param>
        /// <param name="message">The message.</param>
        /// <exception cref="DMSException"></exception>
        protected void ThrowExceptionIfNull(object o, string message)
        {
            if (o == null)
            {
                throw new DMSException(message);
            }
        }
    }
}
