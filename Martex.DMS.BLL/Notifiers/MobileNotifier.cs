using Martex.DMS.BLL.Communication;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using log4net;
using Microsoft.Azure.NotificationHubs;
using Martex.DMS.BLL.Facade;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;
using System.Threading.Tasks;
using Newtonsoft.Json.Linq;
using Martex.DMS.BLL.Model;
using System.Collections;
using Martex.DMS.DAL.Extensions;
using Newtonsoft.Json;

namespace Martex.DMS.BLL.Communication
{
    public enum NotificationSender
    {
        wns,
        apns,
        gcm
    }
    
    public class MobileNotifier : INotifier
    {
        protected static ILog logger = LogManager.GetLogger(typeof(MobileNotifier));
        private string notificationHubConnectionString;
        private string notificationHubName;
        private NotificationHubClient hubClient;
        private DeviceFacade deviceFacadeService;

        private const string NOTIFICATION_HUB_CONNECTION_STRING = "NOTIFICATION_HUB_CONNECTION_STRING";
        private const string NOTIFICATION_HUB_NAME = "NOTIFICATION_HUB_NAME";
        private const string CATEGORY_FOR_PUSH_MESSAGE = "Category";

        public MobileNotifier()
        {
            //Getting connection string values from the Application configuration 
            var appConfigRepository = new AppConfigRepository();
            notificationHubConnectionString = AppConfigRepository.GetValue(NOTIFICATION_HUB_CONNECTION_STRING);
            notificationHubName = AppConfigRepository.GetValue(NOTIFICATION_HUB_NAME);

            //Creating Object for Device Facade
            deviceFacadeService = new DeviceFacade();
        }

        private NotificationHubClient HubClient
        {
            get
            {
                if (hubClient != null)
                {
                    return hubClient;
                }
                else
                {
                    hubClient = NotificationHubClient.CreateClientFromConnectionString(notificationHubConnectionString, notificationHubName);
                    return hubClient;
                }
            }
        }

        /// <summary>
        /// Sends out the notifications via Mobile Push notifications.
        /// </summary>
        /// <param name="communicationQueue">The communication queue.</param>
        public void Notify(CommunicationQueue communicationQueue)
        {
            if (string.IsNullOrWhiteSpace(notificationHubName) || string.IsNullOrWhiteSpace(notificationHubConnectionString))
            {
                throw new DMSException("One of Notification hub or connection string is not properly configured");
            }
            
            List<string> tags = new List<string>();
            tags.Add(communicationQueue.NotificationRecipient);
            var devicesToBeNotified = deviceFacadeService.GetDevices(tags);

            if (devicesToBeNotified.Count > 0)
            {
                devicesToBeNotified.ForEach(d =>
                {
                    //notification sender defult to iOS
                    var sender = NotificationSender.apns;
                    sender = d.DeviceOS == "Android" ? NotificationSender.gcm : NotificationSender.apns;

                    //send notificaiton
                    SendNotification(sender, communicationQueue, tags).Wait(); 
                });
            }
        }

        /// <summary>
        /// Sends the notification using Azue notification hub
        /// </summary>
        /// <param name="pns">The PNS.{GCM, APNS, WNS}</param>
        /// <param name="message">The message. Body of the Notification</param>
        /// <param name="to_tags">The to_tags. List of Recipients</param>
        /// <returns></returns>
        private async Task SendNotification(NotificationSender pns, CommunicationQueue queueRecord, List<string> to_tag)
        {
            NotificationOutcome outcome = null;

            var notifier = new HubNotification();
            notifier.Title = queueRecord.Subject;
            notifier.Message = notifier.Alert = queueRecord.MessageText;

            var messageData = queueRecord.MessageData;
            Hashtable ht = new Hashtable();
            if(!string.IsNullOrWhiteSpace(messageData))
            {
                ht = messageData.XMLToKeyValuePairs();
            }

            if(ht.Contains("Category"))
            {
                notifier.Category = ht[CATEGORY_FOR_PUSH_MESSAGE].ToString();
            }
            ht["ContactLogID"] = queueRecord.ContactLogID.ToString();
            notifier.Data = JsonConvert.SerializeObject(ht);

            string message = Newtonsoft.Json.JsonConvert.SerializeObject(notifier);

            switch (pns)
            {
                case NotificationSender.wns:
                    // Windows 8.1 / Windows Phone 8.1
                    //{0}: Message
                    var toast = @"<toast><visual><binding template=""ToastText01""><text id=""1"">" + message + "</text></binding></visual></toast>";
                    outcome = await HubClient.SendWindowsNativeNotificationAsync(toast, to_tag);
                    break;
                case NotificationSender.apns:
                    // iOS: 
                    //{0}: Message
                    var alert = "{\"aps\": " + message + " }";                    
                    outcome = await HubClient.SendAppleNativeNotificationAsync(alert, to_tag);
                    break;
                case NotificationSender.gcm:
                    // Android
                    //{0}: Message                    
                   
                    var notif = "{\"data\" : " + message + "}";
                    outcome = await HubClient.SendGcmNativeNotificationAsync(notif.ToString(), to_tag);
                    break;
            }

            if (outcome == null || ((outcome.State == Microsoft.Azure.NotificationHubs.NotificationOutcomeState.Abandoned) ||
                                    (outcome.State == Microsoft.Azure.NotificationHubs.NotificationOutcomeState.Unknown)))
            {
                StringBuilder pushResult = new StringBuilder();
                if (outcome != null)
                {
                    var results = outcome.Results;
                    results.ForEach(r =>
                    {
                        pushResult.AppendFormat("Platform : {0}", r.ApplicationPlatform);
                        pushResult.AppendFormat("Outcome : {0}", r.Outcome);
                        pushResult.AppendFormat("PnsHandle : {0}", r.PnsHandle);
                        pushResult.AppendFormat("RegistrationId : {0}", r.RegistrationId);
                    });
                }
                logger.ErrorFormat("Error while sending Push notifications - {0}", pushResult.ToString());
                throw new DMSException("An error occurred while pushing notification. Please check logs for details.");
            }            
        }
    }    
}
