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
    public partial class ACESPaymentList_Result
    {
        public Nullable<int> TotalRows { get; set; }
        public long RowNum { get; set; }
        public Nullable<int> ID { get; set; }
        public string PaymentType { get; set; }
        public string CheckNumber { get; set; }
        public Nullable<System.DateTime> CheckDate { get; set; }
        public Nullable<decimal> TotalAmount { get; set; }
        public Nullable<System.DateTime> RecievedDate { get; set; }
        public string Comment { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string ModifyBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public Nullable<decimal> PaymentBalance { get; set; }
    }
}
