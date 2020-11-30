using System;

using Android.App;
using Android.Content.PM;
using Android.Runtime;
using Android.Views;
using Android.Widget;
using Android.OS;
using Xamarin.Forms;
using Plugin.Toasts;
using FFImageLoading.Forms.Droid;

using ODISMember.Entities;
using ODISMember.Services.Service;
using HockeyApp;
using Plugin.Permissions;
using Xamarin.Forms.Platform.Android;
using Android.Hardware;
using ODISMember.Droid.Events;
using Android.Content;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Droid.Renderers;

namespace ODISMember.Droid
{
    [Activity(Label = "Pinnacle", Icon = "@drawable/icon", Theme = "@style/MyTheme", WindowSoftInputMode = SoftInput.StateAlwaysHidden, ScreenOrientation = ScreenOrientation.Portrait, ConfigurationChanges = ConfigChanges.ScreenSize | ConfigChanges.Orientation)]
    public class MainActivity : global::Xamarin.Forms.Platform.Android.FormsApplicationActivity//Xamarin.Forms.Platform.Android.FormsAppCompatActivity
    {
        static MainActivity instance;
        public static readonly object _syncLock = new object();

        public SensorManager _sensorManager;
        public Sensor _sensor;
        public ShakeDetector _shakeDetector;
        public const string HOCKEYAPP_APPID = "11951f3809f146eba84267bd2afa4b84";
        public static MainActivity CurrentActivity
        {
            get { return instance; }
        }
        protected override void OnCreate(Bundle bundle)
        {
            base.OnCreate(bundle);
            ScreenshotManager.Activity = this;
            // FormsAppCompatActivity.ToolbarResource = Resource.Layout.toolbar;
            instance = this;
            _sensorManager = (SensorManager)GetSystemService(Context.SensorService);
            _sensor = _sensorManager.GetDefaultSensor(SensorType.Accelerometer);
            _shakeDetector = new ShakeDetector();
            // Register the crash manager before Initializing the trace writer
            CrashManager.Register(this, HOCKEYAPP_APPID);
            HockeyApp.Metrics.MetricsManager.Register(this, this.Application, HOCKEYAPP_APPID);
            System.Globalization.CultureInfo.DefaultThreadCurrentCulture = System.Globalization.CultureInfo.CreateSpecificCulture("en-US");

            global::Xamarin.Forms.Forms.Init(this, bundle);
            Xamarin.FormsMaps.Init(this, bundle);
            //KB: For UITests.
            Xamarin.Forms.Forms.ViewInitialized += (object sender, Xamarin.Forms.ViewInitializedEventArgs e) =>
            {
                if (!string.IsNullOrWhiteSpace(e.View.StyleId) && e.NativeView != null)
                {
                    e.NativeView.ContentDescription = e.View.StyleId;
                }
            };

            var pixels = Resources.DisplayMetrics.WidthPixels; // real pixels
            var scale = Resources.DisplayMetrics.Density;
            int dps = (int)((pixels - 0.5f) / scale);

            App.ScreenWidth = dps;

            pixels = Resources.DisplayMetrics.HeightPixels; // real pixels
            scale = Resources.DisplayMetrics.Density;
            dps = (int)((pixels - 0.5f) / scale);

            App.ScreenHeight = dps; // real pixels
            DependencyService.Register<ToastNotificatorImplementation>();
            ToastNotificatorImplementation.Init(this);
            ActionBar.SetIcon(Android.Resource.Color.Transparent);
            CachedImageRenderer.Init();
            DependencyService.Register<XLabs.Platform.Services.Geolocation.Geolocator>();
            
             LoadApplication(new App());
            _shakeDetector.Shaked += (sender, shakeCount) =>
            {
                lock (_syncLock)
                {
                    EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.CALL_SCREENSHOOT));
                }
            };
        }

        public override void OnRequestPermissionsResult(int requestCode, string[] permissions, Permission[] grantResults)
        {
            PermissionsImplementation.Current.OnRequestPermissionsResult(requestCode, permissions, grantResults);
        }
        protected override void OnStart()
        {
            base.OnStart();
        }
        protected override void OnResume()
        {
            base.OnResume();
            _sensorManager.RegisterListener(_shakeDetector, _sensor, SensorDelay.Ui);
            //Start Tracking usage in this activity
            Tracking.StartUsage(this);
        }
        protected override void OnPause()
        {
            //Stop Tracking usage in this activity
            Tracking.StopUsage(this);

            base.OnPause();
            _sensorManager.UnregisterListener(_shakeDetector);
        }
    }
}