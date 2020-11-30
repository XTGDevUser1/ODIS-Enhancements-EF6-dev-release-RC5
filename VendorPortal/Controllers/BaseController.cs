using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using s = System.Web.Security;
using System.Web.Security;
using log4net;
using VendorPortal.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using System.Text;
using VendorPortal.Common;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.Model;
using System.Xml;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Extensions;

namespace VendorPortal.Controllers
{
    public class BaseController : Controller
    {
        #region Protected Members
        protected static readonly ILog logger = LogManager.GetLogger(typeof(BaseController));
        #endregion

        #region Protected Methods

        protected void LogBrowserInformation()
        {
            var browser = Request.Browser;
            logger.InfoFormat("Request captured from browser : {0}", "Type = " + browser.Type + "\n"
                                                                        + "Name = " + browser.Browser + "\n"
                                                                        + "Version = " + browser.Version + "\n"
                                                                        + "Major Version = " + browser.MajorVersion + "\n"
                                                                        + "Minor Version = " + browser.MinorVersion + "\n"
                                                                        + "Platform = " + browser.Platform + "\n");
        }
        protected string GetVehicleTypeNameById(int vt)
        {
            string vehicleType = "Auto";
            switch (vt)
            {
                case ((int)VehicleTypes.Auto):
                    vehicleType = VehicleTypes.Auto.ToString();
                    break;
                case ((int)VehicleTypes.Motorcycle):
                    vehicleType = VehicleTypes.Motorcycle.ToString();
                    break;
                case ((int)VehicleTypes.RV):
                    vehicleType = VehicleTypes.RV.ToString();
                    break;
                case ((int)VehicleTypes.Trailer):
                    vehicleType = VehicleTypes.Trailer.ToString();
                    break;
            }

            return vehicleType;
        }
        protected IEnumerable<string> GetErrorsFromModelState()
        {
            return ModelState.SelectMany(x => x.Value.Errors
                .Select(error =>
                {
                    logger.Warn(error.ErrorMessage);
                    return error.ErrorMessage;
                }));
        }
        protected string GetErrorsFromModelStateAsString()
        {
            StringBuilder sb = new StringBuilder();
            ModelState.ForEach(x => x.Value.Errors
                .ForEach(error =>
                {
                    logger.Warn(error.ErrorMessage);
                    sb.AppendLine(error.ErrorMessage);
                }));
            return sb.ToString();
        }

        #endregion

        #region Public Properties
        public string LoggedInUserName
        {
            get
            {
                return User.Identity.Name;
            }
        }
        #endregion

        #region Public Methods
        /// <summary>
        /// Get the Logged User Details
        /// </summary>
        /// <returns></returns>
        public MembershipUser GetLoggedInUser()
        {
            if (Request.IsAuthenticated)
            {
                string loggedInUsername = User.Identity.Name;
                MembershipUserCollection users = s.Membership.FindUsersByName(loggedInUsername);
                if (users.Count > 0)
                {
                    return users[loggedInUsername];
                }
            }

            throw new Exception("Request Unauthorized");
        }
        /// <summary>
        /// Get the Logged User ID
        /// </summary>
        /// <returns></returns>
        public Guid GetLoggedInUserId()
        {
            return (Guid)GetLoggedInUser().ProviderUserKey;
        }
        /// <summary>
        /// Used to store User Details
        /// </summary>
        /// <param name="loggedInUsername"></param>
        public void StoreProfile(string loggedInUsername)
        {
            var userFacade = new UsersFacade();

            /*AppConfigRepository appConfigRepository = new AppConfigRepository();
            string vendorRegionOfficePhoneNumber = AppConfigRepository.GetValue("VendorServicesPhoneNumber");
            string vendorRegionFaxPhoneNumber = AppConfigRepository.GetValue("VendorServicesFaxNumber");
            var loggedInUserId = Guid.Empty;
            MembershipUserCollection users = s.Membership.FindUsersByName(loggedInUsername);
            
            if (users.Count > 0)
            {
                loggedInUserId = (Guid)users[loggedInUsername].ProviderUserKey;
            }

            aspnet_Users user = userFacade.Get(loggedInUserId);
            MembershipUser userDetails = s.Membership.GetUser(loggedInUsername);

            RegisterUserModel userProfile = new RegisterUserModel();
            VendorManagementFacade vendorFacade = new VendorManagementFacade();
            var vendorUser = vendorFacade.GetVendorUser(user.UserId);
            userProfile.VendorRegionOfficeNumber = vendorRegionOfficePhoneNumber;
            userProfile.VendorRegionFaxNumber = vendorRegionFaxPhoneNumber;
            if (vendorUser != null)
            {
                var vendor = vendorFacade.Get(vendorUser.VendorID.Value);

                userProfile.FirstName = vendorUser.FirstName;
                userProfile.Email = userDetails.Email;
                userProfile.LastName = vendorUser.LastName;
                userProfile.UserRoles = Roles.GetRolesForUser(loggedInUsername);
                userProfile.ID = vendorUser.ID;
                userProfile.VendorID = vendorUser.VendorID;
                userProfile.PostLoginPromptID = vendorUser.PostLoginPromptID;
                userProfile.ChangePassowrd = vendorUser.ChangePassword;
                userProfile.ReceiveNotification = vendorUser.ReceiveNotification;

                if (vendor != null)
                {
                    userProfile.VendorName = vendor.Name;
                    userProfile.VendorNumber = vendor.VendorNumber;
                    userProfile.Active = vendor.IsActive;

                    var vendorRegion = vendor.VendorRegion;
                    if (vendorRegion != null)
                    {
                        userProfile.VendorRegionContactFirstName = vendorRegion.ContactFirstName;
                        userProfile.VendorRegionContactLastName = vendorRegion.ContactLastName;
                        userProfile.VendorRegionEmail = vendorRegion.Email;
                        userProfile.VendorRegionPhoneNumber = vendorRegion.PhoneNumber;
                        userProfile.VendorRegionName = vendorRegion.Name;
                    }
                }
            }
            */
            var vendorUserFacade = new VendorUserFacade();
            var vendorFacade = new VendorFacade();
            var vendorUserProfile = vendorUserFacade.GetVendorUserProfile(loggedInUsername);
            if (vendorUserProfile != null)
            {
                var userProfile = new RegisterUserModel
                {
                    UserName = loggedInUsername,
                    VendorRegionOfficeNumber = vendorUserProfile.VendorServicesPhoneNumber,
                    VendorRegionFaxNumber = vendorUserProfile.VendorServicesFaxNumber,
                    FirstName = vendorUserProfile.FirstName,
                    Email = vendorUserProfile.Email,
                    LastName = vendorUserProfile.LastName,
                    UserRoles = Roles.GetRolesForUser(loggedInUsername),
                    ID = vendorUserProfile.VendorUserID,
                    VendorID = vendorUserProfile.VendorID,
                    PostLoginPromptID = vendorUserProfile.PostLoginPromptID.GetValueOrDefault(),
                    ChangePassowrd = vendorUserProfile.ChangePassword.GetValueOrDefault(),
                    ReceiveNotification = vendorUserProfile.ReceiveNotification.GetValueOrDefault(),
                    VendorName = vendorUserProfile.VendorName,
                    VendorNumber = vendorUserProfile.VendorNumber,
                    Active = vendorUserProfile.VendorIsActive,
                    IsVendorLockedOut = vendorUserProfile.IsVendorLockedOut.GetValueOrDefault(),
                    VendorRegionContactFirstName = vendorUserProfile.VendorRegionContactFirstName,
                    VendorRegionContactLastName = vendorUserProfile.VendorRegionContactLastName,
                    VendorRegionEmail = vendorUserProfile.VendorRegionEmail,
                    VendorRegionPhoneNumber = vendorUserProfile.VendorRegionPhoneNumber,
                    VendorRegionName = vendorUserProfile.VendorRegionName
                };


                var vendor = vendorFacade.GetVendor(vendorUserProfile.VendorID);
                if (vendor != null)
                {
                    userProfile.InsuranceExpirationDate = vendor.InsuranceExpirationDate;
                }
                Session["LOGGED_IN_USER"] = userProfile;

                Session[StringConstants.SESSION_ACCESS_LIST] = userFacade.GetAccessControlList(vendorUserProfile.UserId);
            }
        }

        public int LoggedInUserVendorID
        {
            get
            {
                var userProfile = Session["LOGGED_IN_USER"] as RegisterUserModel;
                if (userProfile == null)
                {
                    throw new Exception("Request Unauthorized");
                }
                return userProfile.VendorID.GetValueOrDefault();
            }
        }

        /// <summary>
        /// Determines whether [is super vendor] [the specified user ID].
        /// </summary>
        /// <param name="userId">The user ID.</param>
        /// <returns>
        ///   <c>true</c> if [is super vendor] [the specified user ID]; otherwise, <c>false</c>.
        /// </returns>
        public bool IsSuperVendor(Guid userId)
        {

            bool isSuper = false;

            var membershipUser = s.Membership.GetUser(userId);
            if (membershipUser != null && Roles.IsUserInRole(membershipUser.UserName, "sysadmin"))
            {
                logger.InfoFormat("{0} is a sysadmin", membershipUser.UserName);
                return true;
            }
            var userFacade = new UsersFacade();
            var vendorFacade = new VendorManagementFacade();
            var vendorUser = vendorFacade.GetVendorUser(userId);
            if (vendorUser != null)
            {
                var vendorDetails = vendorFacade.Get(vendorUser.VendorID.GetValueOrDefault());
                aspnet_Users user = userFacade.Get(userId);
                if (user != null)
                {
                    if (vendorDetails.VendorNumber.Equals(user.UserName, StringComparison.OrdinalIgnoreCase))
                    {
                        isSuper = true;
                    }
                }
            }
            return isSuper;

        }

        /// <summary>
        /// Get the access on USer Profile
        /// </summary>
        /// <returns></returns>
        public RegisterUserModel GetProfile()
        {
            // If the object in session got disposed due to GC, let's attempt to reload the profile once again.

            var userProfile = Session["LOGGED_IN_USER"] as RegisterUserModel;
            if (userProfile == null && Request.IsAuthenticated)
            {
                StoreProfile(LoggedInUserName);
            }

            return Session["LOGGED_IN_USER"] as RegisterUserModel;
        }


        public string GetLoggedInUserPhone(string PhoneType)
        {
            var user = GetProfile();
            return ReferenceDataRepository.GetLoggedInUserPhone(EntityNames.VENDOR, PhoneType, user.VendorID);
        }

        #endregion
    }
}
