using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MemberAPI.Models
{
    public class MemberDependentModel
    {
        public string DateOfBirth { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public bool Inactivate { get; set; }
        public string MemberNumber { get; set; }
    }
}