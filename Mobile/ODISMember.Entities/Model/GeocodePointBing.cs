using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class GeocodePointBing
    {
        public string Type { get; set; }
        public List<double> Coordinates { get; set; }
        public string CalculationMethod { get; set; }
        public List<string> UsageTypes { get; set; }
    }
}
