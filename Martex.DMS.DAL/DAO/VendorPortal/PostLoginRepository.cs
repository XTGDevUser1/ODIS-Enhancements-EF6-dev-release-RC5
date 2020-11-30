using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO.VendorPortal
{
    public class PostLoginRepository
    {
        /// <summary>
        /// Gets the vendor phone numbers.
        /// </summary>
        /// <param name="vendorId">The vendor identifier.</param>
        /// <returns></returns>
        public List<PostLogin_VendorPhoneNumbers_Result> GetVendorPhoneNumbers(int vendorId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetPostLogin_VendorPhoneNumbers(vendorId).ToList<PostLogin_VendorPhoneNumbers_Result>();
            }
        }

        /// <summary>
        /// Gets the latest contract and TA(Terms & Agreements) for vendor.
        /// </summary>
        /// <param name="vendorId">The vendor identifier.</param>
        /// <returns></returns>
        public LatestContractAndTAForVendor_Result GetLatestContractAndTAForVendor(int vendorId)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetLatestContractAndTAForVendor(vendorId).FirstOrDefault();
            }
        }

    }
}
