using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TK.CustomMap.Api.Bing
{
    public class ResourceBing : IPlaceResult
    {
        public string __type { get; set; }
        public List<double> Bbox { get; set; }
        public string Name { get; set; }
        public PointBing Point { get; set; }
        public AddressBing Address { get; set; }
        public string Confidence { get; set; }
        public string EntityType { get; set; }
        public List<GeocodePointBing> GeocodePoints { get; set; }
        public List<string> MatchCodes { get; set; }
        public string Description { get { return this.Name; } set { this.Name = value; } }
        public string Subtitle { get; set; }
    }
}
