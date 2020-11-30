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

namespace VendorPortal.Controllers
{
    public class TransitionRegisterController : BaseController
    {
        #region Utility methods
        /// <summary>
        /// Gets the formatted phone number.
        /// </summary>
        /// <param name="p">The application.</param>
        /// <returns></returns>
        private string GetFormattedPhoneNumber(string p)
        {
            if (string.IsNullOrEmpty(p))
            {
                return p;
            }
            var tokens = p.Split(' ');
            var phoneNumber = tokens[1];
            return string.Format("({0}){1}-{2}", phoneNumber.Substring(0, 3), phoneNumber.Substring(3, 3), phoneNumber.Substring(6));
        }
        #endregion

       
        public ActionResult Index()
        {
            ViewData["AppVersion"] = AppConfigRepository.GetValue(AppConfigConstants.APPLICATION_VERSION);
            ViewData[AppConfigConstants.DEVICE_NAME_REGISTRY_PATH] = AppConfigRepository.GetValue(AppConfigConstants.DEVICE_NAME_REGISTRY_PATH);
            LogOnModel model = new LogOnModel();
            return View(model);
        }

        [HttpPost, ValidateInput(false)]
        public JsonResult JsonTransitionVerify(LogOnModel model, string returnUrl)
        {
            var facade = new TransitionVerifyFacade();
            try
            {
                logger.InfoFormat("Transition Verify");
                if (ModelState.IsValid)
                {
                    if (facade.VerifyVendorLegacy(model.UserName, model.Password))
                    {
                        if (!facade.IsVendorRegistered(model.UserName, model.Password))
                        {
                            logger.InfoFormat("Transition Verify success user is not registered");
                            string vendorID = facade.GetVendorLegacyDetails(model.UserName, model.Password).VendorID.ToString();
                            return Json(new { success = true, VendorID = vendorID }, JsonRequestBehavior.AllowGet);
                        }
                        else
                        {
                            logger.InfoFormat("Transition Verify success user is already registered");
                            return Json(new { registered = true }, JsonRequestBehavior.AllowGet);
                        }
                    }
                    else
                    {
                        ModelState.AddModelError("", "That User name, password combination is not valid, please try again");
                    }
                }
                var errorList = GetErrorsFromModelState();
                logger.InfoFormat("Transition Verify failed with {0} errors", errorList.Count());
                return Json(new { errors = errorList }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                return Json(new { errors = new List<string>() { ex.Message }, JsonRequestBehavior.AllowGet });
            }
        }

        /// <summary>
        /// Vendors the register transition.
        /// </summary>
        /// <param name="vendorID">The vendor ID.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        public ActionResult RegisterVendorTransition(string VendorID)
        {
            int IntvendorID = 0;
            int.TryParse(VendorID, out IntvendorID);

            // Verify Vendor ID
            var facade = new TransitionVerifyFacade();
            VendorLegacyCredential vendorLegacyRecord = facade.GetVendorLegacyDetails(string.Empty, string.Empty, IntvendorID);
            if (vendorLegacyRecord == null)
            {
                return RedirectToAction("Index");
            }

            // Verify Registration once again
            if (facade.IsVendorRegistered(vendorLegacyRecord.UserName, vendorLegacyRecord.Password))
            {
                return RedirectToAction("Index");
            }

            VendorRegisterModel model = new VendorRegisterModel();
            Vendor vendorDetails = facade.GetVendorDetails(IntvendorID);
            model.FirstName = vendorDetails.ContactFirstName;
            model.LastName = vendorDetails.ContactLastName;
            model.Email = vendorDetails.Email;
            model.UserName = facade.GetVendorLegacyDetails(string.Empty, string.Empty, IntvendorID).UserName;
            model.VendorID = IntvendorID;
            return PartialView("_RegisterVendorTransition", model);
        }

        [HttpPost, ValidateInput(false)]
        public ActionResult SaveVendorTransition(VendorRegisterModel model)
        {
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            var transitionFacade = new TransitionVerifyFacade();
            try
            {
                logger.InfoFormat("Validate Transition Registration details");
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
                    aspNetUser.MobileAlias = null;
                    aspNetUser.IsAnonymous = false;

                    aspNetUser.aspnet_Membership = new aspnet_Membership();
                    aspNetUser.aspnet_Membership.IsApproved = true;
                    aspNetUser.aspnet_Membership.IsLockedOut = false;
                    aspNetUser.aspnet_Membership.Email = model.Email;
                    aspNetUser.aspnet_Membership.Password = model.Password;


                    VendorUser vendorUser = new VendorUser();
                    vendorUser.VendorID = model.VendorID;
                    vendorUser.FirstName = model.FirstName;
                    vendorUser.LastName = model.LastName;
                    vendorUser.IsHelpOverlayEnabled = true;
                    PostLoginPrompt postLogin = transitionFacade.GetPostLoginPromptDetails("InitialLoginVerifyData");
                    if (postLogin != null)
                    {
                        vendorUser.PostLoginPromptID = postLogin.ID;
                    }
                    else
                    {
                        throw new DMSException("Post Login Prompt - InitialLoginVerifyData is not set up in the system");
                    }
                    // Set aspnet_userid after the userid is created.                    

                    logger.Info("Attempting to save the registration");
                    MembershipUser user = vendorFacade.RegisterVendor(aspNetUser, vendorUser, Request.RawUrl, eventDetails, model.UserName, HttpContext.Session.SessionID, true);
                    logger.Info("Vendor registered successfully");

                    // Get Vendor Office Phone.
                    VendorManagementFacade vmFacade = new VendorManagementFacade();
                    var vendorUserFromDB = vmFacade.GetVendorUser((Guid)user.ProviderUserKey);

                    var phoneFacade = new PhoneFacade();
                    var officePhone = phoneFacade.Get(vendorUserFromDB.VendorID.GetValueOrDefault(), EntityNames.VENDOR, "Office");
                    string officePhoneNumber = string.Empty;
                    if (officePhone != null)
                    {
                        officePhoneNumber = GetFormattedPhoneNumber(officePhone.PhoneNumber);
                    }

                    EmailService emailService = new EmailService();

                    Hashtable context = new Hashtable();
                    context.Add("user", model.UserName.Trim());
                    context.Add("url", string.Format("{0}://{1}", Request.Url.Scheme, Request.Url.Authority));

                    var vendor = vmFacade.Get(vendorUserFromDB.VendorID.Value);
                    var vendorRegion = vendor.VendorRegion;
                    context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER) ?? string.Empty);
                    context.Add("fax", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_FAX_NUMBER) ?? string.Empty);
                
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
                    string toDisplayName = model.FirstName + " " + model.LastName;
                    emailService.SendEmail(context, model.Email, TemplateNames.VENDOR_PORTAL_TRANSITION_REGISTRATION_CONFIRMATION, fromAddress, fromDisplayName, toDisplayName);
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
                return Json(new { errors = new List<string>() { ex.Message } }, JsonRequestBehavior.AllowGet);
            }

        }

        [HttpPost]
        public ActionResult VendorTransitionSuccess()
        {
            return View();
        }

    }
}
