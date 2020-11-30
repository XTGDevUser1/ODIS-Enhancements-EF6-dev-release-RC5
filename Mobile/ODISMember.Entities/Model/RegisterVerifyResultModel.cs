using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
   public class RegisterVerifyResultModel
    {
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public PhoneNumberModel CellPhone { get; set; }
        public string Email { get; set; }
        public string MemberNumber { get; set; }
    }
}
