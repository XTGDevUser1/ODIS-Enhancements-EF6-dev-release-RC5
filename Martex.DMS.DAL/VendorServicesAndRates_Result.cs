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
    public partial class VendorServicesAndRates_Result
    {
        public Nullable<int> ProductID { get; set; }
        public string Name { get; set; }
        public Nullable<decimal> BaseRate { get; set; }
        public Nullable<decimal> EnrouteRate { get; set; }
        public Nullable<decimal> EnrouteFreeMiles { get; set; }
        public Nullable<decimal> ServiceRate { get; set; }
        public Nullable<decimal> ServiceFreeMiles { get; set; }
        public Nullable<decimal> HourlyRate { get; set; }
        public Nullable<decimal> GoaRate { get; set; }
        public Nullable<int> ContractRateScheduleID { get; set; }
    }
}