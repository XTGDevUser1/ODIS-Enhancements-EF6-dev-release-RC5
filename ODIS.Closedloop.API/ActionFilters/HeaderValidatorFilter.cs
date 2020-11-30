using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.DAO;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Filters;

namespace ODIS.Closedloop.API.ActionFilters
{
    public class InvalidAPIKeyActionResult : IHttpActionResult
    {
        public string ReasonPhrase { get; private set; }

        public HttpRequestMessage Request { get; private set; }

        public InvalidAPIKeyActionResult(string reason, HttpRequestMessage request)
        {
            this.ReasonPhrase = reason;
            this.Request = request;
        }

        public Task<HttpResponseMessage> ExecuteAsync(CancellationToken cancellationToken)
        {
            HttpResponseMessage response = new HttpResponseMessage(HttpStatusCode.Unauthorized);
            response.RequestMessage = Request;
            response.Headers.Add("ODIS-ErrorDetail", ReasonPhrase);
            return Task.FromResult(response);
        }
    }
    public class HeaderValidatorFilterAttribute : FilterAttribute, IAuthenticationFilter
    {
        public Task AuthenticateAsync(HttpAuthenticationContext context, CancellationToken cancellationToken)
        {
            // Check if the authorization header is having the api key
            // 1. Look for credentials in the request.
            var request = context.Request;
            var authorization = request.Headers.FirstOrDefault(x => x.Key.ToLower() == "x-api-key");

            // 2. If there are no credentials, do nothing.
            if (authorization.Value == null || string.IsNullOrWhiteSpace(authorization.Value.FirstOrDefault()))
            {
                context.ErrorResult = new InvalidAPIKeyActionResult("Missing API Key in the request header", request);                
            }
            else if (!string.IsNullOrWhiteSpace(authorization.Value.FirstOrDefault()))
            {
                var apiKey = AppConfigRepository.GetValue(AppConfigConstants.ClosedLoopApiKey); //ConfigurationManager.AppSettings["ApiKey"];
                if (!authorization.Value.FirstOrDefault().Equals(apiKey))
                {
                    context.ErrorResult = new InvalidAPIKeyActionResult("Invalid API Key", request);
                }
            }

            return Task.FromResult(0);
        }   

        public Task ChallengeAsync(HttpAuthenticationChallengeContext context, CancellationToken cancellationToken)
        {
            return Task.FromResult(0);
        }
    }
}
