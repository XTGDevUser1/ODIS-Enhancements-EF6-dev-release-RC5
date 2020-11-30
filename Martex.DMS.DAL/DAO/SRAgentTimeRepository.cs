using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    public enum AgentTimeCounts
    {
        PO,
        DISPATCH_CALL,
        CLICK_TO_CALL,
        SERVICE_FACILITY
    }
    public class SRAgentTimeRepository
    {
        /// <summary>
        /// Creates the specified sr agent time.
        /// </summary>
        /// <param name="srAgentTime">The sr agent time.</param>
        public void Create(ServiceRequestAgentTime srAgentTime)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.ServiceRequestAgentTimes.Add(srAgentTime);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the event.
        /// </summary>
        /// <param name="srAgentTimeID">The sr agent time identifier.</param>
        /// <param name="lastEventLogId">The last event log identifier.</param>
        /// <param name="timeSinceFirstEvent">The time since first event.</param>
        /// <param name="finalize">if set to <c>true</c> [finalize].</param>
        public void UpdateEvent(int srAgentTimeID, long lastEventLogId, int timeSinceFirstEvent, bool finalize = false)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var srAgentTime = dbContext.ServiceRequestAgentTimes.Where(x => x.ID == srAgentTimeID).FirstOrDefault();
                if (srAgentTime != null)
                {
                    srAgentTime.EndDate = DateTime.Now;
                    srAgentTime.EndEventLogID = lastEventLogId;
                    srAgentTime.EventSeconds = timeSinceFirstEvent;
                    if (finalize)
                    {
                        srAgentTime.IsBeginMatchedToEnd = finalize;
                    }
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Updates the counts.
        /// </summary>
        /// <param name="srAgentTimeID">The sr agent time identifier.</param>
        /// <param name="count">The count.</param>
        /// <param name="agentTimeCountType">Type of the agent time count.</param>
        public void UpdateCounts(int srAgentTimeID, AgentTimeCounts agentTimeCountType)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var srAgentTime = dbContext.ServiceRequestAgentTimes.Where(x => x.ID == srAgentTimeID).FirstOrDefault();
                if (srAgentTime != null)
                {
                    switch (agentTimeCountType)
                    {                        
                        case AgentTimeCounts.CLICK_TO_CALL:
                            srAgentTime.ClickToCallCount = srAgentTime.ClickToCallCount.GetValueOrDefault() + 1;
                            break;
                        case AgentTimeCounts.DISPATCH_CALL:
                            srAgentTime.DispatchISPCallCount = srAgentTime.DispatchISPCallCount.GetValueOrDefault() + 1;
                            break;
                        case AgentTimeCounts.PO:
                            srAgentTime.IssuedPOCount = srAgentTime.IssuedPOCount.GetValueOrDefault() + 1;
                            break;   
                        case AgentTimeCounts.SERVICE_FACILITY:
                            srAgentTime.ServiceFacilityCallCount = srAgentTime.ServiceFacilityCallCount.GetValueOrDefault() + 1;
                            break;
                        default:
                            break;
                    }
                    dbContext.SaveChanges();
                }
            }
        }
        
    }
}
