using System;
using System.Text.RegularExpressions;

namespace ODISMember.Entities
{
    public class MemberDetailModel
    {
        public string NMCMemberNumber { get; set; }

        public int IsPrimary { get; set; }

        public Nullable<int> PlanID { get; set; }

        public string PlanName { get; set; }

        public string FirstName { get; set; }

        public string MiddleName { get; set; }

        public string LastName { get; set; }

        public string Suffix { get; set; }

        public string AddressLine1 { get; set; }

        public string AddressLine2 { get; set; }

        public string City { get; set; }

        public string StateProvince { get; set; }

        public string PostalCode { get; set; }

        public string CountryCode { get; set; }

        public string HomePhoneTypeCode { get; set; }

        public string HomePhoneCountryCode { get; set; }

        public string HomePhoneAreaCode { get; set; }

        public string HomePhone { get; set; }

        public string CellPhoneTypeCode { get; set; }

        public string CellPhoneCountryCode { get; set; }

        public string CellPhoneAreaCode { get; set; }

        public string CellPhone { get; set; }

        public string Email1 { get; set; }

        public Nullable<System.DateTime> DateOfBirth { get; set; }
        public Nullable<System.DateTime> EffectiveDate { get; set; }

        public Nullable<System.DateTime> ExpirationDate { get; set; }

        public Nullable<System.DateTime> MemberSinceDate { get; set; }
        public string NMCMemberNumberString
        {
            get { return "Member #: " + NMCMemberNumber; }
        }
        public string AddressLineString2
        {
            get { return City + ", " + StateProvince + " " + PostalCode; }
        }

        public string FullName { get { return this.Suffix.Trim() + this.FirstName.Trim() + " " + this.LastName.Trim(); } }

        public string DateOfBirthString { get { return (DateOfBirth != null) ? DateOfBirth.Value.ToString(ODISMember.Entities.Constants.DateFormat) : string.Empty; } }

        public string EffectiveDateString { get { return (EffectiveDate != null) ? EffectiveDate.Value.ToString(ODISMember.Entities.Constants.DateFormat) : string.Empty; } }

        public string ExpirationDateString {
            get {
                return (ExpirationDate != null) ? "Expiration: " + ExpirationDate.Value.ToString(ODISMember.Entities.Constants.DateFormat) : string.Empty;
            }
        }

        public string MemberSinceDateString { get { return (MemberSinceDate != null) ? MemberSinceDate.Value.ToString(ODISMember.Entities.Constants.DateFormat) : string.Empty; } }

        public string HomePhoneString { get { return (string.IsNullOrEmpty(this.HomePhoneAreaCode) && string.IsNullOrEmpty(this.HomePhone)) ? string.Empty :  String.Format("{0:(###) ###-####}", double.Parse(this.HomePhoneAreaCode.Trim() + this.HomePhone.Trim())); } }
    }

}

