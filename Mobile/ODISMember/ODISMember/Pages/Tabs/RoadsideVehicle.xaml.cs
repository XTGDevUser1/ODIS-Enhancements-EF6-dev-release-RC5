using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ODISMember.Entities.Model;

using Xamarin.Forms;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Classes;
using ODISMember.Entities;
using Newtonsoft.Json;
using ODISMember.Shared;

namespace ODISMember.Pages.Tabs
{
    public partial class RoadsideVehicle : ContentPage
    {
        ServiceRequestModel serviceRequestModel;

        public RangeEnabledObservableCollection<VehicleModel> VehicleList
        {
            get;
            set;
        }
        bool isNextClicked = false;
        public RoadsideVehicle(ServiceRequestModel serviceRequestModel)
        {
            InitializeComponent();
            isNextClicked = false;
            this.serviceRequestModel = serviceRequestModel;

            this.Title = "Choose a Vehicle";
            this.BackgroundColor = ColorResources.RoadsideVehicleLayoutBackground;

            VehicleList = new RangeEnabledObservableCollection<VehicleModel>();
            listVehicle.ItemsSource = VehicleList;
            listVehicle.ItemTemplate = new DataTemplate(typeof(VehicleCell));
            listVehicle.ItemSelected += ListVehicle_ItemSelected;
            listVehicle.SeparatorVisibility = SeparatorVisibility.None;


            Menu menu = new Menu();
            //menu.Icon = ImagePathResources.AddIcon;
            menu.Priority = 0;
            menu.Name = "Add";
            menu.ToolbarItemOrder = 0;
            menu.ActionOnClick += OpenAddVehicle;
            CommonMenu.CreateMenu(this, menu);
            Global.AddPage(this);

            //if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            //{
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
           // }

            LoadData();
        }

        void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.REFRESH_VEHICLES)
            {
                LoadDataOnRefresh();
            }
        }
        private async void LoadDataOnRefresh()
        {

            stackVehicleSync.IsVisible = true;
            MemberHelper memberHelper = new MemberHelper();
            OperationResult operationResult = await memberHelper.GetVehicles();

            if (operationResult != null)
            {
                if (operationResult.Status == OperationStatus.SUCCESS)
                {
                    VehicleList.Clear();
                    if (operationResult.Data != null)
                    {
                        List<VehicleModel> vehicles = JsonConvert.DeserializeObject<List<VehicleModel>>(operationResult.Data.ToString());
                        VehicleList.InsertRange(vehicles);
                    }
                }
                else if (operationResult.Status == OperationStatus.INFO)
                {

                    ToastHelper.ShowInfoToast("Information", operationResult.ErrorMessage);
                }
                else
                {
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
            if (VehicleList.Count == 0)
            {
                lblNoRecords.IsVisible = true;
                listVehicle.IsVisible = false;
            }
            else
            {
                lblNoRecords.IsVisible = false;
                listVehicle.IsVisible = true;
            }
            stackVehicleSync.IsVisible = false;
        }
        void OpenAddVehicle()
        {
            isNextClicked = true;
            Navigation.PushAsync(new AddEditVehicle(),false);//(new VehicleType());
        }

        private void LoadData()
        {
            Device.BeginInvokeOnMainThread(() =>
            {

                HUD load = new HUD("Loading...");
                MemberHelper memberHelper = new MemberHelper();
                var result = memberHelper.GetVehicles();
                result.ContinueWith(x =>
                {
                    if (x.IsCompleted && !x.IsFaulted)
                    {
                        OperationResult operationResult = x.Result;
                        VehicleList.Clear();
                        if (operationResult != null)
                        {
                            if (operationResult.Status == OperationStatus.SUCCESS)
                            {
                                if (operationResult.Data != null)
                                {
                                    List<VehicleModel> vehicles = JsonConvert.DeserializeObject<List<VehicleModel>>(operationResult.Data.ToString());
                                    VehicleList.InsertRange(vehicles);
                                }
                                load.Dismiss();
                            }
                            else if (operationResult.Status == OperationStatus.INFO)
                            {
                                load.Dismiss();
                                ToastHelper.ShowInfoToast("Information", operationResult.ErrorMessage);
                            }
                            else
                            {
                                load.Dismiss();

                                ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                            }
                        }
                        else
                        {
                            load.Dismiss();
                        }

                        if (VehicleList.Count == 0)
                        {
                            lblNoRecords.IsVisible = true;
                            listVehicle.IsVisible = false;
                        }
                        else
                        {
                            lblNoRecords.IsVisible = false;
                            listVehicle.IsVisible = true;
                        }

                    }
                    else
                    {
                        load.Dismiss();
                    }
                });
            });
        }

        void ListVehicle_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null)
            {
                VehicleModel vehicle = (VehicleModel)e.SelectedItem;
                serviceRequestModel.VehicleType = vehicle.VehicleType;
                serviceRequestModel.VehicleID = Convert.ToInt32(vehicle.SystemIdentifier);
                //serviceRequestModel.VehicleVIN = vehicle.VIN;
                if (!string.IsNullOrEmpty(vehicle.Make) && vehicle.Make.ToLower() == "other")
                {
                    serviceRequestModel.VehicleMake = vehicle.MakeOther;
                }
                else
                {
                    serviceRequestModel.VehicleMake = vehicle.Make;
                }
                if (!string.IsNullOrEmpty(vehicle.Model) && vehicle.Model.ToLower() == "other")
                {
                    serviceRequestModel.VehicleModel = vehicle.ModelOther;
                }
                else
                {
                    serviceRequestModel.VehicleModel = vehicle.Model;
                }
                serviceRequestModel.VehicleColor = vehicle.Color;
                serviceRequestModel.VehicleVIN = vehicle.VIN;                
                serviceRequestModel.VehicleYear = vehicle.Year != null ? Convert.ToInt32(vehicle.Year) : (int?)null;
                serviceRequestModel.VehicleChassis = vehicle.Chassis;
                serviceRequestModel.VehicleEngine = vehicle.Engine;
                serviceRequestModel.LicenseState = vehicle.LicenseState;
                serviceRequestModel.LicenseNumber = vehicle.LicenseNumber;
                serviceRequestModel.LicenseCountry = vehicle.LicenseCountry;
                serviceRequestModel.VehicleCategory = vehicle.VehicleCategory;
                serviceRequestModel.RVType = vehicle.RVType;

                listVehicle.SelectedItem = null;
                isNextClicked = true;
                Navigation.PushAsync(new RoadsideVehicleService(vehicle, serviceRequestModel));
            }
        }

        protected override bool OnBackButtonPressed()
        {
            return base.OnBackButtonPressed();
        }
        
        
        protected override void OnDisappearing()
        {
            
            if (!isNextClicked)
            {

                EventDispatcher.RaiseEvent(serviceRequestModel, new RefreshEventArgs(AppConstants.Event.ADD_SOURCE_MAP));
            }
            else
            {
                isNextClicked = false;
            }
            base.OnDisappearing();
        }
    }
}
