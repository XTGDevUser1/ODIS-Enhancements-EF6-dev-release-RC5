using Martex.DMS.DAL.Common;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class DispatchProcessingServiceRepository
    {
        /// <summary>
        /// Gets the contact category ID.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public int GetContactCategoryID(string name = "ClosedLoop")
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.ContactCategories.Where(n => n.Name.Equals(name, StringComparison.OrdinalIgnoreCase)).FirstOrDefault().ID;
            }
        }
        /// <summary>
        /// Gets the contact type ID.
        /// </summary>
        /// <returns></returns>
        public int GetContactTypeID()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.ContactTypes.Where(n => n.Name.Equals("System", StringComparison.OrdinalIgnoreCase)).FirstOrDefault().ID;
            }
        }
        /// <summary>
        /// Gets the contact source ID.
        /// </summary>
        /// <returns></returns>
        public int GetContactSourceID()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                int contactCategoryID = GetContactCategoryID();
                return entities.ContactSources.Where(n => n.Name.Equals("ServiceRequest", StringComparison.OrdinalIgnoreCase))
                                              .Where(c => c.ContactCategoryID == contactCategoryID)
                                              .FirstOrDefault().ID;
            }
        }
        /// <summary>
        /// Gets the contact reason ID.
        /// </summary>
        /// <returns></returns>
        public int GetContactReasonID()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                int contactCategoryID = GetContactCategoryID();
                return entities.ContactReasons.Where(n => n.Name.Equals("Verify Service", StringComparison.OrdinalIgnoreCase))
                                              .Where(c => c.ContactCategoryID == contactCategoryID)
                                              .FirstOrDefault().ID;
            }
        }
        /// <summary>
        /// Gets the contact action ID.
        /// </summary>
        /// <returns></returns>
        public int GetContactActionID()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                return entities.ContactActions.Where(n => n.Name.Equals("Pending", StringComparison.OrdinalIgnoreCase))
                                              .Where(c => c.ContactCategoryID == null)
                                              .FirstOrDefault().ID;
            }
        }
        /// <summary>
        /// Gets the template ID.
        /// </summary>
        /// <param name="TollFreeNumber">The toll free number.</param>
        /// <returns></returns>
        public int? GetTemplateID(string sourceSystem, string tollFreeNumber)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                if(SourceSystemName.MEMBER_MOBILE.Equals(sourceSystem))
                {
                    return entities.Templates.Where(u => u.Name.Equals("ClosedLoopSMS", StringComparison.OrdinalIgnoreCase)).FirstOrDefault().ID;
                }                
                if (string.IsNullOrWhiteSpace(tollFreeNumber))
                {
                    return entities.Templates.Where(u => u.Name.Equals("ClosedLoopSMSNoTollFreeNumber", StringComparison.OrdinalIgnoreCase)).FirstOrDefault().ID;
                }
                return entities.Templates.Where(u => u.Name.Equals("ClosedLoopSMSTollFreeNumber", StringComparison.OrdinalIgnoreCase)).FirstOrDefault().ID;
            }
        }
        /// <summary>
        /// Updates the service request closed loop status.
        /// </summary>
        public void UpdateServiceRequestClosedLoopStatus()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                entities.UpdateServiceRequestClosedLoopStatus();
            }
        }
        /// <summary>
        /// Updates the service request status.
        /// </summary>
        public void UpdateServiceRequestStatus()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                entities.UpdateServiceRequestStatus();
            }
        }
        /// <summary>
        /// Prepares the service request export.
        /// </summary>
        public void PrepareServiceRequestExport()
        {
            using (DMSEntities entities = new DMSEntities())
            {
                entities.PrepareServiceRequestExport();
            }
        }
    }
}
