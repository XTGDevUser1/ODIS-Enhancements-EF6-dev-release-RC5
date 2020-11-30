using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;
using log4net;
using System.Transactions;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{

    /// <summary>
    /// 
    /// </summary>
    public class ClosedLoopFacade
    {
        #region Protected Methods
        
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(ClosedLoopFacade));

        #endregion

        #region Public Methods

        /// <summary>
        /// Updates the closed loop call results.
        /// </summary>
        /// <param name="callStatus">The call status.</param>
        /// <param name="serviceStatus">The service status.</param>
        /// <param name="entryID">Contact Log ID</param>
        /// <returns></returns>
        public bool UpdateClosedLoopCallResults(string callStatus, string serviceStatus, string entryID)
        {
            try
            {
                logger.InfoFormat("Inside ClosedLoopCall method");
                logger.InfoFormat("Verifying Input Values: Callstatus - " + callStatus + "; ServiceStatus - " + serviceStatus + "; EntryID - " + entryID);
                
                int intEntryID = 0;
                if (entryID.IndexOf("_") > 0)
                    //Should be prefixed with 'DMS_####'
                    intEntryID = Convert.ToInt32(entryID.Substring(entryID.IndexOf("_") + 1));
                else
                    intEntryID = Convert.ToInt32(entryID);

                VerifyEntryID(intEntryID);
                logger.InfoFormat("Started Processing for Entry ID - {0}" , intEntryID);
                CreateRecord(callStatus, serviceStatus, intEntryID);
                logger.InfoFormat("Finished Processing");
                
                return true;
            }
             catch (System.Exception ex)
            {
                logger.Error(ex.Message, ex);
                throw new DMSException(ex.Message, ex);
                
            }


        }

        #endregion

        #region Private Methods

        /// <summary>
        /// Gets the contact action ID.
        /// </summary>
        /// <param name="statusValue">The status value.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to find Contact Action</exception>
        private int GetContactActionID(string statusValue)
        {
            ContactAction contactAction = null;
            switch (statusValue.ToLower())
            {
                case "complete":
                    contactAction = new ContactStaticDataRepository().GetContactActionByName("ServiceArrived", "ClosedLoop");
                    break;
                case "notarrived":
                    contactAction = new ContactStaticDataRepository().GetContactActionByName("ServiceNotArrived", "ClosedLoop");
                    break;
                case "noresponse":
                    contactAction = new ContactStaticDataRepository().GetContactActionByName("Unknown", "ClosedLoop");
                    break;
                default:
                    contactAction = new ContactStaticDataRepository().GetContactActionByName("NoAnswer", "ClosedLoop");
                    break;

            }

            if (contactAction == null)
            {
                throw new DMSException("Unable to find Contact Action");
            }

            return contactAction.ID;
        }

        /// <summary>
        /// Gets the closed loop status ID.
        /// </summary>
        /// <param name="serviceStatus">The service status.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to get closed loop status id</exception>
        private int GetClosedLoopStatusID(string serviceStatus)
        {
            ClosedLoopRepository facade = new ClosedLoopRepository();
            ClosedLoopStatu closedLoopStatus = null;
            switch (serviceStatus.ToLower())
            {
                case "complete":
                    closedLoopStatus = facade.GetClosedLoopStatusByName("ServiceArrived");
                    break;
                case "notarrived":
                    closedLoopStatus = facade.GetClosedLoopStatusByName("ServiceNotArrived");
                    break;
                case "noresponse":
                    closedLoopStatus = facade.GetClosedLoopStatusByName("Unknown");
                    break;
                default:
                    closedLoopStatus = facade.GetClosedLoopStatusByName("NoAnswer");
                    break;
            }

            if (closedLoopStatus == null)
            {
                throw new DMSException("Unable to get closed loop status id");
            }

            return closedLoopStatus.ID;
        }

        /// <summary>
        /// Gets the service request status ID.
        /// </summary>
        /// <param name="serviceStatus">The service status.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Unable to get the Service request Status Record</exception>
        private int? GetServiceRequestStatusID(string serviceStatus)
        {
            ServiceRequestRepository facade = new ServiceRequestRepository();
            ServiceRequestStatu serviceEntity = null;

            switch (serviceStatus)
            {
                    case "Complete":
                    serviceEntity = facade.GetServiceRequestStatus(serviceStatus);
                    break;

            }

            if (serviceEntity == null)
            {
                throw new DMSException("Unable to get the Service request Status Record");
            }

            return serviceEntity.ID;
        }

        /// <summary>
        /// Creates the record.
        /// </summary>
        /// <param name="callStatus">The call status.</param>
        /// <param name="serviceStatus">The service status.</param>
        /// <param name="entryID">The entry ID.</param>
        private void CreateRecord(string callStatus, string serviceStatus, int entryID)
        {
            ClosedLoopRepository closedLoopRepo = new ClosedLoopRepository();
            ContactLogAction contactLogAction = new ContactLogAction();
            ContactLogActionRepository contactLogActionRepository = new ContactLogActionRepository();
            contactLogAction.ContactActionID = GetContactActionID(serviceStatus);
            contactLogAction.ContactLogID = entryID;

            ServiceRequestRepository serviceRequestRepository = new ServiceRequestRepository();
            //Code to Rerieve the Service Request ID FROM Contact Log Link Table based on Entity Type.

            var serviceRequestId = contactLogActionRepository.GetServiceRequestID(entryID);
            if(serviceRequestId == null)
            {
                throw new DMSException("Unable to retrieve service request details");
            }
            ServiceRequest serviceRequest = serviceRequestRepository.GetById(serviceRequestId.Value);

            //Only update SR status if complete
            if (serviceStatus == "Complete")
                serviceRequest.ServiceRequestStatusID = GetServiceRequestStatusID(serviceStatus);

            serviceRequest.ClosedLoopStatusID = GetClosedLoopStatusID(serviceStatus);

            using (TransactionScope tran = new TransactionScope())
            {
                contactLogActionRepository.Save(contactLogAction, "system");
                serviceRequestRepository.UpdateServiceRequest(serviceRequest, "system");
                if ("Complete".Equals(serviceStatus, StringComparison.InvariantCultureIgnoreCase))
                {
                    var eventLogRepository = new EventLogRepository();
                    eventLogRepository.LogEventForServiceRequestStatus(serviceRequest.ID, EventNames.SERVICE_COMPLETED, "Dispatch Service", null, null, "system");
                }
                tran.Complete();
            }


        }

        /// <summary>
        /// Verifies the service status for call status.
        /// </summary>
        /// <param name="callStatus">The call status.</param>
        /// <param name="serviceStatus">The service status.</param>
        /// <exception cref="DMSException">Invalid Service Status value</exception>
        private void VerifyServiceStatusForCallStatus(string callStatus, string serviceStatus)
        {
            if (callStatus.Equals("Answered", StringComparison.OrdinalIgnoreCase))
            {
                if (!serviceStatus.Equals("NotArrived", StringComparison.OrdinalIgnoreCase) && !(serviceStatus.Equals("NoResponse", StringComparison.OrdinalIgnoreCase)) && !(serviceStatus.Equals("Complete", StringComparison.OrdinalIgnoreCase)))
                {
                    throw new DMSException("Invalid Service Status value");
                }
            }
        }

        /// <summary>
        /// Verifies the call status input.
        /// </summary>
        /// <param name="callStatus">The call status.</param>
        /// <exception cref="DMSException">Call Status supplied values is invalid.</exception>
        private void VerifyCallStatusInput(string callStatus)
        {
            if (!(callStatus.Equals("Answered") || callStatus.Equals("NoAnswer")))
            {
                throw new DMSException("Call Status supplied values is invalid.");
            }
        }

        /// <summary>
        /// Verifies the entry ID.
        /// </summary>
        /// <param name="entryID">The entry ID.</param>
        /// <exception cref="DMSException">Invalid entry id</exception>
        private void VerifyEntryID(int entryID)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                ContactLog entity = entities.ContactLogs.Where(u => u.ID == entryID).FirstOrDefault();
                if (entity == null)
                {
                    throw new DMSException("Invalid entry id");
                }
            }
        }
        #endregion
    }
}
