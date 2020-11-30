using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorManagementRepository
    {
        /// <summary>
        /// Gets the vendor rates and schedules.
        /// </summary>
        /// <param name="criteria">The criteria.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Vendor_Rates_Schedules_Result> GetVendorRatesAndSchedules(PageCriteria criteria, int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorRatesSchedules(criteria.WhereClause, criteria.StartInd, criteria.EndInd, criteria.PageSize, criteria.SortColumn, criteria.SortDirection, vendorID).ToList();
            }
        }

        /// <summary>
        /// Deletes the vendor rate and schedules.
        /// </summary>
        /// <param name="contractRateScheduleID">The contract rate schedule ID.</param>
        /// <exception cref="DMSException">Hello !!</exception>
        public void DeleteVendorRateAndSchedules(int contractRateScheduleID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<ContractRateScheduleProduct> existingRecord = dbContext.ContractRateScheduleProducts.Where(u => u.ContractRateScheduleID == contractRateScheduleID).ToList();
                if (existingRecord == null || existingRecord.Count == 0)
                {
                    var existingContractRate = dbContext.ContractRateSchedules.Where(u => u.ID == contractRateScheduleID && u.IsActive == true).FirstOrDefault();
                    if (existingContractRate != null)
                    {
                        dbContext.Entry(existingContractRate).State = EntityState.Deleted;
                        dbContext.SaveChanges();
                    }
                }
                else
                {
                    throw new DMSException("Related record exists !");
                }
            }
        }

        /// <summary>
        /// Gets the vendor services and rates.
        /// </summary>
        /// <param name="contractID">The contract ID.</param>
        /// <param name="contractRateScheduleID">The contract rate schedule ID.</param>
        /// <returns></returns>
        public List<VendorServicesAndRates_Result> GetVendorServicesAndRates(int? contractRateScheduleID, int? vendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorServicesAndRates(contractRateScheduleID, vendorLocationID).ToList<VendorServicesAndRates_Result>();
            }
        }

        /// <summary>
        /// Gets the vendor rate schedule details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="contractScheduleRateID">The contract schedule rate ID.</param>
        /// <param name="useVendorID">if set to <c>true</c> [use vendor ID].</param>
        /// <returns></returns>
        public VendorRatesDetailsModel GetVendorRateScheduleDetails(int vendorID, int contractScheduleRateID, bool useVendorID = true)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {

                List<VendorRatesDetailsModel> list = new List<VendorRatesDetailsModel>();
                if (useVendorID)
                {
                    list = (from crs in dbContext.ContractRateSchedules
                            join c in dbContext.Contracts on crs.ContractID equals c.ID
                            where c.VendorID == vendorID
                            where c.IsActive == true
                            select new VendorRatesDetailsModel
                            {
                                ContractID = crs.ContractID ?? 0,
                                EndDate = crs.EndDate,
                                ContractRateScheduleID = crs.ID,
                                SignedDate = crs.SignedDate,
                                StartDate = crs.StartDate,
                                ContractRateScheduleStatus = crs.ContractRateScheduleStatu != null ? crs.ContractRateScheduleStatu.Name : null,
                                ContractStartDate = c.StartDate,
                                SignedBy = crs.SignedBy,
                                SignedByTitle = crs.SignedByTitle,
                                ContractRateScheduleStatusID = crs.ContractRateScheduleStatu.ID,
                                CreatedBy = crs.CreateBy,
                                ModifiedBy = crs.ModifyBy,
                                CreatedOn = crs.CreateDate,
                                ModifiedOn = crs.ModifyDate
                            }).ToList<VendorRatesDetailsModel>();
                    return list.OrderByDescending(u => u.StartDate).FirstOrDefault();

                }
                else // using contractratescheduleID
                {
                    list = (from crs in dbContext.ContractRateSchedules
                            join c in dbContext.Contracts on crs.ContractID equals c.ID
                            where crs.ID == contractScheduleRateID
                            select new VendorRatesDetailsModel
                            {
                                ContractID = crs.ContractID ?? 0,
                                EndDate = crs.EndDate,
                                ContractRateScheduleID = crs.ID,
                                SignedDate = crs.SignedDate,
                                StartDate = crs.StartDate,
                                ContractRateScheduleStatus = crs.ContractRateScheduleStatu != null ? crs.ContractRateScheduleStatu.Name : null,
                                ContractStartDate = c.StartDate,
                                SignedBy = crs.SignedBy,
                                SignedByTitle = crs.SignedByTitle,
                                ContractRateScheduleStatusID = crs.ContractRateScheduleStatu.ID,
                                CreatedBy = crs.CreateBy,
                                ModifiedBy = crs.ModifyBy,
                                CreatedOn = crs.CreateDate,
                                ModifiedOn = crs.ModifyDate
                            }).ToList<VendorRatesDetailsModel>();
                    return list.FirstOrDefault();

                }

            }

        }

        /// <summary>
        /// Gets the vendor contract count.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public int GetVendorContractCount(int vendorID)
        {
            int count = 0;
            using (DMSEntities dbContext = new DMSEntities())
            {
                count = dbContext.Contracts.Where(u => u.VendorID == vendorID && u.IsActive == true).Count();
            }
            return count;
        }

        /// <summary>
        /// Gets the vendor contract.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public Contract GetVendorContract(int vendorID)
        {
            Contract model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.Contracts.Where(u => u.IsActive == true && u.VendorID == vendorID).OrderByDescending(a => a.CreateDate).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the vendor contract status.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <returns></returns>
        public string GetVendorContractStatus(int vendorID)
        {

            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorContractStatus(vendorID).FirstOrDefault().ContractStatus;
            }
        }

        /// <summary>
        /// Gets the vendor contract status.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public ContractStatu GetVendorContractStatusID(int vendorID)
        {
            ContractStatu model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                Contract contract = dbContext.Contracts.Where(u => u.IsActive == true && u.VendorID == vendorID).OrderByDescending(a => a.CreateDate).FirstOrDefault();
                if (contract != null)
                {
                    model = dbContext.ContractStatus.Where(a => a.ID == contract.ContractStatusID).FirstOrDefault();
                }
            }
            return model;
        }
        /// <summary>
        /// Gets the existing contracts for vendor.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Contract> GetExistingContractsForVendor(int vendorID)
        {
            List<Contract> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.Contracts.Where(u => u.VendorID == vendorID && u.IsActive == true && u.StartDate != null).ToList();

            }
            return list;
        }


        /// <summary>
        /// Gets the service ratings.
        /// </summary>
        /// <param name="vendorID">The vendor unique identifier.</param>
        /// <returns></returns>
        public List<VendorServiceRatings_Result> GetServiceRatings(int vendorID)
        {
            List<VendorServiceRatings_Result> list = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                list = dbContext.GetVendorServiceRatings(vendorID).ToList<VendorServiceRatings_Result>();
            }
            return list;
        }

        public List<VendorDetailsForReport_Result> GetVendorDetailsForReport(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorDetailsForReport(vendorID).ToList<VendorDetailsForReport_Result>();
            }
        }

        public List<RateSchedulesForReport_Result> GetRateSchedulesForReport(int rateScheduleID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetRateSchedulesForReport(rateScheduleID).ToList<RateSchedulesForReport_Result>();
            }
        }
    }
}
