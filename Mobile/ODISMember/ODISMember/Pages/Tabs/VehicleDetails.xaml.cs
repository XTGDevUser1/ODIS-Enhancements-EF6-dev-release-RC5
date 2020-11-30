using System;
using System.Collections.Generic;
using System.Linq;
using Xamarin.Forms;
using ODISMember.Model;
using ODISMember.Entities.Model;
using ODISMember.CustomControls;
using ODISMember.Helpers.UIHelpers;
using System.Threading.Tasks;
using ODISMember.Entities;
using ODISMember.Classes;
using ODISMember.Behaviors;
using ODISMember.Shared;
using Newtonsoft.Json;
using ODISMember.Services.Service;
using ODISMember.Entities.Table;
using System.IO;
using ODISMember.Pages.Tabs;

namespace ODISMember
{
    public partial class VehicleDetails : ContentPage
    {
        public VehicleModel CurrentVehicle
        {
            get;
            set;
        }

        MemberHelper memberHelper = new MemberHelper();
        LoggerHelper logger = new LoggerHelper();
        public VehicleDetails(VehicleModel vehicle)
        {
            InitializeComponent();

            //tracking page view
            logger.TrackPageView(PageNames.VEHICLE_DETAILS);

            CurrentVehicle = vehicle;
            Title = "Vehicle Detail";
            //this.BindingContext = CurrentVehicle;
            

            //vehicleImage.HeightRequest = App.ScreenHeight / 3;
            //vehicleImage.WidthRequest = App.ScreenWidth;
            loadData();
            Menu menu = new Menu();
           // menu.Icon = ImagePathResources.SaveIcon;
            menu.Priority = 0;
            menu.Name = "Edit";
            menu.ToolbarItemOrder = 0;
            menu.ActionOnClick += openEdit;
            CommonMenu.CreateMenu(this, menu);

            //if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            //{
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            //}
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {

            if (e.EventId == AppConstants.Event.REFRESH_CURRENT_VEHICLE)
            {
                if (sender != null)
                {

                    CurrentVehicle = (VehicleModel)sender;
                    loadData();
                }
            }
        }

        private void loadData()
        {
            Device.BeginInvokeOnMainThread(() =>
            {
                //if (CurrentVehicle.Photo != null && CurrentVehicle.Photo.Length > 0)
                //{
                //    vehicleImage.Source = Xamarin.Forms.ImageSource.FromStream(() =>
                //    {

                //        Stream stream = new MemoryStream(CurrentVehicle.Photo);
                //        return stream;
                //    });
                //}
                //else if (CurrentVehicle.Photo == null || CurrentVehicle.Photo.Length == 0)
                //{
                //    if (CurrentVehicle.VehicleType == "RV")
                //    {
                //        vehicleImage.Source = ImagePathResources.VehicleRv;
                //        vehicleImage.LoadingPlaceholder = ImagePathResources.VehicleRv;
                //        vehicleImage.ErrorPlaceholder = ImagePathResources.VehicleRv;

                //    }
                //    else if (CurrentVehicle.VehicleType == "Auto")
                //    {
                //        vehicleImage.Source = ImagePathResources.VehicleCar;
                //        vehicleImage.LoadingPlaceholder = ImagePathResources.VehicleCar;
                //        vehicleImage.ErrorPlaceholder = ImagePathResources.VehicleCar;
                //    }
                //    else if (CurrentVehicle.VehicleType == "Motorcycle")
                //    {
                //        vehicleImage.Source = ImagePathResources.VehicleMotorCycle;
                //        vehicleImage.LoadingPlaceholder = ImagePathResources.VehicleMotorCycle;
                //        vehicleImage.ErrorPlaceholder = ImagePathResources.VehicleMotorCycle;
                //    }
                //}
                lblVehicleType.Text = string.Format(" - {0} Details - ", CurrentVehicle.VehicleType);
                lblVehicleYaerMakeModel.Text = CurrentVehicle.Year + " " + CurrentVehicle.Make + " " + CurrentVehicle.Model;
                lblYear.ValueText = CurrentVehicle.Year;
                lblMake.ValueText = CurrentVehicle.Make;
                lblModel.ValueText = CurrentVehicle.Model;
                lblColor.ValueText = CurrentVehicle.Color;
                lblVin.ValueText = CurrentVehicle.VIN;
                lblLicenseCountry.ValueText = CurrentVehicle.LicenseCountry;
                lblLicenseNumber.ValueText = CurrentVehicle.LicenseNumber;
                lblLicenseState.ValueText = CurrentVehicle.LicenseState;
            });
        }

        private void openEdit()
        {
            Navigation.PushAsync(new AddEditVehicle(CurrentVehicle),false);
        }
    }
}

