using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DAO.VendorPortal;

namespace Martex.DMS.BLL.Facade.VendorPortal
{
    public class TransitionVerifyFacade
    {
        /// <summary>
        /// Verifies the vendor legacy.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <param name="password">The password.</param>
        /// <returns></returns>
        public bool VerifyVendorLegacy(string userName, string password)
        {
            var repository = new TransitionVerifyRepository();
            bool isValid = false;
            VendorLegacyCredential model = repository.GetVendorLegacy(userName, password);
            if (model != null)
            {
                isValid = true;
            }
            return isValid;
        }

        /// <summary>
        /// Determines whether [is vendor registered] [the specified user name].
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <param name="password">The password.</param>
        /// <returns>
        ///   <c>true</c> if [is vendor registered] [the specified user name]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsVendorRegistered(string userName, string password)
        {
            bool isRegistered = false;
            var repository = new TransitionVerifyRepository();
            VendorUser model = repository.GetVendorUserDetails(repository.GetVendorLegacy(userName, password).VendorID);
            if (model != null)
            {
                isRegistered = true;
            }
            return isRegistered;
        }

        /// <summary>
        /// Gets the vendor legacy details.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <param name="password">The password.</param>
        /// <returns></returns>
        public VendorLegacyCredential GetVendorLegacyDetails(string userName, string password, int? vendorID = null)
        {
            var repository = new TransitionVerifyRepository();
            return repository.GetVendorLegacy(userName, password, vendorID);
        }

        /// <summary>
        /// Gets the vendor details.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        public Vendor GetVendorDetails(int vendorID)
        {
            var repository = new TransitionVerifyRepository();
            return repository.GetVendorDetails(vendorID);

        }

        /// <summary>
        /// Gets the post login prompt details.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public PostLoginPrompt GetPostLoginPromptDetails(string name)
        {
            var repository = new TransitionVerifyRepository();
            return repository.GetPostLoginPromptDetails(name);
        }


        /// <summary>
        /// Gets the vendor user by user id.
        /// </summary>
        /// <param name="userID">The user ID.</param>
        /// <returns></returns>
        public VendorUser GetVendorUserByUserId(Guid userID)
        {
            var repository = new TransitionVerifyRepository();
            return repository.GetVendorUserByUserId(userID);
        }
    }
}
