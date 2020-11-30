using System;
using System.Collections.Generic;
using Gcm.Client;
using Xamarin.Forms;
using ODISMember.Droid.Notifications;
using ODISMember.Interfaces;

[assembly: Dependency (typeof (PushNotification))]
namespace ODISMember.Droid.Notifications
{
	public class PushNotification: IPushNotification
	{
		#region IPushNotification implementation
		public void Register (string userId)
		{
			try
			{
                // Check to ensure everything's set up right
                GcmClient.CheckDevice(MainActivity.CurrentActivity);
                GcmClient.CheckManifest(MainActivity.CurrentActivity);

                // Register for push notifications                
                GcmClient.Register(MainActivity.CurrentActivity, ODISMember.Entities.Constants.GOOGLE_API_PROJECT_NUMBER);
            }
			catch (Java.Net.MalformedURLException)
			{
				Console.WriteLine ("There was an error creating the Mobile Service. Verify the URL");
			}
			catch (Exception e)
			{
				//Console.WriteLine ("Error: "+e.InnerException.Message.ToString());
			}
		}
		#endregion		
	}
}

