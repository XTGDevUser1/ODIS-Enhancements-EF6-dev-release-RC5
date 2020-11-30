using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Mvc;
using s = System.Web.Security;
using System.Web.Security;
using log4net;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL;
using System.Text;
using Martex.DMS.Common;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.DAL.Common;
using System.IO;
using Martex.DMS.BLL.DataValidators;
using Martex.DMS.DAL.DAO.MessageMaintenance;
using Martex.DMS.DAL.DAO.Admin;
using Martex.DMS.DAL.DAO.QA;
using Martex.DMS.DAO;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.Areas.Common.Controllers
{
    /// <summary>
    /// Base Controller
    /// </summary>
    public class BaseController : Controller
    {
        #region Protected Members
        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(BaseController));

        #endregion

        #region Protected Methods

        /// <summary>
        /// Gets the vehicle type name by id.
        /// </summary>
        /// <param name="vt">The vt.</param>
        /// <returns></returns>
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

        /// <summary>
        /// Gets the state of the errors from model.
        /// </summary>
        /// <returns></returns>
        protected IEnumerable<string> GetErrorsFromModelState()
        {
            return ModelState.SelectMany(x => x.Value.Errors
                .Select(error =>
                {
                    logger.Warn(error.ErrorMessage);
                    return error.ErrorMessage;
                }));
        }

        /// <summary>
        /// Gets the errors from model state as string.
        /// </summary>
        /// <returns></returns>
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


        /// <summary>
        /// Sets the tab validation status.
        /// </summary>
        /// <param name="requestArea">The request area.</param>
        protected void SetTabValidationStatus(RequestArea requestArea)
        {
            var serviceRequestID = DMSCallContext.ActiveServiceRequestId ?? DMSCallContext.ServiceRequestID;
            //TFS:163
            ViewData[StringConstants.TAB_VALIDATION_STATUS] = (int)CallFacade.GetTabValidationStatus(serviceRequestID, requestArea);
            ViewData[StringConstants.SERVICE_REQUEST_EXCEPTIONS] = CallFacade.GetAllExceptions(serviceRequestID, requestArea);
        }
        #endregion

        #region Public Properties
        /// <summary>
        /// Gets the name of the logged in user.
        /// </summary>
        /// <value>
        /// The name of the logged in user.
        /// </value>
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
        /// Get the Logged In User Details
        /// </summary>
        /// <returns></returns>
        /// <exception cref="System.Exception">Request Unauthorized</exception>
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
        /// Get the Logged In User ID
        /// </summary>
        /// <returns></returns>
        public Guid GetLoggedInUserId()
        {
            return (Guid)GetLoggedInUser().ProviderUserKey;
        }

        /// <summary>
        /// Used to store User Details
        /// </summary>
        /// <param name="loggedInUsername">The logged in username.</param>
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
            userProfile.IsLoggedInUserPasswordExpired = ((DateTime.Now - userDetails.LastPasswordChangedDate).TotalDays >= 90 ? true : false);

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
                userProfile.Pin = up.Pin;
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
                DMSCallContext.IsClickToCallEnabled = true;
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

        #region Helpers
        protected string RenderPartialViewToString(string viewName, object model)
        {
            if (string.IsNullOrEmpty(viewName))
                viewName = ControllerContext.RouteData.GetRequiredString("action");
            ViewData.Model = model;
            using (StringWriter sw = new StringWriter())
            {
                ViewEngineResult viewResult = ViewEngines.Engines.FindPartialView(ControllerContext, viewName);
                ViewContext viewContext = new ViewContext(ControllerContext, viewResult.View, ViewData, TempData, sw);
                viewResult.View.Render(viewContext, sw);

                return sw.GetStringBuilder().ToString();
            }
        }
        #endregion

        #region Services

        public IMessageMaintenance MessageMaintenanceService
        {
            get
            {
                return new MessageMaintenanceService();
            }
        }

        public IEventViewerService EventViewerService
        {
            get
            {
                return new EventViewerService();
            }
        }

        public ICoachingConcern CoachingConcernService
        {
            get
            {
                return new CoachingConcernService();
            }
        }

        #endregion

        #region Hagerty Check
        internal bool IsHagertyProgram(int programID)
        {
            List<ChildrenPrograms_Result> list = ReferenceDataRepository.GetChildPrograms("Hagerty");
            if (list != null && list.Count > 0)
            {
                int count = list.Where(x => x.ProgramID == programID).Count();
                return count > 0;
            }
            return false;
        }
        #endregion

        /// <summary>
        /// Increments the call counts.
        /// </summary>
        /// <param name="countType">Type of the count.</param>
        protected void IncrementCallCounts(AgentTimeCounts countType)
        {
            var srAgentTime = DMSCallContext.SRAgentTime;
            if (srAgentTime != null)
            {
                var srAgentTimeRepository = new SRAgentTimeRepository();
                srAgentTimeRepository.UpdateCounts(srAgentTime.ID, countType);
            }
        }

        protected string GetTimeType()
        {
            if (User.IsInRole(RoleConstants.RVTech))
            {
                return TimeTypes.TECH;
            }
            if (User.IsInRole(RoleConstants.QA))
            {
                return TimeTypes.QA;
            }
            if(!( User.IsInRole(RoleConstants.Agent) || User.IsInRole(RoleConstants.Manager) || User.IsInRole(RoleConstants.Dispatcher) || User.IsInRole(RoleConstants.QA) ))
            {
                return TimeTypes.BACKOFFICE;
            }
            return TimeTypes.BACKEND;
        }

        protected void RecalculateEstimate()
        {
            logger.Info("Checking to see if estimate has to be recalculated");
            var serviceRequestId = DMSCallContext.ServiceRequestID;
            // Recalculate Estimate
            var srfacade = new ServiceFacade();
            ServiceRequest sr = srfacade.GetServiceRequestById(serviceRequestId);
            bool recalculateEstimate = true;
            var srStatus = sr.ServiceRequestStatu.Name;
            List<PurchaseOrder> issuedPurchaseOrders = new PORepository().GetIssuedPOsForSR(serviceRequestId);
            if (srStatus == ServiceRequestStatusNames.CANCELLED || srStatus == ServiceRequestStatusNames.COMPLETE)
            {
                recalculateEstimate = false;
            }
            else if (issuedPurchaseOrders != null && issuedPurchaseOrders.Count > 0)
            {
                recalculateEstimate = false;
            }
            logger.InfoFormat("Recalculating estimate? {0}", (sr.ServiceEstimate != null && sr.ServiceEstimate > 0 && recalculateEstimate));
            if (sr.ServiceEstimate != null && sr.ServiceEstimate > 0 && recalculateEstimate)
            {
                logger.InfoFormat("Updating estimate for SR ID - {0}", serviceRequestId);
                var estimateLog = new Dictionary<string, string>();
                estimateLog.Add("PriorEstimate", sr.ServiceEstimate.GetValueOrDefault().ToString());
                EstimateFacade estimateFacade = new EstimateFacade();
                var estimate = estimateFacade.GetServiceRequestEstimate(serviceRequestId);

                ServiceRepository serviceRepository = new ServiceRepository();
                sr.ServiceEstimate = estimate.Estimate;
                sr.EstimatedTimeCost = estimate.EstimatedTimeCost;

                estimateLog.Add("NewEstimate", sr.ServiceEstimate.GetValueOrDefault().ToString());

                serviceRepository.UpdateServiceRequestEstimateValues(sr, LoggedInUserName);
                var eventLogFacade = new EventLoggerFacade();
                var eventLogId = eventLogFacade.LogEvent(Request.RawUrl, EventNames.UPDATE_SERVICEREQUEST_ESTIMATE, estimateLog, LoggedInUserName, Session.SessionID);
                eventLogFacade.CreateRelatedLogLinkRecord(eventLogId, serviceRequestId, EntityNames.SERVICE_REQUEST);
                logger.InfoFormat("Logged event for updating estimate - {0}", eventLogId);
            }
        }

    }
}
