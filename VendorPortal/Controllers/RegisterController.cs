using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using membershipProvider = System.Web.Security;
using System.Web.Security;
using Martex.DMS.DAO;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using log4net;
using System.Collections;
using System.Web.Hosting;
using NVelocity.App;
using Commons.Collections;
using NVelocity;
using System.IO;
using System.Net.Mail;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using VendorPortal.Models;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Facade.VendorPortal;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.BLL.SMTPSettings;
using Martex.DMS.DAL.Extensions;
using VendorPortal.ActionFilters;
using VendorPortal.Common;

namespace VendorPortal.Controllers
{
    public class RegisterController : BaseController
    {
        UsersFacade userFacade = new UsersFacade();
       
        #region Private methods

        /// <summary>
        /// Sends the activation email.
        /// </summary>
        /// <param name="user">The user.</param>
        private void SendActivationEmail(MembershipUser user)
        {

            // Send an email to the user email address with the activation token.
            Hashtable context = new Hashtable();
            context.Add("url", string.Format("{0}://{1}", Request.Url.Scheme, Request.Url.Authority));
            context.Add("activationToken", (Guid)user.ProviderUserKey);
            context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER) ?? string.Empty);
            context.Add("fax", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_FAX_NUMBER) ?? string.Empty);
            EmailService emailService = new EmailService();
            aspnet_Users aspnetUser = userFacade.Get(Guid.Parse(user.ProviderUserKey.ToString()));
            VendorManagementFacade vendorFacade = new VendorManagementFacade();
            var vendorUser = vendorFacade.GetVendorUser(aspnetUser.UserId);
            var vendor = vendorFacade.Get(vendorUser.VendorID.Value);
            var vendorRegion = vendor.VendorRegion;
            if (vendorRegion != null)
            {
                context.Add("ContactFirstName", vendorRegion.ContactFirstName ?? string.Empty);
                context.Add("ContactLastName", vendorRegion.ContactLastName ?? string.Empty);
                context.Add("Email", vendorRegion.Email ?? string.Empty);
                context.Add("PhoneNumber", vendorRegion.PhoneNumber.GetFormattedPhoneNumber());
                context.Add("RegionName", vendorRegion.Name);
            }
            else
            {
                context.Add("ContactFirstName", string.Empty);
                context.Add("ContactLastName", string.Empty);
                context.Add("Email", string.Empty);
                context.Add("PhoneNumber", string.Empty);
                context.Add("RegionName", string.Empty);
            }


            string fromDisplayName = AppConfigConstants.GLOBAL_FROM_DISPLAY_NAME_COACH_VENDOR;
            string fromAddress = AppConfigRepository.GetValue(AppConfigConstants.NO_REPLY_FROM_EMAIL_ADDRESS);
            string toDisplayName = vendorUser.FirstName + " " + vendorUser.LastName;
            emailService.SendEmail(context, user.Email, TemplateNames.VENDOR_PORTAL_REGISTRATION_ACTIVATION, fromAddress, fromDisplayName, toDisplayName);
        }

        #endregion

        //
        // GET: /Register/
        [NoCache]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        public ActionResult Index()
        {
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            return View();
        }

        [NoCache]
        public ActionResult RegisterSuccess()
        {
            return View("_RegisterSuccess");
        }



        [HttpPost, ValidateInput(false)]
        [NoCache]
        public ActionResult Index(VendorIdentity model)
        {
            OperationResult result = new OperationResult();
            // Use VendorFacade to find out if there exists a vendor for the given identity parameters.
            // If vendor exists, check to see if the vendor is already registered.
            // Report status back accordingly.
            VendorFacade facade = new VendorFacade();
            var vendorID = facade.VerifyVendor(model.VendorNumber, model.PhoneNumber);
            if (vendorID == null)
            {
                logger.Info("Vendor not verified");
                result.Status = "NotFound";
            }
            else
            {
                bool isVendorRegistered = facade.IsVendorRegistered(vendorID.Value);
                logger.InfoFormat("Vendor [ {0} ] registered - {1}", vendorID.Value, isVendorRegistered);
                if (isVendorRegistered)
                {
                    result.Status = "Registered";
                }
                else
                {
                    result.Status = "NotRegistered";
                    result.Data = new { vendorID = vendorID.Value };
                }
            }

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        /// <summary>
        /// Registers the vendor.
        /// </summary>
        /// <param name="id">The id.</param>
        /// <returns></returns>      
        [NoCache]
        public ActionResult RegisterVendor(string id)
        {

            ViewData["VendorID"] = id;
            int IntvendorID = 0;
            int.TryParse(id, out IntvendorID);
            // Verify Vendor ID
            VendorRegisterModel model = new VendorRegisterModel();
            var facade = new TransitionVerifyFacade();
            Vendor vendorDetails = facade.GetVendorDetails(IntvendorID);
            model.FirstName = vendorDetails.ContactFirstName;
            model.LastName = vendorDetails.ContactLastName;
            model.Email = vendorDetails.Email;
            model.UserName = vendorDetails.VendorNumber;
            model.VendorID = IntvendorID;
            return PartialView("_RegisterVendor", model);
        }

        /// <summary>
        /// Registers the vendor.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        public ActionResult RegisterVendor(VendorRegisterModel model)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };

            try
            {
                logger.InfoFormat("Validate Registration details");
                EventLoggerFacade facade = new EventLoggerFacade();
                Dictionary<string, string> eventDetails = new Dictionary<string, string>();
                // Prepare event details
                eventDetails.Add("Username", model.UserName);
                eventDetails.Add("Email", model.Email);
                eventDetails.Add("FirstName", model.FirstName);
                eventDetails.Add("LastName", model.LastName);

                if (ModelState.IsValid)
                {
                    VendorFacade vendorFacade = new VendorFacade();

                    aspnet_Users aspNetUser = new aspnet_Users();
                    //Membership properties
                    aspNetUser.UserName = model.UserName.Trim();
                    aspNetUser.aspnet_Membership = new aspnet_Membership();
                    aspNetUser.aspnet_Membership.IsApproved = false;
                    aspNetUser.aspnet_Membership.Email = model.Email;
                    aspNetUser.aspnet_Membership.Password = model.Password == null ? string.Empty : model.Password;


                    VendorUser vendorUser = new VendorUser();
                    vendorUser.VendorID = model.VendorID;
                    vendorUser.FirstName = model.FirstName;
                    vendorUser.LastName = model.LastName;
                    // Set aspnet_userid after the userid is created.                    

                    logger.Info("Attempting to save the registration");
                    MembershipUser user = vendorFacade.RegisterVendor(aspNetUser, vendorUser, Request.RawUrl, eventDetails, model.UserName, HttpContext.Session.SessionID);

                    logger.Info("Vendor registered successfully, sending an activation email");
                    SendActivationEmail(user);

                    vendorFacade.LogContactForRegistration(model.VendorID, model.Email, model.FirstName, model.LastName);

                    logger.InfoFormat("Email sent successfully to {0}", user.Email);
                    return Json(new OperationResult() { Status = OperationStatus.SUCCESS }, JsonRequestBehavior.AllowGet);

                }

                // If we got this far, something failed
                // Log an event to the database            
                //facade.LogEvent(Request.RawUrl, EventNames.LOGIN_FAILURE, eventDetails, model.UserName, HttpContext.Session.SessionID);
                var errorList = GetErrorsFromModelState();
                logger.InfoFormat("Registration failed with {0} errors", errorList.Count());

                return Json(new { errors = errorList }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                return Json(new { errors = new List<string>() { ex.Message }, JsonRequestBehavior.AllowGet });
            }

        }
    }
}
