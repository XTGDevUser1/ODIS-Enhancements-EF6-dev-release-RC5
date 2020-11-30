using ODISMember.Entities;
using ODISMember.Pages.Walkthrough;
using ODISMember.Shared;

using Xamarin.Forms;

namespace ODISMember.Pages.Registration
{
    public partial class DataInitializing : ContentPage
    {
        private MemberHelper memberHelper = new MemberHelper();

        public DataInitializing()
        {
            InitializeComponent();
            NavigationPage.SetHasNavigationBar(this, false);
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            InitializeApp();
        }

        /// <summary>
        /// Initializes the application.
        /// </summary>
        private async void InitializeApp()
        {
            using (new HUD("Loading Membership and Members Data..."))
            {
                await memberHelper.GetMembership();
                await memberHelper.GetMembers();
            }
            SettingsTable setting = memberHelper.GetSettings();
            if (setting.IsWalkthroughShown)
            {
                App.Current.MainPage = new RootPage(true);
            }
            else
            {
                await Navigation.PushAsync(new IntraductionPage());
            }
        }
    }
}