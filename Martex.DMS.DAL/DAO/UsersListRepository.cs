using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAO;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class UsersListRepository : IRepository<SearchUsersResult>
    {
        public List<SearchUsersResult> GetAll()
        {
            throw new NotImplementedException();
        }

        public int Add(SearchUsersResult entity)
        {
            throw new NotImplementedException();
        }

        public void Update(SearchUsersResult entity)
        {
            throw new NotImplementedException();
        }

        public void Delete<T1>(T1 id)
        {
            throw new NotImplementedException();
        }

        public SearchUsersResult Get<T1>(T1 id)
        {
            throw new NotImplementedException();
        }

        /// <summary>
        /// Gets all for.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <returns></returns>
        public List<SearchUsersResult> GetAllFor(Guid? id, Common.PageCriteria pageCriteria)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetUsers(id, null, 1, 100, 10, "UserName", "ASC").ToList<SearchUsersResult>();
                return list;
            }
        }
    }
}
