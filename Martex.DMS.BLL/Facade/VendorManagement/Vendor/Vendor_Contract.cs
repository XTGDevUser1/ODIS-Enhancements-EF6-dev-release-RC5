using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorManagementFacade
    {
        /// <summary>
        /// Gets the vendor contract list.
        /// </summary>
        /// <param name="pg">The pg.</param>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorContractList_Result> GetVendorContractList(PageCriteria pg, int VendorID)
        {
            return repository.GetVendorContractList(pg, VendorID);
        }

        /// <summary>
        /// Gets the vendor contract details.
        /// </summary>
        /// <param name="contractID">The contract ID.</param>
        /// <returns></returns>
        public VendorContractDetails_Result GetVendorContractDetails(int contractID)
        {
            return repository.GetVendorContractDetails(contractID);
        }

        /// <summary>
        /// Saves the vendor contract details.
        /// </summary>
        /// <param name="data">The data.</param>
        /// <param name="vendorID">The vendor ID.</param>
        /// <exception cref="System.NotImplementedException"></exception>
        public int SaveVendorContractDetails(VendorContractDetails_Result data, string currentUser)
        {
            using (TransactionScope tran = new TransactionScope())
            {
                Contract contract = new Contract();
                contract.ContractStatusID = data.ContractStatusID;
                contract.VendorTermsAgreementID = data.VTAID;
                contract.SignedDate = data.SignedDate;
                contract.SignedBy = data.SignedBy;
                contract.SignedByTitle = data.SignedByTitle;
                contract.StartDate = data.StartDate;
                contract.EndDate = data.EndDate;
                contract.IsActive = true;
                if (data.ID > 0)
                {
                    contract.ID = data.ID;
                    contract.ModifyBy = currentUser;
                    contract.ModifyDate = DateTime.Now;
                    repository.UpdateContract(contract);
                }
                else
                {
                    contract.VendorID = data.VendorID;
                    contract.CreateBy = currentUser;
                    contract.CreateDate = DateTime.Now;
                    SourceSystem sourceSystem = repository.GetSourceSystem("BackOffice");
                    if (sourceSystem == null)
                    {
                        throw new DMSException("Source System- BackOffice not setup in the system.");
                    }
                    contract.SourceSystemID = sourceSystem.ID;
                    repository.SaveContract(contract);
                }
                tran.Complete();
                return contract.ID;

            }
        }

        /// <summary>
        /// Gets the contract status ID.
        /// </summary>
        /// <param name="contractStatusName">Name of the contract status.</param>
        /// <returns></returns>
        public int? GetContractStatusID(string contractStatusName)
        {
            ContractStatu contractStatus = repository.GetContractStatus(contractStatusName);
            if (contractStatus == null)
            {
                throw new DMSException("Contract Status Name - " + contractStatusName + "not setup in the system");
            }
            return contractStatus.ID;
        }

        /// <summary>
        /// Gets the contact by vendor ID.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public Contract GetContactByVendorID(int vendorID)
        {
            return repository.GetContactByVendorID(vendorID);
        }

        /// <summary>
        /// Gets the latest VTA.
        /// </summary>
        /// <returns></returns>
        public int? GetLatestVTA()
        {
            return repository.GetVendorTermsAgreementID();
        }

        /// <summary>
        /// Deletes the vendor contract.
        /// </summary>
        /// <param name="contractID">The contract ID.</param>
        /// <exception cref="DMSException">There is activity tied to this contract, so it can't be deleted. You can set the Status=Inactive instead.</exception>
        public void DeleteVendorContract(int contractID)
        {
            try
            {
                logger.Info("In Facade to delete vendor Contract");
                repository.DeleteVendorContract(contractID);
                logger.Info("Deletion Successful");
            }
            catch (Exception ex)
            {
                logger.InfoFormat("Error is: {0}", ex);
                throw new DMSException("There is activity tied to this contract, so it can't be deleted. You can set the Status=Inactive instead.");
            }
        }
    }
}