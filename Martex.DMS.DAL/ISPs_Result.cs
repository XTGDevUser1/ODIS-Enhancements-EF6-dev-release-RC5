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
    
    [Serializable] 
    public partial class ISPs_Result
    {
        public int VendorID { get; set; }
        public int VendorLocationID { get; set; }
        public Nullable<decimal> Latitude { get; set; }
        public Nullable<decimal> Longitude { get; set; }
        public string VendorName { get; set; }
        public string VendorNumber { get; set; }
        public string Source { get; set; }
        public string ContractStatus { get; set; }
        public string Address1 { get; set; }
        public string Address2 { get; set; }
        public string City { get; set; }
        public string StateProvince { get; set; }
        public string PostalCode { get; set; }
        public string CountryCode { get; set; }
        public string DispatchPhoneNumber { get; set; }
        public string FaxPhoneNumber { get; set; }
        public string OfficePhoneNumber { get; set; }
        public Nullable<int> AdministrativeRating { get; set; }
        public string InsuranceStatus { get; set; }
        public string BusinessHours { get; set; }
        public string Comment { get; set; }
        public Nullable<int> ProductID { get; set; }
        public string ProductName { get; set; }
        public Nullable<decimal> ProductRating { get; set; }
        public Nullable<double> EnrouteMiles { get; set; }
        public Nullable<int> EnrouteTimeMinutes { get; set; }
        public Nullable<decimal> ServiceMiles { get; set; }
        public Nullable<int> ServiceTimeMinutes { get; set; }
        public Nullable<double> ReturnMiles { get; set; }
        public Nullable<int> ReturnTimeMinutes { get; set; }
        public Nullable<double> EstimatedHours { get; set; }
        public Nullable<double> EstimatedPrice { get; set; }
        public Nullable<double> WiseScore { get; set; }
        public string CallStatus { get; set; }
        public string RejectReason { get; set; }
        public string RejectComment { get; set; }
        public Nullable<bool> IsPossibleCallback { get; set; }
        public Nullable<decimal> BaseRate { get; set; }
        public Nullable<decimal> HourlyRate { get; set; }
        public Nullable<decimal> EnrouteRate { get; set; }
        public Nullable<int> EnrouteFreeMiles { get; set; }
        public Nullable<int> ServiceFreeMiles { get; set; }
        public Nullable<decimal> ServiceRate { get; set; }
        public string AllServices { get; set; }
        public string CellPhoneNumber { get; set; }
        public Nullable<int> VendorLocationVirtualID { get; set; }
        public string PaymentTypes { get; set; }
        public Nullable<int> ProductSearchRadiusMiles { get; set; }
        public Nullable<bool> IsInProductSearchRadius { get; set; }
        public string AlternateDispatchPhoneNumber { get; set; }
    }
}
