namespace ODISMember.Pages.Registration
{
    using System;
    using Xamarin.Forms;
    using Behaviors;
    using Entities;
    using Shared;
    using Helpers.UIHelpers;

    /// <summary>
    /// used for forget password functionality 
    /// </summary>
    /// <seealso cref="Xamarin.Forms.BaseContentPage" />
    public partial class ForgotPassword : BaseContentPage
    {
        LoggerHelper logger = new LoggerHelper();
        private MemberHelper memberServiceHelper = null;

        #region Properties
        private MemberHelper MemberServiceHelper
        {
            get
            {
                if(memberServiceHelper != null)
                {
                    return memberServiceHelper;
                }

                memberServiceHelper = new MemberHelper();

                return memberServiceHelper;
            }
        }
        #endregion        
        public ForgotPassword()
        {
            logger.TrackPageView(PageNames.FORGOT_PASSWORD);

            InitializeComponent();
            
            Title = "Forgot Password";

            NavigationPage.SetHasNavigationBar(this, false);

            widgetEmail.Behaviors.Add(new EmailValidatorBehavior() { IsRequired = true });

            var tapGestureRecognizer = new TapGestureRecognizer();
            tapGestureRecognizer.Tapped += TapGestureRecognizer_Tapped;
            tapGestureRecognizer.NumberOfTapsRequired = 1;
            widgetActionBar.BtnImage.GestureRecognizers.Add(tapGestureRecognizer);

            btnSubmit.Clicked += BtnSubmit_Clicked;

            Content = CreateLoadingIndicatorRelativeLayout(mainLayout);
        }
        /// <summary>
        /// Handles the Tapped event of the back image control and it will remove the current page from stack
        /// </summary>
        /// <param name="sender">The source of the event.</param>
        /// <param name="e">The <see cref="EventArgs"/> instance containing the event data.</param>
        private void TapGestureRecognizer_Tapped(object sender, EventArgs e)
        {
            Navigation.PopAsync();
        }
        /// <summary>
        /// Handles the Clicked event of the BtnSubmit control. It will reset the password.
        /// </summary>
        /// <param name="sender">The source of the event.</param>
        /// <param name="e">The <see cref="EventArgs"/> instance containing the event data.</param>
        async void BtnSubmit_Clicked(object sender, EventArgs e)
        {
            widgetEmail.onValidate();
            if (widgetEmail.IsValid)
            {
                using (new HUD("Processing Request..."))
                {
                    OperationResult operationResult = await MemberServiceHelper.ResetPassword(widgetEmail.EntryValue.Text);
                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                    {
                        await Navigation.PopAsync();
                        ToastHelper.ShowSuccessToast("Success");
                    }
                    else
                    {
                        logger.Result(operationResult);
                        ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                    }
                }
            }
        }
    }
}
