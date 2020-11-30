using SQLite.Net.Attributes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Table
{
    public class MakeModel
    {
        [PrimaryKey, AutoIncrement]
        public int UniqueId { get; set; }
        public int Id { get; set; }
        public int? VehicleTypeID { get; set; }
        public string VehicleType { get; set; }
        public int? VehicleCategoryID { get; set; }
        public string VehicleCategory { get; set; }
        public int? RVTypeID { get; set; }
        public string RVType { get; set; }
        public int? MotorcycleTypeID { get; set; }
        public string MotorcycleType { get; set; }
        public int? TrailerTypeID { get; set; }
        public string TrailerType { get; set; }
        public string Make { get; set; }
        public string Model { get; set; }
        public int? WarrantyPeriod { get; set; }
        public string WarrantyPeriodUOM { get; set; }
        public int? WarrantyMileageMiles { get; set; }
        public int? WarrantyMileageKilometers { get; set; }
        public bool? IsSportUtility { get; set; }
        public int? Sequence { get; set; }
        public bool? IsActive { get; set; }
    }
}
