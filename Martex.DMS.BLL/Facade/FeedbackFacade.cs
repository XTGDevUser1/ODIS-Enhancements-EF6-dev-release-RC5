using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

using System.Configuration;
using System.Net.Configuration;
using System.Net.Mail;
using Martex.DMS.DAO;
using System.Net.Mime;
using System.Web;
using System.IO;
using System.Collections.Specialized;
using log4net;

using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.Common;
using Martex.DMS.BLL.SMTPSettings;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using System.Collections;
using Martex.DMS.DAL.Extensions;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Facade Manages Feedback
    /// </summary>
    public class FeedbackFacade
    {
        #region Private Methods

        /// <summary>
        /// The FEEDBACk_ MAIL_ SUBJECT
        /// </summary>
        private const string FEEDBACK_MAIL_SUBJECT = "FEEDBACK_MAIL_SUBJECT";

        #endregion

        #region Protected Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static readonly ILog logger = LogManager.GetLogger(typeof(FeedbackFacade));

        #endregion

        #region Public Methods

        /// <summary>
        /// Saves the specified feed back.
        /// </summary>
        /// <param name="feedBack">The feed back.</param>
        /// <param name="stream">The stream (uploaded file).</param>
        /// <param name="fileName">Name of the uploaded file.</param>
        /// <exception cref="DMSException">Missing To address in FeedbackType</exception>
        public int Save(Feedback feedBack, System.IO.Stream stream, string fileName, string screenshot)
        {
            if (logger.IsInfoEnabled)
            {
                logger.InfoFormat("Attempting to save feedback from user {0}", feedBack.Name);
            }

            FeedbackRepository feedbackReposotory = new FeedbackRepository();
            feedBack.CreateBy = feedBack.Name;
            feedBack.CreateDate = DateTime.Now;
            feedbackReposotory.Add(feedBack);
            // Sending email           
            string toEmail = string.Empty;
            string subject = string.Empty;
            string bodySubject = string.Empty;
            string priority = string.Empty;
            NameValueCollection appSettings = ConfigurationManager.AppSettings;
            //if (appSettings[FEEDBACK_MAIL_SUBJECT] != null)
            //{
            subject = AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_FEEDBACK_MAIL_SUBJECT);

            //}
            // Get FeedbackType from the database of the particular FeedbackTypeId
            FeedbackType feedbackType = ReferenceDataRepository.GetFeedbackType(feedBack.FeedbackTypeID);
            if (feedbackType != null)
            {
                // mail will send to the email-id depending upon the FeedbackType.
                toEmail = feedbackType.NotificationEmail;
                bodySubject = feedbackType.Name;
                subject += " - " + feedbackType.Description;
            }
            // If tomail address (from FeedbackType) is there then only it will send the mail
            if (!string.IsNullOrEmpty(toEmail))
            {
                MailMessage message = new MailMessage();
                //message.From = new MailAddress(fromEmail, name);
                message.Subject = subject;
                // CR : 1236
                // SD : Try to split the toEmail using ; and , and add the tokens to the To list.
                string[] toEmails = toEmail.Split(';', ',');
                foreach (string token in toEmails)
                {
                    message.To.Add(token);
                }
                message.IsBodyHtml = true;
                message.Body = string.Format("<html><body><br/>User: {0}<br/>Phone: {1}<br/>Email: {2}<br/>Subject: {3}<br/>Priority: {4}<br/>Comments: {5}</body></html>", feedBack.Name, feedBack.PhoneNumber, feedBack.Email, bodySubject, feedBack.Priority, feedBack.Comments);
                if (stream != null && stream.Length > 0 && !string.IsNullOrEmpty(fileName))
                {
                    // If any attachment file is there then this block of statement will be executed.
                    FileInfo fileInfo = new FileInfo(fileName);
                    Attachment attached = new Attachment(stream, MediaTypeNames.Application.Octet);
                    attached.Name = fileInfo.Name;
                    message.Attachments.Add(attached);

                }
                if (!String.IsNullOrEmpty(screenshot))
                {
                    FileInfo fileScreenShotInfo = new FileInfo(screenshot);
                    if (fileScreenShotInfo.Exists)
                    {
                        message.Attachments.Add(new Attachment(screenshot));
                    }
                }
                SmtpClient smtpclient = new SmtpClient();
                smtpclient.Send(message);
            }
            else
            {
                logger.Warn("Could not send an email due to missing 'to' address ");
                throw new DMSException("Missing To address in FeedbackType");
            }
            return feedBack.ID;
        }


        /// <summary>
        /// Saves the vendor portal feedback.
        /// </summary>
        /// <param name="feedBack">The feed back.</param>
        /// <param name="sessionID">The session ID.</param>
        /// <param name="Source">The source.</param>
        public void SaveVendorPortalFeedback(Feedback feedBack, string sessionID, string Source, System.IO.Stream stream, string fileName, string currentUser, string sourceSystemName = null)
        {
            FileInfo fileInfo = null;
            if (logger.IsInfoEnabled)
            {
                logger.InfoFormat("Attempting to save feedback from user {0}", feedBack.Name);
            }
            #region Saving Feedback
            FeedbackRepository feedbackRepository = new FeedbackRepository();
            var lookupRepository = new CommonLookUpRepository();
            string priority = string.Empty;

            int priorityId = int.Parse(feedBack.Priority);
            ServiceRequestPriority priorityObj = ReferenceDataRepository.GetPriorities().Where(x => x.ID == priorityId).SingleOrDefault<ServiceRequestPriority>();
            if (priorityObj != null)
            {
                feedBack.Priority = priorityObj.Name;
                priority = priorityObj.Name;
            }
            ContactMethod contactMethodObj = null;
            if (feedBack.PreferedContactMethodID.HasValue)
            {
                contactMethodObj = ReferenceDataRepository.GetContactMethods().Where(x => x.ID == feedBack.PreferedContactMethodID.Value).SingleOrDefault<ContactMethod>();
            }
            string contactMethodType = string.Empty;
            if (contactMethodObj != null)
            {
                contactMethodType = contactMethodObj.Name;
            }

            if (sourceSystemName != null)
            {
                SourceSystem sourceSystem = lookupRepository.GetSourceSystem(sourceSystemName);
                if (sourceSystem != null)
                {
                    feedBack.SourceSystemID = sourceSystem.ID;
                }
                else
                {
                    throw new DMSException("Source System - " + sourceSystemName + "not configured in system. ");
                }
            }

            feedBack.CreateBy = currentUser;
            feedBack.CreateDate = DateTime.Now;
            feedbackRepository.Add(feedBack);
            #endregion

            #region Create EventLog and Link records
            EventLoggerFacade eventLoggerFacade = new EventLoggerFacade();
            long eventID = eventLoggerFacade.LogEvent("Vendor", EventNames.VENDOR_PORTAL_SUBMIT_FEEDBACK, feedBack.Comments, feedBack.Name, sessionID);
            eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, feedBack.VendorID, EntityNames.VENDOR);
            eventLoggerFacade.CreateRelatedLogLinkRecord(eventID, feedBack.ID, EntityNames.FEEDBACK);
            #endregion

            #region Create contactLog and link records
            VendorRepository vendorRepository = new VendorRepository();
            var vendor = vendorRepository.GetByID(feedBack.VendorID.GetValueOrDefault());

            if (vendor == null)
            {
                logger.WarnFormat("No vendor found for the id {0}", feedBack.VendorID);
                throw new DMSException("Vendor not found for the given ID");
            }
            var contactLogRepository = new ContactLogRepository();
            ContactLog contactLog = new ContactLog()
            {
                ContactSourceID = null,
                TalkedTo = null,
                Company = vendor.Name,
                PhoneTypeID = null,
                PhoneNumber = null,
                Email = feedBack.Email,
                Direction = "Inbound",
                Comments = feedBack.Comments,
                Description = "Vendor Portal Feedback",
                CreateBy = currentUser,
                CreateDate = DateTime.Now
            };

            ContactStaticDataRepository staticDataRepo = new ContactStaticDataRepository();
            ContactType systemType = staticDataRepo.GetTypeByName("Vendor");
            if (systemType == null)
            {
                throw new DMSException("Contact Type - 'Vendor' is not set up in the system");
            }

            contactLog.ContactTypeID = systemType.ID;
            ContactMethod contactMethod = staticDataRepo.GetMethodByName("Web");
            if (contactMethod == null)
            {
                throw new DMSException("Contact Method - 'Web' is not set up in the system");
            }
            contactLog.ContactMethodID = contactMethod.ID;

            ContactCategory contactCategory = staticDataRepo.GetContactCategoryByName("VendorPortal");
            if (contactCategory == null)
            {
                throw new DMSException("Contact Category - 'VendorPortal' is not set up in the system");
            }

            contactLog.ContactCategoryID = contactCategory.ID;

            logger.Info("Saving contact logs");

            contactLogRepository.Save(contactLog, currentUser);
            contactLogRepository.CreateLinkRecord(contactLog.ID, EntityNames.FEEDBACK, feedBack.ID);
            contactLogRepository.CreateLinkRecord(contactLog.ID, EntityNames.VENDOR, feedBack.VendorID);

            #endregion

            #region Sending Email
            EmailService ms = new EmailService();

            string toEmail = string.Empty;
            string subject = string.Empty;

            NameValueCollection appSettings = ConfigurationManager.AppSettings;
            
            FeedbackType feedbackType = ReferenceDataRepository.GetFeedbackType(feedBack.FeedbackTypeID);
            VendorRegion vendorRegion = new ReferenceDataRepository().GetVendorRegion(vendor.VendorRegionID.GetValueOrDefault());
            subject = "Your Coach-Net Feedback" + feedbackType != null ? " - "+feedbackType.Description : string.Empty;
            if (vendorRegion != null)
            {
                toEmail = vendorRegion.Email;
            }
            else
            {
                toEmail = AppConfigRepository.GetValue(AppConfigConstants.APPLICAITON_CONFIGURAITON_VENDOR_FEEDBACK_DEFAULT_EMAIL);
            }

            logger.InfoFormat("Send email from {0} to {1}", feedBack.Name, toEmail);

            if (!string.IsNullOrEmpty(toEmail))
            {
                MailMessage message = new MailMessage();

                message.Subject = subject;

                string[] toEmails = toEmail.Split(';', ',');
                foreach (string token in toEmails)
                {
                    message.To.Add(token);
                }
                message.IsBodyHtml = true;
                message.Body = string.Format("<html><body><br/>User: {0}<br/>Phone: {1}<br/>Email: {2}<br/>Contact preference: {3}<br/>Subject: {4}<br/>Priority: {5}<br/>Comments: {6}</body></html>", feedBack.Name, feedBack.PhoneNumber, feedBack.Email, contactMethodType, feedbackType.Name, priority, feedBack.Comments);

                if (stream != null && stream.Length > 0 && !string.IsNullOrEmpty(fileName))
                {
                    // If any attachment file is there then this block of statement will be executed.
                    fileInfo = new FileInfo(fileName);
                    Attachment attached = new Attachment(stream, MediaTypeNames.Application.Octet);
                    attached.Name = fileInfo.Name;
                    message.Attachments.Add(attached);

                    //Document record creation
                    logger.InfoFormat("Adding document for entity {0} and recordID {1}", EntityNames.FEEDBACK, feedBack.ID);
                    DocumentRepository documentRepository = new DocumentRepository();
                    Document document = new Document();
                    document.Name = fileInfo.Name;
                    document.RecordID = feedBack.ID;
                    document.CreateBy = currentUser;
                    document.CreateDate = DateTime.Now;

                    string documentCategoryName = "Feedback";

                    DocumentCategory category = ReferenceDataRepository.GetDocumentCategoryByName(documentCategoryName);
                    if (category == null)
                    {
                        throw new DMSException("Document Category with name - " + documentCategoryName + "not configured in system. ");
                    }
                    document.DocumentCategoryID = category.ID;

                    BinaryReader b = new BinaryReader(stream);
                    byte[] binData = b.ReadBytes(Convert.ToInt32(stream.Length));
                    document.DocumentFile = binData;

                    //Create document
                    int id = documentRepository.Add(document, EntityNames.FEEDBACK);
                    eventLoggerFacade = new EventLoggerFacade();
                    long eventLogID = eventLoggerFacade.LogEvent(Source, EventNames.EVENT_ADD_DOCUMENT, string.Empty, currentUser, sessionID);

                    eventLoggerFacade.CreateRelatedLogLinkRecord(eventLogID, feedBack.ID, EntityNames.FEEDBACK);
                    logger.Info("Document and its related Event logs and links created successfully");

                }

                ms.SendEmail(message);
                
                /* TFS : 949
                logger.InfoFormat("Sending reply to {0}", feedBack.Email);
                string fromDisplayName = AppConfigConstants.GLOBAL_FROM_DISPLAY_NAME_COACH_VENDOR;
                string fromAddress = AppConfigRepository.GetValue(AppConfigConstants.NO_REPLY_FROM_EMAIL_ADDRESS);
                string toDisplayName = feedBack.Name;
                Hashtable context = new Hashtable();
                context.Add("Office", AppConfigRepository.GetValue(AppConfigConstants.APPCONFIG_VENDOR_SERVICE_PHONE_NUMBER).GetFormattedPhoneNumber() ?? string.Empty);
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

                ms.SendEmail(context, feedBack.Email, TemplateNames.VENDOR_PORTAL_FEEDBACK_CONFIRMATION, fromAddress, fromDisplayName, toDisplayName);
                */
            }
            else
            {
                logger.Warn("Could not send an email due to missing 'to' address ");
                throw new DMSException("Missing To address in FeedbackType");
            }

            #endregion

        }
        #endregion
    }
}
