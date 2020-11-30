using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.DataValidators
{
    public enum TabValidationStatus : int
    {
        NOT_VISITED = 0,
        VISITED_WITH_NO_ERRORS = 1,
        VISITED_WITH_ERRORS = 2
    }
    public enum RequestArea : int
    {
        START = 0,
        MEMBER,
        VEHICLE,
        SERVICE,
        MAP,
        ESTIMATE,
        DISPATCH,
        PO,
        PAYMENT,
        ACTIVITY,
        FINISH
    }
    /// <summary>
    /// Interface that defines the contract for ServiceRequest data validators.
    /// </summary>
    public interface IServiceRequestDataValidator
    {
        /// <summary>
        /// Validate the service request data. The attributes to be considered by the validator are in conjunction with the Area.
        /// </summary>
        /// <param name="serviceRequestID"></param>
        /// <returns></returns>
        TabValidationStatus Validate(int serviceRequestID);

        /// <summary>
        /// Validates the specified service request.
        /// </summary>
        /// <param name="serviceRequest">The service request.</param>
        /// <returns></returns>
        TabValidationStatus Validate(ServiceRequest serviceRequest);
        /// <summary>
        /// The area that the validator considers while validating the service request data.
        /// </summary>
        RequestArea Area { get; }
    }
}
