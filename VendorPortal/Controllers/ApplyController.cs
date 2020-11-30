using System.Web.Mvc;
using System.Linq;
using VendorPortal.ActionFilters;
using Martex.DMS.DAO;
using Martex.DMS.DAL.Common;
using VendorPortal.Common;
using VendorPortal.BLL.Models;
using Martex.DMS.BLL.Facade;
using System.Net.Mail;
using VendorPortal.Controllers;
using VendorPortal.Models;
using Martex.DMS.BLL.SMTPSettings;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Newtonsoft.Json;
using System.Web;

namespace VendorPortal.Controllers
{
    public class ApplyController : BaseController
    {
        //
        // GET: /ISP/VendorApplication/
        /// <summary>
        /// Landing page for Vendor Application.
        /// </summary>
        /// <returns></returns>
        [AllowAnonymous]
        [ReferenceDataFilter(StaticData.CountryCode, false)]
        [ReferenceDataFilter(StaticData.ReferralSource, false)]
        [ReferenceDataFilter(StaticData.Country, false)]
        [ReferenceDataFilter(StaticData.Province, true)]
        [ReferenceDataFilter(StaticData.DispatchSoftwareProduct, true)]
        [ReferenceDataFilter(StaticData.DispatchGPSNetwork, true)]
        [NoCache]
        public ActionResult Index()
        {
            LogBrowserInformation();
            ViewData[StaticData.PhoneType.ToString()] = ReferenceDataRepository.GetPhoneTypes(EntityNames.VENDOR).ToSelectListItem(x => x.ID.ToString(), y => y.Name, true);
            VendorApplicationFacade facade = new VendorApplicationFacade();
            ViewData["VendorServices"] = facade.GetServices();
            return View();
        }

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        /// <returns></returns>
        [HttpPost, ValidateInput(false)]
        [AllowAnonymous]
        [NoCache]
        public ActionResult Save(VendorApplicationModel model)
        {
            VendorApplicationFacade facade = new VendorApplicationFacade();
            logger.Info("Saving Application");
            var modelForLogging = new VendorApplicationModel();
            modelForLogging = model;
            HttpPostedFileBase newCertificateOfInsurance = null;
            if (model.CertificateOfInsurance != null)
            {
                newCertificateOfInsurance = model.CertificateOfInsurance;
                modelForLogging.CertificateOfInsurance = null;
            }
            logger.InfoFormat("Saving Vendor Application Parameters :  {0}", JsonConvert.SerializeObject(new
            {
                VendorApplicationModel = modelForLogging
            }));
            if (newCertificateOfInsurance != null)
            {
                model.CertificateOfInsurance = newCertificateOfInsurance;
            }

            VendorApplication va = facade.Save(model, Request.RawUrl, Session.SessionID);
            // TFS : 1497	Vendor Application - Send Confirmation Email
            logger.Info("Sending confirmation email");
            string toDisplayName = model.ContactFirstName + " " + model.ContactLastName;
            string fromAddress = AppConfigRepository.GetValue(AppConfigConstants.NO_REPLY_FROM_EMAIL_ADDRESS);

            EmailService email = new EmailService();
            Hashtable context = new Hashtable();
            VendorManagementFacade vendorFacade = new VendorManagementFacade();
            var vendor = vendorFacade.Get(va.VendorID.Value);
            var vendorRegion = vendor.VendorRegion;
            VendorUser vendorUser = null;
            if (vendor.VendorUsers != null && vendor.VendorUsers.Count > 0)
            {
                vendorUser = vendor.VendorUsers.FirstOrDefault();
            }

            string vendorFirstName = vendor.ContactFirstName;
            string vendorLastName = vendor.ContactLastName;

            if (string.IsNullOrEmpty(vendorFirstName))
            {
                if (vendorUser != null)
                {
                    vendorFirstName = vendorUser.FirstName;
                }
            }

            if (string.IsNullOrEmpty(vendorLastName))
            {
                if (vendorUser != null)
                {
                    vendorLastName = vendorUser.LastName;
                }
            }
            context.Add("UserFirst", vendorFirstName ?? string.Empty);
            context.Add("UserLast", vendorLastName ?? string.Empty);
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

            email.SendEmail(context, model.Email, TemplateNames.VENDOR_PORTAL_APPLICATION_CONFIRMATION, fromAddress, fromDisplayName, toDisplayName);

            OperationResult result = new OperationResult() { Status = OperationStatus.SUCCESS };
            return Json(result, "text/plain", JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        [AllowAnonymous]
        public ActionResult SaveConfirmation()
        {
            return View("Save");
        }

    }
}
