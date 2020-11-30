using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
   public class RegisterUserInfo
    {
        public int SystemIdentifier { get; set; }
        public string UserID { get; set; }
        public string Password { get; set; }
        public int PersonID { get; set; }
        public string MemberNumber { get; set; }
        public PhoneNumberModel CellPhone { get; set; }
        public string Email { get; set; }
        public string NmcPasswordResetToken { get; set; }
        public string NmcPasswordTokenGeneratedOn { get; set; }
        public int NmcPasswordTokenValidityInHours { get; set; }
        public string NmcPasswordLastChangeDate { get; set; }
    }
}
