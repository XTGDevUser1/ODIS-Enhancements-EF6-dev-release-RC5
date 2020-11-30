using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorManagementRepository
    {
        /// <summary>
        /// Gets the vendor location services service list.
        /// </summary>
        /// <param name="vendorId">The vendor ID.</param>
        /// <param name="vendorLocationId">The vendor location ID.</param>
        /// <returns></returns>
        public List<VendorLocationServices_Result> GetVendorLocationServices(int vendorId, int vendorLocationId)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.GetVendorLocationServices(vendorId, vendorLocationId).ToList();
            }
        }

        /// <summary>
        /// Vendor Portal Location Service
        /// </summary>
        /// <param name="vendorId"></param>
        /// <param name="vendorLocationId"></param>
        /// <returns></returns>
        public List<VendorPortalLocationServicesList_Result> GetVendorPortalLocationServicesList(int vendorId, int vendorLocationId)
        {
            using (var dbContext = new DMSEntities())
            {
                return dbContext.GetVendorPortalLocationServicesList(vendorId, vendorLocationId).ToList();
            }
        }


        /// <summary>
        /// Saves the vendor location services.
        /// </summary>
        /// <param name="vendorLocationId">The vendor location unique identifier.</param>
        /// <param name="services">The services.</param>
        /// <param name="createBy">The create by.</param>
        public void SaveVendorLocationServices(int vendorLocationId, List<string> services,  string createBy)
        {
            using (var dbContext = new DMSEntities())
            {
                dbContext.SaveVendorLocationProducts(vendorLocationId, string.Join(",", services.ToArray()), createBy);
            }
        }

    }
}
