using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;
using System.Web.Mvc;
//using Martex.DMS.DAL;

namespace VendorPortal.Models
{
    [Serializable]
    public class RegisterUserModel : RegisterModel
    {
        [Required]
        [Display(Name = "First name")]
        public string FirstName { get; set; }

        [Required]
        [Display(Name = "Last name")]
        public string LastName { get; set; }

        public int? VendorUserID { get; set; }

        public string VendorName { get; set; }

        [Required]
        public int? VendorID { get; set; }

        [Display(Name = "User Roles")]
        public string[] UserRoles { get; set; }

        public string[] SelectedUserRoles { get; set; }
        public string UserRoleName { get; set; }

        public bool IsAdmin { get; set; }

        [Required]
        [Display(Name = "Active")]
        public bool Active { get; set; }
        public bool IsVendorLockedOut { get; set; }
        [Required]
        [DataType(DataType.DateTime)]
        [Display(Name = "Last Activity Date")]
        public DateTime LastActivityDate { get; set; }


        public int? ID { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? LastUpdated { get; set; }

        public string ModifiedBy { get; set; }

        public int? PostLoginPromptID { get; set; }

        public bool? ChangePassowrd { get; set; }
        public string VendorNumber { get; set; }

        public bool? ReceiveNotification { get; set; }

        public string VendorRegionName { get; set; }
        public string VendorRegionContactFirstName { get; set; }
        public string VendorRegionContactLastName { get; set; }
        public string VendorRegionEmail { get; set; }
        public string VendorRegionPhoneNumber { get; set; }
        public string VendorRegionOfficeNumber { get; set; }
        public string VendorRegionFaxNumber { get; set; }
        public DateTime? InsuranceExpirationDate { get; set; }
    }
}