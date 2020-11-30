namespace Martex.DMS.EventNotification.Console
{
    using Martex.DMS.BLL.Facade;
    using Martex.DMS.DAL;
    using Martex.DMS.EventNotification.Console.Common;
    using Microsoft.Azure.NotificationHubs;
    using System;
    using System.Collections.Generic;
    using System.Linq;
    using System.Text;
    using System.Threading.Tasks;

    /// <summary>
    /// To process the Notifications using notificaiton hub
    /// </summary>
    class PushNotification
    {
        #region Fields
        private NotificationHubClient hubClient = null;
        private DeviceFacade deviceFacadeService = null;
        #endregion

        #region Properties

        /// <summary>
        /// Gets the Notificaiton Hub client object
        /// </summary>
        /// <value>
        /// The hub client.
        /// </value>
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
                    hubClient = NotificationHubClient.CreateClientFromConnectionString(Constants.AZURE_NOTIFICATION_LISTEN_CONNECTION_STRING, Constants.AZURE_NOTIFICATION_HUB_NAME);

                    return hubClient;
                }
            }
        }

        /// <summary>
        /// Gets the device facade service.
        /// </summary>
        /// <value>
        /// The device facade service.
        /// </value>
        private DeviceFacade DeviceFacadeService
        {
            get
            {
                if (deviceFacadeService != null)
                {
                    return deviceFacadeService;
                }
                else
                {
                    deviceFacadeService = new DeviceFacade();

                    return deviceFacadeService;
                }
            }
        }
        #endregion

        /// <summary>
        /// Processes the notifications.
        /// </summary>
        public void ProcessNotifications()
        {
            //TODO: tags will get formed from the communication queue recipients
            var tags = new List<string>();            
            tags.Add("MembershipNumber:5028652");            

            //Get all the devices realted to tags
            List<MobileDeviceRegistration> list = DeviceFacadeService.GetDevices(tags);

            Task.Run(() =>
            {
                for (int i = 0, iCount = list.Count; i < iCount; i++)
                {
                    var item = list[i];
                    //notification sender defult to iOS
                    var sender = NotificationSender.apns;
                    sender = item.DeviceOS == "Android" ? NotificationSender.gcm : NotificationSender.apns;

                    //send notificaiton
                    SendNotification(sender, "Hello World!", tags).Wait(); 
                }
            });
        }

        /// <summary>
        /// Sends the notification using Azue notification hub
        /// </summary>
        /// <param name="pns">The PNS.{GCM, APNS, WNS}</param>
        /// <param name="message">The message. Body of the Notification</param>
        /// <param name="to_tags">The to_tags. List of Recipients</param>
        /// <returns></returns>
        private async Task SendNotification(NotificationSender pns, string message, List<string> to_tag)
        {
            NotificationOutcome outcome = null;
            
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
                    var alert = "{\"aps\":{\"alert\":\"" + message + "\"}}";
                    outcome = await HubClient.SendAppleNativeNotificationAsync(alert, to_tag);
                    break;
                case NotificationSender.gcm:
                    // Android
                    //{0}: Message
                    var notif = "{ \"data\" : {\"message\":\"" + message + "\"}}";
                    outcome = await HubClient.SendGcmNativeNotificationAsync(notif, to_tag);
                    break;
            }

            if (outcome != null)
            {
                if (!((outcome.State == Microsoft.Azure.NotificationHubs.NotificationOutcomeState.Abandoned) ||
                    (outcome.State == Microsoft.Azure.NotificationHubs.NotificationOutcomeState.Unknown)))
                {
                    Console.WriteLine("Notificaiton has been processed");
                    //TODO: Need to update communication queue with the status
                }
            }
            else
            {
                Console.WriteLine("Not able to process notificaiton");
                //TODO: Need to update communication queue with the status
            }
        }
    }
}
