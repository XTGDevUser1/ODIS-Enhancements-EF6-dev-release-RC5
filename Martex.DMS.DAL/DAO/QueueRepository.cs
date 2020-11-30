using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Data.Entity;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class QueueRepository
    {
        /// <summary>
        /// Searches the queue list of the specific user.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="pc">The pc.</param>
        /// <returns>List of queues</returns>
        public List<Queue_Result> Search(Guid userId, PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetQueue(userId, pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<Queue_Result>();
            }
        }


        /// <summary>
        /// Gets the specified service request.
        /// </summary>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <returns>service request</returns>
        public List<ServiceRequest_Result> GetServiceRequest(int serviceRequestId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetServiceRequest(serviceRequestId).ToList<ServiceRequest_Result>();
            }
        }

        /// <summary>
        /// Gets the case depending upon Id.
        /// </summary>
        /// <param name="caseId">The case id.</param>
        /// <returns></returns>
        public Case GetCase(int caseId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Cases.Where(a => a.ID == caseId)
                    .Include(c => c.Member)
                    .Include(c => c.Program)
                    .Include(s=>s.SourceSystem)
                    .SingleOrDefault();
            }
        }

        /// <summary>
        /// Updates the case.
        /// </summary>
        /// <param name="caseRecord">The case record.</param>
        public void UpdateCase(Case caseRecord, int? newAssignedTo)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var caseObject = dbContext.Cases.Include(x => x.User).Where(a => a.ID == caseRecord.ID).FirstOrDefault();
                if (caseObject.AssignedToUserID != null && caseObject.AssignedToUserID != caseRecord.AssignedToUserID)
                {
                    throw new DMSException(string.Format("Request in use by {0}", caseObject.User != null ? (caseObject.User.FirstName + ' ' + caseObject.User.LastName) : string.Empty));
                }
                else
                {
                    caseObject.AssignedToUserID = newAssignedTo;
                }
                dbContext.Entry(caseObject).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        //Lakshmi - Queue Color
        public string GetQueueStatusColor(string statusName, string nextAction)
        {
            string color = string.Empty;

            using (DMSEntities dbContext = new DMSEntities())
            {
                var queue = (from qs in dbContext.QueueStatus
                             join na in dbContext.NextActions on qs.Action.Trim().ToUpper() equals na.Description.Trim().ToUpper()
                             where (qs.Action.Trim().ToUpper() == nextAction.Trim().ToUpper()) &
                             ((qs.SRStatusName.Trim().ToUpper() == statusName.Trim().ToUpper()) | ((qs.SRStatusName + "^".Trim().ToUpper() == statusName.Trim().ToUpper())))
                             & (qs.IsActive.Value)
                             select qs).FirstOrDefault();

                if (queue != null)
                {
                    color = queue.Color;
                }
            }

            return color;

        }

        //Lakshmi - Queue Color
        public static List<QueueStatu> QueueStatusList = null;
        public static List<QueueStatu> GetQueueStatusList()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                QueueStatusList = dbContext.QueueStatus.ToList();
                return QueueStatusList;
            }
        }

        public int? GetAssignedToUserId(int serviceRequestId)
        {
            int? assignedToUserId = null;

            using (DMSEntities dbContext = new DMSEntities())
            {
                int caseId = (from srobj in dbContext.ServiceRequests
                              where srobj.ID == serviceRequestId
                              select srobj.CaseID).FirstOrDefault();
                assignedToUserId = (from caseobj in dbContext.Cases
                                    where caseobj.ID == caseId
                                    select caseobj.AssignedToUserID).FirstOrDefault();
            }
            return assignedToUserId;
        }

    }
}
