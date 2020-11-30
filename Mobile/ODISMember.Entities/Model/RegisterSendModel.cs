using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
   public class RegisterSendModel
    {
        public string MembershipNumber { get; set; }
        public RegisterUserInfo ObjWebUser { get; set; }
        public string OldPassword { get; set; }
    }
}
