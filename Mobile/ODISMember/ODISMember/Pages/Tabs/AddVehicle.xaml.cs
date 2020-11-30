using System;
using Xamarin.Forms;
using System.Threading.Tasks;
using ODISMember.Helpers.UIHelpers;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using System.Collections.Generic;
using ODISMember.Behaviors;
using ODISMember.Classes;
using ODISMember.Shared;
using Newtonsoft.Json;
using System.Linq;
using ODISMember.Services.Service;
using ODISMember.Entities.Table;
using ODISMember.Widgets;

namespace ODISMember.Pages.Tabs
{
    public partial class AddVehicle : ContentPage
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
        public AddVehicle()
        {
            InitializeComponent();
            logger.TrackPageView(PageNames.VEHICLES_ADD);
            NavigationPage.SetHasNavigationBar(this, false);
            Title = "Add Vehicle";
            CurrentVehicle = new VehicleModel();
            CurrentVehicle.PersonId = Constants.PersonID;
            LoadDropdowns();
            this.BindingContext = CurrentVehicle;
            widgetLength.Behaviors.Add(new NumberValidatorBehavior_LabelEntryVertical() { IsRequired = false });
            widgetGrossWeight.Behaviors.Add(new NumberValidatorBehavior_LabelEntryVertical() { IsRequired = false });
            widgetVIN.Behaviors.Add(new LengthValidatorBehavior_LabelEntryVertical() { Length = 17 });
            widgetLicensePlateNumber.Behaviors.Add(new CapitalConvertBehavior_LabelEntryVertical());

            imgUpload = new CustomImageUpload(this,false)
            {
                CurrentPage = this,
                IsBottomButtonsVisible = false,
                ImageHeight = Constants.FFIMAGE_VEHICLE_HEIGHT,
                ImageWidth = Constants.FFIMAGE_VEHICLE_WIDTH,
                DefaultImageSource = ImagePathResources.AddVehicleActive
            };
            stackImageUpload.Children.Add(imgUpload);
         
            widgetModel.OnDropDownSelection += WidgetModel_OnDropDownSelection;
            widgetMake.OnDropDownSelection += WidgetMake_OnDropDownSelection;
            widgetCountry.OnDropDownSelection += WidgetCountry_OnDropDownSelection;

            widgetModel.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());
            widgetMake.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());
            widgetYear.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());

            //Removing Gross weight
            widgetGrossWeight.IsVisible = false;

            VehicleCustomActionBar = new CustomActionBar("Add Vehicle");
            stackCustomActionBar.Children.Add(VehicleCustomActionBar);
            VehicleCustomActionBar.OnCloseClick += CustomActionBar_OnCloseClick;
            VehicleCustomActionBar.BtnDone.TextColor = Color.Silver;
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
            widgetState.ItemSource = LoadStates(widgetCountry.Value);
        }

        private void WidgetMake_OnDropDownSelection(object sender, TextChangedEventArgs e)
        {
            widgetModel.ItemSource = LoadModels(VehicleTypeValue, widgetMake.Key);
            if (widgetModel.EntryText != null)
            {
                widgetModel.EntryText = string.Empty;
                SelectedMakeModel = null;
            }
            if (widgetMake.Key.ToLower() == "other")
            {
                widgetMakeOther.IsVisible = true;
            }
            else
            {
                widgetMakeOther.IsVisible = false;
                widgetMakeOther.EntryValue.Text = string.Empty;
            }
        }
        private void WidgetModel_OnDropDownSelection(object sender, TextChangedEventArgs e)
        {
            SelectedMakeModel = MakeModels.Where(a => a.Id.ToString() == widgetModel.Value).FirstOrDefault();

            if (widgetModel.Key.ToLower() == "other")
            {
                widgetModelOther.IsVisible = true;
            }
            else
            {
                widgetModelOther.IsVisible = false;
                widgetModelOther.EntryValue.Text = string.Empty;
            }
        }
        private void onVehicleTypeChange(string vehicleType)
        {
            widgetMake.ItemSource = LoadMakes(vehicleType);

            if (widgetMake.SelectedItem != null)
            {
                widgetModel.ItemSource = LoadModels(vehicleType, widgetMake.SelectedItem.Value.Key);
            }

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
            widgetGrossWeight.EntryText = string.Empty;
        }
        public void LoadDropdowns()
        {
            LoadVehicleTypes();
            ImageTextRadioButton imageTextRadioButton = new ImageTextRadioButton(VehicleTypeRadiobuttons);
            stackVehicleTypes.Children.Add(imageTextRadioButton);
            imageTextRadioButton.OnImageClick += ImageTextRadioButton_OnImageClick;

            widgetYear.ItemSource = LoadYears();
            widgetTransmission.ItemSource = LoadTransmission();
            widgetEngine.ItemSource = LoadEngines();
            widgetChassis.ItemSource = LoadChassis();
            widgetVehicleColor.ItemSource = LoadColors();
            widgetCountry.ItemSource = LoadCountries();
        }

        private void ImageTextRadioButton_OnImageClick(object sender, EventArgs e)
        {
            var radio = sender as RadioButtonItem;
            if (radio != null)
            {
                VehicleCustomActionBar.OnDoneClick -= CustomActionBar_OnDoneClick;
                VehicleCustomActionBar.OnDoneClick += CustomActionBar_OnDoneClick;
                VehicleCustomActionBar.BtnDone.TextColor = ColorResources.ToolbarMenuColor;

                stackVehicleFields.IsVisible = true;
                VehicleTypeKey = radio.Text;
                VehicleTypeValue = vehicleTypes[VehicleTypeKey];
                onVehicleTypeChange(VehicleTypeValue);
            }
            else
            {
                VehicleCustomActionBar.BtnDone.TextColor = Color.Silver;
            }
        }
        #region Dropdowns
        public void LoadVehicleTypes()
        {
            vehicleTypes = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetVehicleTypes(Constants.MEMBER_PROGRAM_ID)).Result;
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> vehicleTypeList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (vehicleTypeList.Count > 0)
                {
                    vehicleTypes = vehicleTypeList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());

                    VehicleTypeRadiobuttons = new List<RadioButtonItem>();
                    foreach (string key in vehicleTypes.Keys)
                    {
                        VehicleTypeRadiobuttons.Add(new RadioButtonItem()
                        {
                            Text = key,
                            SelectedImageURL = ImagePathResources.TowService,
                            UnSelectedImageURL = ImagePathResources.TowServiceDisabled
                        });
                    }

                    //BindableRadioGroup memberPlanRadiouGroup = new BindableRadioGroup();
                    //memberPlanRadiouGroup.Orientation = StackOrientation.Vertical;
                    //memberPlanRadiouGroup.ItemsSource = VehicleTypeRadiobuttons;
                    //stackVehicleTypes.Children.Add(memberPlanRadiouGroup);
                    //memberPlanRadiouGroup.CheckedChanged += MemberPlanRadiouGroup_CheckedChanged;
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
        

        public Dictionary<string, string> LoadChassis()
        {
            Dictionary<string, string> chassis = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalVehicleChassis()).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> chassisList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (chassisList.Count > 0)
                {
                    chassis = chassisList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
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
        public Dictionary<string, string> LoadColors()
        {
            Dictionary<string, string> colors = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalVehicleColors()).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> colorList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (colorList.Count > 0)
                {
                    colors = colorList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
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
        public Dictionary<string, string> LoadEngines()
        {
            Dictionary<string, string> engines = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalVehicleEngines()).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> engineList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (engineList.Count > 0)
                {
                    engines = engineList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
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
        public Dictionary<string, string> LoadMakes(string vehicleTypeId)
        {
            MakeModels = memberHelper.GetLocalMakeModels();
            var result = MakeModels.Where(a => a.VehicleTypeID.Value.ToString() == vehicleTypeId).GroupBy(test => test.Make)
                   .Select(grp => grp.First())
                   .ToList();
            Dictionary<string, string> makes = new Dictionary<string, string>();
            makes = result.ToDictionary(pair => pair.Make, pair => pair.Make.ToString());
            return makes;
        }
        public Dictionary<string, string> LoadModels(string vehicleTypeId, string makeId)
        {
            var result = MakeModels.Where(a => (a.VehicleTypeID.Value.ToString() == vehicleTypeId) && (a.Make == makeId)).ToList();
            Dictionary<string, string> models = new Dictionary<string, string>();
            models = result.ToDictionary(pair => pair.Model, pair => pair.Id.ToString());
            return models;
        }
        public Dictionary<string, string> LoadYears()
        {
            Dictionary<string, string> years = new Dictionary<string, string>();
            for (int y = DateTime.Now.Year; y >= 1957; y--)
            {
                years.Add(y.ToString(), y.ToString());
            }
            return years;
        }

        public Dictionary<string, string> LoadTransmission()
        {
            Dictionary<string, string> transmission = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalVehicleTransmissions()).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> transmissionList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (transmissionList.Count > 0)
                {
                    transmission = transmissionList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
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
        public Dictionary<string, string> LoadCountries()
        {
            Dictionary<string, string> countries = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalCountryCodes()).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<Countries> countryList = JsonConvert.DeserializeObject<List<Countries>>(operationResult.Data.ToString());
                if (countryList.Count > 0)
                {
                    countries = countryList.ToDictionary(pair => pair.ISOCode, pair => pair.SystemIdentifier.ToString());
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
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> stateList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (stateList.Count > 0)
                {
                    states = stateList.ToDictionary(pair => pair.Key + "-" + pair.Value, pair => pair.Key.ToString());
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

        #endregion
        private async void saveVehicle()
        {
            widgetMake.onValidate();
            widgetModel.onValidate();
            widgetYear.onValidate();

            if (widgetMake.IsValid && widgetModel.IsValid && widgetYear.IsValid && widgetGrossWeight.onValidate() && widgetLength.onValidate() && widgetVIN.onValidate())
            {
                using (new HUD("Adding Vehicle..."))
                {
                    //byte[] imgBytes = await imgUpload.GetImageBytes(Constants.FFIMAGE_VEHICLE_HEIGHT, Constants.FFIMAGE_VEHICLE_WIDTH);
                    //if (imgBytes != null)
                    //{
                    //    CurrentVehicle.Photo = imgBytes;
                    //}
                    if (!imgUpload.IsDefaultImage)
                    {
                        byte[] imgBytes = await imgUpload.GetImageBytes(Constants.FFIMAGE_VEHICLE_HEIGHT, Constants.FFIMAGE_VEHICLE_WIDTH);
                        CurrentVehicle.Photo = imgBytes;
                    }
                    if (SelectedMakeModel != null)
                    {
                        CurrentVehicle.VehicleCategory = SelectedMakeModel.VehicleCategory;
                        CurrentVehicle.RVType = SelectedMakeModel.RVType;
                    }

                    CurrentVehicle.VehicleType = this.VehicleTypeKey;
                    CurrentVehicle.Year = widgetYear.Key;
                    CurrentVehicle.Make = widgetMake.Key;
                    CurrentVehicle.Model = widgetModel.Key;
                    CurrentVehicle.MakeOther = widgetMakeOther.EntryValue.Text;
                    CurrentVehicle.ModelOther = widgetModelOther.EntryValue.Text;
                    CurrentVehicle.VIN = widgetVIN.EntryValue.Text;
                    CurrentVehicle.Color = widgetVehicleColor.Key;
                    CurrentVehicle.LicenseNumber = widgetLicensePlateNumber.EntryValue.Text;
                    CurrentVehicle.LicenseState = widgetState.Value;
                    CurrentVehicle.LicenseCountry = widgetCountry.Key;                    
                    if (stackRV.IsVisible)
                    {
                        CurrentVehicle.Transmission = widgetTransmission.Key;
                        CurrentVehicle.Engine = widgetEngine.Key;
                        CurrentVehicle.Chassis = widgetChassis.Key;
                        CurrentVehicle.Length = widgetLength.EntryValue.Text;
                        if (!string.IsNullOrEmpty(widgetGrossWeight.EntryValue.Text))
                        {
                            // CurrentVehicle.GrossWeight = decimal.Parse(widgetGrossWeight.EntryValue.Text);
                        }
                    }
                    CurrentVehicle.MemberNumber = Constants.MEMBER_NUMBER;
                    List<VehicleModel> vehicleModels = new List<VehicleModel>();
                    vehicleModels.Add(CurrentVehicle);
                    var json = Newtonsoft.Json.JsonConvert.SerializeObject(vehicleModels);
                    OperationResult operationResult = await memberHelper.AddVehicles(vehicleModels);
                    if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS)
                    {
                        ToastHelper.ShowSuccessToast("Success", "Vehicle Added Successfully");
                        EventDispatcher.RaiseEvent(new object(), new RefreshEventArgs(ODISMember.AppConstants.Event.REFRESH_VEHICLES));
                        //this.Navigation.RemovePage(this.Navigation.NavigationStack[this.Navigation.NavigationStack.Count - 2]);
                        await this.Navigation.PopAsync();
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

