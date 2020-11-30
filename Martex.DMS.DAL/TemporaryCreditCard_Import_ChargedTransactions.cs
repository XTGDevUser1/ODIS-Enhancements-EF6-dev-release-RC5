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
    public partial class TemporaryCreditCard_Import_ChargedTransactions
    {
        public long RecordID { get; set; }
        public Nullable<System.Guid> ProcessIdentifier { get; set; }
        public Nullable<int> TemporaryCreditCardID { get; set; }
        public Nullable<int> TemporaryCreditCardDetailsID { get; set; }
        public string FINVirtualCardNumber_C_CreditCardNumber { get; set; }
        public string FINCFFData02_C_OriginalReferencePurchaseOrderNumber { get; set; }
        public Nullable<int> TransactionSequence { get; set; }
        public System.DateTime FINTransactionDate_C_IssueDate_TransactionDate { get; set; }
        public string TransactionType { get; set; }
        public string TransactionBy { get; set; }
        public Nullable<decimal> RequestedAmount { get; set; }
        public Nullable<decimal> ApprovedAmount { get; set; }
        public Nullable<decimal> AvailableBalance { get; set; }
        public System.DateTime FINPostingDate_ChargeDate { get; set; }
        public decimal FINTransactionAmount_ChargeAmount { get; set; }
        public string FINTransactionDescription_ChargeDescription { get; set; }
        public System.DateTime CreateDate { get; set; }
        public string CreatedBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifiedBy { get; set; }
        public string ExceptionMessage { get; set; }
    }
}