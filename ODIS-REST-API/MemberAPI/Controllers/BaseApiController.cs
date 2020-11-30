using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using Newtonsoft.Json;
using System.Configuration;
using System.Security.Claims;
using System.Threading;
using log4net;

namespace MemberAPI.Controllers
{
    public class BaseApiController : ApiController
    {
        public const string REQUEST = "Request";
        public const string RESPONSE = "Response";
        protected static ILog logger = LogManager.GetLogger(typeof(BaseApiController));

        public string AuthenticatedUserName
        {
            get
            {
                return (User.Identity as System.Security.Claims.ClaimsIdentity).Claims.Where(a => a.Type.Equals("username")).Select(a => a.Value).FirstOrDefault();// UserName();
            }
        }

        public int OrganizationID
        {
            get
            {
                int organizationId = -1;

                IEnumerable<string> apiKeyHeaderValues = null;
                
                string headerOrganizationId = null;

                Request.Headers.TryGetValues(StringConstants.ORGANIZATION_ID, out apiKeyHeaderValues);

                if (apiKeyHeaderValues != null)
                {
                    foreach (string key in apiKeyHeaderValues)
                    {
                        headerOrganizationId = key;
                    }
                }

                if (!string.IsNullOrEmpty(headerOrganizationId))
                {
                    int.TryParse(headerOrganizationId, out organizationId);
                }                             
                
                return organizationId;
            }
        }

        public string Claim_MemberNumber
        {
            get
            {
                // Access ClaimsIdentity which contains claims
                var claimsIdentity = (ClaimsPrincipal)Thread.CurrentPrincipal;
                return (from c in claimsIdentity.Claims
                        where c.Type == "membernumber"
                        select c.Value).Single();
            }
        }

        public string Claim_MemberShipNumber
        {
            get
            {
                // Access ClaimsIdentity which contains claims
                var claimsIdentity = (ClaimsPrincipal)Thread.CurrentPrincipal;
                return (from c in claimsIdentity.Claims
                        where c.Type == "membershipnumber"
                        select c.Value).Single();
            }
        }

        public int Claim_ProgramID
        {
            get
            {
                // Access ClaimsIdentity which contains claims
                var claimsIdentity = (ClaimsPrincipal)Thread.CurrentPrincipal;
                var sProgramID = (from c in claimsIdentity.Claims
                                  where c.Type == "ProgramID"
                                  select c.Value).Single();
                int programID = 0;
                int.TryParse(sProgramID, out programID);
                return programID;
            }
        }

        /// <summary>
        /// Logs the API event.
        /// </summary>        
        /// <param name="eventName">Name of the event.</param>
        /// <param name="data">The data.</param>
        /// <param name="relatedEntityName">Name of the related entity.</param>
        /// <param name="relatedEntityID">The related entity identifier.</param>
        protected void LogAPIEvent(object obj, bool isError = false)
        {
            if (isError)
            {
                logger.Error(string.Format("ERROR : {0}", Request.RequestUri.AbsolutePath), obj as Exception);
            }
            else
            {   
                //logger.InfoFormat("{0} - {1}", Request.RequestUri.AbsolutePath, JsonConvert.SerializeObject(obj));
                logger.InfoFormat("{0} - {1}", Request.RequestUri.AbsolutePath, JsonConvert.SerializeObject(obj, Formatting.Indented, new JsonSerializerSettings { PreserveReferencesHandling = PreserveReferencesHandling.Objects }));
            }
        }
    }
}
