using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using log4net;
using Martex.DMS.DAO;

namespace Martex.DMS.BLL.DataValidators
{
    public class MemberDataValidator : AbstractServiceRequestDataValidator
    {
        protected static readonly ILog logger = LogManager.GetLogger(typeof(MemberDataValidator));
        public override TabValidationStatus Validate(int serviceRequestID)
        {
            logger.InfoFormat("Validation Member tab for service request ID = {0}", serviceRequestID);            
            ClearExceptions(serviceRequestID);
            var sr = GetServiceRequest(serviceRequestID);
            if (sr != null)
            {
                try
                {
                    var c = sr.Case;
                    if (string.IsNullOrEmpty(c.ContactFirstName) || string.IsNullOrEmpty(c.ContactLastName))
                    {
                        LogException(serviceRequestID, "Contact First and Last fields are mandatory");
                        return TabValidationStatus.VISITED_WITH_ERRORS;
                    }
                }
                catch(Exception ex)
                {
                    LogException(serviceRequestID, ex.Message.ToString());
                }
            }
            return TabValidationStatus.VISITED_WITH_NO_ERRORS;
        }        

        public override RequestArea Area
        {
            get { return RequestArea.MEMBER; }
        }
    }
}
