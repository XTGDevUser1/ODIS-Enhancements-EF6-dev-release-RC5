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
    public partial class ProgramDataItemValue
    {
    	public ProgramDataItemValue()
        {
            this.ProgramDataItemLinks = new HashSet<ProgramDataItemLink>();
        }
    
        public int ID { get; set; }
        public int ProgramDataItemID { get; set; }
        public string Value { get; set; }
        public string Description { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    
        public virtual ProgramDataItem ProgramDataItem { get; set; }
        public virtual ICollection<ProgramDataItemLink> ProgramDataItemLinks { get; set; }
    }
}
