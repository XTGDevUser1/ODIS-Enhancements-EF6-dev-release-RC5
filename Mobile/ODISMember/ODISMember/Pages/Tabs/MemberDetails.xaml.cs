using ODISMember.Classes;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Services.Service;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class MemberDetails : ContentPage
    {
        AccountModel mMember;
        LoggerHelper logger = new LoggerHelper();
        public MemberDetails(AccountModel member)
        {
            InitializeComponent();
            Title = "Membership";
            mMember = member;
            //tracking page view
            logger.TrackPageView(PageNames.ACCOUNT_MEMBERSHIP_DETAILS);

            LoadData(member);

            if (Constants.IS_MASTER_MEMBER)
            {
                Menu menu = new Menu();
                menu.Icon = ImagePathResources.EditIcon;
                menu.Priority = 0;
                menu.Name = "Edit";
                menu.ToolbarItemOrder = 0;
                menu.ActionOnClick += openMemberEdit;
                CommonMenu.CreateMenu(this, menu);
            }

            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            }
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if(e.EventId == AppConstants.Event.REFRESH_MEMBERSHIP_DETAILS)
            {
                LoadData(sender as AccountModel);
            }
            if (e.EventId == AppConstants.Event.REFRESH_CURRENT_MEMBER_DETAILS)
            {
                LoadData(Global.CurrentMember);
            }
        }

        public void LoadData(AccountModel member)
        {
            Device.BeginInvokeOnMainThread(() =>
            {
                if (member != null)
                {
                  
                    lblExpiration.Text = "Expires: " + member.ExpirationDateString;
                    lblPlanName.Text = "Plan: " + Constants.MEMBER_PLAN_NAME;

                    if (member.MasterMember != null)
                    {
                        lblDOB.Text = member.MasterMember.DateOfBirthStringWithTitle;
                        lblFullName.Text = member.MasterMember.FullName;
                    }

                    if (member.Addresses != null && member.Addresses.Count > 0)
                    {
                        lblAddress1.Text = member.Addresses[0].Address1;
                        lblAddress2.Text = member.Addresses[0].Address2;
                        if (string.IsNullOrEmpty(member.Addresses[0].Address2))
                        {
                            lblAddress2.IsVisible = false;
                        }

                        lblCityStateProvince.Text = member.Addresses[0].AddressLineString2 + " " + member.Addresses[0].CountryCode;// countryCode;
                    }
                    if (member.PhoneNumbers != null && member.PhoneNumbers.Count > 0)
                    {
                        lblCellPhone.Text = member.PhoneNumbers[0].PhoneString;
                    }
                    lblEmail.Text = member.EmailAddress;
                }
            });
           
        }
        public void openMemberEdit()
        {
            Navigation.PushAsync(new EditAccount());
        }
    }
}
