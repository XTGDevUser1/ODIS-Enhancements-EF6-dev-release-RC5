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
    public partial class VendorTermsAgreement
    {
    	public VendorTermsAgreement()
        {
            this.Contracts = new HashSet<Contract>();
        }
    
        public int ID { get; set; }
        public Nullable<System.DateTime> EffectiveDate { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public string FileName { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    
        public virtual ICollection<Contract> Contracts { get; set; }
    }
}