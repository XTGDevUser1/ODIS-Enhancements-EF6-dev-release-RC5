using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorManagementRepository
    {
        /// <summary>
        /// Gets the specified vendor ID.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        public Vendor Get(int vendorID)
        {
            Vendor model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.Vendors.Include("VendorApplications").Include("VendorStatu").Include("VendorUsers").Include("VendorRegion").Include("DispatchSoftwareProduct").Include("DispatchSoftwareProduct1").Include("DispatchGPSNetwork").Where(u => u.ID == vendorID).FirstOrDefault();
                if (model == null)
                {
                    throw new DMSException(String.Format("Unable to retrieve details for the Vendor {0}", vendorID));
                }
            }
            return model;

        }

        /// <summary>
        /// Updates the vendor web account.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <param name="model">The model.</param>
        public void UpdateVendorWebAccount(string userName, VendorWebAccountInfoModel model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                aspnet_Membership currentRecord = dbContext.aspnet_Membership.Where(u => u.UserId == model.UserId && u.ApplicationId == model.ApplicationId).FirstOrDefault();
                if (currentRecord == null)
                {
                    throw new DMSException(string.Format("Unable to retriev web account details for the vendor ID {0}", model.VendorID));
                }
                else
                {
                    currentRecord.Email = model.Email;
                    if (!string.IsNullOrEmpty(model.Email))
                    {
                        currentRecord.LoweredEmail = model.Email.ToLower();
                    }
                    currentRecord.IsApproved = model.IsApproved;
                    currentRecord.IsLockedOut = model.IsLockedOut;
                }
                dbContext.SaveChanges();

            }
        }

        /// <summary>
        /// Gets the vendor web account information.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorWebAccountInfoModel GetVendorWebAccountInformation(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorWebAccountInformation(vendorID).FirstOrDefault();
            }

        }

        /// <summary>
        /// Update the vendor information.
        /// </summary>
        /// <param name="model">The model.</param>
        public void UpdateVendorInformation(Vendor model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.Vendors.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingRecord == null)
                {
                    throw new Exception(String.Format("Unable to retrive Vendor Details for the Given ID {0}", model.ID));
                }

                #region Other Values
                existingRecord.ModifyBy = userName;
                existingRecord.ModifyDate = DateTime.Now;
                #endregion

                #region Insurance Section
                existingRecord.InsuranceCarrierName = model.InsuranceCarrierName;
                existingRecord.InsuranceExpirationDate = model.InsuranceExpirationDate;
                existingRecord.InsurancePolicyNumber = model.InsurancePolicyNumber;
                existingRecord.IsInsuranceCertificateOnFile = model.IsInsuranceCertificateOnFile;
                existingRecord.IsInsuranceAdditional = model.IsInsuranceAdditional;                 //Lakshmi - Addition Check box on Insurence - Vendor tab
                #endregion

                #region Quality Indicators Section

                existingRecord.IsEmployeeBackgroundChecked = model.IsEmployeeBackgroundChecked;
                existingRecord.IsEmployeeBackgroundCheckedComment = model.IsEmployeeBackgroundCheckedComment;

                existingRecord.IsEmployeeDrugTested = model.IsEmployeeDrugTested;
                existingRecord.IsEmployeeDrugTestedComment = model.IsEmployeeDrugTestedComment;

                existingRecord.IsDriverUniformed = model.IsDriverUniformed;
                existingRecord.IsDriverUniformedComment = model.IsDriverUniformedComment;

                existingRecord.IsEachServiceTruckMarked = model.IsEachServiceTruckMarked;
                existingRecord.IsEachServiceTruckMarkedComment = model.IsEachServiceTruckMarkedComment;
                #endregion

                #region Information Section
                existingRecord.Name = model.Name;
                existingRecord.CorporationName = model.CorporationName;
                existingRecord.TaxClassification = model.TaxClassification;
                existingRecord.TaxClassificationOther = model.TaxClassificationOther;
                existingRecord.TaxEIN = model.TaxEIN;
                existingRecord.TaxSSN = model.TaxSSN;
                existingRecord.ContactFirstName = model.ContactFirstName;
                existingRecord.ContactLastName = model.ContactLastName;
                existingRecord.Email = model.Email;
                existingRecord.Website = model.Website;
                existingRecord.DepartmentOfTransportationNumber = model.DepartmentOfTransportationNumber;
                existingRecord.MotorCarrierNumber = model.MotorCarrierNumber;
                existingRecord.IsW9OnFile = model.IsW9OnFile;
                existingRecord.VendorStatusID = model.VendorStatusID;
                existingRecord.IsLevyActive = model.IsLevyActive;
                existingRecord.LevyRecipientName = model.LevyRecipientName;
                existingRecord.IsVirtualLocationEnabled = model.IsVirtualLocationEnabled;
                #endregion

                #region Dispatch Software
                existingRecord.DispatchSoftwareProductID = model.DispatchSoftwareProductID;
                existingRecord.DispatchSoftwareProductOther = model.DispatchSoftwareProductOther;
                existingRecord.DriverSoftwareProductID = model.DriverSoftwareProductID;
                existingRecord.DriverSoftwareProductOther = model.DriverSoftwareProductOther;
                existingRecord.DispatchGPSNetworkID = model.DispatchGPSNetworkID;
                existingRecord.DispatchGPSNetworkOther = model.DispatchGPSNetworkOther;
                #endregion

                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Gets the vendor latest contract rate schedule.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public int? GetVendorLatestContractRateSchedule(int vendorID)
        {
            int? contrectRateScheduleID = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = (from rateSchedule in dbContext.ContractRateSchedules
                              join contract in dbContext.Contracts on rateSchedule.ContractID equals contract.ID
                              where contract.VendorID == vendorID
                              orderby contract.StartDate descending
                              select rateSchedule).FirstOrDefault();

                if (result != null)
                {
                    contrectRateScheduleID = result.ID;
                }

            }
            return contrectRateScheduleID;
        }

        public string GetVendorIndicators(string entityName, int recordID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorIndicators(entityName, recordID).Single<string>();
            }
        }

        /// <summary>
        /// Gets whether vendor is coach net dealer partner or not.
        /// </summary>
        /// <param name="vendorID">The vendor identifier.</param>
        /// <returns></returns>
        public bool GetIsVendorCoachNetDealerPartner(int vendorID)
        {
            bool isVendorCoachNetDealerPartner = false;
            using (DMSEntities dbContext = new DMSEntities())
            {
                Product product = dbContext.Products.Where(a => a.Name == Products.COACHNET_DEALER_PARTNER).FirstOrDefault();
                VendorProduct vp = dbContext.VendorProducts.Where(a => a.VendorID == vendorID && a.ProductID == product.ID).FirstOrDefault();
                if (vp != null)
                {
                    isVendorCoachNetDealerPartner = true;
                }
            }
            return isVendorCoachNetDealerPartner;

        }
    }
}
