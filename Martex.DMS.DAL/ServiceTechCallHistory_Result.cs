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
    public partial class ServiceTechCallHistory_Result
    {
        public string ContactCategory { get; set; }
        public string CompanyName { get; set; }
        public string PhoneNumber { get; set; }
        public string TalkedTo { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public string ContactReason { get; set; }
        public string ContactAction { get; set; }
        public string Question { get; set; }
        public string Answer { get; set; }
        public string Comments { get; set; }
    }
}
