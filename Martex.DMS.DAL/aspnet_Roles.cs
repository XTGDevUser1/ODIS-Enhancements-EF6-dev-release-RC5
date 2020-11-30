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
    public partial class aspnet_Roles
    {
    	public aspnet_Roles()
        {
            this.AccessControlLists = new HashSet<AccessControlList>();
            this.NextActionRoles = new HashSet<NextActionRole>();
            this.OrganizationRoles = new HashSet<OrganizationRole>();
            this.aspnet_Users = new HashSet<aspnet_Users>();
            this.UserPortletDefaultByRoles = new HashSet<UserPortletDefaultByRole>();
            this.UserInvites = new HashSet<UserInvite>();
            this.ClientRoles = new HashSet<ClientRole>();
        }
    
        public System.Guid RoleId { get; set; }
        public System.Guid ApplicationId { get; set; }
        public string RoleName { get; set; }
        public string LoweredRoleName { get; set; }
        public string Description { get; set; }
    
        public virtual ICollection<AccessControlList> AccessControlLists { get; set; }
        public virtual aspnet_Applications aspnet_Applications { get; set; }
        public virtual ICollection<NextActionRole> NextActionRoles { get; set; }
        public virtual ICollection<OrganizationRole> OrganizationRoles { get; set; }
        public virtual ICollection<aspnet_Users> aspnet_Users { get; set; }
        public virtual ICollection<UserPortletDefaultByRole> UserPortletDefaultByRoles { get; set; }
        public virtual ICollection<UserInvite> UserInvites { get; set; }
        public virtual ICollection<ClientRole> ClientRoles { get; set; }
    }
}
