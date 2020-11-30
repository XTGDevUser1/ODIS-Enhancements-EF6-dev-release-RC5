using ODISMember.Entities;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class Loging : ContentPage
    {
        MemberHelper memberHelper = new MemberHelper();
        public Loging()
        {
            InitializeComponent();
            switchLog.IsToggled = memberHelper.CheckIsLoggingEnabled();
            switchLog.Toggled += SwitchLog_Toggled;
            btnSendLogs.Clicked += BtnSendLogs_Clicked;
        }
        private void BtnSendLogs_Clicked(object sender, EventArgs e)
        {
            LoggerHelper logger = new LoggerHelper();
            logger.SendLog();
        }
        private void SwitchLog_Toggled(object sender, ToggledEventArgs e)
        {
            Constants.IS_LOGGING_ENABLED = e.Value;
            memberHelper.UpdateSettingsLogging(e.Value);
        }
    }
}
