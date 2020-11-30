using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Model;
using System.Transactions;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using log4net;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class ContactLogFacade
    {

        protected static readonly ILog logger = LogManager.GetLogger(typeof(ContactLogFacade));

        #region Public Methods
        
        /// <summary>
        /// Gets the latest contact log.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="contactSourceId">The contact source id.</param>
        /// <returns></returns>
        public ContactLog GetLatestContactLog(int recordID, params int?[] contactSourceId)
        {   
            ContactLogRepository repository = new ContactLogRepository();
            ContactLog contactLog = repository.GetLatestContactLog(recordID,contactSourceId);
            
            if (contactLog == null)
            {
                return new ContactLog();
            }
            return contactLog;
        }

        /// <summary>
        /// Gets the previous call list.
        /// </summary>
        /// <param name="emergencyAssistanceID">The emergency assistance ID.</param>
        /// <param name="contactLogID">The contact log ID.</param>
        /// <returns></returns>
        public List<PreviousCallList> GetPreviousCallList(int emergencyAssistanceID,int? contactLogID)
        {
            ContactLogRepository repository = new ContactLogRepository();
            List<PreviousCallList> result = repository.GetPreviousCallList(emergencyAssistanceID);
            
            if (contactLogID.HasValue && contactLogID.Value > 0)
            {
                result = result.Where(u => u.ContactLogID == contactLogID).ToList();
            }
            if (result == null)
            {
                result = new List<PreviousCallList>();
            }
            foreach (PreviousCallList tempCallList in result)
            {
                if (!string.IsNullOrEmpty(tempCallList.PhoneNumber))
                {
                    tempCallList.PhoneNumber = tempCallList.PhoneNumber.Insert(3, "-").Insert(7, "-");
                }
            }
            return result;
        }

        #endregion

        public int Log(string strContactCategory, string strContactType, string strContactMethod, string direction, string description, string strContactReason, string strContactAction,string company, string email, string currentUser, int? relatedRecordID = null, string relatedEntityName = null)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                CommonLookUpRepository lookUp = new CommonLookUpRepository();
                var contactLogRepo = new ContactLogRepository();
                ContactCategory contactCategory = lookUp.GetContactCategory(strContactCategory);
                ContactType contactType = lookUp.GetContactType(strContactType);
                ContactMethod contactMethod = lookUp.GetContactMethod(strContactMethod);
                if (contactCategory == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Contact Category - {0}", strContactCategory));
                }
                if (contactType == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Contact Type - {0}", strContactType));
                }
                if (contactMethod == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Contact Method - {0}", strContactMethod));
                }
                ContactLog contactLog = new ContactLog()
                {
                    ContactCategoryID = contactCategory.ID,
                    ContactTypeID = contactType.ID,
                    ContactMethodID = contactMethod.ID,
                    ContactSourceID = null,
                    Company = company,
                    Email = email,
                    Direction = direction,
                    Description = description,
                    Comments = null,
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    ModifyBy = null,
                    ModifyDate = null,
                };

                logger.Info("Trying to Create Contact Log");
                contactLogRepo.Save(contactLog, currentUser);

                ContactReason contactReason = lookUp.GetContactReason(strContactReason, contactCategory.ID);
                if (contactReason == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Contact Reason - {0}", strContactReason));
                }
                ContactAction contactAction = lookUp.GetContactAction(strContactAction, contactCategory.ID);
                if (contactAction == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Contact Action - {0}", strContactAction));
                }

                ContactLogReason contactLogReaosn = new ContactLogReason()
                {
                    ContactLogID = contactLog.ID,
                    ContactReasonID = contactReason.ID,
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now
                };
                logger.Info(string.Format("Trying to Create Contact Log Reason for Contact Log {0}", contactLog.ID));
                contactLogRepo.CreateContactLogReason(contactLogReaosn);

                ContactLogAction contactLogAction = new ContactLogAction()
                {
                    ContactLogID = contactLog.ID,
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    ContactActionID = contactAction.ID
                };
                logger.Info(string.Format("Trying to Create Contact Action for Contact Log {0}", contactLog.ID));
                contactLogRepo.CreateContactLogAction(contactLogAction);

                logger.Info(string.Format("Trying to Create Link Record for Contact Log ID {0}", contactLog.ID));
                contactLogRepo.CreateLinkRecord(contactLog.ID, relatedEntityName, relatedRecordID);
                tran.Complete();

                return contactLog.ID;
            }
        }

        public void CreateLinkRecord(int contactLogID, int relatedRecordID, string entityName)
        {
            var contactLogRepo = new ContactLogRepository();
            contactLogRepo.CreateLinkRecord(contactLogID, entityName, relatedRecordID);
        }
    }
}
