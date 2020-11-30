using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using System.Data.Entity;
using Martex.DMS.DAL.DMSBaseException;

namespace Martex.DMS.DAL.DAO
{
    public class VendorApplicationRepository
    {

        /// <summary>
        /// Adds the specified vendor application.
        /// </summary>
        /// <param name="vendorApplication">The vendor application.</param>
        public void Add(VendorApplication vendorApplication)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.VendorApplications.Add(vendorApplication);
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Updates the name of the insurance file.
        /// </summary>
        /// <param name="recordID">The record ID.</param>
        /// <param name="fileName">Name of the file.</param>
        public void UpdateInsuranceFileName(int recordID, string fileName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorApplication existingRecord = dbContext.VendorApplications.Where(u => u.ID == recordID).FirstOrDefault();
                if (existingRecord != null)
                {
                    existingRecord.InsuranceCertificateFileName = fileName;
                }

                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Sets the vendor ID.
        /// </summary>
        /// <param name="vendorApplicationID">The vendor application ID.</param>
        /// <param name="vendorID">The vendor ID.</param>
        public void SetVendorID(int vendorApplicationID, int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var va = dbContext.VendorApplications.Where(v => v.ID == vendorApplicationID).FirstOrDefault();
                if (va != null)
                {
                    va.VendorID = vendorID;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Gets the services.
        /// </summary>
        /// <returns></returns>
        public List<ServicesForVendorPortal_Result> GetServices()
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetServicesForVendorPortal().ToList<ServicesForVendorPortal_Result>();
            }
        }

        /// <summary>
        /// Adds the products.
        /// </summary>
        /// <param name="applicationID">The application ID.</param>
        /// <param name="services">The services.</param>
        public void AddProducts(int applicationID, List<string> services)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                services.ForEach(s =>
                {
                    VendorApplicationProduct vap = new VendorApplicationProduct();
                    vap.VendorApplicationID = applicationID;
                    vap.ProductID = Convert.ToInt32(s);

                    dbContext.VendorApplicationProducts.Add(vap);
                });

                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Adds the postal codes to vendor application
        /// </summary>
        /// <param name="applicationID">The application ID.</param>
        /// <param name="postalCodes">The postal codes.</param>
        public void AddPostalCodes(int applicationID, List<string> postalCodes, bool isSecondary = false)
        {
            postalCodes.ForEach(p =>
            {
                if (p.Length > 20)
                {
                    throw new DMSException(string.Format("Zip codes are not in correct format - {0}", p));
                }
            });

            using (DMSEntities dbContext = new DMSEntities())
            {
                postalCodes.ForEach(s =>
                {
                    if (!string.IsNullOrEmpty(s) && s.Trim().Length > 0)
                    {
                        VendorApplicationPostalCode vapc = new VendorApplicationPostalCode();
                        vapc.PostalCode = s.Trim();
                        vapc.VendorApplicationID = applicationID;
                        vapc.IsSecondary = isSecondary;
                        dbContext.VendorApplicationPostalCodes.Add(vapc);
                    }
                });
                dbContext.SaveChanges();

            }
        }


        /// <summary>
        /// Updates the vendor user.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        public void UpdateVendorUser(int vendorID, string currentUser, VendorUser vendorUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                //int vendorUserID = ID.GetValueOrDefault();
                VendorUser existingVendorUser = dbContext.VendorUsers.Where(a => a.ID == vendorUser.ID).FirstOrDefault();
                if (existingVendorUser != null)
                {
                    existingVendorUser.PostLoginPromptID = null;
                    existingVendorUser.FirstName = vendorUser.FirstName;
                    existingVendorUser.LastName = vendorUser.LastName;
                    existingVendorUser.ModifyBy = currentUser;
                    existingVendorUser.ModifyDate = DateTime.Now;
                    dbContext.Entry(existingVendorUser).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }

        public void UpdateVendorUserPostLoginPromptID(int vendorUserID, int? postLoginPromptID, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorUser existingVendorUser = dbContext.VendorUsers.Where(a => a.ID == vendorUserID).FirstOrDefault();
                if (existingVendorUser != null)
                {
                    existingVendorUser.PostLoginPromptID = postLoginPromptID;
                    existingVendorUser.ModifyBy = currentUser;
                    existingVendorUser.ModifyDate = DateTime.Now;
                    dbContext.Entry(existingVendorUser).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }

        /// <summary>
        /// Updates the vendor details.
        /// </summary>
        /// <param name="currentUser">The current user.</param>
        /// <param name="vendor">The vendor.</param>
        public void UpdateVendorDetails(string currentUser, Vendor vendor)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Vendor existingVendor = dbContext.Vendors.Where(a => a.ID == vendor.ID).FirstOrDefault();
                if (existingVendor != null)
                {
                    existingVendor.ContactFirstName = vendor.ContactFirstName;
                    existingVendor.ContactLastName = vendor.ContactLastName;
                    existingVendor.Email = vendor.Email;
                    existingVendor.ModifyBy = currentUser;
                    existingVendor.ModifyDate = DateTime.Now;
                    dbContext.Entry(existingVendor).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }

        public void UpdateVendorProductDetails(Vendor vendor, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                Vendor existingVendor = dbContext.Vendors.Where(a => a.ID == vendor.ID).FirstOrDefault();
                if (existingVendor != null)
                {
                    existingVendor.DispatchSoftwareProductID = vendor.DispatchSoftwareProductID;
                    existingVendor.DispatchSoftwareProductOther = vendor.DispatchSoftwareProductOther;
                    existingVendor.DriverSoftwareProductID = vendor.DriverSoftwareProductID;
                    existingVendor.DriverSoftwareProductOther = vendor.DriverSoftwareProductOther;
                    existingVendor.DispatchGPSNetworkID = vendor.DispatchGPSNetworkID;
                    existingVendor.DispatchGPSNetworkOther = vendor.DispatchGPSNetworkOther;
                    existingVendor.ModifyBy = currentUser;
                    existingVendor.ModifyDate = DateTime.Now;
                    dbContext.Entry(existingVendor).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }

        }

        /// <summary>
        /// Updates the membership email.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="Email">The email.</param>
        public void UpdateMembershipEmail(Guid userId, string Email)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                aspnet_Membership am = dbContext.aspnet_Membership.Where(a => a.UserId == userId).FirstOrDefault();
                am.Email = Email;
                am.LoweredEmail = Email.ToLower();

                dbContext.Entry(am).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Saves the business hours.
        /// </summary>
        /// <param name="vendorapplicationID">The vendorapplication ID.</param>
        /// <param name="businessHours">The business hours.</param>
        /// <param name="createBy">The create by.</param>
        public void SaveBusinessHours(int vendorapplicationID, List<BusinessHours> businessHours, string createBy)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<VendorApplicationBusinessHour> existingList = dbContext.VendorApplicationBusinessHours.Where(a => a.VendorApplicationID == vendorapplicationID).ToList<VendorApplicationBusinessHour>();
                foreach (var item in existingList)
                {
                    dbContext.Entry(item).State = EntityState.Deleted;
                }
                var newBH = (VendorApplicationBusinessHour)null;
                foreach (var bh in businessHours)
                {
                    newBH = new VendorApplicationBusinessHour()
                    {
                        VendorApplicationID = vendorapplicationID,
                        DayName = bh.DayName,
                        DayNumber = bh.DayNumber,
                        StartTime = bh.StartTime,
                        EndTime = bh.EndTime,
                        CreateBy = createBy,
                        CreateDate = DateTime.Now
                    };
                    dbContext.VendorApplicationBusinessHours.Add(newBH);
                }
                dbContext.SaveChanges();
            }

        }

        public string GetVendorUserName(string vendorNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var userName = "";
                var query = from u in dbContext.aspnet_Users
                            join vu in dbContext.VendorUsers on u.UserId equals vu.aspnet_UserID
                            join v in dbContext.Vendors on vu.VendorID equals v.ID
                            where v.VendorNumber == vendorNumber
                            select new
                            {
                                userName = u.UserName
                            };
                if (query.Count() > 0)
                {
                    userName = query.Select(a => a.userName).FirstOrDefault().ToString();
                }
                return userName;
            }
        }
    }
}
