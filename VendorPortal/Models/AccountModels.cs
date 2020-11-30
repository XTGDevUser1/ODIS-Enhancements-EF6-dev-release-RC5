using System;
using System.Collections.Generic;
using da = System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Web.Mvc;
using System.Web.Security;
using Martex.DMS.DAL.Entities;


namespace VendorPortal.Models
{

    public class ChangePasswordModel
    {
        [da.Required]
        [da.DataType(da.DataType.Password)]
        [da.Display(Name = "Current password")]
        public string OldPassword { get; set; }

        [da.Required]
        [da.StringLength(100, ErrorMessage = "The {0} must be at least {2} characters long.", MinimumLength = 6)]
        [da.DataType(da.DataType.Password)]
        [da.Display(Name = "New password")]
        public string NewPassword { get; set; }

        [da.DataType(da.DataType.Password)]
        [da.Display(Name = "Confirm new password")]
        [da.Compare("NewPassword", ErrorMessage = "The new password and confirmation password do not match.")]
        public string ConfirmPassword { get; set; }

        public string UserName { get; set; }

        [da.DataType(da.DataType.EmailAddress)]
        public string Email { get; set; }

        public bool UpdateChangePassVendorUser { get; set; }
    }

    public class LogOnModel
    {
        [da.Required]
        [da.Display(Name = "User name")]
        public string UserName { get; set; }

        [da.Required]
        [da.DataType(da.DataType.Password)]
        [da.Display(Name = "Password")]
        public string Password { get; set; }

        [da.Display(Name = "Remember me?")]
        public bool RememberMe { get; set; }

        public string DeviceName { get; set; }
    }

    [Serializable]
    public class RegisterModel
    {
        [da.Required]
        [da.Display(Name = "User name")]
        public string UserName { get; set; }

        [da.DataType(da.DataType.EmailAddress)]
        [da.Display(Name = "Email address")]
        [da.Required(ErrorMessage = "Email is required. ")]
        public string Email { get; set; }

        [da.StringLength(100, ErrorMessage = "The {0} must be at least {2} characters long.", MinimumLength = 6)]
        [da.DataType(da.DataType.Password)]
        [da.Display(Name = "Password")]        
        public string Password { get; set; }

        [da.DataType(da.DataType.Password)]
        [da.Display(Name = "Confirm password")]
        [da.Compare("Password", ErrorMessage = "Password and Confirm Password must match.")]        
        public string ConfirmPassword { get; set; }
    }

    [Serializable]
    public class VendorRegisterModel : RegisterModel
    {
        /// <summary>
        /// Gets or sets the vendor ID.
        /// </summary>
        /// <value>
        /// The vendor ID.
        /// </value>
        public int VendorID { get; set; }
        /// <summary>
        /// Gets or sets the first name.
        /// </summary>
        /// <value>
        /// The first name.
        /// </value>
        [da.Required(ErrorMessage = "First Name is required. ")]
        public string FirstName { get; set; }
        /// <summary>
        /// Gets or sets the last name.
        /// </summary>
        /// <value>
        /// The last name.
        /// </value>
        [da.Required(ErrorMessage = "Last Name is required. ")]
        public string LastName { get; set; }
    }

    [Serializable]
    public class VendorIdentity
    {
        /// <summary>
        /// Gets or sets the vendor number.
        /// </summary>
        /// <value>
        /// The vendor number.
        /// </value>
        [da.Required]
        public string VendorNumber { get; set; }

        /// <summary>
        /// Gets or sets the tax ID.
        /// </summary>
        /// <value>
        /// The tax ID.
        /// </value>
        //[Required]
        public string TaxID { get; set; }

        public string PhoneNumber{ get; set; }
    }

    [Serializable]
    public class UserProfileModel
    {
        public UserInformation UserInformation { get; set; }
        public ChangePasswordModel ChangePasswordModel { get; set; }
    }
}
