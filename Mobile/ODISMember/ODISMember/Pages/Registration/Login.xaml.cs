using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using ODISMember.Behaviors;
using ODISMember.Widgets;
using ODISMember.Entities;
using Plugin.Toasts;
//using AI.XamarinSDK.Abstractions;
using ODISMember.Services.Service;
using ODISMember.CustomControls;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Shared;
using ODISMember.Interfaces;
using Newtonsoft.Json;
using ODISMember.Entities.Model;
using ODISMember.Entities.Table;
using ODISMember.Data;
using System.IO;
using System.Reflection;
using ODISMember.Pages.Tabs;

namespace ODISMember.Pages.Registration
{
    public partial class Login : BaseContentPage
    {
        LoggerHelper logger = new LoggerHelper();
       
        public Login()
        {
            InitializeComponent();
            logger.TrackPageView(PageNames.LOGIN);
            NavigationPage.SetHasNavigationBar(this, false);
            EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            btnLogin.Clicked += BtnLogin_Clicked;
            btnSendUserName.Clicked += BtnSendUserName_Clicked;
            btnForgotPwd.Clicked += BtnForgotPwd_Clicked;
            btnTermsAndConditions.Clicked += BtnTermsAndConditions_Clicked;
            btnRegister.Clicked += BtnRegister_Clicked;
            btnJoin.Clicked += BtnJoin_Clicked;
            widgetUserName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetPassword.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());

            #if DEBUG
            widgetUserName.EntryText = "pmctest";
            widgetPassword.EntryText = "Password1";
            #endif

            Content = CreateLoadingIndicatorRelativeLayout(mainLayout);
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.CALL_SCREENSHOOT)
            {
                //if (!Global.IsFeedBackPageActive )
                //{
                    Global.IsFeedBackPageActive = true;
                    byte[] ScreenShot = DependencyService.Get<IScreenshotManager>().CaptureAsync();
                    Navigation.PushAsync(new FeedBack(ScreenShot));
                }
            //}
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
        }
        private void BtnJoin_Clicked(object sender, EventArgs e)
        {
            Device.OpenUri(new Uri("https://www.pinnaclemotorclub.com/pmcmobile/"));
        }

        private void BtnTermsAndConditions_Clicked(object sender, EventArgs e)
        {
            Navigation.PushAsync(new TermsAndConditions());
        }

        private void BtnRegister_Clicked(object sender, EventArgs e)
        {
            Navigation.PushAsync(new RegisterVerify());
        }

        void BtnSendUserName_Clicked(object sender, EventArgs e)
        {
            Navigation.PushAsync(new ForgotUserName());
        }

        async void BtnLogin_Clicked(object sender, EventArgs e)
        {
            widgetUserName.onValidate();
            widgetPassword.onValidate();

            if (widgetUserName.IsValid && widgetPassword.IsValid)
            {
                HUD load = new HUD("Loading...");
                MemberHelper memberHelper = new MemberHelper();
                AccessResult accessResult = await memberHelper.Login(widgetUserName.EntryValue.Text, widgetPassword.EntryValue.Text);
                if (accessResult != null && accessResult.Status == OperationStatus.SUCCESS)
                {
                    //Adding logged in username to constants
                    Constants.USER_NAME = widgetUserName.EntryValue.Text;

                    //register the device: Fully Async process, no need of await
                    memberHelper.DeviceRegister();

                    Navigation.PushAsync(new DataInitializing());
                    load.Dismiss();
                    logger.SetIdentity(Constants.MEMBER_NUMBER);
                }
                else
                {
                    logger.Result(accessResult);
                    load.Dismiss();
                    ToastHelper.ShowErrorToast("Error", accessResult.ErrorMessage);
                }
            }
        }


        void BtnForgotPwd_Clicked(object sender, EventArgs e)
        {
            Navigation.PushAsync(new ForgotPassword());
        }

        void BtnSignUp_Clicked(object sender, EventArgs e)
        {
            Navigation.PushAsync(new Membership());
        }

       
    }
}
