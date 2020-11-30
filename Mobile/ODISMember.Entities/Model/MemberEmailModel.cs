using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class MemberEmailModel
    {
        public EmailRegisterModel ObjWebUser { get; set; }
        public Constants.enumMemberEmailType EmailType { get; set; }
    }
}
