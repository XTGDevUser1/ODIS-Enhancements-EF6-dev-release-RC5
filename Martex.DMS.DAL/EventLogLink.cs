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
    public partial class EventLogLink
    {
        public long ID { get; set; }
        public long EventLogID { get; set; }
        public int EntityID { get; set; }
        public Nullable<int> RecordID { get; set; }
    
        public virtual Entity Entity { get; set; }
        public virtual EventLog EventLog { get; set; }
    }
}
