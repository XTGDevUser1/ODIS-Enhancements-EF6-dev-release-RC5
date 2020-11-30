using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class ContactLogActionRepository
    {

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void Save(ContactLogAction model, string userName)
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
                entities.ContactLogActions.Add(model);
                entities.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the service request ID.
        /// </summary>
        /// <param name="contactLogID">The contact log ID.</param>
        /// <returns></returns>
        public int? GetServiceRequestID(int contactLogID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                var entityDetails = entities.Entities.Where(u => u.Name.Equals("ServiceRequest")).FirstOrDefault();
                
                var result = entities.ContactLogLinks.Where(r => r.ContactLogID == contactLogID)
                                                      .Where(r => r.EntityID == entityDetails.ID)
                                                      .FirstOrDefault();
                if (result == null)
                {
                    return null;
                }
                return result.RecordID;
            }
        }
    }
}
