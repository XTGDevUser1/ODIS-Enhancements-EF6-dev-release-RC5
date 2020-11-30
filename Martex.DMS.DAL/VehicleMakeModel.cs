//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Martex.DMS.DAL
{
    using System;
    using System.Collections.Generic;
    
    [Serializable] 
    public partial class VehicleMakeModel
    {
        public int ID { get; set; }
        public string Make { get; set; }
        public string Model { get; set; }
        public string Trim { get; set; }
        public Nullable<double> Year { get; set; }
        public string CarCategory { get; set; }
        public string EnginePosition { get; set; }
        public string Engine { get; set; }
        public string EngineType { get; set; }
        public string ValvesPerCylinder { get; set; }
        public string MaxPower { get; set; }
        public string MaxTorque { get; set; }
        public string Compression { get; set; }
        public string TopSpeed { get; set; }
        public string Fuel { get; set; }
        public string Transmission { get; set; }
        public string Acceleration { get; set; }
        public string Drive { get; set; }
        public Nullable<int> Seats { get; set; }
        public Nullable<int> Doors { get; set; }
        public string CountryofOrigin { get; set; }
        public string FrontTire { get; set; }
        public string RearTire { get; set; }
        public string Chassis { get; set; }
        public string CO2Emissions { get; set; }
        public string TurnCircle { get; set; }
        public string Weight { get; set; }
        public string TowingWeight { get; set; }
        public string TotalLength { get; set; }
        public string TotalWidth { get; set; }
        public string TotalHeight { get; set; }
        public string MaxWeightWithLoad { get; set; }
        public string FrontBrakesType { get; set; }
        public string RearBrakesType { get; set; }
        public string CargoSpace { get; set; }
        public string FuelWithHighwayDrinve { get; set; }
        public string FuelWithMixedDrive { get; set; }
        public string FuelWithCityDrive { get; set; }
        public string FuelTankCapacity { get; set; }
        public Nullable<int> VehicleCategoryID { get; set; }
        public Nullable<int> WarrantyPeriod { get; set; }
        public string WarrantyPeriodUOM { get; set; }
        public Nullable<int> WarrantyMileageMiles { get; set; }
        public Nullable<int> WarrantyMileageKilometers { get; set; }
    
        public virtual VehicleCategory VehicleCategory { get; set; }
    }
}
