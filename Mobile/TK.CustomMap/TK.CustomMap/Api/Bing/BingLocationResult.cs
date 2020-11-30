using Newtonsoft.Json;
using System.Collections.Generic;

namespace TK.CustomMap.Api.Bing
{
    /// <summary>
    /// Result class of the OSM Nominatim search API call
    /// </summary>
    public class BingLocationResult 
    {
        public string AuthenticationResultCode { get; set; }
        public string BrandLogoUri { get; set; }
        public string Copyright { get; set; }
        public List<ResourceSet> ResourceSets { get; set; }
        public int StatusCode { get; set; }
        public string StatusDescription { get; set; }
        public string TraceId { get; set; }
       
    }
}


//BingLocationResult