using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class MemberInformation
    {
        public int MembershipID { get; set; }
        public string MembershipNumber { get; set; }
        public string MembershipStatus { get; set; }
        public string Program { get; set; }
        public int? ProgramID { get; set; }
        public string Line1 { get; set; }
        public string CityStateZip { get; set; }
        public string PhoneNumber	{ get; set; }
        public string Email	{ get; set; }
        public int MemberID	{ get; set; }
        public string MasterMember	{ get; set; }
        public string MemberName	{ get; set; }
        public string MemberStatus	{ get; set; }
        public DateTime? MemberExpireDate { get; set; }
    }

    public class MembershipContactInformation
    {
        public int MemberID { get; set; }
        public int MemberShipID { get; set; }
        public int AddressID { get; set; }
        public int AddressTypeID { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public PhoneEntity CallbackNumber { get; set; }
        public PhoneEntity AlternateCallbackNumber { get; set; }
        public string Address1 { get; set; }
        public string Address2 { get; set; }
        public string Address3 { get; set; }
        public string City { get; set; }
        public int? StateProvinceID { get; set; }
        public string Zip { get; set; }
        public int? CountryID { get; set; }
        public PhoneEntity HomePhone { get; set; }
        public PhoneEntity CellPhone { get; set; }
        public PhoneEntity WorkPhone { get; set; }
        public string Email { get; set; }
        public bool IsDeliveryDriver { get; set; }
    }

    public class MemberDetailsModel
    {
        public bool IsMemberNameEdit { get; set; }
        public MemberContactInformation_Result MembershipContactInformation { get; set; }
        public List<MemberAssociateList_Result> MemberAssociateList { get; set; }
        public List<MemberServiceRequestHistory_Result> ServiceRequestHistory { get; set; }
        public MembsershipInformation_Result MembershipInformation { get; set; }
        public List<MemberProducts_Result> MemberProductsList { get; set; }
    }

}
