using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Security;
using VendorPortal.Models;
using log4net;

namespace VendorPortal.ActionFilters
{
    /// <summary>
    /// Attribute to handle session timeouts for AJAX requests.
    /// </summary>
    public class DMSAuthorizeAttribute : AuthorizeAttribute
    {
        public string Securable { get; set; }

        protected static readonly ILog logger = LogManager.GetLogger(typeof(DMSAuthorizeAttribute));
        public override void OnAuthorization(AuthorizationContext filterContext)
        {
            if (!string.IsNullOrEmpty(Securable) && DMSSecurityProvider.GetAccessType(Securable) == AccessType.Denied)
            {
                logger.InfoFormat("{0} is denied", Securable);
                if (filterContext.HttpContext.Request.IsAjaxRequest())
                {
                    // Fire back an unauthorized response
                    filterContext.HttpContext.Response.StatusCode = 403;
                    UrlHelper urlHelper = new UrlHelper(filterContext.RequestContext);
                    OperationResult result = new OperationResult()
                    {
                        Status = OperationStatus.ERROR,
                        ErrorDetail = "Access Denied",
                        ErrorMessage = "Access Denied",
                        Data = urlHelper.Action("Index", "AccessDenied", new { area = string.Empty })
                    };
                    filterContext.Result = new JsonResult()
                    {
                        Data = result,
                        JsonRequestBehavior = JsonRequestBehavior.AllowGet
                    };

                }
                else
                {
                    filterContext.HttpContext.Response.StatusCode = 401;
                    filterContext.Result = new RedirectResult("~/AccessDenied/Index");
                }

            }
            else
            {
                base.OnAuthorization(filterContext);
            }
        }

        /// <summary>
        /// Processes AJAX HTTP requests that fail authorization due to a session timeout.
        /// </summary>
        /// <param name="filterContext">Encapsulates the information for using <see cref="T:System.Web.Mvc.AuthorizeAttribute"/>. The <paramref name="filterContext"/> object contains the controller, HTTP context, request context, action result, and route data.</param>
        protected override void HandleUnauthorizedRequest(AuthorizationContext filterContext)
        {
            if (filterContext.HttpContext.Request.IsAjaxRequest())
            {
                // Fire back an unauthorized response
                filterContext.HttpContext.Response.StatusCode = 403;
                UrlHelper urlHelper = new UrlHelper(filterContext.RequestContext);
                OperationResult result = new OperationResult()
                {
                    Status = OperationStatus.ERROR,
                    ErrorDetail = "Session timeout",
                    ErrorMessage = "Session timeout",
                    Data = urlHelper.Action("Login","/Account")
                };
                filterContext.Result = new JsonResult()
                {
                    Data = result,
                    JsonRequestBehavior = JsonRequestBehavior.AllowGet
                };

            }
            else
            {
                base.HandleUnauthorizedRequest(filterContext);
            }
            
        }
        
    }
}