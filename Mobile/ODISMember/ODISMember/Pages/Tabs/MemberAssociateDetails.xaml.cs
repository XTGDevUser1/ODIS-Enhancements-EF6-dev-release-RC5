using ODISMember.Classes;
using ODISMember.Common;
using ODISMember.Entities;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Services.Service;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class MemberAssociateDetails : ContentPage
    {       
        Associate mAssociate;
        LoggerHelper logger = new LoggerHelper();
        StaticDataInitializer staticDataInitializer = new StaticDataInitializer();
        public MemberAssociateDetails(Associate associate)
        {
            InitializeComponent();

            //tracking page view
            logger.TrackPageView(PageNames.ACCOUNT_MEMBER_DETAILS);
            Title = "Member Details";
            mAssociate = associate;

            LoadData(mAssociate);

            if (Constants.IS_MASTER_MEMBER || associate.MemberNumber == Constants.MEMBER_NUMBER)
            {
                Menu menu = new Menu();
                menu.Icon = ImagePathResources.EditIcon;
                menu.Priority = 1;
                menu.Name = "Edit";
                menu.ToolbarItemOrder = 0;
                menu.ActionOnClick += openMemberAssociateEdit;
                CommonMenu.CreateMenu(this, menu);

                if (associate.MemberNumber != Constants.MEMBER_NUMBER)
                {
                    btnDelete.IsVisible = true;
                    btnDelete.Clicked += BtnDelete_Clicked;
                }
            }

            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            }
        }

        private async void BtnDelete_Clicked(object sender, EventArgs e)
        {
            bool isSuccess = await DisplayAlert("Delete", "Are you sure you want to delete this member?", "Yes", "No");
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

                    Navigation.PopAsync();
                }
                else
                {
                    hud.Dismiss();
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.REFRESH_MEMBER_DETAILS)
            {
              var  associate = sender as Associate;
                if (associate != null)
                {
                    Device.BeginInvokeOnMainThread(() => {
                        LoadData(associate);
                    });
                }
            }
        }

        public void LoadData(Associate associate)
        {
            if (associate != null)
            {
                lblMemberNumber.Text = associate.MemberNumberStringWithTitle;
                lblFullName.Text = associate.FullName;
                lblEmail.Text = associate.Email;
                lblDateOfBirth.Text = associate.DateOfBirthStringWithTitle;
                lblPhone.Text = associate.CellPhone != null ? associate.CellPhone.PhoneString : string.Empty;
            }
        }
        private void openMemberAssociateEdit()
        {
            Navigation.PushAsync(new AddMemberAssociate(mAssociate));
        }
    }
}
