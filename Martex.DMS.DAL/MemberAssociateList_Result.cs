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
    public partial class MemberAssociateList_Result
    {
        public Nullable<int> TotalRows { get; set; }
        public long RowNum { get; set; }
        public Nullable<int> MembershipID { get; set; }
        public string MemberID { get; set; }
        public string PrimaryMember { get; set; }
        public string MemberName { get; set; }
        public string EffectiveDate { get; set; }
        public string ExpirationDate { get; set; }
        public string MemberStatus { get; set; }
    }
}
