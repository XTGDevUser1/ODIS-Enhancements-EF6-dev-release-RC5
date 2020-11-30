using Newtonsoft.Json;
using ODISMember.Behaviors;
using ODISMember.Classes;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Entities.Table;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Shared;
using ODISMember.Widgets;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class AddEditVehicle : CustomContentPage
    {
        public VehicleModel CurrentVehicle
        {
            get;
            set;
        }

        CustomImageUpload imgUpload;
        MemberHelper memberHelper = new MemberHelper();
        LoggerHelper logger = new LoggerHelper();
        Dictionary<string, string> vehicleTypes;
        List<MakeModel> MakeModels;
        List<RadioButtonItem> VehicleTypeRadiobuttons;
        MakeModel SelectedMakeModel = null;
        string VehicleTypeValue;
        string VehicleTypeKey;
        CustomActionBar VehicleCustomActionBar;
        bool isAdd = true;
        public AddEditVehicle(VehicleModel vehicle = null)
        {
            InitializeComponent();
            logger.TrackPageView(PageNames.VEHICLES_ADD_EDIT);
            string title = string.Empty;
            if (vehicle != null)
            {
                isAdd = false;
                CurrentVehicle = vehicle;
                title = "Edit Vehicle";
                stackVehicleTypes.IsVisible = false;
                stackVehicleTypes.HeightRequest = 0;

                stackVehicleFields.IsVisible = true;
            }
            else
            {
                isAdd = true;
                CurrentVehicle = new VehicleModel();
                CurrentVehicle.PersonId = Constants.PersonID;
                title = "Add Vehicle";
            }
            imgUpload = new CustomImageUpload(this, false)
            {
                CurrentPage = this,
                IsBottomButtonsVisible = false,
                ImageHeight = (App.ScreenHeight / 3), //Constants.FFIMAGE_VEHICLE_HEIGHT,
                ImageWidth = App.ScreenWidth, //Constants.FFIMAGE_VEHICLE_WIDTH,
                DefaultImageSource = ImagePathResources.AddVehicleActive
            };
            //stackImageUpload.Children.Add(imgUpload);

            if (Device.OS == TargetPlatform.Android)
            {
                NavigationPage.SetHasNavigationBar(this, false);
                VehicleCustomActionBar = new CustomActionBar(title);
                //VehicleCustomActionBar.BackgroundColor = Color.White;
                stackCustomActionBar.Children.Add(VehicleCustomActionBar);
                VehicleCustomActionBar.OnCloseClick += CustomActionBar_OnCloseClick;

                if (!isAdd)
                {
                    VehicleCustomActionBar.OnDoneClick -= CustomActionBar_OnDoneClick;
                    VehicleCustomActionBar.OnDoneClick += CustomActionBar_OnDoneClick;
                    VehicleCustomActionBar.BtnDone.TextColor = Color.Black;//ColorResources.ToolbarMenuColor;
                }
                else
                {
                    VehicleCustomActionBar.BtnDone.TextColor = Color.Silver;
                }
            }
            else if (Device.OS == TargetPlatform.iOS)
            {
                stackActionBar.HeightRequest = 0;
                Title = title;

                Menu menuDone = new Menu();
                menuDone.Priority = 0;
                menuDone.Name = "Done";
                menuDone.ActionOnClick = saveVehicle;
                CommonMenu.CreateMenu(this, menuDone);

                Menu menuCancel = new Menu();
                menuCancel.Priority = 1;
                menuCancel.Name = "Cancel";
                menuCancel.ActionOnClick = closeCurrentPage;
                CommonMenu.CreateMenu(this, menuCancel);
            }

            //if (!isAdd)
            //{
            //    btnDelete.Clicked += BtnDelete_Clicked;
            //}
            //else
            //{
            //    btnDelete.IsVisible = false;
            //}
            LoadVehicleTypes();
        }

        //private async void BtnDelete_Clicked(object sender, EventArgs e)
        //{
        //    bool isSuccess = await DisplayAlert("Delete", "Are you sure you want to delete this vehicle?", "Yes", "No");
        //    if (isSuccess)
        //    {
        //        var hud = new HUD("Deleting...");
        //        OperationResult operationResult = await memberHelper.DeleteVehicles(CurrentVehicle.SystemIdentifier);

        //        if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
        //        {
        //            hud.Dismiss();
        //            ToastHelper.ShowSuccessToast("Success", "Vehicle deleted successfully");
        //            EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(ODISMember.AppConstants.Event.REFRESH_VEHICLES));
        //            Navigation.RemovePage(Navigation.NavigationStack[Navigation.NavigationStack.Count - 2]);
        //            await Navigation.PopAsync();
        //        }
        //        else
        //        {
        //            hud.Dismiss();
        //            if (operationResult != null && operationResult.ErrorMessage != null)
        //            {
        //                ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
        //            }
        //        }
        //    }
        //}

        string SetVehilcePhotoDefaultImage(string vehicleType)
        {
            if (vehicleType == "RV")
            {
                return ImagePathResources.VehicleRv;
            }
            else if (vehicleType == "Auto")
            {
                return ImagePathResources.VehicleCar;
            }
            else if (vehicleType == "Motorcycle")
            {
                return ImagePathResources.VehicleMotorCycle;
            }
            return string.Empty;
        }
        private void CustomActionBar_OnDoneClick(object sender, EventArgs e)
        {
            saveVehicle();
        }

        private void CustomActionBar_OnCloseClick(object sender, EventArgs e)
        {
            closeCurrentPage();
        }
        private void closeCurrentPage()
        {
            Navigation.PopAsync();
        }
        private void WidgetCountry_OnDropDownSelection(object sender, TextChangedEventArgs e)
        {
            widgetState.EntryText = string.Empty;
            Dictionary<string, string> countryParams = new Dictionary<string, string>();
            countryParams.Add("CountryId", widgetCountry.Value);
            widgetState.LoadItemSourceParam = countryParams;
        }

        private void WidgetMake_OnDropDownSelection(object sender, TextChangedEventArgs e)
        {
            if (!string.IsNullOrEmpty(VehicleTypeValue) && !string.IsNullOrEmpty(widgetMake.Key))
            {
                Dictionary<string, string> modelParams = new Dictionary<string, string>();
                modelParams.Add("VehicleTypeId", VehicleTypeValue);
                modelParams.Add("MakeId", widgetMake.Key);
                widgetModel.LoadItemSourceParam = modelParams;
            }
            if (widgetModel.EntryText != null)
            {
                widgetModel.EntryText = string.Empty;
                widgetModelOther.IsVisible = false;
                SelectedMakeModel = null;
            }
            OnMakeChange(widgetMake.EntryText.ToLower());
        }
        private void WidgetModel_OnDropDownSelection(object sender, TextChangedEventArgs e)
        {
            OnModelChange(widgetModel.Key.ToLower());
        }
        private void onVehicleTypeChange(string vehicleType)
        {
            if (vehicleType == "2")// 2 = RV
            {
                widgetVehicleColor.IsVisible = true;
                stackRV.IsVisible = true;
            }
            else if (vehicleType == "1" || vehicleType == "3") // 1 = Auto && 3 = Motorcycle
            {
                widgetVehicleColor.IsVisible = true;
                stackRV.IsVisible = false;
                InvisibleForRV();
            }
            else
            {
                widgetVehicleColor.IsVisible = false;
                stackRV.IsVisible = false;
                InvisibleForRV();
                widgetVehicleColor.EntryText = string.Empty;
            }
            if (widgetMake.EntryText != null)
            {
                widgetMake.EntryText = string.Empty;
            }
            if (widgetModel.EntryText != null)
            {
                widgetModel.EntryText = string.Empty;
                SelectedMakeModel = null;
            }

        }
        void InvisibleForRV()
        {
            widgetTransmission.EntryText = string.Empty;
            widgetEngine.EntryText = string.Empty;
            widgetChassis.EntryText = string.Empty;
            widgetLength.EntryText = string.Empty;
        }

        void LoadContent()
        {
            Device.BeginInvokeOnMainThread(() =>
            {
                onVehicleTypeChange(VehicleTypeValue);
                if (!isAdd)
                {
                    lblVehicleType.Text = string.Format(" - {0} Details - ", VehicleTypeKey);
                    imgUpload.DefaultImageSource = SetVehilcePhotoDefaultImage(CurrentVehicle.VehicleType);
                    imgUpload.SetImageSouce(CurrentVehicle.Photo);

                    widgetYear.EntryValue.Text = CurrentVehicle.Year;
                    widgetYear.Key = CurrentVehicle.Year;

                    widgetMake.EntryValue.Text = CurrentVehicle.Make;
                    widgetMake.Key = CurrentVehicle.Make;

                    if ("Other".Equals(CurrentVehicle.Make, StringComparison.CurrentCultureIgnoreCase))
                    {
                        widgetMakeOther.IsVisible = true;
                    }

                    widgetModel.EntryValue.Text = CurrentVehicle.Model;
                    widgetModel.Key = CurrentVehicle.Model;

                    if ("Other".Equals(CurrentVehicle.Model, StringComparison.CurrentCultureIgnoreCase))
                    {
                        widgetModelOther.IsVisible = true;
                    }

                    widgetMakeOther.EntryValue.Text = CurrentVehicle.MakeOther;
                    widgetModelOther.EntryValue.Text = CurrentVehicle.ModelOther;
                    widgetVIN.EntryValue.Text = CurrentVehicle.VIN;

                    widgetVehicleColor.EntryValue.Text = CurrentVehicle.Color;
                    widgetVehicleColor.Key = CurrentVehicle.Color;

                    widgetCountry.EntryValue.Text = CurrentVehicle.LicenseCountry;
                    widgetCountry.Key = CurrentVehicle.LicenseCountry;

                    widgetState.EntryValue.Text = CurrentVehicle.LicenseState;
                    widgetState.Value = CurrentVehicle.LicenseState;


                    LoadCountries(null);
                    if (widgetCountry.Value != null)
                    {
                        Dictionary<string, string> countryParams = new Dictionary<string, string>();
                        countryParams.Add("CountryId", widgetCountry.Value);
                        widgetState.LoadItemSourceParam = countryParams;
                    }

                    widgetLicensePlateNumber.EntryValue.Text = CurrentVehicle.LicenseNumber;
                    widgetTransmission.EntryValue.Text = CurrentVehicle.Transmission;
                    widgetTransmission.Key = CurrentVehicle.Transmission;

                    widgetEngine.EntryValue.Text = CurrentVehicle.Engine;
                    widgetEngine.Key = CurrentVehicle.Engine;

                    widgetChassis.EntryValue.Text = CurrentVehicle.Chassis;
                    widgetChassis.Key = CurrentVehicle.Chassis;

                    widgetLength.EntryValue.Text = CurrentVehicle.Length;

                    Dictionary<string, string> makeParams = new Dictionary<string, string>();
                    makeParams.Add("VehicleTypeId", VehicleTypeValue);
                    widgetMake.LoadItemSourceParam = makeParams;

                    Dictionary<string, string> modelParams = new Dictionary<string, string>();
                    modelParams.Add("VehicleTypeId", VehicleTypeValue);
                    modelParams.Add("MakeId", CurrentVehicle.Make);
                    widgetModel.LoadItemSourceParam = modelParams;


                }
                else
                {
                    ImageTextRadioButton imageTextRadioButton = new ImageTextRadioButton(VehicleTypeRadiobuttons);
                    stackVehicleTypes.Children.Add(imageTextRadioButton);
                    imageTextRadioButton.OnImageClick += ImageTextRadioButton_OnImageClick;
                }

                widgetLength.Behaviors.Add(new NumberValidatorBehavior_LabelEntryVertical() { IsRequired = false });
                widgetVIN.Behaviors.Add(new LengthValidatorBehavior_LabelEntryVertical() { Length = 17 });
                widgetLicensePlateNumber.Behaviors.Add(new CapitalConvertBehavior_LabelEntryVertical());
                widgetModel.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());
                widgetMake.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());
                widgetYear.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());

                widgetCountry.OnDropDownSelection += WidgetCountry_OnDropDownSelection;
                widgetModel.OnDropDownSelection += WidgetModel_OnDropDownSelection;
                widgetMake.OnDropDownSelection += WidgetMake_OnDropDownSelection;

                widgetYear.LoadItemSource = LoadYears;
                widgetMake.LoadItemSource = LoadMakes;
                widgetModel.LoadItemSource = LoadModels;
                widgetVehicleColor.LoadItemSource = LoadColors;
                widgetCountry.LoadItemSource = LoadCountries;
                widgetState.LoadItemSource = LoadStates;
                widgetTransmission.LoadItemSource = LoadTransmission;
                widgetEngine.LoadItemSource = LoadEngines;
                widgetChassis.LoadItemSource = LoadChassis;

            });

        }
        void OnModelChange(string model)
        {
            if (MakeModels == null || MakeModels.Count == 0)
            {
                MakeModels = memberHelper.GetLocalMakeModels();
            }
            SelectedMakeModel = MakeModels.Where(a => a.Id.ToString() == widgetModel.Value).FirstOrDefault();
            if (model.ToLower() == "other")
            {
                widgetModelOther.IsVisible = true;
            }
            else
            {
                widgetModelOther.IsVisible = false;
                widgetModelOther.EntryValue.Text = string.Empty;
            }
        }
        void OnMakeChange(string make)
        {
            if (make.ToLower() == "other")
            {
                widgetMakeOther.IsVisible = true;
            }
            else
            {
                widgetMakeOther.IsVisible = false;
                widgetMakeOther.EntryValue.Text = string.Empty;
            }

        }
        private void ImageTextRadioButton_OnImageClick(object sender, EventArgs e)
        {
            var radio = sender as RadioButtonItem;
            if (radio != null)
            {
                if (Device.OS == TargetPlatform.Android)
                {
                    VehicleCustomActionBar.OnDoneClick -= CustomActionBar_OnDoneClick;
                    VehicleCustomActionBar.OnDoneClick += CustomActionBar_OnDoneClick;
                    VehicleCustomActionBar.BtnDone.TextColor = Color.Black;// ColorResources.ToolbarMenuColor;
                }

                stackVehicleFields.IsVisible = true;
                VehicleTypeKey = radio.Text;
                VehicleTypeValue = vehicleTypes[VehicleTypeKey];
                onVehicleTypeChange(VehicleTypeValue);

                Dictionary<string, string> makeParams = new Dictionary<string, string>();
                makeParams.Add("VehicleTypeId", VehicleTypeValue);
                widgetMake.LoadItemSourceParam = makeParams;
                stackVehicleTypes.IsVisible = false;
                stackVehicleTypes.HeightRequest = 0;
                lblVehicleType.Text = string.Format(" - {0} Details - ", VehicleTypeKey);
                imgUpload.DefaultImageSource = SetVehilcePhotoDefaultImage(VehicleTypeKey);
            }
            else
            {
                if (Device.OS == TargetPlatform.Android)
                {
                    VehicleCustomActionBar.BtnDone.TextColor = Color.Silver;
                }
            }
        }
        #region Dropdowns
        public void LoadVehicleTypes()
        {
            var hud = new HUD("Loading..");
            vehicleTypes = new Dictionary<string, string>();
            var t = memberHelper.GetVehicleTypes(Constants.MEMBER_PROGRAM_ID);
            t.ContinueWith(x =>
            {
                if (!x.IsFaulted)
                {
                    OperationResult operationResult = (OperationResult)x.Result;
                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
                    {
                        List<KeyValuePair<string, string>> vehicleTypeList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                        if (vehicleTypeList.Count > 0)
                        {
                            vehicleTypes = vehicleTypeList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
                            if (isAdd)
                            {
                                VehicleTypeRadiobuttons = new List<RadioButtonItem>();
                                foreach (string key in vehicleTypes.Keys)
                                {
                                    VehicleTypeRadiobuttons.Add(new RadioButtonItem()
                                    {
                                        Text = key,
                                        SelectedImageURL = SetVehilcePhotoDefaultImage(key),
                                        UnSelectedImageURL = SetVehilcePhotoDefaultImage(key)
                                    });
                                }
                            }
                            else
                            {
                                if (vehicleTypes.ContainsKey(CurrentVehicle.VehicleType))
                                {
                                    KeyValuePair<string, string> vehicleTypeSelectedItem = vehicleTypes.Where(a => a.Key == CurrentVehicle.VehicleType).First();
                                    if (vehicleTypeSelectedItem.Key != null && vehicleTypeSelectedItem.Value != null)
                                    {
                                        VehicleTypeKey = vehicleTypeSelectedItem.Key;
                                        VehicleTypeValue = vehicleTypeSelectedItem.Value;
                                    }
                                }

                            }
                        }
                        LoadContent();
                    }
                    else
                    {
                        if (operationResult != null && operationResult.ErrorMessage != null)
                        {
                            ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                        }
                    }
                    hud.Dismiss();
                }
                else
                {
                    ToastHelper.ShowErrorToast("Error", "Unable to get vehicle types");
                }
            });

        }


        public Dictionary<string, string> LoadChassis(Dictionary<string, string> inputs)
        {
            Dictionary<string, string> chassis = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalVehicleChassis()).Result;
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> chassisList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (chassisList.Count > 0)
                {
                    chassis = chassisList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
                    if (!isAdd && chassis.ContainsKey(CurrentVehicle.Chassis))
                    {
                        widgetChassis.SelectedItem = chassis.Where(a => a.Key == CurrentVehicle.Chassis).First();
                        widgetChassis.EntryValue.Text = widgetChassis.Key;
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
            return chassis;
        }
        public Dictionary<string, string> LoadColors(Dictionary<string, string> inputs)
        {
            Dictionary<string, string> colors = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalVehicleColors()).Result;
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> colorList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (colorList.Count > 0)
                {
                    colors = colorList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
                    if (!isAdd && colors.ContainsKey(CurrentVehicle.Color))
                    {
                        widgetVehicleColor.SelectedItem = colors.Where(a => a.Key == CurrentVehicle.Color).First();
                        widgetVehicleColor.EntryValue.Text = widgetVehicleColor.Key;
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
            return colors;
        }
        public Dictionary<string, string> LoadEngines(Dictionary<string, string> inputs)
        {
            Dictionary<string, string> engines = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalVehicleEngines()).Result;
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> engineList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (engineList.Count > 0)
                {
                    engines = engineList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
                    if (!isAdd && engines.ContainsKey(CurrentVehicle.Engine))
                    {
                        widgetEngine.SelectedItem = engines.Where(a => a.Key == CurrentVehicle.Engine).First();
                        widgetEngine.EntryValue.Text = widgetEngine.Key;
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
            return engines;
        }
        public Dictionary<string, string> LoadMakes(Dictionary<string, string> inputs)//string vehicleTypeId)
        {
            Dictionary<string, string> makes = new Dictionary<string, string>();
            if (inputs != null && inputs.Count > 0)
            {
                if (MakeModels == null || MakeModels.Count == 0)
                {
                    MakeModels = memberHelper.GetLocalMakeModels();
                }
                var result = MakeModels.Where(a => a.VehicleTypeID.Value.ToString() == inputs["VehicleTypeId"]).GroupBy(test => test.Make)
                       .Select(grp => grp.First())
                       .ToList();

                List<KeyValuePair<string, string>> makeList = new List<KeyValuePair<string, string>>();
                KeyValuePair<string, string> other = new KeyValuePair<string, string>("Other", "Other");
                makeList.Insert(0, other);
                List<KeyValuePair<string, string>> makeListItems = result.ToDictionary(pair => pair.Make, pair => pair.Make.ToString()).ToList();
                makeList.InsertRange(1, makeListItems.OrderBy(a => a.Key));
                makes = makeList.ToDictionary(a => a.Key, a => a.Value);
            }
            return makes;
        }
        public Dictionary<string, string> LoadModels(Dictionary<string, string> inputs)//(string vehicleTypeId, string makeId)
        {
            Dictionary<string, string> models = new Dictionary<string, string>();
            if (inputs != null && inputs.Count > 0)
            {
                if (MakeModels == null || MakeModels.Count == 0)
                {
                    MakeModels = memberHelper.GetLocalMakeModels();
                }
                var result = MakeModels.Where(a => (a.VehicleTypeID.Value.ToString() == inputs["VehicleTypeId"]) && (a.Make == inputs["MakeId"])).ToList();

                List<KeyValuePair<string, string>> modelList = new List<KeyValuePair<string, string>>();
                KeyValuePair<string, string> other = new KeyValuePair<string, string>("Other", "Other");
                modelList.Insert(0, other);
                List<KeyValuePair<string, string>> modelListItems = result.ToDictionary(pair => pair.Model.Trim(), pair => pair.Id.ToString()).ToList();
                modelList.InsertRange(1, modelListItems.OrderBy(a => a.Key));
                models = modelList.ToDictionary(a => a.Key, a => a.Value);
            }
            return models;
        }
        public Dictionary<string, string> LoadYears(Dictionary<string, string> inputs)
        {
            Dictionary<string, string> years = new Dictionary<string, string>();
            for (int y = DateTime.Now.Year; y >= 1957; y--)
            {
                years.Add(y.ToString(), y.ToString());
            }

            if (!isAdd && years.ContainsKey(CurrentVehicle.Year))
            {
                widgetYear.SelectedItem = years.Where(a => a.Key == CurrentVehicle.Year).First();
                widgetYear.EntryValue.Text = widgetYear.Key;
            }
            return years;
        }

        public Dictionary<string, string> LoadTransmission(Dictionary<string, string> inputs)
        {
            Dictionary<string, string> transmission = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalVehicleTransmissions()).Result;
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> transmissionList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (transmissionList.Count > 0)
                {
                    transmission = transmissionList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
                    if (!isAdd && transmission.ContainsKey(CurrentVehicle.Transmission))
                    {
                        widgetTransmission.SelectedItem = transmission.Where(a => a.Key == CurrentVehicle.Transmission).First();
                        widgetTransmission.EntryValue.Text = widgetTransmission.Key;
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
            return transmission;
        }
        public Dictionary<string, string> LoadCountries(Dictionary<string, string> inputs)
        {
            Dictionary<string, string> countries = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalCountryCodes()).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS)
            {
                List<Countries> countryList = JsonConvert.DeserializeObject<List<Countries>>(operationResult.Data.ToString());
                if (countryList.Count > 0)
                {
                    countries = countryList.ToDictionary(pair => pair.ISOCode, pair => pair.SystemIdentifier.ToString());

                    if (!isAdd && countries.ContainsKey(CurrentVehicle.LicenseCountry))
                    {
                        widgetCountry.SelectedItem = countries.Where(a => a.Key == CurrentVehicle.LicenseCountry).First();
                        widgetCountry.EntryValue.Text = widgetCountry.Key;
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
        public Dictionary<string, string> LoadStates(Dictionary<string, string> inputs)//(string countryId)
        {
            Dictionary<string, string> states = new Dictionary<string, string>();
            if (inputs != null && inputs.Count > 0)
            {
                OperationResult operationResult = Task.Run(() => memberHelper.GetStatesForCountry(inputs["CountryId"])).Result;
                if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS)
                {
                    List<KeyValuePair<string, string>> stateList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                    if (stateList.Count > 0)
                    {
                        states = stateList.ToDictionary(pair => pair.Key + "-" + pair.Value, pair => pair.Key.ToString());

                        if (states.ContainsValue(CurrentVehicle.LicenseState))
                        {
                            widgetState.SelectedItem = states.Where(a => a.Value == CurrentVehicle.LicenseState).First();
                            widgetState.EntryValue.Text = widgetState.Value;
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
            }
            return states;
        }

        #endregion
        async void saveVehicle()
        {
            if (Device.OS == TargetPlatform.iOS && isAdd)
            {
                if (string.IsNullOrEmpty(VehicleTypeKey))
                {
                    ToastHelper.ShowWarningToast("Warning", "Please select vehicle type..");
                    return;
                }
            }


            string loadingText = "Updating Vehicle...";
            if (isAdd)
            {
                loadingText = "Adding Vehicle...";
            }

            widgetMake.onValidate();
            widgetModel.onValidate();
            widgetYear.onValidate();
            if (widgetMake.IsValid && widgetModel.IsValid && widgetYear.IsValid && widgetLength.onValidate() && widgetVIN.onValidate())
            {
                using (new HUD(loadingText))
                {
                    MemberHelper memberHelper = new MemberHelper();
                    if (SelectedMakeModel != null)
                    {
                        CurrentVehicle.VehicleCategory = SelectedMakeModel.VehicleCategory;
                        CurrentVehicle.RVType = SelectedMakeModel.RVType;
                    }
                    else
                    {
                        CurrentVehicle.VehicleCategory = null;
                        CurrentVehicle.RVType = null;
                    }

                    //if (!imgUpload.IsDefaultImage)
                    //{
                    //    byte[] imgBytes = await imgUpload.GetImageBytes(Constants.FFIMAGE_VEHICLE_HEIGHT, Constants.FFIMAGE_VEHICLE_WIDTH);//(int)(App.ScreenHeight / 3), (int)App.ScreenWidth);
                    //    CurrentVehicle.Photo = imgBytes;
                    //}
                    CurrentVehicle.VehicleType = VehicleTypeKey;
                    CurrentVehicle.Make = widgetMake.Key;
                    CurrentVehicle.Model = widgetModel.Key;
                    CurrentVehicle.VIN = widgetVIN.EntryValue.Text;
                    CurrentVehicle.Year = widgetYear.Key;
                    CurrentVehicle.MakeOther = widgetMakeOther.EntryValue.Text;
                    CurrentVehicle.ModelOther = widgetModelOther.EntryValue.Text;
                    CurrentVehicle.Color = widgetVehicleColor.Key;
                    CurrentVehicle.LicenseNumber = widgetLicensePlateNumber.EntryValue.Text;
                    CurrentVehicle.LicenseState = widgetState.Value;
                    CurrentVehicle.LicenseCountry = widgetCountry.Key;

                    CurrentVehicle.Transmission = widgetTransmission.Key;
                    CurrentVehicle.Engine = widgetEngine.Key;
                    CurrentVehicle.Chassis = widgetChassis.Key;
                    CurrentVehicle.Length = widgetLength.EntryValue.Text;

                    List<VehicleModel> vehicleModels = new List<VehicleModel>();
                    vehicleModels.Add(CurrentVehicle);
                    OperationResult operationResult;
                    if (isAdd)
                    {
                        operationResult = await memberHelper.AddVehicles(vehicleModels);
                    }
                    else
                    {
                        operationResult = await memberHelper.UpdateVehicles(vehicleModels);
                    }
                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
                    {
                        string message = "Vehicle updated successfully";
                        if (isAdd)
                        {
                            message = "Vehicle Added successfully";
                        }
                        ToastHelper.ShowSuccessToast("Success", message);
                        EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(ODISMember.AppConstants.Event.REFRESH_VEHICLES));
                        if (!isAdd)
                        {
                            EventDispatcher.RaiseEvent(CurrentVehicle, new RefreshEventArgs(ODISMember.AppConstants.Event.REFRESH_CURRENT_VEHICLE));
                        }
                        await Navigation.PopAsync(false);
                    }
                    else
                    {
                        if (operationResult != null && operationResult.ErrorMessage != null)
                        {
                            ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                        }
                    }
                }
            }
        }
    }
}
