using FFImageLoading.Forms;
using ODISMember.Classes;
using ODISMember.Common;
using ODISMember.Contract;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Services.Service;
using ODISMember.Widgets;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ODISMember.Entities.Model;

using Xamarin.Forms;
using XLabs.Forms.Controls;
using static ODISMember.AppConstants;

namespace ODISMember.Pages.Tabs
{
    public partial class MyCard : ContentView, ITabView
    {
        BaseContentPage Parent;
        public LoggerHelper logger = new LoggerHelper();
        public MyCard(BaseContentPage parent)
        {
            InitializeComponent();
            //tracking page view
            logger.TrackPageView(PageNames.MY_CARD);
            Parent = parent;

            if (!string.IsNullOrEmpty(Constants.PRODUCT_IMAGE))
            {
                productImage.Source = string.Format("{0}{1}", Global.ApplicationSettings[ApplicationSettings.PRODUCT_IMAGE_VIRTUAL_DIRECTORY_PATH], Constants.PRODUCT_IMAGE);
            }

            widgetMemberSince.ValueText = Constants.MEMBER_SUBSCRIPTION_START_DATE;
            if (Global.CurrentAssociateMember != null)
            {
                widgetMemberNumber.ValueText = Global.CurrentAssociateMember.MemberNumber;
            }
            btnRoadsideAssistancePhoneNumber.Text = GetFormatedPhoneNumber(Constants.DISPATCH_PHONE_NUMBER);
            btnMembershipServicePhoneNumber.Text = GetFormatedPhoneNumber(Constants.MEMBER_SERVICE_PHONE_NUMBER);

            lblFooter.Text = string.Format("Benefits and Services provided by {0}. Please see Membership Guidelines at the end of this guide for service terms and for other matters that apply to specific states.", Constants.ORGANIZATION_NAME);

            btnMembershipServicePhoneNumber.Clicked += BtnMembershipServicePhoneNumber_Clicked;
            btnRoadsideAssistancePhoneNumber.Clicked += BtnRoadsideAssistancePhoneNumber_Clicked;
        }

        private void BtnRoadsideAssistancePhoneNumber_Clicked(object sender, EventArgs e)
        {
            if (!string.IsNullOrEmpty(btnRoadsideAssistancePhoneNumber.Text))
            {
                DailNumber(btnRoadsideAssistancePhoneNumber.Text);
            }
        }

        private void BtnMembershipServicePhoneNumber_Clicked(object sender, EventArgs e)
        {
            if (!string.IsNullOrEmpty(btnMembershipServicePhoneNumber.Text))
            {
                DailNumber(btnMembershipServicePhoneNumber.Text);
            }
        }
        async void DailNumber(string number)
        {
            Dictionary<Plugin.Permissions.Abstractions.Permission, Plugin.Permissions.Abstractions.PermissionStatus> permissions = await Plugin.Permissions.CrossPermissions.Current.RequestPermissionsAsync(new[] { Plugin.Permissions.Abstractions.Permission.Phone });
            if (permissions[Plugin.Permissions.Abstractions.Permission.Phone] == Plugin.Permissions.Abstractions.PermissionStatus.Granted)
            {
                DependencyService.Get<IPhoneCall>().MakeQuickCall(number);
            }
            else
            {
                bool result = await Parent.DisplayAlert("", "Turn on call phone permissions in the Settings to allow Roadside to make a call", "Go To Settings", "Cancel");
                if (result)
                {
                    DependencyService.Get<Interfaces.IOpenSettings>().Opensettings();
                }
            }
        }
        public string Title
        {
            get
            {
                return "My Card";
            }
        }

        public void InitializeToolbar()
        {
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }

        public string GetFormatedPhoneNumber(string PhoneNumber)
        {
            if (!string.IsNullOrEmpty(PhoneNumber))
            {
                return String.Format("{0:(###) ###-####}", double.Parse(PhoneNumber));
            }
            else
            {
                return string.Empty;
            }
        }


    }
}
