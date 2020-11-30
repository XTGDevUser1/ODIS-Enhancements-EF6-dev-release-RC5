using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using Newtonsoft.Json;

namespace Martex.DMS.DAL.Entities
{
    public class MemberShipInfoDetails
    {
        public int MasterMemberID { get; set; }
        public int MembershipID { get; set; }
        public string Name { get; set; }
        public int? ClientID { get; set; }
        public int? ProgramID { get; set; }
        public string MemberShipNumber { get; set; }
        public int? PrefixID { get; set; }
        public string PrefixName { get; set; }
        public string FirstName { get; set; }
        public string MiddleName { get; set; }
        public string LastName { get; set; }
        public int? SuffixID { get; set; }
        public string SuffixName { get; set; }
        public string Email { get; set; }
        public string ClientReference { get; set; }

        public bool IsDeliveryDriver { get; set; }
        public DateTime? MemberSince { get; set; }
        public DateTime? EffectiveDate { get; set; }
        public DateTime? ExpirationDate { get; set; }
        public string MemberNote { get; set; }

        public string CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
        public string ModifiedBy { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public int? SourceID { get; set; }
        public string SourceSystemName { get; set; }

        public bool IsMemberExpired
        {
            get
            {
                if (this.ExpirationDate.HasValue)
                {
                    if (this.ExpirationDate.Value <= DateTime.Now)
                    {
                        return true;
                    }
                    return false;
                }
                return false;
            }
        }

        public string MemberReferenceProgram { get; set; }
        //NP: Added to use in Add Member for Membership
        public string ClientName { get; set; }

    }

    public class MemberInfoDetails
    {
        public int MembershipID { get; set; }

        public DateTime? MemberSince { get; set; }
        public DateTime? EffectiveDate { get; set; }
        public DateTime? ExpirationDate { get; set; }
        public bool IsMemberExpired
        {
            get
            {
                if (this.ExpirationDate.HasValue)
                {
                    if (this.ExpirationDate.Value <= DateTime.Now)
                    {
                        return true;
                    }
                    return false;
                }
                return false;
            }
        }
        public int MemberID { get; set; }
        public int? ClientID { get; set; }
        public int? ProgramID { get; set; }
        public string ProgramReference { get; set; }
        public string MembershipNumber { get; set; }
        public string ClientReference { get; set; }
        public int? PrefixID { get; set; }
        public string PrefixName { get; set; }
        public string FirstName { get; set; }
        public string MiddleName { get; set; }
        public string LastName { get; set; }
        public int? SuffixID { get; set; }
        public string SuffixName { get; set; }
        public string Email { get; set; }
        public string CreatedBy { get; set; }
        public DateTime? CreatedOn { get; set; }
        public string ModifiedBy { get; set; }
        public DateTime? ModifiedOn { get; set; }
        public string SourceSystemName { get; set; }
        public int? SourceID { get; set; }
    }

    public class MembershipAddModel
    {
        public Membership MembershipInformation { get; set; }
        public Member MemberInformation { get; set; }
        public AddressEntity AddressInformation { get; set; }
        public PhoneEntity PhoneInfomation { get; set; }
        public int? ClientID { get; set; }
        public int? PrefixID { get; set; }
        public int? SuffixID { get; set; }
    }


    public class MemberApiModel
    {
        #region Basic Details
        [Required, MaxLength(25)]
        public string CustomerID { get; set; }
        [MaxLength(25)]
        public string CustomerGroupID { get; set; }
        public bool? IsPrimary { get; set; }
        [Required, Range(0, 9999999999)]
        public int? ProgramID { get; set; }
        [MaxLength(50)]
        public string FirstName { get; set; }
        [MaxLength(50)]
        public string MiddleName { get; set; }
        [MaxLength(50)]
        public string LastName { get; set; }
        [MaxLength(255)]
        public string Email { get; set; }        
        public DateTime? EffectiveDate { get; set; }        
        public DateTime? ExpirationDate { get; set; }
        #endregion

        #region AddressDetails
        [MaxLength(100)]
        public string Address1 { get; set; }
        [MaxLength(100)]
        public string Address2 { get; set; }
        [MaxLength(100)]
        public string City { get; set; }
        [MaxLength(2)]
        public string StateProvince { get; set; }
        [MaxLength(20)]
        public string PostalCode { get; set; }
        [MaxLength(2)]
        public string CountryCode { get; set; }
        #endregion

        #region Phone Details
        //[Range(0, 9999999999)]
        public string PhoneCountryCode { get; set; }
        public string PhoneNumber { get; set; }
        [MaxLength(20)]
        public string PhoneType { get; set; }
        //[Range(0, 9999999999)]
        public string AltPhoneCountryCode { get; set; }
        public string AltPhoneNumber { get; set; }
        [MaxLength(20)]
        public string AltPhoneType { get; set; }
        #endregion

        #region Vehicle Details
        [MaxLength(17)]
        public string VehicleVIN { get; set; }
        [MaxLength(20)]
        public string VehicleType { get; set; }
        [Range(0, 9999)]
        public int? VehicleYear { get; set; }
        [MaxLength(50)]
        public string VehicleMake { get; set; }
        [MaxLength(50)]
        public string VehicleModel { get; set; }
        [MaxLength(50)]
        public string VehicleColor { get; set; }
        [Range(0, 9999999999)]
        public int? VehicleWarrantyPeriod { get; set; }
        [MaxLength(20)]
        public string VehicleWarrantyPeriodUOM { get; set; }
        [Range(0, 9999999999)]
        public int? VehicleWarrantyMiles { get; set; }
        [MaxLength(20)]
        public string VehicleWarrantyMilesUOM { get; set; }
        [Range(0, 9999999999)]
        public int? VehicleCurrentMileage { get; set; }
        #endregion

        #region Additional Properties
        [JsonIgnore]
        public int? PrimaryContactPhoneTypeID { get; set; }
        public string PrimaryFormattedPhoneNumber { get; set; }
        [JsonIgnore]
        public int? AltContactPhoneTypeID { get; set; }
        public string AltFormattedPhoneNumber { get; set; }

        public int? InternalCustomerGroupID { get; set; }
        public int? InternalCustomerID { get; set; }
        [JsonIgnore]
        public int? AddressEntityID { get; set; }
        [JsonIgnore]
        public int? PrimaryPhoneEntityID { get; set; }
        [JsonIgnore]
        public int? AltPhoneEntityID { get; set; }
        [JsonIgnore]
        public int? VehicleID { get; set; }
        [JsonIgnore]
        public int? ClientID { get; set; }

        public string VehicleMakeOther { get; set; }
        public string VehicleModelOther { get; set; }
        [JsonIgnore]
        public int? VehicleTypeID { get; set; }
        [JsonIgnore]
        public int? VehicleCategoryID { get; set; }

        [JsonIgnore]
        public int? RVTypeID { get; set; }

        // Additional vehicle fields
        public string VehicleChassis { get; set; }
        public string VehicleEngine { get; set; }
        public string LicenseState { get; set; }
        public string LicenseNumber { get; set; }
        public string LicenseCountry { get; set; }
        #endregion

        public string CurrentUser { get; set; }
    }

    public class MemberApiSaveReturnModel
    {
        public int? InternalCustomerGroupID { get; set; }
        public int? InternalCustomerID { get; set; }
    }

    public class MemberApiReturnModel
    {
        public Membership Membership { get; set; }
        public Member Member { get; set; }
        public AddressEntity AddressEntity { get; set; }
        public PhoneEntity PrimaryPhoneEntity { get; set; }
        public PhoneEntity AltPhoneEntity { get; set; }
        public Vehicle Vehicle { get; set; }
    }

    public class DeviceRegisterModel
    {
        public string DeviceOS { get; set; }
        public List<string> Tags { get; set; }
    }
}
