using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.Entities
{
    /// <summary>
    /// 
    /// </summary>
    public class GenericPhoneModel
    {
        private PhoneRepository repository = new PhoneRepository();

        public int RecordID { get; set; }
        public string EntityName { get; set; }
        public int Height { get; set; }
        public bool IsReadOnly { get; set; }

        /// <summary>
        /// Gets the phone numbers.
        /// </summary>
        /// <value>
        /// The phone numbers.
        /// </value>
        public List<PhoneEntityExtended> PhoneNumbers
        {
            get
            {
                if (this.RecordID > 0 && !string.IsNullOrEmpty(this.EntityName))
                {
                    string[] excludedTypes = null;
                    if (this.EntityName.Equals(EntityNames.VENDOR))
                    {
                        excludedTypes = new string[] { PhoneTypeNames.BANK};
                    }
                    return repository.GetGenericPhoneNumber(this.RecordID, this.EntityName, excludedTypes);
                }
                return null;
            }
        }
    }

    /// <summary>
    /// 
    /// </summary>
    public class PhoneEntityExtended
    {
        public int PhoneID { get; set; }
        public int EntityID { get; set; }
        public string EntityName { get; set; }
        public int RecordID { get; set; }
        public int? PhoneTypeID { get; set; }
        public string PhoneTypeName { get; set; }
        public string PhoneTypeDescription { get; set; }
        public string PhoneNumber { get; set; }
    }

    public static class PhoneEntityExtendedHelper
    {
        public static PhoneEntity ToPhoneEntity(this PhoneEntityExtended model,string userName)
        {
            PhoneEntity entity = new PhoneEntity();
            entity.ID = model.PhoneID;
            entity.RecordID = model.RecordID;
            entity.PhoneTypeID = model.PhoneTypeID;
            entity.PhoneNumber = model.PhoneNumber;
            entity.ModifyBy = userName;
            entity.CreateBy = userName;
            entity.ModifyDate = DateTime.Now;
            entity.CreateDate = DateTime.Now;
            return entity;
        }
    }
}
