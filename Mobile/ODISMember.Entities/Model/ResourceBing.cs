using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class ResourceBing
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
    }
}
