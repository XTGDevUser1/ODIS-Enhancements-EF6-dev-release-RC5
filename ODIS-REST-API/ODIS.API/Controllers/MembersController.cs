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
using System.Web;

namespace ODISAPI.Controllers
{
    [RoutePrefix("api")]
    public class MembersController : BaseApiController
    {
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(MembersController));

        MemberManagementFacade facade = new MemberManagementFacade();
        MemberAPIFacade memberApiFacade = new MemberAPIFacade();

        /// <summary>
        /// Gets the specified identifier.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <returns></returns>
        [Authorize]
        [Route("v1/Members/{id}")]
        public OperationResult Get(int id)
        {
            MemberApiModel model = new MemberApiModel();
            model.InternalCustomerID = id;
            return FindMembers(model);
        }

        /// <summary>
        /// Gets the specified identifier.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <returns></returns>
        [Authorize]
        [Route("v1/Members")]
        public OperationResult Get([FromUri]MemberApiModel req)
        {
            return FindMembers(req);
        }

        /// <summary>
        /// Finds the members.
        /// </summary>
        /// <param name="req">The req.</param>
        /// <returns></returns>
        private OperationResult FindMembers(MemberApiModel req)
        {
            if (req == null)
            {
                req = new MemberApiModel();
            }
            logger.InfoFormat("MemberSearchController - Search(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                customerID = req.CustomerID,
                customerGroupID = req.CustomerGroupID,
                internalMemberID = req.InternalCustomerID
            }));

            LogAPIEvent(EventNames.API_GET_MEMBER_BEGIN, req);
            OperationResult result = new OperationResult();
            if (string.IsNullOrEmpty(req.CustomerID) && string.IsNullOrEmpty(req.CustomerGroupID) && (req.InternalCustomerID == null || req.InternalCustomerID.Value == 0) && string.IsNullOrEmpty(req.VehicleVIN) && (string.IsNullOrEmpty(req.LastName) || string.IsNullOrEmpty(req.FirstName)))
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = "At least one of Last Name & First Name or CustomerID or CustomerGroupID or InternalCustomerID or VIN is required";
            }
            //Last Name, VIN, Member #(CustomerGroupID)
            if (req.CustomerID != null && req.CustomerID.Length > 50)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = "The field CustomerID must be a string or array type with a maximum length of '50'.";
            }
            if (req.CustomerGroupID != null && req.CustomerGroupID.Length > 50)
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = "The field CustomerGroupID must be a string or array type with a maximum length of '50'.";
            }
            if (req.InternalCustomerID != null && (- 2147483648 > req.InternalCustomerID.Value || req.InternalCustomerID.Value > 2147483647))
            {
                result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                result.ErrorMessage = "MemberID is an integer field. Value should be between '-2147483648' and '2147483647'.";
            }
            if (result.Status != OperationStatus.BUSINESS_RULE_FAIL)
            {
                logger.InfoFormat("MemberSearchController - Search() - Parameters Validation Successful.");
                var list = memberApiFacade.SearchMemberAPI(req.CustomerID, req.CustomerGroupID, req.InternalCustomerID, req.LastName, req.FirstName, req.VehicleVIN, AuthenticatedUserName);
                if (list.Count == 0 && req.InternalCustomerID.GetValueOrDefault() > 0)
                {
                    result.ErrorMessage = "Member not found";
                }
                result.Data = list;
            }

            LogAPIEvent(EventNames.API_GET_MEMBER_END, result);

            logger.InfoFormat("MemberSearchController  - Search(), Returns : {0}", JsonConvert.SerializeObject(new
            {
                result = result
            }));
            return result;
        }


        /// <summary>
        /// Posts the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// CustomerID already exists
        /// or
        /// Program not exists
        /// or
        /// Invalid StateProvince value
        /// or
        /// Invalid PhoneType value
        /// or
        /// EffectiveDate value exceeds ExpirationDate value
        /// or
        /// Invalid Vehicle Year
        /// or
        /// Invalid VIN
        /// or
        /// Invalid Vehicle information
        /// </exception>
        [Authorize]
        [Route("v1/Members")]
        public OperationResult Post(MemberApiModel model)
        {
            OperationResult result = new OperationResult();
            logger.InfoFormat("Called POST with data - {0}", JsonConvert.SerializeObject(model));
            LogAPIEvent(EventNames.API_POST_MEMBER_BEGIN, model);
            try
            {
                // Calling ModelState.IsValid addresses Required and MaxLength validations.
                if (ModelState.IsValid)
                {
                    model.CurrentUser = AuthenticatedUserName;
                    if (string.IsNullOrEmpty(model.VehicleType))
                    {
                        model.VehicleType = VehicleTypeNames.AUTO;
                    }
                    Client client = ReferenceDataRepository.GetClientForUser(AuthenticatedUserName);
                    if (client != null)
                    {
                        model.ClientID = client.ID;
                    }
                    MemberRepository memberRepository = new MemberRepository();
                    Member member = memberRepository.GetMemberByClientMemberKey(model.CustomerID, model.ClientID.GetValueOrDefault());
                    if (member != null)
                    {
                        throw new DMSException("CustomerID already exists");
                    }
                    var program = ReferenceDataRepository.GetProgramByIDAndClientID(model.ProgramID.GetValueOrDefault(), model.ClientID.GetValueOrDefault());
                    if (program == null)
                    {
                        throw new DMSException("Program does not exist or doesn't belong to the current Client");
                    }

                    CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
                    Country country = lookUpRepo.GetCountryByCode(model.CountryCode);

                    if (country == null)
                    {
                        throw new DMSException("Invalid Country Code");
                    }
                    StateProvince state = lookUpRepo.GetStateProvinceByAbbreviation(model.StateProvince);

                    if (state.CountryID != country.ID)
                    {
                        throw new DMSException("Invalid StateProvince value");
                    }
                    if (string.IsNullOrEmpty(model.PhoneType))
                    {
                        model.PhoneType = PhoneTypeNames.Cell;
                    }
                    PhoneType phoneType = lookUpRepo.GetPhoneTypeByName(model.PhoneType);
                    if (phoneType == null)
                    {
                        throw new DMSException("Invalid PhoneType value");
                    }
                    if (model.AltPhoneNumber != null)
                    {
                        if (string.IsNullOrEmpty(model.AltPhoneType))
                        {
                            model.AltPhoneType = PhoneTypeNames.Cell;
                        }
                        phoneType = lookUpRepo.GetPhoneTypeByName(model.AltPhoneType);
                        if (phoneType == null)
                        {
                            throw new DMSException("Invalid Alternate Phone Type value");
                        }
                    }

                    if (!(model.ExpirationDate > model.EffectiveDate))
                    {
                        throw new DMSException("EffectiveDate value exceeds ExpirationDate value");
                    }
                    if (model.VehicleYear != null)
                    {
                        if (!(model.VehicleYear <= DateTime.Now.AddYears(1).Year))
                        {
                            throw new DMSException("Invalid Vehicle Year");
                        }
                    }

                    if (!(string.IsNullOrEmpty(model.VehicleVIN)))
                    {
                        if (!ReferenceDataRepository.CheckIsVINValid(model.VehicleVIN))
                        {
                            throw new DMSException("Invalid VIN");
                        }
                    }

                    if (model.IsPrimary == null)
                    {
                        model.IsPrimary = false;
                    }

                    #region Code to validate the fields on the server side.
                    /* Code to validate the fields on the server side.*/
                    //Validate fields based on program configuration.
                    ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
                    var programConfig = repository.GetProgramInfo(model.ProgramID, "RegisterMember", "Validation");

                    List<string> fieldsFailedValidation = ValidateMemberFields(model, programConfig);

                    if (fieldsFailedValidation.Count > 0)
                    {
                        result.Status = OperationStatus.BUSINESS_RULE_FAIL;
                        StringBuilder sb = new StringBuilder();
                        foreach (var field in fieldsFailedValidation)
                        {
                            sb.AppendLine("The " + field + " is required");
                        }
                        result.Status = OperationStatus.ERROR;
                        result.ErrorMessage = sb.ToString();
                    }
                    else
                    {
                        #region Validate Vehicle fields
                        bool isVehicleRequired = false;
                        bool isVINRequired = false;
                        if (IsFieldRequired("RequireVehicle", programConfig))
                        {
                            isVehicleRequired = true;
                        }
                        //TFS: 1413
                        var programConfigForVIN = repository.GetProgramInfo(model.ProgramID, "Vehicle", "Validation");
                        if (IsFieldRequired("VIN Number", programConfigForVIN))
                        {
                            isVINRequired = true;
                        }

                        var vehicleValidationErrors = memberApiFacade.ValidateVehicleFields(model.VehicleVIN, model.VehicleMake, model.VehicleModel, model.VehicleYear, isVehicleRequired, isVINRequired);
                        if (!string.IsNullOrEmpty(vehicleValidationErrors))
                        {
                            throw new DMSException(vehicleValidationErrors);
                        }


                        #endregion
                        result.Data = facade.SaveMemberDetails(model);
                    }

                    #endregion
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
                                if (error.Exception.Message.Contains("ExpirationDate"))
                                {
                                    sb.AppendLine("Invalid Expiration Date");
                                }
                                else if (error.Exception.Message.Contains("EffectiveDate"))
                                {
                                    sb.AppendLine("Invalid Effective Date");
                                }
                                else
                                {
                                    sb.AppendLine(error.Exception.ToString());
                                }
                            }
                        }
                    }
                    result.ErrorMessage = sb.ToString();//Request.CreateErrorResponse(HttpStatusCode.BadRequest, ModelState).ReasonPhrase.ToString();
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
                result.ErrorMessage = ex.Message;
            }
            LogAPIEvent(EventNames.API_POST_MEMBER_END, result, EntityNames.MEMBER, result.Data != null ? ((MemberApiModel)result.Data).InternalCustomerID : null);
            return result;
        }

        /// <summary>
        /// Puts the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// Customer doesn't exists.
        /// or
        /// Program not exists
        /// or
        /// Invalid StateProvince value
        /// or
        /// Invalid PhoneType value
        /// or
        /// EffectiveDate value exceeds ExpirationDate value
        /// or
        /// Invalid Vehicle Year
        /// or
        /// Invalid VIN
        /// </exception>
        [Authorize]
        [Route("v1/Members")]
        public OperationResult Put(MemberApiModel model)
        {
            LogAPIEvent(EventNames.API_PUT_MEMBER_BEGIN, model);
            logger.InfoFormat("Called PUT with data - {0}", JsonConvert.SerializeObject(model));
            OperationResult result = new OperationResult();
            try
            {
                if (ModelState.IsValid)
                {
                    model.CurrentUser = AuthenticatedUserName;
                    Client client = ReferenceDataRepository.GetClientForUser(AuthenticatedUserName);
                    if (client != null)
                    {
                        model.ClientID = client.ID;
                    }
                    //TODO : Need to add condition for Client. -- ProgramID in (Select ID From Program where ClientID = [ClientID determined by authentication])
                    MemberRepository memberRepository = new MemberRepository();
                    Member member = memberRepository.GetMemberByClientMemberKey(model.CustomerID, model.ClientID.GetValueOrDefault());
                    if (member == null)
                    {
                        throw new DMSException("Customer doesn't exist.");
                    }
                    else
                    {
                        model.InternalCustomerID = member.ID;
                    }
                    if (string.IsNullOrEmpty(model.VehicleType))
                    {
                        model.VehicleType = VehicleTypeNames.AUTO;
                    }
                    var program = ReferenceDataRepository.GetProgramByIDAndClientID(model.ProgramID.GetValueOrDefault(), model.ClientID.GetValueOrDefault());
                    if (program == null)
                    {
                        throw new DMSException("Program does not exist or doesn't belong to the current Client");
                    }
                    CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
                    if (!string.IsNullOrEmpty(model.CountryCode) && !string.IsNullOrEmpty(model.StateProvince))
                    {

                        Country country = lookUpRepo.GetCountryByCode(model.CountryCode);
                        StateProvince state = lookUpRepo.GetStateProvinceByAbbreviation(model.StateProvince);

                        if (state.CountryID != country.ID)
                        {
                            throw new DMSException("Invalid StateProvince value");
                        }
                    }
                    if (model.PhoneNumber != null && string.IsNullOrEmpty(model.PhoneType))
                    {
                        model.PhoneType = PhoneTypeNames.Cell;
                        PhoneType phoneType = lookUpRepo.GetPhoneTypeByName(model.PhoneType);
                        if (phoneType == null)
                        {
                            throw new DMSException("Invalid PhoneType value");
                        }
                    }
                    if (model.AltPhoneNumber != null && string.IsNullOrEmpty(model.AltPhoneType))
                    {
                        model.AltPhoneType = PhoneTypeNames.Cell;
                        PhoneType altPhoneType = lookUpRepo.GetPhoneTypeByName(model.AltPhoneType);
                        if (altPhoneType == null)
                        {
                            throw new DMSException("Invalid PhoneType value");
                        }
                    }
                    if (model.EffectiveDate != null && model.ExpirationDate != null && !(model.ExpirationDate > model.EffectiveDate))
                    {
                        throw new DMSException("EffectiveDate value exceeds ExpirationDate value");
                    }
                    if (model.VehicleYear != null)
                    {
                        if (!(model.VehicleYear <= DateTime.Now.AddYears(1).Year))
                        {
                            throw new DMSException("Invalid Vehicle Year");
                        }
                    }

                    if (!(string.IsNullOrEmpty(model.VehicleVIN)))
                    {
                        if (!ReferenceDataRepository.CheckIsVINValid(model.VehicleVIN))
                        {
                            throw new DMSException("Invalid VIN");
                        }
                    }

                    #region Validate Vehicle fields
                    var vehicleValidationErrors = memberApiFacade.ValidateVehicleFields(model.VehicleVIN, model.VehicleMake, model.VehicleModel, model.VehicleYear, false, false);
                    if (!string.IsNullOrEmpty(vehicleValidationErrors))
                    {
                        throw new DMSException(vehicleValidationErrors);
                    }


                    #endregion

                    result.Data = facade.SaveMemberDetails(model);


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
                                if (error.Exception.Message.Contains("ExpirationDate"))
                                {
                                    sb.AppendLine("Invalid Expiration Date");
                                }
                                else if (error.Exception.Message.Contains("EffectiveDate"))
                                {
                                    sb.AppendLine("Invalid Effective Date");
                                }
                                else
                                {
                                    sb.AppendLine(error.Exception.ToString());
                                }
                            }
                        }
                    }
                    result.ErrorMessage = sb.ToString();//Request.CreateErrorResponse(HttpStatusCode.BadRequest, ModelState).ReasonPhrase.ToString();
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
                result.ErrorMessage = ex.Message;
            }

            LogAPIEvent(EventNames.API_PUT_MEMBER_END, result, EntityNames.MEMBER, result.Data != null ? ((MemberApiModel)result.Data).InternalCustomerID : null);
            return result;
        }



        private List<string> ValidateMemberFields(MemberApiModel model, List<ProgramInformation_Result> programConfig)
        {
            // Validate fields based on the programConfiguration.
            List<string> fieldsFailedValidation = new List<string>();
            /*
             *  RequireAddress1
                RequireAddress2
                RequireAddress3
                RequireCity
                RequireCountry
                RequireEffectiveDate
                RequireEmail
                RequireExpirationDate
                RequireFirstName
                RequireLastName
                RequireMiddleName
                RequirePhone
                RequirePrefix
                RequireProgram
                RequireState
                RequireSuffix
                RequireZip
             */


            if (IsFieldRequired("RequireFirstName", programConfig) && string.IsNullOrEmpty(model.FirstName))
            {
                fieldsFailedValidation.Add("First Name");
            }
            if (IsFieldRequired("RequireMiddleName", programConfig) && string.IsNullOrEmpty(model.MiddleName))
            {
                fieldsFailedValidation.Add("Middle Name");
            }
            if (IsFieldRequired("RequireLastName", programConfig) && string.IsNullOrEmpty(model.LastName))
            {
                fieldsFailedValidation.Add("Last Name");
            }

            if (IsFieldRequired("RequirePhone", programConfig) && model.PhoneNumber == null)
            {
                fieldsFailedValidation.Add("Phone Number");
            }
            if (IsFieldRequired("RequireAddress1", programConfig) && string.IsNullOrEmpty(model.Address1))
            {
                fieldsFailedValidation.Add("Address Line1");
            }

            if (IsFieldRequired("RequireAddress2", programConfig) && string.IsNullOrEmpty(model.Address2))
            {
                fieldsFailedValidation.Add("Address Line2");
            }

            //if (IsFieldRequired("RequireAddress3", programConfig) && string.IsNullOrEmpty(model.Address3))
            //{
            //    fieldsFailedValidation.Add("Address Line3");
            //}

            if (IsFieldRequired("RequireCity", programConfig) && string.IsNullOrEmpty(model.City))
            {
                fieldsFailedValidation.Add("City");
            }
            if (IsFieldRequired("RequireCountry", programConfig) && model.CountryCode == null)
            {
                fieldsFailedValidation.Add("Country");
            }
            if (IsFieldRequired("RequireState", programConfig) && model.StateProvince == null)
            {
                fieldsFailedValidation.Add("State");
            }
            if (IsFieldRequired("RequireZip", programConfig) && string.IsNullOrEmpty(model.PostalCode))
            {
                fieldsFailedValidation.Add("Postal Code");
            }
            if (IsFieldRequired("RequireProgram", programConfig) && model.ProgramID == null)
            {
                fieldsFailedValidation.Add("Program");
            }
            if (IsFieldRequired("RequireEmail", programConfig) && string.IsNullOrEmpty(model.Email))
            {
                fieldsFailedValidation.Add("Email");
            }
            if (IsFieldRequired("RequireEffectiveDate", programConfig) && model.EffectiveDate == null)
            {
                fieldsFailedValidation.Add("Effective Date");
            }
            if (IsFieldRequired("RequireExpirationDate", programConfig) && model.ExpirationDate == null)
            {
                fieldsFailedValidation.Add("Expiration Date");
            }



            return fieldsFailedValidation;
        }


        private bool IsFieldRequired(string fieldName, List<ProgramInformation_Result> programConfig)
        {
            return programConfig.Where(x => fieldName.Equals(x.Name, StringComparison.InvariantCultureIgnoreCase) &&
                                            "yes".Equals(x.Value, StringComparison.InvariantCultureIgnoreCase)).Count() > 0;
        }



        [Authorize]
        [Route("v1/Devices/Register")]
        public OperationResult POST(DeviceRegisterModel deviceRegisterModel)
        {
            OperationResult result = new OperationResult();
            
            //LogAPIEvent(EventNames.API_POST_DEVICE_BEGIN, model);
            try
            {
                List<MobileDeviceRegistration> tags = new List<MobileDeviceRegistration>();

                if (!string.IsNullOrEmpty(deviceRegisterModel.DeviceOS) && deviceRegisterModel != null && deviceRegisterModel.Tags != null && deviceRegisterModel.Tags.Count >0)
                {
                    for (int i = 0, iCount = deviceRegisterModel.Tags.Count; i < iCount; i++)
                    {
                        tags.Add(new MobileDeviceRegistration()
                        {
                            DeviceOS = deviceRegisterModel.DeviceOS,
                            Tag = deviceRegisterModel.Tags[i],
                            CreateDate = DateTime.Now,
                            CreateBy = AuthenticatedUserName
                        });
                    }                    
                }
                else                
                {
                    throw new Exception("Model is not valid");
                }

                DeviceFacade facade = new DeviceFacade();
                facade.RegisterDevice(tags);
                //LogAPIEvent(EventNames.API_POST_DEVICE_END, result);
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = ex.Message.ToString();
            }
            return result;
        }

        [Authorize]
        [Route("v1/Countries")]
        public OperationResult GET()
        {
            OperationResult result = new OperationResult();
            result.Data = ReferenceDataRepository.GetCountryTelephoneCode(true);
            return result;
        }

        [Authorize]
        [HttpGet]
        [Route("v1/Members/MobileStaticDataVersions")]
        public OperationResult GETMobileStaticDataVersions()
        {
            OperationResult result = new OperationResult();
            MobileStaticDataVersionFacade facade = new MobileStaticDataVersionFacade();
            result.Data = facade.Get();
            return result;
        }
    }
}
