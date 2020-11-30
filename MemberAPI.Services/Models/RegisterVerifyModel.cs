using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services.Models
{
    public class RegisterVerifyModel
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public MembershipService.PhoneNumber CellPhone { get; set; }
        public string Email { get; set; }
    }
}
