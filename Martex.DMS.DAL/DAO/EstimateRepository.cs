using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO
{
   public class EstimateRepository
    {
       public ServiceRequestEstimate_Result GetServiceRequestEstimate(int serviceRequestID)
       {
           using (DMSEntities dbContext = new DMSEntities())
           {
               return dbContext.GetServiceRequestEstimate(serviceRequestID).FirstOrDefault();
           }
       }

       public ServiceRequestDeclineReason GetServiceRequestDeclineReasonById(int? id)
       {
           using (DMSEntities dbContext = new DMSEntities())
           {
               return dbContext.ServiceRequestDeclineReasons.Where(a => a.ID == id).FirstOrDefault();
           }
       }
    }
}
