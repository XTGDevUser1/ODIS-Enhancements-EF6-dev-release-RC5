using System;

namespace ODISMember.Entities.Model
{
    public class VehicleModel
    {
        public string Chassis { get; set; }
        public string Color { get; set; }
        public string Description { get; set; }
        public string Engine { get; set; }
        public string Height { get; set; }
        public string HitchType { get; set; }
        public bool IsActive { get; set; }
        public bool IsFirstOwner { get; set; }
        public string Length { get; set; }
        public string LicenseCountry { get; set; }
        public string LicenseNumber { get; set; }
        public string LicenseState { get; set; }
        public string Make { get; set; }
        public string MakeOther { get; set; }
        public string MemberNumber { get; set; }
        public string Model { get; set; }
        public string ModelOther { get; set; }
        public long PersonId { get; set; }
        public byte[] Photo { get; set; }
        public string RVType { get; set; }
        public long SystemIdentifier { get; set; }
        public string Transmission { get; set; }
        public string VIN { get; set; }
        public string VehicleCategory { get; set; }
        public string VehicleType { get; set; }
        public System.DateTime WarrantyEndDate { get; set; }
        public System.DateTime WarrantyStartDate { get; set; }
        public string Year { get; set; }
    }
}

