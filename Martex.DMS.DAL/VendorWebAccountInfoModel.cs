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
    public partial class VendorWebAccountInfoModel
    {
        public Nullable<int> VendorID { get; set; }
        public string Username { get; set; }
        public string FirstLastName { get; set; }
        public string Email { get; set; }
        public System.DateTime LastActivityDate { get; set; }
        public System.DateTime LastPasswordChangedDate { get; set; }
        public bool IsApproved { get; set; }
        public bool IsLockedOut { get; set; }
        public string LegacyUsername { get; set; }
        public string LegacyPassword { get; set; }
        public System.Guid ApplicationId { get; set; }
        public System.Guid UserId { get; set; }
    }
}
