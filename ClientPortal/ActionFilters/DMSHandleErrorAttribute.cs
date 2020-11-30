using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using ClientPortal.Models;
using System.Net;
using log4net;
using System.Data;
using System.Data.SqlClient;
using Martex.DMS.DAL.DMSBaseException;

namespace ClientPortal.ActionFilters
{
    /// <summary>
    /// Handle errors that raise during the processing of a request.
    /// </summary>
    public class DMSHandleErrorAttribute : HandleErrorAttribute
    {
        protected static ILog logger = LogManager.GetLogger(typeof(DMSHandleErrorAttribute));
        /// <summary>
        /// Called when an exception occurs.
        /// If the request is of type Ajax - send OperationResult object (duly filled) as part of response and leave the default error handling, otherwise.
        /// </summary>
        /// <param name="filterContext">The action-filter context.</param>
        /// <exception cref="T:System.ArgumentNullException">The <paramref name="filterContext"/> parameter is null.</exception>
        public override void OnException(ExceptionContext filterContext)
        {
            try
            {
                string errorKey = errorKey = filterContext.HttpContext.Session.SessionID + DateTime.Now.ToString("yyyyMMdd");

                var exception = filterContext.Exception;
                logger.Error(errorKey, exception);

                if (filterContext.RequestContext.HttpContext.Request.IsAjaxRequest())
                {
                    string errorMessage = exception.Message;
                    if (exception is DMSException)
                    {
                        errorMessage = exception.Message;
                        errorKey = null;
                    }
                    else if (exception is EntityCommandExecutionException || exception is SqlException)
                    {
                        errorMessage = "Error while accessing database.";
                    }
                    else if (exception is Exception)
                    {
                        errorMessage = "An error occurred while processing the request";
                    }
                    OperationResult result = new OperationResult() { Status = OperationStatus.ERROR, Data = errorKey, ErrorMessage = errorMessage };
                    filterContext.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                    filterContext.Result = new JsonResult() { Data = result };

                    filterContext.HttpContext.Response.TrySkipIisCustomErrors = true;
                    filterContext.ExceptionHandled = true;
                }
                else
                {
                    filterContext.Controller.TempData["errorkey"] = errorKey;
                    base.OnException(filterContext);
                }
            }
            catch (Exception)
            {
                // Call the default implementation in case there is an error while handling an error !
                base.OnException(filterContext);
            }
        }
    }
}