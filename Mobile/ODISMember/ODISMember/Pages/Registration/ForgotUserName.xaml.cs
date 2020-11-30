using System;
using System.Collections.Generic;
using Xamarin.Forms;
using ODISMember.Behaviors;
using ODISMember.Pages.Registration;
using ODISMember.Entities;
using System.Threading.Tasks;
using ODISMember.Services.Service;
using ODISMember.Shared;
using ODISMember.Helpers.UIHelpers;

namespace ODISMember
{
	public partial class ForgotUserName : BaseContentPage
    {
        LoggerHelper logger = new LoggerHelper();
        public ForgotUserName ()
		{
			InitializeComponent ();

            //tracking page view
            logger.TrackPageView(PageNames.FORGOT_USER_NAME);

            Title = "Forgot Username";
			NavigationPage.SetHasNavigationBar(this, false);            
            widgetEmail.Behaviors.Add(new EmailValidatorBehavior() { IsRequired = true });
            btnSubmit.Clicked += BtnSubmit_Clicked;
			//widgetActionBar.BtnImage.ImageClicked += WidgetActionBar_BtnImage_Clicked;

            var tapGestureRecognizer = new TapGestureRecognizer();
            tapGestureRecognizer.Tapped += WidgetActionBar_BtnImage_Clicked;
            tapGestureRecognizer.NumberOfTapsRequired = 1;
            widgetActionBar.BtnImage.GestureRecognizers.Add(tapGestureRecognizer);
            Content = CreateLoadingIndicatorRelativeLayout(mainLayout);
        }
		void WidgetActionBar_BtnImage_Clicked (object sender, EventArgs e)
		{
			Navigation.PopAsync();
		}
        	
		async void BtnSubmit_Clicked (object sender, EventArgs e)
		{
            try
            {
                if (widgetEmail.onValidate())
                {
                    using (new HUD("Processing Request...")) {
                        //IsLoading(true);
                        MemberHelper memberHelper = new MemberHelper();
                        //OperationResult operationResult =Task.Run(()=> memberHelper.SendUserName (widgetMemberNumber.EntryValue.Text)).Result;
                        OperationResult operationResult = await memberHelper.SendUserName(widgetEmail.EntryValue.Text);
                        if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                        {
                            //IsLoading(false);
                            Navigation.PopAsync();
                            ToastHelper.ShowSuccessToast("Success");
                        }
                        else
                        {
                            //IsLoading(false);
                            logger.Result(operationResult);
                            ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                        }
                    }
                }
            }
            catch (Exception ex) {
                logger.Error(ex);
            }
		}
	}
}

