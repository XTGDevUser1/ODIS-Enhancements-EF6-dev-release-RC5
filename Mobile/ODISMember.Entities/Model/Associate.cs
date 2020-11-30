using ODISMember.Entities.Model;
using System;

namespace ODISMember.Entities
{
    public class Associate
    {
        public Associate()
        {

        }

        public PhoneNumberModel CellPhone { get; set; }
        public string DateOfBirth { get; set; }
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string InitalJoinDate { get; set; }
        public bool IsActive { get; set; }
        public string LastName { get; set; }
        public string MemberNumber { get; set; }
        public string MembershipNumber { get; set; }
        public ODISMember.Entities.Constants.MemberType MemberType { get; set; }
        public string MiddleName { get; set; }
        public ODISMember.Entities.Constants.enumPersonRelationship RelationshipType { get; set; }
        public string Suffix { get; set; }
        public long SystemIdentifier { get; set; }
        public byte[] Photo { get; set; }
        public string UserName { get; set; }
        public bool IsRegistered { get; set; }
        public DateTime? EffectiveDate { get; set; }
        public DateTime? ExpirationDate { get; set; }
        /*Extra Properties*/
        public int LocalId { get; set; }
        public string FullName { get { return FirstName + " " + LastName; } }
        public string MemberNumberStringWithTitle { get { return "Member Number: " + MemberNumber; } }
        public string DateOfBirthString
        {
            get { return string.IsNullOrEmpty(DateOfBirth) ? string.Empty : Convert.ToDateTime(DateOfBirth).ToString(ODISMember.Entities.Constants.DateFormat); }
        }
        public string DateOfBirthStringWithTitle
        {
            get { return string.IsNullOrEmpty(DateOfBirth) ? "Date of Birth: " : "Date of Birth: " + Convert.ToDateTime(DateOfBirth).ToString(ODISMember.Entities.Constants.DateFormat); }
        }
        public Nullable<DateTime> DateOfBirthInDateTime
        {
            get { return string.IsNullOrEmpty(DateOfBirth) ? (DateTime?)null : Convert.ToDateTime(DateOfBirth); }
            set { DateOfBirth = value.ToString(); }
        }


    }
}

