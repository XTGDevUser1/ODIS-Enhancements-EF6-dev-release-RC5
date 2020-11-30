using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class FinishRepository
    {
        /// <summary>
        /// Gets the contact reasons.
        /// </summary>
        /// <param name="contactCategory">The contact category.</param>
        /// <returns></returns>
        public List<ContactReason> GetContactReasons(int contactCategory)
        {
            List<ContactReason> reasons = new List<ContactReason>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                reasons = dbContext.ContactReasons.Where(r => r.ContactCategoryID == contactCategory && r.IsActive == true && r.IsShownOnScreen == true).OrderBy(r => r.Sequence).ToList<ContactReason>();
                return reasons;
            }
        }
        /// <summary>
        /// Gets the contact action.
        /// </summary>
        /// <param name="contactCategory">The contact category.</param>
        /// <returns></returns>
        public List<ContactAction> GetContactAction(int contactCategory)
        {
            List<ContactAction> actions = new List<ContactAction>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                actions = dbContext.ContactActions.Where(a => a.ContactCategoryID == contactCategory && a.IsActive == true && a.IsShownOnScreen == true).OrderBy(r => r.Sequence).ToList<ContactAction>();
                return actions;
            }
        }
        /// <summary>
        /// Gets the closed loop activities.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <returns></returns>
        public List<ClosedLoopActivities_Result> GetClosedLoopActivities(int? serviceRequestID)
        {
            List<ClosedLoopActivities_Result> closedloopActivities = new List<ClosedLoopActivities_Result>();
            using (DMSEntities dbContext = new DMSEntities())
            {
                closedloopActivities = dbContext.GetClosedLoopActivities(serviceRequestID).ToList<ClosedLoopActivities_Result>();
            }
            return closedloopActivities;
        }

        
    }
}
