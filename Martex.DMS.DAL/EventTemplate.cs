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
    public partial class EventTemplate
    {
    	public EventTemplate()
        {
            this.EventSubscriptionRecipients = new HashSet<EventSubscriptionRecipient>();
        }
    
        public int ID { get; set; }
        public int EventID { get; set; }
        public int TemplateID { get; set; }
        public bool IsDefault { get; set; }
    
        public virtual Event Event { get; set; }
        public virtual Template Template { get; set; }
        public virtual ICollection<EventSubscriptionRecipient> EventSubscriptionRecipients { get; set; }
    }
}
