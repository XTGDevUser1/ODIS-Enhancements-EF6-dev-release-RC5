using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services.Models
{
    public class MemberEmailModel
    {
        public MembershipService.WebUser ObjWebUser { get; set; }
        public MembershipService.enumMemberEmailType EmailType { get; set; }
    }
}
