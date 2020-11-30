using Microsoft.Owin.Security.OAuth;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using log4net;
using Newtonsoft.Json;

namespace ODISAPI
{
    public class ODISAuthorizationServerProvider : OAuthAuthorizationServerProvider
    {
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ODISAuthorizationServerProvider));

        public override async Task ValidateClientAuthentication(OAuthValidateClientAuthenticationContext context)
        {
            context.Validated();
        }

        public override async Task GrantResourceOwnerCredentials(OAuthGrantResourceOwnerCredentialsContext context)
        {
            //logger.InfoFormat("ODISAuthorizationServerProvider - GrantResourceOwnerCredentials(), Parameters : {0}", JsonConvert.SerializeObject(new
            //{
            //    context = context
            //}));
            context.OwinContext.Response.Headers.Add("Access-Control-Allow-Origin", new[] { "*" });
            if (!(System.Web.Security.Membership.ValidateUser(context.UserName, context.Password)))
            {
                context.SetError("invalid_grant", "The user name or password is incorrect.");
                return;
            }

            var identity = new ClaimsIdentity(context.Options.AuthenticationType);
            identity.AddClaim(new Claim("username", context.UserName));
            context.Validated(identity);
            //logger.InfoFormat("ODISAuthorizationServerProvider - GrantResourceOwnerCredentials(), Finished : {0}", JsonConvert.SerializeObject(new
            //{
            //    context = context
            //}));
        }
    }
}
