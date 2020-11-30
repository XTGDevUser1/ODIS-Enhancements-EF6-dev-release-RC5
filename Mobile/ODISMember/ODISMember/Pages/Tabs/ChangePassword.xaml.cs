using Newtonsoft.Json;
using ODISMember.Behaviors;
using ODISMember.Classes;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
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
    public partial class ChangePassword : CustomContentPage
    {
        LoggerHelper logger = new LoggerHelper();
        private MemberHelper memberServiceHelper = null;
        Associate associate;
        #region Properties
        private MemberHelper MemberServiceHelper
        {
            get
            {
                if (memberServiceHelper != null)
                {
                    return memberServiceHelper;
                }

                memberServiceHelper = new MemberHelper();

                return memberServiceHelper;
            }
        }
        #endregion
        public ChangePassword(Associate member)
        {
            InitializeComponent();
            associate = member;
            //tracking page view
            logger.TrackPageView(PageNames.ACCOUNT_CHANGE_PASSWORD);
            widgeCurrentPassword.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetNewPassword.Behaviors.Add(new PasswordBehavior_LabelEntryVertical() { IsRequired = true });
            widgetConfirmPassword.Behaviors.Add(new ConfirmPasswordBehavior_LabelEntryVertical(widgetNewPassword) { IsRequired = true });
            string title = "Change Password";
            if (Device.OS == TargetPlatform.Android)
            {
                NavigationPage.SetHasNavigationBar(this, false);
                CustomActionBar customActionBar = new CustomActionBar(title);
                stackCustomActionBar.Children.Add(customActionBar);
                customActionBar.OnCloseClick += CustomActionBar_OnCloseClick;
                customActionBar.OnDoneClick += CustomActionBar_OnDoneClick;
            }
            else if (Device.OS == TargetPlatform.iOS)
            {
                stackActionBar.HeightRequest = 0;
                Title = title;

                Menu menuDone = new Menu();
                menuDone.Priority = 0;
                menuDone.Name = "Done";
                menuDone.ActionOnClick += changePassword;
                CommonMenu.CreateMenu(this, menuDone);

                Menu menuCancel = new Menu();
                menuCancel.Priority = 1;
                menuCancel.Name = "Cancel";
                menuCancel.ActionOnClick += closeCurrentPage;
                CommonMenu.CreateMenu(this, menuCancel);
            }
        }
        private void CustomActionBar_OnDoneClick(object sender, EventArgs e)
        {
            changePassword();
        }

        private void CustomActionBar_OnCloseClick(object sender, EventArgs e)
        {
            closeCurrentPage();
        }
        private void closeCurrentPage()
        {
            Navigation.PopAsync();
        }
        async void changePassword()
        {
            widgeCurrentPassword.onValidate();
            widgetNewPassword.onValidate();
            widgetConfirmPassword.onValidate();
            if (widgeCurrentPassword.IsValid && widgetNewPassword.IsValid && widgetConfirmPassword.IsValid)
            {
                using (new HUD("Changing Password..."))
                {
                    RegisterSendModel registerSendModel = new RegisterSendModel();
                    registerSendModel.OldPassword = widgeCurrentPassword.EntryText;
                    registerSendModel.ObjWebUser = new RegisterUserInfo();
                    registerSendModel.ObjWebUser.Password = widgetNewPassword.EntryText;
                    registerSendModel.ObjWebUser.MemberNumber = associate.MemberNumber;//Constants.MEMBER_NUMBER;
                    registerSendModel.ObjWebUser.UserID = associate.UserName;// Constants.USER_NAME;

                    logger.Trace(string.Format("Page:{0}, Method:{1}, RegisterSendModel:{2}", "Account Change Password", "Change Password", JsonConvert.SerializeObject(registerSendModel)));
                    
                    OperationResult operationResult = await MemberServiceHelper.ChangePassword(registerSendModel);
                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                    {
                        logger.Trace(string.Format("Page:{0}, Method:{1}, ChangePassword Response:{2}", "Account Change Password", "Change Password", "Password updated successfully"));
                        ToastHelper.ShowSuccessToast("Success", "Password updated successfully");
                        await Navigation.PopAsync();
                    }
                    else
                    {
                        logger.Trace(string.Format("Page:{0}, Method:{1}, ChangePassword Response:{2}", "Account Change Password", "Change Password", operationResult.ErrorMessage));
                        ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                    }
                }
            }
        }
    }
}
