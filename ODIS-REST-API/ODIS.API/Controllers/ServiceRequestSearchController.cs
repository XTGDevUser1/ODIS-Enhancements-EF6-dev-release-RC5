using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Mvc;
using log4net;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using Newtonsoft.Json;

namespace ODISAPI.Controllers
{
    public class ServiceRequestSearchController : BaseApiController
    {
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ServiceRequestSearchController));

        ServiceRequestAPIFacade facade = new ServiceRequestAPIFacade();
        UsersFacade uFacade = new UsersFacade();
        /// <summary>
        /// Posts the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [Authorize]
        public OperationResult Post(ServiceRequestSearchModel model)
        {
            logger.InfoFormat("ServiceRequestSearchController - Post(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                ServiceRequestSearchModel = model
            }));

            var result = new OperationResult();

            try
            {
                if (ModelState.IsValid)
                {
                    if (model.EndDate != null && model.StartDate != null && model.EndDate < model.StartDate)
                    {
                        throw new DMSException("EndDate must be greater than StartDate");
                    }

                    model.userID = uFacade.GetUserByName(AuthenticatedUserName).UserId;
                    result.Data = facade.GetAPIServiceRequestList(model);
                }
                else
                {
                    result.Status = OperationStatus.ERROR;
                    StringBuilder sb = new StringBuilder();
                    foreach (var modelState in ModelState.Values)
                    {
                        foreach (var error in modelState.Errors)
                        {
                            if (error.ErrorMessage != null)
                            {
                                sb.AppendLine(error.ErrorMessage.ToString());
                            }
                            if (error.Exception != null)
                            {
                                sb.AppendLine(error.Exception.ToString());
                            }
                        }
                    }
                    result.ErrorMessage = sb.ToString();
                }
            }
            catch (DMSException dex)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = dex.Message;
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.InnerException != null ? ex.InnerException.Message : ex.Message;
            }


            logger.InfoFormat("ServiceRequestSearchController  - Post(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                result = result
            }));
            return result;
        }
    }
}