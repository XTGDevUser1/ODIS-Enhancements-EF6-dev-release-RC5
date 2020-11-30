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

namespace VendorPortal.Controllers
{
    public class AccountController : BaseController
    {

        UsersFacade userFacade = new UsersFacade();
        VendorPortalFacade facade = new VendorPortalFacade();

        #region Public Methods
        [NoCache]
        public ActionResult Login()
        {
            LogBrowserInformation();
            return View();
        }




        /// <summary>
        /// LogOn - Action method for AJAX requests
        /// </summary>
        /// <param name="model">Login details</param>
        /// <returns>Json - Success if the login is successful; List of errors, otherwise</returns>
        [HttpPost, ValidateInput(false)]
        public JsonResult JsonLogOn(LogOnModel model, string returnUrl)
        {
            try
            {
                logger.InfoFormat("Validate credentials");
                EventLoggerFacade facade = new EventLoggerFacade();
                Dictionary<string, string> eventDetails = new Dictionary<string, string>();
                // Prepare event details
                eventDetails.Add("Username", model.UserName);

                if (ModelState.IsValid)
                {
                    if (membershipProvider.Membership.ValidateUser(model.UserName, model.Password))
                    {
                        FormsAuthentication.SetAuthCookie(model.UserName, true);

                        StoreProfile(model.UserName);
                        RegisterUserModel UserProfile = GetProfile();
                        if (returnUrl == "/")
                        {
                            returnUrl = "";
                        }
                        var isSysAdmin = Roles.IsUserInRole(model.UserName, "sysadmin");
                        if (isSysAdmin || UserProfile.Active)
                        {
                            // Log an event to the database
                            facade.LogEvent(Request.RawUrl, EventNames.LOGIN_SUCCESS, eventDetails, model.UserName, HttpContext.Session.SessionID);

                            logger.InfoFormat("Login Successful");
                            if (isSysAdmin)
                            {
                                return Json(new { success = true, redirect = "/Users/Home/Index" });
                            }
                            else
                            {
                                return Json(new { success = true, redirect = string.IsNullOrEmpty(returnUrl) ? "/ISP/Dashboard/Index" : returnUrl });
                            }
                        }
                        else
                        {
                            ModelState.AddModelError("", "This account is no longer active, please contact Vendor Services");
                        }
                    }
                    else
                    {
                        MembershipUser userDetails = membershipProvider.Membership.GetUser(model.UserName);
                        if (userDetails != null)
                        {
                            if (!userDetails.IsApproved)
                            {
                                ModelState.AddModelError("", "The Account has not been activated yet.");
                            }
                            else if (userDetails.IsLockedOut)
                            {
                                ModelState.AddModelError("", "The Account has been temporarily locked out. Please contact Vendor Services");
                            }
                            else
                            {
                                ModelState.AddModelError("", "That User name, password combination is not valid, please try again");
                            }
                        }
                        else
                        {
                            ModelState.AddModelError("", "That User name is not found in system, please try again");
                        }
                    }
                }

                // If we got this far, something failed
                // Log an event to the database            
                facade.LogEvent(Request.RawUrl, EventNames.LOGIN_FAILURE, eventDetails, model.UserName, HttpContext.Session.SessionID);
                var errorList = GetErrorsFromModelState();
                logger.InfoFormat("Log on failed with {0} errors", errorList.Count());



                return Json(new { errors = errorList }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                return Json(new { errors = new List<string>() { ex.Message } });
            }
        }

        //
        // GET: /Account/LogOff

        /// <summary>
        /// Logs the user out of the application.
        /// </summary>
        /// <returns></returns>
        public ActionResult LogOff()
        {
            Session.RemoveAll();
            FormsAuthentication.SignOut();

            return RedirectToAction("Login", "Account", new { area = string.Empty });
        }


        /// <summary>
        /// Register - Action method for AJAX requests
        /// </summary>
        /// <param name="model">The Registration details</param>
        /// <returns>Json - Success if the registration is successful; List of errors, otherwise</returns>
        [HttpPost]
        public ActionResult JsonRegister(RegisterModel model)
        {
            try
            {
                if (ModelState.IsValid)
                {
                    // Attempt to register the user
                    logger.InfoFormat("Attempting to register the user {0}", model.UserName);
                    MembershipCreateStatus createStatus;
                    MembershipUser user = membershipProvider.Membership.CreateUser(model.UserName, model.Password, model.Email, null, null, true, null, out createStatus);

                    if (createStatus == MembershipCreateStatus.Success)
                    {
                        FormsAuthentication.SetAuthCookie(model.UserName, createPersistentCookie: false);
                        return Json(new { success = true });
                    }
                    else
                    {
                        ModelState.AddModelError("", ErrorCodeToString(createStatus));
                    }
                }
                logger.Info("Registration failed");
                return Json(new { errors = GetErrorsFromModelState() }, JsonRequestBehavior.AllowGet);
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                return Json(new { errors = new List<string>() { ex.Message } });
            }
        }

        /// <summary>
        /// Retrieve Logged in user details
        /// </summary>
        /// <returns></returns>
        public ActionResult GetUserDetails()
        {
            RegisterUserModel model = Session["LOGGED_IN_USER"] as RegisterUserModel;
            return View("_UserProfileDetails", model);
        }

        #endregion

        #region Status Codes
        private static string ErrorCodeToString(MembershipCreateStatus createStatus)
        {
            // See http://go.microsoft.com/fwlink/?LinkID=177550 for
            // a full list of status codes.
            switch (createStatus)
            {
                case MembershipCreateStatus.DuplicateUserName:
                    return "User name already exists. Please enter a different user name.";

                case MembershipCreateStatus.DuplicateEmail:
                    return "A user name for that e-mail address already exists. Please enter a different e-mail address.";

                case MembershipCreateStatus.InvalidPassword:
                    return "The password provided is invalid. Please enter a valid password value.";

                case MembershipCreateStatus.InvalidEmail:
                    return "The e-mail address provided is invalid. Please check the value and try again.";

                case MembershipCreateStatus.InvalidAnswer:
                    return "The password retrieval answer provided is invalid. Please check the value and try again.";

                case MembershipCreateStatus.InvalidQuestion:
                    return "The password retrieval question provided is invalid. Please check the value and try again.";

                case MembershipCreateStatus.InvalidUserName:
                    return "The user name provided is invalid. Please check the value and try again.";

                case MembershipCreateStatus.ProviderError:
                    return "The authentication provider returned an error. Please verify your entry and try again. If the problem persists, please contact your system administrator.";

                case MembershipCreateStatus.UserRejected:
                    return "The user creation request has been canceled. Please verify your entry and try again. If the problem persists, please contact your system administrator.";

                default:
                    return "An unknown error occurred. Please verify your entry and try again. If the problem persists, please contact your system administrator.";
            }
        }
        #endregion

        #region Unused Action methods

        //
        // POST: /Account/LogOn
        [HttpPost, ValidateInput(false)]
        public ActionResult LogOn(LogOnModel model, string returnUrl)
        {

            if (ModelState.IsValid)
            {
                if (membershipProvider.Membership.ValidateUser(model.UserName, model.Password))
                {
                    FormsAuthentication.SetAuthCookie(model.UserName, model.RememberMe);

                    if (Url.IsLocalUrl(returnUrl) && returnUrl.Length > 1 && returnUrl.StartsWith("/")
                        && !returnUrl.StartsWith("//") && !returnUrl.StartsWith("/\\"))
                    {
                        return Redirect(returnUrl);
                    }
                    else
                    {
                        return RedirectToAction("Index", "Home");
                    }

                }
                else
                {
                    ModelState.AddModelError("", "That User name, password combination is not valid, please try again");
                }
            }


            // If we got this far, something failed, redisplay form
            return View(model);
        }

        //
        // GET: /Account/Register

        public ActionResult Register()
        {
            LogBrowserInformation();
            return View();
        }

        //
        // POST: /Account/Register

        [HttpPost, ValidateInput(false)]
        public ActionResult Register(RegisterModel model)
        {
            if (ModelState.IsValid)
            {
                // Attempt to register the user
                MembershipCreateStatus createStatus;
                membershipProvider.Membership.CreateUser(model.UserName, model.Password, model.Email, null, null, true, null, out createStatus);

                if (createStatus == MembershipCreateStatus.Success)
                {
                    FormsAuthentication.SetAuthCookie(model.UserName, false /* createPersistentCookie */);
                    return RedirectToAction("Index", "Home");
                }
                else
                {
                    ModelState.AddModelError("", ErrorCodeToString(createStatus));
                }
            }

            // If we got this far, something failed, redisplay form
            return View(model);
        }

        //
        // GET: /Account/ChangePassword

        [Authorize]
        public ActionResult ChangePassword()
        {
            return View();
        }

        //
        // POST: /Account/ChangePassword

        [Authorize]
        [HttpPost, ValidateInput(false)]
        public ActionResult ChangePassword(ChangePasswordModel model)
        {
            if (ModelState.IsValid)
            {

                // ChangePassword will throw an exception rather
                // than return false in certain failure scenarios.
                bool changePasswordSucceeded;
                try
                {
                    MembershipUser currentUser = membershipProvider.Membership.GetUser(User.Identity.Name, true /* userIsOnline */);
                    changePasswordSucceeded = currentUser.ChangePassword(model.OldPassword, model.NewPassword);
                }
                catch (Exception)
                {
                    changePasswordSucceeded = false;
                }

                if (changePasswordSucceeded)
                {
                    return RedirectToAction("ChangePasswordSuccess");
                }
                else
                {
                    ModelState.AddModelError("", "The current password is incorrect or the new password is invalid.");
                }
            }

            // If we got this far, something failed, redisplay form
            return View(model);
        }

        //
        // GET: /Account/ChangePasswordSuccess

        public ActionResult ChangePasswordSuccess()
        {
            return View();
        }

        #endregion

        #region Vendor related verification and registration methods

        /// <summary>
        /// Generates the activation email.
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        public ActionResult GenerateActivationEmail()
        {
            return PartialView("_GenerateActivationEmail");
        }

        /// <summary>
        /// Generates the activation email.
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        public ActionResult ResendActivationEmail()
        {
            return View("GenerateActivationEmail");
        }

        /// <summary>
        /// Generates the activation email.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        public ActionResult GenerateActivationEmail(string userName)
        {
            MembershipUser user = membershipProvider.Membership.GetUser(userName);
            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            VendorFacade facade = new VendorFacade();
            if (user == null)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = "User not found in the system";
            }
            else
            {
                //    StoreProfile(userName);
                //    RegisterUserModel UserProfile = GetProfile();
                //    bool isVendorRegistered = facade.IsVendorRegistered(UserProfile.VendorID.Value);

                if (user.IsApproved)
                {
                    result.Status = OperationStatus.ERROR;
                    result.ErrorMessage = "Your account has already been activated.  Please go to the Login page and login.  If you have forgotten your password you can request it be sent to you from the Login page.";
                    logger.Info("User Already Active");
                }
                else
                {
                    logger.InfoFormat("Sending activation link to {0}", user.Email);
                    SendActivationEmail(user);
                    logger.Info("Mail sent successfully");
                }
            }

            return Json(result, JsonRequestBehavior.AllowGet);

        }

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


        /// <summary>
        /// Activates the vendor.
        /// </summary>
        /// <param name="id">The confirmation token.</param>
        /// <returns></returns>
        public ActionResult ActivateVendor(string id)
        {
            TransitionVerifyFacade facade = new TransitionVerifyFacade();
            Guid activationToken = Guid.Empty;
            Guid.TryParse(id, out activationToken);
            MembershipUser user = membershipProvider.Membership.GetUser(activationToken);
            if (user != null)
            {
                //user.UnlockUser();
                user.IsApproved = true;
                membershipProvider.Membership.UpdateUser(user);
                logger.InfoFormat("activated the user {0}", user.UserName);
                VendorUser model = facade.GetVendorUserByUserId(activationToken);
                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                long eventID = eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.WEB_AUTHENTICATION, "Web registration authentication complete", id, "system", null, Session.SessionID);
                eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, model.VendorID, EntityNames.VENDOR);
                logger.Info("Event log created successfully");

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
                context.Add("user", user.UserName.Trim());
                context.Add("url", string.Format("{0}://{1}", Request.Url.Scheme, Request.Url.Authority));
                context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER) ?? string.Empty);
                context.Add("fax", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_FAX_NUMBER) ?? string.Empty);
                var vendor = vmFacade.Get(vendorUserFromDB.VendorID.Value);
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
                string toDisplayName = model.FirstName + " " + model.LastName;
                emailService.SendEmail(context, user.Email, TemplateNames.VENDOR_PORTAL_REGISTRATION_CONFIRMATION, fromAddress, fromDisplayName, toDisplayName);

                return View("ActivationSuccess");
            }
            else
            {
                logger.InfoFormat("Activation failed for the ID {0}", id);
                return View("ActivationFailure");
            }
        }

        /// <summary>
        /// _s the change password.
        /// </summary>
        /// <returns></returns>
        public ActionResult _ChangePassword()
        {
            ChangePasswordModel model = new ChangePasswordModel();
            UserProfileModel upm = new UserProfileModel();
            upm.ChangePasswordModel = model;
            return PartialView(upm);
        }

        /// <summary>
        /// Gets the post login URL.
        /// </summary>
        /// <param name="postLoginPromptId">The post login prompt id.</param>
        /// <returns></returns>
        public ActionResult GetPostLoginUrl(int? postLoginPromptId)
        {
            OperationResult result = new OperationResult();
            if (postLoginPromptId.HasValue)
            {
                PostLoginPrompt prompt = new ReferenceDataRepository().GetPostLoginUrl(postLoginPromptId.GetValueOrDefault());
                result.Data = prompt.PageReference;
                result.Status = "Success";
            }
            else
            {
                result.Data = "Post Login Prompt Id is null.";
                result.Status = "Failure";
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [AllowAnonymous]
        public ActionResult ForgotPassword(string id)
        {
            logger.InfoFormat("AccountController -> ForgotPassword(). Id : {0}", id);
            string passwordResetToken = id;
            var paymentRepository = new PaymentRepository();
            var vpFacade = new VendorPortalFacade();
            string decryptedPasswordResetToken = paymentRepository.EncryptDecrypt(passwordResetToken, false);
            string[] splittedStrings = decryptedPasswordResetToken.Split('&');
            string vendorNumber = splittedStrings[0];

            int vendorUserId = int.Parse(vendorNumber);
            aspnet_Users au = facade.GetVendorByVendorUserId(vendorUserId);
            if (au == null)
            {
                throw new DMSException(string.Format("No AspNet User Record found for vendorUserId : {0}", vendorUserId));
            }
            aspnet_Membership am = facade.GetAspnetMembershipUser(au.UserId);
            Vendor vendor = facade.GetVendor(vendorUserId);
            logger.InfoFormat("AccountController -> ForgotPassword(). Vendor User Id : {0}, User Name : {1}", vendorNumber, au.UserName);
            List<string> remainingStrings = new List<string>();
            for (int i = 1, l = splittedStrings.Length; i < l; i++)
            {
                remainingStrings.Add(splittedStrings[i]);
            }
            string resetPasswordToken = string.Join("&", remainingStrings);
            
            logger.InfoFormat("AccountController -> ForgotPassword(). Password Token : {0}", resetPasswordToken);
            bool isResetPasswordTokenValid = vpFacade.CheckIsPasswordTokenValid(vendorNumber, resetPasswordToken);
            logger.InfoFormat("AccountController -> ForgotPassword(). Password Token Valid : {0}", isResetPasswordTokenValid);

            ViewData["PasswordResetToken"] = resetPasswordToken;
            ViewData["IsResetPasswordTokenValid"] = isResetPasswordTokenValid;
            ViewData["UserName"] = au.UserName;
            ViewData["Email"] = vendor.Email ?? am.Email;
            var upModel = new UserProfileModel();

            return View(upModel);
        }

        [HttpPost, ValidateInput(false)]
        [AllowAnonymous]
        public ActionResult UpdatePassword(UserProfileModel upm)
        {
            ChangePasswordModel model = upm.ChangePasswordModel;
            var result = new OperationResult();
            bool changePasswordSucceeded;
            var currentUser = System.Web.Security.Membership.GetUser(User.Identity.Name, true /* userIsOnline */) ??
                                         System.Web.Security.Membership.GetUser(upm.ChangePasswordModel.UserName);
            try
            {
                changePasswordSucceeded = currentUser.ChangePassword(model.OldPassword, model.NewPassword);
            }
            catch (Exception)
            {
                result.Status = "Failure";
                result.Data = "The new password must be at least 7 characters";//ex.Message.ToString();
                return Json(result, JsonRequestBehavior.AllowGet);
            }

            var loggedInUserId = Guid.Empty;
            string loggedInUserName = LoggedInUserName;
            if (loggedInUserName == null || loggedInUserName == "")
            {
                loggedInUserName = upm.ChangePasswordModel.UserName;
            }
            MembershipUserCollection users = System.Web.Security.Membership.FindUsersByName(loggedInUserName);
            if (users.Count > 0)
            {
                loggedInUserId = (Guid)users[loggedInUserName].ProviderUserKey;
            }

            aspnet_Users user = userFacade.Get(loggedInUserId);
            StoreProfile(loggedInUserName);
            RegisterUserModel userProfile = GetProfile();

            if (string.IsNullOrEmpty(model.Email))
            {
                model.Email = userProfile.Email;
            }
            if (changePasswordSucceeded == true)
            {
                if (model.Email != null)
                {

                    EmailService email = new EmailService();
                    Hashtable context = new Hashtable();
                    context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER) ?? string.Empty);
                    VendorManagementFacade vendorFacade = new VendorManagementFacade();
                    var vendor = vendorFacade.Get(userProfile.VendorID.Value);
                    string fromDisplayName = AppConfigConstants.GLOBAL_FROM_DISPLAY_NAME_COACH_VENDOR;
                    string fromAddress = AppConfigRepository.GetValue(AppConfigConstants.NO_REPLY_FROM_EMAIL_ADDRESS);
                    string toDisplayName = userProfile.FirstName + " " + userProfile.LastName;
                    email.SendEmail(context, model.Email, TemplateNames.VENDOR_PORTAL_CHANGE_PASSWORD, fromAddress, fromDisplayName, toDisplayName);
                }

                facade.UpdateChangePasswordVendorUser(user.UserId, string.Empty, false, LoggedInUserName);
                StoreProfile(loggedInUserName);
                EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
                eventLoggerFacade.LogEvent(Request.RawUrl, EventNames.UPDATE_PASSWORD, "Update Password", loggedInUserName, Session.SessionID);
                result.Status = "Success";
            }
            else
            {
                result.Status = "Failure";
                if (userProfile.IsVendorLockedOut)
                {
                    result.Data = "The account is locked out. Please contact your vendor rep.";
                }
                else
                {
                    result.Data = "We are unable to change the password at this moment. Please click Forgot Password and try again.";
                }
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        #endregion

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

    }
}
