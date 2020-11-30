using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO.QA
{
    public class CoachingConcernService : ICoachingConcern
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="criteria"></param>
        /// <param name="loggedInUserName"></param>
        /// <returns></returns>
        public List<CoachingConcerns_List_Result> List(Common.PageCriteria criteria, string loggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetCoachingConcernsList(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection).ToList<CoachingConcerns_List_Result>();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="createIfNotExists"></param>
        /// <returns></returns>
        public CoachingConcern Get(int recordID, bool createIfNotExists = false)
        {
            CoachingConcern model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.CoachingConcerns.Where(u => u.ID == recordID).FirstOrDefault();
            }
            if (model == null && createIfNotExists)
            {
                model = new CoachingConcern();
            }
            return model;
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="LoggedInUserName"></param>
        public void Delete(int recordID, string LoggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.CoachingConcerns.Where(u => u.ID == recordID).FirstOrDefault();
                if (existingRecord != null)
                {
                    dbContext.CoachingConcerns.Remove(existingRecord);
                    dbContext.SaveChanges();
                }
            }
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <param name="LoggedInUserName"></param>
        public void SaveDetails(CoachingConcern model, string LoggedInUserName, string pageSource, string sessionID)
        {
            long eventLogID;
            bool IsNewRecord = false;
            EventLogRepository eventLog = new EventLogRepository();
            using (TransactionScope transaction = new TransactionScope())
            {
                using (DMSEntities dbContext = new DMSEntities())
                {
                    #region Primary Record
                    var existingRecord = dbContext.CoachingConcerns.Where(u => u.ID == model.ID).FirstOrDefault();
                    if (existingRecord == null)
                    {
                        model.CreateBy = LoggedInUserName;
                        model.CreateDate = DateTime.Now;
                        model.IsActive = true;
                        dbContext.CoachingConcerns.Add(model);
                        IsNewRecord = true;
                    }
                    else
                    {
                        existingRecord.AgentUserName = model.AgentUserName;
                        existingRecord.TeamManager = model.TeamManager;
                        existingRecord.ConcernTypeID = model.ConcernTypeID;
                        existingRecord.ConcernID = model.ConcernID;
                        existingRecord.CallRecordingID = model.CallRecordingID;
                        existingRecord.ServiceRequestID = model.ServiceRequestID;
                        existingRecord.PurchaseOrderID = model.PurchaseOrderID;
                        existingRecord.Notes = model.Notes;
                        existingRecord.IsAppealed = model.IsAppealed;
                        existingRecord.AppealedDate = model.AppealedDate;
                        existingRecord.IsInternalAppeal = model.IsInternalAppeal;
                        existingRecord.InternalAppealDate = model.InternalAppealDate;
                        existingRecord.AppealApproved = model.AppealApproved;
                        existingRecord.IsCoached = model.IsCoached;
                        existingRecord.CoachedDate = model.CoachedDate;
                        existingRecord.PendingDate = model.PendingDate;
                        existingRecord.SevereQualityViolation = model.SevereQualityViolation;
                        existingRecord.ZeroToleranceViolation = model.ZeroToleranceViolation;
                        existingRecord.ModifyBy = LoggedInUserName;
                        existingRecord.ModifyDate = DateTime.Now;
                        IsNewRecord = false;
                    }
                    dbContext.SaveChanges();
                    #endregion

                    #region Create Event Logs
                    // Get the Event ID from the database.
                    IRepository<Event> eventRepository = new EventRepository();
                    Event theEvent = eventRepository.Get<string>(IsNewRecord ? EventNames.ADD_COACHING_CONCERN : EventNames.UPDATE_COACHING_CONCERN);
                    if (theEvent == null)
                    {
                        throw new DMSException("Invalid event name " + (IsNewRecord ? EventNames.ADD_COACHING_CONCERN : EventNames.UPDATE_COACHING_CONCERN));
                    }
                    eventLogID = eventLog.Add(new EventLog()
                    {
                        Source = pageSource,
                        EventID = theEvent.ID,
                        SessionID = sessionID,
                        Description = theEvent.Description,
                        CreateDate = DateTime.Now,
                        CreateBy = LoggedInUserName
                    });

                    var agentUserMembership = dbContext.aspnet_Users.Where(u => u.UserName.Equals(model.AgentUserName)).FirstOrDefault();
                    if (agentUserMembership != null)
                    {
                        var agentUser = dbContext.Users.Where(u => u.aspnet_UserID.Equals(agentUserMembership.UserId)).FirstOrDefault();
                        if (agentUser != null)
                        {
                            eventLog.CreateLinkRecord(eventLogID, EntityNames.USER, agentUser.ID);
                        }

                        if (agentUser != null && agentUser.ManagerID.HasValue)
                        {
                            eventLog.CreateLinkRecord(eventLogID, EntityNames.USER, agentUser.ManagerID);
                        }
                    }

                    if (model.ServiceRequestID.HasValue)
                    {
                        eventLog.CreateLinkRecord(eventLogID, EntityNames.SERVICE_REQUEST, model.ServiceRequestID);
                    }
                    if (model.PurchaseOrderID.HasValue)
                    {
                        eventLog.CreateLinkRecord(eventLogID, EntityNames.PURCHASE_ORDER, model.PurchaseOrderID);
                    }
                    #endregion
                }
                transaction.Complete();
            }
        }
    }
}
