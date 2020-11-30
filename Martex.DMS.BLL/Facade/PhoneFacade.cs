using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using log4net;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Manage Phones
    /// </summary>
    public class PhoneFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(PhoneFacade));
        #endregion

        #region Public Contstants
        public const string ADD = "add";
        public const string EDIT = "edit";
        public const string DELETE = "delete";
        #endregion

        #region Public Methods
        /// <summary>
        /// Saves the phone details.
        /// </summary>
        /// <param name="recordId">The record id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="userName">Name of the user.</param>
        /// <param name="phoneDetails">The phone details.</param>
        /// <param name="mode">The mode.</param>
        public void SavePhoneDetails(int recordId, string entityName, string userName, List<PhoneEntity> phoneDetails, string mode)
        {
            if (phoneDetails != null)
            {
                foreach (PhoneEntity phone in phoneDetails)
                {
                    if (phone != null)
                    {
                        logger.InfoFormat("'{0}'ing Phone [ {1} ]", mode, phone.ID);
                        phone.RecordID = recordId;
                        // Let us not create new Phone type records.
                        phone.PhoneType = null;

                        if (mode == ADD)
                        {
                            phone.CreateBy = phone.ModifyBy = userName;
                            phone.CreateDate = phone.ModifyDate = DateTime.Now;
                        }
                        else if (mode == EDIT)
                        {
                            phone.ModifyBy = userName;
                            phone.ModifyDate = DateTime.Now;
                        }
                        var phoneRepository = new PhoneRepository();
                        phoneRepository.Save(phone, entityName, mode == DELETE);
                    }
                }
            }

        }

        /// <summary>
        /// Gets the specified record ID.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="type">The type.</param>
        /// <returns></returns>
        public PhoneEntity Get(int recordID, string entityName, string type)
        {
            var phoneRepository = new PhoneRepository();
            return phoneRepository.Get(recordID, entityName, type);
        }

        /// <summary>
        /// Gets the name of the phone type by.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public PhoneType GetPhoneTypeByName(string name)
        {
            var phoneRepository = new PhoneRepository();
            return phoneRepository.GetPhoneTypeByName(name);
        }


        #endregion
    }
}
