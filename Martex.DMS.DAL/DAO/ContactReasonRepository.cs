using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// Contact Reason Repository
    /// </summary>
    public class ContactReasonRepository
    {
        /// <summary>
        /// Gets the specified id.
        /// </summary>
        /// <param name="Id">The id.</param>
        /// <returns></returns>
        public ContactReason Get(int Id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.ContactReasons.Where(a => a.ID == Id).SingleOrDefault();
            }
        }
    }
}
