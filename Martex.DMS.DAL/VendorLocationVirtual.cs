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
    public partial class VendorLocationVirtual
    {
        public int ID { get; set; }
        public int VendorLocationID { get; set; }
        public Nullable<decimal> Latitude { get; set; }
        public Nullable<decimal> Longitude { get; set; }
        public System.Data.Entity.Spatial.DbGeography GeographyLocation { get; set; }
        public bool IsActive { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public string LocationAddress { get; set; }
        public string LocationCity { get; set; }
        public string LocationStateProvince { get; set; }
        public string LocationCountryCode { get; set; }
        public string LocationPostalCode { get; set; }
    
        public virtual VendorLocation VendorLocation { get; set; }
    }
}
