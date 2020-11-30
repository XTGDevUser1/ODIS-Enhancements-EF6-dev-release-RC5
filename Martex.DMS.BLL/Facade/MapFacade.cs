using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Transactions;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using log4net;
using System.Net;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade manages Map
    /// </summary>
    public class MapFacade
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(MapFacade));
        #region Public Methods

        /// <summary>
        /// Updates the service request.
        /// </summary>
        /// <param name="eventSource">The event source.</param>
        /// <param name="loggedInUser">The logged in user.</param>
        /// <param name="serviceRequest">The service request.</param>
        /// <param name="sessionID">The session ID.</param>
        public void UpdateServiceRequest(string eventSource, string loggedInUser, ServiceRequest serviceRequest, string sessionID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                ServiceRequestRepository serviceRequestRepository = new ServiceRequestRepository();
                serviceRequestRepository.UpdateMapDetails(serviceRequest);
                logger.InfoFormat("Updated map attributes on SR - {0}", serviceRequest.ID);
                serviceRequestRepository.UpdateVendorLocationDetails(serviceRequest.ID);
                logger.InfoFormat("Updated Vendor location attributes on SR - {0}", serviceRequest.ID);
                tran.Complete();
            }
        }

        /// <summary>
        /// Gets the call history.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<MapCallHistory_Result> GetCallHistory(int serviceRequestID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.GetMapCallHistory(serviceRequestID).ToList<MapCallHistory_Result>();
            }
        }

        public void UpdateMemberPersonalInfo(string email, string userName, int memberID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                MemberRepository memberRepository = new MemberRepository();
                memberRepository.UpdatePersonalInfo(string.Empty, string.Empty, email, userName, memberID);
            }
        }

        public void UpdateMemberEmailInfo(string email, int? reasonId, int caseID, string username)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                CaseRepository caserep = new CaseRepository();
                caserep.UpdateContactEmailAddress(email, reasonId, caseID, username);
            }
        }

        public void SetSMSAvailable(int caseID, bool? isSmsAvail)
        {
            CaseRepository caserep = new CaseRepository();
            caserep.SetSMSAvailable(caseID, isSmsAvail.GetValueOrDefault());
        }
        //public List<ContactEmailDeclineReason> GetDeclinedReasons()
        //{
        //    using (DMSEntities entities = new DMSEntities())
        //    {
        //        MapRepository mapRep = new MapRepository();
        //        return mapRep.GetDeclineReasons();
        //    }
        //}

        /// <summary>
        /// Determines whether [is show survey email allowed] [the specified program id].
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="configurationType">Type of the configuration.</param>
        /// <param name="configurationCategory">Category of the configuration.</param>
        /// <param name="Key">The key.</param>
        /// <returns>
        ///   <c>true</c> if [is show survey email allowed] [the specified program id]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsShowSurveyEmailAllowed(int programId, string configurationType, string configurationCategory, string Key)
        {
            var progRepository = new ProgramMaintenanceRepository();
            var programConfigs = progRepository.GetProgramInfo(programId, configurationType, configurationCategory);
            bool updateMembershipNumber = programConfigs.Where(p => p.Name.Equals(Key, StringComparison.InvariantCultureIgnoreCase) && p.Value.Equals("Yes", StringComparison.InvariantCultureIgnoreCase)).Count() > 0;
            return updateMembershipNumber;
        }


        public void SetMapSnapshot(int serviceRequestID)
        {

            try
            {
                string bingKey = AppConfigRepository.GetValue("BING_API_KEY");
                const string MAP_URL_LOCATION_ONLY = "https://dev.virtualearth.net/REST/V1/Imagery/Map/Road/{0},{1}/15?pp={0},{1};53;A&mapLayer=TrafficFlow&key={2}&mapSize=500,125";
                const string MAP_URL_ROUTE = "https://dev.virtualearth.net/REST/V1/Imagery/Map/Road/Routes/?wp.0={0},{1};;A&wp.1={2},{3};;B&timeType=Departure&dateTime={4}&output=xml&key={5}&mapSize=500,125";
                string staticMapURL = string.Empty;
                string destinationAddress = string.Empty;
                decimal? serviceLocationLatitude = null, serviceLocationLongitude = null, destinationLatitude = null, destinationLongitude = null;

                var serviceRequestRepository = new ServiceRequestRepository();
                var serviceRequest = serviceRequestRepository.GetById(serviceRequestID);

                if (serviceRequest != null)
                {
                    destinationAddress = serviceRequest.DestinationAddress;
                    serviceLocationLatitude = serviceRequest.ServiceLocationLatitude;
                    serviceLocationLongitude = serviceRequest.ServiceLocationLongitude;
                    destinationLatitude = serviceRequest.DestinationLatitude;
                    destinationLongitude = serviceRequest.DestinationLongitude;
                }
                if (serviceLocationLatitude != null && serviceLocationLongitude != null)
                {
                    if (!string.IsNullOrWhiteSpace(destinationAddress))
                    {
                        staticMapURL = string.Format(MAP_URL_ROUTE, serviceLocationLatitude, serviceLocationLongitude, destinationLatitude, destinationLongitude, DateTime.Now.ToString("hh:mm:sstt"), bingKey);
                    }
                    else
                    {
                        staticMapURL = string.Format(MAP_URL_LOCATION_ONLY, serviceLocationLatitude, serviceLocationLongitude, bingKey);
                    }

                    // Download the image data and convert that to base64 string.
                    WebClient client = new WebClient();
                    byte[] bytes = client.DownloadData(staticMapURL);
                    var base64String = Convert.ToBase64String(bytes);

                    //Update serviceRequest with map snapshot.
                    serviceRequestRepository.SetMapSnapshot(serviceRequestID, base64String);
                }
            }
            catch (Exception ex)
            {
                logger.Error(string.Format("Error while setting mapsnapshot for SR ID {0}", serviceRequestID), ex);
            }
        }

        #endregion
    }
}
