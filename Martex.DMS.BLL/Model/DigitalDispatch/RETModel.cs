using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.DigitalDispatch
{
    public class RETModel : DigitalDispatchHeaderModel
    {
        public string JobID { get; set; }
        public string ServiceProviderResponse { get; set; }
        public int? ETA { get; set; }
        public int? MilesToVehicle { get; set; }
        public int? MilesLoaded { get; set; }
        public decimal? EstimatedPrice { get; set; }
        public string ColorOfTruck { get; set; }
        public string ContactName { get; set; }
        public string RejectDescription { get; set; }
        public int? CurrentTemperature { get; set; }
        public string PrecipitationType { get; set; }
        public string RoadCondition { get; set; }
        public string Remarks { get; set; }
    }
}
