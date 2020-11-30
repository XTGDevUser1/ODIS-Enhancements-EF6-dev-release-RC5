using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Routing;
using System.Web.Security;
using Martex.DMS.Models;
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
using Martex.DMS.Areas.Common.Controllers;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.Areas.Application.Models;
using Martex.DMS.ActionFilters;
using Martex.DMS.DAL;
using System.Text;
using System.Security.Cryptography;
using Newtonsoft.Json;

namespace Martex.DMS.Controllers
{
    /// <summary>
    /// Account Controller
    /// </summary>
    public class AccountController : BaseController
    {

        private string GetReturnUrl(string userName)
        {
            string returnUrl = "/Home/Index";
            string[] userRoles = Roles.GetRolesForUser(userName);
            if (userRoles.Length > 0)
            {
                switch (userRoles[0].ToLower())
                {
                    case "agent":
                        break;
                    case "clientadmin":
                        break;
                    case "manager":
                        break;
                    case "qa":
                        break;
                    case "dispatcher":
                        break;
                    case "clientagent":
                        break;
                    case "sysadmin":
                        break;
                }
            }
            return returnUrl;
        }

        #region Public Methods
        /// <summary>
        /// Method to Verify the Login
        /// </summary>
        /// <returns></returns>
        [NoCache]
        public ActionResult LogOn()
        {
            ViewData["AppVersion"] = AppConfigRepository.GetValue(AppConfigConstants.APPLICATION_VERSION);
            ViewData[AppConfigConstants.DEVICE_NAME_REGISTRY_PATH] = AppConfigRepository.GetValue(AppConfigConstants.DEVICE_NAME_REGISTRY_PATH);

            // Calculate click to call enable status.
            bool isClickToCallEnabled = false;

            string configValue = AppConfigRepository.GetValue(AppConfigConstants.CLICK_TO_CALL_ENABLED);
            bool.TryParse(configValue, out isClickToCallEnabled);
            DMSCallContext.IsClickToCallEnabled = isClickToCallEnabled;

            return View();
        }

        /// <summary>
        /// LogOn - Action method for AJAX requests
        /// </summary>
        /// <param name="model">Login details</param>
        /// <param name="returnUrl">The return URL.</param>
        /// <returns>
        /// Json - Success if the login is successful; List of errors, otherwise
        /// </returns>
        [HttpPost]
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
                    if (System.Web.Security.Membership.ValidateUser(model.UserName, model.Password))
                    {
                        FormsAuthentication.SetAuthCookie(model.UserName, true);
                        // Log an event to the database
                        facade.LogEvent(Request.RawUrl, EventNames.LOGIN_SUCCESS, eventDetails, model.UserName, HttpContext.Session.SessionID);
                        logger.InfoFormat("Device name read from the client by the applet : {0}", model.DeviceName);
                        DMSCallContext.ClickToCallDeviceName = model.DeviceName;

                        StoreProfile(model.UserName);
                        logger.InfoFormat("Login Successful");
                        return Json(new { success = true, redirect = string.IsNullOrEmpty(returnUrl) ? GetReturnUrl(model.UserName) : returnUrl });
                    }
                    else
                    {
                        ModelState.AddModelError("", "That User name, password combination is not valid, please try again");
                    }
                }

                // If we got this far, something failed
                // Log an event to the database            
                facade.LogEvent(Request.RawUrl, EventNames.LOGIN_FAILURE, eventDetails, model.UserName, HttpContext.Session.SessionID);
                var errorList = GetErrorsFromModelState();
                logger.InfoFormat("Log on failed with {0} errors", errorList.Count());

                // Clear off DMSCallContext values (if any)
                DMSCallContext.Reset();

                return Json(new { errors = errorList });
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                return Json(new { errors = new List<string>() { ex.Message } });
            }
        }

        /// <summary>
        /// Logs the user out of the application.
        /// </summary>
        /// <returns></returns>
        public ActionResult LogOff()
        {
            Session.RemoveAll();
            FormsAuthentication.SignOut();

            return RedirectToAction("LogOn", "Account", new { area = string.Empty });
        }


        /// <summary>
        /// Register - Action method for AJAX requests
        /// </summary>
        /// <param name="model">The Registration details</param>
        /// <returns>
        /// Json - Success if the registration is successful; List of errors, otherwise
        /// </returns>
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
                    MembershipUser user = System.Web.Security.Membership.CreateUser(model.UserName, model.Password, model.Email, null, null, true, null, out createStatus);

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
                return Json(new { errors = GetErrorsFromModelState() });
            }
            catch (Exception ex)
            {
                logger.Error(ex.Message, ex);
                return Json(new { errors = new List<string>() { ex.Message } });
            }
        }

        /// <summary>
        /// Forgot Password - Action method for AJAX requests
        /// </summary>
        /// <param name="username">The username.</param>
        /// <returns>
        /// Json - Success if the password is sent to email successfully; List of errors, otherwise
        /// </returns>
        [HttpPost]
        public ActionResult JsonForgotPassword(string username)
        {
            EventLoggerFacade facade = new EventLoggerFacade();
            Dictionary<string, string> eventDetails = new Dictionary<string, string>();
            // Prepare event details
            eventDetails.Add("Username", username);

            if (ModelState.IsValid)
            {
                try
                {
                    logger.InfoFormat("Attempting to recover the password of {0}", username);
                    /**********Mail**********/
                    System.Net.Mail.MailMessage mm;
                    mm = new System.Net.Mail.MailMessage();

                    MembershipUserCollection users = System.Web.Security.Membership.FindUsersByName(username);
                    if (users.Count > 0)
                    {
                        MembershipUser user = users[username];

                        mm.Subject = "Martex DMS: Account Login Details";
                        string page = Request.Url.AbsoluteUri.Replace("JsonForgotPassword", "Logon");
                        Hashtable context = new Hashtable();
                        context.Add("url", string.Format("{0}://{1}", Request.Url.Scheme, Request.Url.Authority));
                        context.Add("password", user.ResetPassword());
                        context.Add("user", user.UserName);
                        context.Add("email", user.Email);

                        string body = GetEmailBody("ForgotPassword", user, context);

                        mm.Body = body;
                        mm.To.Add(new MailAddress(user.Email));

                        mm.IsBodyHtml = true;
                        SendEmail(mm);

                        eventDetails.Add("email", user.Email);
                        facade.LogEvent(Request.RawUrl, EventNames.FORGOT_PASSWORD, eventDetails, username, HttpContext.Session.SessionID);
                        logger.InfoFormat("Forgot password of {0} sent to {1}", username, user.Email);
                        /**********End-Mail**********/
                        return Json(new { success = true });
                    }
                    else
                    {
                        logger.InfoFormat("Given user - {0} doesn't exist in the system", username);
                        ModelState.AddModelError("", "User does not exist");
                    }
                }
                catch (Exception ex)
                {
                    logger.Error(ex.Message, ex);
                    ModelState.AddModelError("", ex.Message);
                }

            }

            return Json(new { errors = GetErrorsFromModelState() });
        }

        /// <summary>
        /// Retrieve Logged in user details
        /// </summary>
        /// <returns></returns>
        public ActionResult GetUserDetails()
        {
            RegisterUserModel model = Session["LOGGED_IN_USER"] as RegisterUserModel;

            logger.InfoFormat("AccountController - GetUserDetails(), Results:  {0}", JsonConvert.SerializeObject(new
            {
                UserDetails = model
            }));
            return View("_UserProfileDetails", model);
        }

        #endregion

        #region Utility methods

        /// <summary>
        /// Gets the email body.
        /// </summary>
        /// <param name="templateFile">The template file.</param>
        /// <param name="user">The user.</param>
        /// <param name="templateData">The template data.</param>
        /// <returns></returns>
        private string GetEmailBody(string templateFile, MembershipUser user, Hashtable templateData)
        {
            string TEMPLATE_ROOT = HostingEnvironment.MapPath("~/Templates");
            templateFile = templateFile + ".vm";

            //Initialize Velocity
            ExtendedProperties p = new ExtendedProperties();
            p.SetProperty(NVelocity.Runtime.RuntimeConstants.FILE_RESOURCE_LOADER_PATH, TEMPLATE_ROOT);
            VelocityEngine v = new VelocityEngine();
            v.Init(p);

            VelocityContext context = new VelocityContext(templateData);

            using (StringWriter writer = new StringWriter())
            {
                v.MergeTemplate(templateFile, context, writer);
                return writer.GetStringBuilder().ToString();
            }

        }

        /// <summary>
        /// Sends the email.
        /// </summary>
        /// <param name="mailMessage">The mail message.</param>
        private void SendEmail(System.Net.Mail.MailMessage mailMessage)
        {
            System.Net.Mail.MailMessage mm = mailMessage;
            mm.IsBodyHtml = true;
            SmtpClient smtp = new SmtpClient();
            smtp.Send(mm);
        }
        #endregion

        #region Status Codes
        /// <summary>
        /// Errors the code to string.
        /// </summary>
        /// <param name="createStatus">The create status.</param>
        /// <returns></returns>
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

        /// <summary>
        /// Logs the on.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <param name="returnUrl">The return URL.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult LogOn(LogOnModel model, string returnUrl)
        {

            if (ModelState.IsValid)
            {
                if (System.Web.Security.Membership.ValidateUser(model.UserName, model.Password))
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


        /// <summary>
        /// Registers this instance.
        /// </summary>
        /// <returns></returns>
        public ActionResult Register()
        {
            return View();
        }


        /// <summary>
        /// Registers the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost]
        public ActionResult Register(RegisterModel model)
        {
            if (ModelState.IsValid)
            {
                // Attempt to register the user
                MembershipCreateStatus createStatus;
                System.Web.Security.Membership.CreateUser(model.UserName, model.Password, model.Email, null, null, true, null, out createStatus);

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


        /// <summary>
        /// Changes the password.
        /// </summary>
        /// <returns></returns>
        [Authorize]
        public ActionResult ChangePassword()
        {
            return View();
        }


        /// <summary>
        /// Changes the password.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [Authorize]
        [HttpPost]
        public ActionResult ChangePassword(ChangePasswordModel model)
        {
            if (ModelState.IsValid)
            {

                // ChangePassword will throw an exception rather
                // than return false in certain failure scenarios.
                bool changePasswordSucceeded;
                try
                {
                    MembershipUser currentUser = System.Web.Security.Membership.GetUser(User.Identity.Name, true /* userIsOnline */);
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


        /// <summary>
        /// Changes the password success.
        /// </summary>
        /// <returns></returns>
        public ActionResult ChangePasswordSuccess()
        {
            return View();
        }

        [Authorize]
        public ActionResult _ChangeExpiredPassword()
        {
            return View();
        }

        internal string EncodePassword(string pass, string salt, int passwordFormat = 1)
        {
            if (passwordFormat == 0)
            {
                return pass;
            }
            byte[] bytes = Encoding.Unicode.GetBytes(pass);
            byte[] src = Convert.FromBase64String(salt);
            byte[] dst = new byte[src.Length + bytes.Length];
            byte[] inArray = null;
            Buffer.BlockCopy(src, 0, dst, 0, src.Length);
            Buffer.BlockCopy(bytes, 0, dst, src.Length, bytes.Length);
            if (passwordFormat == 1)
            {
                HashAlgorithm algorithm = HashAlgorithm.Create("SHA1");
                inArray = algorithm.ComputeHash(dst);
            }
            return Convert.ToBase64String(inArray);
        }



        [Authorize]
        [HttpPost]
        public ActionResult UpdatePassword(ChangePasswordModel model)
        {
            OperationResult result = new OperationResult();
            if (ModelState.IsValid)
            {
                UserRepository repository = new UserRepository();
                PaymentRepository payRepository = new PaymentRepository();
                Guid loggedInUserID = GetLoggedInUserId();
                List<UserPasswordHistory> userPasswordList = repository.GetUserPasswordHistory(loggedInUserID);
                bool isPasswordNew = true;
                if (userPasswordList.Count > 0)
                {
                    foreach (UserPasswordHistory userPassword in userPasswordList)
                    {
                        if (userPassword.Password == EncodePassword(model.NewPassword, userPassword.PasswordSalt, userPassword.PasswordFormat.GetValueOrDefault()))
                        {
                            isPasswordNew = false;
                        }
                    }
                }
                // ChangePassword will throw an exception rather
                // than return false in certain failure scenarios.
                if (isPasswordNew)
                {
                    bool changePasswordSucceeded;
                    try
                    {
                        MembershipUser currentUser = System.Web.Security.Membership.GetUser(User.Identity.Name, true /* userIsOnline */);
                        changePasswordSucceeded = currentUser.ChangePassword(model.OldPassword, model.NewPassword);
                    }
                    catch (Exception ex)
                    {
                        if (ex.Message == "Non alpha numeric characters in 'newPassword' needs to be greater than or equal to '1'.")
                        {
                            result.Data = "Password should contain at least one Non alpha numeric character";
                        }
                        if (ex.Message == "The length of parameter 'newPassword' needs to be greater or equal to '7'.")
                        {
                            result.Data = "New Password must be least 7 characters.";
                        }
                        if (ex.Message == "The length of parameter 'newPassword' needs to be greater or equal to '6'.")
                        {
                            result.Data = "New Password must be 6 characters.";
                        }
                        changePasswordSucceeded = false;
                    }

                    if (changePasswordSucceeded)
                    {
                        result.Status = "Success";
                        repository.AddPasswordToHistory(loggedInUserID, LoggedInUserName);
                        StoreProfile(LoggedInUserName);
                    }
                    else
                    {
                        result.Status = "Failure";
                        if (result.Data == null)
                        {
                            result.Data = "The current password is incorrect.";
                        }
                        ModelState.AddModelError("", result.Data.ToString());
                    }
                }
                else
                {
                    result.Status = "Failure";
                    result.Data = "Password must be different than the last 5 passwords you have used.";
                }
            }
            else
            {
                result.Status = "Failure";
                result.Data = "The current password is incorrect.";
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }
        #endregion

    }
}
