using System;
using System.Collections.Generic;
using System.Linq;

using Foundation;
using UIKit;
using Xamarin;
using FFImageLoading.Forms.Touch;
using Plugin.Toasts;
using Xamarin.Forms;
//using AI.XamarinSDK.Abstractions;
using ODISMember.Entities;
using CoreLocation;
using ODISMember;
using System.Globalization;
using XLabs.Forms;
using HockeyApp;
using System.Threading.Tasks;
using System.IO;
using ODISMember.iOS.Renderers;
using XLabs.Ioc;
using XLabs.Platform.Device;
using XLabs.Platform.Services;
using TK.CustomMap.iOSUnified;
using WindowsAzure.Messaging;
using ODISMember.Entities.Model;
using Newtonsoft.Json;
using Xamarin.Forms.Platform.iOS;
using ObjCRuntime;
using ODISMember.Helpers.ModelHelper;
using ODISMember.Helpers.UIHelpers;

namespace ODISMember.iOS
{
    // The UIApplicationDelegate for the application. This class is responsible for launching the 
    // User Interface of the application, as well as listening (and optionally responding) to 
    // application events from iOS.
    [Register("AppDelegate")]
    public partial class AppDelegate : XFormsApplicationDelegate//global::Xamarin.Forms.Platform.iOS.FormsApplicationDelegate //
    {
        const string HOCKEYAPP_APPID = "4869580ebadf4fa89491c63049f72bc3";//9a5f9488c61e4f84a5a7240dd3a89fc4";//"9db70eb4a5e641bbbc7e1bc9b41be88b";
        private SBNotificationHub Hub { get; set; }
        public bool IsFromNotification = false;

        //
        // This method is invoked when the application has loaded and is ready to run. In this 
        // method you should instantiate the window, load the UI into it and then make the window
        // visible.
        //
        // You have 17 seconds to return from this method, or iOS will terminate your application.
        //
        public override bool FinishedLaunching(UIApplication app, NSDictionary options)
        {
            IsFromNotification = false;
            (new iOS_Analytics()).InitHockeyApp();

            global::Xamarin.Forms.Forms.Init();
            FormsMaps.Init();

            CultureInfo.DefaultThreadCurrentCulture = CultureInfo.CreateSpecificCulture("en-US");

            UINavigationBar.Appearance.TintColor = Xamarin.Forms.Color.FromHex("#c3002f").ToUIColor();
            var iPhoneLocationManager = new CLLocationManager();

            TKCustomMapRenderer.InitMapRenderer();
            NativePlacesApi.Init();

            App.ScreenHeight = (double)UIScreen.MainScreen.Bounds.Height;
            App.ScreenWidth = (double)UIScreen.MainScreen.Bounds.Width;

            DependencyService.Register<ToastNotificatorImplementation>();
            DependencyService.Register<XLabs.Platform.Services.Geolocation.Geolocator>();

            PhoneCallImplementation.Init();
            ToastNotificatorImplementation.Init();
            CachedImageRenderer.Init();

            // Handling Push notification when app is closed if App was opened by Push Notification...
            if (options != null && options.Keys != null && options.Keys.Count() != 0 && options.ContainsKey(new NSString("UIApplicationLaunchOptionsRemoteNotificationKey")))
            {
                NSDictionary UIApplicationLaunchOptionsRemoteNotificationKey = options.ObjectForKey(new NSString("UIApplicationLaunchOptionsRemoteNotificationKey")) as NSDictionary;
                IsFromNotification = true;
                ProcessNotification(UIApplicationLaunchOptionsRemoteNotificationKey, true);
            }

            LoadApplication(new App());
            return base.FinishedLaunching(app, options);
        }

        public override void RegisteredForRemoteNotifications(UIApplication application, NSData deviceToken)
        {
            Hub = new SBNotificationHub(ODISMember.Entities.Constants.AZURE_NOTIFICATION_LISTEN_CONNECTION_STRING, ODISMember.Entities.Constants.AZURE_NOTIFICATION_HUB_NAME);

            Hub.UnregisterAllAsync(deviceToken, (error) =>
            {
                if (error != null)
                {
                    Console.WriteLine("Error calling Unregister: {0}", error.ToString());
                    return;
                }

                NSSet tags = new NSSet(ODISMember.Entities.Constants.TAG_MEMBERSHIP_NUMBER + ODISMember.Entities.Constants.MEMBER_MEMBERSHIP_NUMBER, ODISMember.Entities.Constants.TAG_MEMBER_NUMBER + ODISMember.Entities.Constants.MEMBER_NUMBER);
                Hub.RegisterNativeAsync(deviceToken, tags, (errorCallback) =>
                {
                    if (errorCallback != null)
                        Console.WriteLine("RegisterNativeAsync error: " + errorCallback.ToString());
                });
            });
        }
        public override void DidReceiveRemoteNotification(UIApplication application, NSDictionary userInfo, Action<UIBackgroundFetchResult> completionHandler)
        {
            if (!IsFromNotification)
            {
                ProcessNotification(userInfo, IsFromNotification);
            }
            else
            {
                IsFromNotification = false;
            }
        }
        public override void ReceivedRemoteNotification(UIApplication application, NSDictionary userInfo)
        {
            if (!IsFromNotification)
            {
                ProcessNotification(userInfo, IsFromNotification);
            }
            else
            {
                IsFromNotification = false;
            }
        }
        public override void HandleAction(UIApplication application, string actionIdentifier, NSDictionary remoteNotificationInfo, Action completionHandler)
        {
            //createSampleNotification("HandleAction", "HandleAction" + actionIdentifier);
            // onNotificationActionClick(actionIdentifier);
        }
        // iOS 8
        public override void HandleAction(UIApplication application, string actionIdentifier, UILocalNotification localNotification, Action completionHandler)
        {
            //createSampleNotification("8HandleAction", "8HandleAction" + actionIdentifier);
            // onNotificationActionClick(actionIdentifier);
        }
        //void onNotificationActionClick(string actionIdentifier)
        //{
        //    SQLite_iOS sqLite = new SQLite_iOS();
        //    SQLite.Net.SQLiteConnection connection = sqLite.GetConnection();
        //    ODISMember.Data.DBRepository DBRepository = new ODISMember.Data.DBRepository(connection);
        //    List<Entities.Table.Notification> listNotifications = DBRepository.GetAllRecords<Entities.Table.Notification>();

        //    string phone = string.Empty;
        //    string contactLogID = string.Empty;
        //    if (listNotifications.Count > 0)
        //    {
        //        Newtonsoft.Json.Linq.JObject result = Newtonsoft.Json.Linq.JObject.Parse(listNotifications[0].Data);
        //        phone = (string)result["TollFreeNumber"];
        //        contactLogID = (string)result["ContactLogID"];
        //    }

        //    if ("ACCEPT_IDENTIFIER".Equals(actionIdentifier, StringComparison.CurrentCultureIgnoreCase) || "DENY_IDENTIFIER".Equals(actionIdentifier, StringComparison.InvariantCultureIgnoreCase))
        //    {
        //        string serviceStatus = string.Empty;
        //        if ("ACCEPT_IDENTIFIER".Equals(actionIdentifier, StringComparison.CurrentCultureIgnoreCase))
        //        {
        //            serviceStatus = "COMPLETE";
        //        }
        //        if ("DENY_IDENTIFIER".Equals(actionIdentifier, StringComparison.CurrentCultureIgnoreCase))
        //        {
        //            serviceStatus = "NOTARRIVED";
        //        }
        //        NetworkStatus internetStatus = Reachability.InternetConnectionStatus();
        //        if (internetStatus != NetworkStatus.NotReachable)
        //        {
        //            Helpers.ModelHelper.PushNotificationHelper helper = new Helpers.ModelHelper.PushNotificationHelper();
        //            helper.SendServiceRequestCompletedResponse(contactLogID, "ANSWERED", serviceStatus);
        //        }
        //        else
        //        {
        //            createSampleNotification("No connectivity", "We are unable to process your request");
        //        }
        //        if ("DENY_IDENTIFIER".Equals(actionIdentifier, StringComparison.CurrentCultureIgnoreCase))
        //        {
        //            PhoneCallImplementation phoneCallImplementation = new PhoneCallImplementation();
        //            phoneCallImplementation.MakeQuickCall(phone);
        //        }
        //    }

        //}
        private void ProcessNotification(NSDictionary options, bool fromFinishedLaunching)
        {
            //If this came from the ReceivedRemoteNotification while the app was running,
            // we of course need to manually process things like the sound, badge, and alert.

            // Check to see if the dictionary has the aps key.  This is the notification payload you would have sent
            if (null != options && options.ContainsKey(new NSString("aps")))
            {
                //Get the aps dictionary
                NSDictionary aps = options.ObjectForKey(new NSString("aps")) as NSDictionary;

                Entities.Table.Notification notification = new Entities.Table.Notification();

                //Extract the Title of Notification alert
                if (aps.ContainsKey(new NSString("Title")))
                {
                    notification.Title = (aps[new NSString("Title")] as NSString).ToString();
                }
                //Extract the Message of Notification alert
                if (aps.ContainsKey(new NSString("Message")))
                {
                    notification.Message = (aps[new NSString("Message")] as NSString).ToString();
                }

                //Extract the Category of Notification alert
                if (aps.ContainsKey(new NSString("category")))
                {
                    notification.Category = (aps[new NSString("category")] as NSString).ToString();
                }

                //Extract the Category of Notification alert
                if (aps.ContainsKey(new NSString("Data")))
                {
                    notification.Data = (aps[new NSString("Data")] as NSString).ToString();
                }
                PushNotificationHelper pushNotificationHelper = new PushNotificationHelper((new SQLite_iOS()).GetConnection());
                pushNotificationHelper.SaveNotificationIntoLocalDB(notification);
                if (!fromFinishedLaunching)
                {
                    if (notification != null)
                    {
                        createNotification(notification);
                    }
                }
            }
        }

        void createNotification(Entities.Table.Notification notification)
        {
            UILocalNotification localNotification = new UILocalNotification();
            NSDate.FromTimeIntervalSinceNow(15);
            localNotification.AlertTitle = notification.Title;
            localNotification.AlertBody = notification.Message;
            localNotification.SoundName = UILocalNotification.DefaultSoundName;
            localNotification.AlertLaunchImage = "Icon-Small.png";
            //if (!string.IsNullOrEmpty(notification.Category))
            //{
            //    localNotification.Category = notification.Category;
            //}
            UIApplication.SharedApplication.ScheduleLocalNotification(localNotification);
        }
        void createSampleNotification(string title, string desc)
        {
            UILocalNotification localNotification = new UILocalNotification();
            NSDate.FromTimeIntervalSinceNow(15);
            localNotification.AlertTitle = title;
            localNotification.AlertBody = desc;
            localNotification.SoundName = UILocalNotification.DefaultSoundName;
            localNotification.AlertLaunchImage = "Icon-Small.png";
            UIApplication.SharedApplication.ScheduleLocalNotification(localNotification);
        }
        public override void OnActivated(UIApplication application)
        {

            base.OnActivated(application);
        }
        public override void DidEnterBackground(UIApplication application)
        {
            base.DidEnterBackground(application);
        }
    }
    [Register("MyApplication")]
    public class MyApplication : UIApplication
    {
        public override void MotionEnded(UIEventSubtype motion, UIEvent evt)
        {
            if (motion == UIEventSubtype.MotionShake)
            {
                EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.CALL_SCREENSHOOT));
            }
        }
    }
}
