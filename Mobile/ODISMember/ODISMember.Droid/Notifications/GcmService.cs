using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Android.App;
using Android.Content;
using Android.OS;
using Android.Runtime;
using Android.Views;
using Android.Widget;
using Gcm.Client;
using Android.Util;
using Android.Support.V4.Content;
using Android.Media;
using Android.Graphics;
using WindowsAzure.Messaging;
using Newtonsoft.Json;
using ODISMember.Entities.Model;
using Plugin.Connectivity;
using ODISMember.Helpers.ModelHelper;

namespace ODISMember.Droid.Notifications
{
    /// <summary>
    /// Registering service to receive push notifications on background
    /// </summary>
    /// <seealso cref="Gcm.Client.GcmServiceBase" />
    [Service]
    public class GcmService : GcmServiceBase
    {
        public static string RegistrationID { get; private set; }
        private NotificationHub Hub { get; set; }

        public void RemoveNotification(int id)
        {
            // Get the notification manager:
            NotificationManager notificationManager = GetSystemService(Context.NotificationService) as NotificationManager;
            notificationManager.Cancel(id);
        }

        public GcmService()
            : base(GcmBroadcastReceiver.SENDER_IDS)
        {
        }
        protected override void OnHandleIntent(Intent intent)
        {
            if (intent != null && intent.Extras != null)
            {
                string notification = intent.GetStringExtra("Notification") ?? string.Empty;
                if (!string.IsNullOrEmpty(notification))
                {
                    ODISMember.Entities.Table.Notification notificationContent = JsonConvert.DeserializeObject<ODISMember.Entities.Table.Notification>(notification);
                    string userAction = intent.GetStringExtra("Action") ?? string.Empty;
                    if ("YES".Equals(userAction, StringComparison.CurrentCultureIgnoreCase))
                    {
                        Newtonsoft.Json.Linq.JObject result = Newtonsoft.Json.Linq.JObject.Parse(notificationContent.Data);
                        string phone = (string)result["TollFreeNumber"];
                        string contactLogID = (string)result["ContactLogID"];

                        RemoveNotification(0);

                        if (CrossConnectivity.Current.IsConnected)
                        {
                            Helpers.ModelHelper.PushNotificationHelper helper = new Helpers.ModelHelper.PushNotificationHelper();
                            helper.SendServiceRequestCompletedResponse(contactLogID, "ANSWERED", "COMPLETE");
                        }
                        else
                        {
                            createNotification("No connectivity", "We are unable to process your request");
                        }

                    }
                }
                else
                {
                    base.OnHandleIntent(intent);
                }
            }
        }
        protected override void OnRegistered(Context context, string registrationId)
        {
            RegistrationID = registrationId;
            var tags = new List<string>()
            {
                ODISMember.Entities.Constants.TAG_MEMBERSHIP_NUMBER + ODISMember.Entities.Constants.MEMBER_MEMBERSHIP_NUMBER,
                ODISMember.Entities.Constants.TAG_MEMBER_NUMBER + ODISMember.Entities.Constants.MEMBER_NUMBER
            };
            Hub = new NotificationHub(ODISMember.Entities.Constants.AZURE_NOTIFICATION_HUB_NAME, ODISMember.Entities.Constants.AZURE_NOTIFICATION_LISTEN_CONNECTION_STRING, context);
            try
            {
                Hub.UnregisterAll(registrationId);
            }
            catch (Exception ex)
            {
                //TODO: Log Error
            }
            try
            {
                Hub.Register(registrationId, tags.ToArray());
                //var hubRegistration = Hub.Register(registrationId, tags.ToArray());
            }
            catch (Exception ex)
            {
                //TODO: Log Error
            }
        }

        protected override void OnMessage(Context context, Intent intent)
        {
            if (intent != null && intent.Extras != null)
            {
                ODISMember.Entities.Table.Notification notification = new ODISMember.Entities.Table.Notification();

                notification.Title = intent.Extras.GetString("Title");
                notification.Message = intent.Extras.GetString("Message");
                notification.Category = intent.Extras.GetString("category");
                notification.Data = intent.Extras.GetString("Data"); 
                PushNotificationHelper pushNotificationHelper = new PushNotificationHelper((new SQLite_Android()).GetConnection());
                pushNotificationHelper.SaveNotificationIntoLocalDB(notification);

                if (notification != null)
                {
                    createLocalNotification(notification);
                }
            }
        }

        protected override void OnUnRegistered(Context context, string registrationId)
        {
            ODISMember.Entities.Table.Notification notification = new ODISMember.Entities.Table.Notification();
            notification.Title = "GCM Unregistered...";
            notification.Message = "The device has been unregistered!";
            createLocalNotification(notification);
        }

        protected override bool OnRecoverableError(Context context, string errorId)
        {
            return base.OnRecoverableError(context, errorId);
        }

        protected override void OnError(Context context, string errorId)
        {
            //TODO: Log Error
        }
        private void createNotification(string title, string desc)
        {
            Notification.BigTextStyle textStyle = new Notification.BigTextStyle();
            textStyle.BigText(desc);
            // Set up an intent so that tapping the notifications returns to this app:
            Intent intent = new Intent(this, typeof(MainActivity));

            // Create a PendingIntent; we're only using one PendingIntent (ID = 0):
            const int pendingIntentId = 0;
            PendingIntent pendingIntent =
                PendingIntent.GetActivity(this, pendingIntentId, intent, PendingIntentFlags.OneShot);

            Notification.Builder builder = new Notification.Builder(this)
            .SetContentIntent(pendingIntent)
            .SetContentTitle(title)
            .SetStyle(textStyle)
            .SetSmallIcon(Resource.Drawable.ic_launcher);

            // Build the notification:
            Notification notification = builder.Build();

            // Get the notification manager:
            NotificationManager notificationManager =
                GetSystemService(Context.NotificationService) as NotificationManager;

            // Publish the notification:
            notificationManager.Notify((int)DateTime.Now.Ticks, notification);

        }
        void createLocalNotification(ODISMember.Entities.Table.Notification notification)
        {
            // Set up an intent so that tapping the notifications returns to this app:
            Intent intent = new Intent(this, typeof(MainActivity));

            // Create a PendingIntent; we're only using one PendingIntent (ID = 0):
            const int pendingIntentId = 0;
            PendingIntent pendingIntent = PendingIntent.GetActivity(this, pendingIntentId, intent, PendingIntentFlags.OneShot);

            //Intent yesIntent = new Intent(this, typeof(GcmService));
            //yesIntent.PutExtra("Notification", JsonConvert.SerializeObject(notification));
            //yesIntent.PutExtra("Action", "YES");

            //Intent noIntent = new Intent(this, typeof(DialerActivity));
            //noIntent.PutExtra("Notification", JsonConvert.SerializeObject(notification));
            //noIntent.PutExtra("Action", "NO");

            //var yesServiceIntent = PendingIntent.GetService(this, 1, yesIntent, PendingIntentFlags.CancelCurrent);
            //var noServiceIntent = PendingIntent.GetActivity(this, 2, noIntent, PendingIntentFlags.OneShot);

            //Android.App.Notification.Action ok_action = new Android.App.Notification.Action(Resource.Drawable.icDoneBlack, "Yes", yesServiceIntent);
            //Android.App.Notification.Action cancel_action = new Android.App.Notification.Action(Resource.Drawable.icClearBlack, "No", noServiceIntent);

            //// Instantiate the Big Text style:
            //Notification.BigTextStyle textStyle = new Notification.BigTextStyle();
            //textStyle.SetBigContentTitle(notification.Title);
            //textStyle.BigText(notification.Message);

            // Instantiate the builder and set notification elements, including pending intent:
            Notification.Builder builder = new Notification.Builder(this)
                .SetContentIntent(pendingIntent)
                 .SetContentTitle(notification.Title)
                  .SetContentText(notification.Message)
                  .SetPriority(0)
                  .SetSound(RingtoneManager.GetDefaultUri(RingtoneType.Notification))
                  .SetAutoCancel(true)
                .SetSmallIcon(Resource.Drawable.ic_launcher);

            //if (!string.IsNullOrEmpty(notification.Category) && notification.Category == "CONFIRMATION_CATEGORY")
            //{
            //    builder.AddAction(ok_action);
            //    builder.AddAction(cancel_action);
            //}

            // Build the notification:
            Notification localNotification = builder.Build();

            // Get the notification manager:
            NotificationManager notificationManager =
                GetSystemService(Context.NotificationService) as NotificationManager;

            // Publish the notification:
            const int notificationId = 0;
            notificationManager.Notify(notificationId, localNotification);
        }
    }
}