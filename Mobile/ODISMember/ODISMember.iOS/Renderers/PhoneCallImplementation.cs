using Foundation;
using ODISMember.Contract;
using ODISMember.iOS.Renderers;
using System;
using System.Collections.Generic;
using System.Text;
using UIKit;
using Xamarin.Forms;
using System.Text.RegularExpressions;

[assembly: Dependency(typeof(PhoneCallImplementation))]
namespace ODISMember.iOS.Renderers
{
    public class PhoneCallImplementation : IPhoneCall
    {
        public static void Init() { }
        public async void MakeQuickCall(string PhoneNumber)
        {
            if (!string.IsNullOrEmpty(PhoneNumber))
            {
                
                    PhoneNumber = Regex.Replace(PhoneNumber, @"\s", "");
                    PhoneNumber = PhoneNumber.Replace("%20", string.Empty);
                
            }

            if (System.Text.RegularExpressions.Regex.IsMatch(PhoneNumber, "^(\\(?\\+?[0-9]*\\)?)?[0-9_\\- \\(\\)]*$"))
            {
                NSUrl url = new NSUrl(string.Format(@"telprompt://{0}", PhoneNumber));
                UIApplication.SharedApplication.OpenUrl(url);
            }
            else
            {
                UIAlertView alert = new UIAlertView();
                alert.Title = "Error";
                alert.AddButton("OK");
                alert.Message = "Please enter a valid phone number";
                alert.Show();
            }
        }
    }
}
