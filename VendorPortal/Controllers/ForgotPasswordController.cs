using System;
using System.Collections.Generic;
using System.Web;
using System.Web.Mvc;
using membershipProvider = System.Web.Security;
using System.Web.Security;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.Common;
using System.Collections;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL;
using Martex.DMS.BLL.SMTPSettings;
using Martex.DMS.DAL.Extensions;

namespace VendorPortal.Controllers
{
    public class ForgotPasswordController : BaseController
    {
        UsersFacade userFacade = new UsersFacade();
        VendorPortalFacade facade = new VendorPortalFacade();

        public ActionResult Index()
        {
            return View();
        }

        [HttpPost, ValidateInput(false)]
        public ActionResult JsonForgotPassword(string username)
        {
            EventLoggerFacade eventLogFacade = new EventLoggerFacade();
            PaymentRepository paymentRepository = new PaymentRepository();
            var loggedInUserId = Guid.Empty;
            MembershipUserCollection memberShipUsers = System.Web.Security.Membership.FindUsersByName(username);
            if (memberShipUsers.Count > 0)
            {
                loggedInUserId = (Guid)memberShipUsers[username].ProviderUserKey;

                aspnet_Users aspnetUser = userFacade.Get(loggedInUserId);
                MembershipUser userDetails = System.Web.Security.Membership.GetUser(username);

                VendorUser vu = new VendorUser();

                
                Dictionary<string, string> eventDetails = new Dictionary<string, string>();
                // Prepare event details
                eventDetails.Add("Username", username);

                if (ModelState.IsValid && userDetails.IsApproved)
                {
                    try
                    {
                        logger.InfoFormat("Attempting to recover the password of {0}", username);
                        /**********Mail**********/
                        EmailService emailService = new EmailService();
                        MembershipUserCollection users = membershipProvider.Membership.FindUsersByName(username);
                        if (users.Count > 0)
                        {
                            MembershipUser user = users[username];
                            string page = Request.Url.AbsoluteUri.Replace("JsonForgotPassword", "Logon");
                            string randomString = user.ResetPassword();
                            logger.InfoFormat("Password reseted successfully for user {1}. Password Reset Token : {0}", randomString, username);
                            vu = facade.UpdateChangePasswordVendorUser(aspnetUser.UserId,randomString, true,LoggedInUserName);

                            string resetPassowrdString = vu.ID.ToString() + "&" + randomString;
                            string encryptedResetPassowrdString = paymentRepository.EncryptDecrypt(resetPassowrdString, true);
                            logger.InfoFormat("Link encrypted successfully. Encrypted Password Reset Token : {0}", encryptedResetPassowrdString);
                            Hashtable context = new Hashtable();

                            context.Add("url", string.Format("{0}://{1}", Request.Url.Scheme, Request.Url.Authority));
                            context.Add("passwordResetToken", Url.Encode(encryptedResetPassowrdString));
                            context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER));

                            VendorManagementFacade vendorFacade = new VendorManagementFacade();
                            var vendorUser = vendorFacade.GetVendorUser(aspnetUser.UserId);

                            var vendor = vendorFacade.Get(vendorUser.VendorID.Value);
                            var vendorRegion = vendor.VendorRegion;

                            string fromDisplayName = AppConfigConstants.GLOBAL_FROM_DISPLAY_NAME_COACH_VENDOR;
                            string fromAddress = AppConfigRepository.GetValue(AppConfigConstants.NO_REPLY_FROM_EMAIL_ADDRESS);
                            string toDisplayName = vendorUser.FirstName + " " + vendorUser.LastName;

                            emailService.SendEmail(context, user.Email, TemplateNames.VENDOR_PORTAL_FORGOT_PASSWORD, fromAddress, fromDisplayName, toDisplayName);
                            eventDetails.Add("email", user.Email);
                            eventLogFacade.LogEvent(Request.RawUrl, EventNames.FORGOT_PASSWORD, eventDetails, username, HttpContext.Session.SessionID);
                            logger.InfoFormat("Reset Password Email link for the user {0} sent to the email : {1}", username, user.Email);
                            /**********End-Mail**********/
                            return Json(new { success = true }, JsonRequestBehavior.AllowGet);
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
                else
                {
                    ModelState.AddModelError("", "User does not exist");
                }
            }
            else
            {
                ModelState.AddModelError("", "User does not exist");
            }

            return Json(new { errors = GetErrorsFromModelState() }, JsonRequestBehavior.AllowGet);
        }
    }
}
