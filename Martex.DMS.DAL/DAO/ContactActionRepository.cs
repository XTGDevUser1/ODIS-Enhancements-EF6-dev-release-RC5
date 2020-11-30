using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// Contact Action Repository
    /// </summary>
    public class ContactActionRepository
    {
        /// <summary>
        /// Gets the specified id.
        /// </summary>
        /// <param name="Id">The id.</param>
        /// <returns></returns>
        public ContactAction Get(int Id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContactActions.Where(a => a.ID == Id).SingleOrDefault();
            }
        }
    }
}
