using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MemberAPI.Models
{
    public class VehicleInformation
    {
        public string VIN { get; set; }
        public string VehicleYear { get; set; }
        public string VehicleMake { get; set; }
        public string VehicleModel { get; set; }
        public string Transmission { get; set; }
        public string VehicleEngineManufacturer { get; set; }
        public string VehicleEngineType { get; set; }
        public string VehicleChassis { get; set; }
        public string VehicleLength { get; set; }
        public string Color { get; set; }
        public string LicenseState { get; set; }
        public string LicenseNumber { get; set; }
        public string Photo { get; set; }


        //public string FirstOwner { get; set; }        
        //public bool PrimaryVehicle { get; set; }
        //public long SystemIdentifier { get; set; }
        //public DateTime VehiclePurchaseDate { get; set; }        
        //public DateTime WarrantyStartDate { get; set; }
        //public string i5RVType { get; set; }
        //public string i5TowType { get; set; }
        //public string i5VehicleClass { get; set; }
    }
}