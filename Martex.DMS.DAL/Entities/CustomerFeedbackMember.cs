using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.DAL.Entities
{
    public class CustomerFeedbackMember
    {
        public int MembershipId { get; set; }
        public string MembershipNumber { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }

        public int CustomerFeedbackId { get; set; }
        public string MemberPhoneNumber { get; set; }
        public string MemberEmailAddress { get; set; }
        public string MemberAddressLine1 { get; set; }
        public string MemberAddressLine2 { get; set; }
        public string MemberAddressLine3 { get; set; }
        public string MemberCity { get; set; }

        public string ISOCode { get; set; }
        public string MemberAddressCountryCode { get; set; }
        public int? MemberAddressCountryCodeID { get; set; }
        public string Name { get; set; }
        public string MemberAddressStateProvince { get; set; }
        public int? MemberAddressStateProvinceID { get; set; }
        public string MemberAddressPostalCode { get; set; }

        public Nullable<System.DateTime> CreateDate { get; set; }
        public string CreateBy { get; set; }
    }
}
