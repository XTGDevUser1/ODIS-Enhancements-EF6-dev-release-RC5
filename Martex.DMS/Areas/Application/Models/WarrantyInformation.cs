using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.Areas.Application.Models
{
    public class WarrantyInformation
    {
        public int? WarrantyPeriod { get; set; }
        public string WarrantyPeriodUOM { get; set; }
        public int? WarrantyMileage { get; set; }
        public string WarrantyMileageUOM { get; set; }
    }
}