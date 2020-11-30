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
    public partial class CustomerFeedbackSource
    {
    	public CustomerFeedbackSource()
        {
            this.CustomerFeedbackSourcePriorities = new HashSet<CustomerFeedbackSourcePriority>();
            this.CustomerFeedbacks = new HashSet<CustomerFeedback>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public int IsActive { get; set; }
        public Nullable<int> Sequence { get; set; }
    
        public virtual ICollection<CustomerFeedbackSourcePriority> CustomerFeedbackSourcePriorities { get; set; }
        public virtual ICollection<CustomerFeedback> CustomerFeedbacks { get; set; }
    }
}