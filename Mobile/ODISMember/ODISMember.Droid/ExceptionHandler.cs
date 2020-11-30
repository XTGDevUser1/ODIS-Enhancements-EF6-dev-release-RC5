using System;
using Android.App;
using Android.OS;
using Android.Runtime;
using ODISMember.Services.Service;
using Plugin.CurrentActivity;

namespace ODISMember.Droid
{
	[Application]
	public class ExceptionHandler: Application
    {
		public ExceptionHandler(IntPtr javaReference, JniHandleOwnership transfer)
			: base(javaReference, transfer) { }

        

		public override void OnCreate()
		{
			base.OnCreate();
			AndroidEnvironment.UnhandledExceptionRaiser += UnhandledExceptionHandler;
		}
		void UnhandledExceptionHandler(object sender, RaiseThrowableEventArgs e)
		{
            if (e.Exception != null)
            {
                //(new Logger()).Error(e.Exception);
            }
			e.Handled = true;
		}

		protected override void Dispose(bool disposing)
		{
			AndroidEnvironment.UnhandledExceptionRaiser -= UnhandledExceptionHandler;
			base.Dispose(disposing);
		}

        public void OnActivityCreated(Activity activity, Bundle savedInstanceState)
        {
            CrossCurrentActivity.Current.Activity = activity;
        }

        public void OnActivityDestroyed(Activity activity)
        {
        }

        public void OnActivityPaused(Activity activity)
        {
        }

        public void OnActivityResumed(Activity activity)
        {
            CrossCurrentActivity.Current.Activity = activity;
        }

        public void OnActivitySaveInstanceState(Activity activity, Bundle outState)
        {
        }

        public void OnActivityStarted(Activity activity)
        {
            CrossCurrentActivity.Current.Activity = activity;
        }

        public void OnActivityStopped(Activity activity)
        {
        }
    }
}
