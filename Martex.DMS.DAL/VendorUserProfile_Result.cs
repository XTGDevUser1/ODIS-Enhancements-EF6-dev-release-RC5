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
    public partial class VendorUserProfile_Result
    {
        public string VendorServicesPhoneNumber { get; set; }
        public string VendorServicesFaxNumber { get; set; }
        public string FirstName { get; set; }
        public string Email { get; set; }
        public string LastName { get; set; }
        public int VendorUserID { get; set; }
        public Nullable<int> PostLoginPromptID { get; set; }
        public Nullable<bool> ChangePassword { get; set; }
        public Nullable<bool> ReceiveNotification { get; set; }
        public string VendorName { get; set; }
        public string VendorNumber { get; set; }
        public bool VendorIsActive { get; set; }
        public string VendorRegionContactFirstName { get; set; }
        public string VendorRegionContactLastName { get; set; }
        public string VendorRegionEmail { get; set; }
        public string VendorRegionPhoneNumber { get; set; }
        public string VendorRegionName { get; set; }
        public int VendorID { get; set; }
        public System.Guid UserId { get; set; }
        public Nullable<bool> IsVendorLockedOut { get; set; }
    }
}
