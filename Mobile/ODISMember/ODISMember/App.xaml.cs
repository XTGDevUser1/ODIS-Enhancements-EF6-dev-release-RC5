using ODISMember.Pages;
using ODISMember.Pages.Registration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using TK.CustomMap.Api.Google;
using ODISMember.Data;
using ODISMember.Entities.Model;
using ODISMember.Shared;
using ODISMember.Entities;
using ODISMember.Common;
using ODISMember.Helpers.UIHelpers;
using Plugin.Connectivity;

namespace ODISMember
{
    public partial class App : Application
    {
        public IHUDProvider _hud;
        public static double ScreenHeight;
        public static double ScreenWidth;
        MemberHelper memberHelper = new MemberHelper();
        public IHUDProvider Hud
        {
            get
            {
                return _hud ?? (_hud = DependencyService.Get<IHUDProvider>());
            }
        }

        public new static App Current
        {
            get
            {
                return (App)Application.Current;
            }
        }

        public App()
        {
            CrossConnectivity.Current.ConnectivityChanged += (sender, args) =>
            {
                Constants.IS_CONNECTED = args.IsConnected;
            };
            MemberHelper helper = new MemberHelper();
            DBInitialize dbInitialize = new DBInitialize();
            InitializeComponent();
            dbInitialize.CreateTables();
            GmsDirection.Init("AIzaSyCUedxnPNmnaKSyNmCdBQUTtQizRt1jiV4");
            Constants.IS_LOGGING_ENABLED = helper.CheckIsLoggingEnabled();
            ODISBackgroundService.GetInstance().StartService();

            Task.Run(() =>
            {
                StaticDataInitializer dataInitializer = new StaticDataInitializer();
                dataInitializer.InitializeStaticData();
            });
            
            bool isValidToken = ValidateAccessToken();


            if (isValidToken)
            {
                MainPage = new RootPage(false);
            }
            else
            {
                MainPage = new NavigationPage(new Login());
            }
        }
        protected override void OnResume()
        {
            if (Global.IsGotoSetting)
            {
                Global.IsGotoSetting = false;
                EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.ADD_CURRENT_LOCATION_POINT));
            }
            base.OnResume();
        }
        /// <summary>        
        /// Verifying User already have valid access token to proceed without giving login details again.
        /// </summary>
        private bool ValidateAccessToken()
        {

            Member localMember = memberHelper.GetLocalMember();

            if (localMember != null && localMember.CreatedOn != null && !string.IsNullOrEmpty(localMember.ExpiresIn))
            {
                var expiresIn = Convert.ToDouble(localMember.ExpiresIn);

                //validating user last login time and access token expire time
                //if (last login time + token expire seconds) > CurrentTime + 24 hours, we consider token still accessible and user no need to login again
                //else we consider that token got expired and app will show login screen.
                if (localMember.CreatedOn.AddSeconds(expiresIn) > DateTime.Now.AddHours(24))
                {
                    //Assigning Static values to access through out application
                    Constants.ACCESS_TOKEN = localMember.AccessToken;
                    Constants.MEMBER_NUMBER = localMember.MemberNumber;
                    Constants.MASTER_MEMBER_NUMBER = localMember.MasterMemberNumber;
                    Constants.MEMBER_FULL_NAME = localMember.FirstName + " " + localMember.LastName;
                    Constants.MEMBER_PLAN_NAME = localMember.PlanName;
                    Constants.MEMBER_PROGRAM_ID = localMember.ProgramID;
                    Constants.MEMBER_FIRST_NAME = localMember.FirstName;
                    Constants.MEMBER_LAST_NAME = localMember.LastName;
                    Constants.MEMBER_SERVICE_PHONE_NUMBER = localMember.MemberServicePhoneNumber;
                    Constants.MEMBER_MEMBERSHIP_NUMBER = localMember.MembershipNumber;
                    Constants.IS_ACTIVE = localMember.IsActive;
                    Constants.BENEFIT_GUIDE_PDF = localMember.BenefitGuidePDF;
                    Constants.DISPATCH_PHONE_NUMBER = localMember.DispatchPhoneNumber;
                    Constants.IS_MASTER_MEMBER = localMember.IsMasterMember;
                    Constants.IS_SHOW_MEMBER_LIST = localMember.IsShowMemberList;
                    Constants.IS_SHOW_ADD_MEMBER = localMember.IsShowAddMember;
                    Constants.PRODUCT_IMAGE = localMember.ProductImage;
                    Constants.USER_NAME = localMember.UserName;
                    Constants.MEMBER_SUBSCRIPTION_START_DATE = localMember.CurrentSubscriptionStartDate.HasValue ? localMember.CurrentSubscriptionStartDate.Value.ToString(Constants.DateFormat) : string.Empty;
                    Constants.PersonID = localMember.PersonID;
                    return true;
                }
            }
            return false;
        }
    }
}
