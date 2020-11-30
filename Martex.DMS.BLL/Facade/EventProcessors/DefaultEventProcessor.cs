using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using log4net;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade.EventProcessors
{
    public class DefaultEventProcessor : IEventProcessor
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(DefaultEventProcessor));
        /// <summary>
        /// Processes the event log.
        /// </summary>
        /// <param name="eventLog">The event log.</param>
        /// <param name="subscription">The subscription.</param>
        public virtual void ProcessEventLog(EventLog eventLog, EventSubscriptionRecipient subscriptionRecipient)
        {
            logger.InfoFormat("Processing subscription Recipient ID {0} with description {1}, data {2} from event log {3}", subscriptionRecipient.ID, eventLog.Description, eventLog.Data, eventLog.ID);

            CommunicationQueueRepository queueRepository = new CommunicationQueueRepository(eventLog, subscriptionRecipient);
            queueRepository.Enqueue();
        }

        #region //TODO: KB: The following code will be removed after unit testing
        /*private int? CreateContactLog(int? vendorID, int? contactMethodID, string contactDetail)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                #region Create ContactLog
                ContactLogRepository clRepository = new ContactLogRepository();
                ContactLog cl = new ContactLog();
                ContactCategory cc = dbContext.ContactCategories.Where(ccExp => ccExp.Name == "ContactVendor").FirstOrDefault<ContactCategory>();
                ContactType ct = dbContext.ContactTypes.Where(cType => cType.Name == "System").FirstOrDefault<ContactType>();
                ContactMethod emailContactMethod = dbContext.ContactMethods.Where(cm => cm.Name == "Email").FirstOrDefault();
                ContactSource cs = dbContext.ContactSources.Where(cSource => cSource.Name == "VendorData" && cSource.ContactCategoryID == cc.ID).FirstOrDefault<ContactSource>();
                if (cc != null)
                {
                    cl.ContactCategoryID = cc.ID;
                }
                if (ct != null)
                {
                    cl.ContactTypeID = ct.ID;
                }

                cl.ContactMethodID = contactMethodID;
                if (cs != null)
                {
                    cl.ContactSourceID = cs.ID;
                }

                var vendor = new VendorRepository().GetByID(vendorID.Value);
                cl.Company = vendor.Name;

                var faxPhoneType = dbContext.PhoneTypes.Where(x => x.Name == "Fax").FirstOrDefault();
                if (emailContactMethod != null && emailContactMethod.ID == contactMethodID.GetValueOrDefault())
                {
                    cl.Email = contactDetail;                    
                }
                else
                {
                    cl.PhoneTypeID = faxPhoneType.ID;
                    cl.PhoneNumber = contactDetail;
                }
                cl.Direction = "Outbound";
                cl.Description = "Insurance Expiration Notice";
                cl.CreateDate = DateTime.Now;                
                cl.CreateBy = "system";
                
                clRepository.Save(cl, "system", vendorID, EntityNames.VENDOR);                

                #endregion

                #region ContactLogReason
                ContactLogReasonRepository clrRepository = new ContactLogReasonRepository();
                ContactReason cReason = dbContext.ContactReasons.Where(cr => cr.Name == "VendorInsurance" && cr.ContactCategoryID == cc.ID).FirstOrDefault<ContactReason>();
                ContactLogReason clReason = new ContactLogReason();
                clReason.ContactLogID = cl.ID;
                clReason.ContactReasonID = cReason.ID;
                clReason.CreateDate = DateTime.Now;
                clReason.CreateBy = "system";
                clrRepository.Save(clReason, "system");
                #endregion

                #region ContactLogAction

                #region Contact Vendor
                ContactAction ContactVandorContactAction = (from ca in dbContext.ContactActions
                                                            join oc in dbContext.ContactCategories on ca.ContactCategoryID equals oc.ID
                                                            where ca.Name == "SendInsuranceExpirationNotice" && oc.Name == "ContactVendor"
                                                            select ca).FirstOrDefault<ContactAction>();
                ContactLogActionRepository clarepository = new ContactLogActionRepository();
                ContactLogAction clActionContactVendor = new ContactLogAction();
                clActionContactVendor.ContactLogID = cl.ID;
                clActionContactVendor.ContactActionID = ContactVandorContactAction.ID;
                clActionContactVendor.CreateDate = DateTime.Now;
                clActionContactVendor.CreateBy = "system";
                clarepository.Save(clActionContactVendor, "system");
                #endregion
                #endregion

                return cl.ID;
            }
        }
        */
        #endregion

    }


}
