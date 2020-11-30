using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities
{
    public class AccessResult
    {
        public string access_token { get; set; }
        public string expires_in { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string MemberNumber { get; set; }
        public long PersonID { get; set; }
        public string token_type { get; set; }
        public string error { get; set; }
        public string error_description { get; set; }
        public string Status { get { return string.IsNullOrEmpty(access_token) ? OperationStatus.ERROR : OperationStatus.SUCCESS; } }
        public string ErrorMessage { get { return error_description; } }
        public string ProductImage { get; set; }
        public bool IsShowMemberList { get; set; }
        public bool IsShowAddMember { get; set; }
        public string MembershipStatus { get; set; }
        public DateTime? MemberSinceDate { get; set; }
        public DateTime? CurrentSubscriptionExpirationDate { get; set; }
        public DateTime? CurrentSubscriptionStartDate { get; set; }
        public string MembershipNumber { get; set; }
        public string PlanName { get; set; }
        public int PlanID { get; set; }
        public string ProductCode { get; set; }
        public bool IsActive { get; set; }
        public string MasterPersonID { get; set; }
        public string MasterMemberNumber { get; set; }
        public string ProgramID { get; set; }
        public bool IsMasterMember { get; set; }
        public string ContactMethod { get; set; }
        public string MemberServicePhoneNumber { get; set; }
        public string DispatchPhoneNumber { get; set; }
        public string BenefitGuidePDF { get; set; }
    }
}
