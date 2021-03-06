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
    public partial class StateProvince
    {
    	public StateProvince()
        {
            this.AddressEntities = new HashSet<AddressEntity>();
            this.Payments = new HashSet<Payment>();
            this.PaymentTransactions = new HashSet<PaymentTransaction>();
            this.VendorACHes = new HashSet<VendorACH>();
            this.VendorRegionStateProvinces = new HashSet<VendorRegionStateProvince>();
            this.Claims = new HashSet<Claim>();
        }
    
        public int ID { get; set; }
        public Nullable<int> CountryID { get; set; }
        public string Abbreviation { get; set; }
        public string Name { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<decimal> Latitude { get; set; }
        public Nullable<decimal> Longitude { get; set; }
        public string Color { get; set; }
    
        public virtual ICollection<AddressEntity> AddressEntities { get; set; }
        public virtual Country Country { get; set; }
        public virtual ICollection<Payment> Payments { get; set; }
        public virtual ICollection<PaymentTransaction> PaymentTransactions { get; set; }
        public virtual ICollection<VendorACH> VendorACHes { get; set; }
        public virtual ICollection<VendorRegionStateProvince> VendorRegionStateProvinces { get; set; }
        public virtual ICollection<Claim> Claims { get; set; }
    }
}
