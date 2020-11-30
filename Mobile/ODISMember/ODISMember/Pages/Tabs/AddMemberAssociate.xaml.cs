using Newtonsoft.Json;
using ODISMember.Behaviors;
using ODISMember.Classes;
using ODISMember.Common;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Entities.Table;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Library;
using ODISMember.Services.Service;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class AddMemberAssociate : CustomContentPage
    {
        Associate mAssociate;
        bool isAdd = true;
        LoggerHelper logger = new LoggerHelper();
        MemberHelper memberHelper = new MemberHelper();
        StaticDataInitializer staticDataInitializer = new StaticDataInitializer();
        public AddMemberAssociate(Associate associate = null)
        {
            InitializeComponent();

            //tracking page view
            logger.TrackPageView(PageNames.ACCOUNT_MEMBER_ADD_EDIT);
            if (associate != null)
            {
                mAssociate = associate;
                isAdd = false;
            }
            else
            {
                isAdd = true;
                mAssociate = new Associate();
            }
            this.BindingContext = mAssociate;
            widgetFirstName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetLastName.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetBirthDate.Behaviors.Add(new RequireValidatorBehavior_LabelDateVertical());
            widgetEmail.Behaviors.Add(new EmailValidatorBehavior() { IsRequired = true });

            if (mAssociate!=null && !string.IsNullOrEmpty(mAssociate.DateOfBirth))
            {
                DateTime dateOfBirth;
                if (DateTime.TryParse(mAssociate.DateOfBirth, out dateOfBirth))
                {
                    widgetBirthDate.Date = dateOfBirth;
                }
            }

            if (mAssociate!=null && mAssociate.CellPhone != null)
            {
                widgetContact.EntryValue.Text = (mAssociate.CellPhone.AreaCode != null ? mAssociate.CellPhone.AreaCode.Trim() : string.Empty) + (mAssociate.CellPhone.Number != null ? mAssociate.CellPhone.Number.Trim() : string.Empty);
            }
            widgetContact.ItemSource = LoadCountries();
            widgetContact.Behaviors.Add(new CountryPhoneNumberBehavior_LabelDropdownEntryHorizontal() { IsRequired = true, Length = 10 });
            widgetContact.EntryValue.FormatCharacters = "( -)";
            widgetContact.EntryValue.Mask = new System.Collections.Generic.List<MaskRules>(
                new[] {
                    new MaskRules {Start=0,End=3,Mask="{0:3}" },
                    new MaskRules {Start=3,End=6,Mask="({0:3}) {3:3}" },
                    new MaskRules {Start=6,End=10,Mask="({0:3}) {3:3}-{6:}" }
                });
            string title = "Add a Member";

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
                menuDone.ActionOnClick += saveMemberAssociate;
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
            saveMemberAssociate();
        }

        private void CustomActionBar_OnCloseClick(object sender, EventArgs e)
        {
            closeCurrentPage();
        }
        private void closeCurrentPage()
        {
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
                        if (mAssociate != null && mAssociate.CellPhone != null && !string.IsNullOrEmpty(mAssociate.CellPhone.CountryCode.Trim()) && countries.ContainsValue(mAssociate.CellPhone.CountryCode.Trim()))
                        {
                            widgetContact.SelectedItem = countries.Where(a => a.Value.Trim() == mAssociate.CellPhone.CountryCode.Trim()).First();
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
        private async void saveMemberAssociate()
        {
            widgetFirstName.onValidate();
            widgetLastName.onValidate();
            widgetBirthDate.onValidate();
            widgetContact.onValidate();
            widgetEmail.onValidate();
            using (new HUD("Saving Member..."))
            {
                if (widgetFirstName.IsValid && widgetLastName.IsValid &&
                     widgetBirthDate.IsValid && widgetContact.IsValid && widgetEmail.IsValid && PhoneNumberValidator.ValidatePhoneNumber(widgetContact))
                {
                    MemberHelper memberHelper = new MemberHelper();
                    string input = Regex.Replace(widgetContact.EntryValue.Text, "[^0-9]+", string.Empty);
                    string phoneNumber = input;
                    if (!string.IsNullOrEmpty(phoneNumber))
                    {
                        if (mAssociate.CellPhone == null)
                        {
                            mAssociate.CellPhone = new PhoneNumberModel();
                        }

                        mAssociate.CellPhone.PhoneNumberType = Constants.enumPhoneType.Cell;
                        mAssociate.MemberType = Constants.MemberType.Dependent;
                        mAssociate.RelationshipType = Constants.enumPersonRelationship.Associate;

                        mAssociate.CellPhone.CountryCode = widgetContact.Value.Trim();
                        mAssociate.CellPhone.AreaCode = phoneNumber.Substring(0, Math.Min(phoneNumber.Length, 3));
                        mAssociate.CellPhone.Number = phoneNumber.Substring(phoneNumber.Length - 7);
                        mAssociate.DateOfBirth = widgetBirthDate.SelectedDate();

                        mAssociate.IsActive = true;
                        mAssociate.MembershipNumber = Constants.MEMBER_MEMBERSHIP_NUMBER;
                    }
                    var associates = new List<Associate>();
                    associates.Add(mAssociate);

                    OperationResult operationResult = await memberHelper.AddEditMember(associates);

                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                    {
                        if (isAdd)
                        {
                            ToastHelper.ShowSuccessToast("Success", "Member information added successfully.");
                        }
                        else
                        {
                            ToastHelper.ShowSuccessToast("Success", "Member information updated successfully.");
                        }
                        Device.BeginInvokeOnMainThread(() =>
                        {
                            EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.START_REFRESH_MEMBERS_SYNC));
                        });
                        staticDataInitializer.UpdateMembers();
                        staticDataInitializer.UpdateMembership();
                        await Navigation.PopAsync();
                    }
                    else
                    {
                        ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                    }
                }
            }
        }
    }
}
