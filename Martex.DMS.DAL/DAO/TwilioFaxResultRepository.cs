using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.DAL.DAO
{
    public class TwilioFaxResultRepository
    {
        /// <summary>
        /// Logs the sent fax status.
        /// </summary>
        /// <param name="faxSid">The fax sid.</param>
        /// <param name="communicationLogId">The communication log identifier.</param>
        /// <param name="status">The status.</param>
        public void LogSentFaxStatus(string faxSid, long communicationLogId, string status)
        {
            using (var dbContext = new DMSEntities())
            {
                var twilioFaxResult = new TwilioFaxResult()
                {
                    FaxSid = faxSid,
                    CommunicationLogID = communicationLogId,
                    DeliveryStatus = status
                };
                dbContext.TwilioFaxResults.Add(twilioFaxResult);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the pending faxes.
        /// </summary>
        /// <returns></returns>
        public List<TwilioFaxResult> GetPendingFaxes()
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.TwilioFaxResults.Where(x => x.DeliveryStatus != "delivered" && x.DeliveryStatus != "failed").ToList();
            }
        }

        /// <summary>
        /// Updates the delivery status.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <param name="deliveryStatus">The delivery status.</param>
        public void UpdateDeliveryStatus(long id, string deliveryStatus)
        {
            using (var dbContext = new DMSEntities())
            {
                var twilioFaxResult = dbContext.TwilioFaxResults.Where(x => x.ID == id).FirstOrDefault();
                if (twilioFaxResult != null)
                {
                    twilioFaxResult.DeliveryStatus = deliveryStatus;
                    dbContext.Entry(twilioFaxResult).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }
    }
}