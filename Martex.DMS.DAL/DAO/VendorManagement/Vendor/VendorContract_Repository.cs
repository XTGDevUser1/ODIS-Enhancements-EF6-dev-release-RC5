using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorManagementRepository
    {
        /// <summary>
        /// Gets the vendor contract list.
        /// </summary>
        /// <param name="pg">The pg.</param>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorContractList_Result> GetVendorContractList(PageCriteria pg, int VendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorContractList(pg.WhereClause, pg.StartInd, pg.EndInd, pg.PageSize, pg.SortColumn, pg.SortDirection, VendorID).ToList<VendorContractList_Result>();
            }
        }

        /// <summary>
        /// Gets the vendor contract details.
        /// </summary>
        /// <param name="ContractID">The contract ID.</param>
        /// <returns></returns>
        public VendorContractDetails_Result GetVendorContractDetails(int ContractID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorContractDetails(ContractID).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the contract status.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public ContractStatu GetContractStatus(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var c = dbContext.ContractStatus.Where(s => s.Name == name).FirstOrDefault();
                return c;
            }
        }


        /// <summary>
        /// Gets the contact by vendor ID.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public Contract GetContactByVendorID(int vendorID)
        {
            Contract model = new Contract();
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.Contracts.Where(u => u.VendorID == vendorID).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the source system.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public SourceSystem GetSourceSystem(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var s = dbContext.SourceSystems.Where(c => c.Name == name).FirstOrDefault();
                return s;
            }
        }

        /// <summary>
        /// Gets the vendor terms agreement ID.
        /// </summary>
        /// <returns></returns>
        public int? GetVendorTermsAgreementID()
        {
            int? maxID = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var terms = (from v in dbContext.VendorTermsAgreements
                             where v.EffectiveDate < DateTime.Now && v.IsActive == true
                             select v).ToList<VendorTermsAgreement>();
                if (terms != null && terms.Count > 0)
                {
                   maxID = terms.Max(m => m.ID);
                }

                return maxID;
            }
        }

        /// <summary>
        /// Saves the contract.
        /// </summary>
        /// <param name="c">The c.</param>
        public void SaveContract(Contract c)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Contracts.Add(c);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Inserts the rate schedule and rates for contract.
        /// </summary>
        /// <param name="contractID">The contract identifier.</param>
        public void InsertRateScheduleAndRatesForContract(int contractID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.InsertRateScheduleAndRatesForContract(contractID);
            }
        }

        /// <summary>
        /// Updates the contract.
        /// </summary>
        /// <param name="contract">The contract.</param>
        public void UpdateContract(Contract contract)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Contract existingContract = dbContext.Contracts.Where(a => a.ID == contract.ID).FirstOrDefault();
                existingContract.ModifyBy = contract.ModifyBy;
                existingContract.ModifyDate = contract.ModifyDate;

                existingContract.SignedBy = contract.SignedBy;
                existingContract.SignedByTitle = contract.SignedByTitle;
                existingContract.EndDate = contract.EndDate;
                existingContract.StartDate = contract.StartDate;
                existingContract.SignedDate = contract.SignedDate;
                existingContract.VendorTermsAgreementID = contract.VendorTermsAgreementID;
                existingContract.ContractStatusID = contract.ContractStatusID;
                dbContext.Entry(existingContract).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Deletes the vendor contract.
        /// </summary>
        /// <param name="contractID">The contract ID.</param>
        public void DeleteVendorContract(int contractID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Contract existingContract = dbContext.Contracts.Where(a => a.ID == contractID).FirstOrDefault();
                dbContext.Entry(existingContract).State = EntityState.Deleted;
                dbContext.SaveChanges();
            }
        }
    }
}