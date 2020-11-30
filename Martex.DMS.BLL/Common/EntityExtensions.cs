using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.BLL.Common
{
    public static class EntityExtensions
    {
        /// <summary>
        /// Clones the specified address.
        /// </summary>
        /// <param name="address">The address.</param>
        /// <returns></returns>
        public static AddressEntity Clone(this AddressEntity address)
        {
            var newAddressEntity = new AddressEntity();
            newAddressEntity.Line1 = address.Line1;
            newAddressEntity.Line2 = address.Line2;
            newAddressEntity.Line3 = address.Line3;

            newAddressEntity.City = address.City;
            newAddressEntity.StateProvinceID = address.StateProvinceID;
            newAddressEntity.StateProvince = address.StateProvince;
            newAddressEntity.CountryID = address.CountryID;
            newAddressEntity.CountryCode = address.CountryCode;
            newAddressEntity.PostalCode = address.PostalCode;
            newAddressEntity.AddressTypeID = address.AddressTypeID;

            newAddressEntity.CreateBy = address.CreateBy;
            newAddressEntity.CreateDate = address.CreateDate;
            return newAddressEntity;
        }

        public static PhoneEntity Clone(this PhoneEntity phone)
        {
            var newPhoneEntity = new PhoneEntity();

            newPhoneEntity.PhoneNumber = phone.PhoneNumber;
            newPhoneEntity.PhoneTypeID = phone.PhoneTypeID;

            newPhoneEntity.CreateBy = phone.CreateBy;
            newPhoneEntity.CreateDate = phone.CreateDate;
            return newPhoneEntity;
        }

        public static Dictionary<string, string> ToDictionary(this object myObj)
        {
            return myObj.GetType()
                .GetProperties()
                .Select(pi => new { Name = pi.Name, Value = pi.GetValue(myObj, null) })
                .Union(
                    myObj.GetType()
                    .GetFields()
                    .Select(fi => new { Name = fi.Name, Value = fi.GetValue(myObj) })
                 )
                 .ToDictionary(ks => ks.Name, vs => vs.Value != null ? vs.Value.ToString() : string.Empty);
        }

        public static void ThrowExceptionIfNull(this ApplicationConfiguration appConfig, string message)
        {
            if (appConfig == null)
            {
                throw new DMSException(message);
            }
        }
    }
}
