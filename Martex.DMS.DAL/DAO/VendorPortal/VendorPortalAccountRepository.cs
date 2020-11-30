using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO.VendorPortal
{
    public class VendorPortalAccountRepository
    {
        /// <summary>
        /// Updates the vendor information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="System.Exception"></exception>
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

                #region Insurance Section
                existingRecord.InsuranceCarrierName = model.InsuranceCarrierName;
                existingRecord.InsuranceExpirationDate = model.InsuranceExpirationDate;
                existingRecord.InsurancePolicyNumber = model.InsurancePolicyNumber;
                #endregion

                #region Information Section
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
                #endregion
                
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Updates the vendor lcoation.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void UpdateVendorLcoation(VendorLocation model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingRecord = dbContext.VendorLocations.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingRecord != null)
                {

                    // Other Properties
                    existingRecord.ModifyBy = userName;
                    existingRecord.ModifyDate = DateTime.Now;
                   
                    // Basic Information
                    existingRecord.IsOpen24Hours = model.IsOpen24Hours;
                    existingRecord.IsKeyDropAvailable = model.IsKeyDropAvailable;
                    existingRecord.IsOvernightStayAllowed = model.IsOvernightStayAllowed;
                    existingRecord.IsElectronicDispatchAvailable = model.IsElectronicDispatchAvailable;
                }
                dbContext.SaveChanges();
            }
        }
    }
}
