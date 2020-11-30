using System;
using System.Collections.Generic;
using Xamarin.Forms;
using System.Collections.ObjectModel;
using ODISMember.Model;
using ODISMember.Classes;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Entities;
using System.Threading.Tasks;
using Newtonsoft.Json;
using System.IO;
using ODISMember.Entities.Model;
using Plugin.Toasts;
using ODISMember.Pages.Tabs;
using ODISMember.Common;
using ODISMember.Services.Service;
using ODISMember.Shared;

namespace ODISMember
{
    public partial class Vehicles : ContentView, ITabView
    {
        public bool isItemSelected = false;
        public RangeEnabledObservableCollection<VehicleModel> VehicleList
        {
            get;
            set;
        }

        public string Title
        {
            get
            {
                return "My Vehicles";
            }
        }
        BaseContentPage Parent;
        LoggerHelper logger = new LoggerHelper();
        public Vehicles(BaseContentPage parent)
        {
            InitializeComponent();

            logger.TrackPageView(PageNames.VEHICLES);

            this.Parent = parent;
            VehicleList = new RangeEnabledObservableCollection<VehicleModel>();
            listVehicle.ItemsSource = VehicleList;
            listVehicle.ItemTemplate = new DataTemplate(typeof(VehicleCell));
            listVehicle.ItemSelected += ListVehicle_ItemSelected;
            listVehicle.BackgroundColor = ColorResources.VehiclesListBackgroundColor;
            listVehicle.SeparatorVisibility = SeparatorVisibility.None;

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
       async void OpenAddVehicle()
        {
            await Navigation.PushAsync(new AddEditVehicle(),false);
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
        async void ListVehicle_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (!isItemSelected)
            {
                isItemSelected = true;
                if (e.SelectedItem != null)
                {
                    VehicleModel selectedVehicle = e.SelectedItem as VehicleModel;
                    await Parent.Navigation.PushAsync(new VehicleDetails(selectedVehicle));
                }
                isItemSelected = false;

            }
            listVehicle.SelectedItem = null;
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }

        public void InitializeToolbar()
        {
            Menu menu = new Menu();
            //menu.Icon = ImagePathResources.AddIcon;
            menu.Priority = 0;
            menu.Name = "Add";
            menu.ToolbarItemOrder = 0;
            menu.ActionOnClick += OpenAddVehicle;
            CommonMenu.CreateMenu(Parent, menu);
        }
    }
}

