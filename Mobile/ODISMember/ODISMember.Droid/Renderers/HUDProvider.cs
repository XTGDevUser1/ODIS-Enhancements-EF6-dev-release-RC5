using ODISMember.Droid;
using ODISMember.Shared;
using System;
using Xamarin.Forms;

[assembly: Dependency(typeof(HUDProvider))]

namespace ODISMember.Droid
{
    public class HUDProvider : IHUDProvider
    {
        public void DisplayProgress(string message)
        {
            AndroidHUD.AndHUD.Shared.Show(Forms.Context, message);
        }

        public void DisplaySuccess(string message)
        {
            AndroidHUD.AndHUD.Shared.ShowSuccess(Forms.Context, message, AndroidHUD.MaskType.Black, TimeSpan.FromSeconds(1));
        }

        public void DisplayError(string message)
        {
            AndroidHUD.AndHUD.Shared.ShowError(Forms.Context, message, AndroidHUD.MaskType.Black, TimeSpan.FromSeconds(1));
        }

        public void Dismiss()
        {
            AndroidHUD.AndHUD.Shared.Dismiss(Forms.Context);
        }
    }
}