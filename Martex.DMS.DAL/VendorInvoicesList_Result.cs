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
    public partial class VendorInvoicesList_Result
    {
        public Nullable<int> TotalRows { get; set; }
        public long RowNum { get; set; }
        public Nullable<int> ID { get; set; }
        public string VendorNumber { get; set; }
        public string PurchaseOrderNumber { get; set; }
        public string POStatus { get; set; }
        public Nullable<System.DateTime> IssueDate { get; set; }
        public Nullable<decimal> PurchaseOrderAmount { get; set; }
        public string InvoiceNumber { get; set; }
        public Nullable<System.DateTime> ReceivedDate { get; set; }
        public Nullable<System.DateTime> InvoiceDate { get; set; }
        public Nullable<decimal> InvoiceAmount { get; set; }
        public string InvoiceStatus { get; set; }
        public Nullable<System.DateTime> ToBePaidDate { get; set; }
        public Nullable<System.DateTime> ExportDate { get; set; }
        public Nullable<System.DateTime> PaymentDate { get; set; }
        public Nullable<decimal> PaymentAmount { get; set; }
        public string PaymentType { get; set; }
        public Nullable<System.DateTime> CheckClearedDate { get; set; }
        public Nullable<int> VendorID { get; set; }
        public string VendorName { get; set; }
        public string VendorInvoiceException { get; set; }
        public Nullable<long> RecivedCount { get; set; }
        public Nullable<long> ReadyForPaymentCount { get; set; }
        public Nullable<long> ExceptionCount { get; set; }
        public Nullable<long> PaidCount { get; set; }
        public Nullable<long> CancelledCount { get; set; }
        public string PaymentNumber { get; set; }
        public string RecieveMethod { get; set; }
    }
}