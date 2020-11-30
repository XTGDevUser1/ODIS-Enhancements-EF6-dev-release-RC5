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
    public partial class EditProfile : CustomContentPage
    {
        Associate mAssociate;
        MemberHelper memberHelper = new MemberHelper();
        CustomImageUpload imgUpload;
        StaticDataInitializer staticDataInitializer = new StaticDataInitializer();
        public EditProfile(Associate associate)
        {
            InitializeComponent();
            if (Constants.IS_MASTER_MEMBER && associate.MemberNumber == Constants.MEMBER_NUMBER)
            {
                //if (Global.CurrentMember != null && Global.CurrentMember.MasterMember != null)
                //{
                    mAssociate = associate;
               // }
            }
            else
            {
                mAssociate = associate;
            }
            imgUpload = new CustomImageUpload(this,false)
            {
                CurrentPage = this,
                IsBottomButtonsVisible = false,
                ImageHeight = Constants.FFIMAGE_VEHICLE_HEIGHT,
                ImageWidth = Constants.FFIMAGE_VEHICLE_WIDTH,
                DefaultImageSource = ImagePathResources.ProfileMenuDeafultImage
            };
            stackProfileImageUpload.Children.Add(imgUpload);
            imgUpload.SetImageSouce(associate.Photo);
            widgetDOB.Behaviors.Add(new RequireValidatorBehavior_LabelDateVertical());
            widgetEmail.Behaviors.Add(new EmailValidatorBehavior() { IsRequired = true });
            widgetContact.Behaviors.Add(new CountryPhoneNumberBehavior_LabelDropdownEntryHorizontal() { IsRequired = true, Length = 10 });
            widgetContact.EntryValue.FormatCharacters = "( -)";
            widgetContact.EntryValue.Mask = new System.Collections.Generic.List<MaskRules>(
                new[] {
                    new MaskRules {Start=0,End=3,Mask="{0:3}" },
                    new MaskRules {Start=3,End=6,Mask="({0:3}) {3:3}" },
                    new MaskRules {Start=6,End=10,Mask="({0:3}) {3:3}-{6:}" }
                });
            LoadData(associate);
            string title = "Profile";
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

        private void LoadData(Associate associate)
        {
            lblFullName.Text = associate.FullName;
            widgetMemberNumber.ValueText = associate.MemberNumber;
            widgetUserName.ValueText = associate.UserName;
            widgetEmail.EntryValue.Text = associate.Email;
            widgetContact.EntryText = (associate.CellPhone.AreaCode != null ? associate.CellPhone.AreaCode.Trim() : string.Empty) + (associate.CellPhone.Number != null ? associate.CellPhone.Number.Trim() : string.Empty);
            widgetContact.ItemSource = LoadCountries();
            DateTime dateOfBirth;
            if (DateTime.TryParse(associate.DateOfBirth, out dateOfBirth))
            {
                widgetDOB.Date = dateOfBirth;
            }
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
                        if (mAssociate != null && mAssociate.CellPhone != null && !string.IsNullOrEmpty(mAssociate.CellPhone.CountryCode) && countries.ContainsValue(mAssociate.CellPhone.CountryCode.Trim()))
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
            widgetDOB.onValidate();
            widgetContact.onValidate();
            widgetEmail.onValidate();
            using (new HUD("Updating Member..."))
            {
                if (widgetDOB.IsValid && widgetContact.IsValid && widgetEmail.IsValid && PhoneNumberValidator.ValidatePhoneNumber(widgetContact))
                {
                    MemberHelper memberHelper = new MemberHelper();

                    if (!imgUpload.IsDefaultImage)
                    {
                        byte[] imgBytes = await imgUpload.GetImageBytes(Constants.FFIMAGE_VEHICLE_HEIGHT, Constants.FFIMAGE_VEHICLE_WIDTH);//(int)(App.ScreenHeight / 3), (int)App.ScreenWidth);
                        mAssociate.Photo = imgBytes;
                    }
                    string input = Regex.Replace(widgetContact.EntryValue.Text, "[^0-9]+", string.Empty);
                    string phoneNumber = input;
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
                    mAssociate.DateOfBirth = widgetDOB.SelectedDate();
                    mAssociate.Email = widgetEmail.EntryValue.Text;
                    mAssociate.IsActive = true;
                    mAssociate.MembershipNumber = Constants.MEMBER_MEMBERSHIP_NUMBER;
                    OperationResult operationResult;
                    List<Associate> associates = new List<Associate>();
                    if (Constants.IS_MASTER_MEMBER && mAssociate.MemberNumber == Constants.MEMBER_NUMBER)
                    {
                        Global.CurrentMember.MasterMember = mAssociate;
                        operationResult = await memberHelper.UpdateMemberhip(Global.CurrentMember);
                    }
                    else {
                        associates.Add(mAssociate);
                        operationResult = await memberHelper.AddEditMember(associates);
                    }

                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                    {
                        ToastHelper.ShowSuccessToast("Success", "Member information updated successfully.");
                        staticDataInitializer.UpdateMembers();
                        staticDataInitializer.UpdateMembership();
                        EventDispatcher.RaiseEvent(mAssociate, new RefreshEventArgs(AppConstants.Event.REFRESH_MEMBER_DETAILS));
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
