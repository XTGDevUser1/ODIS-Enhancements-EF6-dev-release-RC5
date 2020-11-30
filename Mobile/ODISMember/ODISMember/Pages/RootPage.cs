using System;
using Xamarin.Forms;
using ODISMember.Model;
using ODISMember.Classes;
using ODISMember.Helpers.UIHelpers;
using System.Threading.Tasks;
using ODISMember.Pages.Registration;
using ODISMember.Entities;
using ODISMember.Common;
using ODISMember.Interfaces;

namespace ODISMember.Pages
{
    public class RootPage : Xamarin.Forms.MasterDetailPage
    {
        CustomMenuItem oldSelected = null;
        MenuPage menuPage;
        MemberHelper memberHelper = new MemberHelper();
        StaticDataInitializer staticDataInitializer = new StaticDataInitializer();
        static NavigationPage NavigationStack;

        public static Action PopModal
        {
            get
            {
                return new Action(() => {                    
                    NavigationStack.Navigation.PopModalAsync();
                });
            }
        }

        public RootPage(bool isFreshUser)
        {
            //remove all the delegates
            //this should be the first statement
            EventDispatcher.RemoveAllDelegates();
            PushNotificationRegister();
            menuPage = new MenuPage();

            //menuPage.TopMenu.ItemSelected -= (sender, e) => NavigateTo(e.SelectedItem as CustomMenuItem);
            //menuPage.TopMenu.ItemSelected += (sender, e) => {
            //    NavigateTo(e.SelectedItem as CustomMenuItem);
            //};

            menuPage.TopMenu.ItemTapped -= TopMenu_ItemTapped;
            menuPage.TopMenu.ItemTapped += TopMenu_ItemTapped;

            Master = menuPage;
            NavigationStack = new NavigationPage(new Index());
            Detail = NavigationStack;            

            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            }
            Global.GetAllMembers();
            Global.GetMembership();
            Global.GetApplicationSettings();

            if (!isFreshUser)
            {
                GetDataFromServer();
            }
           
        }
        /// <summary>
        /// Register the current device to get Push notifications
        /// </summary>
        private void PushNotificationRegister()
        {
            var pushNotifiation = DependencyService.Get<IPushNotification>();
            pushNotifiation.Register(Constants.USER_NAME);
        }
        public void GetDataFromServer()
        {
            staticDataInitializer.UpdateMembers();
            staticDataInitializer.UpdateMembership();
        }
        private void TopMenu_ItemTapped(object sender, ItemTappedEventArgs e)
        {
            CustomMenuItem newSelected = (CustomMenuItem)e.Item;

            if (oldSelected == null || newSelected.Id != oldSelected.Id)
            {
                oldSelected = newSelected;
                NavigateTo(newSelected);
            }
            else
            {
                menuPage.TopMenu.SelectedItem = oldSelected;
                this.IsPresented = false;
            }
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.OPEN_LEFT_MENU)
            {
                this.IsPresented = true;
            }
            if (e.EventId == AppConstants.Event.RESET_LEFT_MENU)
            {
                oldSelected = null;
            }
            if (e.EventId == AppConstants.Event.MEMBER_DATA_UPDATED_LOCALLY)
            {
                Global.GetAllMembers();
            }
            if (e.EventId == AppConstants.Event.MEMBERSHIP_DATA_UPDATED_LOCALLY)
            {
                Global.GetMembership();
            }
            if (e.EventId == AppConstants.Event.APPLICATION_SETTINGS_DATA_UPDATED_LOCALLY)
            {
                Global.GetApplicationSettings();
            }

        }

        void NavigateTo(CustomMenuItem menu)
        {
            if (menu != null)
            {
                if (menu.EventId == AppConstants.Event.OPEN_ACCOUNT ||
                    menu.EventId == AppConstants.Event.OPEN_PROFILE ||
                    menu.EventId == AppConstants.Event.OPEN_VEHICLES ||
                    menu.EventId == AppConstants.Event.OPEN_HISTORY ||
                    menu.EventId == AppConstants.Event.OPEN_SETTINGS ||
                    menu.EventId == AppConstants.Event.OPEN_HELP ||
                    menu.EventId == AppConstants.Event.OPEN_LOGOUT)
                    IsPresented = false;

                EventDispatcher.RaiseEvent(null, new RefreshEventArgs(menu.EventId));
            }
        }
        protected override void OnAppearing()
        {
            Global.RemovePages(this);
            base.OnAppearing();
        }
    }
}

