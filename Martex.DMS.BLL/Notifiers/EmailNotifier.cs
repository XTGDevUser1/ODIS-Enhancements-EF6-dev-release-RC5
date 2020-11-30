using System.Net.Mail;
using log4net;

namespace Martex.DMS.BLL.Communication
{
    /// <summary>
    /// EmailNotifier
    /// </summary>
    public class EmailNotifier : INotifier
    {
        protected static ILog logger = LogManager.GetLogger(typeof(EmailNotifier));
        #region INotifier Members
        /// <summary>
        /// Notifiers the specified communication queue.
        /// </summary>
        /// <param name="communicationQueue">The communication queue.</param>
        public void Notify(DAL.CommunicationQueue communicationQueue)
        {
            MailMessage message = new MailMessage();
            message.Subject = communicationQueue.Subject;
            string sToAddress = communicationQueue.NotificationRecipient;
            string[] toAddresses = sToAddress.Split(',', ';');
            foreach (string toAddress in toAddresses)
            {
                message.To.Add(toAddress);
            }
            
            message.IsBodyHtml = true;
            message.Body = communicationQueue.MessageText;
            SmtpClient smtpclient = new SmtpClient();
            smtpclient.Send(message);
        }

        #endregion
    }
}
