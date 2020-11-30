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
    public partial class RateType
    {
    	public RateType()
        {
            this.BillingDefinitionInvoiceLines = new HashSet<BillingDefinitionInvoiceLine>();
            this.BillingInvoiceLines = new HashSet<BillingInvoiceLine>();
            this.ContractRateScheduleProducts = new HashSet<ContractRateScheduleProduct>();
            this.ContractRateScheduleProductLogs = new HashSet<ContractRateScheduleProductLog>();
            this.MarketLocationProductRates = new HashSet<MarketLocationProductRate>();
            this.ProductRateTypes = new HashSet<ProductRateType>();
        }
    
        public int ID { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string UnitOfMeasure { get; set; }
        public string UnitOfMeasureSource { get; set; }
        public Nullable<int> Sequence { get; set; }
        public Nullable<bool> IsActive { get; set; }
    
        public virtual ICollection<BillingDefinitionInvoiceLine> BillingDefinitionInvoiceLines { get; set; }
        public virtual ICollection<BillingInvoiceLine> BillingInvoiceLines { get; set; }
        public virtual ICollection<ContractRateScheduleProduct> ContractRateScheduleProducts { get; set; }
        public virtual ICollection<ContractRateScheduleProductLog> ContractRateScheduleProductLogs { get; set; }
        public virtual ICollection<MarketLocationProductRate> MarketLocationProductRates { get; set; }
        public virtual ICollection<ProductRateType> ProductRateTypes { get; set; }
    }
}