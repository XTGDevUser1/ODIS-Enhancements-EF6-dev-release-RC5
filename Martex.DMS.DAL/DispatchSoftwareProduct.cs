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
    public partial class DispatchSoftwareProduct
    {
    	public DispatchSoftwareProduct()
        {
            this.Vendors = new HashSet<Vendor>();
            this.Vendors1 = new HashSet<Vendor>();
            this.VendorApplications = new HashSet<VendorApplication>();
            this.VendorApplications1 = new HashSet<VendorApplication>();
        }
    
        public int ID { get; set; }
        public string VendorName { get; set; }
        public string SoftwareName { get; set; }
        public string Description { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
    
        public virtual ICollection<Vendor> Vendors { get; set; }
        public virtual ICollection<Vendor> Vendors1 { get; set; }
        public virtual ICollection<VendorApplication> VendorApplications { get; set; }
        public virtual ICollection<VendorApplication> VendorApplications1 { get; set; }
    }
}