using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Web.Http;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAO;
using log4net;
using Newtonsoft.Json;
using Martex.DMS.BLL.Model.API;

namespace ODISAPI.Controllers
{
    [RoutePrefix("api")]
    public class ServiceRequestController : BaseApiController
    {
        CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
        MemberRepository memberRepository = new MemberRepository();
        ServiceRequestAPIFacade facade = new ServiceRequestAPIFacade();
        MemberAPIFacade memberApiFacade = new MemberAPIFacade();
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ServiceRequestController));

        UsersFacade uFacade = new UsersFacade();

        /// <summary>
        /// Gets the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [Authorize]
        [Route("v1/servicerequests/{id}")]
        public OperationResult Get(int? id)
        {
            logger.InfoFormat("ServiceRequestController - Get(), Parameters : {0}", id);
            LogAPIEvent(EventNames.API_GET_SERVICEREQUEST_BEGIN, id);
            var result = new OperationResult();
            var srs = facade.GetServiceRequestByIDForAPI(id);
            result.Data = srs;
            LogAPIEvent(EventNames.API_GET_SERVICEREQUEST_END, result);
            return result;
        }


        /// <summary>
        /// Gets the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [Authorize]
        [Route("v1/servicerequests")]
        public OperationResult Get([FromUri] ServiceRequestSearchModel model)
        {
            if (model == null)
            {
                model = new ServiceRequestSearchModel();
            }
            logger.InfoFormat("ServiceRequestController - Get(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                ServiceRequestSearchModel = model
            }));
            if (string.IsNullOrEmpty(model.CustomerGroupID) && string.IsNullOrEmpty(model.CustomerID))
            {
                throw new DMSException("One of CustomerID or CustomerGroupID is required along with Program ID");
            }
            LogAPIEvent(EventNames.API_GET_SERVICEREQUEST_BEGIN, model);
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

            LogAPIEvent(EventNames.API_GET_SERVICEREQUEST_END, result);
            logger.InfoFormat("ServiceRequestController  - Get(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                result = result
            }));
            return result;
        }


        /// <summary>
        /// Gets the active service request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [Authorize]
        [Route("v1/servicerequests/ActiveRequest")]
        public OperationResult GetActiveRequest([FromUri] ServiceRequestSearchModel model)
        {
            if (model == null)
            {
                model = new ServiceRequestSearchModel();
            }
            logger.InfoFormat("ServiceRequestController - GetActiveRequest(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                ServiceRequestSearchModel = model
            }));
            if (string.IsNullOrEmpty(model.CustomerGroupID) && string.IsNullOrEmpty(model.CustomerID))
            {
                throw new DMSException("One of CustomerID or CustomerGroupID is required along with Program ID");
            }
            LogAPIEvent(EventNames.API_GET_ACTIVE_REQUEST_BEGIN, model);
            var result = new OperationResult();

            try
            {
                if (ModelState.IsValid)
                {
                    if (model.EndDate != null && model.StartDate != null && model.EndDate < model.StartDate)
                    {
                        throw new DMSException("EndDate must be greater than StartDate");
                    }
                    logger.InfoFormat("Getting user ID from username {0}", AuthenticatedUserName);
                    model.userID = uFacade.GetUserByName(AuthenticatedUserName).UserId;
                    logger.InfoFormat("Obtained user ID from username {0}", AuthenticatedUserName);

                    logger.Info("START : Executing SP to get history list");
                    var listOfSRs = facade.GetAPIServiceRequestList(model);
                    logger.Info("END : Executing SP to get history list");

                    var activeRequest = listOfSRs.Where(x => (!x.Status.StartsWith("Cancelled") && !x.Status.StartsWith("Complete"))).OrderByDescending(x => x.CreateDate).FirstOrDefault();
                    logger.Info("DONE : Filtering for active request");
                    result.Data = activeRequest;
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

            LogAPIEvent(EventNames.API_GET_ACTIVE_REQUEST_END, result);
            logger.InfoFormat("ServiceRequestController  - GetActiveRequest(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                result = result
            }));
            return result;
        }

        // POST: api/ServiceRequest
        [Route("v1/ServiceRequests")]
        [HttpPost]
        public OperationResult Post(ServiceRequestApiModel model)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Called POST with data - {0}", JsonConvert.SerializeObject(model));
            LogAPIEvent(EventNames.API_POST_SERVICEREQUEST_BEGIN, model);
            try
            {
                // AddressDetails addressDetails = AddressFacade.GetAddressDetailsByLatLong(model.LocationLatitude, model.LocationLongitude);

                if (ModelState.IsValid)
                {
                    model.CurrentUser = AuthenticatedUserName;
                    if (string.IsNullOrEmpty(model.ContactFirstName))
                    {
                        throw new DMSException("ContactFirstName is required");
                    }

                    if (string.IsNullOrEmpty(model.ContactLastName))
                    {
                        throw new DMSException("ContactLastName is required");
                    }

                    if (string.IsNullOrWhiteSpace(model.MemberPhoneNumber))
                    {
                        throw new DMSException("Member PhoneNumber is required");
                    }

                    Client client = ReferenceDataRepository.GetClientForUser(AuthenticatedUserName);
                    if (client != null)
                    {
                        model.ClientID = client.ID;
                    }
                    //TODO : Need to add condition for Client. -- ClientID = [ClientID determined by authentication]  
                    var program = ReferenceDataRepository.GetProgramByIDAndClientID(model.ProgramID.GetValueOrDefault(), model.ClientID.GetValueOrDefault());
                    //TODO: KB - Enable after review.
                    if (program == null)
                    {
                        throw new DMSException("Program does not exist or doesn't belong to the current Client");
                    }

                    if (!(string.IsNullOrEmpty(model.LocationCountryCode)))
                    {
                        Country country = lookUpRepo.GetCountryByCode(model.LocationCountryCode);
                        if (!(string.IsNullOrEmpty(model.LocationStateProvince)))
                        {
                            StateProvince state = lookUpRepo.GetStateProvinceByAbbreviation(model.LocationStateProvince);

                            if (state.CountryID != country.ID)
                            {
                                throw new DMSException("Invalid StateProvince value");
                            }
                        }
                    }
                    if ((string.IsNullOrEmpty(model.MemberPhoneType)))
                    {
                        model.MemberPhoneType = PhoneTypeNames.Cell;
                    }
                    PhoneType phoneType = lookUpRepo.GetPhoneTypeByName(model.MemberPhoneType);
                    if (phoneType == null)
                    {
                        throw new DMSException("Invalid PhoneType value");
                    }
                    if (string.IsNullOrEmpty(model.Language))
                    {
                        model.Language = LanguageNames.ENGLISH;
                    }
                    Language language = ReferenceDataRepository.GetLanguageByName(model.Language);
                    if (language == null)
                    {
                        throw new DMSException("Invalid Language value");
                    }
                    if (model.VehicleYear != null)
                    {
                        if (!(model.VehicleYear <= DateTime.Now.AddYears(1).Year))
                        {
                            throw new DMSException("Invalid Vehicle Year");
                        }
                    }

                    //TFS 1412: Validate VIN if RequireVIN ProgramConfig is set up.
                    var programMaintenanceRepository = new Martex.DMS.DAL.DAO.ProgramMaintenanceRepository();
                    var progConfigs = programMaintenanceRepository.GetProgramInfo(model.ProgramID, "RegisterMember", "Validation");

                    var vinRequired = progConfigs.Where(x => (x.Name.Equals("RequireVIN", StringComparison.InvariantCultureIgnoreCase) && x.Value.Equals("yes", StringComparison.InvariantCultureIgnoreCase))).Count() > 0;
                    
                    if (string.IsNullOrEmpty(model.VehicleType))
                    {
                        model.VehicleType = VehicleTypeNames.AUTO;
                    }
                    VehicleType vehicleType = lookUpRepo.GetVehicleTypeByName(model.VehicleType);
                    if (vehicleType == null)
                    {
                        throw new DMSException("Invalid VehicleType.");
                    }

                    if(!string.IsNullOrEmpty(model.VehicleCategory))
                    {
                        var vehicleCategory = lookUpRepo.GetVehicleCategoryByName(model.VehicleCategory);
                        if(vehicleCategory != null)
                        {
                            model.VehicleCategoryID = vehicleCategory.ID;
                        }
                    }

                    if (!string.IsNullOrEmpty(model.RVType))
                    {
                        var rvType = ReferenceDataRepository.GetRVType(model.RVType);
                        if (rvType != null)
                        {
                            model.RVTypeID = rvType.ID;
                        }
                    }

                    var vehicleValidationErrors = memberApiFacade.ValidateVehicleFields(model.VehicleVIN, model.VehicleMake, model.VehicleModel, model.VehicleYear, false, vinRequired);
                    if (!string.IsNullOrEmpty(vehicleValidationErrors))
                    {
                        throw new DMSException(vehicleValidationErrors);
                    }

                    result.Data = facade.SaveServiceRequestFromWebService(model);
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
                    result.ErrorMessage = sb.ToString();//Request.CreateErrorResponse(HttpStatusCode.BadRequest, ModelState).ReasonPhrase.ToString();
                }
            }
            catch (DMSException dex)
            {
                logger.Error("Error while saving request", dex);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = dex.Message;
            }
            catch (Exception ex)
            {
                logger.Error("Error while saving request", ex);
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message;
            }
            LogAPIEvent(EventNames.API_POST_SERVICEREQUEST_END, result, EntityNames.SERVICE_REQUEST, result.Data != null ? ((ServiceRequestApiModel)result.Data).ServiceRequestID : null);
            return result;

        }

        // PUT: api/ServiceRequest/5
        [Route("v1/ServiceRequests")]
        public void Put(int id, [FromBody]string value)
        {
        }

        // DELETE: api/ServiceRequest/5
        [Route("v1/ServiceRequests")]
        public void Delete(int id)
        {
        }

        [Route("v1/servicerequests/{id}/cancel")]
        [HttpGet]
        public OperationResult Cancel(int id)
        {
            return new OperationResult() { Status = OperationStatus.SUCCESS };
        }

        [Route("v1/servicerequests/{id}/Estimate/Confirm")]
        [HttpGet]
        public OperationResult ConfirmEstimate(int id)
        {
            LogAPIEvent(EventNames.API_GET_CONFIRM_ESTIMATE_BEGIN, new { ServiceRequestID = id});
            logger.InfoFormat("Confirming Service Request {0}", id);
            facade.ConfirmEstimate(id, AuthenticatedUserName);
            LogAPIEvent(EventNames.API_GET_CONFIRM_ESTIMATE_END, new { ServiceRequestID = id });
            return new OperationResult() { Status = OperationStatus.SUCCESS };
        }

        [Route("v1/servicerequests/{id}/Estimate/Cancel")]
        [HttpGet]
        public OperationResult CancelEstimate(int id)
        {
            logger.InfoFormat("Cancelling Service Request {0}", id);
            LogAPIEvent(EventNames.API_GET_CANCEL_ESTIMATE_BEGIN, new { ServiceRequestID = id });
            facade.CancelEstimate(id, AuthenticatedUserName);
            LogAPIEvent(EventNames.API_GET_CANCEL_ESTIMATE_END, new { ServiceRequestID = id });
            return new OperationResult() { Status = OperationStatus.SUCCESS };
        }

        [Route("v1/servicerequests/closeloop")]
        [HttpPost]
        public OperationResult UpdateClosedLoopStatus([FromBody]ClosedLoopRequest closedLoopRequest)
        {
            OperationResult result = new OperationResult();
            ClosedLoopFacade facade = new ClosedLoopFacade();
            LogAPIEvent(EventNames.API_POST_CLOSELOOP_BEGIN, closedLoopRequest);
            bool updateStatus = facade.UpdateClosedLoopCallResults(closedLoopRequest.CallStatus, closedLoopRequest.ServiceStatus, closedLoopRequest.ContactLogID);
            if(!updateStatus)
            {
                result.Status = OperationStatus.ERROR;
                result.Data = "Unable to update closed loop status, please check API logs for more details";
            }
            LogAPIEvent(EventNames.API_POST_CLOSELOOP_END, result);
            return result;
        }

    }
}
