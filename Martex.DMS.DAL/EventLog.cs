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
    public partial class EventLog
    {
    	public EventLog()
        {
            this.EventLogLinks = new HashSet<EventLogLink>();
        }
    
        public long ID { get; set; }
        public int EventID { get; set; }
        public string SessionID { get; set; }
        public string Source { get; set; }
        public string Description { get; set; }
        public string Data { get; set; }
        public Nullable<System.DateTime> NotificationQueueDate { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
    
        public virtual Event Event { get; set; }
        public virtual ICollection<EventLogLink> EventLogLinks { get; set; }
    }
}
