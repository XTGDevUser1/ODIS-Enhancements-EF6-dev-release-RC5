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
    public partial class ServiceFacilitySelection_Result
    {
        public int VendorID { get; set; }
        public string VendorName { get; set; }
        public string VendorNumber { get; set; }
        public Nullable<int> AdministrativeRating { get; set; }
        public int VendorLocationID { get; set; }
        public string PhoneNumber { get; set; }
        public Nullable<double> EnrouteMiles { get; set; }
        public string Address1 { get; set; }
        public string Address2 { get; set; }
        public string City { get; set; }
        public string StateProvince { get; set; }
    }
}
