using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ContactLogReasonRepository
    {
        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void Save(ContactLogReason model, string userName)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                if (string.IsNullOrEmpty(model.CreateBy))
                {
                    model.CreateBy = userName;
                }
                if (model.CreateDate == null)
                {
                    model.CreateDate = System.DateTime.Now;
                }
                entities.ContactLogReasons.Add(model);
                entities.SaveChanges();
            }
        }
    }
}
