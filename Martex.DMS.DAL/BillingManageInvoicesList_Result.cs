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
    
    [Serializable] 
    public partial class BillingManageInvoicesList_Result
    {
        public Nullable<int> TotalRows { get; set; }
        public long RowNum { get; set; }
        public Nullable<int> ID { get; set; }
        public string InvoiceDescription { get; set; }
        public Nullable<int> BillingScheduleID { get; set; }
        public string BillingSchedule { get; set; }
        public string BillingScheduleTypeID { get; set; }
        public string BillingScheduleType { get; set; }
        public Nullable<System.DateTime> ScheduleDate { get; set; }
        public Nullable<System.DateTime> ScheduleRangeBegin { get; set; }
        public Nullable<System.DateTime> ScheduleRangeEnd { get; set; }
        public string InvoiceNumber { get; set; }
        public Nullable<System.DateTime> InvoiceDate { get; set; }
        public Nullable<int> InvoiceStatusID { get; set; }
        public string InvoiceStatus { get; set; }
        public Nullable<int> TotalDetailCount { get; set; }
        public Nullable<decimal> TotalDetailAmount { get; set; }
        public Nullable<int> ReadyToBillCount { get; set; }
        public Nullable<decimal> ReadyToBillAmount { get; set; }
        public Nullable<int> PendingCount { get; set; }
        public Nullable<decimal> PendingAmount { get; set; }
        public Nullable<int> ExcludedCount { get; set; }
        public Nullable<decimal> ExceptionAmount { get; set; }
        public Nullable<int> ExceptionCount { get; set; }
        public Nullable<decimal> ExcludedAmount { get; set; }
        public Nullable<int> OnHoldCount { get; set; }
        public Nullable<decimal> OnHoldAmount { get; set; }
        public Nullable<int> PostedCount { get; set; }
        public Nullable<decimal> PostedAmount { get; set; }
        public Nullable<int> BillingDefinitionInvoiceID { get; set; }
        public Nullable<int> ClientID { get; set; }
        public string InvoiceName { get; set; }
        public string PONumber { get; set; }
        public string AccountingSystemCustomerNumber { get; set; }
        public string ClientName { get; set; }
        public Nullable<bool> CanAddLines { get; set; }
        public string BilingScheduleStatus { get; set; }
        public Nullable<int> ScheduleDateTypeID { get; set; }
        public Nullable<int> ScheduleRangeTypeID { get; set; }
        public string AccountingSystemAddressCode { get; set; }
    }
}
