using MemberAPI.DAL.CustomEntities;
using MemberAPI.Services.Models;
using Newtonsoft.Json;
using RestSharp;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services
{
    public class ODISAPIService : IODISAPIService
    {
        #region App Settings
        const string ODIS_API_END_POINT = "ODISAPIEndPoint";
        const string ODIS_API_Token_URL = "ODISAPITokenURL";
        const string ODIS_API_USER_NAME = "ODISAPIUserName";
        const string ODIS_API_PASSWORD = "ODISAPIPassword";
        const string MEMBER_MOBILE_SOURCE_SYSTEM = "MemberMobile";
        #endregion

        /// <summary>
        /// Authenticates this instance.
        /// </summary>
        /// <returns>Access token to make API calls</returns>
        public string Authenticate()
        {
            string endPoint = ConfigurationManager.AppSettings[ODIS_API_END_POINT];
            string userName = ConfigurationManager.AppSettings[ODIS_API_USER_NAME];
            string password = ConfigurationManager.AppSettings[ODIS_API_PASSWORD];
            string tokenURL = "token";

            var client = new RestClient(endPoint);
            var request = new RestRequest(tokenURL, Method.POST);

            request.AddHeader("contenttype", "x-www-form-urlencoded");

            request.AddParameter("grant_type", "password");
            request.AddParameter("username", userName);
            request.AddParameter("password", password);

            IRestResponse response = client.Execute(request);
            if (response.ResponseStatus == ResponseStatus.Completed && response.StatusCode == HttpStatusCode.OK)
            {
                return JsonConvert.DeserializeObject<ODISAPIAuthResponse>(response.Content).Access_Token;
            }
            else
            {
                return null;
            }
        }

        protected T Execute<T>(string endpointURL, string accessToken, Method method, object body)
        {
            string endPoint = ConfigurationManager.AppSettings[ODIS_API_END_POINT];
            var client = new RestClient(endPoint);
            var request = new RestRequest(endpointURL, method);
            //adding authorization header
            request.AddHeader("Authorization", "bearer " + accessToken);

            request.RequestFormat = DataFormat.Json;
            request.AddBody(body);

            IRestResponse response = client.Execute(request);
            /* ODIS API returns JSON even in the case of an internal server error */
            //if (response.ResponseStatus == ResponseStatus.Completed && response.StatusCode == HttpStatusCode.OK)
            {
                APIOperationResult operationResult = JsonConvert.DeserializeObject<APIOperationResult>(response.Content);
                if (operationResult.Status != "Success")
                {
                    throw new MemberException(operationResult.ErrorMessage);// new Exception(operationResult.ErrorDetail));
                }
                else
                {
                    if (operationResult.Status == "Success" && operationResult.Data != null)
                    {
                        var result = JsonConvert.DeserializeObject<T>(operationResult.Data.ToString());
                        return result;
                    }
                }
            }

            return default(T);
        }

        protected T Execute<T>(string endpointURL, string accessToken, Method method, List<KeyValuePair<string, string>> parameters)
        {
            string endPoint = ConfigurationManager.AppSettings[ODIS_API_END_POINT];
            var client = new RestClient(endPoint);
            var request = new RestRequest(endpointURL, method);
            //adding authorization header
            request.AddHeader("Authorization", "bearer " + accessToken);

            //adding url parameters
            parameters.ForEach(p =>
            {
                if (!string.IsNullOrEmpty(p.Value))
                {
                    request.AddParameter(p.Key, p.Value);
                }
            });

            IRestResponse response = client.Execute(request);
            /* ODIS API returns JSON even in the case of an internal server error */
            //if (response.ResponseStatus == ResponseStatus.Completed && response.StatusCode == HttpStatusCode.OK)
            {
                APIOperationResult operationResult = JsonConvert.DeserializeObject<APIOperationResult>(response.Content);
                if (operationResult.Status != "Success")
                {
                    throw new MemberException(operationResult.ErrorMessage);// new Exception(operationResult.ErrorDetail));
                }
                else
                {
                    if (operationResult.Status == "Success" && operationResult.Data != null)
                    {
                        var result = JsonConvert.DeserializeObject<T>(operationResult.Data.ToString());
                        return result;
                    }
                }
            }

            return default(T);
        }

        /// <summary>
        /// Services the requests.
        /// </summary>
        /// <param name="accessToken">The access token.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns>Member Service Requests Hisotry</returns>
        public List<ODISAPISearchSRListModel> ServiceRequests(string accessToken, string memberNumber, string membershipNumber, int programID, string sourceSystem)
        {
            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();

            const string serviceRequestsURL = "api/v1/servicerequests";

            //adding url parameters
            parameters.Add(new KeyValuePair<string, string>("customerID", memberNumber));
            parameters.Add(new KeyValuePair<string, string>("customerGroupID", membershipNumber));
            parameters.Add(new KeyValuePair<string, string>("programID", programID.ToString()));
            parameters.Add(new KeyValuePair<string, string>("sourceSystem", sourceSystem));

            return Execute<List<ODISAPISearchSRListModel>>(serviceRequestsURL, accessToken, Method.GET, parameters);

        }

        /// <summary>
        /// Gets the active request.
        /// </summary>
        /// <param name="accessToken">The access token.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        public ODISAPISearchSRListModel GetActiveRequest(string accessToken, string memberNumber, string membershipNumber, int programID)
        {
            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            const string apiURL = "api/v1/servicerequests/ActiveRequest";

            //adding url parameters
            parameters.Add(new KeyValuePair<string, string>("customerID", memberNumber));
            parameters.Add(new KeyValuePair<string, string>("customerGroupID", membershipNumber));
            parameters.Add(new KeyValuePair<string, string>("programID", programID.ToString()));
            parameters.Add(new KeyValuePair<string, string>("sourceSystem", MEMBER_MOBILE_SOURCE_SYSTEM));

            return Execute<ODISAPISearchSRListModel>(apiURL, accessToken, Method.GET, parameters);
        }

        /// <summary>
        /// Gets the questionnaire.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        public List<ServiceQuestions> GetQuestionnaire(QuestionsCriteria criteria)
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to retrieve questionnaire - Authentication failure");
            }

            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            const string apiURL = "api/v1/RoadsideServices/Questions";

            //adding url parameters            
            parameters.Add(new KeyValuePair<string, string>("programID", criteria.ProgramID.ToString()));
            parameters.Add(new KeyValuePair<string, string>("ProductCategory", criteria.ProductCategory));
            parameters.Add(new KeyValuePair<string, string>("SourceSystem", MEMBER_MOBILE_SOURCE_SYSTEM));
            parameters.Add(new KeyValuePair<string, string>("VehicleCategory", criteria.VehicleCategory));
            parameters.Add(new KeyValuePair<string, string>("VehicleType", criteria.VehicleType));

            return Execute<List<ServiceQuestions>>(apiURL, accessToken, Method.GET, parameters);
        }

        /// <summary>
        /// Gets the service request.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to retrieve questionnaire</exception>
        public ODISAPISearchSRListModel GetServiceRequest(int serviceRequestID)
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to retrieve Service Request - Authentication failure");
            }

            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            string apiURL = string.Format("api/v1/ServiceRequests/{0}", serviceRequestID);

            //adding url parameters            
            //parameters.Add(new KeyValuePair<string, string>("id", serviceRequestID.ToString()));            
            return Execute<ODISAPISearchSRListModel>(apiURL, accessToken, Method.GET, parameters);
        }

        public List<RoadsideServices_Result> GetRoadsideServices(int programID)
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to retrieve Roadside Services - Authentication failure");
            }

            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            string apiURL = string.Format("api/v1/RoadsideServices/{0}", programID);

            //adding url parameters            
            //parameters.Add(new KeyValuePair<string, string>("id", serviceRequestID.ToString()));            
            return Execute<List<RoadsideServices_Result>>(apiURL, accessToken, Method.GET, parameters);
        }

        /// <summary>
        /// Submits the request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        public ServiceRequestModel SubmitRequest(ServiceRequestModel model)
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to submit Service Request - Authentication failure");
            }

            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            string apiURL = "api/v1/ServiceRequests";

            return Execute<ServiceRequestModel>(apiURL, accessToken, Method.POST, model);
        }

        /// <summary>
        /// Confirms the estimate.
        /// </summary>
        /// <param name="id">The identifier.</param>
        public void ConfirmEstimate(int id)
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to confirm estimate - Authentication failure");
            }

            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            string apiURL = string.Format("api/v1/servicerequests/{0}/Estimate/Confirm", id);

            Execute<object>(apiURL, accessToken, Method.GET, parameters);
        }

        /// <summary>
        /// Cancels the estimate.
        /// </summary>
        /// <param name="id">The identifier.</param>
        public void CancelEstimate(int id)
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to cancel estimate - Authentication failure");
            }

            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            string apiURL = string.Format("api/v1/servicerequests/{0}/Estimate/Cancel", id);

            Execute<object>(apiURL, accessToken, Method.GET, parameters);
        }

        /// <summary>
        /// Gets the countries.
        /// </summary>
        /// <returns></returns>
        /// <exception cref="System.MemberAccessException">Unable to retrieve Countries</exception>
        public List<ODISAPICountriesResult> GetCountries()
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to retrieve Countries - Authentication failure");
            }

            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            string apiURL = "api/v1/Countries";

            return Execute<List<ODISAPICountriesResult>>(apiURL, accessToken, Method.GET, parameters);
        }

        /// <summary>
        /// Devices the register.
        /// </summary>
        /// <param name="tags">The tags.</param>
        /// <exception cref="System.MemberAccessException">Unable to register device</exception>
        public void DeviceRegister(DeviceRegisterModel tags)
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to register device - Authentication failure");
            }

            //List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            //parameters.Add(new KeyValuePair<string, string>("DeviceRegisterModel", JsonConvert.SerializeObject(tags))); 

            string apiURL = "api/v1/Devices/Register";

            Execute<object>(apiURL, accessToken, Method.POST, tags);
        }

        /// <summary>
        /// Gets mobile APIs static data versions .
        /// </summary>
        /// <returns></returns>
        public List<MobileStaticDataVersion> GETMobileStaticDataVersions()
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to register device - Authentication failure");
            }

            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();

            string apiURL = "api/v1/Members/MobileStaticDataVersions";

            return Execute<List<MobileStaticDataVersion>>(apiURL, accessToken, Method.GET, parameters);
        }

        /// <summary>
        /// Closes the loop.
        /// </summary>
        /// <param name="callStatus">The call status.</param>
        /// <param name="serviceStatus">The service status.</param>
        /// <param name="contactLogID">The contact log identifier.</param>
        public void CloseLoop(string callStatus, string serviceStatus, string contactLogID)
        {
            var accessToken = Authenticate();
            if (string.IsNullOrEmpty(accessToken))
            {
                throw new MemberAccessException("Unable to call CloseLoop - Authentication failure");
            }

            string apiURL = "api/v1/ServiceRequests/CloseLoop";
            List<KeyValuePair<string, string>> parameters = new List<KeyValuePair<string, string>>();
            parameters.Add(new KeyValuePair<string,string>("CallStatus", callStatus));
            parameters.Add(new KeyValuePair<string,string>("ServiceStatus", serviceStatus));
            parameters.Add(new KeyValuePair<string,string>("ContactLogID", contactLogID));
            
            var result = Execute<APIOperationResult>(apiURL, accessToken, Method.POST, parameters);

            if (result != null && "Error".Equals(result.Status,StringComparison.InvariantCultureIgnoreCase))
            {
                throw new MemberAccessException(result.Data.ToString());
            }
        }
    }
}
