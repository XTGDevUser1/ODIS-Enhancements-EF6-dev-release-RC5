using MemberAPI.DAL.CustomEntities;
using MemberAPI.Services.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services
{
    public interface IODISAPIService
    {

        /// <summary>
        /// Authenticates this instance.
        /// </summary>
        /// <returns>Access token to make API calls</returns>
        string Authenticate();

        /// <summary>
        /// Services the requests.
        /// </summary>
        /// <param name="accessToken">The access token.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <param name="SourceSystem">The source system.</param>
        /// <returns>
        /// Member Service Requests Hisotry
        /// </returns>
        List<ODISAPISearchSRListModel> ServiceRequests(string accessToken, string memberNumber, string membershipNumber, int programID, string sourceSystem);

        /// <summary>
        /// Gets the active request.
        /// </summary>
        /// <param name="accessToken">The access token.</param>
        /// <param name="membershipNumber">The membership number.</param>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        ODISAPISearchSRListModel GetActiveRequest(string accessToken, string memberNumber, string membershipNumber, int programID);

        /// <summary>
        /// Gets the roadside services.
        /// </summary>
        /// <param name="programID">The program identifier.</param>
        /// <returns></returns>
        List<RoadsideServices_Result> GetRoadsideServices(int programID);

        /// <summary>
        /// Gets the questionnaire.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <returns></returns>
        List<ServiceQuestions> GetQuestionnaire(QuestionsCriteria criteria);

        /// <summary>
        /// Gets the service request.
        /// </summary>
        /// <param name="serviceRequestID">The service request identifier.</param>
        /// <returns></returns>
        ODISAPISearchSRListModel GetServiceRequest(int serviceRequestID);

        /// <summary>
        /// Submits the request.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        ServiceRequestModel SubmitRequest(ServiceRequestModel model);

        /// <summary>
        /// Confirms the estimate.
        /// </summary>
        /// <param name="id">The identifier.</param>
        void ConfirmEstimate(int id);

        /// <summary>
        /// Cancels the estimate.
        /// </summary>
        /// <param name="id">The identifier.</param>
        void CancelEstimate(int id);

        /// <summary>
        /// Closes the loop.
        /// </summary>
        /// <param name="callStatus">The call status.</param>
        /// <param name="serviceStatus">The service status.</param>
        /// <param name="contactLogID">The contact log identifier.</param>
        void CloseLoop(string callStatus, string serviceStatus, string contactLogID);

        /// <summary>
        /// Gets the countries.
        /// </summary>
        /// <returns></returns>
        /// <exception cref="System.MemberAccessException">Unable to retrieve Countries</exception>
        List<ODISAPICountriesResult> GetCountries();

        /// <summary>
        /// Devices the register.
        /// </summary>
        /// <param name="tags">The tags.</param>
        /// <exception cref="System.MemberAccessException">Unable to register device</exception>
        void DeviceRegister(DeviceRegisterModel tags);

        /// <summary>
        /// Gets mobile APIs static data versions .
        /// </summary>
        /// <returns></returns>
        List<MobileStaticDataVersion> GETMobileStaticDataVersions();
    }
}
