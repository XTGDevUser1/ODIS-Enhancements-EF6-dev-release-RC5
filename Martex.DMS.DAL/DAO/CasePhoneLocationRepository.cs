using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class CasePhoneLocationRepository
    {

        /// <summary>
        /// Gets the specified case id.
        /// </summary>
        /// <param name="caseId">The case id.</param>
        /// <returns></returns>
        public CasePhoneLocation Get(int caseId)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                CasePhoneLocation result = entities.CasePhoneLocations.Where(u => u.CaseID == caseId).FirstOrDefault();
                return result;
            }
        }

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        public void  Save(CasePhoneLocation model)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                entities.CasePhoneLocations.Add(model);
                entities.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the by inbound call id.
        /// </summary>
        /// <param name="inboundCallId">The inbound call id.</param>
        /// <returns></returns>
        public CasePhoneLocation GetByInboundCallId(int inboundCallId)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                CasePhoneLocation result = entities.CasePhoneLocations.Where(u => u.InboundCallID == inboundCallId).FirstOrDefault();
                return result;
            }
        }
    }
    
}
