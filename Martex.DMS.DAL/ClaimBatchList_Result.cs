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
    public partial class ClaimBatchList_Result
    {
        public Nullable<int> TotalRows { get; set; }
        public long RowNum { get; set; }
        public Nullable<int> ID { get; set; }
        public string BatchType { get; set; }
        public Nullable<int> BatchStatusID { get; set; }
        public string BatchStatus { get; set; }
        public Nullable<int> TotalCount { get; set; }
        public Nullable<decimal> TotalAmount { get; set; }
        public Nullable<int> MasterETLLoadID { get; set; }
        public Nullable<int> TransactionETLLoadID { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
    }
}
