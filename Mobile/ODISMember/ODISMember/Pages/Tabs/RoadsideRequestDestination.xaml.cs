using Newtonsoft.Json;
using ODISMember.Classes;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Interfaces;
using ODISMember.Model;
using ODISMember.Services.Service;
using ODISMember.Shared;
using Plugin.Permissions;
using Plugin.Permissions.Abstractions;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using TK.CustomMap;
using TK.CustomMap.Api.Bing;
using Xamarin.Forms;
using Xamarin.Forms.Maps;

namespace ODISMember.Pages.Tabs
{
    public partial class RoadsideRequestDestination : ContentPage
    {
        LoggerHelper logger = new LoggerHelper();
        ServiceRequestModel serviceRequestModel;
        MapViewModel destinationMapModel;
        XLabs.Platform.Services.Geolocation.IGeolocator geolocator = null;
        private PlacesAutoComplete autoComplete = null;
        //TKCustomMap mapView;

        MemberHelper memberHelper = new MemberHelper();
        public RoadsideRequestDestination(ServiceRequestModel serviceRequestModel)
        {
            InitializeComponent();

            Title = "Set Destination";
            this.serviceRequestModel = serviceRequestModel;

            destinationMapModel = new MapViewModel();

            this.BindingContext = destinationMapModel;
            CreateView();
            Global.AddPage(this);
            //Setup();
            Menu menu = new Menu();
            menu.Priority = 0;
            menu.Name = "Next";
            menu.ToolbarItemOrder = 0;
            menu.ActionOnClick += SendLocation;
            CommonMenu.CreateMenu(this, menu);
        }
        void Setup()
        {
            //if (geolocator != null)
            //    return;
            geolocator = null;
            geolocator = DependencyService.Get<XLabs.Platform.Services.Geolocation.IGeolocator>();
            geolocator.DesiredAccuracy = 1;

        }
        private void CreateView()
        {

            try
            {
                autoComplete = new PlacesAutoComplete(true, 0) { ApiToUse = PlacesAutoComplete.PlacesApi.BingBusiness };
                autoComplete.Latitude = serviceRequestModel.LocationLatitude;
                autoComplete.Longitude = serviceRequestModel.LocationLongitude;
                autoComplete.SetBinding(PlacesAutoComplete.PlaceSelectedCommandProperty, "PlaceSelectedCommand");
                autoComplete.BackgroundColor = Color.Transparent;

                autoComplete.MapView.SetBinding(TKCustomMap.CustomPinsProperty, "Pins");
                autoComplete.MapView.SetBinding(TKCustomMap.MapClickedCommandProperty, "MapClickedCommand");
                autoComplete.MapView.SetBinding(TKCustomMap.MapLongPressCommandProperty, "MapLongPressCommand");
                autoComplete.MapView.SetBinding(TKCustomMap.MapCenterProperty, "MapCenter");
                autoComplete.MapView.SetBinding(TKCustomMap.PinSelectedCommandProperty, "PinSelectedCommand");
                autoComplete.MapView.SetBinding(TKCustomMap.SelectedPinProperty, "SelectedPin");
                autoComplete.MapView.SetBinding(TKCustomMap.RoutesProperty, "Routes");
                autoComplete.MapView.SetBinding(TKCustomMap.PinDragEndCommandProperty, "DragEndCommand");
                autoComplete.MapView.SetBinding(TKCustomMap.CirclesProperty, "Circles");
                autoComplete.MapView.SetBinding(TKCustomMap.CalloutClickedCommandProperty, "CalloutClickedCommand");
                autoComplete.MapView.SetBinding(TKCustomMap.PolylinesProperty, "Lines");
                autoComplete.MapView.SetBinding(TKCustomMap.PolygonsProperty, "Polygons");
                autoComplete.MapView.SetBinding(TKCustomMap.MapRegionProperty, "MapRegion");
                autoComplete.MapView.SetBinding(TKCustomMap.RouteClickedCommandProperty, "RouteClickedCommand");
                autoComplete.MapView.SetBinding(TKCustomMap.RouteCalculationFinishedCommandProperty, "RouteCalculationFinishedCommand");
                autoComplete.MapView.SetBinding(TKCustomMap.TilesUrlOptionsProperty, "TilesUrlOptions");

                autoComplete.SetBinding(PlacesAutoComplete.BoundsProperty, "MapRegion");
                autoComplete.SetBinding(PlacesAutoComplete.SearchPositionProperty, "SelectedPin");
               // autoComplete.IsUserCurrentLocationButtonVisible = true;
               // autoComplete.CurrentLocationClicked += UserLocation_ImageClick;
                mapLayout.Children.Add(autoComplete);

                var position = new Xamarin.Forms.Maps.Position((double)serviceRequestModel.LocationLatitude, (double)serviceRequestModel.LocationLongitude);//Default to Source Position
                var mapspan = MapSpan.FromCenterAndRadius(position, Distance.FromMiles(4));
                autoComplete.MapView.MoveToRegion(mapspan);
                autoComplete.MapView.MapCenter = position;

            }
            catch (Exception ex)
            {
                logger.Error(ex);

            }
        }
        private void UserLocation_ImageClick(object sender, EventArgs e)
        {
            //GetLocation();
            pinUserCurrentLocation();
        }
        //private async void GetLocation()
        //{
        //    PermissionStatus status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Location);
        //    SettingsTable settings = memberHelper.GetSettings();
        //    if (settings.IsLocationPermissionAsked && status != PermissionStatus.Granted)
        //    {

        //        if (Parent != null)
        //        {
        //            bool result = await DisplayAlert("", "Turn on location permissions in the Settings to allow Roadside to use your location", "Go To Settings", "Cancel");
        //            if (result)
        //            {
        //                DependencyService.Get<IOpenSettings>().Opensettings();
        //            }
        //            return;
        //        }
        //    }
        //    Setup();
        //    if (!geolocator.IsGeolocationAvailable)
        //    {
        //        await DisplayAlert("Location Not Found", "We cannot retrieve your GPS location.  Please enter the address of the vehicle in the search box.", "OK");
        //        return;
        //    }

        //    var hud = new HUD("Finding Location...");
        //    try
        //    {
        //        var cancelSource = new CancellationTokenSource();
        //        XLabs.Platform.Services.Geolocation.Position position = null;
        //        try
        //        {
        //            position = await geolocator.GetPositionAsync(10000, cancelSource.Token, false);
        //            try
        //            {
        //                logger.Trace("RoadsideRequestDestination ShowLocationAlert Finding Location... position: " + JsonConvert.SerializeObject(position));
        //            }
        //            catch (Exception ex)
        //            {
        //                logger.Trace("RoadsideRequestDestination ShowLocationAlert Finding Location... Serializing exception ex: " + ex.InnerException != null ? ex.InnerException.Message : ex.Message);
        //            }

        //        }
        //        catch (Exception exce)
        //        {
        //            position = null;
        //            logger.Trace("RoadsideRequestDestination ShowLocationAlert position is null");
        //        }

        //        if (position != null)
        //        {
        //            Device.BeginInvokeOnMainThread(async () =>
        //            {
        //                string title = "Your location";
        //                Entities.Model.AddressBing address = null;
        //                BingAddressRoot bingAddressRoot = await memberHelper.GetBingAddress(position.Latitude.ToString(), position.Longitude.ToString());
        //                try
        //                {
        //                    logger.Trace("RoadsideRequestDestination ShowLocationAlert Finding Location... bingAddressRoot: " + JsonConvert.SerializeObject(bingAddressRoot));
        //                }
        //                catch (Exception)
        //                {
        //                    logger.Trace("RoadsideRequestDestination ShowLocationAlert Finding Location... bingAddressRoot SerializeObject error");
        //                }

        //                if (bingAddressRoot != null)
        //                {
        //                    if (bingAddressRoot.ResourceSets != null && bingAddressRoot.ResourceSets.Count > 0)
        //                    {
        //                        if (bingAddressRoot.ResourceSets[0].Resources != null && bingAddressRoot.ResourceSets[0].Resources.Count > 0)
        //                        {
        //                            if (bingAddressRoot.ResourceSets[0].Resources[0].Address != null)
        //                            {
        //                                address = bingAddressRoot.ResourceSets[0].Resources[0].Address;
        //                                title = address.FormattedAddress;
        //                                logger.Trace("RoadsideRequestDestination ShowLocationAlert Finding Location... title: " + title);
        //                            }
        //                        }
        //                    }
        //                }

        //                destinationMapModel.MapCenter = new Xamarin.Forms.Maps.Position(position.Latitude, position.Longitude);
        //                var pin = new TKCustomMapPin
        //                {
        //                    Position = new Xamarin.Forms.Maps.Position(position.Latitude, position.Longitude),
        //                    Title = title,
        //                    ShowCallout = true,
        //                    IsDraggable = true,
        //                    DefaultPinColor = Color.Red
        //                };
        //                if (address != null)
        //                {
        //                    pin.LocationCity = address.Locality;
        //                    pin.LocationStateProvince = address.AdminDistrict;
        //                    pin.LocationPostalCode = address.PostalCode;
        //                    pin.LocationAddress = address.AddressLine;
        //                    pin.LocationCountryCode = address.CountryRegionIso2;
        //                    pin.LocationDescription = address.FormattedAddress;
        //                    try
        //                    {
        //                        logger.Trace("RoadsideRequestDestination ShowLocationAlert Finding Location... address: " + JsonConvert.SerializeObject(address));
        //                    }
        //                    catch (Exception)
        //                    {
        //                        logger.Trace("RoadsideRequestDestination ShowLocationAlert Finding Location... address SerializeObject error");
        //                    }

        //                }
        //                Device.BeginInvokeOnMainThread(() =>
        //                {
        //                    var mapspan = MapSpan.FromCenterAndRadius(pin.Position, Distance.FromMiles(2));
        //                    destinationMapModel.Pins.Clear();
        //                    destinationMapModel.Pins.Add(pin);
        //                    destinationMapModel.SelectedPin = pin;
        //                    autoComplete.MapView.MoveToRegion(mapspan);
        //                });
        //            });
        //            hud.Dismiss();
        //        }
        //        else
        //        {
        //            hud.Dismiss();
        //            ToastHelper.ShowErrorToast("Error", "Not able to find your location");
        //        }

        //    }
        //    catch (Exception ex)
        //    {
        //        if (hud != null)
        //            hud.Dismiss();
        //        ToastHelper.ShowErrorToast("Error", "Not able to find your location");
        //        logger.Error(ex);
        //    }
        //}
        // Pin current location

        private async void pinUserCurrentLocation()
        {
            PermissionStatus status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Location);
            if (status == PermissionStatus.Granted)
            {

                var hud = new HUD("Finding Location...");
                var locator = Plugin.Geolocator.CrossGeolocator.Current;
                locator.DesiredAccuracy = 50;
                if (!locator.IsGeolocationAvailable)
                {
                    hud.Dismiss();
                    ToastHelper.ShowErrorToast("Location Not Found", "We cannot retrieve your GPS location.  Please enter the address of the vehicle in the search box.");
                    return;
                }
                if (!locator.IsGeolocationEnabled)
                {
                    hud.Dismiss();
                    ToastHelper.ShowErrorToast("Error", "Please turn on your GPS to find your location");
                    return;
                }

                // XLabs.Platform.Services.Geolocation.Position position = null;
                Plugin.Geolocator.Abstractions.Position position = null;
                try
                {
                    position = await locator.GetPositionAsync(30000, null, false);
                    //position = await geolocator.GetPositionAsync(10000, cancelSource.Token, false);
                }
                catch (Exception ex)
                {
                    position = null;
                }
                if (position != null)
                {
                    Device.BeginInvokeOnMainThread(async () =>
                    {
                        string title = "Your location";
                        Entities.Model.AddressBing address = null;
                        BingAddressRoot bingAddressRoot = await memberHelper.GetBingAddress(position.Latitude.ToString(), position.Longitude.ToString());
                        if (bingAddressRoot != null)
                        {
                            if (bingAddressRoot.ResourceSets != null && bingAddressRoot.ResourceSets.Count > 0)
                            {
                                if (bingAddressRoot.ResourceSets[0].Resources != null && bingAddressRoot.ResourceSets[0].Resources.Count > 0)
                                {
                                    if (bingAddressRoot.ResourceSets[0].Resources[0].Address != null)
                                    {
                                        address = bingAddressRoot.ResourceSets[0].Resources[0].Address;
                                        title = address.FormattedAddress;
                                    }
                                }
                            }
                        }
                        //mapViewModel.MapCenter = new Xamarin.Forms.Maps.Position(position.Latitude, position.Longitude);
                        var pin = new TKCustomMapPin
                        {
                            Position = new Xamarin.Forms.Maps.Position(position.Latitude, position.Longitude),
                            Title = title,
                            ShowCallout = true,
                            IsDraggable = true,
                            DefaultPinColor = Color.Red
                        };
                        if (address != null)
                        {
                            pin.LocationCity = address.Locality;
                            pin.LocationStateProvince = address.AdminDistrict;
                            pin.LocationPostalCode = address.PostalCode;
                            pin.LocationAddress = address.AddressLine;
                            pin.LocationCountryCode = address.CountryRegionIso2;
                            pin.LocationDescription = address.FormattedAddress;
                        }
                        var mapspan = MapSpan.FromCenterAndRadius(pin.Position, Distance.FromMiles(2));
                        destinationMapModel.Pins.Clear();
                        destinationMapModel.Pins.Add(pin);
                        destinationMapModel.SelectedPin = pin;
                        autoComplete.MapView.MoveToRegion(mapspan);
                    });
                    hud.Dismiss();
                }
                else
                {
                    hud.Dismiss();
                    ToastHelper.ShowErrorToast("Error", "Not able to find your location");
                }
            }
            else
            {
                if (Parent != null)
                {
                    bool result = await DisplayAlert("", "Turn on location permissions in the Settings to allow Roadside to use your location", "Go To Settings", "Cancel");
                    if (result)
                    {
                        DependencyService.Get<IOpenSettings>().Opensettings();
                    }
                }
            }
        }
        private async void SendLocation()
        {
            MapViewModel mapViewModel = (MapViewModel)this.BindingContext;
            if (mapViewModel != null && mapViewModel.SelectedPin != null)
            {
                if (ValidateSelectedPin(mapViewModel.SelectedPin))
                {
                    //updating service request model with selected pin data
                    UpdateServiceRequestModelBySelectedPin(mapViewModel.SelectedPin);

                    NavigateToServiceQuestionSubmitPage();
                }
                else
                {
                    //If Selected Pin not have enough information we reverse geocode using Bing location service.
                    AddressReverseGeoCode(mapViewModel.SelectedPin);
                }
            }
            else
            {
                ToastHelper.ShowWarningToast("Warning", "Please long press on map to select your location");
            }
        }

        private bool ValidateSelectedPin(TKCustomMapPin selectedPin)
        {
            if (selectedPin.Position != null && !string.IsNullOrEmpty(selectedPin.LocationCity) && !string.IsNullOrEmpty(selectedPin.LocationStateProvince)
                && !string.IsNullOrEmpty(selectedPin.LocationPostalCode) && !string.IsNullOrEmpty(selectedPin.LocationDescription)
                && !string.IsNullOrEmpty(selectedPin.LocationCountryCode))
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        private void AddressReverseGeoCode(TKCustomMapPin selectedPin)
        {
            BingLocations bingLocations = BingLocations.Instance;
            bingLocations.ReverseGeoCode(selectedPin.LocationCountryCode, selectedPin.LocationStateProvince, selectedPin.LocationCity, !string.IsNullOrEmpty(selectedPin.LocationAddress) ? selectedPin.LocationAddress.Split(',')[0] : "", selectedPin.Position.Latitude, selectedPin.Position.Longitude).ContinueWith((response) =>
            {
                bool isModelUpdated = false;
                if (response.IsCompleted)
                {
                    var resources = response.Result;
                    if (resources != null && resources.Count() > 0)
                    {
                        //taking Region from the selected pin address. If region not present address will return
                        var vicityRegion = !string.IsNullOrEmpty(selectedPin.LocationAddress) ? (selectedPin.LocationAddress.Split(',').Count() > 1 ? selectedPin.LocationAddress.Split(',')[1] : selectedPin.LocationAddress.Split(',')[0]) : "";
                        TK.CustomMap.Api.Bing.ResourceBing resource = new TK.CustomMap.Api.Bing.ResourceBing();
                        //checking region available in the returned result. And selected top result from the available
                        resource = resources.Where(a => a.Address.FormattedAddress.Contains(vicityRegion)).FirstOrDefault();
                        if (resource == null)
                        {
                            //region not available in the resources we setting the first value from the list.
                            resource = resources.First();
                        }

                        serviceRequestModel.DestinationLatitude = resource.Point != null && resource.Point.Coordinates != null && resource.Point.Coordinates.Count > 0 ? (decimal)resource.Point.Coordinates[0] : 0;
                        serviceRequestModel.DestinationLongitude = resource.Point != null && resource.Point.Coordinates != null && resource.Point.Coordinates.Count > 0 ? (decimal)resource.Point.Coordinates[1] : 0;
                        serviceRequestModel.DestinationCity = resource.Address.Locality;
                        serviceRequestModel.DestinationStateProvince = resource.Address.AdminDistrict;
                        serviceRequestModel.DestinationPostalCode = resource.Address.PostalCode;
                        serviceRequestModel.DestinationAddress = resource.Address.FormattedAddress;
                        serviceRequestModel.DestinationCountryCode = resource.Address.CountryRegionIso2;

                        isModelUpdated = true;
                        Device.BeginInvokeOnMainThread(() =>
                        {
                            NavigateToServiceQuestionSubmitPage();
                        });
                    }
                }

                if (!isModelUpdated)
                {
                    UpdateServiceRequestModelBySelectedPin(selectedPin);
                }
            });
        }

        private void UpdateServiceRequestModelBySelectedPin(TKCustomMapPin selectedPin)
        {
            serviceRequestModel.DestinationLatitude = (decimal)selectedPin.Position.Latitude;
            serviceRequestModel.DestinationLongitude = (decimal)selectedPin.Position.Longitude;
            serviceRequestModel.DestinationCity = selectedPin.LocationCity;
            serviceRequestModel.DestinationStateProvince = selectedPin.LocationStateProvince;
            serviceRequestModel.DestinationPostalCode = selectedPin.LocationPostalCode;
            serviceRequestModel.DestinationAddress = selectedPin.LocationDescription;
            serviceRequestModel.DestinationCountryCode = selectedPin.LocationCountryCode;
        }

        private void NavigateToServiceQuestionSubmitPage()
        {
            Navigation.PushAsync(new ServiceQuestionsSubmit(serviceRequestModel));
        }

        protected override bool OnBackButtonPressed()
        {
            Global.RemovePage(this);

            Debug.WriteLine("Back button pressed");
            return base.OnBackButtonPressed();
        }



    }
}
