using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.DAL.Entities
{
    public class MemberModel
    {
        public string ClientReferenceNumber { get; set; }
        public int? Prefix { get; set; }
        public string FirstName { get; set; }
        public string MiddleName { get; set; }
        public string LastName { get; set; }
        public int? Suffix { get; set; }
        public string PhoneNumber { get; set; }
        public int? PhoneType { get; set; }
        //public string Extension { get; set; }
        //public string CountryCode { get; set; }
        
        public string AddressLine1 { get; set; }
        public string AddressLine2 { get; set; }
        public string AddressLine3 { get; set; }
        public string City { get; set; }
        public int? State { get; set; }
        public string PostalCode { get; set; }
        public int? Country { get; set; }
        
        public string Email { get; set; }
        public int? ProgramID { get; set; }
        public int CaseID { get; set; }

        // List of addresses - Original values.
       // public List<AddressEntity> Addresses { get; set; }
        // Values obtained from the view.
       // public List<AddressEntity> InsertedAddresses { get; set; }
        public ProgramDataItemForClientReference_Result ClientReferenceControlData { get; set; }

        public DateTime? EffectiveDate { get; set; }
        public DateTime? ExpirationDate { get; set; }
        public int MemberID { get; set; }

        //NP 8/19 Added inorder to fetch the data while saving Membership Management add member
        public int MembershipID { get; set; }
        public int MemberNumber { get; set; }

        public int? AddressTypeID { get; set; }

        public Dictionary<string, string> DynamicDataElements { get; set; }

        // Name fields.
        public string Country_input { get; set; }
        public string Prefix_input { get; set; }
        public string Suffix_input { get; set; }
        public string ProgramID_input { get; set; }
        public string State_input { get; set; }
        public string PhoneNumber_ddlPhoneType_input { get; set; }
    }
}
