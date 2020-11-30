using System;
using Microsoft.SqlServer.Server;
using System.Net;

namespace ODIS.Map.Snapshot
{    
    public class MapSnapshotGenerator
    {
        [Microsoft.SqlServer.Server.SqlFunction(DataAccess = DataAccessKind.Read)]
        public static string GetSnapshot(decimal? serviceLocationLatitude, decimal? serviceLocationLongitude, decimal? destinationLatitude, decimal? destinationLongitude, string bingKey)
        {
            const string MAP_URL_LOCATION_ONLY = "http://dev.virtualearth.net/REST/V1/Imagery/Map/Road/{0},{1}/15?pp={0},{1};53;A&mapLayer=TrafficFlow&key={2}&mapSize=500,125";
            const string MAP_URL_ROUTE = "https://dev.virtualearth.net/REST/V1/Imagery/Map/Road/Routes/?wp.0={0},{1};;A&wp.1={2},{3};;B&timeType=Departure&dateTime={4}&output=xml&key={5}&mapSize=500,125";
            string staticMapURL = string.Empty;
            string destinationAddress = string.Empty;
            
            if (destinationLatitude != null && destinationLongitude != null)
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

            return base64String;
        }
    }
}
