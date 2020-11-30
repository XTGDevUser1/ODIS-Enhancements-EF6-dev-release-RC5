using ODISMember.Classes;
using ODISMember.Common;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Interfaces;
using ODISMember.Model;
using ODISMember.Shared;
using Plugin.Permissions;
using Plugin.Permissions.Abstractions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using TK.CustomMap;
using Xamarin.Forms;
using Xamarin.Forms.Maps;

namespace ODISMember.Pages.Tabs
{
    public partial class Roadside : ContentView, ITabView
    {
        private PlacesAutoComplete autoComplete = null;
        private XLabs.Platform.Services.Geolocation.IGeolocator geolocator = null;
        private LoggerHelper logger = new LoggerHelper();
        // private TKCustomMap mapView;
        private MapViewModel mapViewModel;
        private MemberHelper memberHelper = new MemberHelper();
        private BaseContentPage Parent;
        // private CustomImageButton UserLocation;
        //
        PermissionStatus previousPermissions;

        public Roadside(BaseContentPage parent)
        {
            InitializeComponent();
            logger.TrackPageView(PageNames.GET_HELP);
            this.Parent = parent;
            //Reset service request phone number
            Global.ServiceRequestPhoneNumber = string.Empty;
            EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            Setup();
            CreateView();
        }

        public string Title
        {
            get { return "Set Location"; }
        }

        public void InitializeToolbar()
        {
            Menu menu = new Menu();
            //menu.Icon = ImagePathResources.SaveIcon;
            menu.Priority = 0;
            menu.Name = "Next";
            menu.ToolbarItemOrder = 0;
            menu.ActionOnClick += SendLocation;
            CommonMenu.CreateMenu(Parent, menu);
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }

        private void AddressReverseGeoCode(ServiceRequestModel serviceRequestModel, TKCustomMapPin selectedPin)
        {
            TK.CustomMap.Api.Bing.BingLocations bingLocations = TK.CustomMap.Api.Bing.BingLocations.Instance;
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

                        serviceRequestModel.LocationLatitude = resource.Point != null && resource.Point.Coordinates != null && resource.Point.Coordinates.Count > 0 ? (decimal)resource.Point.Coordinates[0] : 0;
                        serviceRequestModel.LocationLongitude = resource.Point != null && resource.Point.Coordinates != null && resource.Point.Coordinates.Count > 0 ? (decimal)resource.Point.Coordinates[1] : 0;
                        serviceRequestModel.LocationCity = resource.Address.Locality;
                        serviceRequestModel.LocationStateProvince = resource.Address.AdminDistrict;
                        serviceRequestModel.LocationPostalCode = resource.Address.PostalCode;
                        serviceRequestModel.LocationAddress = resource.Address.FormattedAddress;
                        serviceRequestModel.LocationCountryCode = resource.Address.CountryRegionIso2;

                        isModelUpdated = true;
                        //navigating the page
                        NavigateRoadsideVehiclePage(serviceRequestModel);
                    }
                }

                if (!isModelUpdated)
                {
                    UpdateServiceRequestModelBySelectedPin(serviceRequestModel, selectedPin);
                }
            });
        }

        private void CreateView(ServiceRequestModel serviceRequestModel = null)
        {
            try
            {
                mapViewModel = null;
                this.BindingContext = null;
                //mapView = null;
                mapViewModel = new MapViewModel();
                this.BindingContext = mapViewModel;

                autoComplete = null;

                autoComplete = new PlacesAutoComplete(true, 0) { ApiToUse = PlacesAutoComplete.PlacesApi.BingBusiness };
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
                autoComplete.IsUserCurrentLocationButtonVisible = true;

                mapLayout.Children.Add(autoComplete);

                autoComplete.CurrentLocationClicked += UserLocation_ImageClick;
                if (serviceRequestModel != null)
                {
                    pinUserSelectedLocation(serviceRequestModel);
                }
                else
                {
                    PinLocationBasedOnLocationPermission();
                }
            }
            catch (Exception ex)
            {
                logger.Trace("Roadside CreateView Exception: " + ex.ToString());
                logger.Error(ex);
            }
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.ADD_SOURCE_MAP)
            {
                if (sender != null)
                {
                    ServiceRequestModel serviceRequestModelRefresh = (ServiceRequestModel)sender;
                    var position = new Xamarin.Forms.Maps.Position((double)serviceRequestModelRefresh.LocationLatitude, (double)serviceRequestModelRefresh.LocationLongitude);
                    CreateView(serviceRequestModelRefresh);
                }
                else
                {
                    CreateView();
                }
            }
            else if (e.EventId == AppConstants.Event.REMOVE_SOURCE_MAP)
            {

                mapLayout.Children.Remove(autoComplete);
            }
            else if (e.EventId == AppConstants.Event.ADD_CURRENT_LOCATION_POINT)
            {
                if (Parent.CurrentActiveTab == AppConstants.Event.OPEN_GET_HELP)
                {
                    CheckUserLocation();
                }
            }
        }
        private async void CheckUserLocation()
        {
            PermissionStatus status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Location);
            if (previousPermissions != status || mapViewModel.SelectedPin == null)
            {
                if (status == PermissionStatus.Granted)
                {
                    pinUserCurrentLocation(false);
                }
                else
                {
                    pinUserDefaultLocation();
                }
            }
            previousPermissions = status;
        }
        private void NavigateRoadsideVehiclePage(ServiceRequestModel serviceRequestModel)
        {
            Device.BeginInvokeOnMainThread(() =>
            {
                this.Navigation.PushAsync(new RoadsideVehicle(serviceRequestModel));
                mapLayout.Children.Remove(autoComplete);
            });
        }

        // Pin current location
        private async void pinUserCurrentLocation(bool isSettingPopup = true)
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
                        AddressBing address = null;
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
                        mapViewModel.MapCenter = new Xamarin.Forms.Maps.Position(position.Latitude, position.Longitude);
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
                        plotPinOnMap(pin);
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
                if (Parent != null && isSettingPopup)
                {
                    bool result = await Parent.DisplayAlert("", "Turn on location permissions in the Settings to allow Roadside to use your location", "Go To Settings", "Cancel");
                    if (result)
                    {
                        DependencyService.Get<IOpenSettings>().Opensettings();
                    }
                }
            }
        }

        // Pin user default location
        private async void pinUserDefaultLocation()
        {
            if (Global.CurrentMember != null && Global.CurrentMember.Addresses != null && Global.CurrentMember.Addresses.Count > 0)
            {
                var hud = new HUD("Loading Address...");
                Device.BeginInvokeOnMainThread(async () =>
                {
                    //Thread will wait to Map get ready for plotting a pin
                    await System.Threading.Tasks.Task.Delay(2000);

                    var addressObj = Global.CurrentMember.Addresses[0];
                    string title = addressObj.FullAddress;
                    BingAddressRoot bingAddressRoot = null;
                    try
                    {
                        bingAddressRoot = await memberHelper.GetBingPoints(addressObj.FullAddress);
                    }
                    catch (Exception rootEx)
                    {
                        bingAddressRoot = null;
                    }
                    AddressBing address = null;
                    List<double> coordinates = null;
                    if (bingAddressRoot != null)
                    {
                        if (bingAddressRoot.ResourceSets != null && bingAddressRoot.ResourceSets.Count > 0)
                        {
                            if (bingAddressRoot.ResourceSets[0].Resources != null && bingAddressRoot.ResourceSets[0].Resources.Count > 0)
                            {
                                if (bingAddressRoot.ResourceSets[0].Resources[0].Point != null)
                                {
                                    coordinates = bingAddressRoot.ResourceSets[0].Resources[0].Point.Coordinates;
                                    address = bingAddressRoot.ResourceSets[0].Resources[0].Address;
                                }
                            }
                        }
                    }
                    if (coordinates != null)
                    {
                        var latitude = coordinates[0];
                        var longitude = coordinates[1];
                        mapViewModel.MapCenter = new Xamarin.Forms.Maps.Position(latitude, longitude);
                        var pin = new TKCustomMapPin
                        {
                            Position = new Xamarin.Forms.Maps.Position(latitude, longitude),
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
                            if (address.AddressLine == null)
                            {
                                pin.LocationAddress = title;
                            }
                            else
                            {
                                pin.LocationAddress = address.AddressLine;
                            }
                            pin.LocationCountryCode = address.CountryRegionIso2;
                            pin.LocationDescription = address.FormattedAddress;
                        }
                        plotPinOnMap(pin);
                        hud.Dismiss();
                    }
                    else
                    {
                        hud.Dismiss();
                        ToastHelper.ShowErrorToast("Error", "Not able to find your address");
                    }
                });
            }

        }

        // Pin user selected location
        private void pinUserSelectedLocation(ServiceRequestModel serviceRequestModel)
        {
            Xamarin.Forms.Maps.Position position = new Xamarin.Forms.Maps.Position((double)serviceRequestModel.LocationLatitude.Value, (double)serviceRequestModel.LocationLongitude.Value);
            var pin = new TKCustomMapPin
            {
                Position = position,
                Title = serviceRequestModel.SourceLocationDescription, //serviceRequestModel.LocationAddress,
                ShowCallout = true,
                IsDraggable = true,
                DefaultPinColor = Color.Red,
                LocationCity = serviceRequestModel.LocationCity,
                LocationStateProvince = serviceRequestModel.LocationStateProvince,
                LocationPostalCode = serviceRequestModel.LocationPostalCode,
                LocationAddress = serviceRequestModel.LocationAddress,
                LocationCountryCode = serviceRequestModel.LocationCountryCode,
                LocationDescription = serviceRequestModel.ServiceLocationDescription
            };

            plotPinOnMap(pin);
        }

        void plotPinOnMap(TKCustomMapPin pin = null)
        {
            if (pin != null)
            {
                Device.BeginInvokeOnMainThread(() =>
                {
                    var mapspan = MapSpan.FromCenterAndRadius(pin.Position, Distance.FromMiles(2));
                    mapViewModel.Pins.Clear();
                    mapViewModel.Pins.Add(pin);
                    mapViewModel.SelectedPin = pin;
                    mapViewModel.MapRegion = mapspan;
                    autoComplete.MapView.MoveToRegion(mapspan);

                    autoComplete.Latitude = (decimal)pin.Position.Latitude;
                    autoComplete.Longitude = (decimal)pin.Position.Longitude;

                });
            }
            else
            {
                var positionDefault = new Xamarin.Forms.Maps.Position(Constants.DEFAULT_LATITUDE, Constants.DEFAULT_LONGITUDE);
                var mapspanDefault = MapSpan.FromCenterAndRadius(positionDefault, Distance.FromMiles(500));
                autoComplete.MapView.MoveToRegion(mapspanDefault);
                autoComplete.Latitude = (decimal)Constants.DEFAULT_LATITUDE;
                autoComplete.Longitude = (decimal)Constants.DEFAULT_LONGITUDE;
            }
        }
        private async void SendLocation()
        {
            if (mapViewModel != null && mapViewModel.SelectedPin != null)
            {
                ServiceRequestModel serviceRequestModel = new ServiceRequestModel();
                //TFS: #1371
                serviceRequestModel.IsSMSAvailable = true;
                serviceRequestModel.ContactEmail = Global.CurrentAssociateMember != null ? Global.CurrentAssociateMember.Email : null;
                serviceRequestModel.SourceLocationDescription = autoComplete.MapView.SelectedPin.Title;
                if (ValidateSelectedPin(mapViewModel.SelectedPin))
                {
                    UpdateServiceRequestModelBySelectedPin(serviceRequestModel, mapViewModel.SelectedPin);
                }
                else
                {
                    //If Selected Pin not have enough information we reverse geocode using Bing location service.
                    AddressReverseGeoCode(serviceRequestModel, mapViewModel.SelectedPin);
                }
            }
            else
            {
                ToastHelper.ShowWarningToast("Warning", "Please long press on map to select your location");
            }
        }

        private void Setup()
        {
            geolocator = null;
            geolocator = DependencyService.Get<XLabs.Platform.Services.Geolocation.IGeolocator>();
            geolocator.DesiredAccuracy = 1;
        }

        private async void PinLocationBasedOnLocationPermission()
        {
            PermissionStatus status = await CrossPermissions.Current.CheckPermissionStatusAsync(Permission.Location);
            previousPermissions = status;
            if (status == PermissionStatus.Granted)
            {
                pinUserCurrentLocation();
            }
            else
            {
                if (Parent != null)
                {
                    bool result = await Parent.DisplayAlert("", "Turn on location permissions in the Settings to allow Roadside to use your location", "Go To Settings", "Cancel");
                    if (result)
                    {
                        DependencyService.Get<IOpenSettings>().Opensettings();
                        Global.IsGotoSetting = true;
                    }
                    else
                    {
                        pinUserDefaultLocation();
                    }
                }

            }
        }

        private void UpdateServiceRequestModelBySelectedPin(ServiceRequestModel serviceRequestModel, TKCustomMapPin selectedPin)
        {
            serviceRequestModel.LocationLatitude = (decimal)mapViewModel.SelectedPin.Position.Latitude;
            serviceRequestModel.LocationLongitude = (decimal)mapViewModel.SelectedPin.Position.Longitude;
            serviceRequestModel.LocationCity = mapViewModel.SelectedPin.LocationCity;
            serviceRequestModel.LocationStateProvince = mapViewModel.SelectedPin.LocationStateProvince;
            serviceRequestModel.LocationPostalCode = mapViewModel.SelectedPin.LocationPostalCode;
            serviceRequestModel.LocationAddress = mapViewModel.SelectedPin.LocationDescription;
            serviceRequestModel.LocationCountryCode = mapViewModel.SelectedPin.LocationCountryCode;
            //navigating the page
            NavigateRoadsideVehiclePage(serviceRequestModel);
        }

        private void UserLocation_ImageClick(object sender, EventArgs e)
        {
            pinUserCurrentLocation();
            // pinTestUserCurrentLocation();
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
    }
}