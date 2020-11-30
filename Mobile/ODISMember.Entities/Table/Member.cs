using SQLite.Net.Attributes;
using System;
namespace ODISMember.Entities
{
    public class Member
    {
        [PrimaryKey, AutoIncrement]
        public int Id { get; set; }
        public string AccessToken { get; set; }
        public string TokenType { get; set; }
        public string ExpiresIn { get; set; }
        public string MemberNumber { get; set; }
        public string MembershipNumber { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public int PlanID { get; set; }
        public string PlanName { get; set; }
        public string ProductCode { get; set; }
        public string PostalCode { get; set; }
        public string UserName { get; set; }
        public string Password { get; set; }
        public long PersonID { get; set; }
        public string MembershipStatus { get; set; }
        public DateTime? MemberSinceDate { get; set; }
        public DateTime? CurrentSubscriptionExpirationDate { get; set; }
        public DateTime? CurrentSubscriptionStartDate { get; set; }
        public bool IsActive { get; set; }
        public string MasterPersonID { get; set; }
        public string MasterMemberNumber { get; set; }
        public string ProgramID { get; set; }
        public bool IsMasterMember { get; set; }
        public bool IsShowMemberList { get; set; }
        public bool IsShowAddMember { get; set; }
        public string ContactMethod { get; set; }
        public DateTime CreatedOn { get; set; }
        public string MemberServicePhoneNumber { get; set; }
        public string BenefitGuidePDF { get; set; }
        public string DispatchPhoneNumber { get; set; }
        public string ProductImage { get; set; }
    }
}


