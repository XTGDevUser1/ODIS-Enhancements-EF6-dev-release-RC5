using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.Common;
using System.Net;
using System.Net.Security;
using System.ServiceModel;
using Martex.DMS.BLL.Hagerty;
using log4net;
using Newtonsoft.Json;


namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade to Manage Vehicles
    /// </summary>
    public class VehicleFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VehicleFacade));
        #endregion

        #region Public Methods
        /// <summary>
        /// Gets the member vehicles.
        /// </summary>
        /// <param name="memberId">The member id.</param>
        /// <param name="membershipId">The membership id.</param>
        /// <param name="programID">The program ID.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <param name="isAHagertyProgram">if set to <c>true</c> [is A hagerty program].</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Invalid event name</exception>
        public List<Vehicles_Result> GetMemberVehicles(int memberId, int membershipId, int programID, string eventSource, string loggedInUserName, int serviceRequestID, string sessionID, bool isAHagertyProgram)
        {
            logger.InfoFormat("VehicleFacade - GetMemberVehicles(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                memberId = memberId,
                membershipId = membershipId,
                programID = programID,
                eventSource = eventSource,
                loggedInUserName = loggedInUserName,
                serviceRequestID = serviceRequestID,
                sessionID = sessionID,
                isAHagertyProgram = isAHagertyProgram
            }));
            VehicleRepository repository = new VehicleRepository();
            //KB: Using the parameter isAHagertyProgram - A Hagerty program is one whose client = Hagerty and is Hagerty Main program or one of the children of Hagerty Main program.
            if (isAHagertyProgram)
            {
                logger.Info("Current program is a Hagerty Program. Attempting to invoke the web service");
                int? memberNumber = repository.GetMemberNumber(membershipId);
                List<Vehicles_Result> vehicleResult = new List<Vehicles_Result>();
                string anyErrorsOnServiceCall = string.Empty;
                if (memberNumber.HasValue)
                {
                    try
                    {
                        EndpointAddress wsAddress = new EndpointAddress(AppConfigRepository.GetValue(AppConfigConstants.Hagerty_Service_URI));
                        WSHttpBinding wsBinding = new WSHttpBinding("WSHttpBinding_INMCService");

                        using (NMCServiceClient requestClient = new NMCServiceClient(wsBinding, wsAddress))
                        {
                            requestClient.ClientCredentials.UserName.UserName = AppConfigRepository.GetValue(AppConfigConstants.Hagerty_Service_UserName);
                            requestClient.ClientCredentials.UserName.Password = AppConfigRepository.GetValue(AppConfigConstants.Hagerty_Service_Password);

                            ResponseData responseData = requestClient.GetResponseData(memberNumber.Value);

                            if (responseData != null)
                            {
                                int i = 0;
                                foreach (PolicyVehicles pv in responseData.PolicyVehicleResponse)
                                {
                                    Vehicles_Result result = new Vehicles_Result();
                                    result.ID = ++i;
                                    result.Make = pv.Make;
                                    result.Model = pv.Model;
                                    result.Year = pv.Year;
                                    //RA: Default to Auto if nothing is returned
                                    if (string.IsNullOrEmpty(pv.VehicleType))
                                    {
                                        result.VehicleTypeID = 1;
                                        result.VehicleTypeName = "Auto";
                                    }
                                    else
                                    {
                                        result.VehicleTypeID = repository.GetVehicleTypeId(pv.VehicleType);
                                        if (result.VehicleTypeID == 1)
                                        {
                                            result.VehicleTypeName = "Auto";
                                        }
                                        else
                                        {
                                            result.VehicleTypeName = pv.VehicleType;
                                        }
                                    }
                                    result.VehicleCategoryID = 1;
                                    result.FromCase = 2;
                                    vehicleResult.Add(result);
                                }
                            }
                        }
                    }
                    catch (FaultException fex)
                    {
                        anyErrorsOnServiceCall = fex.Message;
                    }
                    catch (Exception ex)
                    {
                        anyErrorsOnServiceCall += ex.Message;
                    }
                }
                //For Event Log
                EventLogRepository eventLogRepository = new EventLogRepository();

                IRepository<Event> eventRepository = new EventRepository();
                Event theEvent = eventRepository.Get<string>(EventNames.RETRIEVE_HAGERTY_VEHICLE);

                if (theEvent == null)
                {
                    throw new DMSException("Invalid event name");
                }

                EventLog eventLog = new EventLog();
                eventLog.Source = eventSource;
                eventLog.EventID = theEvent.ID;
                eventLog.SessionID = sessionID;
                if (string.IsNullOrEmpty(anyErrorsOnServiceCall))
                {
                    eventLog.Description = "<Membership><MembershipID>" + membershipId + "</MembershipID></Membership>";
                }
                else
                {
                    eventLog.Description = "<Membership><MembershipID>" + membershipId + "</MembershipID><Error>" + anyErrorsOnServiceCall + "</Error></Membership>";
                }

                eventLog.CreateDate = DateTime.Now;
                eventLog.CreateBy = loggedInUserName;
                logger.InfoFormat("Trying to log the event {0}", EventNames.RETRIEVE_HAGERTY_VEHICLE);
                long eventLogId = eventLogRepository.Add(eventLog, serviceRequestID, EntityNames.SERVICE_REQUEST);
                return vehicleResult;
            }
            logger.Info("Current program is not a Hagerty program, so retrieving vehicles for member from the system");
            return repository.GetMemberVehicles(programID, memberId, membershipId);
        }

        /// <summary>
        /// Gets the vehicle type by programe.
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <returns></returns>
        public List<ProgramVehicleType> GetVehicleTypeByPrograme(int programId)
        {
            return new VehicleRepository().GetVehicleTypeByPrograme(programId);
        }

        /// <summary>
        /// Gets the vehicle.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>
        public Vehicle GetVehicle(int id)
        {
            return new VehicleRepository().GetVehicle(id);
        }

        /// <summary>
        /// Determines whether [is show commercial vehicle allowed] [the specified program id].
        /// </summary>
        /// <param name="programId">The program id.</param>
        /// <param name="configurationType">Type of the configuration.</param>
        /// <param name="updateKey">The update key.</param>
        /// <returns>
        ///   <c>true</c> if [is show commercial vehicle allowed] [the specified program id]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsShowCommercialVehicleAllowed(int programId, string configurationType, string updateKey)
        {
            ProgramMaintenanceRepository repository = new ProgramMaintenanceRepository();
            var result = repository.GetProgramInfo(programId, configurationType, null);
            bool allowUpdate = false;
            result.ForEach(x =>
            {
                if (x.Name == updateKey && x.Value.Equals("Yes", StringComparison.InvariantCultureIgnoreCase))
                {
                    allowUpdate = true;
                }
            });
            return allowUpdate;
        }

        public List<VINSearch_Result> SearchByVIN(string searchText, PageCriteria pc)
        {
            VehicleRepository repository = new VehicleRepository();
            return repository.SearchByVIN(searchText, pc);
        }

        //Lakshmi - Hagerty Integration 
        //No need to call Hagerty web service for Vehicle tab click.

        /// Gets the member vehicles.
        /// </summary>
        /// <param name="memberId">The member id.</param>
        /// <param name="membershipId">The membership id.</param>
        /// <param name="programID">The program ID.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="loggedInUserName">Name of the logged in user.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">Invalid event name</exception>
        public List<Vehicles_Result> GetMemberVehicles(int memberId, int membershipId, int programID, string eventSource, string loggedInUserName, int serviceRequestID, string sessionID)
        {
            logger.InfoFormat("VehicleFacade - GetMemberVehicles(), Parameters : {0}", JsonConvert.SerializeObject(new
            {
                memberId = memberId,
                membershipId = membershipId,
                programID = programID,
                eventSource = eventSource,
                loggedInUserName = loggedInUserName,
                serviceRequestID = serviceRequestID,
                sessionID = sessionID
            }));
            VehicleRepository repository = new VehicleRepository();
            logger.Info("Current program is not a Hagerty program, so retrieving vehicles for member from the system");
            return repository.GetMemberVehicles(programID, memberId, membershipId);
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="model"></param>
        /// <param name="LoggedInUserName"></param>
        public void UpdateVehicleTypeDetails(Vehicle model, string LoggedInUserName)
        {
            VehicleRepository repository = new VehicleRepository();
            repository.UpdateVehicleTypeDetails(model, LoggedInUserName);
        }
        #endregion
    }
}
