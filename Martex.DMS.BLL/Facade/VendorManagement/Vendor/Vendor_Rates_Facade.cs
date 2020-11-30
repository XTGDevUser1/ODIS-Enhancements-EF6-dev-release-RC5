using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAO;
using System.Transactions;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorManagementFacade
    {
        /// <summary>
        /// Gets the vendor rates and schedules.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Vendor_Rates_Schedules_Result> GetVendorRatesAndSchedules(PageCriteria criteria, int vendorID)
        {
            return vendorManagement_Repository.GetVendorRatesAndSchedules(criteria, vendorID);
        }

        /// <summary>
        /// Deletes the vendor rate and schedules.
        /// </summary>
        /// <param name="contractRateScheduleID">The contract rate schedule ID.</param>
        public void DeleteVendorRateAndSchedules(int contractRateScheduleID)
        {
            vendorManagement_Repository.DeleteVendorRateAndSchedules(contractRateScheduleID);
        }


        /// <summary>
        /// Gets the vendor contract count.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public int GetVendorContractCount(int vendorID)
        {
            return vendorManagement_Repository.GetVendorContractCount(vendorID);
        }


        /// <summary>
        /// Gets the existing contracts for vendor.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Contract> GetExistingContractsForVendor(int vendorID)
        {
            return vendorManagement_Repository.GetExistingContractsForVendor(vendorID);

        }

        /// <summary>
        /// Gets the vendor contract.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public Contract GetVendorContract(int vendorID)
        {
            return vendorManagement_Repository.GetVendorContract(vendorID);
        }

        /// <summary>
        /// Saves the contract rate schedule.
        /// </summary>
        /// <param name="model">The model.</param>
        public void SaveContractRateSchedule(VendorRatesModel model,string userName)
        {
            ContractRateSchedule crs = new ContractRateSchedule();
            var current = model.CurrentRateSchedule;
            repository.SaveContractRateSchedule(current, userName);
        }
        /// <summary>
        /// Gets the vendor rate schedule details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="contractScheduleRateID">The contract schedule rate ID.</param>
        /// <returns></returns>
        public VendorRatesModel GetVendorRates(int vendorID, int? contractScheduleRateID, int? contractID = null, bool useVendorID = true)
        {
            VendorRatesModel model = new VendorRatesModel();
            if (useVendorID)
            {
                model.CurrentRateSchedule = vendorManagement_Repository.GetVendorRateScheduleDetails(vendorID, 0, true);
            }
            else
            {
                model.CurrentRateSchedule = vendorManagement_Repository.GetVendorRateScheduleDetails(vendorID, contractScheduleRateID.GetValueOrDefault(), false);
            }

            if (model.CurrentRateSchedule != null)
            {
                model.ServiceRates = repository.GetVendorServicesAndRates(model.CurrentRateSchedule.ContractRateScheduleID, null);
            }

            return model;
        }

        /// <summary>
        /// Creates the contract rate schedule record.
        /// </summary>
        /// <param name="contractID">The contract ID.</param>
        /// <param name="currentUser">The current user.</param>
        /// <returns></returns>
        public int CreateContractRateScheduleRecord(int vendorID, int contractID, string currentUser, string source = "/Application/VendorMaintenance/")
        {
            EventLogRepository eventLogRepo = new EventLogRepository();
            CommonLookUpRepository lookUpRepo = new CommonLookUpRepository();
            var crs = new ContractRateSchedule()
            {
                ContractID = contractID,
                CreateBy = currentUser,
                CreateDate = DateTime.Now,
                IsActive = true
            };
            using (TransactionScope transaction = new TransactionScope())
            {
                logger.InfoFormat("Creating Contract Rate Schedule for the Contract ID {0}", contractID);
                // 1. Insert Contract Rate Schedule
                repository.AddContractRateSchedule(crs, "Pending");

                // 2. Inser Event Log.
                logger.InfoFormat("Creating Event Log Records for the Contract ID {0}", contractID);
                Event eventName = lookUpRepo.GetEvent(EventNames.ADD_CONTRACT_RATE_SCHEDULE);
                EventLog eventLog = new EventLog()
                {
                    Source = "",
                    Description = "",
                    NotificationQueueDate = null,
                    CreateBy = currentUser,
                    CreateDate = DateTime.Now,
                    EventID = eventName.ID
                };
                long eventLogID = eventLogRepo.Add(eventLog);
                eventLogRepo.CreateLinkRecord(eventLogID, EntityNames.VENDOR, vendorID);
                eventLogRepo.CreateLinkRecord(eventLogID, EntityNames.CONTRACT, vendorID);

                // 3. Call SP 
                logger.InfoFormat("Calling SP to Add Contract Rate Schedul for contract ID {0}", contractID);
                repository.AddVendorContractRateSchedule(contractID, crs.ID, currentUser);


                transaction.Complete();
            }
            return crs.ID;
        }

        /// <summary>
        /// Gets the service ratings.
        /// </summary>
        /// <param name="vendorID">The vendor unique identifier.</param>
        /// <returns></returns>
        public List<VendorServiceRatings_Result> GetServiceRatings(int vendorID)
        {
            return repository.GetServiceRatings(vendorID);
        }

        public List<VendorDetailsForReport_Result> GetVendorDetailsForReport(int vendorID)
        {
            return repository.GetVendorDetailsForReport(vendorID);
        }

        public List<RateSchedulesForReport_Result> GetRateSchedulesForReport(int rateScheduleID)
        {
            return repository.GetRateSchedulesForReport(rateScheduleID);
        }
        

    }
}
