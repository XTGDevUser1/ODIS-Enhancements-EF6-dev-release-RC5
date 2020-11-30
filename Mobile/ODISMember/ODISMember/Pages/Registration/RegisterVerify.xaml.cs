using System;
using Xamarin.Forms;
using ODISMember.Behaviors;
using System.Threading.Tasks;
using ODISMember.Services.Service;
using ODISMember.Entities;
using Newtonsoft.Json;
using ODISMember.Entities.Model;
using ODISMember.Shared;
using ODISMember.Helpers.UIHelpers;

namespace ODISMember.Pages.Registration
{
    public partial class RegisterVerify : BaseContentPage
    {
        LoggerHelper logger = new LoggerHelper();
        public RegisterVerify()
        {
            InitializeComponent();

            //tracking page view
            logger.TrackPageView(PageNames.REGISTER_VERIFY);

            NavigationPage.SetHasNavigationBar(this, false);
            Title = "Register";
            widgetMemberNumber.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetFirstName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetLastName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());

            btnVerify.Clicked += BtnVerify_Clicked;
            btnTermsAndConditions.Clicked += BtnTermsAndConditions_Clicked;
            var tapGestureRecognizer = new TapGestureRecognizer();
            tapGestureRecognizer.Tapped += WidgetActionBar_BtnImage_Clicked;
            tapGestureRecognizer.NumberOfTapsRequired = 1;
            widgetActionBar.BtnImage.GestureRecognizers.Add(tapGestureRecognizer);
            Global.AddPage(this);
            //Content = CreateLoadingIndicatorRelativeLayout(mainLayout);
        }
        void WidgetActionBar_BtnImage_Clicked(object sender, EventArgs e)
        {
            Global.RemovePage(this);
            Navigation.PopAsync();
        }

        private void BtnTermsAndConditions_Clicked(object sender, EventArgs e)
        {
            Navigation.PushAsync(new TermsAndConditions());
        }

        async void BtnVerify_Clicked(object sender, EventArgs e)
        {
            try
            {
                logger.Debug(string.Format("BtnVerify_Clicked MemberNumber={0}, FirstName={1}, LastName={2}", widgetMemberNumber.EntryValue.Text, widgetFirstName.EntryValue.Text, widgetLastName.EntryValue.Text));
                widgetMemberNumber.onValidate();
                widgetFirstName.onValidate();
                widgetLastName.onValidate();
                if (widgetMemberNumber.IsValid && widgetFirstName.IsValid && widgetLastName.IsValid)
                {
                    using (new HUD("Verifying Details..."))
                    {
                        //IsLoading(true);
                        MemberHelper memberHelper = new MemberHelper();
                        //OperationResult operationResult = Task.Run(() => memberHelper.RegisterVerify(widgetMemberNumber.EntryValue.Text, widgetLastName.EntryValue.Text, widgetFirstName.EntryValue.Text)).Result;
                        OperationResult operationResult = await memberHelper.RegisterVerify(widgetMemberNumber.EntryValue.Text, widgetLastName.EntryValue.Text, widgetFirstName.EntryValue.Text);
                        if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
                        {
                            RegisterVerifyResultModel verifyModel = JsonConvert.DeserializeObject<RegisterVerifyResultModel>(operationResult.Data.ToString());
                            verifyModel.MemberNumber = widgetMemberNumber.EntryValue.Text;
                            //IsLoading(false);
                            //ToastHelper.ShowSuccessToast("Success");
                            await Navigation.PushAsync(new Register(verifyModel));
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
            catch (Exception ex)
            {

                logger.Error(ex);
            }

        }
    }
}

