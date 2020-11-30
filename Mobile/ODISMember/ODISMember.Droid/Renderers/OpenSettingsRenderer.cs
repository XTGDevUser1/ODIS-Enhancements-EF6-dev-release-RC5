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
using ODISMember.Interfaces;
using Xamarin.Forms;
using ODISMember.Droid.Renderers;
using Android.Provider;
using System.Runtime.Remoting.Contexts;

[assembly: Dependency(typeof(OpenSettingsRenderer))]
namespace ODISMember.Droid.Renderers
{
    class OpenSettingsRenderer : IOpenSettings
    {
        public void Opensettings()
        {

            Global.IsGotoSetting = true;
            Intent i = new Intent();
            i.SetAction(Android.Provider.Settings.ActionApplicationDetailsSettings);
            i.AddCategory(Intent.CategoryDefault);
            i.SetData(Android.Net.Uri.Parse("package:" + Xamarin.Forms.Forms.Context.PackageName));
            i.AddFlags(ActivityFlags.NewTask);
            i.AddFlags(ActivityFlags.NoHistory);
            i.AddFlags(ActivityFlags.ExcludeFromRecents);
            Xamarin.Forms.Forms.Context.StartActivity(i);
        }
    }
}