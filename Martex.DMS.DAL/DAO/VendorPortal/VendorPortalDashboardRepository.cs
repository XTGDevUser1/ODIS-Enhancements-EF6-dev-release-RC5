using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO.VendorPortal
{
    public class VendorPortalDashboardRepository
    {

        /// <summary>
        /// Gets the vendor dashboard service call activity.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Vendor_Dashboard_ServiceCallActivity_Result> GetVendorDashboardServiceCallActivity(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorDashboardServiceCallActivity(vendorID).ToList();
            }
        }


        /// <summary>
        /// Gets the vendor dashboard service ratings.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Vendor_Dashboard_ServiceRatings_Result> GetVendorDashboardServiceRatings(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorDashboardServiceRatings(vendorID).ToList();
            }
        }


        /// <summary>
        /// Gets the vendor dashboard profile completeness.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<Vendor_Dashboard_Profile_completeness_Result> GetVendorDashboardProfileCompleteness(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorDashboardProfileCompleteness(vendorID).ToList();
            }
        }

        /// <summary>
        /// Gets the vendor dashboard service types.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorDashboardServiceTypes_Result> GetVendorDashboardServiceTypes(int vendorID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorDashboardServiceTypes(vendorID).ToList();
            }
        }
    }
}
