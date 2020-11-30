using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.DAO.VendorPortal
{
    public class TransitionVerifyRepository
    {
        /// <summary>
        /// Gets the vendor legacy.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <param name="password">The password.</param>
        /// <returns></returns>
        public VendorLegacyCredential GetVendorLegacy(string userName, string password, int? vendorID = null)
        {
            VendorLegacyCredential model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                if (vendorID.HasValue)
                {
                    model = dbContext.VendorLegacyCredentials.Where(u => u.VendorID == vendorID).FirstOrDefault();
                }
                else
                {
                    model = dbContext.VendorLegacyCredentials.Where(u => u.UserName.Equals(userName) && u.Password.Equals(password)).FirstOrDefault();
                }
            }
            return model;
        }

        /// <summary>
        /// Gets the vendor user details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public VendorUser GetVendorUserDetails(int vendorID)
        {
            VendorUser model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.VendorUsers.Where(u => u.VendorID == vendorID).FirstOrDefault();
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
            Vendor model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.Vendors.Where(u => u.ID == vendorID).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the post login prompt details.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public PostLoginPrompt GetPostLoginPromptDetails(string name)
        {
            PostLoginPrompt model = null;
            using (DMSEntities dbContext = new DMSEntities())
            {
                model = dbContext.PostLoginPrompts.Where(u => u.IsActive == true && u.Name.Equals(name, StringComparison.CurrentCultureIgnoreCase)).FirstOrDefault();
            }
            return model;
        }

        /// <summary>
        /// Gets the vendor user by user id.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <returns></returns>
        public VendorUser GetVendorUserByUserId(Guid userID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorUsers.Where(u => u.aspnet_UserID == userID).FirstOrDefault();
            }
        }
    }
}
