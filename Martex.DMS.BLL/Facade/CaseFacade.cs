using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Transactions;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using log4net;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// 
    /// </summary>
    public class CaseFacade
    {
        #region Protected Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(CaseFacade));



        /// <summary>
        /// The case repository
        /// </summary>
        CaseRepository repository = new CaseRepository();

        #endregion

        #region Public Methods

        /// <summary>
        /// Gets the case by id.
        /// </summary>
        /// <param name="caseid">The caseid.</param>
        /// <returns></returns>
        public Case GetCaseById(int caseid)
        {           
            return repository.GetCaseById(caseid);
        }

        /// <summary>
        /// Updates the vehicle information.
        /// </summary>
        /// <param name="caseId">The case id.</param>
        /// <param name="serviceRequestId">The service request id.</param>
        /// <param name="programId">The program id.</param>
        /// <param name="vehicle">The vehicle.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <exception cref="DMSException">Invalid event name  + EventNames.LEAVE_VEHICLE_TAB</exception>
        public static void UpdateVehicleInformation(int caseId, int serviceRequestId, int programId, Vehicle vehicle, string eventSource, string loggedInUserName, string sessionID, string mainTabName)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                if (mainTabName == "VehicleTab")
                {
                    //For Event Log
                    IRepository<Event> eventRepository = new EventRepository();
                    EventLogRepository eventLogRepository = new EventLogRepository();
                    Event theEvent = eventRepository.Get<string>(EventNames.SAVE_VEHICLE_TAB);

                    if (theEvent == null)
                    {
                        throw new DMSException("Invalid event name " + EventNames.SAVE_VEHICLE_TAB);
                    }

                    EventLog eventLog = new EventLog();
                    eventLog.Source = eventSource;
                    eventLog.EventID = theEvent.ID;
                    eventLog.SessionID = sessionID;
                    eventLog.Description = "Save Vehicle tab";
                    eventLog.CreateDate = DateTime.Now;
                    eventLog.CreateBy = loggedInUserName;
                    logger.InfoFormat("Trying to log the event {0}", EventNames.SAVE_VEHICLE_TAB);
                    long eventLogId = eventLogRepository.Add(eventLog, serviceRequestId, EntityNames.SERVICE_REQUEST);
                    logger.Info("Created Event Log and link records.");

                }
                var serviceRequestRepository = new ServiceRequestRepository();
                CaseRepository repository = new CaseRepository();
                repository.UpdateVehicleInformation(caseId, programId, vehicle, loggedInUserName);
                logger.InfoFormat("Updated vehicle information on Case for case id : {0}", caseId);

                var c = repository.GetCaseById(caseId);
                var sr = serviceRequestRepository.GetById(serviceRequestId);
                int? towCategoryID = null;

                

                logger.Info("Determine service eligibility");
                if (sr.IsPossibleTow.GetValueOrDefault())
                {
                    var pc = ReferenceDataRepository.GetProductCategoryByName("Tow");
                    towCategoryID = pc.ID;
                }

                var serviceFacade = new ServiceFacade();
                serviceFacade.UpdateServiceEligibility(c.MemberID, c.ProgramID, sr.ProductCategoryID, sr.PrimaryProductID, c.VehicleTypeID, c.VehicleCategoryID, towCategoryID, serviceRequestId, caseId, loggedInUserName, SourceSystemName.DISPATCH);

                
                serviceRequestRepository.UpdateTabStatus(serviceRequestId, TabConstants.VehicleTab, loggedInUserName);
                logger.Info("Updated Vehicle tab status on service request");

                


                tran.Complete();
            }
        }

        /// <summary>
        /// Gets the ContactDeclinedReason name by id.
        /// </summary>
        /// <param name="caseid">The caseid.</param>
        /// <returns></returns>
        public ContactEmailDeclineReason GetDeclinedReasonById(int reasonid)
        {
            return repository.DeclinedReasonById(reasonid);
        }

        //Lakshmi
        public void updateCaseMemberNo(int svcreqNo, int memberid, string memberno, string username, string sessionID)
        {
            repository.UpdateMemberNoInCase(svcreqNo, memberid, memberno, username);

            IRepository<Event> eventRepository = new EventRepository();
            EventLogRepository eventLogRepository = new EventLogRepository();
            Event theEvent = eventRepository.Get<string>(EventNames.UPDATE_CASE);

            if (theEvent == null)
            {
                throw new DMSException("Invalid event name " + EventNames.UPDATE_CASE);
            }

            EventLog eventLog = new EventLog();
            eventLog.Source = "/History/UpdateMembershipNoInCase";
            eventLog.EventID = theEvent.ID;
            eventLog.SessionID = sessionID;
            eventLog.Description = "Added member number " + memberno + " for Service Request " + svcreqNo;
            eventLog.CreateDate = DateTime.Now;
            eventLog.CreateBy = username;
            logger.InfoFormat("Trying to log the event {0}", EventNames.UPDATE_CASE);
            long eventLogId = eventLogRepository.Add(eventLog, svcreqNo, EntityNames.SERVICE_REQUEST);
            logger.Info("Created Event Log for Updating Member Info in case");
        }

        #endregion
    }
}
