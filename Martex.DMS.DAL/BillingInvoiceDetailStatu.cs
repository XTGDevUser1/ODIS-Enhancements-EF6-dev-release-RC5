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
    public partial class BillingInvoiceDetailStatu
    {
    	public BillingInvoiceDetailStatu()
        {
            this.BillingDefinitionInvoiceLineEvents = new HashSet<BillingDefinitionInvoiceLineEvent>();
            this.BillingInvoiceDetails = new HashSet<BillingInvoiceDetail>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
    
        public virtual ICollection<BillingDefinitionInvoiceLineEvent> BillingDefinitionInvoiceLineEvents { get; set; }
        public virtual ICollection<BillingInvoiceDetail> BillingInvoiceDetails { get; set; }
    }
}
