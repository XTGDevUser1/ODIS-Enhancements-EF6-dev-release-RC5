using ODISMember.Common;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using ODISMember.Entities.Model;
using ODISMember.Entities;
using Newtonsoft.Json;
using XLabs.Forms.Controls;
using ODISMember.Classes;
using ODISMember.Helpers.UIHelpers;
using ODISMember.CustomControls;
using ODISMember.Services.Service;
using ODISMember.Shared;
using System.Diagnostics;

namespace ODISMember.Pages.Tabs
{
    public partial class Account : ContentView, ITabView
    {
        public bool isItemSelected = false;
        BaseContentPage Parent;
        LoggerHelper logger = new LoggerHelper();
        RangeEnabledObservableCollection<Associate> ObservableAssociates;

        public Account(BaseContentPage parent)
        {
            InitializeComponent();
            ObservableAssociates = new RangeEnabledObservableCollection<Associate>();
            logger.TrackPageView(PageNames.ACCOUNT);
            this.Parent = parent;

            if ((!Constants.IS_SHOW_MEMBER_LIST)||(!Constants.IS_SHOW_ADD_MEMBER))
            {
                stackMembersList.HeightRequest = 0;
                stackMembersList.IsVisible = false;
            }
            else
            {
                MembersList.ItemTemplate = new DataTemplate(typeof(MemberCellLayout));
                MembersList.ItemsSource = ObservableAssociates;
                MembersList.ItemSelected += MembersList_ItemSelected;
            }
            if (Constants.IS_MASTER_MEMBER && Constants.IS_SHOW_MEMBER_LIST && Constants.IS_SHOW_ADD_MEMBER)
            {
                btnAddMember.Clicked += BtnAddMember_Clicked;
            }
            else
            {
                stackAddMember.HeightRequest = 0;
                stackAddMember.IsVisible = false;
            }
            LoadData(Global.CurrentMember);
            LoadAssociates();
            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;

            }
        }

        private void LoadAssociates()
        {
            if (Global.CurrentAssociateMembers.Count > 0)
            {
                ObservableAssociates.Clear();
                ObservableAssociates.InsertRange(Global.CurrentAssociateMembers);
                MembersList.HeightRequest = 50 * (ObservableAssociates.Count + 1);
            }
            else {
                ObservableAssociates.Clear();
            }
        }

        private void BtnAddMember_Clicked(object sender, EventArgs e)
        {
            Parent.Navigation.PushAsync(new AddMemberAssociate());
        }

        async void MembersList_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (!isItemSelected)
            {
                isItemSelected = true;
                if (e.SelectedItem != null)
                {
                    Associate selectedAssociateMember = e.SelectedItem as Associate;
                    await Parent.Navigation.PushAsync(new ProfileView(selectedAssociateMember));
                }
                isItemSelected = false;

            }
            MembersList.SelectedItem = null;
        }





        protected void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.REFRESH_CURRENT_MEMBER_DETAILS)
            {
                LoadData(Global.CurrentMember);
            }
            if (e.EventId == AppConstants.Event.REFRESH_MEMBERS)
            {
                LoadAssociates();
            }
        }

        public string Title
        {
            get { return "Account"; }
        }
        private void LoadData(AccountModel member)
        {

            if (member != null)
            {

                widgetMembershipPlan.ValueText = Constants.MEMBER_PLAN_NAME;
                if (member != null && member.MasterMember != null)
                {
                    widgetMemberShipNumber.ValueText = member.MembershipNumber;
                }
                widgetExpires.ValueText = member.ExpirationDateString;

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

            }
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }

        public void InitializeToolbar()
        {
            if (Constants.IS_MASTER_MEMBER)
            {
                Menu menu = new Menu();
                menu.Priority = 0;
                menu.Name = "Edit";
                menu.ToolbarItemOrder = 0;
                menu.ActionOnClick += OpenEditAccount;
                CommonMenu.CreateMenu(Parent, menu);
            }
        }

        private void OpenEditAccount()
        {
            Parent.Navigation.PushAsync(new EditAccount());
        }
    }
}
