using ODISMember.Classes;
using ODISMember.Common;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;

using Xamarin.Forms;
using ODISMember.Pages.Tabs;
using FFImageLoading.Forms;
using FFImageLoading.Work;
using FFImageLoading.Transformations;
using System.IO;
using ODISMember.Entities;

namespace ODISMember.Pages.Tabs
{
    public partial class Settings : ContentView, ITabView
    {
        BaseContentPage Parent;
      
        MemberHelper memberHelper = new MemberHelper();
        LoggerHelper logger = new LoggerHelper();
        public Settings(BaseContentPage parent)
        {
            InitializeComponent();
            Parent = parent;
           
            var settings = memberHelper.GetMemberSettings();
            if (settings != null)
            {
                switchLocateMe.IsToggled = settings.IsLocationAllowed;
                switchPushNotification.IsToggled = settings.IsNotificationEnabled;
            }

            switchLocateMe.Toggled += SwitchLocateMe_Toggled;
            switchPushNotification.Toggled += SwitchPushNotification_Toggled;
            btnLogs.Clicked += BtnLogs_Clicked;

           
        }
       
        private void SwitchPushNotification_Toggled(object sender, ToggledEventArgs e)
        {
            memberHelper.UpdateSettingsNotification(e.Value);
        }

        private void SwitchLocateMe_Toggled(object sender, ToggledEventArgs e)
        {
            memberHelper.UpdateSettingsLocation(e.Value);
        }

        private void BtnMembershipPlan_Clicked(object sender, EventArgs e)
        {
            //throw new NotImplementedException();
        }

        private void BtnLogs_Clicked(object sender, EventArgs e)
        {
            Parent.Navigation.PushAsync(new Loging());
        }

        private void BtnEditMember_Clicked(object sender, EventArgs e)
        {
            Parent.Navigation.PushAsync(new EditAccount());
        }

        private void BtnMembers_Clicked(object sender, EventArgs e)
        {
            Parent.Navigation.PushAsync(new MemberAssociates());
        }

        public string Title
        {
            get
            {
                return "Settings";
            }
        }

        public void InitializeToolbar()
        {
            //throw new NotImplementedException();
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }
    }
}

