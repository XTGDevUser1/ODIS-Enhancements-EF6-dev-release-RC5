using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO.VendorPortal
{
    public class VendorPortalACHRepository
    {
        /// <summary>
        /// Gets the vendor ACH details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorACH GetVendorACHDetails(int vendorID)
        {
            // DO NOT WRTIE THROW EXCEPTION
            VendorACH model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.VendorACHes.Where(u => u.VendorID == vendorID && u.IsActive == true).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the vendor details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public Vendor GetVendorDetails(int vendorID)
        {
            // DO NOT WRTIE THROW EXCEPTION
            Vendor model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.Vendors.Where(u => u.ID == vendorID).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Creates the ACH record.
        /// </summary>
        /// <param name="model">The model.</param>
        public void CreateACHRecord(VendorACH model)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.VendorACHes.Add(model);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the ACH record.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        public void UpdateACHRecord(VendorACH model,string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorACH existingRecord = dbContext.VendorACHes.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingRecord == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve Vendor ACH Details for {0}", model.ID));
                }
                existingRecord.NameOnAccount = model.NameOnAccount;
                existingRecord.BankABANumber = model.BankABANumber;
                existingRecord.AccountNumber = model.AccountNumber;
                existingRecord.AccountType = model.AccountType;
                existingRecord.ReceiptEmail = model.ReceiptEmail;

                existingRecord.BankName = model.BankName;
                existingRecord.BankAddressLine1 = model.BankAddressLine1;
                existingRecord.BankAddressLine2 = model.BankAddressLine2;
                existingRecord.BankAddressLine3 = model.BankAddressLine3;
                existingRecord.BankAddressCity = model.BankAddressCity;
                existingRecord.BankAddressPostalCode = model.BankAddressPostalCode;
                existingRecord.BankAddressStateProvince = model.BankAddressStateProvince;
                existingRecord.BankAddressStateProvinceID = model.BankAddressStateProvinceID;
                existingRecord.BankAddressCountryCode = model.BankAddressCountryCode;
                existingRecord.BankAddressCountryID = model.BankAddressCountryID;
                existingRecord.BankPhoneNumber = model.BankPhoneNumber;

                existingRecord.ACHStatusID = model.ACHStatusID;
                existingRecord.ModifyBy = userName;
                existingRecord.ModifyDate = DateTime.Now;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the vendor information AC h_ active inactive.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userName">Name of the user.</param>
        /// <exception cref="DMSException"></exception>
        public void UpdateACHInformationFor_ActiveInactive(VendorACH model, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorACH existingRecord = dbContext.VendorACHes.Where(u => u.ID == model.ID).FirstOrDefault();
                if (existingRecord == null)
                {
                    throw new DMSException(string.Format("Unable to retrieve vendor ACH details {0}", model.ID));
                }
                existingRecord.IsActive = model.IsActive;
                existingRecord.ModifyDate = DateTime.Now;
                existingRecord.ModifyBy = userName;
                dbContext.SaveChanges();
            }
        }
    }
}
