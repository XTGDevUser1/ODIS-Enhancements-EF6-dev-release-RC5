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
    public partial class Membership
    {
    	public Membership()
        {
            this.MemberProducts = new HashSet<MemberProduct>();
            this.Vehicles = new HashSet<Vehicle>();
            this.MembershipBlackListVendors = new HashSet<MembershipBlackListVendor>();
            this.MemberPaymentMethods = new HashSet<MemberPaymentMethod>();
            this.Members = new HashSet<Member>();
        }
    
        public int ID { get; set; }
        public string MembershipNumber { get; set; }
        public string Email { get; set; }
        public string ClientReferenceNumber { get; set; }
        public string ClientMembershipKey { get; set; }
        public bool IsActive { get; set; }
        public Nullable<int> CreateBatchID { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<int> ModifyBatchID { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public string Note { get; set; }
        public Nullable<int> SourceSystemID { get; set; }
        public string AltMembershipNumber { get; set; }
    
        public virtual ICollection<MemberProduct> MemberProducts { get; set; }
        public virtual SourceSystem SourceSystem { get; set; }
        public virtual ICollection<Vehicle> Vehicles { get; set; }
        public virtual ICollection<MembershipBlackListVendor> MembershipBlackListVendors { get; set; }
        public virtual ICollection<MemberPaymentMethod> MemberPaymentMethods { get; set; }
        public virtual ICollection<Member> Members { get; set; }
    }
}
