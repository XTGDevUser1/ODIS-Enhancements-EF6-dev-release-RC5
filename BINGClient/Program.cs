using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using BINGClient.BINGServices;

namespace BINGClient
{
    class VendorAddress
    {
        public string Address { get; set; }
        public string City { get; set; }
        public string State { get; set; }
        public string Zip { get; set; }
        public string Country { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }

        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            
            sb.Append(" ====== START : Address ========");
            sb.AppendLine();
            sb.AppendFormat("Address : {0}", Address);
            sb.AppendLine();
            sb.AppendFormat("City : {0}", City);
            sb.AppendLine();
            sb.AppendFormat("State : {0}", State);
            sb.AppendLine();
            sb.AppendFormat("Zip : {0}", Zip);
            sb.AppendLine();
            sb.AppendFormat("Country : {0}", Country);
            sb.AppendLine();
            sb.AppendFormat("Latitude : {0}", Latitude);
            sb.AppendLine();
            sb.AppendFormat("Longitude : {0}", Longitude);
            sb.AppendLine();
            sb.Append(" ====== END : Address ========");
            sb.AppendLine();

            return sb.ToString();
        }
    }
    class Program
    {
        
        static void Main(string[] args)
        {
            
            Console.WriteLine(GetAddress("2701 S KAUFMAN", "ENNIS", "TX", "75119", "US"));
            Console.WriteLine(GetAddress("818 W Park Row Dr", "Arlington", "Texas", null,"US"));
            Console.WriteLine(GetAddress("2201 Brookhollow Plaza Dr", "Arlington", "Texas", "76006", "US"));
            
        }

        public static VendorAddress GetAddress(string address, string city, string state, string zip, string country)
        {
            // Set a Bing Maps key before making a request
            string key = "Ag37nsHBx8BxsIiXtl5qxfYNY7tt6s-aKky73p8iYA3vdZ8NDx3YCC7L1WWAgCEK"; //"AiCxnleqgXn7NC_nPmLMfek8lCJZdKtJ279g4aQMeUBuTD_CjqxnGfJ0ZyZfvNiy";

            GeocodeRequest geocodeRequest = new GeocodeRequest();

            // Set the credentials using a valid Bing Maps Key
            geocodeRequest.Credentials = new Credentials();
            geocodeRequest.Credentials.ApplicationId = key;

            // Set the full address query
            geocodeRequest.Query = string.Join(" ", address, city, state, country, zip);

            // Set the options to only return high confidence results
            ConfidenceFilter[] filters = new ConfidenceFilter[1];
            filters[0] = new ConfidenceFilter();
            filters[0].MinimumConfidence = Confidence.High;

            GeocodeOptions geocodeOptions = new GeocodeOptions();
            geocodeOptions.Filters = filters;

            geocodeRequest.Options = geocodeOptions;

            // Make the geocode request
            System.ServiceModel.EndpointAddress remoteAddress = new System.ServiceModel.EndpointAddress("http://dev.virtualearth.net/webservices/v1/geocodeservice/GeocodeService.svc");
            GeocodeServiceClient geocodeService =
            new GeocodeServiceClient("BasicHttpBinding_IGeocodeService", remoteAddress);
            
            geocodeService.Open();
            GeocodeResponse geocodeResponse = geocodeService.Geocode(geocodeRequest);

            VendorAddress va = new VendorAddress();

            if (geocodeResponse.Results != null && geocodeResponse.Results.Length > 0)
            {
                var result = geocodeResponse.Results[0];
                if (result.Address != null)
                {
                    var ra = result.Address;
                    va.Address = ra.AddressLine;
                    va.City = ra.Locality;
                    va.Zip = ra.PostalCode;
                    va.State = ra.AdminDistrict;
                    va.Country = ra.CountryRegion;
                }
                Dictionary<int, string> calculationMethodPrecendence = new Dictionary<int, string>();
                calculationMethodPrecendence.Add(1, "Rooftop");
                calculationMethodPrecendence.Add(2, "Parcel");
                calculationMethodPrecendence.Add(3, "Interpolation");
                calculationMethodPrecendence.Add(4, "InterpolationOffset");

                var location = (from l in result.Locations
                                join c in calculationMethodPrecendence on l.CalculationMethod equals c.Value
                                orderby c.Key
                                    select l).FirstOrDefault();

                if (location != null)
                {
                    Console.WriteLine("Calculation Method : {0} ", location.CalculationMethod);
                    va.Latitude = location.Latitude;
                    va.Longitude = location.Longitude;
                }

                /*foreach (var location in result.Locations)
                {
                    if (location.CalculationMethod.Equals("Interpolation", StringComparison.InvariantCultureIgnoreCase))
                    {
                        va.Latitude = location.Latitude;
                        va.Longitude = location.Longitude;
                    }
                }*/
            }

            return va;
        }
    }
}
