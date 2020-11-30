using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO.MessageMaintenance
{
    public class MessageMaintenanceService : IMessageMaintenance
    {
        /// <summary>
        /// 
        /// </summary>
        /// <param name="criteria"></param>
        /// <returns></returns>
        public List<MessageList_Result> MessageList(PageCriteria criteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetMessageList(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection).ToList<MessageList_Result>();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="createIfNotExists"></param>
        /// <returns></returns>
        public Message Get(int recordID, bool createIfNotExists = false)
        {
            Message model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.Messages.Where(u => u.ID == recordID).FirstOrDefault();
            }

            if (model == null && createIfNotExists)
            {
                model = new Message();
            }
            return model;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <param name="LoggedInUserName"></param>
        public void SaveMessageDetails(Message model, string LoggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.Messages.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingRecord == null)
                {
                    model.CreateBy = LoggedInUserName;
                    model.CreateDate = DateTime.Now;
                    model.IsActive = true;
                    dbContext.Messages.Add(model);
                }
                else
                {
                    existingRecord.MessageTypeID = model.MessageTypeID;
                    existingRecord.MessageScope = model.MessageScope;
                    existingRecord.Subject = model.Subject;
                    existingRecord.MessageText = model.MessageText;
                    existingRecord.StartDate = model.StartDate;
                    existingRecord.EndDate = model.EndDate;
                    existingRecord.Sequence = model.Sequence;
                    existingRecord.ModifyBy = LoggedInUserName;
                    existingRecord.ModifyDate = DateTime.Now;
                }
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="recordID"></param>
        /// <param name="LoggedInUserName"></param>
        public void DeleteMessage(int recordID, string LoggedInUserName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.Messages.Where(u => u.ID == recordID).FirstOrDefault();
                if (existingRecord != null)
                {
                    dbContext.Messages.Remove(existingRecord);
                    dbContext.SaveChanges();
                }
            }
        }
    }
}
