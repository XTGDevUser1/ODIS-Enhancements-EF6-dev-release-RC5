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
    public partial class CallType
    {
    	public CallType()
        {
            this.Cases = new HashSet<Case>();
            this.InboundCalls = new HashSet<InboundCall>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Nullable<int> ContactCategoryID { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
    
        public virtual ContactCategory ContactCategory { get; set; }
        public virtual ICollection<Case> Cases { get; set; }
        public virtual ICollection<InboundCall> InboundCalls { get; set; }
    }
}