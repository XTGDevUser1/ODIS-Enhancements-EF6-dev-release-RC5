using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
   public class EmailRegisterModel
    {
        public string Email { get; set; }

        public string MemberNumber { get; set; }

        public System.DateTime NMCPasswordLastChangeDate { get; set; }

        public System.Guid NMCPasswordResetToken { get; set; }

        public System.DateTime NMCPasswordTokenGeneratedOn { get; set; }

        public long NMCPasswordTokenValidityInHours { get; set; }

        public string Password { get; set; }

        public long PersonID { get; set; }

        public long SystemIdentifier { get; set; }

        public string UserID { get; set; }
    }
}
