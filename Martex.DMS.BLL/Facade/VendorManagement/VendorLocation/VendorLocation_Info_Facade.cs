using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAO;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DAO;
using System.Transactions;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorManagementFacade
    {
        #region Process to Update Vendor Location Lat Long
        public List<VendorLocationGeographyListManage_Result> GetVendorLocationGeographyList(PageCriteria page)
        {
            return repository.GetVendorLocationGeographyList(page);
        }

        public void UpdateLatLongForVendorLocation(int vendorLocationID, string userName)
        {
            logger.InfoFormat("Processing - Geography Started for Vendor Location ID {0}", vendorLocationID);
            #region Address Entity
            AddressEntity address = null;
            logger.InfoFormat("Trying to retrieve Vendor Location Info Address Details for the given ID {0}", vendorLocationID);
            List<AddressEntity> list = addressRepository.GetAddresses(vendorLocationID, EntityNames.VENDOR_LOCATION, AddressTypeNames.Business);
            if (list != null && list.Count > 0)
            {
                logger.InfoFormat("Retrieving Finished for Location Info Address Details for the given ID {0}", vendorLocationID);
                address = list.FirstOrDefault();
                logger.InfoFormat("Trying to retrieve Lat Long for the given ID {0} and address ID {1}", vendorLocationID, address.ID);
                LatitudeLongitude latLong = AddressFacade.GetLatLong(string.Join(",", address.Line1, address.Line2, address.Line3), address.City, address.StateProvince, address.PostalCode, address.CountryCode);
                if (latLong != null && latLong.Latitude.HasValue && latLong.Longitude.HasValue && latLong.Latitude.Value != 0 && latLong.Longitude.Value != 0)
                {
                    logger.InfoFormat("Found Latitude and Longitude for address ID {0} trying to Update in Vendor Location", address.ID);
                    using (TransactionScope transaction = new TransactionScope())
                    {
                        repository.UpdateVendorLocation(vendorLocationID, latLong.Latitude, latLong.Longitude, userName);
                        addressRepository.UpdateGeographyType(vendorLocationID, EntityNames.VENDOR_LOCATION);
                        transaction.Complete();
                    }
                }
                else
                {
                    logger.InfoFormat("Unable to retrieve Latitude and Longitude for address ID {0}", address.ID);
                    throw new Exception(string.Format("Unable to retrieve Latitude and Longitude for Vendor Location ID {0}", vendorLocationID));
                }
            }
            else
            {
                logger.InfoFormat("Retrieving Finished for Location Info Address Details for the given ID {0} found no records", vendorLocationID);
                throw new Exception(string.Format("Unable to retrieve address for Vendor Location ID {0}", vendorLocationID));
            }
            #endregion

        }
        #endregion

        #region Retrieve Vendor Location Information
        /// <summary>
        /// Gets the vendor location information details.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <param name="vendorLocationID">The vendor location identifier.</param>
        /// <returns></returns>
        public VendorLocationInfoModel GetVendorLocationInfoDetails(int vendorID, int vendorLocationID)
        {
            VendorLocationInfoModel model = new VendorLocationInfoModel();
            #region Vendor Location Information Details
            logger.InfoFormat("Trying to retrieve Vendor Location Details for the given ID {0}", vendorLocationID);
            model.BasicInformation = repository.GetVendorLocationDetails(vendorLocationID);
            model.Geography = repository.GetVendorLocationGeographyDetails(vendorLocationID);
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
            model.PaymentTypes = vendorManagement_Repository.GetPaymentTypesForVendorLocation(vendorLocationID, EntityNames.VENDOR_LOCATION);
            logger.Info("Retrieving finished for the payment types");
            #endregion

            #region Vendor Location Business Hours
            if (model.BasicInformation.IsOpen24Hours.HasValue && !model.BasicInformation.IsOpen24Hours.Value)
            {
                logger.Info("Trying to Vendor Location Business Hours");
                model.BusinessHours = repository.GetBusinessHours(vendorLocationID);
                logger.Info("Retrieving finished for Business Hours");
            }
            #endregion

            #region Other Properties
            model.VendorID = vendorID;
            model.OldVendorLocationStatusID = model.BasicInformation.VendorLocationStatusID;

            model.IsCoachNetDealerPartner = repository.IsVendorLocationCoachNetDealerPartner(vendorLocationID);
            model.VendorLocationProductRatingForCoachNetDealerPartner = repository.GetVendorLocationProductRatingForCoachNetDealerPartner(vendorLocationID);
            #endregion

            return model;
        }
        #endregion

        #region Save Vendor Location Information
        public void SaveVendorLocationInfoDetails(VendorLocationInfoModel model, string userName)
        {
            List<CheckBoxLookUp> paymentTypeList = null;
            if (model.PaymentTypes != null)
            {
                paymentTypeList = model.PaymentTypes.Where(u => u.Selected == true).ToList();
            }
            List<VendorLocationPaymentType> vendorLocationPaymentTypeList = vendorManagement_Repository.GetVendorLocationPaymentTypes(model.BasicInformation.ID);
            bool isVendorStatusChanged = false;
            if (model.OldVendorLocationStatusID.HasValue && model.OldVendorLocationStatusID.Value != model.BasicInformation.VendorLocationStatusID.Value)
            {
                isVendorStatusChanged = true;
                logger.InfoFormat("Vendor Location Status ID is changed for the vendor Lcoation ID {0}", model.BasicInformation.ID);
            }

            using (TransactionScope transaction = new TransactionScope())
            {
                // If the Vendor Status is Changed Log the Entry
                if (isVendorStatusChanged)
                {
                    logger.InfoFormat("Trying to Create Vendor Status Log for the given Vendor Location ID {0} in Transaction", model.BasicInformation.ID);
                    VendorStatusLog vendorStatusLog = new VendorStatusLog()
                    {
                        VendorID = null,
                        VendorStatusIDBefore = model.OldVendorLocationStatusID,
                        VendorStatusIDAfter = model.BasicInformation.VendorLocationStatusID,
                        VendorStatusReasonID = model.VendorLocationChangeReasonID,
                        VendorStatusReasonOther = model.VendorLocationChangeReasonOther,
                        Comment = model.VendorLocationChangeReasonComments,
                        CreateBy = userName,
                        CreateDate = DateTime.Now
                    };
                    repository.CreateVendorStatusLog(vendorStatusLog);
                }

                // Process Vendor Location Payment Types
                // Delete all previous records
                foreach (VendorLocationPaymentType record in vendorLocationPaymentTypeList)
                {
                    vendorManagement_Repository.DeleteVendorLocationPaymentType(record.ID);
                }
                // Insert new records
                if (paymentTypeList != null && paymentTypeList.Count > 0)
                {
                    foreach (CheckBoxLookUp record in paymentTypeList)
                    {
                        vendorManagement_Repository.AddVendorLocationPaymentType(new VendorLocationPaymentType()
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
                //TODO: Fix VendorLocationType
                //model.BasicInformation.VendorLocationTypeID = ReferenceDataRepository.GetVendorLocationType(VendorLocationTypeNames.Physical).ID;
                vendorManagement_Repository.UpdateVendorLcoation(model.BasicInformation, userName);

                addressRepository.UpdateGeographyType(model.BasicInformation.ID, EntityNames.VENDOR_LOCATION);

                logger.Info("Vendor Location Details Updated Successfully");

                //Process Business Hours if it's it's not open for 24 hours
                if (model.BasicInformation.IsOpen24Hours.HasValue && !model.BasicInformation.IsOpen24Hours.Value)
                {
                    logger.InfoFormat("Trying to Update Vendor Location Business Hours Details for the ID {0}", model.BasicInformation.ID);
                    vendorManagement_Repository.SaveBusinessHours(model.BasicInformation.ID, model.BusinessHours, userName);
                    logger.Info("Business Hours Updated Successfully");
                }
                repository.UpdateVendorLocationCoachNetDealerPartnerDetails(model.BasicInformation.ID, model.IsCoachNetDealerPartner, model.VendorLocationProductRatingForCoachNetDealerPartner, userName);
                transaction.Complete();
            }
        }
        #endregion
    }
}
