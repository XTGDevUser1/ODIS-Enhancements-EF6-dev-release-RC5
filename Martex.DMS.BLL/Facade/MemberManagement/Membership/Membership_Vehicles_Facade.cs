using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Transactions;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Facade
{
    public partial class MemberManagementFacade
    {
        //1. Get list of vehicles

        /// <summary>
        /// Gets the vehicles by membership.
        /// </summary>
        /// <param name="membershipID">The membership ID.</param>
        /// <returns></returns>
        public List<Vehicles_Result> GetVehiclesByMembership(int membershipID)
        {
            return repository.GetVehiclesByMembership(membershipID);
        }
        
        //2. Save
        /// <summary>
        /// Saves the vehicles for membership.
        /// </summary>
        /// <param name="vehicle">The vehicle.</param>
        /// <param name="eventSource">The event source.</param>
        /// <param name="currentUser">The current user.</param>
        /// <param name="sessionID">The session ID.</param>
        public void SaveVehiclesForMembership(Vehicle vehicle, string eventSource, string currentUser, string sessionID)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                VehicleRepository vehicleRepository = new VehicleRepository();
                if (vehicle.ID > 0)
                {
                    vehicle.ModifyBy = currentUser;
                    vehicle.ModifyDate = DateTime.Now;
                }
                vehicleRepository.AddOrUpdateVehicle(vehicle, null, (vehicle.ID == 0));

                logger.Info("Vehicle data saved successfully");
                EventLoggerFacade eventLogFacade = new EventLoggerFacade();
                eventLogFacade.LogEvent(eventSource, EventNames.ADD_VEHICLE, string.Empty, currentUser, vehicle.MembershipID, EntityNames.MEMBERSHIP, sessionID);

                logger.Info("Event log and link records created successfully");
                tran.Complete();
            }
        }

        /// <summary>
        /// Deletes the vehicle.
        /// </summary>
        /// <param name="vehicleID">The vehicle ID.</param>
        public void DeleteVehicle(int vehicleID)
        {
            VehicleRepository repository = new VehicleRepository();
            repository.TryDelete(vehicleID);
        }
    }
}
