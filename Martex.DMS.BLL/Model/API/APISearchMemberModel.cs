using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL
{
    public class APISearchMembershipModel
    {
        public string CustomerGroupID { get; set; }
        public int? InternalCustomerGroupID { get; set; }
        public List<APISearchMembershipMemberModel> Members { get; set; }
        public List<APISearchMembershipPhoneModel> Phones { get; set; }
        public List<APISearchMembershipAddressModel> Addresses { get; set; }
    }
    public class APISearchMembershipMemberModel
    {
        public int? InternalCustomerID { get; set; }
        public string FirstName { get; set; }
        public string MiddleName { get; set; }
        public string LastName { get; set; }
        public string Prefix { get; set; }
        public string Suffix { get; set; }
        public DateTime? EffectiveDate { get; set; }
        public DateTime? ExpirationDate { get; set; }
        public string Program { get; set; }
        public string CustomerID { get; set; }
        public List<APISearchMembershipVehicleModel> MemberVehicles { get; set; }

    }

    public class APISearchMembershipAddressModel
    {
        public int ID { get; set; }
        public Nullable<int> EntityID { get; set; }
        public Nullable<int> AddressTypeID { get; set; }
        public string Entity { get; set; }
        public string AddressType { get; set; }
        public string Line1 { get; set; }
        public string Line2 { get; set; }
        public string Line3 { get; set; }
        public string City { get; set; }
        public string StateProvince { get; set; }
        public string PostalCode { get; set; }
        public Nullable<int> StateProvinceID { get; set; }
        public Nullable<int> CountryID { get; set; }
        public string CountryCode { get; set; }
    }

    public class APISearchMembershipPhoneModel
    {
        public int ID { get; set; }
        public int EntityID { get; set; }
        public Nullable<int> PhoneTypeID { get; set; }
        public string Entity { get; set; }
        public string PhoneType { get; set; }
        public string PhoneNumber { get; set; }
        public Nullable<int> IndexPhoneNumber { get; set; }
        public Nullable<int> Sequence { get; set; }
    }

    public class APISearchMembershipVehicleModel
    {
        public string VIN { get; set; }
        public string Year { get; set; }
        public string Make { get; set; }
        public string MakeOther { get; set; }
        public string Model { get; set; }
        public string ModelOther { get; set; }
        public string LicenseState { get; set; }
        public string LicenseNumber { get; set; }
        public string Color { get; set; }
        public int? Length { get; set; }
        public string Height { get; set; }
        public string Description { get; set; }
        public string Chassis { get; set; }
        public string Engine { get; set; }
        public int? StartMileage { get; set; }
        public int? EndMileage { get; set; }
        public DateTime? WarrantyStartDate { get; set; }
        public DateTime? WarrantyEndDate { get; set; }
        public int? WarrantyMileage { get; set; }
        public int? WarrantyPeriod { get; set; }
        public string WarrantyPeriodUOM { get; set; }
        public DateTime? PurchaseDate { get; set; }
    }

}
