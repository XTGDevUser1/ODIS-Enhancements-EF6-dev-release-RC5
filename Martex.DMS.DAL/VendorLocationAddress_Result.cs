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
    public partial class VendorLocationAddress_Result
    {
        public int VendorLocation { get; set; }
        public string LocationAddress1 { get; set; }
        public string LocationAddress2 { get; set; }
        public string LocationAddress3 { get; set; }
        public string LocationCity { get; set; }
        public Nullable<int> LocationState { get; set; }
        public Nullable<int> LocationCountry { get; set; }
        public string LocationPostalCode { get; set; }
        public string LocationFaxNumber { get; set; }
        public string LocationDispatchNumber { get; set; }
        public string LocationOfficeNumber { get; set; }
    }
}
