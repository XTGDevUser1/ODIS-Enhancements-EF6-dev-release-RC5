using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorPortalFacade
    {
        VendorPortalRepository repository = new VendorPortalRepository();

        /// <summary>
        /// Updates the change password vendor user.
        /// </summary>
        /// <param name="userId">The user id.</param>
        /// <param name="value">if set to <c>true</c> [value].</param>
        public VendorUser UpdateChangePasswordVendorUser(Guid userId,string randomString, bool value,string currentUser)
        {
            return repository.UpdateChangePasswordVendorUser(userId, randomString, value, currentUser);
        }

        /// <summary>
        /// Updates the user information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userId">The user id.</param>
        /// <param name="currentUser">The current user.</param>
        public void UpdateUserInformation(UserInformation model,Guid userId,string currentUser)
        {
            repository.UpdateUserInformation(model, userId, currentUser);
        }


        public bool CheckIsPasswordTokenValid(string vendorNumber, string resetPasswordToken)
        {
            return repository.CheckIsPasswordTokenValid(vendorNumber, resetPasswordToken);
        }

        public aspnet_Users GetVendorByVendorUserId(int vendorUserID)
        {
            return repository.GetVendorByVendorUserID(vendorUserID);
        }

        public aspnet_Membership GetAspnetMembershipUser(Guid aspnetUserID)
        {
            return repository.GetAspnetMembershipUser(aspnetUserID);
        }
        public Vendor GetVendor(int vendorUserID)
        {
            return repository.GetVendor(vendorUserID);
        }
    }
}
