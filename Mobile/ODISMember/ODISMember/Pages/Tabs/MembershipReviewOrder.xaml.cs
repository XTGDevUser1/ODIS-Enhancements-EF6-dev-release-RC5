using System;
using System.Collections.Generic;

using Xamarin.Forms;
using ODISMember.Model;
using ODISMember.Entities.Model;
using ODISMember.Entities;
using System.Threading.Tasks;
using Plugin.Toasts;

namespace ODISMember
{
    public partial class MembershipReviewOrder : ContentPage
    {
        public MemberModel memberModel
        {
            get;
            set;
        }
        public MembershipReviewOrder(MemberModel member)
        {
            InitializeComponent();
            NavigationPage.SetHasNavigationBar(this, false);
            memberModel = member;
            this.BindingContext = member;
            btnSubmit.Clicked += BtnSubmit_Clicked;
            var tapGestureRecognizer = new TapGestureRecognizer();
            tapGestureRecognizer.Tapped += WidgetActionBar_BtnImage_Clicked;
            tapGestureRecognizer.NumberOfTapsRequired = 1;
            widgetActionBar.BtnImage.GestureRecognizers.Add(tapGestureRecognizer);
        }
        void WidgetActionBar_BtnImage_Clicked(object sender, EventArgs e)
        {
            Global.RemovePage(this);
            Navigation.PopAsync();
        }
        void BtnSubmit_Clicked(object sender, EventArgs e)
        {
            MemberHelper memberHelper = new MemberHelper();
            OperationResult operationResult = Task.Run(() => memberHelper.Join(memberModel)).Result;
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
            {
                stackReviewConfirmation.IsVisible = true;
                stackReview.HeightRequest = 0;
                Global.RemovePages(this);
            }
            else {
                ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
            }
        }
    }
}

