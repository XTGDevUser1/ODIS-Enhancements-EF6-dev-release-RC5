using System;
using Xamarin.Forms;
using UIKit;
using Foundation;
using ODISMember.iOS.Notifications;
using ODISMember.Interfaces;

[assembly: Dependency (typeof (PushNotification))]
namespace ODISMember.iOS.Notifications
{
    public class PushNotification: IPushNotification
	{
        #region IPushNotification implementation
        public void Register (string userId)
		{
			try
			{
                if (UIDevice.CurrentDevice.CheckSystemVersion(8, 0))
                {
                    #region Confirmation Notification
                    UIMutableUserNotificationAction acceptAction = new UIMutableUserNotificationAction();
                    acceptAction.Title = "Yes";
                    acceptAction.Identifier = "ACCEPT_IDENTIFIER";
                    acceptAction.ActivationMode = UIUserNotificationActivationMode.Background;
                    acceptAction.Destructive = false;
                    acceptAction.AuthenticationRequired = false;

                    UIMutableUserNotificationAction denyAction = new UIMutableUserNotificationAction();
                    denyAction.Title = "No";
                    denyAction.Identifier = "DENY_IDENTIFIER";
                    denyAction.ActivationMode = UIUserNotificationActivationMode.Foreground;
                    denyAction.Destructive = false;
                    denyAction.AuthenticationRequired = false;

                    UIMutableUserNotificationCategory confirmationCategory = new UIMutableUserNotificationCategory();
                    confirmationCategory.Identifier = "CONFIRMATION_CATEGORY";
                    confirmationCategory.SetActions(new UIUserNotificationAction[] { acceptAction, denyAction }, UIUserNotificationActionContext.Default);
                    #endregion

                    NSSet categories = new NSSet();
                    UIUserNotificationType types = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound;
                    UIUserNotificationSettings settings = UIUserNotificationSettings.GetSettingsForTypes(types, categories);
                    UIApplication.SharedApplication.RegisterUserNotificationSettings(settings);
                    UIApplication.SharedApplication.RegisterForRemoteNotifications();
                }
                else
                {
                    UIRemoteNotificationType notificationTypes = UIRemoteNotificationType.Alert | UIRemoteNotificationType.Badge | UIRemoteNotificationType.Sound;
                    UIApplication.SharedApplication.RegisterForRemoteNotificationTypes(notificationTypes);
                }
            }
			catch (Exception e)
			{
				Console.WriteLine ("Error: "+e.InnerException.Message.ToString());
			}
		}
		#endregion		
	}
}

