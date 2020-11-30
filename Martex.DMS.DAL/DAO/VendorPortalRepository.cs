using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using System.Data.Entity;
using log4net;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorPortalRepository
    {
        #region Protected Members
        protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorPortalRepository));
        #endregion
        /// <summary>
        /// Updates the change password vendor user.
        /// </summary>
        /// <param name="UserId">The user id.</param>
        /// <param name="value">if set to <c>true</c> [value].</param>
        public VendorUser UpdateChangePasswordVendorUser(Guid UserId, string randomString, bool value, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                string passwordTokenValidityInHours = AppConfigRepository.GetValue("PasswordTokenValidityInHours");
                VendorUser vu = dbContext.VendorUsers.Where(v => v.aspnet_UserID == UserId).FirstOrDefault();
                if (vu == null)
                {
                    throw new DMSException("No Vendor User Found");
                }
                //vu.ChangePassword = value;
                vu.PasswordResetToken = randomString;
                if (value)
                {
                    vu.PasswordTokenGeneratedOn = DateTime.UtcNow;
                    vu.PasswordTokenValidityInHours = int.Parse(passwordTokenValidityInHours);
                }
                else
                {
                    vu.PasswordTokenGeneratedOn = null;
                    vu.PasswordTokenValidityInHours = null;

                }
                vu.ModifyBy = currentUser;
                vu.ModifyDate = DateTime.Now;
                dbContext.Entry(vu).State = EntityState.Modified;
                dbContext.SaveChanges();
                return vu;
            }
        }

        /// <summary>
        /// Updates the user information.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="userId">The user id.</param>
        /// <param name="currentUser">The current user.</param>
        public void UpdateUserInformation(Entities.UserInformation model, Guid userId, string currentUser)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorUser vu = dbContext.VendorUsers.Where(v => v.aspnet_UserID == userId).FirstOrDefault();

                aspnet_Membership am = dbContext.aspnet_Membership.Where(a => a.UserId == userId).FirstOrDefault();
                vu.FirstName = model.FirstName;
                vu.LastName = model.LastName;
                vu.ReceiveNotification = model.ReceiveNotification;
                vu.ModifyBy = currentUser;
                vu.ModifyDate = DateTime.Now;

                am.Email = model.Email;
                am.LoweredEmail = model.Email.ToLower();

                dbContext.Entry(vu).State = EntityState.Modified;
                dbContext.Entry(am).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }

        public bool CheckIsPasswordTokenValid(string vendorNumber, string resetPasswordToken)
        {
            logger.InfoFormat("VendorPortalRepository -> CheckIsPasswordTokenValid. Parameters : (vendorNumber : {0} , resetPasswordToken: {1})", vendorNumber, resetPasswordToken);
            TimeSpan? timeElapsed;
            bool isResetPasswordTokenValid = false;
            using (var dbContext = new DMSEntities())
            {
                int? vendorUserId = int.Parse(vendorNumber);
                VendorUser vu = dbContext.VendorUsers.FirstOrDefault(v => v.ID == vendorUserId);
                if (vu == null)
                {
                    throw new DMSException("No Vendor User Found");
                }
                if (vu.PasswordTokenGeneratedOn.HasValue)
                {
                    timeElapsed = DateTime.UtcNow - vu.PasswordTokenGeneratedOn;
                    var timeElapsedInHours = (int)timeElapsed.Value.TotalHours;
                    logger.InfoFormat("VendorPortalRepository -> CheckIsPasswordTokenValid. Time Elapsed In Hours : {0}, PasswordTokenValidityInHours : {1}", timeElapsedInHours, vu.PasswordTokenValidityInHours);
                    isResetPasswordTokenValid = (vu.PasswordResetToken == resetPasswordToken) && (vu.PasswordTokenValidityInHours >= timeElapsedInHours);
                    logger.InfoFormat("VendorPortalRepository -> CheckIsPasswordTokenValid. Password Token Valid : {0}", isResetPasswordTokenValid);
                }
                return isResetPasswordTokenValid;
            }
        }

        /// <summary>
        /// Gets the vendor by vendor user identifier.
        /// </summary>
        /// <param name="vendorUserId">The vendor user identifier.</param>
        /// <returns></returns>
        public aspnet_Users GetVendorByVendorUserID(int vendorUserId)
        {
            using (var dbContext = new DMSEntities())
            {
                var user = new aspnet_Users();
                var vu = new VendorUser();
                vu = dbContext.VendorUsers.FirstOrDefault(v => v.ID == vendorUserId);
                user = dbContext.aspnet_Users.FirstOrDefault(a => a.UserId == vu.aspnet_UserID);
                return user;
            }
        }
        /// <summary>
        /// Gets the aspnet membership user.
        /// </summary>
        /// <param name="aspnetUserId">The aspnet user identifier.</param>
        /// <returns></returns>
        public aspnet_Membership GetAspnetMembershipUser(Guid aspnetUserId)
        {
            using (var dbContext = new DMSEntities())
            {
                var user = new aspnet_Membership();

                user = dbContext.aspnet_Membership.FirstOrDefault(a => a.UserId == aspnetUserId);
                return user;
            }
        }
        /// <summary>
        /// Gets the vendor.
        /// </summary>
        /// <param name="vendorUserId">The vendor user identifier.</param>
        /// <returns></returns>
        public Vendor GetVendor(int vendorUserId)
        {
            using (var dbContext = new DMSEntities())
            {
                var vendor = new Vendor();
                var vu = new VendorUser();
                vu = dbContext.VendorUsers.FirstOrDefault(v => v.ID == vendorUserId);
                vendor = dbContext.Vendors.FirstOrDefault(v => v.ID == vu.VendorID);
                return vendor;
            }
        }
    }
}
