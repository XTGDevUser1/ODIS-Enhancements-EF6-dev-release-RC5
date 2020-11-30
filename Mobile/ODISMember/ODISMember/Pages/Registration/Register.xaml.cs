using System;
using Xamarin.Forms;
using ODISMember.Behaviors;
using System.Threading.Tasks;
using ODISMember.Services.Service;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Shared;
using ODISMember.Helpers.UIHelpers;
using System.Collections.Generic;
using ODISMember.Entities.Table;
using Newtonsoft.Json;
using System.Linq;
using ODISMember.Common;
using ODISMember.Library;
using System.Text.RegularExpressions;

namespace ODISMember.Pages.Registration
{
    public partial class Register : BaseContentPage
    {
        LoggerHelper logger = new LoggerHelper();
        RegisterVerifyResultModel mRegisterVerifyResultModel;
        MemberHelper memberHelper = new MemberHelper();
        public Register(RegisterVerifyResultModel model)
        {
            InitializeComponent();

            //tracking page view
            logger.TrackPageView(PageNames.REGISTER);

            NavigationPage.SetHasNavigationBar(this, false);
            Title = "Register";
            mRegisterVerifyResultModel = model;
            widgetUserName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetPassword.Behaviors.Add(new PasswordBehavior_LabelEntryVertical() { IsRequired = true });
            widgetConfirmPassword.Behaviors.Add(new ConfirmPasswordBehavior_LabelEntryVertical(widgetPassword) { IsRequired = true });
            widgetEmail.Behaviors.Add(new EmailValidatorBehavior() { IsRequired = true });
            
            btnRegister.Clicked += BtnRegister_Clicked; ;
            var tapGestureRecognizer = new TapGestureRecognizer();
            tapGestureRecognizer.Tapped += WidgetActionBar_BtnImage_Clicked;
            tapGestureRecognizer.NumberOfTapsRequired = 1;
            widgetActionBar.BtnImage.GestureRecognizers.Add(tapGestureRecognizer);
             widgetContact.EntryValue.FormatCharacters = "( -)";
            widgetContact.EntryValue.Mask = new System.Collections.Generic.List<MaskRules>(
                new[] {
                    new MaskRules {Start=0,End=3,Mask="{0:3}" },
                    new MaskRules {Start=3,End=6,Mask="({0:3}) {3:3}" },
                    new MaskRules {Start=6,End=10,Mask="({0:3}) {3:3}-{6:}" }
                });
            LoadData(model);
            widgetContact.Behaviors.Add(new CountryPhoneNumberBehavior_LabelDropdownEntryHorizontal() { IsRequired = true, Length = 10 });

            Content = CreateLoadingIndicatorRelativeLayout(mainLayout);
        }

        public void LoadData(RegisterVerifyResultModel modelObj)
        {
            if (modelObj != null)
            {
                if (!string.IsNullOrEmpty(modelObj.Email))
                {
                    widgetEmail.EntryText = modelObj.Email;
                }
                if (modelObj.CellPhone != null)
                {
                    widgetContact.EntryText = (modelObj.CellPhone.AreaCode != null ? modelObj.CellPhone.AreaCode.Trim() : string.Empty) + (modelObj.CellPhone.Number != null ? modelObj.CellPhone.Number.Trim() : string.Empty);
                }
            }
            widgetContact.ItemSource = LoadCountries();
        }

        void WidgetActionBar_BtnImage_Clicked(object sender, EventArgs e)
        {
            //Global.RemovePage(this);
            Navigation.PopAsync();
        }
        public Dictionary<string, string> LoadCountries()
        {
            Dictionary<string, string> countries = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalCountryCodes()).Result;
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
            {
                if (operationResult.Data != null)
                {
                    List<Countries> countryList = JsonConvert.DeserializeObject<List<Countries>>(operationResult.Data.ToString());
                    if (countryList.Count > 0)
                    {
                        countries = countryList.ToDictionary(pair => pair.ISOCode.Trim() + " (+" + pair.TelephoneCode.Trim().ToString() + ")", pair => pair.ISOCode.Trim().ToString());
                        if (mRegisterVerifyResultModel != null && mRegisterVerifyResultModel.CellPhone != null && !string.IsNullOrEmpty(mRegisterVerifyResultModel.CellPhone.CountryCode) && countries.ContainsValue(mRegisterVerifyResultModel.CellPhone.CountryCode.Trim()))
                        {
                            widgetContact.SelectedItem = countries.Where(a => a.Value.Trim() == mRegisterVerifyResultModel.CellPhone.CountryCode.Trim()).First();
                            widgetContact.EntryValueDropdown.Text = widgetContact.Key;
                        }
                        else if (countries.ContainsValue("US"))
                        {
                            widgetContact.SelectedItem = countries.Where(a => a.Value.Trim() == "US").First();
                            widgetContact.EntryValueDropdown.Text = widgetContact.Key;
                        }
                    }
                }
            }
            else
            {
                if (operationResult != null && operationResult.ErrorMessage != null)
                {
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
            return countries;
        }
        async void BtnRegister_Clicked(object sender, EventArgs e)
        {
            widgetUserName.onValidate();
            widgetPassword.onValidate();
            widgetConfirmPassword.onValidate();
            widgetContact.onValidate();
            widgetEmail.onValidate();
            if (widgetUserName.IsValid && widgetPassword.IsValid && widgetContact.IsValid && widgetEmail.IsValid && 
                widgetConfirmPassword.IsValid && PhoneNumberValidator.ValidatePhoneNumber(widgetContact))
            {
                using (new HUD("Registering..."))
                {
                    //IsLoading(true);
                    string input = Regex.Replace(widgetContact.EntryValue.Text, "[^0-9]+", string.Empty);
                    var phoneNumber = input;

                    RegisterSendModel registerSendModel = new RegisterSendModel();
                    registerSendModel.ObjWebUser = new RegisterUserInfo();
                    registerSendModel.ObjWebUser.MemberNumber = mRegisterVerifyResultModel.MemberNumber;
                    registerSendModel.ObjWebUser.UserID = widgetUserName.EntryValue.Text;
                    registerSendModel.ObjWebUser.Password = widgetPassword.EntryValue.Text;
                    registerSendModel.ObjWebUser.Email = widgetEmail.EntryValue.Text;

                    registerSendModel.ObjWebUser.CellPhone = new PhoneNumberModel();
                    registerSendModel.ObjWebUser.CellPhone.AreaCode = phoneNumber.Substring(0, Math.Min(phoneNumber.Length, 3));
                    registerSendModel.ObjWebUser.CellPhone.Number = phoneNumber.Substring(phoneNumber.Length - 7);
                    registerSendModel.ObjWebUser.CellPhone.PhoneNumberType = Constants.enumPhoneType.Primary;
                    registerSendModel.ObjWebUser.CellPhone.CountryCode = widgetContact.Value;

                    MemberHelper memberHelper = new MemberHelper();
                    OperationResult operationResult = await memberHelper.Register(registerSendModel);
                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                    {
                        ToastHelper.ShowSuccessToast("Success", "Registration Successful. Please login to continue...");
                        Global.RemovePages(this);
                        await Navigation.PushAsync(new Login());
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

