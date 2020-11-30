using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAO;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class VendorRepository
    {
        /// <summary>
        /// Vendors the name of the repo user.
        /// </summary>
        /// <param name="regionID">The region identifier.</param>
        /// <returns></returns>
        public string VendorRepoUserName(int regionID)
        {
            string userName = string.Empty;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var vendorRegion = dbContext.VendorRegions.Where(u => u.ID == regionID).FirstOrDefault();
                if (vendorRegion != null)
                {
                    var currentUserProfile = dbContext.Users.Where(u => u.FirstName.Equals(vendorRegion.ContactFirstName) && u.LastName.Equals(vendorRegion.ContactLastName)).FirstOrDefault();

                    if (currentUserProfile != null)
                    {
                        var memberShipUser = dbContext.aspnet_Users.Where(u => u.UserId == currentUserProfile.aspnet_UserID).FirstOrDefault();
                        if (memberShipUser != null)
                        {
                            userName = memberShipUser.UserName;
                        }
                    }
                }
            }
            return userName;
        }


        /// <summary>
        /// Gets the user.
        /// </summary>
        /// <param name="FirstName">The first name.</param>
        /// <param name="LastName">The last name.</param>
        /// <param name="organizationName">Name of the organization.</param>
        /// <returns></returns>
        public string GetUser(string FirstName, string LastName, string organizationName)
        {
            string userName = string.Empty;
            using (DMSEntities dbContext = new DMSEntities())
            {
                OrganizationRepository organizationRepository = new OrganizationRepository();
                Organization org = organizationRepository.GetOrganizationByName(organizationName);
                if (org != null)
                {
                    int? organizationID = org.ID;
                    var currentUserProfile = dbContext.Users.Where(u => u.FirstName.Equals(FirstName) && u.LastName.Equals(LastName) && u.OrganizationID == organizationID).FirstOrDefault();

                    if (currentUserProfile != null)
                    {
                        var memberShipUser = dbContext.aspnet_Users.Where(u => u.UserId == currentUserProfile.aspnet_UserID).FirstOrDefault();
                        if (memberShipUser != null)
                        {
                            userName = memberShipUser.UserName;
                        }
                    }
                }

            }
            return userName;
        }

        /// <summary>
        /// Searches the specified search term.
        /// </summary>
        /// <param name="searchTerm">The search term.</param>
        /// <param name="pg">The pg.</param>
        /// <returns></returns>
        public List<VendorSearch_Result> Search(string searchTerm, PageCriteria pg)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.SearchVendor(searchTerm, pg.StartInd, pg.EndInd, pg.PageSize, pg.SortColumn, pg.SortDirection);
                return result.ToList<VendorSearch_Result>();
            }
        }

        /// <summary>
        /// Gets the vendor match.
        /// </summary>
        /// <param name="pageCriteria">The page criteria.</param>
        /// <param name="DispatchNum">The dispatch num.</param>
        /// <param name="OfficeNum">The office num.</param>
        /// <param name="VendorName">Name of the vendor.</param>
        /// <returns></returns>
        public List<GetVendorInfoSearch_Result> GetVendorMatch(PageCriteria pageCriteria, string DispatchNum, string OfficeNum, string VendorName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetVendorInfoSearch(pageCriteria.WhereClause, pageCriteria.StartInd, pageCriteria.EndInd, pageCriteria.PageSize, pageCriteria.SortColumn, pageCriteria.SortDirection, DispatchNum, OfficeNum, VendorName);
                return result.ToList<GetVendorInfoSearch_Result>();
            }
        }



        /// <summary>
        /// Adds the vendor.
        /// </summary>
        /// <param name="v">The v.</param>
        public void AddVendor(Vendor v)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.Vendors.Add(v);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Adds the vendor location.
        /// </summary>
        /// <param name="vl">The vl.</param>
        public void AddVendorLocation(VendorLocation vl)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.VendorLocations.Add(vl);
                dbContext.SaveChanges();
            }
        }


        /// <summary>
        /// Gets the vendor location status.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public VendorLocationStatu GetVendorLocationStatus(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.VendorLocationStatus.Where(x => x.Name == name).FirstOrDefault();
                return result;
            }
        }

        /// <summary>
        /// Gets the call history.
        /// </summary>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorCallHistory_Result> GetCallHistory(int serviceRequestID, int vendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var result = dbContext.GetVendorCallHistory(serviceRequestID, vendorLocationID).ToList<VendorCallHistory_Result>();
                return result;
            }
        }

        /// <summary>
        /// Vendors the details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <param name="vendorLocationID">The vendor location ID.</param>
        /// <param name="serviceRequestID">The service request ID.</param>
        /// <param name="searchFrom">The search from.</param>
        /// <returns></returns>
        public GetVendorDetails_Result VendorDetails(int vendorID, int vendorLocationID, int serviceRequestID, string searchFrom)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                GetVendorDetails_Result result = dbContext.GetVendorDetails(vendorID, vendorLocationID, serviceRequestID, searchFrom).FirstOrDefault();
                return result;
            }
        }



        /// <summary>
        /// Gets the vendor ID by number and tax ID.
        /// </summary>
        /// <param name="vendorNumber">The vendor number.</param>
        /// <param name="taxID">The tax ID.</param>
        /// <returns>VendorID if found, returns NULL otherwise</returns>
        public int? GetVendorIDByNumberAndTaxID(string vendorNumber, string taxID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var vendor = dbContext.Vendors.Where(v => v.VendorNumber == vendorNumber && (v.TaxEIN == taxID || v.TaxSSN == taxID)).FirstOrDefault();
                if (vendor != null)
                {
                    return vendor.ID;
                }
            }
            return null;
        }

        /// <summary>
        /// Gets the vendor ID by number and tax ID.
        /// </summary>
        /// <param name="vendorNumber">The vendor number.</param>
        /// <param name="taxID">The tax ID.</param>
        /// <returns>VendorID if found, returns NULL otherwise</returns>
        public int? GetVendorIDByNumberAndPhone(string vendorNumber, string phoneNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var vendor = dbContext.GetVendorByNumberAndPhone(vendorNumber, phoneNumber).ToList().FirstOrDefault();
                if (vendor != null)
                {
                    return vendor.VendorID;
                }
            }
            return null;
        }



        /// <summary>
        /// Determines whether [is vendor registered] [the specified vendor ID].
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns>
        ///   <c>true</c> if [is vendor registered] [the specified vendor ID]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsVendorRegistered(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var vendorUser = dbContext.VendorUsers.Where(v => v.VendorID == vendorID).FirstOrDefault();
                return vendorUser != null;
            }
        }

        /// <summary>
        /// Adds the vendor user.
        /// </summary>
        /// <param name="vendorUser">The vendor user.</param>
        /// <param name="createdBy">The created by.</param>
        public void AddVendorUser(VendorUser vendorUser, string createdBy, bool? setPostLoginValueToNull = null)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                vendorUser.CreateBy = createdBy;
                vendorUser.CreateDate = DateTime.Now;
                if (!setPostLoginValueToNull.GetValueOrDefault())
                {
                    var postLoginPrompt = dbContext.PostLoginPrompts.Where(p => p.Name == "InitialLoginVerifyData" && p.IsActive == true).FirstOrDefault();
                    if (postLoginPrompt != null)
                    {
                        vendorUser.PostLoginPromptID = postLoginPrompt.ID;
                    }
                }
                else
                {
                    vendorUser.PostLoginPromptID = null;
                }
                dbContext.VendorUsers.Add(vendorUser);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Gets the by ID.
        /// </summary>
        /// <param name="vendorId">The vendor ID.</param>
        /// <returns></returns>
        public Vendor GetByID(int vendorId)
        {
            using (var dbContext = new DMSEntities())
            {
                var vendor = dbContext.Vendors.Include("VendorStatu").Include("VendorRegion").FirstOrDefault(v => v.ID == vendorId);
                return vendor;
            }
        }

        /// <summary>
        /// Gets the vendor location by identifier.
        /// </summary>
        /// <param name="id">The identifier.</param>
        /// <returns></returns>
        public VendorLocation GetVendorLocationByID(int id)
        {
            using (var dbContext = new DMSEntities())
            {
                var vendorLocation = dbContext.VendorLocations.FirstOrDefault(v => v.ID == id);
                return vendorLocation;
            }
        }

        /// <summary>
        /// Gets the vendor locations list for vendor number.
        /// </summary>
        /// <param name="vendorNumber">The vendor number.</param>
        /// <returns></returns>
        public List<VendorLocationsListForVendorNumber_Result> GetVendorLocationsListForVendorNumber(string vendorNumber)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationsListForVendorNumber(vendorNumber).ToList();
            }
        }
    }
}
