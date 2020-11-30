using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model.VendorPortal;
using Martex.DMS.DAL.DAO;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO.VendorPortal;
using Martex.DMS.DAL.Entities;
using System.Transactions;

namespace Martex.DMS.BLL.Facade.VendorPortal
{
    public class VendorPortalAccountFacade
    {
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorPortalAccountFacade));
        #endregion

        /// <summary>
        /// Gets the vendor account details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorAccountModel GetVendorAccountDetails(int vendorID)
        {
            VendorAccountModel model = new VendorAccountModel();
            VendorManagementRepository repository = new VendorManagementRepository();
            model.VendorDetails = repository.Get(vendorID);
            return model;
        }

        /// <summary>
        /// Gets the vendor location account details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public VendorLocationAccountModel GetVendorLocationAccountDetails(int vendorID, int vendorLocationID)
        {
            CommonLookUpRepository lookUP = new CommonLookUpRepository();
            VendorManagementRepository repository = new VendorManagementRepository();
            AddressRepository addressRepository = new AddressRepository();
            VendorLocationAccountModel model = new VendorLocationAccountModel();
            
            #region Vendor Location Information Details
            logger.InfoFormat("Trying to retrieve Vendor Location Details for the given ID {0}", vendorLocationID);
            model.BasicInformation = repository.GetVendorLocationDetails(vendorLocationID);
            logger.InfoFormat("Execution finished for the Vendor Location Details for the given ID {0}", vendorLocationID);
            #endregion

            #region Address Entity
            logger.InfoFormat("Trying to retrieve Vendor Location Info Address Details for the given ID {0}", vendorLocationID);
            List<AddressEntity> list = addressRepository.GetAddresses(vendorLocationID, EntityNames.VENDOR_LOCATION, AddressTypeNames.Business);
            if (list != null && list.Count > 0)
            {
                model.AddressInformation = list.FirstOrDefault();
            }
            else
            {
                model.AddressInformation = new AddressEntity();
            }
            logger.InfoFormat("Retrieving Finished for Location Info Address Details for the given ID {0}", vendorLocationID);
            #endregion

            #region Vendor Location Payment Types
            logger.Info("Trying to retrieve Payment Types accepted");
            model.PaymentTypes = repository.GetPaymentTypesForVendorLocation(vendorLocationID,EntityNames.VENDOR_LOCATION);
            logger.Info("Retrieving finished for the payment types");
            #endregion

            #region Other Properties
            model.VendorID = vendorID;
            #endregion

            #region Retrieve Business Hours
            model.BusinessHours = repository.GetBusinessHours(vendorLocationID);
            if (model.BusinessHours == null)
            {
                model.BusinessHours = new List<DAL.Entities.BusinessHours>();
            }
            #endregion

            #region Get the Vendor Location Status Name
            if (model.BasicInformation.VendorLocationStatusID.HasValue)
            {
                model.VendorLocationStatusName = lookUP.GetVendorLocationStatus(model.BasicInformation.VendorLocationStatusID.Value).Name;
            }
            #endregion

            return model;
        }

        /// <summary>
        /// Updates the vendor information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void UpdateVendorInformation(VendorAccountModel model, string userName)
        {
            logger.InfoFormat("Trying to Update Vendor Info Section Details from Vendor Portal");
            VendorPortalAccountRepository repository = new VendorPortalAccountRepository();
            repository.UpdateVendorInformation(model.VendorDetails, userName);
            logger.InfoFormat("Details Saved Successfully");
        }


        /// <summary>
        /// Saves the vendor location info details.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void SaveVendorLocationInfoDetails(VendorLocationAccountModel model, string userName)
        {
            VendorManagementRepository vendorManagementrepository = new VendorManagementRepository();
            AddressRepository addressRepository = new AddressRepository();
            VendorPortalAccountRepository repository = new VendorPortalAccountRepository();

            List<CheckBoxLookUp> paymentTypeList = null;
            if (model.PaymentTypes != null)
            {
                paymentTypeList = model.PaymentTypes.Where(u => u.Selected == true).ToList();
            }
            List<VendorLocationPaymentType> vendorLocationPaymentTypeList = vendorManagementrepository.GetVendorLocationPaymentTypes(model.BasicInformation.ID);
            using (TransactionScope transaction = new TransactionScope())
            {
                // Process Vendor Location Payment Types
                // Delete all previous records
                foreach (VendorLocationPaymentType record in vendorLocationPaymentTypeList)
                {
                    vendorManagementrepository.DeleteVendorLocationPaymentType(record.ID);
                }
                // Insert new records
                if (paymentTypeList != null && paymentTypeList.Count > 0)
                {
                    foreach (CheckBoxLookUp record in paymentTypeList)
                    {
                        vendorManagementrepository.AddVendorLocationPaymentType(new VendorLocationPaymentType()
                        {
                            VendorLocationID = model.BasicInformation.ID,
                            PaymentTypeID = record.ID,
                            IsActive = true,
                            CreateDate = DateTime.Now,
                            CreateBy = userName
                        });
                    }
                }

                // Process Vendor Lcoation Addesss Details
                logger.InfoFormat("Trying to save Vendor Location Business Address Details for the Vendor Location ID {0}", model.BasicInformation.ID);
                addressRepository.Save(model.AddressInformation, EntityNames.VENDOR_LOCATION, AddressTypeNames.Business, model.BasicInformation.ID, userName);
                logger.InfoFormat("Saved successfully Vendor Location Business Address Details for the Vendor Location ID {0}", model.BasicInformation.ID);

                //Update Vendor Location Details Table
                logger.InfoFormat("Trying to Update Vendor Location Details for the ID {0}", model.BasicInformation.ID);
                repository.UpdateVendorLcoation(model.BasicInformation, userName);
                logger.Info("Vendor Location Details Updated Successfully");

                //Process Business Hours if it's it's not open for 24 hours
                if (model.BasicInformation.IsOpen24Hours.HasValue && !model.BasicInformation.IsOpen24Hours.Value)
                {
                    logger.InfoFormat("Trying to Update Vendor Location Business Hours Details for the ID {0}", model.BasicInformation.ID);
                    vendorManagementrepository.SaveBusinessHours(model.BasicInformation.ID, model.BusinessHours, userName);
                    logger.Info("Business Hours Updated Successfully");
                }

                transaction.Complete();
            }
        }

    }
}
