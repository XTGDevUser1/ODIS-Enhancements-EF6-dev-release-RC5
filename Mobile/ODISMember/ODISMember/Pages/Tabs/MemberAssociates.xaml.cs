using Newtonsoft.Json;
using ODISMember.Classes;
using ODISMember.Entities;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Services.Service;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class MemberAssociates : BaseContentPage
    {
        LoggerHelper logger = new LoggerHelper();
        RangeEnabledObservableCollection<Associate> mAssociates;
        public bool isItemSelected = false;
        public MemberAssociates()
        {
            InitializeComponent();

            //tracking page view
            logger.TrackPageView(PageNames.ACCOUNT_MEMBERS);

            Title = "Members";
            mAssociates = new RangeEnabledObservableCollection<Associate>();
            if (Constants.IS_MASTER_MEMBER)
            {
                Menu menu = new Menu();
                menu.Icon = ImagePathResources.AddIcon;
                menu.Priority = 0;
                menu.Name = "Add";
                menu.ToolbarItemOrder = 0;
                menu.ActionOnClick += openMemberAssociateAdd;
                CommonMenu.CreateMenu(this, menu);
            }
            Content = CreateLoadingIndicatorRelativeLayout(mainLayout);
            listAssociates.ItemsSource = mAssociates;

            AssignData(Global.CurrentAssociateMembers);

            listAssociates.ItemSelected += ListAssociates_ItemSelected;

            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            }
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.START_REFRESH_MEMBERS_SYNC)
            {
                Device.BeginInvokeOnMainThread(() =>
                {
                    stackSync.IsVisible = true;
                });
            }
            if (e.EventId == AppConstants.Event.REFRESH_MEMBERS)
            {
                AssignData(Global.CurrentAssociateMembers);
            }
        }

        public void openMemberAssociateAdd()
        {
            Navigation.PushAsync(new AddMemberAssociate());
        }
        private async void ListAssociates_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null && !isItemSelected)
            {
                isItemSelected = true;
                Associate associate = (Associate)e.SelectedItem;
                await Navigation.PushAsync(new MemberAssociateDetails(associate));
            }
            listAssociates.SelectedItem = null;
            isItemSelected = false;
        }

        public async void LoadMembers(bool isLoading = true)
        {
            MemberHelper memberHelper = new MemberHelper();
            HUD hud;
            List<Associate> associates = null;

            //starting loading indicator
            hud = new HUD("Loading...");

            OperationResult operationResult = await memberHelper.GetMembers();
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                associates = JsonConvert.DeserializeObject<List<Associate>>(operationResult.Data.ToString());
                if (associates != null)
                {
                    if (Global.CurrentAssociateMembers != null)
                    {
                        Global.CurrentAssociateMembers.Clear();
                    }
                    foreach (var item in associates)
                    {
                        if (!string.IsNullOrEmpty(item.DateOfBirth) && (Convert.ToDateTime(item.DateOfBirth).Date == Convert.ToDateTime(Constants.DefaultAptifyDate).Date))
                        {
                            item.DateOfBirth = string.Empty;
                        }
                        Global.CurrentAssociateMembers.Add(item);
                    }
                }
                AssignData(Global.CurrentAssociateMembers);
            }

            hud.Dismiss();
        }

        private void AssignData(List<Associate> associates)
        {
            Device.BeginInvokeOnMainThread(() =>
            {

                if (associates != null)
                {

                    lblNoRecords.IsVisible = false;
                    mAssociates.Clear();
                    mAssociates.InsertRange(associates);
                }
                else
                {
                    listAssociates.IsVisible = false;
                }
                stackSync.IsVisible = false;
            });
        }
    }
}
