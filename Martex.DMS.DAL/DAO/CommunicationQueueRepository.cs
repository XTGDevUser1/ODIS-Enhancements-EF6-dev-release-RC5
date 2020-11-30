using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using System.Collections;
using System.Xml;
using System.IO;
using Commons.Collections;
using NVelocity.App;
using NVelocity;
using log4net;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;
using System.Data.Entity;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAO
{
    /// <summary>
    /// 
    /// </summary>
    public class CommunicationQueueRepository
    {
        private string logData;
        private EventLog eventLog;
        private EventSubscriptionRecipient subscriptionRecipient;
        protected static readonly ILog logger = LogManager.GetLogger(typeof(CommunicationQueueRepository));

        /// <summary>
        /// Saves the specified model.
        /// </summary>
        /// <param name="model">The model.</param>
        public void Save(CommunicationQueue model)
        {
            using (DMSEntities entities = new DMSEntities())
            {
                entities.CommunicationQueues.Add(model);
                entities.SaveChanges();
            }
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="contactLogID"></param>
        /// <param name="contactMethodName"></param>
        /// <param name="templateName"></param>
        /// <param name="recipient"></param>
        /// <param name="param"></param>
        /// <param name="userName"></param>
        /// <param name="messageData"></param>
        public void Save(int contactLogID, string contactMethodName, string templateName, string recipient, Hashtable param, string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                #region Verify Records

                var contactMethod = dbContext.ContactMethods.Where(u => u.Name.Equals(contactMethodName)).FirstOrDefault();
                if (contactMethod == null)
                {
                    throw new Exception(string.Format("Unable to retrieve Contact Method {0}", contactMethodName));
                }

                var template = dbContext.Templates.Where(u => u.Name.Equals(templateName)).FirstOrDefault();
                if (template == null)
                {
                    throw new Exception(string.Format("Unable to retrieve Template {0}", templateName));
                }
                #endregion

                #region Create Record
                dbContext.CommunicationQueues.Add(new CommunicationQueue()
                {
                    ContactLogID = contactLogID,
                    ContactMethodID = contactMethod.ID,
                    TemplateID = template.ID,
                    MessageData = GetXML(param),
                    Subject = template.Subject,
                    MessageText = TemplateUtil.ProcessTemplate(template.Body, param),
                    CreateDate = DateTime.Now,
                    CreateBy = userName,
                    NotificationRecipient = recipient
                });
                dbContext.SaveChanges();
                #endregion

            }
        }

        /// <summary>
        /// Gets the XML from a given list of name-value pairs
        /// </summary>
        /// <param name="eventDetails">List of name-value pairs</param>
        /// <returns>XML as string</returns>
        public string GetXML(Hashtable eventDetails)
        {
            StringBuilder sb = new StringBuilder(""); //"<MessageData>");
            XmlWriterSettings settings = new XmlWriterSettings();
            settings.Indent = true;
            settings.OmitXmlDeclaration = true;
            using (XmlWriter writer = XmlWriter.Create(sb, settings))
            {
                writer.WriteStartElement("MessageData");
                foreach (string key in eventDetails.Keys)
                {
                    string val = eventDetails[key] as string;
                    writer.WriteElementString(key, val);
                }
                writer.WriteEndElement();

                writer.Close();
            }
            #region Old Code
            /*foreach (string key in eventDetails.Keys)
            {
                string val = eventDetails[key] as string;
                if (!string.IsNullOrEmpty(val))
                {
                    val = val.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("'", "&quot;");
                }
                sb.AppendFormat("<{0}>{1}</{0}>", key, val);
            }
            sb.Append("</MessageData>");*/
            #endregion
            return sb.ToString();
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="CommunicationQueueRepository"/> class.
        /// </summary>
        /// <param name="logDescription">The log description.</param>
        /// <param name="subscription">The subscription.</param>
        public CommunicationQueueRepository(EventLog eventLog, EventSubscriptionRecipient subscription)
        {
            this.eventLog = eventLog;
            this.subscriptionRecipient = subscription;
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="CommunicationQueueRepository"/> class.
        /// </summary>
        public CommunicationQueueRepository()
        {

        }

        /// <summary>
        /// Extract Node name and values as key value pairs.
        /// </summary>
        /// <param name="xml">The XML.</param>
        /// <returns>Hashtable with key value pairs</returns>
        public Hashtable XMLToKeyValuePairs(string xml)
        {
            Hashtable ht = new Hashtable();

            try
            {
                if (!string.IsNullOrEmpty(xml))
                {
                    XmlDocument doc = new XmlDocument();
                    doc.Load(new StringReader(xml));

                    XmlNodeList nodes = doc.DocumentElement.ChildNodes;

                    foreach (XmlNode node in nodes)
                    {
                        ht.Add(node.Name, node.InnerText ?? string.Empty);
                    }
                }
            }
            catch
            {
                logger.WarnFormat("Input string is not a well-formed XML : {0}", xml);
            }

            return ht;
        }

        /// <summary>
        /// Enqueues a record for Communication Service
        /// </summary>
        public void Enqueue(int? contactLogID = null)
        {
            if (eventLog == null || subscriptionRecipient == null)
            {
                throw new DMSException("One of EventLog or subscription or both are null");
            }

            if (!string.IsNullOrEmpty(eventLog.Description) && eventLog.Description.StartsWith("<"))
            {
                logData = eventLog.Description;
            }
            else
            {
                logData = eventLog.Data;
            }

            // Prepare all the attributes for CommunicationQueue            
            CommunicationQueue queue = new CommunicationQueue();
            queue.ContactMethodID = subscriptionRecipient.ContactMethodID;

            EventTemplate eventTemplate = (new EventTemplateRepository()).GetTemplateById(subscriptionRecipient.EventTemplateID);
            Hashtable tagValues = XMLToKeyValuePairs(logData);
            tagValues.Add("Event", eventLog.Event.Description);//KB: TFS 534
            tagValues.Add("EventDate", eventLog.CreateDate.GetValueOrDefault().ToString("MM/dd/yyyy"));//KB: TFS 534
            
            string subject = string.Empty;
            string messageText = eventLog.Description;
            if (eventTemplate != null)
            {
                if (eventTemplate.Template != null)
                {
                    var template = eventTemplate.Template;
                    subject = TemplateUtil.ProcessTemplate(template.Subject, tagValues);
                    messageText = TemplateUtil.ProcessTemplate(template.Body, tagValues);
                }
            }

            queue.NotificationRecipient = subscriptionRecipient.Recipient;

            queue.Subject = subject;
            queue.MessageText = messageText;
            queue.CreateBy = "SYSTEM";
            queue.CreateDate = DateTime.Now;
            queue.MessageData = logData;
            queue.EventLogID = eventLog.ID;
            queue.ContactLogID = contactLogID;

            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.CommunicationQueues.Add(queue);
                dbContext.SaveChanges();
            }

        }

        /// <summary>
        /// Get the list of unprocessed communication queue from database
        /// </summary>
        /// <returns>List<CommunicationQueue></returns>
        public List<CommunicationQueue> GetQueue()
        {
            //TransactionOptions tranOptions = new TransactionOptions();
            //tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
            //tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
            //using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
            //{
            using (DMSEntities dbContext = new DMSEntities())
            {
                //Sanghi : Issue
                //dbContext.Database.ExecuteSqlCommand("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;");
                var today = DateTime.Today;
                var result = (from c in dbContext.CommunicationQueues
                              where c.ScheduledDate == null || c.ScheduledDate <= DateTime.Now
                              orderby c.CreateDate
                              select c).ToList<CommunicationQueue>();
                //return dbContext.CommunicationQueues.OrderBy(a=> a.ScheduledDate == null || a.ScheduledDate < today).ToList<CommunicationQueue>();
                //tran.Complete();
                return result;
            }
            //}
        }
        /// <summary>
        /// Add the communication log which indicating the status of communication queue, to database
        /// </summary>
        /// <returns></returns>
        public int AddCommunicationLog(CommunicationLog communicationLog)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                dbContext.CommunicationLogs.Add(communicationLog);
                dbContext.Entry(communicationLog).State = EntityState.Added;
                dbContext.SaveChanges();
                return communicationLog.ID;
            }
        }


        /// <summary>
        /// Updates the communication.
        /// </summary>
        /// <param name="communicationQueue">The communication queue.</param>
        public void UpdateCommunication(CommunicationQueue communicationQueue)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var communicationQueueFromDB = dbContext.CommunicationQueues.Where(a => a.ID == communicationQueue.ID).FirstOrDefault();
                if (communicationQueueFromDB != null)
                {
                    communicationQueueFromDB.Attempts = communicationQueue.Attempts;
                    dbContext.Entry(communicationQueueFromDB).State = EntityState.Modified;
                    dbContext.SaveChanges();
                }
            }
        }
        /// <summary>
        /// Delete the communication queue
        /// </summary>
        /// <returns></returns>
        public void DeleteCommunication(int id)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var communicationQueue = dbContext.CommunicationQueues.Where(a => a.ID == id).FirstOrDefault();
                dbContext.Entry(communicationQueue).State = EntityState.Deleted;
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the communication fax details.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        public void UpdateCommunicationFaxDetails(string userName)
        {
            TransactionOptions tranOptions = new TransactionOptions();
            tranOptions.Timeout = new System.TimeSpan(0, 30, 0);
            tranOptions.IsolationLevel = IsolationLevel.ReadUncommitted;
            using (TransactionScope tran = new TransactionScope(TransactionScopeOption.Required, tranOptions))
            {
                using (DMSEntities entities = new DMSEntities())
                {
                    entities.UpdateCommunicationFax(userName);
                }
                tran.Complete();
            }
        }

        /// <summary>
        /// Gets the notification history.
        /// </summary>
        /// <param name="userName">Name of the user.</param>
        /// <returns></returns>
        public List<NotificationHistory_Result> GetNotificationHistory(string userName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var list = dbContext.GetNotificationHistory(userName).ToList<NotificationHistory_Result>();
                return list;
            }
        }
    }
}
