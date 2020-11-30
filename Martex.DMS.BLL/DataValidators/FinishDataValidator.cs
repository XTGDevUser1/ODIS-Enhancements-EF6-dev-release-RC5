using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using log4net;

namespace Martex.DMS.BLL.DataValidators
{
    public class FinishDataValidator: AbstractServiceRequestDataValidator
    {
        protected ServiceRepository serviceRequestRepository = new ServiceRepository();
        protected static readonly ILog logger = LogManager.GetLogger(typeof(FinishDataValidator));
        public override TabValidationStatus Validate(int serviceRequestID)
        {
            //TFS 267: If on the screen Status = Dispatched AND Select POs associated with this SR and none of them have PO Status IN ('Issued','Issued-Paid','Cancelled')
            //          then log an exception that reads - "Status cannot be "dispatched" if no PO's have been issued."
            logger.InfoFormat("Validation Finish tab for service request ID = {0}", serviceRequestID); 
            var sr = serviceRequestRepository.GetServiceRequestById(serviceRequestID);
            if (sr == null)
            {
                logger.WarnFormat("Could not find a service request with ID = {0}", serviceRequestID);
                return TabValidationStatus.VISITED_WITH_NO_ERRORS;
            }
            return this.Validate(sr);            
        }

        /// <summary>
        /// Validates the specified service request.
        /// </summary>
        /// <param name="serviceRequest">The service request.</param>
        /// <returns></returns>
        public override TabValidationStatus Validate(DAL.ServiceRequest serviceRequest)
        {
            if (serviceRequest == null)
            {
                logger.Warn("Could not find a service request");
                return TabValidationStatus.VISITED_WITH_NO_ERRORS;
            }

            ClearExceptions(serviceRequest.ID);

            if ("Dispatched".Equals(serviceRequest.ServiceRequestStatu.Name, StringComparison.InvariantCultureIgnoreCase))
            {
                if (!serviceRequestRepository.HasPOsInStatuses(serviceRequest.ID, "Issued", "Issued-Paid", "Cancelled"))
                {
                    LogException(serviceRequest.ID, "Status cannot be Dispatched if no PO's have been issued");
                    return TabValidationStatus.VISITED_WITH_ERRORS;
                }
            }

            return TabValidationStatus.VISITED_WITH_NO_ERRORS;
        }

        public override RequestArea Area
        {
            get { return RequestArea.FINISH; }
        }
    }
}
