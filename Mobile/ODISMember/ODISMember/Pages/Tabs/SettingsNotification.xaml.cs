using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class SettingsNotification : ContentPage
    {
        MemberHelper memberHelper = new MemberHelper();
        public SettingsNotification()
        {
            InitializeComponent();
            var settings = memberHelper.GetMemberSettings();

            switchNotification.IsToggled = settings.IsNotificationEnabled;
            switchNotification.Toggled += SwitchNotification_Toggled;
        }
        private void SwitchNotification_Toggled(object sender, ToggledEventArgs e)
        {
            memberHelper.UpdateSettingsNotification(e.Value);
        }
    }
}
