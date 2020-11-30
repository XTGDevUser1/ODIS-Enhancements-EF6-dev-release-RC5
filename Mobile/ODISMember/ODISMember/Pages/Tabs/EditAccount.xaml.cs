using System;
using System.Collections.Generic;
using System.Linq;
using Xamarin.Forms;
using ODISMember.Behaviors;
using ODISMember.Entities;
using ODISMember.CustomControls;
using System.Threading.Tasks;
using ODISMember.Common;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Classes;
using ODISMember.Shared;
using ODISMember.Services.Service;
using Newtonsoft.Json;
using ODISMember.Entities.Table;

namespace ODISMember.Pages.Tabs
{

    public partial class EditAccount : CustomContentPage
    {
        MemberHelper memberHelper = new MemberHelper();

        StaticDataInitializer staticDataInitializer = new StaticDataInitializer();
        AccountModel mMember;
        LoggerHelper logger = new LoggerHelper();
        public EditAccount()
        {
            InitializeComponent();
            logger.TrackPageView(PageNames.ACCOUNT_MEMBERSHIP_EDIT);
            mMember = Global.CurrentMember;
            widgetAddressLine1.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetCity.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetPostalCode.Behaviors.Add(new RequireValidatorBehavior_LabelEntryVertical());
            widgetPostalCode.Behaviors.Add(new NumberValidatorBehavior_LabelEntryVertical());
        
            widgetCountry.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());
            widgetState.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());
            LoadData();
            string title = "Account";
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
                menuDone.ActionOnClick += SaveAccountInformation;
                CommonMenu.CreateMenu(this, menuDone);

                Menu menuCancel = new Menu();
                menuCancel.Priority = 1;
                menuCancel.Name = "Cancel";
                menuCancel.ActionOnClick += closeCurrentPage;
                CommonMenu.CreateMenu(this, menuCancel);
            }

            widgetCountry.OnDropDownSelection += WidgetCountry_OnDropDownSelection;
        }
        private void CustomActionBar_OnDoneClick(object sender, EventArgs e)
        {
            SaveAccountInformation();
        }

        private void CustomActionBar_OnCloseClick(object sender, EventArgs e)
        {
            closeCurrentPage();
        }
        private Dictionary<string, string> LoadCountryTelephoneCodes()
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

        private void closeCurrentPage()
        {
            Navigation.PopAsync();
        }
        private void WidgetCountry_OnDropDownSelection(object sender, TextChangedEventArgs e)
        {
            widgetState.EntryText = string.Empty;
            widgetState.ItemSource = LoadStates(widgetCountry.Value);
        }

        public Dictionary<string, string> LoadCountries()
        {
            Dictionary<string, string> countries = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalCountryCodes()).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS)
            {
                List<Countries> countryList = JsonConvert.DeserializeObject<List<Countries>>(operationResult.Data.ToString());
                if (countryList.Count > 0)
                {
                    countries = countryList.ToDictionary(pair => pair.ISOCode, pair => pair.SystemIdentifier.ToString());

                    if (mMember != null && mMember.Addresses.Count > 0 && countries.ContainsValue(mMember.Addresses[0].CountryCodeID.ToString()))
                    {
                        widgetCountry.SelectedItem = countries.Where(a => a.Value == mMember.Addresses[0].CountryCodeID.ToString()).First();
                        widgetCountry.EntryValue.Text = widgetCountry.Key;
                    }
                    if (mMember != null && mMember.Addresses.Count > 0)
                    {
                        widgetState.ItemSource = LoadStates(mMember.Addresses[0].CountryCodeID.ToString());
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
        public Dictionary<string, string> LoadStates(string countryId)
        {
            Dictionary<string, string> states = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetStatesForCountry(countryId)).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS)
            {
                List<KeyValuePair<string, string>> stateList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (stateList.Count > 0)
                {
                    states = stateList.ToDictionary(pair => pair.Key + "-" + pair.Value, pair => pair.Key.ToString());

                    if (mMember != null && mMember.Addresses.Count > 0 && states.ContainsValue(mMember.Addresses[0].State))
                    {
                        widgetState.SelectedItem = states.Where(a => a.Value == mMember.Addresses[0].State).First();
                        widgetState.EntryValue.Text = widgetState.Key;
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
            return states;
        }

        private void LoadData()
        {
            widgetCountry.ItemSource = LoadCountries();

            if (mMember != null)
            {
                if (mMember.MasterMember != null)
                {
                    widgetMembershipPlan.ValueText = Constants.MEMBER_PLAN_NAME;
                    widgetMemberShipNumber.ValueText = mMember.MembershipNumber;
                    widgetExpires.ValueText = mMember.ExpirationDateString;
                    if (mMember.Addresses.Count > 0)
                    {
                        widgetAddressLine1.EntryText = mMember.Addresses[0].Address1;
                        widgetAddressLine2.EntryText = mMember.Addresses[0].Address2;
                        widgetCity.EntryText = mMember.Addresses[0].City;
                        widgetPostalCode.EntryText = mMember.Addresses[0].PostalCode;
                    }
                  Associate masterMember = mMember.MasterMember;
                }
            }
        }
   
        async void SaveAccountInformation()
        {
            widgetAddressLine1.onValidate();
            widgetCity.onValidate();
            widgetCountry.onValidate();
            widgetState.onValidate();
            widgetPostalCode.onValidate();

                var hud = new HUD("Updating Details...");

                if (mMember.Addresses.Count > 0)
                {
                    mMember.Addresses[0].Address1 = widgetAddressLine1.EntryText;
                    mMember.Addresses[0].Address2 = widgetAddressLine2.EntryText;
                    mMember.Addresses[0].City = widgetCity.EntryText;
                    mMember.Addresses[0].State = widgetState.Value;
                    mMember.Addresses[0].CountryCodeID = int.Parse(widgetCountry.Value);
                    mMember.Addresses[0].CountryCode = widgetCountry.Key;
                    mMember.Addresses[0].PostalCode = widgetPostalCode.EntryText;
                }
                else
                {
                    AddressModel addressModel = new AddressModel();
                    addressModel.Address1 = widgetAddressLine1.EntryText;
                    addressModel.Address2 = widgetAddressLine2.EntryText;
                    addressModel.City = widgetCity.EntryText;
                    addressModel.State = widgetState.Value;
                    addressModel.CountryCodeID = int.Parse(widgetCountry.Value);
                    addressModel.CountryCode = widgetCountry.Key;
                    addressModel.PostalCode = widgetPostalCode.EntryText;
                    mMember.Addresses = new List<AddressModel>();
                    mMember.Addresses.Add(addressModel);
                }

                OperationResult operationResult = await memberHelper.UpdateMemberhip(mMember);
                if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                {
                    staticDataInitializer.UpdateMembers();
                    staticDataInitializer.UpdateMembership();
                    hud.Dismiss();
                    ToastHelper.ShowSuccessToast("Success", "Account information updated successfully.");
                EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(ODISMember.AppConstants.Event.REFRESH_CURRENT_MEMBER_DETAILS));
                await Navigation.PopAsync();
                }
                else
                {
                    hud.Dismiss();
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
        }
    }

