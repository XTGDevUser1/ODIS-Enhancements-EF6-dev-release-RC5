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
    public partial class TemporaryCreditCardDetail
    {
        public int ID { get; set; }
        public int TemporaryCreditCardID { get; set; }
        public Nullable<int> TransactionSequence { get; set; }
        public Nullable<System.DateTime> TransactionDate { get; set; }
        public string TransactionType { get; set; }
        public string TransactionBy { get; set; }
        public Nullable<decimal> RequestedAmount { get; set; }
        public Nullable<decimal> ApprovedAmount { get; set; }
        public Nullable<decimal> AvailableBalance { get; set; }
        public Nullable<System.DateTime> ChargeDate { get; set; }
        public Nullable<decimal> ChargeAmount { get; set; }
        public string ChargeDescription { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    }
}
