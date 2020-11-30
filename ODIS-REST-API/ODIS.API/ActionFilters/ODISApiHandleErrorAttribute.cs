using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.Models;
using System.Net;
using log4net;
using System.Data;
using System.Data.SqlClient;
using Martex.DMS.DAL.DMSBaseException;
//using System.Data.Entity.Core;
//using System.Data.Entity.Infrastructure;
//using System.Data.Entity.Validation;
using System.Text;
using System.Web.Http.Filters;
using System.Net.Http;

namespace ODISAPI.ActionFilters
{
    /// <summary>
    /// Handle errors that raise during the processing of a request.
    /// </summary>
    public class ODISApiHandleErrorAttribute : ExceptionFilterAttribute
    {
        protected static ILog logger = LogManager.GetLogger(typeof(ODISApiHandleErrorAttribute));
        /// <summary>
        /// Called when an exception occurs.
        /// If the request is of type Ajax - send OperationResult object (duly filled) as part of response and leave the default error handling, otherwise.
        /// </summary>
        /// <param name="filterContext">The action-filter context.</param>
        /// <exception cref="T:System.ArgumentNullException">The <paramref name="filterContext"/> parameter is null.</exception>
        public override void OnException(HttpActionExecutedContext filterContext)
        {
            try
            {
                string errorKey = errorKey = "-" + DateTime.Now.Ticks.ToString();//filterContext.Request..SessionID + 

                var exception = filterContext.Exception;
                string errorMessage = exception.InnerException != null ? exception.InnerException.Message : exception.Message;
                logger.Error(errorMessage, exception);
                HttpStatusCode status = HttpStatusCode.InternalServerError;
                 var exType = filterContext.Exception.GetType();

                if (exType == typeof(UnauthorizedAccessException))
                {
                    status = HttpStatusCode.Unauthorized;
                }
                else if (exType == typeof(ArgumentException))
                {
                    status = HttpStatusCode.NotFound;
                }

                 if (exType == typeof(DMSException))
                {
                    errorMessage = exception.Message;
                }
                else if (exType == typeof(SqlException))//exType == typeof(System.Data.Entity.Core.EntityCommandExecutionException) || 
                {
                    errorMessage = "Error while accessing database.";
                }
                else if (exType == typeof(Exception))
                {
                    errorMessage = " An error has occurred while processing your request";
                }

                var apiError = new OperationResult
                {
                    Status = OperationStatus.ERROR,
                    ErrorMessage = errorMessage,
                    ErrorDetail = exception.InnerException != null ? exception.InnerException.Message : exception.Message
                };

                // create a new response and attach our ApiError object
                // which now gets returned on ANY exception result
                var errorResponse = filterContext.Request.CreateResponse<OperationResult>(status, apiError);
                filterContext.Response = errorResponse;
            }
            catch (Exception ex)
            {
                // Call the default implementation in case there is an error while handling an error !
                //base.OnException(filterContext);

                var exception = filterContext.Exception;
                string errorMessage = exception.InnerException != null ? exception.InnerException.Message : exception.Message;
                logger.Error(errorMessage, exception);
                throw ex;
            }
            finally
            {
                base.OnException(filterContext);
            }
        }
    }
}