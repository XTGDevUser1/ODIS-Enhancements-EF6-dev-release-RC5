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
    public partial class ChangeLogMapping
    {
    	public ChangeLogMapping()
        {
            this.ClientChangeLogMappings = new HashSet<ClientChangeLogMapping>();
        }
    
        public int ID { get; set; }
        public Nullable<int> EntityID { get; set; }
        public string ColumnName { get; set; }
        public bool IsActive { get; set; }
    
        public virtual Entity Entity { get; set; }
        public virtual ICollection<ClientChangeLogMapping> ClientChangeLogMappings { get; set; }
    }
}