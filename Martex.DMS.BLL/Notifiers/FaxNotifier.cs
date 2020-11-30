using System.Drawing;
using System.Drawing.Printing;
using Martex.DMS.DAL.DAO;
using Martex.DMS.BLL.Common;
using System.Windows.Forms;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAO;
using System.Collections;
using System.IO;
using System;
using System.Security;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Security.Permissions;
using Microsoft.Win32.SafeHandles;
using System.Runtime.ConstrainedExecution;

using Martex.DMS.BLL.Security;
using log4net;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.BLL.Communication
{
    /// <summary>
    /// FaxNotifier
    /// </summary>
    public class FaxNotifier : INotifier
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
        protected static ILog logger = LogManager.GetLogger(typeof(FaxNotifier));
        #endregion

        #region INotifier Members

        /// <summary>
        /// The print font
        /// </summary>
        private Font printFont;

        /// <summary>
        /// The text to print
        /// </summary>
        private string textToPrint = string.Empty;

        #endregion

        /// <summary>
        /// Prints the document.
        /// </summary>
        /// <param name="sender">The sender.</param>
        /// <param name="e">The <see cref="WebBrowserDocumentCompletedEventArgs"/> instance containing the event data.</param>
        private void PrintDocument(object sender, WebBrowserDocumentCompletedEventArgs e)
        {
            // Print the document now that it is fully loaded.
            ((WebBrowser)sender).Print();

            // Dispose the WebBrowser now that the task is complete. 
            ((WebBrowser)sender).Dispose();
        }

        /// <summary>
        /// Handles the PrintPage event of the printDocument control.
        /// The PrintPage event is raised for page to be printed.
        /// </summary>
        /// <param name="sender">The source of the event.</param>
        /// <param name="ev">The <see cref="PrintPageEventArgs"/> instance containing the event data.</param>
        private void printDocument_PrintPage(object sender, PrintPageEventArgs ev)
        {
            float yPos = 0;
            int count = 0;
            float leftMargin = ev.MarginBounds.Left;
            float topMargin = ev.MarginBounds.Top;

            printFont.GetHeight(ev.Graphics);
            yPos = topMargin + (count *
                     printFont.GetHeight(ev.Graphics));
            ev.Graphics.DrawString(textToPrint, printFont, Brushes.Black,
               leftMargin, yPos, new StringFormat());
            ev.HasMorePages = false;
        }

        /// <summary>
        /// Deletes the file if exists.
        /// </summary>
        /// <param name="fileName">Name of the file.</param>
        private void DeleteFileIfExists(string fileName)
        {
            FileInfo fExistFile = new FileInfo(fileName);
            if (fExistFile.Exists)
            {
                fExistFile.Delete();
            }
        }

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

            //Sanghi : Fax Implementation
            TemplateRepository repository = new TemplateRepository();
            Template template = repository.GetTemplateByName(AppConfigConstants.TEMPLATE_FAX_HEADER_XML_FILE);
            if (template == null)
            {
                throw new DMSException("Unable to retrieve the template details");
            }

            AppConfigRepository appConfigRepository = new AppConfigRepository();
            ApplicationConfiguration appConfiguration = appConfigRepository.GetApplicationConfiguration(AppConfigConstants.APPLICATION_CONFIGURATION_TYPE_COM_QUEUE, AppConfigConstants.APPLICATION_CONFIGURATION_CAT_FAX_SERVICE);

            if (appConfiguration == null)
            {
                throw new DMSException("Unable to retrieve the application configuration details");
            }

            //CR: 1312 : Change the reference to the body file path to use the local body file path appconfig setting.
            string localBodyFilePath = AppConfigRepository.GetValue(AppConfigConstants.LOCAL_BODY_FILE_PATH);

            string filePathforHtml = AppConfigRepository.GetValue(AppConfigConstants.BODY_FILE_PATH);
            string fileNameforHtml = "\\FaxBody_" + communicationQueue.CommunicationLogID.ToString();

            string filePathforXML = AppConfigRepository.GetValue(AppConfigConstants.XML_API_PATH);
            string fileNameforXML = "\\FaxHeader_" + communicationQueue.CommunicationLogID.ToString();

            logger.InfoFormat(" HTML Path : {0}, XML Path : {1}", filePathforHtml, filePathforXML);

            CommunicationQueueRepository communicationRepository = new CommunicationQueueRepository();
            Hashtable htParams = new Hashtable();
            //CR: 1312 : Change the reference to the body file path to use the local body file path appconfig setting.
            htParams.Add("MessageFilePath", localBodyFilePath + fileNameforHtml + ".htm");
            htParams.Add("CommunicationLogID", communicationQueue.CommunicationLogID.ToString());
            htParams.Add("CoverPage", AppConfigRepository.GetValue(AppConfigConstants.COVER_PAGE));
            htParams.Add("GFISenderEmail", AppConfigRepository.GetValue(AppConfigConstants.GFI_SENDER_EMAIL));
            htParams.Add("FaxNumber", communicationQueue.NotificationRecipient ?? string.Empty);
            string bodyMessage = TemplateUtil.ProcessTemplate(template.Body, htParams);

            string faxServerUsername = AppConfigRepository.GetValue(AppConfigConstants.FAX_SERVER_USERNAME);
            string faxServerPassword = AppConfigRepository.GetValue(AppConfigConstants.FAX_SERVER_PASSWORD);

            logger.InfoFormat(" Fax server username : {0}", faxServerUsername);

            IntPtr token = IntPtr.Zero;
            LogonUser(faxServerUsername,
                        "nmcdallas.nmca.com",
                        faxServerPassword,
                        (int)LogonType.NewCredentials,
                        0,
                        ref token);

            try
            {
                using (WindowsImpersonationContext context = WindowsIdentity.Impersonate(token))
                {
                    FileInfo fXmlFile = new FileInfo(filePathforXML + fileNameforXML);
                    logger.InfoFormat("Creating xml file");
                    using (StreamWriter sw = new StreamWriter(new FileStream(fXmlFile.FullName, FileMode.OpenOrCreate), System.Text.UTF8Encoding.Default))
                    {
                        sw.Write(bodyMessage);
                        sw.Close();
                    }
                    FileInfo fBodyFile = new FileInfo(filePathforHtml + fileNameforHtml + ".htm");

                    logger.InfoFormat("Creating html file");
                    using (StreamWriter sw = new StreamWriter(new FileStream(fBodyFile.FullName, FileMode.OpenOrCreate), System.Text.UTF8Encoding.Default))
                    {
                        sw.Write(communicationQueue.MessageText);
                        sw.Close();
                    }

                    File.Move(fXmlFile.FullName, fXmlFile.FullName + ".xml");
                }

            }
            catch (System.Exception ex)
            {
                logger.Warn(ex.Message, ex);
                // Just to make sure take in case of any exception occurs while creating the files into physical drive  
                // Let clean the drive with the files whihc is created above
                using (WindowsImpersonationContext context = WindowsIdentity.Impersonate(token))
                {
                    DeleteFileIfExists(filePathforHtml + fileNameforHtml + ".htm");
                    DeleteFileIfExists(filePathforXML + fileNameforXML + ".xml");
                }
                throw new Exception("An error had occured while creating the file", ex);
            }

        }

    }

}
