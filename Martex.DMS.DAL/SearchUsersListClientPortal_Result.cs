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
    public partial class SearchUsersListClientPortal_Result
    {
        public int TotalRows { get; set; }
        public long RowNum { get; set; }
        public Nullable<int> ID { get; set; }
        public Nullable<System.Guid> UserID { get; set; }
        public string UserName { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string OrganizationName { get; set; }
        public string Roles { get; set; }
        public string DataGroups { get; set; }
        public Nullable<bool> IsApproved { get; set; }
        public Nullable<int> DisplayOrder { get; set; }
        public string Email { get; set; }
    }
}
