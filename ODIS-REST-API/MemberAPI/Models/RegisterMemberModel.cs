using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using MemberAPI.Services.MembershipService;

namespace MemberAPI.Models
{
    public class RegisterMemberModel
    {
        public string MembershipNumber { get; set; }
        public WebUser ObjWebUser { get; set; }
    }

    public class VerifyRegistrationModel
    {
        public string MemberNumber { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
    }

    public class ResetPasswordModel
    {
        public string Email { get; set; }
        //public string Password { get; set; }
        //public string ContactMethod { get; set; }
    }

    public class ChangePasswordModel
    {        
        public WebUser ObjWebUser { get; set; }
        public string OldPassword { get; set; }
    }

    public class UserMemberNumber
    {
        public string Email { get; set; }
    }

    public class ChangePasswordTokenModel
    {
        public Guid PasswordResetToken { get; set; }
        public string NewPassword { get; set; }
    }
}