using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Martex.DMS.BLL.Model;
using Microsoft.Reporting.WebForms;
using System.Web.Hosting;
using Martex.DMS.BLL.SMTPSettings;
using System.Net.Mail;
using System.IO;
using Martex.DMS.Models;
using Martex.DMS.BLL.Facade;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Martex.DMS.DAL.Common;
using log4net;
using Martex.DMS.BLL.Common;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL;

namespace Martex.DMS.Areas.VendorManagement.Controllers
{
    public partial class VendorHomeController
    {
        //protected static readonly ILog logger = LogManager.GetLogger(typeof(VendorHomeController));

        [HttpPost]
        public ActionResult _PreviewRatesInfo(int? vendorID, int? rateScheduleID, string source)
        {
            logger.InfoFormat("Presenting the options dialog for Vendor {0} and RateSchedule {1}", vendorID, rateScheduleID);
            VendorManagementFacade vendorFacade = new VendorManagementFacade();
            var vendor = vendorFacade.Get(vendorID.Value);
            ViewData["Email"] = vendor.Email;
            ViewData["VendorID"] = vendorID;
            ViewData["RateScheduleID"] = rateScheduleID;
            ViewData["Source"] = source;

            return PartialView();
        }


        [HttpPost]
        public ActionResult GetRatesForPreview(VendorRatesAgreementModel ratesAgreement)
        {
            logger.InfoFormat("Generating preview for {0}", ratesAgreement.ToString());
            
            VendorManagementFacade vendorFacade = new VendorManagementFacade();
            var vendor = vendorFacade.Get(ratesAgreement.VendorID);

            if (vendor.VendorApplications != null && vendor.VendorApplications.Count > 0)
            {
                var vendorApplication = vendor.VendorApplications.FirstOrDefault();
                ratesAgreement.ApplicationDate = vendorApplication.CreateDate;
            }
            
            string fileName = "rates".Equals(ratesAgreement.Source, StringComparison.InvariantCultureIgnoreCase) ? "RateSchedule" : "WelcomeLetter";
            fileName = string.Format("{0}_{1}_{2}.pdf", vendor.VendorNumber,fileName, DateTime.Now.ToString("yyyyMMdd_HHmm"));

            byte[] bytes = GetRatesAgreementPDF(ratesAgreement);

            return File(bytes, "application/pdf", fileName);
        }

        [HttpPost]
        public ActionResult SendRatesAsEmail(VendorRatesAgreementModel ratesAgreement)
        {
            OperationResult result = new OperationResult();

            logger.InfoFormat("Sending email for {0}", ratesAgreement.ToString());
            EmailService emailService = new EmailService();
            VendorManagementFacade vendorFacade = new VendorManagementFacade();
            var vendor = vendorFacade.Get(ratesAgreement.VendorID);
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
            if (vendor.VendorApplications != null && vendor.VendorApplications.Count > 0)
            {
                var vendorApplication = vendor.VendorApplications.FirstOrDefault();
                ratesAgreement.ApplicationDate = vendorApplication.CreateDate;
            }

            // Set the flag for email.
            ratesAgreement.SendEmail = true;

            byte[] bytes = GetRatesAgreementPDF(ratesAgreement);

            bool forRates = ("rates".Equals(ratesAgreement.Source, StringComparison.InvariantCultureIgnoreCase));


            Attachment a = new Attachment(new MemoryStream(bytes), string.Format("{0}_{1}_{2}.pdf", vendor.VendorNumber, forRates ? "RateSchedule" : "WelcomeLetter", DateTime.Now.ToString("yyyyMMdd_HHmm")));
            List<Attachment> attachments = new List<Attachment>();
            if (forRates)
            {
                attachments.Add(a);
            }
            
            var vendorRegion = vendor.VendorRegion;
            Hashtable context = new Hashtable();
            context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER).GetFormattedPhoneNumber() ?? string.Empty);
            context.Add("fax", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_FAX_NUMBER) ?? string.Empty);
            context.Add("UserFirst", vendorFirstName ?? string.Empty);
            context.Add("UserLast", vendorLastName ?? string.Empty);
            context.Add("user", vendor.VendorNumber);
            context.Add("url", string.Format("{0}://{1}", Request.Url.Scheme,"pinnacleproviders.com"));//NP 3/19/2015: Commented(TFS #582) Request.Url.Authority));

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
                logger.Warn("Vendor region not available");
                context.Add("ContactFirstName", string.Empty);
                context.Add("ContactLastName", string.Empty);
                context.Add("Email", string.Empty);
                context.Add("PhoneNumber", string.Empty);
                context.Add("RegionName", string.Empty);
            }
            string fromEmail = vendorRegion != null ? vendorRegion.Email : string.Empty;
            string fromDisplayName = vendorRegion != null ? string.Join(" ", vendorRegion.ContactFirstName, vendorRegion.ContactLastName) : string.Empty;
            emailService.SendEmail(context,ratesAgreement.Email, forRates ? TemplateNames.VENDOR_SEND_RATE_SCHEDULE : TemplateNames.VENDOR_WELCOME, fromEmail, fromDisplayName, string.Empty, attachments);


            var contactLogFacade = new ContactLogFacade();
            contactLogFacade.Log(ContactCategoryNames.CONTACT_VENDOR,
                "Vendor",
                ContactMethodNames.EMAIL,
                "Outbound",
                forRates ? "Send Rate Schedule" : "Send Welcome Letter",
                ContactReasonName.NEW_VENDOR,
                forRates ? ContactActionName.SEND_RATE_SCHEDULE : ContactActionName.SEND_WELCOME_LETTER,
                vendor != null ? vendor.Name : "No Vendor Present",
                ratesAgreement.Email,
                LoggedInUserName,
                vendor != null ? vendor.ID : (int?)null,
                EntityNames.VENDOR);
            logger.Info("Contact Logs created successfully");

            return Json(result, JsonRequestBehavior.AllowGet);
        }

        private byte[] GetRatesAgreementPDF(VendorRatesAgreementModel ratesAgreement)
        {
            // Run the report and extract the PDF.
            ReportViewer reportViewer = new ReportViewer();
            var localReport = reportViewer.LocalReport;
            string purposeForPreview = "Print".Equals(ratesAgreement.PurposeForPreview, StringComparison.InvariantCultureIgnoreCase) ? "1" : "0";
            if ("rates".Equals(ratesAgreement.Source, StringComparison.InvariantCultureIgnoreCase))
            {
                localReport.ReportPath = HostingEnvironment.MapPath("~/Reports/RptContractRateSchedule.rdlc");
                var vendorDetails = facade.GetVendorDetailsForReport(ratesAgreement.VendorID);
                var rates = facade.GetRateSchedulesForReport(ratesAgreement.RateScheduleID);


                localReport.DataSources.Add(new Microsoft.Reporting.WebForms.ReportDataSource("dsVendor", vendorDetails));
                localReport.DataSources.Add(new Microsoft.Reporting.WebForms.ReportDataSource("dsRateSchedule", rates));

                string includeCover = ratesAgreement.SendEmail ? "0" : "1";
               


                //Fact: There is no need to pass VendorID and RateScheduleID as the dataasets are provided to the report in the above statements.
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("PageVisibility", includeCover));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmAdditionalText", ratesAgreement.AdditionalText ?? string.Empty));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmToEmailAddress", ratesAgreement.Email));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmPurpose", purposeForPreview));
                string applicationDate = DateTime.Now.ToShortDateString();
                if (ratesAgreement.ApplicationDate != null)
                {
                    applicationDate = ratesAgreement.ApplicationDate.Value.ToShortDateString();
                }
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmApplicationDate", applicationDate));
            }
            else
            {
                localReport.ReportPath = HostingEnvironment.MapPath("~/Reports/RptWelcomeNotice.rdlc");
                var vendorDetails = facade.GetVendorDetailsForReport(ratesAgreement.VendorID);
                
                localReport.DataSources.Add(new Microsoft.Reporting.WebForms.ReportDataSource("dsVendor", vendorDetails));

                //Fact: There is no need to pass VendorID and RateScheduleID as the dataasets are provided to the report in the above statements.
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmAdditionalText", ratesAgreement.AdditionalText ?? string.Empty));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmToEmailAddress", ratesAgreement.Email));
                localReport.SetParameters(new Microsoft.Reporting.WebForms.ReportParameter("prmPurpose", purposeForPreview));
                
            }


            reportViewer.ProcessingMode = ProcessingMode.Local;
            byte[] bytes = reportViewer.LocalReport.Render("PDF");
            return bytes;
        }

        [HttpPost]
        public ActionResult PrintLetter(VendorRatesAgreementModel ratesAgreement)
        {
            VendorManagementFacade vendorFacade = new VendorManagementFacade();
            var vendor = vendorFacade.Get(ratesAgreement.VendorID);
            var contactLogFacade = new ContactLogFacade();
            if ("rates".Equals(ratesAgreement.Source, StringComparison.InvariantCultureIgnoreCase))
            {
                contactLogFacade.Log(ContactCategoryNames.CONTACT_VENDOR,
                    "Vendor",
                    ContactMethodNames.MAIL,
                    "Outbound",
                    "Send Rate Schedule",
                    ContactReasonName.NEW_VENDOR,
                    ContactActionName.SEND_RATE_SCHEDULE,
                    vendor != null ? vendor.Name : "No Vendor Present",
                    ratesAgreement.Email,
                    LoggedInUserName,
                    ratesAgreement.VendorID,
                    EntityNames.VENDOR);
            }
            else
            {
                contactLogFacade.Log(ContactCategoryNames.CONTACT_VENDOR,
                    "Vendor",
                    ContactMethodNames.MAIL,
                    "Outbound",
                    "Send Welcome Letter",
                    ContactReasonName.NEW_VENDOR,
                    ContactActionName.SEND_WELCOME_LETTER,
                    vendor != null ? vendor.Name : "No Vendor Present",
                    ratesAgreement.Email,
                    LoggedInUserName,
                    ratesAgreement.VendorID,
                    EntityNames.VENDOR);
            }
            logger.Info("Contact Logs created successfully");

            OperationResult result = new OperationResult();
            return Json(result, JsonRequestBehavior.AllowGet);
        }
    }
}
