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
    public partial class GetUsersByNextActionRoles_Result
    {
        public int ID { get; set; }
        public Nullable<int> OrganizationID { get; set; }
        public System.Guid aspnet_UserID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string AgentNumber { get; set; }
        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
        public Nullable<System.DateTime> ModifyDate { get; set; }
        public string ModifyBy { get; set; }
        public string PhoneUserID { get; set; }
        public string PhonePassword { get; set; }
        public Nullable<int> ManagerID { get; set; }
        public Nullable<int> Pin { get; set; }
    }
}
