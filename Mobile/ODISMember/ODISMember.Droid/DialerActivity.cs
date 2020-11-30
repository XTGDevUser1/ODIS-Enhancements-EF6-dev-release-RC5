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
using Newtonsoft.Json;


namespace ODISMember.Droid
{
    [Activity(Label = "DialerActivity")]
    public class DialerActivity : Activity
    {
        protected override void OnCreate(Bundle savedInstanceState)
        {
            base.OnCreate(savedInstanceState);

            if (this.Intent != null && this.Intent.Extras != null)
            {
                string notification = this.Intent.GetStringExtra("Notification") ?? string.Empty;
                if (!string.IsNullOrEmpty(notification))
                {
                    ODISMember.Entities.Table.Notification notificationContent = JsonConvert.DeserializeObject<ODISMember.Entities.Table.Notification>(notification);
                    string userAction = this.Intent.GetStringExtra("Action") ?? string.Empty;
                    Newtonsoft.Json.Linq.JObject result = Newtonsoft.Json.Linq.JObject.Parse(notificationContent.Data);
                    string phone = (string)result["TollFreeNumber"];
                    string contactLogID = (string)result["ContactLogID"];

                    if ("NO".Equals(userAction, StringComparison.CurrentCultureIgnoreCase) && !string.IsNullOrEmpty(phone))
                    {

                        if (Plugin.Connectivity.CrossConnectivity.Current.IsConnected)
                        {
                            Helpers.ModelHelper.PushNotificationHelper helper = new Helpers.ModelHelper.PushNotificationHelper();
                            helper.SendServiceRequestCompletedResponse(contactLogID, "ANSWERED", "NOTARRIVED");
                        }
                        else
                        {
                            createNotification("No connectivity", "We are unable to process your request");
                        }

                        if (System.Text.RegularExpressions.Regex.IsMatch(phone, "^(\\(?\\+?[0-9]*\\)?)?[0-9_\\- \\(\\)]*$"))
                        {
                            var uri = Android.Net.Uri.Parse(String.Format("tel:{0}", phone));
                            var intent = new Intent(Intent.ActionView, uri);
                            this.StartActivity(intent);
                        }
                    }

                }
            }
            NotificationManager notificationManager = GetSystemService(Context.NotificationService) as NotificationManager;
            notificationManager.Cancel(0);
            Finish();
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
    }
}