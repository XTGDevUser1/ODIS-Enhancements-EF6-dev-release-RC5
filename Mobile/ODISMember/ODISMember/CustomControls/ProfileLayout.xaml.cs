using ODISMember.Common;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Pages.Tabs;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.CustomControls
{
    public partial class ProfileLayout : StackLayout
    {
        Associate mAssociate;
        ContentPage Parent;
        StaticDataInitializer staticDataInitializer = new StaticDataInitializer();
        MemberHelper memberHelper = new MemberHelper();
        public ProfileLayout(ContentPage page, Associate associate)
        {
            InitializeComponent();

            
            mAssociate = associate;
            Parent = page;
            LoadData(associate);
            if (associate.IsRegistered)
            {
                btnEmailSetup.HeightRequest = 0;
            }
            if (associate.MemberNumber == Constants.MEMBER_NUMBER)
            {
                profileViewOnly();
            }
            else if (Constants.IS_MASTER_MEMBER && associate.MemberNumber != Constants.MEMBER_NUMBER)
            {
                memberProfileViewOnly();
            }
            else if (!Constants.IS_MASTER_MEMBER && associate.MemberNumber != Constants.MEMBER_NUMBER)
            {
                memberProfileViewOnlyNoEdit();
            }
            btnChagePassword.Clicked += BtnChagePassword_Clicked;
            btnEmailSetup.Clicked += BtnEmailSetup_Clicked;
            //btnDeleteMember.Clicked += BtnDeleteMember_Clicked;
            EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.REFRESH_MEMBER_DETAILS)
            {
                Associate associate = (Associate)sender;
                LoadData(associate);
            }
        }

        private async void BtnDeleteMember_Clicked(object sender, EventArgs e)
        {
            bool isSuccess = await Parent.DisplayAlert("Delete", "Are you sure you want to delete this member?", "Yes", "No");
            if (isSuccess)
            {
                var hud = new HUD("Deleting...");
                MemberHelper memberHelper = new MemberHelper();
                OperationResult operationResult = await memberHelper.DeleteMember(mAssociate.MemberNumber);

                if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                {
                    hud.Dismiss();
                    ToastHelper.ShowSuccessToast("Success", "Member deleted successfully");

                    EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.START_REFRESH_MEMBERS_SYNC));
                    staticDataInitializer.UpdateMembers();
                    staticDataInitializer.UpdateMembership();

                    await Parent.Navigation.PopAsync();
                }
                else
                {
                    hud.Dismiss();
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
        }

        private async void BtnEmailSetup_Clicked(object sender, EventArgs e)
        {
            MemberEmailModel memberEmailModel = new MemberEmailModel();
            memberEmailModel.EmailType = Constants.enumMemberEmailType.InvitationToRegister;
            memberEmailModel.ObjWebUser = new EmailRegisterModel();
            memberEmailModel.ObjWebUser.MemberNumber = mAssociate.MemberNumber;
            memberEmailModel.ObjWebUser.Email = mAssociate.Email;
            memberEmailModel.ObjWebUser.PersonID = mAssociate.SystemIdentifier;
            using (new HUD("Processing request..."))
            {
                OperationResult operationResult = await memberHelper.EmailSetupInstructions(memberEmailModel);
                if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                {
                    staticDataInitializer.UpdateMembers();
                    ToastHelper.ShowSuccessToast("Success", "Mail sent successfully");
                    await Parent.Navigation.PopAsync();
                }
                else
                {
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
        }

        private void BtnChagePassword_Clicked(object sender, EventArgs e)
        {
            Navigation.PushAsync(new ChangePassword(mAssociate));
        }

        private void LoadData(Associate associate)
        {
            if (associate != null)
            {
                lblFullName.Text = associate.FullName;
                widgetMemberNumber.ValueText = associate.MemberNumber;
                widgetUserName.ValueText = associate.UserName;
                widgetDOB.ValueText = associate.DateOfBirthString;
                widgetEmail.ValueText = associate.Email;
                widgetPhoneNumber.ValueText = associate.CellPhone != null ? associate.CellPhone.PhoneString : string.Empty;
                if (associate.Photo != null && associate.Photo.Length > 0)
                {
                    profileImage.Source = Xamarin.Forms.ImageSource.FromStream(() =>
                    {
                        Stream stream = new MemoryStream(associate.Photo);
                        return stream;
                    });
                }

                else
                {
                    profileImage.Source = Classes.ImagePathResources.ProfileMenuDeafultImage;
                }
            }
        }
        void memberProfileViewOnly()
        {
            stackChangePassword.HeightRequest = 0;
        }
        void memberProfileViewOnlyNoEdit()
        {
            stackButtons.HeightRequest = 0;
            stackChangePassword.HeightRequest = 0;
        }
        void profileViewOnly()
        {
            stackButtons.HeightRequest = 0;
        }
    }
}
