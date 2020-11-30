using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;

namespace Martex.DMS.BLL.DataValidators
{
    public class ServiceDataValidator : AbstractServiceRequestDataValidator
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(ServiceDataValidator));
        public override TabValidationStatus Validate(int serviceRequestID)
        {
            logger.InfoFormat("Validation Service tab for service request ID = {0}", serviceRequestID); 
            // Clear off the errors related to this area
            ClearExceptions(serviceRequestID);
            // Validate the errors and log exceptions to ServiceRequestException table.

            return TabValidationStatus.VISITED_WITH_NO_ERRORS;
        }

        public override RequestArea Area
        {
            get
            {
                return RequestArea.SERVICE;
            }
            
        }
    }
}
