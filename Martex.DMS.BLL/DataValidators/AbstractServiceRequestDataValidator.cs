using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAO;

namespace Martex.DMS.BLL.DataValidators
{
    public abstract class AbstractServiceRequestDataValidator : IServiceRequestDataValidator
    {
        protected ServiceRequestRepository srRepository = new ServiceRequestRepository();
        protected ServiceRequest GetServiceRequest(int serviceRequestID)
        {
           
            var sr = srRepository.GetById(serviceRequestID);
            return sr;
        }

        protected virtual void ClearExceptions(int serviceRequestID)
        {
            srRepository.ClearExceptions(serviceRequestID, Area.ToString());
        }

        protected virtual void LogException(int serviceRequestID, string message)
        {
            srRepository.LogException(serviceRequestID, Area.ToString(), message);
        }

        public abstract TabValidationStatus Validate(int serviceRequestID);


        public abstract RequestArea Area
        {
            get;
        }

        public virtual TabValidationStatus Validate(ServiceRequest serviceRequest)
        {
            throw new NotImplementedException();
        }
    }
}
