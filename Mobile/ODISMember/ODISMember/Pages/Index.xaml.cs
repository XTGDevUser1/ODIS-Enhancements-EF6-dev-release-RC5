using ODISMember.Common;
using ODISMember.Pages.Tabs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Classes;
using ODISMember.Entities;
using ODISMember.Pages.Registration;
using ODISMember.Shared;
using ODISMember.Entities.Model;
using Newtonsoft.Json;
using ODISMember.Data;
using ODISMember.Interfaces;
using ODISMember.Helpers.ModelHelper;

namespace ODISMember.Pages
{
    public partial class Index : BaseContentPage
    {
        Dictionary<int, ContentView> viewCache = new Dictionary<int, ContentView>();
        MemberHelper _memberHelper = new MemberHelper();
        PushNotificationHelper pushNotificationHelper = new PushNotificationHelper();

        public Index()
        {
            InitializeComponent();
            Global.IsFeedBackPageActive = false;
            BackgroundColor = ColorResources.BackgroundColor;
            Content = CreateLoadingIndicatorRelativeLayout(relativeLayout);
            this.btnHome.Clicked += (sender, e) =>
            {
                if (this.txtHome.TextColor == ColorResources.BottomMenuTextColorSelected)
                {
                    return;
                }
                RefreshBottomWorkspace(ODISMember.AppConstants.Event.OPEN_HOME);
            };
            this.btnMyCard.Clicked += (sender, e) =>
             {
                 if (this.txtMyCard.TextColor == ColorResources.BottomMenuTextColorSelected)
                 {
                     return;
                 }
                 RefreshBottomWorkspace(ODISMember.AppConstants.Event.OPEN_MYCARD);
             };
            this.btnGetHelp.Clicked += (sender, e) =>
            {
                if (this.txtHelp.TextColor == ColorResources.BottomMenuTextColorSelected)
                {
                    return;
                }
                RefreshBottomWorkspace(ODISMember.AppConstants.Event.OPEN_GET_HELP);
            };
            this.btnBenefit.Clicked += (sender, e) =>
            {
                if (this.txtBenefits.TextColor == ColorResources.BottomMenuTextColorSelected)
                {
                    return;
                }
                RefreshBottomWorkspace(ODISMember.AppConstants.Event.OPEN_BENEFIT);
            };
            this.btnMore.Clicked += (sender, e) =>
            {
                if (this.txtMore.TextColor == ColorResources.BottomMenuTextColorSelected)
                {
                    return;
                }
                RefreshBottomWorkspace(ODISMember.AppConstants.Event.OPEN_MORE);
            };

            ShowStatusPage();

            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            }
        }

        private void ShowStatusPage()
        {
            Entities.Table.Notification localNotification = pushNotificationHelper.GetExistingNotification();
            if (localNotification != null)
            {
                NotificationData notificationData = JsonConvert.DeserializeObject<NotificationData>(localNotification.Data.ToString());
                if (notificationData != null)
                {
                    RefreshBottomWorkspace(ODISMember.AppConstants.Event.OPEN_STATUS, notificationData.ServiceRequestID);
                }
            }
            else
            {
                RefreshBottomWorkspace(ODISMember.AppConstants.Event.OPEN_HOME);
            }
        }

        protected void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == ODISMember.AppConstants.Event.OPEN_ACCOUNT ||
                e.EventId == ODISMember.AppConstants.Event.OPEN_PROFILE ||
                e.EventId == ODISMember.AppConstants.Event.OPEN_VEHICLES ||
                e.EventId == ODISMember.AppConstants.Event.OPEN_HISTORY ||
                e.EventId == ODISMember.AppConstants.Event.OPEN_HELP)
            {
                RefreshWorkspace(e.EventId);
                ResetBottomNavBar();
            }
            else if (e.EventId == ODISMember.AppConstants.Event.OPEN_SETTINGS)
            {
                DependencyService.Get<IOpenSettings>().Opensettings();
            }
            else if (e.EventId == ODISMember.AppConstants.Event.OPEN_HOME)
            {
                UpdateBottomNavBar(e.EventId);
            }
            else if (e.EventId == ODISMember.AppConstants.Event.OPEN_LOGOUT)
            {
                var result = DisplayAlert("Logout", "Do you want to logout?", "YES", "NO");
                result.ContinueWith(x =>
                {
                    if (!x.IsFaulted && x.IsCompleted)
                    {
                        if (x.Result)
                        {
                            ODISBackgroundService.GetInstance().Enqueue(() =>
                            {
                                _memberHelper.ClearMemberData();
                                Device.BeginInvokeOnMainThread(() =>
                                {
                                    App.Current.MainPage = new NavigationPage(new Login());
                                });
                            });
                        }
                        else
                        {
                            EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.RESET_LEFT_MENU));
                        }
                    }
                });
            }
            else if (e.EventId == ODISMember.AppConstants.Event.OPEN_BENEFIT ||
                e.EventId == ODISMember.AppConstants.Event.OPEN_REQUEST_SUCCESS ||
                e.EventId == ODISMember.AppConstants.Event.OPEN_STATUS)
            {
                RefreshBottomWorkspace(e.EventId, sender);
            }
            if (e.EventId == AppConstants.Event.CALL_SCREENSHOOT)
            {
                if (Global.IsFeedBackPageActive == false)
                {
                    byte[] ScreenShot = DependencyService.Get<IScreenshotManager>().CaptureAsync();
                    Global.IsFeedBackPageActive = true;
                    this.Navigation.PushAsync(new FeedBack(ScreenShot));
                }

            }
        }
        private void RefreshBottomWorkspace(int eventId, object response = null)
        {

            if (eventId == AppConstants.Event.OPEN_MORE)
            {
                EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(ODISMember.AppConstants.Event.OPEN_LEFT_MENU));
                return;
            }
            else if (eventId == AppConstants.Event.OPEN_GET_HELP)
            {
                EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(ODISMember.AppConstants.Event.RESET_LEFT_MENU));

                MemberHelper memberHelper = new MemberHelper();
                Member member = memberHelper.GetLocalMember();

                Device.BeginInvokeOnMainThread(async () =>
                {
                    using (new HUD("Checking Pending Request..."))
                    {
                        var result = await memberHelper.GetActiveRequest(member.MembershipNumber);
                        ServiceRequest serviceRequest = null;
                        if (result.Data != null)
                        {
                            serviceRequest = JsonConvert.DeserializeObject<ServiceRequest>(result.Data.ToString());
                        }
                        if (serviceRequest != null && !string.IsNullOrEmpty(serviceRequest.RequestNumber.ToString()))//TrackerID
                        {
                            UpdateBottomNavBar(AppConstants.Event.OPEN_STATUS, serviceRequest.RequestNumber.ToString());//TrackerID
                        }
                        else
                        {
                            UpdateBottomNavBar(eventId, response);
                        }
                    }
                });
            }
            else
            {
                EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(ODISMember.AppConstants.Event.RESET_LEFT_MENU));

                UpdateBottomNavBar(eventId, response);
            }
        }

        public void UpdateBottomNavBar(int eventId, object response = null)
        {
            ResetBottomNavBar();

            if (eventId == AppConstants.Event.OPEN_HOME)
            {
                //imgHome.BackgroundColor = ColorResources.BottomMenuSelectedColor;
                this.imgHome.Source = ImagePathResources.HomeBottomIconSelected;
                this.txtHome.TextColor = ColorResources.BottomMenuTextColorSelected;
            }
            else if (eventId == AppConstants.Event.OPEN_MYCARD)
            {
                //imgMyCard.BackgroundColor = ColorResources.BottomMenuSelectedColor;
                this.imgMyCard.Source = ImagePathResources.MyCardIconSelected;
                this.txtMyCard.TextColor = ColorResources.BottomMenuTextColorSelected;
            }
            else if (eventId == AppConstants.Event.OPEN_GET_HELP)
            {
                //imgGetHelp.BackgroundColor = ColorResources.BottomMenuSelectedColor;
                this.imgGetHelp.Source = ImagePathResources.GetHelpIconSelected;
                this.txtHelp.TextColor = ColorResources.BottomMenuTextColorSelected;
            }
            else if (eventId == AppConstants.Event.OPEN_REQUEST_SUCCESS || eventId == AppConstants.Event.OPEN_STATUS)
            {
                //imgGetHelp.BackgroundColor = ColorResources.BottomMenuSelectedColor;
                this.imgGetHelp.Source = ImagePathResources.GetHelpIconSelected;
                this.txtHelp.TextColor = ColorResources.BottomMenuTextColorSelected;
            }
            else if (eventId == AppConstants.Event.OPEN_BENEFIT)
            {
                //imgBenefit.BackgroundColor = ColorResources.BottomMenuSelectedColor;
                this.imgBenefit.Source = ImagePathResources.BenefitBottomIconSelected;
                this.txtBenefits.TextColor = ColorResources.BottomMenuTextColorSelected;
            }
            RefreshWorkspace(eventId, response);
        }

        public void ResetBottomNavBar()
        {
            this.imgHome.BackgroundColor = this.imgBenefit.BackgroundColor = this.imgGetHelp.BackgroundColor = this.imgMore.BackgroundColor = this.imgMyCard.BackgroundColor = Color.Transparent;
            this.imgHome.Source = ImagePathResources.HomeBottomIcon;
            this.imgBenefit.Source = ImagePathResources.BenefitBottomIcon;
            this.imgGetHelp.Source = ImagePathResources.GetHelpIcon;
            this.imgMore.Source = ImagePathResources.MoreIcon;
            this.imgMyCard.Source = ImagePathResources.MyCardIcon;

            this.txtHome.TextColor = this.txtBenefits.TextColor = this.txtHelp.TextColor = this.txtMyCard.TextColor = this.txtMore.TextColor = ColorResources.BottomMenuTextColor;
        }

        private void RefreshWorkspace(int source, object response = null)
        {
            workArea.Children.Clear();
            if (source == AppConstants.Event.OPEN_HOME)
            {
                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new Home(this));
                }
                else
                {
                    viewCache.Remove(source);
                    viewCache.Add(source, new Home(this));
                }
            }
            else if (source == AppConstants.Event.OPEN_MYCARD)
            {
                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new MyCard(this));
                }
            }
            else if (source == AppConstants.Event.OPEN_GET_HELP)
            {
                if (!viewCache.ContainsKey(source))
                {
                    if (Constants.IS_ACTIVE)
                    {
                        viewCache.Add(source, new ODISMember.Pages.Tabs.Roadside(this));
                    }
                    else
                    {
                        viewCache.Add(source, new ODISMember.Pages.Tabs.MemberInActive(this));
                    }
                }
                else
                {

                    if (Constants.IS_ACTIVE)
                    {
                        viewCache.Remove(source);
                        viewCache.Add(source, new ODISMember.Pages.Tabs.Roadside(this));
                    }
                }
            }
            else if (source == AppConstants.Event.OPEN_BENEFIT)
            {
                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new Benefits(this));
                }
            }
            else if (source == AppConstants.Event.OPEN_ACCOUNT)
            {
                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new Account(this));
                }
            }
            else if (source == AppConstants.Event.OPEN_PROFILE)
            {

                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new Profile(this, Global.CurrentAssociateMember));
                }
                else
                {
                    viewCache.Remove(source);
                    viewCache.Add(source, new Profile(this, Global.CurrentAssociateMember));
                }
            }
            else if (source == AppConstants.Event.OPEN_VEHICLES)
            {
                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new Vehicles(this));
                }
                else
                {
                    viewCache.Remove(source);
                    viewCache.Add(source, new Vehicles(this));
                }
            }
            else if (source == AppConstants.Event.OPEN_HELP)
            {
                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new Help(this));
                }
                EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(AppConstants.Event.REFRESH_HELP));
            }
            else if (source == AppConstants.Event.OPEN_STATUS)
            {
                string serviceRequestID = string.Empty;
                if (response != null)
                {
                    serviceRequestID = response.ToString();
                }

                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new RoadsideRequestStatusView(this, serviceRequestID));
                }
                else
                {
                    viewCache.Remove(source);
                    viewCache.Add(source, new RoadsideRequestStatusView(this, serviceRequestID));
                }
            }
            else if (source == AppConstants.Event.OPEN_HISTORY)
            {
                if (!viewCache.ContainsKey(source))
                {
                    viewCache.Add(source, new History(this));
                }
                else
                {
                    viewCache.Remove(source);
                    viewCache.Add(source, new History(this));
                }
            }
            CurrentActiveTab = source;
            workArea.Children.Add(viewCache[source]);
            var tabView = viewCache[source] as ITabView;
            tabView.ResetToolbar();
            tabView.InitializeToolbar();
            this.Title = tabView.Title;
        }
    }
}
