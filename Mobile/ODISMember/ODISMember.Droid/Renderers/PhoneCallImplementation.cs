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
using ODISMember.Contract;
using Xamarin.Forms;
using ODISMember.Droid.Renderers;

[assembly: Dependency(typeof(PhoneCallImplementation))]
namespace ODISMember.Droid.Renderers
{
    public class PhoneCallImplementation : IPhoneCall
    {
        /// <summary>
        /// Used for registration with dependency service
        /// </summary>
        public static void Init() { }

        public async void MakeQuickCall(string PhoneNumber)
        {
            if (System.Text.RegularExpressions.Regex.IsMatch(PhoneNumber, "^(\\(?\\+?[0-9]*\\)?)?[0-9_\\- \\(\\)]*$"))
            {
                Intent phone = new Intent(Intent.ActionCall, Android.Net.Uri.Parse(string.Format("tel:{0}", PhoneNumber)));
                // make the voice call
                Plugin.CurrentActivity.CrossCurrentActivity.Current.Activity.StartActivity(phone);
            }
            else
            {
                new AlertDialog.Builder(Android.App.Application.Context)
                      .SetPositiveButton("OK", (sender, args) =>
                      {
                          // User pressed OK
                      })
                      .SetMessage("Please enter a valid phone number")
                      .SetTitle("Error")
                      .Show();
            }
        }
    }
}