using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net.Mail;
using log4net;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.DMSBaseException;
using System.Collections;
using Commons.Collections;
using NVelocity.App;
using NVelocity;
using System.IO;
using System.Configuration;
using Martex.DMS.BLL.Common;

namespace Martex.DMS.BLL.SMTPSettings
{
    public class EmailService
    {
        #region Protected Methods

        /// <summary>
        /// The logger
        /// </summary>
        protected static ILog logger = LogManager.GetLogger(typeof(EmailService));

        #endregion

        #region Private Helpers

        /// <summary>
        /// Gets the SMTP client.
        /// </summary>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// </exception>
        private SmtpClient GetSMTPClient(ref string fromAddressFromDB)
        {
            logger.Info("Trying to retrieve Global SMTP Settings");

            #region SMTP Settings
            List<ApplicationConfiguration> appConfiguration = new AppConfigRepository().GetApplicationConfigurationList(ApplicationConfigurationTypes.SYSTEM, ApplicationConfigurationCategories.EMAIL);
            ApplicationConfiguration ssl = appConfiguration.Where(u => u.Name.Equals("GlobalSMTPEnabledSSL")).FirstOrDefault();
            ApplicationConfiguration port = appConfiguration.Where(u => u.Name.Equals("GlobalSMTPPortNumber")).FirstOrDefault(); ;
            ApplicationConfiguration password = appConfiguration.Where(u => u.Name.Equals("GlobalSMTPPassword")).FirstOrDefault(); ;
            ApplicationConfiguration userName = appConfiguration.Where(u => u.Name.Equals("GlobalSMTPUserName")).FirstOrDefault(); ;
            ApplicationConfiguration hostAddress = appConfiguration.Where(u => u.Name.Equals("GlobalSMTPHostName")).FirstOrDefault(); ;
            ApplicationConfiguration fromAddress = appConfiguration.Where(u => u.Name.Equals("GlobalSMTPFromAddress")).FirstOrDefault(); ;

            if (ssl == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Application Configuration {0}", "GlobalSMTPEnabledSSL"));
            }

            if (port == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Application Configuration {0}", "GlobalSMTPPortNumber"));
            }

            if (password == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Application Configuration {0}", "GlobalSMTPPassword"));
            }

            if (userName == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Application Configuration {0}", "GlobalSMTPUserName"));
            }

            if (hostAddress == null)
            {
                throw new DMSException(string.Format("Unable to retrieve Application Configuration {0}", "GlobalSMTPHostName"));
            }

            if (fromAddress == null && string.IsNullOrEmpty(fromAddressFromDB))
            {
                throw new DMSException(string.Format("Unable to retrieve Application Configuration {0}", "GlobalSMTPFromAddress"));
            }
            #endregion

            #region Validate Inputs
            bool sslEnabled = false;
            int portNumber = 0;
            string smtpPassword = string.Empty;
            string smtpUserName = string.Empty;
            string smtpHost = string.Empty;
            string smtpFromAddress = string.Empty;

            bool.TryParse(ssl.Value, out sslEnabled);
            int.TryParse(port.Value, out portNumber);
            smtpPassword = password.Value;
            smtpUserName = userName.Value;
            smtpHost = hostAddress.Value;
            smtpFromAddress = fromAddress.Value;

            if (portNumber <= 0)
            {
                throw new DMSException(string.Format("Invalid Value found for Application Configuration Key: {0} - Value : {1}", "GlobalSMTPPortNumber", portNumber));
            }
            if (string.IsNullOrEmpty(smtpHost))
            {
                throw new DMSException(string.Format("Invalid Value found for Application Configuration Key: {0} - Value : {1}", "GlobalSMTPHostName", smtpHost));
            }

            if (string.IsNullOrEmpty(smtpFromAddress) && string.IsNullOrEmpty(fromAddressFromDB))
            {
                throw new DMSException(string.Format("Invalid Value found for Application Configuration Key: {0} - Value : {1}", "GlobalSMTPFromAddress", smtpFromAddress));
            }
            //if (string.IsNullOrEmpty(smtpUserName))
            //{
            //    throw new DMSException(string.Format("Invalid Value found for Application Configuration Key: {0} - Value : {1}", "GlobalSMTPUserName", smtpUserName));
            //}
            if (string.IsNullOrEmpty(fromAddressFromDB))
            {
                fromAddressFromDB = smtpFromAddress;
            }

            #endregion

            #region SMTP Client
            SmtpClient client = new SmtpClient()
            {
                EnableSsl = sslEnabled,
                Port = portNumber,
                Host = smtpHost,
            };
            if (!string.IsNullOrEmpty(smtpUserName) && !string.IsNullOrEmpty(smtpPassword))
            {
                client.Credentials = new System.Net.NetworkCredential(smtpUserName, smtpPassword);
            }
            #endregion

            logger.Info("SMTP Details retrieved successfully");
            return client;
        }

        

        /// <summary>
        /// Gets the template.
        /// </summary>
        /// <param name="templateName">Name of the template.</param>
        /// <returns></returns>
        /// <exception cref="DMSException"></exception>
        
        public Martex.DMS.DAL.Template GetTemplate(string templateName)
        {
            logger.InfoFormat("Trying to retrieve Template details {0}", templateName);
            var lookup = new TemplateRepository();
            Martex.DMS.DAL.Template template = lookup.GetTemplateByName(templateName);
            if (template == null)
            {
                throw new DMSException(string.Format("Unable to retrieve template details for {0}", templateName));
            }
            logger.Info("Retrieved success");
            return template;
        }

        /// <summary>
        /// Gets the email body.
        /// </summary>
        /// <param name="inputParams">The input params.</param>
        /// <param name="templateBody">The template body.</param>
        /// <returns></returns>
        public string GetEmailBody(Hashtable inputParams, string templateBody)
        {
            //Initialize Velocity
            ExtendedProperties p = new ExtendedProperties();
            VelocityEngine v = new VelocityEngine();
            v.Init(p);
            VelocityContext context = new VelocityContext(inputParams);
            StringWriter writer = new StringWriter();
            v.Evaluate(context, writer, string.Empty, templateBody);
            return writer.ToString();
        }
        #endregion

        /// <summary>
        /// Sends the email.
        /// </summary>
        /// <param name="inputParams">The input params.</param>
        /// <param name="toAddress">To address.</param>
        /// <param name="fromAddress">From address.</param>
        /// <param name="templateName">Name of the template.</param>
        /// <returns></returns>
        public bool SendEmail(Hashtable inputParams, string toAddress, string templateName)
        {
            return SendEmail(inputParams, toAddress, templateName, string.Empty, string.Empty,string.Empty);
        }

        public bool SendEmail(Hashtable inputParams, string toAddress, string templateName, string fromAddress, string fromdisplayName, string todisplayName, List<Attachment> attachments = null)
        {
            if (string.IsNullOrEmpty(toAddress))
            {
                throw new DMSException(string.Format("Invalid Address To : {0}", toAddress));
            }

            if (string.IsNullOrEmpty(templateName))
            {
                throw new DMSException(string.Format("Invalid Template Name: {0}", templateName));
            }
            bool isSuccess = false;
            string fromAddressValue = fromAddress;

            MailAddress fromAddressobj = null;
            MailAddress toAddressobj = null;

           
            SmtpClient client = GetSMTPClient(ref fromAddressValue);

            if (!string.IsNullOrEmpty(fromdisplayName))
            {
                fromAddressobj = new MailAddress(fromAddressValue, fromdisplayName);
            }
            else
            {
                fromAddressobj = new MailAddress(fromAddressValue);
            }
            if (!string.IsNullOrEmpty(todisplayName))
            {
                toAddressobj = new MailAddress(toAddress, todisplayName);
            }
            else
            {
                toAddressobj = new MailAddress(toAddress);
            }
            Martex.DMS.DAL.Template template = GetTemplate(templateName);
            MailMessage mail = null;
            mail = new MailMessage(fromAddressobj, toAddressobj)
            {
                Subject = template.Subject,
                IsBodyHtml = true,
                Body = GetEmailBody(inputParams, template.Body),
            };

            string bccInulude = ConfigurationManager.AppSettings[AppConfigConstants.EMAIL_BCC_INCULDE];
            if (!string.IsNullOrEmpty(bccInulude) && bccInulude.ToLower() == AppConfigConstants.EMAIL_BCC_INCULDE_ON.ToLower())
            {
                string bcc = ConfigurationManager.AppSettings[AppConfigConstants.EMAIL_BCC];
                if (string.IsNullOrEmpty(bcc))
                {
                    logger.Warn("No bcc value provided in the web config file");
                }
                else
                {
                    mail.Bcc.Add(bcc);
                }
            }

            if (attachments != null)
            {
                attachments.ForEach(a =>
                {
                    mail.Attachments.Add(a);
                });
            }
            try
            {
                client.Send(mail);
                isSuccess = true;
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                isSuccess = false;
            }

            return isSuccess;
        }

        /// <summary>
        /// Sends the email.
        /// </summary>
        /// <param name="message">The message.</param>
        /// <returns></returns>
        public bool SendEmail(MailMessage message)
        {
            string fromAddress = string.Empty;
            bool isSuccess = false;
            SmtpClient client = GetSMTPClient(ref fromAddress);
            message.From = new MailAddress(fromAddress);

            string bccInulude = ConfigurationManager.AppSettings[AppConfigConstants.EMAIL_BCC_INCULDE];
            if (!string.IsNullOrEmpty(bccInulude) && bccInulude.ToLower() == AppConfigConstants.EMAIL_BCC_INCULDE_ON.ToLower())
            {
                string bcc = ConfigurationManager.AppSettings[AppConfigConstants.EMAIL_BCC];
                if (string.IsNullOrEmpty(bcc))
                {
                    logger.Warn("No bcc value provided in the web config file");
                }
                else
                {
                    message.Bcc.Add(bcc);
                }
            }

            try
            {
                client.Send(message);
                isSuccess = true;
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                isSuccess = false;
            }
            return isSuccess;
        }

        
        /// <summary>
        /// Sends the email.
        /// </summary>
        /// <param name="toAddress">To address.</param>
        /// <param name="templateName">Name of the template.</param>
        /// <returns></returns>
        /// <exception cref="DMSException">
        /// </exception>
        public bool SendEmail(string toAddress, string templateName)
        {
            return SendEmail(toAddress, templateName, string.Empty, string.Empty, string.Empty);
        }

        public bool SendEmail(string toAddress, string templateName,string fromAddress,string fromdisplayName,string todisplayName)
        {
            if (string.IsNullOrEmpty(toAddress))
            {
                throw new DMSException(string.Format("Invalid Address To : {0}", toAddress));
            }

            if (string.IsNullOrEmpty(templateName))
            {
                throw new DMSException(string.Format("Invalid Template Name: {0}", templateName));
            }
            bool isSuccess = false;
            string fromAddressValue = fromAddress;
            SmtpClient client = GetSMTPClient(ref fromAddressValue);
            Martex.DMS.DAL.Template template = GetTemplate(templateName);
            MailAddress fromAddressobj = null;
            MailAddress toAddressobj = null;

            if (!string.IsNullOrEmpty(fromdisplayName))
            {
                fromAddressobj = new MailAddress(fromAddress, fromdisplayName);
            }
            else
            {
                fromAddressobj = new MailAddress(fromAddress);
            }
            if (!string.IsNullOrEmpty(todisplayName))
            {
                toAddressobj = new MailAddress(toAddress, todisplayName);
            }
            else
            {
                toAddressobj = new MailAddress(toAddress);
            }
           
            MailMessage mail = new MailMessage(fromAddressobj, toAddressobj)
            {
                Subject = template.Subject,
                IsBodyHtml = true,
                Body = template.Body
                
            };

            string bccInulude = ConfigurationManager.AppSettings[AppConfigConstants.EMAIL_BCC_INCULDE];
            if (!string.IsNullOrEmpty(bccInulude) && bccInulude.ToLower() == AppConfigConstants.EMAIL_BCC_INCULDE_ON.ToLower())
            {
                string bcc = ConfigurationManager.AppSettings[AppConfigConstants.EMAIL_BCC];
                if (string.IsNullOrEmpty(bcc))
                {
                    logger.Warn("No bcc value provided in the web config file");
                }
                else
                {
                    mail.Bcc.Add(bcc);
                }
            }
            
            try
            {
                client.Send(mail);
                isSuccess = true;
            }
            catch (Exception ex)
            {
                logger.Error(ex);
                isSuccess = false;
            }

            return isSuccess;
        }
    }

}
