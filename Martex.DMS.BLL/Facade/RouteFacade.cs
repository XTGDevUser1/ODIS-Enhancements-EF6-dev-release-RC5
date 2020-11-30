using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.BINGServices;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;
using System.Net;
using BingMapsRESTService.Common.JSON;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Facade
{
    public class RouteFacade
    {
        protected static readonly string BING_API_KEY = AppConfigRepository.GetValue(AppConfigConstants.BING_API_KEY);
        //RouteServiceClient client;
        //RouteRequest routeRequest;

        protected static readonly ILog logger = LogManager.GetLogger(typeof(RouteFacade));

        public RouteFacade()
        {            
            //try
            //{    
            //    //client = new RouteServiceClient("BasicHttpBinding_IRouteService");
            //    //routeRequest = new RouteRequest();
            //    //routeRequest.Credentials = new Credentials();
            //    //routeRequest.Credentials.ApplicationId = BING_API_KEY;
            //}
            //catch (Exception ex)
            //{
            //    logger.Error(ex.Message, ex);
            //    throw ex;
            //}
        }

        /// <summary>
        /// Calculates the enroute miles and time.
        /// </summary>
        /// <param name="isp">The isp.</param>
        /// <param name="serviceLocationLatitude">The service location latitude.</param>
        /// <param name="serviceLocationLongitude">The service location longitude.</param>
        public EnrouteData CalculateEnrouteMilesAndTime(decimal? sourceLatitude, decimal? sourceLongitude, decimal? destinationLatitude, decimal? destinationLongitude)
        {
            logger.InfoFormat("Attempting to calculate Route data with the values {0}, {1}, {2}, {3}", sourceLongitude, sourceLongitude, destinationLatitude, destinationLongitude);
            if (sourceLatitude == null || sourceLongitude == null || destinationLatitude == null || destinationLongitude == null)
            {
                throw new DMSException("One of Latitude / Longitude information is not available to calculate the route");
            }
            
            Uri routeServiceRequest = new Uri(string.Format("http://dev.virtualearth.net/REST/V1/Routes/Driving?wp.0={0},{1}&wp.1={2},{3}&key={4}&$format=json&du=Mile", sourceLatitude,sourceLongitude, destinationLatitude, destinationLongitude, BING_API_KEY));

            WebClient wc = new WebClient();
            string responseAsString = wc.DownloadString(routeServiceRequest);
            var response = JsonConvert.DeserializeObject<Response>(responseAsString);

            LatitudeLongitude latLong = new LatitudeLongitude();
            var enrouteData = new EnrouteData();

            if (response != null && response.resourceSets != null && response.resourceSets.Count > 0)
            {
                var resources = response.resourceSets[0].resources;
                if (resources != null && resources.Count > 0)
                {
                    logger.InfoFormat("Got results from BING");
                    var resource = resources[0];
                    enrouteData.Distance = resource.travelDistance.GetValueOrDefault();
                    enrouteData.Time = resource.travelDuration.GetValueOrDefault();
                }
            }

            //Waypoint[] waypoints = new Waypoint[2];
            //waypoints[0] = new Waypoint();
            //waypoints[0].Description = "Start";
            //waypoints[0].Location = new Location();
            //waypoints[0].Location.Latitude = Convert.ToDouble(sourceLatitude);
            //waypoints[0].Location.Longitude = Convert.ToDouble(sourceLongitude);
            //waypoints[1] = new Waypoint();
            //waypoints[1].Description = "End";
            //waypoints[1].Location = new Location();
            //waypoints[1].Location.Latitude = Convert.ToDouble(destinationLatitude);
            //waypoints[1].Location.Longitude = Convert.ToDouble(destinationLongitude);

            //routeRequest.Waypoints = waypoints;
            //if (routeRequest.UserProfile == null)
            //{
            //    routeRequest.UserProfile = new UserProfile();
            //}
            //routeRequest.UserProfile.DistanceUnit = DistanceUnit.Mile;
            //if (routeRequest.Options == null)
            //{
            //    routeRequest.Options = new RouteOptions();
            //}
            //routeRequest.Options.Optimization = RouteOptimization.MinimizeTime;
            //routeRequest.Options.TrafficUsage = TrafficUsage.TrafficBasedRouteAndTime;

            //RouteResponse routeResponse = client.CalculateRoute(routeRequest);
            
            //var summary = routeResponse.Result.Summary;
            

            logger.InfoFormat("Calculated enroute miles : {0} and time in mins as {1}", enrouteData.Distance, enrouteData.Time);

            return enrouteData;
        }
        
    }

    public class EnrouteData
    {
        /// <summary>
        /// Gets or sets the distance. Unit of measure - Miles
        /// </summary>
        /// <value>
        /// The distance.
        /// </value>
        public double Distance { get; set; }

        /// <summary>
        /// Gets or sets the time. Unit of measure - Seconds
        /// </summary>
        /// <value>
        /// The time.
        /// </value>
        public long Time { get; set; }
    }
}
