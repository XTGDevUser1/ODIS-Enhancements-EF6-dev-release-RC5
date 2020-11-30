using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Web;
using log4net;
using Microsoft.Owin.Security.OAuth;
using MemberAPI.Services;
using System.Configuration;
//using MemberAPI.DAL;
using Microsoft.Owin.Security;
using abo = Aptify.BusinessObjects;

namespace MemberAPI
{
    public class MemberAuthorizationServerProvider : OAuthAuthorizationServerProvider
    {

        protected readonly IMemberService _memberService = new PinnacleMemberService();

        public int GetOrganizationID(OAuthGrantResourceOwnerCredentialsContext context)
        {
            int organizationId = -1;

            string[] apiKeyHeaderValues = null;

            string headerOrganizationId = null;

            context.Request.Headers.TryGetValue(StringConstants.ORGANIZATION_ID, out apiKeyHeaderValues);

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
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(MemberAuthorizationServerProvider));

        public override async Task ValidateClientAuthentication(OAuthValidateClientAuthenticationContext context)
        {
            context.Validated();
        }

        public override async Task GrantResourceOwnerCredentials(OAuthGrantResourceOwnerCredentialsContext context)
        {
            context.OwinContext.Response.Headers.Add("Access-Control-Allow-Origin", new[] { "*" });
            int organizationID = GetOrganizationID(context);

            logger.InfoFormat("Organization ID for the context is {0}", organizationID);
            abo.MemberLogin loginResult = null;
            try
            {
                loginResult = _memberService.Login(organizationID, context.UserName, context.Password);
            }
            catch (MemberException mex)
            {
                context.SetError("invalid_grant", mex.Message);
                return;
            }

            var identity = new ClaimsIdentity(context.Options.AuthenticationType);
            identity.AddClaim(new Claim("username", context.UserName));
            identity.AddClaim(new Claim("membernumber", loginResult.MemberNumber));
            identity.AddClaim(new Claim("membershipnumber", loginResult.MembershipNumber));
            identity.AddClaim(new Claim("ProgramID", loginResult.ProgramID.ToString()));
            /*identity.AddClaim(new Claim("personid", loginResult.PersonID.GetValueOrDefault().ToString()));
            identity.AddClaim(new Claim("firstname", loginResult.FirstName));
            identity.AddClaim(new Claim("lastname", loginResult.LastName));*/

            var ticketProperties = new AuthenticationProperties();
            var additionalProperties = ticketProperties.Dictionary;
            additionalProperties.Add("MemberNumber", loginResult.MemberNumber);
            additionalProperties.Add("MembershipNumber", loginResult.MembershipNumber);
            additionalProperties.Add("FirstName", loginResult.FirstName);
            additionalProperties.Add("LastName", loginResult.LastName);
            additionalProperties.Add("PlanID", loginResult.PlanID.ToString());
            additionalProperties.Add("PlanName", loginResult.PlanName);
            additionalProperties.Add("ProductCode", loginResult.ProductCode);
            additionalProperties.Add("IsActive", loginResult.IsActive.ToString());
            additionalProperties.Add("MemberSinceDate", loginResult.MemberSinceDate != null ? loginResult.MemberSinceDate.ToString() : null);
            additionalProperties.Add("CurrentSubscriptionStartDate", loginResult.CurrentSubscriptionStartDate != null ? loginResult.CurrentSubscriptionStartDate.ToString() : null);
            additionalProperties.Add("CurrentSubscriptionExpirationDate", loginResult.CurrentSubscriptionExpirationDate != null ? loginResult.CurrentSubscriptionExpirationDate.ToString() : null);
            additionalProperties.Add("MasterPersonID", loginResult.MasterPersonID.ToString());
            additionalProperties.Add("MasterMemberNumber", loginResult.MasterMemberNumber);
            additionalProperties.Add("ProgramID", loginResult.ProgramID.ToString());
            additionalProperties.Add("IsMasterMember", loginResult.IsMasterMember.ToString());
            additionalProperties.Add("ContactMethod", loginResult.ContactMethod.ToString());
            additionalProperties.Add("MemberServicePhoneNumber", loginResult.MemberServicePhoneNumber);
            additionalProperties.Add("DispatchPhoneNumber", loginResult.DispatchPhoneNumber);
            additionalProperties.Add("BenefitGuidePDF", loginResult.BenefitGuidePDF);
            additionalProperties.Add("ProductImage", !string.IsNullOrEmpty(loginResult.ProductImage) ? loginResult.ProductImage : string.Empty);
            additionalProperties.Add("IsShowMemberList", loginResult.IsShowMemberList.ToString());
            additionalProperties.Add("IsShowAddMember", loginResult.IsShowAddMember.ToString());
            additionalProperties.Add("PersonID", loginResult.PersonID.ToString());

            context.Validated(new AuthenticationTicket(identity, ticketProperties));
            //context.Validated(identity);
        }

        public override Task TokenEndpoint(OAuthTokenEndpointContext context)
        {
            foreach (KeyValuePair<string, string> property in context.Properties.Dictionary)
            {
                context.AdditionalResponseParameters.Add(property.Key, property.Value);
            }
            return Task.FromResult<object>(null);
        }
    }
}
