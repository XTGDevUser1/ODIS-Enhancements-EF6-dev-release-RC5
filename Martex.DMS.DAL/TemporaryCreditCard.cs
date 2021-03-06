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
    public partial class TemporaryCreditCard
    {
        public int ID { get; set; }
        public string CreditCardIssueNumber { get; set; }
        public string CreditCardNumber { get; set; }
        public Nullable<int> PurchaseOrderID { get; set; }
        public Nullable<int> VendorInvoiceID { get; set; }
        public Nullable<System.DateTime> IssueDate { get; set; }
        public string IssueBy { get; set; }
        public string IssueStatus { get; set; }
        public string ReferencePurchaseOrderNumber { get; set; }
        public string OriginalReferencePurchaseOrderNumber { get; set; }
        public string ReferenceVendorNumber { get; set; }
        public Nullable<decimal> ApprovedAmount { get; set; }
        public Nullable<decimal> TotalChargedAmount { get; set; }
        public Nullable<int> TemporaryCreditCardStatusID { get; set; }
        public string ExceptionMessage { get; set; }
        public string Note { get; set; }
        public Nullable<int> PostingBatchID { get; set; }
        public Nullable<int> AccountingPeriodID { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public Nullable<System.DateTime> LastChargedDate { get; set; }
        public Nullable<bool> IsExceptionOverride { get; set; }
    
        public virtual TemporaryCreditCardStatu TemporaryCreditCardStatu { get; set; }
    }
}
