using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ODISMember.Services.Contract;
using ODISMember.Entities;
using ODISMember.Entities.Model;

namespace ODISMember.Services.Service
{
    public class MemberService : IMemberService
    {
        /// <summary>
        /// Logins with the specified username and password
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <param name="password">The password. 
        /// Note:Password should follow the specified rules</param>
        /// <returns>Member details</returns>
        public async Task<AccessResult> Login(string userName, string password)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("username", userName);
            param.Add("password", password);
            param.Add("grant_type", "password");
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_LOGIN, HttpMethods.POST, param, null, "application/x-www-form-urlencoded");
            var jsonSerializer = new JsonSerializer();
            AccessResult result = (AccessResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(AccessResult));
            return result;
        }

        /// <summary>
        /// To Join the Member
        /// </summary>
        /// <param name="memberModel">The member model.</param>
        /// <returns></returns>
        public async Task<OperationResult> Join(MemberModel memberModel)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("MemberModel", memberModel);
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_JOIN, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Verify the member register details
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <param name="lastName">The last name.</param>
        /// <param name="firstName">The first name.</param>
        /// <returns>returns Success in Status property on successful verification, returns ErrorMessage on verification fails </returns>
        public async Task<OperationResult> RegisterVerify(string memberNumber, string lastName, string firstName)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("Member", new { MemberNumber = memberNumber, LastName = lastName, FirstName = firstName });


            string responseAsString = await RestManager.CallRestService(RestAPI.URL_REGISTER_VERIFY, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Registers member by using membership details
        /// </summary>
        /// <param name="registerSendModel">The register send model.</param>
        /// <returns>returns Success in Status property on successful registration, returns ErrorMessage on registration fails</returns>
        public async Task<OperationResult> Register(RegisterSendModel registerSendModel)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("Member", registerSendModel);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_REGISTER, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Resets the member password.
        /// </summary>
        /// <param name="email">Member registered email.</param>
        /// <returns>returns Success in Status property on successful reset of password, returns ErrorMessage on reset password fails</returns>
        public async Task<OperationResult> ResetPassword(string email)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("Member", new { Email = email });

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_RESET_PASSWORD, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Sends mail to member registered email
        /// </summary>
        /// <param name="email">Member registered email.</param>
        /// <returns>returns Success in Status property on successful reset of password, returns ErrorMessage on reset password fails</returns>
        public async Task<OperationResult> SendUserName(string email)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("UserMemberNumber", new { Email = email });

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_SEND_USER_NAME, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Changes the member password.
        /// </summary>
        /// <param name="changePasswordSendModel">The change password send model.</param>
        /// <returns>returns Success in Status property on successful change password, returns ErrorMessage on change password fails</returns>
        public async Task<OperationResult> ChangePassword(RegisterSendModel changePasswordSendModel)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("Member", changePasswordSendModel);
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_CHANGE_PASSWORD, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        /// <summary>
        /// Gets the member status.
        /// </summary>
        /// <param name="memberNumber">The member number.</param>
        /// <returns></returns>
        public async Task<OperationResult> GetMemberStatus(string memberNumber)
        {
            string getStatusUrl = string.Format(RestAPI.URL_MEMBER_STATUS, memberNumber);
            string responseAsString = await RestManager.CallRestService(getStatusUrl, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetVehicles(bool isVehiclePhotoRequired = true)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("isVehiclePhotoRequired", isVehiclePhotoRequired);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLES, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        public async Task<OperationResult> AddVehicles(List<VehicleModel> vehicles)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("Vehicles", vehicles);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLES, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> UpdateVehicles(List<VehicleModel> vehicles)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("Vehicles", vehicles);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLES, HttpMethods.PUT, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        public async Task<OperationResult> DeleteVehicles(long vehicleId)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("VehicleId", vehicleId);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLE_DELETE, HttpMethods.DELETE, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        public async Task<OperationResult> GetVehicleServices()
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            //param.Add("MasterMemberNumber", masterMemberNumber);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_ROADSIDE_VEHICLE_SERVICES, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetVehicleServiceQuestions(string productCategory, string vehicleCategory, string vehicleType)
        {
            //TODO:SC- Need to remove this latter
            if (string.IsNullOrEmpty(vehicleCategory.Trim()))
            {
                vehicleCategory = "LightDuty";
            }
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("ProductCategory", productCategory);
            param.Add("VehicleCategory", vehicleCategory);
            param.Add("VehicleType", vehicleType);
            param.Add("SourceSystem", Constants.SOURCE_SYSTEM);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_ROADSIDE_VEHICLE_SERVICES_QUESTIONS, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Gets the membership.
        /// </summary>
        /// <returns>Get the membership details</returns>
        public async Task<OperationResult> GetMembership()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_MEMBERSHIP, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Gets the members.
        /// </summary>
        /// <returns>Get the members</returns>
        public async Task<OperationResult> GetMembers()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        public async Task<OperationResult> GetMemberAssociates(string memberNumber)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("MemberNumber", memberNumber);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_ASSOCIATES, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> AddEditMember(List<Associate> associates)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("members", associates);
            var requestType = HttpMethods.POST;
            if (associates != null)
            {
                foreach (var item in associates)
                {
                    if (item.SystemIdentifier != 0L)
                    {
                        requestType = HttpMethods.PUT;
                    }
                }
            }
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER, requestType, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> UpdateMemberhip(AccountModel accountModel)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("membership", accountModel);
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_MEMBERSHIP, HttpMethods.PUT, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> DeleteMember(string memberNumber)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("MemberNumber", memberNumber);
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER, HttpMethods.DELETE, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        public async Task<OperationResult> GetActiveRequest(string membershipNumber)
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_ACTIVE_REQUEST, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Gets the member history.
        /// </summary>        
        /// <returns>Membership History</returns>
        public async Task<OperationResult> GetMemberHistory()
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("SourceSystem", Constants.SOURCE_SYSTEM);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_HISTORY, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        /// <summary>
        /// Submits the service request.
        /// </summary>
        /// <param name="serviceRequestModel">The service request model.</param>
        /// <returns>if request submit success Tracking UID returns</returns>
        public async Task<OperationResult> SubmitServiceRequest(ServiceRequestModel serviceRequestModel)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("serviceRequestModel", serviceRequestModel);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_SUBMIT_REQUEST, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        public async Task<OperationResult> SendServiceRequestCompletedResponse(string contactLogID, string callStatus, string serviceStatus)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("ClosedLoopRequest", new { CallStatus = callStatus, ServiceStatus = serviceStatus, ContactLogID = contactLogID });

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_SUBMIT_REQUEST_CLOSELOOP, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<BingAddressRoot> GetBingAddress(string lat, string lang)
        {
            string fullUrl = string.Format("https://dev.virtualearth.net/REST/v1/Locations/{0},{1}?&incl=ciso2&key={2}", lat, lang, Constants.BING_API_KEY);
            string responseAsString = await RestManager.CallRestService(fullUrl, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            BingAddressRoot result = (BingAddressRoot)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(BingAddressRoot));
            return result;
        }
        public async Task<BingAddressRoot> GetBingPoints(string address)
        {
            string fullUrl = string.Format("http://dev.virtualearth.net/REST/v1/Locations?q={0}&incl=ciso2&key={1}", System.Net.WebUtility.UrlEncode(address), Constants.BING_API_KEY);
            string responseAsString = await RestManager.CallRestService(fullUrl, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            BingAddressRoot result = (BingAddressRoot)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(BingAddressRoot));
            return result;
        }

        public async Task<OperationResult> GetApplicationSettings()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_APPLICATION_SETTINGS, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> ConfirmEstimate(string serviceRequestId)
        {
            string fullUrl = string.Format("{0}/{1}", RestAPI.URL_CONFIRM_ESTIMATE, serviceRequestId);
            string responseAsString = await RestManager.CallRestService(fullUrl, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> EmailSetupInstructions(MemberEmailModel memberEmailModel)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("memberEmailModel", memberEmailModel);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_SEND_MEMBER_EMAIL, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        public async Task<OperationResult> CancelEstimate(string serviceRequestId)
        {
            string fullUrl = string.Format("{0}/{1}", RestAPI.URL_CANCEL_ESTIMATE, serviceRequestId);
            string responseAsString = await RestManager.CallRestService(fullUrl, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        #region Dropdowns
        public async Task<OperationResult> GetVehicleChassis()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLE_CHASSIS_LIST, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetVehicleColors()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLE_COLOR_LIST, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetVehicleEngines()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLE_ENGINE_LIST, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetVehicleMakes(string vehicleTypeId)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("VehicleTypeID", vehicleTypeId);
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLE_MAKE_LIST, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetVehicleModels(string vehicleTypeId, string makeId)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("VehicleTypeID", vehicleTypeId);
            param.Add("Make", makeId);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLE_MODEL_LIST, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetVehicleTypes(string programId)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("ProgramId", programId);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLE_TYPE_LIST, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetVehicleTransmissions()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_VEHICLE_TRANSMISSION_LIST, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetStatesForCountry(string countryId)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("CountryID", countryId);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_STATES_FOR_COUNTRY, HttpMethods.GET, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetCountryCodes()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MEMBER_COUNTRY_CODE, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<OperationResult> GetMakeModels()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_DMS_MAKE_MODEL, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        #endregion

        /// <summary>
        /// Register the device with specific member tags
        /// </summary>
        /// <param name="registerModel">The Member related tag along with device OS.</param>
        /// <returns>Operation Result</returns>
        public async Task<OperationResult> DeviceRegister(DeviceRegisterModel registerModel)
        {
            Dictionary<string, object> param = new Dictionary<string, object>();
            param.Add("DeviceRegisterModel", registerModel);

            string responseAsString = await RestManager.CallRestService(RestAPI.URL_DEVICE_REGISTER, HttpMethods.POST, param);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        public async Task<OperationResult> GetStaticDataVersions()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MOBILE_STATIC_DATA_VERSIONS, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }

        #region WordPress Methods
        public async Task<OperationResult> GetWordPressPosts()
        {
            string responseAsString = await RestManager.CallRestService(RestAPI.URL_MOBILE_WORD_PRESS_POSTS, HttpMethods.GET, null);
            var jsonSerializer = new JsonSerializer();
            OperationResult result = (OperationResult)jsonSerializer.Deserialize(new StringReader(responseAsString), typeof(OperationResult));
            return result;
        }
        public async Task<WPMediaResult> GetWordPressMedia(string href)
        {
            try
            {
                string responseAsString = await RestManager.CallRestService(href, HttpMethods.GET, null);
                var result = JsonConvert.DeserializeObject<List<WPMediaResult>>(responseAsString);
                return (result != null && result.Count > 0) ? result[0] : null;
            }
            catch (Exception ex)
            {
                return null;
            }
        }
        #endregion
    }
}
