using log4net;
using Martex.DMS.BLL.Common;
using Martex.DMS.BLL.Communication;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAO;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Threading.Tasks;
using Twilio;
using Twilio.Rest.Fax.V1;
using SelectPdf;


namespace Martex.DMS.BLL.Communication
{
    public class TwilioFaxNotifier : INotifier
    {
        /// <summary>
        /// Logons the user.
        /// </summary>
        /// <param name="lpszUsername">The LPSZ username.</param>
        /// <param name="lpszDomain">The LPSZ domain.</param>
        /// <param name="lpszPassword">The LPSZ password.</param>
        /// <param name="dwLogonType">Type of the dw logon.</param>
        /// <param name="dwLogonProvider">The dw logon provider.</param>
        /// <param name="phToken">The ph token.</param>
        /// <returns></returns>
        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

        /// <summary>
        /// Closes the handle.
        /// </summary>
        /// <param name="token">The token.</param>
        /// <returns></returns>
        [DllImport("kernel32.dll")]
        public static extern bool CloseHandle(IntPtr token);

        enum LogonType
        {
            Interactive = 2,
            Network = 3,
            Batch = 4,
            Service = 5,
            Unlock = 7,
            NetworkClearText = 8,
            NewCredentials = 9
        }
        #region Protected Methods
        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(TwilioFaxNotifier));
        #endregion

        /// <summary>
        /// Notifies the specified communication queue.
        /// </summary>
        /// <param name="communicationQueue">The communication queue.</param>
        /// <exception cref="DMSException">
        /// Unable to retrieve the template details
        /// or
        /// Unable to retrieve the application configuration details
        /// </exception>
        /// <exception cref="System.Exception">An error had occured while creating the file</exception>
        public void Notify(CommunicationQueue communicationQueue)
        {
            AppConfigRepository appConfigRepository = new AppConfigRepository();

            var faxConfigList = appConfigRepository.GetApplicationConfigurationList(AppConfigConstants.APPLICATION_CONFIGURATION_TYPE_COM_QUEUE, AppConfigConstants.APPLICATION_CONFIGURATION_CAT_FAX_SERVICE);

            string faxFilePDFPath = AppConfigRepository.GetValue(AppConfigConstants.FAX_FILE_PDF_PATH);

            logger.InfoFormat(" Fax PDF Path : {0}", faxFilePDFPath);

            string domainAndUsername = AppConfigRepository.GetValue(AppConfigConstants.FAX_SERVER_USERNAME);
            string faxServerPassword = AppConfigRepository.GetValue(AppConfigConstants.FAX_SERVER_PASSWORD);

            var domainUserTokens = domainAndUsername.Split('\\');
            string domain = string.Empty;
            string faxServerUsername = domainAndUsername;
            if (domainUserTokens.Length > 1)
            {
                domain = domainUserTokens[0];
                faxServerUsername = domainUserTokens[1];
            }

            logger.InfoFormat(" Fax server username : {0}", faxServerUsername);

            IntPtr token = IntPtr.Zero;
            LogonUser(faxServerUsername,
                        domain,
                        faxServerPassword,
                        (int)LogonType.NewCredentials,
                        0,
                        ref token);

            try
            {
                string fileName = "Fax_" + communicationQueue.CommunicationLogID.ToString() + ".pdf";
                using (WindowsImpersonationContext context = WindowsIdentity.Impersonate(token))
                {
                    FileInfo faxPDFFile = new FileInfo(Path.Combine(faxFilePDFPath, fileName));
                    SaveMessageAsPDF(faxPDFFile.FullName, communicationQueue.MessageText);
                }

                // Call Fax API
                var faxIdentifier = SendFax(communicationQueue, faxConfigList, fileName);

                // Log the sid, logID, pending to the FaxResults table
                TwilioFaxResultRepository twilioFaxResultRepository = new TwilioFaxResultRepository();
                twilioFaxResultRepository.LogSentFaxStatus(faxIdentifier, communicationQueue.CommunicationLogID, "pending");

            }
            catch (System.Exception ex)
            {
                logger.Warn(ex.Message, ex);
                throw new Exception("An error had occured while creating the file", ex);
            }
        }

        private void SaveMessageAsPDF(string pathToPDF, string content)
        {
            string fileContent = content;

            // instantiate a html to pdf converter object
            HtmlToPdf converter = new HtmlToPdf();

            // create a new pdf document converting an url
            PdfDocument doc = converter.ConvertHtmlString(fileContent);

            // save pdf document
            doc.Save(pathToPDF);

            // close pdf document
            doc.Close();
        }

        private string SendFax(CommunicationQueue queueItem, List<ApplicationConfiguration> appConfigItems, string pdfFileName)
        {
            var twilioAccountSid = appConfigItems.Where(x => x.Name == AppConfigConstants.TwilioAccountSid).FirstOrDefault();
            var twilioAuthToken = appConfigItems.Where(x => x.Name == AppConfigConstants.TwilioAuthToken).FirstOrDefault();
            var twilioFromNumber = appConfigItems.Where(x => x.Name == AppConfigConstants.TwilioFromNumber).FirstOrDefault();
            var twilioMediaHostURL = appConfigItems.Where(x => x.Name == AppConfigConstants.TwilioMediaHostURL).FirstOrDefault();

            twilioAccountSid.ThrowExceptionIfNull(string.Format("Missing configuration - {0}", AppConfigConstants.TwilioAccountSid));
            twilioAuthToken.ThrowExceptionIfNull(string.Format("Missing configuration - {0}", AppConfigConstants.TwilioAuthToken));
            twilioFromNumber.ThrowExceptionIfNull(string.Format("Missing configuration - {0}", AppConfigConstants.TwilioFromNumber));
            twilioMediaHostURL.ThrowExceptionIfNull(string.Format("Missing configuration - {0}", AppConfigConstants.TwilioMediaHostURL));

            TwilioClient.Init(twilioAccountSid.Value, twilioAuthToken.Value);

            var to = string.Format("+{0}", queueItem.NotificationRecipient.Replace(" ", string.Empty));
            var mediaUrl = new Uri(
                string.Format("{0}/{1}", twilioMediaHostURL.Value, pdfFileName));

            var fax = FaxResource.Create(to, mediaUrl, from: twilioFromNumber.Value);

            return fax.Sid;
        }

        public void RefreshPendingFaxStatuses()
        {
            AppConfigRepository appConfigRepository = new AppConfigRepository();

            var faxConfigList = appConfigRepository.GetApplicationConfigurationList(AppConfigConstants.APPLICATION_CONFIGURATION_TYPE_COM_QUEUE, AppConfigConstants.APPLICATION_CONFIGURATION_CAT_FAX_SERVICE);

            var twilioAccountSid = faxConfigList.Where(x => x.Name == AppConfigConstants.TwilioAccountSid).FirstOrDefault();
            var twilioAuthToken = faxConfigList.Where(x => x.Name == AppConfigConstants.TwilioAuthToken).FirstOrDefault();

            twilioAccountSid.ThrowExceptionIfNull(string.Format("Missing configuration - {0}", AppConfigConstants.TwilioAccountSid));
            twilioAuthToken.ThrowExceptionIfNull(string.Format("Missing configuration - {0}", AppConfigConstants.TwilioAuthToken));

            TwilioFaxResultRepository twilioFaxResultRepository = new TwilioFaxResultRepository();
            var pendingFaxes = twilioFaxResultRepository.GetPendingFaxes();

            TwilioClient.Init(twilioAccountSid.Value, twilioAuthToken.Value);

            pendingFaxes.ForEach(p =>
            {
                try
                {
                    var fax = FaxResource.Fetch(p.FaxSid);

                    if (fax != null)
                    {
                        twilioFaxResultRepository.UpdateDeliveryStatus(p.ID, fax.Status.ToString());
                    }

                }
                catch (Exception ex)
                {
                    logger.Error(ex.Message, ex);
                }
            });

        }
    }
}