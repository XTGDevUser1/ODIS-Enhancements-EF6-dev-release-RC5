using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using ModernHttpClient;
using Newtonsoft.Json;
using System.IO;
using TK.CustomMap.BingSearchService;
using TK.CustomMap.Models;

namespace TK.CustomMap.Api.Bing
{
    /// <summary>
    /// Handles calls the the OSM Nominatim API
    /// </summary>
    public class BingLocations
    {
        const string BaseUrl = "http://dev.virtualearth.net/REST/v1/Locations";

        private static BingLocations _instance;
        private readonly HttpClient _httpClient;
        private string bingMapKey = "Ag37nsHBx8BxsIiXtl5qxfYNY7tt6s-aKky73p8iYA3vdZ8NDx3YCC7L1WWAgCEK";
        /// <summary>
        /// Gets the API Instance
        /// </summary>
        public static BingLocations Instance
        {
            get
            {
                return _instance ?? (_instance = new BingLocations());
            }
        }
        /// <summary>
        /// Gets/Sets the limit of predictions to receive
        /// </summary>
        public int Limit { get; set; }
        /// <summary>
        /// Gets/Sets country codes
        /// </summary>
        public Collection<string> CountryCodes { get; private set; }

        /// <summary>
        /// Creates a new instance of <see cref="OsmNominatim"/>
        /// </summary>
        private BingLocations()
        {
            this._httpClient = new HttpClient(new NativeMessageHandler());
            //this._httpClient.BaseAddress = new Uri(BaseUrl);

            this.Limit = 5;
            this.CountryCodes = new Collection<string>();
        }
        /// <summary>
        /// Calls the OSM Niminatim API to get predictions
        /// </summary>
        /// <param name="searchTerm">Term to search for</param>
        /// <returns>Predictions</returns>
        public async Task<IEnumerable<ResourceBing>> GetPredictions(string searchTerm)
        {
            if (string.IsNullOrWhiteSpace(searchTerm)) return null;

            var result = await this._httpClient.GetAsync(this.BuildQueryString(searchTerm));

            if (result.IsSuccessStatusCode)
            {
                string data = await result.Content.ReadAsStringAsync();
                BingLocationResult bingLocationResult = JsonConvert.DeserializeObject<BingLocationResult>(data);
                if (bingLocationResult.ResourceSets.Count > 0)
                    return bingLocationResult.ResourceSets[0].Resources;
            }
            return null;
        }
        /// <summary>
        /// Build the API query string
        /// </summary>
        /// <param name="searchTerm">Term to search for</param>
        /// <returns>Query string</returns>
        private string BuildQueryString(string searchTerm)
        {
            string searchItem = searchTerm.Replace(" ", "+");
            string query = string.Format(BaseUrl + "?q={0}&incl=ciso2&key={1}", searchItem, bingMapKey);
            return query;
        }

        public void GetBusinessSearchResults(string searchTerm, decimal? latitude, decimal? longitude, Action<IEnumerable<ResourceBing>> serarchComplete)
        {
            SearchRequest searchRequest = new SearchRequest();

            // Set the credentials using a valid Bing Maps key
            searchRequest.Credentials = new Credentials();
            searchRequest.Credentials.ApplicationId = bingMapKey;

            //Create the search query
            StructuredSearchQuery ssQuery = new StructuredSearchQuery();
            ssQuery.Keyword = searchTerm;
            ssQuery.Location = latitude + "," + longitude;
            searchRequest.StructuredQuery = ssQuery;

            //Make the search request 
            SearchServiceClient searchService = new SearchServiceClient();
            searchService.SearchCompleted += (sender, e) =>
            {
                List<ResourceBing> results = new List<ResourceBing>();

                if (!e.Cancelled && e.Result != null)
                {
                    var searchResponse = e.Result;
                    //Parse and format results
                    if (searchResponse.ResultSets != null && searchResponse.ResultSets.Count > 0 && searchResponse.ResultSets[0].Results != null
                    && searchResponse.ResultSets[0].Results.Count > 0 && searchResponse.ResultSets[0].Results.Count > 0)
                    {
                        foreach (BusinessSearchResult result in searchResponse.ResultSets[0].Results.ToList())
                        {
                            results.Add(new Bing.ResourceBing()
                            {
                                Address = new Bing.AddressBing()
                                {
                                    AddressLine = result.Address.AddressLine,
                                    AdminDistrict = result.Address.AdminDistrict,
                                    CountryRegionIso2 = result.Address.CountryRegion,
                                    FormattedAddress = result.Address.FormattedAddress,
                                    Locality = result.Address.Locality,
                                    PostalCode = result.Address.PostalCode
                                },
                                Name = result.Name,
                                Point = new PointBing()
                                {
                                    Coordinates = new List<double> {
                                      result.LocationData!=null && result.LocationData.Locations!=null && result.LocationData.Locations.Count > 0? result.LocationData.Locations[0].Latitude:0,
                                      result.LocationData!=null && result.LocationData.Locations!=null && result.LocationData.Locations.Count > 0? result.LocationData.Locations[0].Longitude:0
                                  }
                                }
                            });
                        }
                    }
                }
                serarchComplete(results);
            };
            searchService.SearchAsync(searchRequest);
        }

        public async Task<IEnumerable<ResourceBing>> GetBusinessSearchResults(string searchTerm, decimal? latitude, decimal? longitude)
        {
            List<ResourceBing> results = new List<ResourceBing>();
            try
            {
                var RestUrl = string.Format("{0}json?location={1}&rankby=distance&name={2}&key={3}",
                    "https://maps.googleapis.com/maps/api/place/nearbysearch/", latitude + "," + longitude, searchTerm, "AIzaSyDHDcOg9TZEyV_797YPxxMjq0rbIu513B4");//radius={2}&500000

                var response = await this._httpClient.GetAsync(RestUrl);

                if (response.IsSuccessStatusCode)
                {
                    string data = await response.Content.ReadAsStringAsync();
                    if (data != null)
                    {
                        GooglePlaces googlePlacesResult = JsonConvert.DeserializeObject<GooglePlaces>(data);

                        if (googlePlacesResult != null && googlePlacesResult.Results != null && googlePlacesResult.Results.Count > 0)
                        {
                            foreach (GPlacesResult gpResult in googlePlacesResult.Results)
                            {
                                results.Add(new Bing.ResourceBing()
                                {
                                    Address = new Bing.AddressBing()
                                    {
                                        AddressLine = gpResult.Vicinity,
                                    },
                                    Name = gpResult.Name + ", " + gpResult.Vicinity,
                                    Point = new PointBing()
                                    {
                                        Coordinates = new List<double> {
                                      gpResult.Geometry!=null && gpResult.Geometry.Location !=null? gpResult.Geometry.Location.Lat:0,
                                      gpResult.Geometry!=null && gpResult.Geometry.Location !=null? gpResult.Geometry.Location.Lng:0,
                                  }
                                    }
                                });
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {

            }

            return results;
        }

        public async Task<IEnumerable<ResourceBing>> ReverseGeoCode(string countryRegion, string adminDistrct, string localaity, string addressLine, double latitude, double longitude)
        {
            var RestUrl = string.Format("{0}?CountryRegion={1}&adminDistrict={2}&locality={3}&addressLine={4}&key={5}&userLocation={6}&incl=ciso2", BaseUrl, countryRegion, adminDistrct, localaity, addressLine, bingMapKey, latitude + "," + longitude);

            var result = await this._httpClient.GetAsync(RestUrl);

            if (result.IsSuccessStatusCode)
            {
                string data = await result.Content.ReadAsStringAsync();
                if (data != null)
                {
                    BingLocationResult bingLocationResult = JsonConvert.DeserializeObject<BingLocationResult>(data);
                    if (bingLocationResult.ResourceSets != null && bingLocationResult.ResourceSets.Count > 0)
                    {
                        return bingLocationResult.ResourceSets[0].Resources;
                    }
                }
            }
            return null;
        }
    }
}
