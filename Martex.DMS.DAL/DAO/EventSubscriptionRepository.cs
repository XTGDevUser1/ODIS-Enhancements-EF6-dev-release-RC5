using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class EventSubscriptionRepository
    {
        /// <summary>
        /// Gets the subscriptions by event ID or event type.
        /// </summary>
        /// <param name="eventId">The event id</param>
        /// <param name="eventTypeId">The event type id.</param>
        /// <returns></returns>
        public List<EventSubscription> GetSubscriptionsByEvent(int eventId, int? eventTypeId, int? eventCategoryId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                var eventSubscriptions = dbContext.EventSubscriptions.Include("Event").Include("EventCategory").Include("ContactMethod").Include("NotificationRecipientType").Where(x =>
                    (x.EventID == eventId || x.EventTypeID == eventTypeId || x.EventCategoryID == eventCategoryId)
                    &&
                    (x.IsActive == true)
                    );

                return eventSubscriptions.ToList<EventSubscription>();
            }
        }

        /// <summary>
        /// Gets the recipients.
        /// </summary>
        /// <param name="eventLogId">The event log identifier.</param>
        /// <returns></returns>
        public List<EventSubscriptionRecipient> GetRecipients(long eventLogId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetEventSubscriptionRecipientsForEventLog(eventLogId).ToList<EventSubscriptionRecipient>();
                return list;
            }
        }
    }
}
