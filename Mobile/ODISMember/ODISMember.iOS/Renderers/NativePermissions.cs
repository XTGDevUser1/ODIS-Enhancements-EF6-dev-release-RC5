using ODISMember.Interfaces;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.Text;
using UIKit;
using Xamarin.Forms;

[assembly: Dependency(typeof(NativePermissions))]
namespace ODISMember.iOS.Renderers
{
    public class NativePermissions : INativePermissions
    {
        public bool CheckNotificationPermission()
        {
            if (UIDevice.CurrentDevice.CheckSystemVersion(8, 0))
            {
                UIUserNotificationType types = UIApplication.SharedApplication.CurrentUserNotificationSettings.Types;
                if (types.HasFlag(UIUserNotificationType.Alert) || types.HasFlag(UIUserNotificationType.Badge) || types.HasFlag(UIUserNotificationType.Sound))
                {
                    return true;
                }
                return false;
            }
            else
            {
                UIRemoteNotificationType types = UIApplication.SharedApplication.EnabledRemoteNotificationTypes;
                if (types.HasFlag(UIRemoteNotificationType.Alert) || types.HasFlag(UIRemoteNotificationType.Badge) || types.HasFlag(UIRemoteNotificationType.Sound))
                {
                    return true;
                }
                return false;
            }
        }
    }
}
