using Foundation;
using ODISMember.Interfaces;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.Text;
using UIKit;
using Xamarin.Forms;

[assembly: Dependency(typeof(OpenSettingsRenderer))]
namespace ODISMember.iOS.Renderers
{
    class OpenSettingsRenderer : IOpenSettings
    {
        public void Opensettings()
        {

            Global.IsGotoSetting = true;
            UIApplication.SharedApplication.OpenUrl(new NSUrl("app-settings:"));
            return;
        }
    }
}
