using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ContactLogRepository
    {
        /// <summary>
        /// Create New Contact Log Record
        /// </summary>
        /// <param name="model"></param>
        /// <param name="userName"></param>
        /// <param name="categoryName"></param>
        /// <param name="contactTypeName"></param>
        /// <param name="contactMethodName"></param>
        /// <param name="contactSource"></param>
        public void Create(ContactLog model, string userName, string categoryName = "", string contactTypeName = "", string contactMethodName = "", string contactSourceName = "", string contactReasonName = "", string contactActionName = "")
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                #region Assign Lookups

                if (!string.IsNullOrEmpty(categoryName))
                {
                    var contactCategory = dbContext.ContactCategories.Where(u => u.Name.Equals(categoryName)).FirstOrDefault();
                    if (contactCategory == null)
                    {
                        throw new Exception(string.Format("Unable to retrieve Contact Category {0}", categoryName));
                    }
                    model.ContactCategoryID = contactCategory.ID;
                }
                if (!string.IsNullOrEmpty(contactSourceName))
                {
                    var contactSource = dbContext.ContactSources.Where(u => u.Name.Equals(contactSourceName) && u.ContactCategory.Name.Equals(categoryName)).FirstOrDefault();
                    if (contactSource == null)
                    {
                        throw new Exception(string.Format("Unable to retrieve Contact Source {0}", contactSourceName));
                    }
                    model.ContactSourceID = contactSource.ID;
                }
                if (!string.IsNullOrEmpty(contactTypeName))
                {
                    var contactType = dbContext.ContactTypes.Where(u => u.Name.Equals(contactTypeName)).FirstOrDefault();
                    if (contactType == null)
                    {
                        throw new Exception(string.Format("Unable to retrieve Contact Type {0}", contactTypeName));
                    }
                    model.ContactTypeID = contactType.ID;
                }
                if (!string.IsNullOrEmpty(contactMethodName))
                {
                    var contactMethod = dbContext.ContactMethods.Where(u => u.Name.Equals(contactMethodName)).FirstOrDefault();
                    if (contactMethod == null)
                    {
                        throw new Exception(string.Format("Unable to retrieve Contact Method {0}", contactMethodName));
                    }
                    model.ContactMethodID = contactMethod.ID;
                }
                #endregion

                #region Create Record

                model.CreateBy = userName;
                model.CreateDate = DateTime.Now;
                dbContext.ContactLogs.Add(model);
                dbContext.SaveChanges();

                #endregion

                #region For Contact Reason

                if (!string.IsNullOrEmpty(contactReasonName))
                {
                    var contactReason = dbContext.ContactReasons.Where(u => u.Name.Equals(contactReasonName) && u.ContactCategory.Name.Equals(categoryName)).FirstOrDefault();
                    if (contactReason == null)
                    {
                        throw new Exception(string.Format("Unable to retrieve Contact Reason {0}", contactReasonName));
                    }
                    dbContext.ContactLogReasons.Add(new ContactLogReason()
                    {
                        ContactLogID = model.ID,
                        ContactReasonID = contactReason.ID,
                        CreateBy = userName,
                        CreateDate = DateTime.Now
                    });
                    dbContext.SaveChanges();
                }

                #endregion

                #region For Contact Action

                if (!string.IsNullOrEmpty(contactActionName))
                {
                    var contactAction = dbContext.ContactActions.Where(u => u.Name.Equals(contactActionName) && u.ContactCategory.Name.Equals(categoryName)).FirstOrDefault();
                    if (contactAction == null)
                    {
                        throw new Exception(string.Format("Unable to retrieve Contact Action {0}", contactActionName));
                    }
                    dbContext.ContactLogActions.Add(new ContactLogAction()
                    {
                        ContactLogID = model.ID,
                        ContactActionID = contactAction.ID,
                        CreateBy = userName,
                        CreateDate = DateTime.Now
                    });
                    dbContext.SaveChanges();
                }

                #endregion
            }
        }

        public ContactLog GetContactLogByConnectID(string amazonConnectID)
        {
            DMSEntities dbContext = new DMSEntities();

            return (from cl in dbContext.ContactLogs
                              join cd in dbContext.ContactLogConnectDatas on cl.ContactLogConnectDataId equals cd.ID
                              where cd.ConnectContactID == amazonConnectID
                              select cl).FirstOrDefault();
        }

        /// <summary>
        /// Updates the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void Save(ContactLog model, string userName, int? relatedRecordID = null, string entityName = null)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                if (model.PhoneNumber != null && model.PhoneNumber.Contains("-"))
                {
                    model.PhoneNumber = model.PhoneNumber.Replace("-", string.Empty);
                }
                ContactLog result = entities.ContactLogs.Where(u => u.ID == model.ID).FirstOrDefault();
                if (result != null)
                {
                    result.PhoneTypeID = model.PhoneTypeID;
                    result.ContactMethodID = model.ContactMethodID;
                    result.Description = model.Description;
                    result.Company = model.Company;
                    result.ContactSourceID = model.ContactSourceID;
                    result.ModifyDate = DateTime.Now;
                    result.ModifyBy = userName;
                    result.Direction = model.Direction;
                    result.Comments = model.Comments;
                    result.TalkedTo = model.TalkedTo;
                    result.ContactTypeID = model.ContactTypeID;
                    result.ContactCategoryID = model.ContactCategoryID;
                }
                else
                {
                    result = model;
                    entities.ContactLogs.Add(result);

                    if (relatedRecordID != null && entityName != null)
                    {
                        Entity theEntity = entities.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                        if (theEntity == null)
                        {
                            throw new DMSException("Invalid Entity name supplied while logging Contact");
                        }
                        //Contact Log Link
                        ContactLogLink cLink = new ContactLogLink();
                        cLink.ContactLog = result;
                        cLink.EntityID = theEntity.ID;
                        cLink.RecordID = relatedRecordID;

                        entities.ContactLogLinks.Add(cLink);
                    }

                }

                entities.SaveChanges();
            }
        }

      /// <summary>
      /// Updates Contact log connect data from the CTR
      /// </summary>
      /// <param name="ctrData">CTR data from Amazon</param>
      /// <returns>Modified record.  Null if not found.</returns>
      public ContactLogConnectData UpdateCTRData(CTRDataModel ctrData) {
        using (var dbContext = new DMSEntities()) {
          var connectContactData = dbContext.ContactLogConnectDatas.FirstOrDefault(
            x => x.ConnectContactID == ctrData.ConnectContactID);

          if (connectContactData == null) {
            return null;
          }

          connectContactData.InitialContactID = ctrData.InitialContactID;
          connectContactData.NextContactId = ctrData.NextContactId;
          connectContactData.PreviousContactID = ctrData.PreviousContactID;
          connectContactData.CustomerEndpoint = ctrData.CustomerEndpoint;
          connectContactData.CustomerEndpointType = ctrData.CustomerEndpointType;
          connectContactData.InitiationMethod = ctrData.InitiationMethod;
          connectContactData.InitiationTimestamp = ctrData.InitiationTimestamp;
          connectContactData.SystemEndpoint = ctrData.SystemEndpoint;
          connectContactData.QueueARN = ctrData.QueueARN;
          connectContactData.QueueName = ctrData.QueueName;
          connectContactData.QueueDuration = ctrData.QueueDuration;
          connectContactData.EnqueueTimestamp = ctrData.EnqueueTimestamp;
          connectContactData.DequeueTimestamp = ctrData.DequeueTimestamp;
          connectContactData.AgentARN = ctrData.AgentARN;
          connectContactData.AgentUsername = ctrData.AgentUsername;
          connectContactData.AgentRoutingProfileARN = ctrData.AgentRoutingProfileARN;
          connectContactData.AgentRoutingProfileName = ctrData.AgentRoutingProfileName;
          connectContactData.AgentNumberOfHolds = ctrData.AgentNumberOfHolds;
          connectContactData.ConnectedToAgentTimestamp = ctrData.ConnectedToAgentTimestamp;
          connectContactData.CustomerHoldDuration = ctrData.CustomerHoldDuration;
          connectContactData.LongestCustomerHoldDuration = ctrData.LongestCustomerHoldDuration;
          connectContactData.TransferCompletedTimestamp = ctrData.TransferCompletedTimestamp;
          connectContactData.TransferredToEndpoint = ctrData.TransferredToEndpoint;
          connectContactData.AfterContactWorkDuration = ctrData.AfterContactWorkDuration;
          connectContactData.AfterContactWorkStartTimestamp = ctrData.AfterContactWorkStartTimestamp;
          connectContactData.AfterContactWorkEndTimestamp = ctrData.AfterContactWorkEndTimestamp;
          connectContactData.AgentIntractionDuration = ctrData.AgentIntractionDuration;
          connectContactData.Channel = ctrData.Channel;
          connectContactData.ConnectedToSystemTimestamp = ctrData.ConnectedToSystemTimestamp;
          connectContactData.DisconnectTimestamp = ctrData.DisconnectTimestamp;
          connectContactData.RecordingLocation = ctrData.RecordingLocation;
          connectContactData.RecordingStatus = ctrData.RecordingStatus;
          connectContactData.RecordingType = ctrData.RecordingType;
          connectContactData.RecordingDeletionReason = ctrData.RecordingDeletionReason;
          connectContactData.AWSAccount = ctrData.AWSAccount;
          connectContactData.InstanceARN = ctrData.InstanceARN;
          connectContactData.CTRRecord = ctrData.CTRRecord;
          connectContactData.ModifyDate = DateTime.UtcNow;
          connectContactData.ModifyBy = "AWS";

          dbContext.SaveChanges();

          return connectContactData;
        }
    }


        /// <summary>
        /// Get the recent Contact log record for the given entity record and contact source.
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="contactSourceId"></param>
        /// <returns></returns>
        public ContactLog GetLatestContactLog(int recordID, params int?[] contactSourceId)
        {
            DMSEntities dbContext = new DMSEntities();

            var cLog = (from cl in dbContext.ContactLogs
                        join cll in dbContext.ContactLogLinks on cl.ID equals cll.ContactLogID
                        where cll.RecordID == recordID && contactSourceId.Contains(cl.ContactSourceID) == true
                        select cl).OrderByDescending(col => col.CreateDate).FirstOrDefault();
            return cLog;
        }


        /// <summary>
        /// Gets the previous call list.
        /// </summary>
        /// <param name="emergencyAssistaceID">The emergency assistace ID.</param>
        /// <returns></returns>
        public List<PreviousCallList> GetPreviousCallList(int emergencyAssistaceID)
        {
            using (DMSEntities dbContect = new DMSEntities())
            {
                List<PreviousCallList> list = dbContect.GetPreviousCallList(emergencyAssistaceID).OrderByDescending(d => d.CreateDate).ToList();
                return list;
            }
        }

        /// <summary>
        /// Creates the link record.
        /// </summary>
        /// <param name="contactLogId">The contact log id.</param>
        /// <param name="entityName">Name of the entity.</param>
        /// <param name="relatedRecordId">The related record id.</param>
        /// <exception cref="DMSException">Invalid Entity name supplied while logging an ContactLog :  + entityName</exception>
        public void CreateLinkRecord(int contactLogId, string entityName, int? relatedRecordId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                ContactLogLink contactLogLink = new ContactLogLink();
                Entity theEntity = dbContext.Entities.Where(x => x.Name == entityName).FirstOrDefault();
                if (theEntity == null)
                {
                    throw new DMSException("Invalid Entity name supplied while logging an ContactLog : " + entityName);
                }

                contactLogLink.EntityID = theEntity.ID;
                contactLogLink.ContactLogID = contactLogId;
                contactLogLink.RecordID = relatedRecordId;
                dbContext.ContactLogLinks.Add(contactLogLink);
                dbContext.SaveChanges();
            }
        }

        public void UpdateClosedLoopStatus(int contactLogID)
        {
            using (var dbContext = new DMSEntities())
            {
                dbContext.dms_closedloop_status_update(contactLogID);
            }
        }
        /// <summary>
        /// Determines whether [is close loop category] [the specified contact log id].
        /// </summary>
        /// <param name="contactLogId">The contact log id.</param>
        /// <returns>
        ///   <c>true</c> if [is close loop category] [the specified contact log id]; otherwise, <c>false</c>.
        /// </returns>
        /// <exception cref="DMSException">ClosedLoop Contact category is not set up in the system</exception>
        public bool IsCloseLoopCategory(int contactLogId)
        {
            bool isClosedLoop = false;
            using (DMSEntities entities = new DMSEntities())
            {
                var cat = entities.ContactCategories.Where(n => n.Name.Equals("ClosedLoop", StringComparison.OrdinalIgnoreCase)).FirstOrDefault();
                if (cat == null)
                {
                    throw new DMSException("ClosedLoop Contact category is not set up in the system");
                }
                int closedLoopID = cat.ID;
                var result = entities.ContactLogs.Where(id => id.ID == contactLogId && id.ContactCategoryID == closedLoopID).FirstOrDefault();
                if (result != null)
                {
                    isClosedLoop = true;
                }
            }
            return isClosedLoop;
        }

        /// <summary>
        /// Creates the contact log reason.
        /// </summary>
        /// <param name="model">The model.</param>
        public void CreateContactLogReason(ContactLogReason model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ContactLogReasons.Add(model);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Creates the contact log action.
        /// </summary>
        /// <param name="model">The model.</param>
        public void CreateContactLogAction(ContactLogAction model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ContactLogActions.Add(model);
                dbContext.SaveChanges();
            }
        }
    }
}
