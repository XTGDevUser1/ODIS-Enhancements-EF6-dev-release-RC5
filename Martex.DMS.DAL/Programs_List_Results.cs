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
    public partial class Programs_List_Results
    {
        public int TotalRows { get; set; }
        public long RowNum { get; set; }
        public Nullable<int> ID { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string ClientID { get; set; }
        public string ParentProgramID { get; set; }
        public Nullable<decimal> CallFee { get; set; }
        public Nullable<decimal> DispatchFee { get; set; }
        public Nullable<bool> IsActive { get; set; }
    }
}