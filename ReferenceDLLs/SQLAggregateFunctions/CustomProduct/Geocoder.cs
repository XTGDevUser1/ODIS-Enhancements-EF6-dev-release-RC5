using Microsoft.SqlServer.Server;
using Microsoft.SqlServer.Types;
using System;
using System.Collections.Generic;
using System.Data.SqlTypes;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Xml;

namespace Spatial
{
    public static class CustomExtensions
    {
        /// <summary>
        /// Blanks if null.
        /// </summary>
        /// <param name="s">The s.</param>
        /// <returns></returns>
        public static string BlankIfNull(this SqlString s)
        {
            if (s.IsNull)
            {
                return string.Empty;
            }
            return (string)s;
        }
    }
    public class Geocoder
    {
        /* Generic function to return XML geocoded location from Bing Maps geocoding service */
        public static XmlDocument Geocode(
          string countryRegion,
          string adminDistrict,
          string locality,
          string postalCode,
          string addressLine
        )
        {
            // Variable to hold the geocode response
            XmlDocument xmlResponse = new XmlDocument();

            // Bing Maps key used to access the Locations API service
            string key = "Ag37nsHBx8BxsIiXtl5qxfYNY7tt6s-aKky73p8iYA3vdZ8NDx3YCC7L1WWAgCEK";

            // URI template for making a geocode request
            string urltemplate = "http://dev.virtualearth.net/REST/v1/Locations?countryRegion={0}&adminDistrict={1}&locality={2}&postalCode={3}&addressLine={4}&key={5}&output=xml";

            // Insert the supplied parameters into the URL template
            string url = string.Format(urltemplate, countryRegion, adminDistrict, locality, postalCode, addressLine, key);

            try
            {
                // Initialise web request
                HttpWebRequest webrequest = null;
                HttpWebResponse webresponse = null;
                Stream stream = null;
                StreamReader streamReader = null;

                // Make request to the Locations API REST service
                webrequest = (HttpWebRequest)WebRequest.Create(url);
                webrequest.Method = "GET";
                webrequest.ContentLength = 0;

                // Retrieve the response
                webresponse = (HttpWebResponse)webrequest.GetResponse();
                stream = webresponse.GetResponseStream();
                streamReader = new StreamReader(stream);
                xmlResponse.LoadXml(streamReader.ReadToEnd());

                // Clean up
                webresponse.Close();
                stream.Dispose();
                streamReader.Dispose();
            }
            catch (Exception ex)
            {
                // Exception handling code here;
            }

            // Return an XMLDocument with the geocoded results 
            return xmlResponse;
        }


        
        /* Wrapper method to expose geocoding functionality as SQL Server User-Defined Function (UDF) */
        [Microsoft.SqlServer.Server.SqlFunction(DataAccess = DataAccessKind.Read)]
        public static SqlGeography GeocodeUDF(
          SqlString countryRegion,
          SqlString adminDistrict,
          SqlString locality,
          SqlString postalCode,
          SqlString addressLine
          )
        {

            // Document to hold the XML geocoded location
            XmlDocument geocodeResponse = new XmlDocument();

            // Attempt to geocode the requested address
            try
            {
                geocodeResponse = Geocode(
                  countryRegion.BlankIfNull(),
                  adminDistrict.BlankIfNull(),
                  locality.BlankIfNull(),
                  postalCode.BlankIfNull(),
                  addressLine.BlankIfNull()
                );
            }
            // Failed to geocode the address
            catch (Exception ex)
            {
                SqlContext.Pipe.Send(ex.Message.ToString());
            }

            // Declare the XML namespace used in the geocoded response
            XmlNamespaceManager nsmgr = new XmlNamespaceManager(geocodeResponse.NameTable);
            nsmgr.AddNamespace("ab", "http://schemas.microsoft.com/search/local/ws/rest/v1");

            // Check that we received a valid response from the geocoding server
            if (geocodeResponse.GetElementsByTagName("StatusCode")[0].InnerText != "200")
            {
                throw new Exception("Didn't get correct response from geocoding server");
            }

            // Retrieve the list of geocoded locations
            XmlNodeList Locations = geocodeResponse.GetElementsByTagName("Location");
            SqlGeography Point = SqlGeography.Null;

            if (Locations.Count > 0)
            {
                // Create a geography Point instance of the first matching location
                double Latitude = double.Parse(Locations[0]["Point"]["Latitude"].InnerText);
                double Longitude = double.Parse(Locations[0]["Point"]["Longitude"].InnerText);
                Point = SqlGeography.Point(Latitude, Longitude, 4326);
            }

            // Return the Point to SQL Server
            return Point;
        }
    }
}

