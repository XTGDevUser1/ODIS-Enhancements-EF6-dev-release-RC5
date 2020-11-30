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
using Xamarin.Forms;
using ODISMember.Droid.Renderers;
using ODISMember.Contract;

[assembly: Dependency(typeof(Android_Analytics))]
namespace ODISMember.Droid.Renderers
{
    public class Android_Analytics : IAnalytics
    {
        public void CustomEvent(string eventName)
        {
            HockeyApp.Metrics.MetricsManager.TrackEvent(eventName);
        }
    }
}