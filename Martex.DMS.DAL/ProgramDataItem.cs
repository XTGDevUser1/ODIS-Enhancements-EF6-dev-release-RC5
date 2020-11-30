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
    public partial class ProgramDataItem
    {
    	public ProgramDataItem()
        {
            this.ProgramDataItemValueEntities = new HashSet<ProgramDataItemValueEntity>();
            this.ProgramDataItemValues = new HashSet<ProgramDataItemValue>();
            this.ProgramDataItemLinks = new HashSet<ProgramDataItemLink>();
            this.ProgramDataItemLinks1 = new HashSet<ProgramDataItemLink>();
        }
    
        public int ID { get; set; }
        public int ProgramID { get; set; }
        public Nullable<int> ControlTypeID { get; set; }
        public Nullable<int> DataTypeID { get; set; }
        public string ScreenName { get; set; }
        public string Name { get; set; }
        public string Label { get; set; }
        public Nullable<int> MaxLength { get; set; }
        public int Sequence { get; set; }
        public bool IsRequired { get; set; }
        public bool IsActive { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    
        public virtual ControlType ControlType { get; set; }
        public virtual DataType DataType { get; set; }
        public virtual Program Program { get; set; }
        public virtual ICollection<ProgramDataItemValueEntity> ProgramDataItemValueEntities { get; set; }
        public virtual ICollection<ProgramDataItemValue> ProgramDataItemValues { get; set; }
        public virtual ICollection<ProgramDataItemLink> ProgramDataItemLinks { get; set; }
        public virtual ICollection<ProgramDataItemLink> ProgramDataItemLinks1 { get; set; }
    }
}
