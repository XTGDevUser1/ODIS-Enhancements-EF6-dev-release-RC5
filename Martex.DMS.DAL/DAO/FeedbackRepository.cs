using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using System.Data;
using System.Data.Entity;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class FeedbackRepository : IRepository<Feedback>
    {
        /// <summary>
        /// Gets all.
        /// </summary>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public List<Feedback> GetAll()
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Adds the specified feedback record to database.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <returns></returns>
        public int Add(Feedback entity)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Feedbacks.Add(entity);
                dbContext.Entry(entity).State = EntityState.Added;
                dbContext.SaveChanges();
                return entity.ID;
            }
        }
        /// <summary>
        /// Updates the specified entity.
        /// </summary>
        /// <param name="entity">The entity.</param>
        /// <exception cref="System.NotImplementedException"></exception>
        public void Update(Feedback entity)
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
        /// Gets the specified id.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public Feedback Get<T1>(T1 id)
        {
            throw new NotImplementedException();
        }
        /// <summary>
        /// Gets all for.
        /// </summary>
        /// <typeparam name="T1">The type of the 1.</typeparam>
        /// <param name="id">The id.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        /// <exception cref="System.NotImplementedException"></exception>
        public List<Feedback> GetAllFor<T1>(T1 id, DAL.Common.PageCriteria pageCriteria)
        {
            throw new NotImplementedException();
        }
    }
}
