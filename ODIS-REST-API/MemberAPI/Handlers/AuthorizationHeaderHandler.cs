using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Formatting;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using System.Web;

namespace MemberAPI.Handlers
{
    public class AuthorizationHeaderHandler : DelegatingHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            if (!request.RequestUri.AbsoluteUri.Contains(StringConstants.SWAGGER))
            {
                var identity = (ClaimsPrincipal)Thread.CurrentPrincipal;

                if (!identity.Identity.IsAuthenticated)
                {
                    IEnumerable<string> apiKeyHeaderValues = null;

                    string applicationApiKey = ConfigurationManager.AppSettings[StringConstants.X_API_KEY];
                    string headerApiKey = null;

                    request.Headers.TryGetValues(StringConstants.X_API_KEY, out apiKeyHeaderValues);

                    if (apiKeyHeaderValues != null)
                    {
                        foreach (string key in apiKeyHeaderValues)
                        {
                            headerApiKey = key;
                        }
                    }

                    if (headerApiKey != applicationApiKey)
                    {
                        // Create the response.
                        var response = new HttpResponseMessage(HttpStatusCode.Unauthorized)
                        {
                            Content = new ObjectContent<OperationResult>(new OperationResult() { Status = OperationStatus.ERROR, Data = StringConstants.REQUEST_NOT_AUTHORIZED }, new JsonMediaTypeFormatter(), JsonMediaTypeFormatter.DefaultMediaType)
                        };

                        // Note: TaskCompletionSource creates a task that does not contain a delegate.
                        var tsc = new TaskCompletionSource<HttpResponseMessage>();
                        tsc.SetResult(response);   // Also sets the task state to "RanToCompletion"
                        return tsc.Task;
                    }
                }
            }

            return base.SendAsync(request, cancellationToken);
        }
    }
}