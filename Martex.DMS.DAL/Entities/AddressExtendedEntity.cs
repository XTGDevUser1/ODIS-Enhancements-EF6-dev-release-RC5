using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.Entities
{
    public class GenericAddressEntityModel
    {
        private AddressRepository repository = new AddressRepository();

        public int RecordID { get; set; }
        public string EntityName { get; set; }
        public int Height { get; set; }
        public bool IsReadOnly { get; set; }
        public bool IsVendorPortal { get; set; }

        public List<AddressExtendedEntity> Address
        {
            get
            {
                if (this.RecordID > 0 && !string.IsNullOrEmpty(this.EntityName))
                {
                    string[] excludedTypes = null;
                    if (this.EntityName.Equals(EntityNames.VENDOR))
                    {
                        excludedTypes = new string[] { AddressTypeNames.BANK, AddressTypeNames.Insurance };
                    }
                    if (this.EntityName.Equals(EntityNames.VENDOR) && IsVendorPortal)
                    {
                        excludedTypes = new string[] { AddressTypeNames.BANK, AddressTypeNames.Insurance, AddressTypeNames.LEVY };
                    }
                    return repository.GetGenericAddressBy(this.RecordID, this.EntityName, excludedTypes);
                }
                return null;
            }
        }
    }

    public class AddressExtendedEntity
    {
        private string _StateProvince;
        private string _CountryCode;
        public int AddressID { get; set; }

        public int EntityID { get; set; }
        public string EntityName { get; set; }
        public int? RecordID { get; set; }

        public int? AddressTypeID { get; set; }
        public string AddressTypeName { get; set; }

        public string AddressLine1 { get; set; }
        public string AddressLine2 { get; set; }
        public string AddressLine3 { get; set; }
        public string City { get; set; }

        public string StateProvince
        {
            get
            {
                if (string.IsNullOrEmpty(this._StateProvince))
                {
                    return string.Empty;
                }
                return this._StateProvince.Substring(0, 2);
            }
            set
            {
                this._StateProvince = value;
            }
        }
        public int? StateProvinceID { get; set; }

        public string CountryCode
        {
            get
            {
                if (string.IsNullOrEmpty(this._CountryCode))
                {
                    return string.Empty;
                }
                return this._CountryCode.Substring(0, 2);
            }
            set
            {
                this._CountryCode = value;
            }
        }
        public int? CountryID { get; set; }

        public string ZipCode { get; set; }

    }

    public static class AddressExtendedEntityHelper
    {
        public static AddressEntity ToAddressEntity(this AddressExtendedEntity address, string userName)
        {
            if (!address.AddressTypeID.HasValue)
            {
                throw new DMSException("Address Type ID is not specified");
            }
            if (!address.CountryID.HasValue)
            {
                throw new DMSException("Country ID is not specified");
            }
            if (!address.StateProvinceID.HasValue)
            {
                throw new DMSException("State ID is not specified");
            }
            if (!address.RecordID.HasValue)
            {
                throw new DMSException("Record ID is not specified");
            }
            AddressEntity model = new AddressEntity();
            model.ID = address.AddressID;
            model.EntityID = address.EntityID;
            model.RecordID = address.RecordID;
            model.AddressTypeID = address.AddressTypeID;
            model.Line1 = address.AddressLine1;
            model.Line2 = address.AddressLine2;
            model.Line3 = address.AddressLine3;
            model.City = address.City;
            model.StateProvince = address.StateProvince;
            model.StateProvinceID = address.StateProvinceID;
            model.PostalCode = address.ZipCode;
            model.CountryID = address.CountryID;
            model.CountryCode = address.CountryCode;
            model.ModifyBy = userName;
            model.CreateBy = userName;
            model.CreateDate = DateTime.Now;
            model.ModifyDate = DateTime.Now;
            return model;
        }
    }
}
