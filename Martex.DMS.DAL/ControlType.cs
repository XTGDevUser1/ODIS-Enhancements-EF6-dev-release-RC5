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
    public partial class ControlType
    {
    	public ControlType()
        {
            this.ApplicationConfigurations = new HashSet<ApplicationConfiguration>();
            this.ProgramConfigurations = new HashSet<ProgramConfiguration>();
            this.ProgramDataItems = new HashSet<ProgramDataItem>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string Class { get; set; }
        public string Icon { get; set; }
        public string Color { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
    
        public virtual ICollection<ApplicationConfiguration> ApplicationConfigurations { get; set; }
        public virtual ICollection<ProgramConfiguration> ProgramConfigurations { get; set; }
        public virtual ICollection<ProgramDataItem> ProgramDataItems { get; set; }
    }
}
