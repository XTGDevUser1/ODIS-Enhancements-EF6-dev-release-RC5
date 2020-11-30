using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class SettingsLocation : ContentPage
    {
        MemberHelper memberHelper = new MemberHelper();
        public SettingsLocation()
        {
            InitializeComponent();

            switchLocation.IsToggled = memberHelper.CheckIsLocationAllowed();
            switchLocation.Toggled += SwitchLocation_Toggled;
        }
        private void SwitchLocation_Toggled(object sender, ToggledEventArgs e)
        {
            memberHelper.UpdateSettingsLocation(e.Value);
        }
    }
}
