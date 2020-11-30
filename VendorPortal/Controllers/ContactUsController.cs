using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using VendorPortal.Models;
using VendorPortal.ActionFilters;
using log4net;
using Martex.DMS.BLL.SMTPSettings;
using System.Net.Mail;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;


namespace VendorPortal.Controllers
{
    public class ContactUsController : Controller
    {
        #region Protected Members
        protected static readonly ILog logger = LogManager.GetLogger(typeof(BaseController));
        #endregion

        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.VendorPortalContactUsSubject, false)]
        public ActionResult Index()
        {
            ContactUsModel model = new ContactUsModel();
            return View(model);
        }


        [HttpPost, ValidateInput(false)]
        public ActionResult SendContactUs(ContactUsModel model)
        {
            OperationResult result = new OperationResult();
            try
            {
                logger.Info("Executing Save for Contact us from Vendor Portal");
                
                #region Setting Other Properties
                model.Browser = Request.Browser.Browser;
                model.ClientIP = Request.UserHostAddress;
                #endregion

                #region Retrieve To Address
                string toAddress = AppConfigRepository.GetValue("ContactUsEmail");
                if (string.IsNullOrEmpty(toAddress))
                {
                    throw new DMSException(string.Format("Unable to retrieve Application Configuration for {0}", "ContactUsEmail"));
                }
                #endregion

                #region Sending Email
                EmailService email = new EmailService();
                MailMessage message = new MailMessage()
                {
                    IsBodyHtml = true,
                    Body = model.GetEmailBody(),
                    Subject = "Vendor Website Contact Us"
                };
                message.To.Add(new MailAddress(toAddress));
                email.SendEmail(message);
                #endregion
                
                result.Status = OperationStatus.SUCCESS;
               
                logger.Info("Execution finished successfully");
            }
            catch (Exception ex)
            {
                result.Status = OperationStatus.ERROR;
                result.ErrorMessage = "An error had occured while processing your request.";
                logger.Error(ex);
            }
            return Json(result, JsonRequestBehavior.AllowGet);
        }

        [HttpPost]
        public ActionResult _Success()
        {
            return PartialView();
        }
        [HttpPost]
        public ActionResult _Failure()
        {
            return PartialView();
        }

    }
}
