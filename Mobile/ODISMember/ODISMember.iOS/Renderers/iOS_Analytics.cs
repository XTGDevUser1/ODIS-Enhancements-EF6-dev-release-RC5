using HockeyApp;
using ODISMember.Contract;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using Xamarin.Forms;

[assembly: Dependency(typeof(iOS_Analytics))]
namespace ODISMember.iOS.Renderers
{
    public class iOS_Analytics : IAnalytics
    {
        const string HOCKEYAPP_APPID = "4869580ebadf4fa89491c63049f72bc3";
        BITHockeyManager manager = null;
        public void CustomEvent(string eventName)
        {
            if (manager == null)
            {
                InitHockeyApp();
            }
            manager.MetricsManager.TrackEvent(eventName);
        }
        public void InitHockeyApp()
        {
            manager = BITHockeyManager.SharedHockeyManager;
            manager.ConfigureWithIdentifier(HOCKEYAPP_APPID, HOCKEYAPP_APPID, new CustomCrashDelegate());
            manager.CrashManager.CrashManagerStatus = BITCrashManagerStatus.AlwaysAsk;
           // manager.CrashManager.EnableOnDeviceSymbolication = true;
            manager.StartManager();
            manager.Authenticator.AuthenticateInstallation();
        }
        public class CustomCrashDelegate : BITCrashManagerDelegate
        {
            //Called at the next restart after a crash, the content of the file will be visible
            //in the HockeyApp dashboard under the "Description" tab
            public override string ApplicationLogForCrashManager(BITCrashManager crashManager)
            {
                {
                    return File.ReadAllText("temp.log");
                }
            }
        }
    }
}
