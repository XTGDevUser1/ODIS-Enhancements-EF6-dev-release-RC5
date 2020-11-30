using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Data.Entity;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class EventRepository : IRepository<Event>
    {
        //LogManualNotificationEvent
        /// <summary>
        /// Gets all.
        /// </summary>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public List<Event> GetAll()
        {
           
            throw new NotImplementedException();
        }
        /// <summary>
        /// Adds the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public int Add(Event entity)
        {
            throw new NotImplementedException();
        }
        /// <summary>
        /// Updates the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <exception cref="System.NotImplementedException"></exception>
        public void Update(Event entity)
        {
            throw new NotImplementedException();
        }
        /// <summary>
        /// Deletes the specified id.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <exception cref="System.NotImplementedException"></exception>
        public void Delete<T1>(T1 id)
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Gets the event for the specified name.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public Event Get<T1>(T1 name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                string criteria = name.ToString();
                var theEvent = dbContext.Events.Where(x => x.Name == criteria)
                                        .Include(e => e.EventCategory)
                                        .Include(e => e.EventType)
                                        .FirstOrDefault();

                return theEvent;
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="name"></param>
        /// <param name="category"></param>
        /// <returns></returns>
        public Event Get(string name, string category)
        {
            using(DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.Events.Where(u => u.Name.Equals(name) && u.EventCategory.Name.Equals(category)).FirstOrDefault();
            }
        }
        /// <summary>
        /// Gets all for.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public List<Event> GetAllFor<T1>(T1 id, DAL.Common.PageCriteria pageCriteria)
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Gets the current user for event.
        /// </summary>
        /// <param name="eventLogID">The event log unique identifier.</param>
        /// <param name="eventSubscriptionID">The event subscription unique identifier.</param>
        /// <returns></returns>
        public List<CurrentUserForEvent_Result> GetCurrentUserForEvent(int eventLogID, int eventSubscriptionID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetCurrentUserForEvent(eventLogID, eventSubscriptionID).ToList<CurrentUserForEvent_Result>();
                return list;
            }
        }


    }
}
