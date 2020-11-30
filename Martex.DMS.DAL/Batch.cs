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
    public partial class Batch
    {
    	public Batch()
        {
            this.Claims = new HashSet<Claim>();
        }
    
        public int ID { get; set; }
        public int BatchTypeID { get; set; }
        public Nullable<int> BatchStatusID { get; set; }
        public string Direction { get; set; }
        public string Description { get; set; }
        public Nullable<int> TotalCount { get; set; }
        public Nullable<decimal> TotalAmount { get; set; }
        public Nullable<int> MasterETLLoadID { get; set; }
        public Nullable<int> TransactionETLLoadID { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    
        public virtual BatchType BatchType { get; set; }
        public virtual ICollection<Claim> Claims { get; set; }
    }
}