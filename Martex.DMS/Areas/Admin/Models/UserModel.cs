using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;
using System.Web.Mvc;
using Martex.DMS.Models;

namespace Martex.DMS.Models
{
    /// <summary>
    /// Model for the Users
    /// </summary>
    [Serializable]
    public class RegisterUserModel : RegisterModel
    {
        [Required]
        [Display(Name = "First name")]
        public string FirstName { get; set; }

        [Required]
        [Display(Name = "Last name")]
        public string LastName { get; set; }

        [Required]
        [Display(Name = "Agent Number")]
        public string AgentNumber { get; set; }

        [Display(Name = "OrganizationID")]
        public int? OrganizationID { get; set; }

        public string OrganizationName { get; set; }

        [Display(Name = "User Roles")]
        public string[] UserRoles { get; set; }
        
        public string[] SelectedUserRoles { get; set; }

        [Display(Name = "Data Groups")]
        public int[] DataGroupsID { get; set; }

        public int[] SelectedDataGroupsID { get; set; }

     
        [Required]
        [Display(Name = "Active")]
        public bool Active { get; set; }

        [Required]
        [DataType(DataType.DateTime)]
        [Display(Name = "Last Activity Date")]
        public DateTime LastActivityDate { get; set; }

        
        public int? ID { get; set; }

        [DataType(DataType.DateTime)]
        public DateTime? LastUpdated { get; set; }

        public string ModifiedBy { get; set; }

        public string PhoneUserId { get; set; }
        public string PhonePassword { get; set; }
        public int? Pin { get; set; }
        public bool IsLoggedInUserPasswordExpired { get; set; }

        public bool IsLockedOut { get;set; }
    }
}
