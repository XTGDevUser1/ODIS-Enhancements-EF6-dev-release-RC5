//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Martex.DMS.DAL
{
    using System;
    
    [Serializable] 
    public partial class Member_Information_Result
    {
        public Nullable<int> MembershipID { get; set; }
        public string ClientMemberType { get; set; }
        public string MembershipNumber { get; set; }
        public string MembershipStatus { get; set; }
        public string Program { get; set; }
        public Nullable<int> ProgramID { get; set; }
        public string Line1 { get; set; }
        public string HomePhoneNumber { get; set; }
        public string WorkPhoneNumber { get; set; }
        public string CellPhoneNumber { get; set; }
        public string CityStateZip { get; set; }
        public string CountryName { get; set; }
        public string Email { get; set; }
        public int MemberID { get; set; }
        public string MasterMember { get; set; }
        public string MemberName { get; set; }
        public string MemberStatus { get; set; }
        public Nullable<System.DateTime> ExpirationDate { get; set; }
        public Nullable<System.DateTime> EffectiveDate { get; set; }
        public Nullable<int> ClientID { get; set; }
        public string ClientName { get; set; }
        public string MembershipNote { get; set; }
        public string FirstName { get; set; }
        public string MiddleName { get; set; }
        public string LastName { get; set; }
        public string Suffix { get; set; }
        public string Prefix { get; set; }
        public string AltMembershipNumber { get; set; }
    }
}
