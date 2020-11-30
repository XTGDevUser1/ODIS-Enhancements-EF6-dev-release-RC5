using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using s = System.Web.Security;
using System.Web.Security;
using log4net;
using ClientPortal.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using System.Text;
using ClientPortal.Common;
using ClientPortal.Areas.Application.Models;
using Martex.DMS.DAL.Common;

namespace ClientPortal.Areas.Common.Controllers
{
    public class BaseController : Controller
    {
        #region Protected Members
        protected static readonly ILog logger = LogManager.GetLogger(typeof(BaseController));
        #endregion

        #region Protected Methods

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
            UsersFacade facade = new UsersFacade();

            var loggedInUserId = Guid.Empty;
            MembershipUserCollection users = s.Membership.FindUsersByName(loggedInUsername);
            if (users.Count > 0)
            {
                loggedInUserId = (Guid)users[loggedInUsername].ProviderUserKey;
            }

            aspnet_Users user = facade.Get(loggedInUserId);
            MembershipUser userDetails = s.Membership.GetUser(loggedInUsername);
            RegisterUserModel userProfile = new RegisterUserModel();
            var up = user.Users.FirstOrDefault();
            if (up != null)
            {
                userProfile.FirstName = up.FirstName;
                userProfile.AgentNumber = up.AgentNumber;
                userProfile.Email = userDetails.Email;
                userProfile.LastName = up.LastName;
                userProfile.OrganizationName = up.Organization.Name;
                userProfile.UserRoles = Roles.GetRolesForUser(loggedInUsername);
                userProfile.ID = up.ID;
                userProfile.PhoneUserId = up.PhoneUserID;
                userProfile.PhonePassword = up.PhonePassword;

            }
            else
            {
                up = new User();
            }

            // Log an event for click to call.
            EventLoggerFacade eventLogFacade = new EventLoggerFacade();
            string eventDetails = "<EventDetail><Result>{0}</Result><DeviceName>{1}</DeviceName></EventDetail>";
            string deviceName = DMSCallContext.ClickToCallDeviceName;
            bool result = string.IsNullOrEmpty(deviceName) ? false : true;
            eventDetails = string.Format(eventDetails, result, deviceName);
            logger.InfoFormat("Logging an event for click to call : {0} ", eventDetails);

            eventLogFacade.LogEvent(Request.RawUrl, "DeviceInfoReadByApplet", eventDetails, loggedInUsername, up.ID, EntityNames.USER, Session.SessionID);

            if (string.IsNullOrEmpty(deviceName) || string.IsNullOrEmpty(up.PhoneUserID) || string.IsNullOrEmpty(up.PhonePassword))
            {
                logger.InfoFormat("Device name : {0}, PhoneUserId : {1} and PhonePassword (available?) : {2}", deviceName, up.PhoneUserID, string.IsNullOrEmpty(up.PhonePassword));
                logger.Warn("Disabling click-to-call as one of the required parameters is missing");
                DMSCallContext.IsClickToCallEnabled = false;
            }
            userProfile.UserName = loggedInUsername;
            Session["LOGGED_IN_USER"] = userProfile;

            //Store Access List
            Session[StringConstants.SESSION_ACCESS_LIST] = facade.GetAccessControlList(loggedInUserId);
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
        #endregion


    }
}
