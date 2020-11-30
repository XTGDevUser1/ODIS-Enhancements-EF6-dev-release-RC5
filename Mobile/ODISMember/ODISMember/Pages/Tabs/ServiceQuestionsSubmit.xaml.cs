using Newtonsoft.Json;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TK.CustomMap;
using Xamarin.Forms;
using Xamarin.Forms.Maps;
using ODISMember.Model;
using ODISMember.Shared;
using XLabs.Ioc;
using XLabs.Platform.Device;
using ODISMember.Contract;
using ODISMember.Behaviors;
using ODISMember.Entities.Table;
using ODISMember.Common;
using ODISMember.Library;
using System.Text.RegularExpressions;
using Plugin.Permissions.Abstractions;
using Plugin.Permissions;

namespace ODISMember.Pages.Tabs
{
    public partial class ServiceQuestionsSubmit : BaseContentPage
    {
        MemberHelper memberHelper = new MemberHelper();
        ServiceRequestModel serviceRequestModel;
        LoggerHelper logger = new LoggerHelper();
        MapViewModel mapViewModel;
        string PrimaryContact;
        public ServiceQuestionsSubmit(ServiceRequestModel serviceRequestModel)
        {
            InitializeComponent();
            Title = "Review";
            this.serviceRequestModel = serviceRequestModel;
            //this.BindingContext = serviceRequestModel;
            mapViewModel = new MapViewModel();

            this.BindingContext = mapViewModel;
            PrimaryContact = string.Empty;
            btnCancel.Clicked += BtnCancel_Clicked;
            btnSubmit.Clicked += BtnSubmit_Clicked;
            btnAddNote.Clicked += BtnAddNote_Clicked;
            widgetContact.Behaviors.Add(new CountryPhoneNumberBehavior_LabelDropdownEntryHorizontal() { IsRequired = true, Length = 10 });
            widgetContact.EntryValue.TextChanged += EntryValue_TextChanged;

            widgetContact.EntryValue.FormatCharacters = "( -)";
            widgetContact.EntryValue.Mask = new System.Collections.Generic.List<MaskRules>(
                new[] {
                    new MaskRules {Start=0,End=3,Mask="{0:3}" },
                    new MaskRules {Start=3,End=6,Mask="({0:3}) {3:3}" },
                    new MaskRules {Start=6,End=10,Mask="({0:3}) {3:3}-{6:}" }
                });
            if (string.IsNullOrEmpty(lblNote.Text))
            {
                NoteLayout.IsVisible = false;
            }

            if (serviceRequestModel.ServiceType.ToLower() != "tow")
            {
                stackTowDestination.IsVisible = false;
            }
            if (!string.IsNullOrEmpty(serviceRequestModel.Note))
            {
                lblNote.Text = serviceRequestModel.Note;
                btnAddNote.Text = "Edit Note";
            }
            Content = CreateLoadingIndicatorRelativeLayout(mainLayout);

            //LoadingMapView();
            LoadNormalMap();
            LoadData();

        }

        private void EntryValue_TextChanged(object sender, TextChangedEventArgs e)
        {
            Global.ServiceRequestPhoneNumber = Regex.Replace(widgetContact.EntryValue.Text, "[^0-9]+", string.Empty); ;
        }

        void LoadData()
        {

            labelService.Text = (serviceRequestModel.ServiceType).ToUpper() + " REQUEST ";
            labelYearMakeModel.Text = serviceRequestModel.YearMakeModel;
            labelLocationAddress.Text = serviceRequestModel.LocationAddress + " " + serviceRequestModel.LocationCountryCode;
            labelDestinationAddress.Text = serviceRequestModel.DestinationAddress + " " + serviceRequestModel.DestinationCountryCode;
            if (!string.IsNullOrEmpty(Global.ServiceRequestPhoneNumber))
            {
                PrimaryContact = Global.ServiceRequestPhoneNumber;
            }
            else if (Global.CurrentAssociateMember != null && Global.CurrentAssociateMember.CellPhone != null)
            {
                PrimaryContact = Global.CurrentAssociateMember.CellPhone.FormatedPhoneNumber;
            }
            widgetContact.EntryValue.Text = PrimaryContact;
            widgetContact.ItemSource = LoadCountries();
            // widgetPhoneNumber.EntryValue.Text = PrimaryContact;
            //widgetCountry.ItemSource = LoadCountries();
        }
        public Dictionary<string, string> LoadCountries()
        {
            Dictionary<string, string> countries = new Dictionary<string, string>();
            Dictionary<string, string> countryCodes = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetLocalCountryCodes()).Result;
            if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS)
            {
                if (operationResult.Data != null)
                {
                    List<Countries> countryList = JsonConvert.DeserializeObject<List<Countries>>(operationResult.Data.ToString());
                    if (countryList.Count > 0)
                    {
                        countries = countryList.ToDictionary(pair => pair.ISOCode.Trim() + " (+" + pair.TelephoneCode.Trim().ToString() + ")", pair => pair.TelephoneCode.Trim().ToString());
                        countryCodes = countryList.ToDictionary(pair => pair.ISOCode.Trim(), pair => pair.TelephoneCode.Trim().ToString());

                        //if member cell phone number exists 
                        if (Global.CurrentAssociateMember != null && Global.CurrentAssociateMember.CellPhone != null && !string.IsNullOrEmpty(Global.CurrentAssociateMember.CellPhone.CountryCode.Trim()) && countryCodes.ContainsKey(Global.CurrentAssociateMember.CellPhone.CountryCode.Trim()))
                        {
                            widgetContact.SelectedItem = countryCodes.Where(a => a.Key.Trim() == Global.CurrentAssociateMember.CellPhone.CountryCode.Trim()).First();
                            widgetContact.EntryValueDropdown.Text = widgetContact.Key + " (+" + widgetContact.Value.Trim() + ")";
                        }
                        //if member cell phone not exists but membership address exists
                        else if (Global.CurrentMember != null && Global.CurrentMember.Address != null && !string.IsNullOrEmpty(Global.CurrentMember.Address.CountryCode.Trim()) && countryCodes.ContainsKey(Global.CurrentMember.Address.CountryCode.Trim()))
                        {
                            widgetContact.SelectedItem = countryCodes.Where(a => a.Key.Trim() == Global.CurrentMember.Address.CountryCode.Trim()).First();
                            widgetContact.EntryValueDropdown.Text = widgetContact.Key + " (+" + widgetContact.Value.Trim() + ")";
                        }
                        else if (countryCodes.ContainsKey("US"))
                        {
                            widgetContact.SelectedItem = countryCodes.Where(a => a.Key.Trim() == "US").First();
                            widgetContact.EntryValueDropdown.Text = widgetContact.Key + " (+" + widgetContact.Value.Trim() + ")";
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
        void LoadNormalMap()
        {
            Position position = new Position((double)serviceRequestModel.LocationLatitude, (double)serviceRequestModel.LocationLongitude);

            var map = new Map(MapSpan.FromCenterAndRadius(position, Distance.FromMiles(5)));
            map.Pins.Add(new Pin()
            {
                Label = serviceRequestModel.LocationAddress,
                Position = new Position((double)serviceRequestModel.LocationLatitude, (double)serviceRequestModel.LocationLongitude)
            });
            if (serviceRequestModel.ServiceType.ToLower() == "tow")
            {
                map.Pins.Add(new Pin()
                {
                    Label = serviceRequestModel.DestinationAddress,
                    Position = new Position((double)serviceRequestModel.DestinationLatitude, (double)serviceRequestModel.DestinationLongitude)
                });
            }
            this.maplayout.Children.Add(map);
        }

        private void BtnAddNote_Clicked(object sender, EventArgs e)
        {
            RoadsideServiceRequestNote notePage = new RoadsideServiceRequestNote(serviceRequestModel.Note);
            notePage.UpdateNote += NotePage_UpdateNote;
            Navigation.PushAsync(notePage);
        }

        private void NotePage_UpdateNote(object sender, EventArgs e)
        {
            bool hasNote = false;
            string note = string.Empty;
            if (sender != null)
            {
                note = (string)sender;
                if (!string.IsNullOrEmpty(note))
                {
                    hasNote = true;
                }
            }
            NoteLayout.IsVisible = hasNote;
            if (hasNote)
            {
                lblNote.Text = note;
                serviceRequestModel.Note = note;
                btnAddNote.Text = "Edit Note";
            }
            else
            {
                lblNote.Text = string.Empty;
                serviceRequestModel.Note = string.Empty;
                btnAddNote.Text = "Add Note +";
            }
        }

        private async void BtnSubmit_Clicked(object sender, EventArgs e)
        {
            widgetContact.onValidate();
            if (widgetContact.IsValid && PhoneNumberValidator.ValidatePhoneNumber(widgetContact))
            {

                serviceRequestModel.SourceSystem = Constants.SOURCE_SYSTEM;
                //serviceRequestModel.NextAction = "Dispatch";
                //serviceRequestModel.NextActionAssignedToUser = "DispatchUser";
                serviceRequestModel.CustomerID = Constants.MEMBER_NUMBER;
                serviceRequestModel.ProgramID = Constants.MEMBER_PROGRAM_ID != null ? Convert.ToInt32(Constants.MEMBER_PROGRAM_ID) : (int?)null;
                serviceRequestModel.CustomerGroupID = Constants.MEMBER_MEMBERSHIP_NUMBER;
                serviceRequestModel.ContactFirstName = Constants.MEMBER_FIRST_NAME;
                serviceRequestModel.ContactLastName = Constants.MEMBER_LAST_NAME;
                // Set the member's cell phone number here.                
                if (Global.CurrentAssociateMember != null && Global.CurrentAssociateMember.CellPhone != null)
                {
                    serviceRequestModel.MemberPhoneCountryCode = !string.IsNullOrEmpty(Global.CurrentAssociateMember.CellPhone.CountryCode) ? Global.CurrentAssociateMember.CellPhone.CountryCode.Trim() : null;
                    //Member Cellphone Number
                    serviceRequestModel.MemberPhoneNumber = Global.CurrentAssociateMember.CellPhone.FormatedPhoneNumber;
                }

                // This maps to the Case.ContactPhoneNumber
                string input = Regex.Replace(widgetContact.EntryValue.Text, "[^0-9]+", string.Empty);
                serviceRequestModel.ContactPhoneNumber = widgetContact.Value.Trim() + " " + input;


                MemberHelper memberHelper = new MemberHelper();
                OperationResult operationResult;
                var hud = new HUD("Loading...");
                OperationResult operationResultCurrentMember = await memberHelper.GetMemberStatus(Constants.MEMBER_NUMBER);
                if (operationResultCurrentMember != null && operationResultCurrentMember.Status == OperationStatus.SUCCESS && operationResultCurrentMember.Data != null)
                {
                    Associate currentMember = JsonConvert.DeserializeObject<Associate>(operationResultCurrentMember.Data.ToString());
                    if (currentMember.EffectiveDate != null)
                    {
                        serviceRequestModel.MemberEffectiveDate = currentMember.EffectiveDate.Value.Date;
                    }
                    if (currentMember.ExpirationDate != null)
                    {
                        serviceRequestModel.MemberExpirationDate = currentMember.ExpirationDate.Value.Date;
                    }
                }
                operationResult = await memberHelper.SubmitServiceRequest(serviceRequestModel);
                hud.Dismiss();
                if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
                {
                    ServiceRequestModel responseRequestModel = JsonConvert.DeserializeObject<ServiceRequestModel>(operationResult.Data.ToString());
                    bool isSRCreate = true;
                    if (responseRequestModel.IsServiceCovered)
                    {
                        isSRCreate = true;
                    }
                    else if (!responseRequestModel.IsServiceCovered)
                    {
                        isSRCreate = await DisplayAlert("Service Not Covered", responseRequestModel.ServiceCoverageDescription + "\n" + responseRequestModel.ServiceEstimateMessage, "Confirm", "Cancel");
                        if (isSRCreate)
                        {
                            var hud1 = new HUD("Loading...");
                            OperationResult operationResultSubmit = await memberHelper.ConfirmEstimate(responseRequestModel.ServiceRequestID.ToString());
                            hud1.Dismiss();
                        }
                        else
                        {
                            var hud2 = new HUD("Loading...");
                            OperationResult operationResultSubmit = await memberHelper.CancelEstimate(responseRequestModel.ServiceRequestID.ToString());
                            hud2.Dismiss();
                        }
                    }

                    if (isSRCreate)
                    {
                        if (Device.OS == TargetPlatform.iOS)
                        {
                            bool isNotificationEnabled = DependencyService.Get<Interfaces.INativePermissions>().CheckNotificationPermission();
                            if (!isNotificationEnabled)
                            {
                                bool result = await DisplayAlert("", "Turn on notification permissions in the Settings to allow Roadside to send you push notifications", "Go To Settings", "Cancel");
                                if (result)
                                {
                                    DependencyService.Get<Interfaces.IOpenSettings>().Opensettings();
                                }
                            }
                        }
                        EventDispatcher.RaiseEvent(responseRequestModel.ServiceRequestID.Value.ToString(), new RefreshEventArgs(AppConstants.Event.OPEN_STATUS));//.TrackerID
                        Global.RemovePages(this);
                        await Navigation.PopAsync();
                    }
                    else
                    {
                        // EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.ADD_SOURCE_MAP));
                    }
                }
                else
                {
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
        }

        private async void BtnCancel_Clicked(object sender, EventArgs e)
        {
            bool isSuccess = await DisplayAlert("Confirmation", "Are you sure you want to cancel this request?", "Yes", "No");
            if (isSuccess)
            {
                EventDispatcher.RaiseEvent(null, new RefreshEventArgs(AppConstants.Event.OPEN_HOME));
                Global.RemovePages(this);
            }
        }
        private void LoadingMapView()
        {
            try
            {
                TKCustomMap mapView = new TKCustomMap();

                mapView.SetBinding(TKCustomMap.CustomPinsProperty, "Pins");
                mapView.SetBinding(TKCustomMap.MapCenterProperty, "MapCenter");
                mapView.SetBinding(TKCustomMap.PinSelectedCommandProperty, "PinSelectedCommand");
                mapView.SetBinding(TKCustomMap.SelectedPinProperty, "SelectedPin");
                mapView.SetBinding(TKCustomMap.PolylinesProperty, "Lines");
                mapView.SetBinding(TKCustomMap.PolygonsProperty, "Polygons");
                mapView.SetBinding(TKCustomMap.MapRegionProperty, "MapRegion");
                mapView.SetBinding(TKCustomMap.RouteClickedCommandProperty, "RouteClickedCommand");
                mapView.SetBinding(TKCustomMap.RouteCalculationFinishedCommandProperty, "RouteCalculationFinishedCommand");
                mapView.SetBinding(TKCustomMap.TilesUrlOptionsProperty, "TilesUrlOptions");

                var pin = new TKCustomMapPin
                {
                    Position = new Position((double)serviceRequestModel.LocationLatitude, (double)serviceRequestModel.LocationLongitude),
                    Title = serviceRequestModel.LocationAddress,
                    ShowCallout = true,
                    IsDraggable = true,
                    DefaultPinColor = Color.Red
                };
                mapViewModel.Pins.Add(pin);

                if (serviceRequestModel.ServiceType.ToLower() == "tow")
                {
                    var pin1 = new TKCustomMapPin
                    {
                        Position = new Position((double)serviceRequestModel.DestinationLatitude, (double)serviceRequestModel.DestinationLongitude),
                        Title = serviceRequestModel.DestinationAddress,
                        ShowCallout = true,
                        IsDraggable = true,
                        DefaultPinColor = Color.Green
                    };
                    mapViewModel.Pins.Add(pin1);
                }

                this.maplayout.Children.Add(mapView);

                var position = new Xamarin.Forms.Maps.Position((double)serviceRequestModel.LocationLatitude, (double)serviceRequestModel.LocationLongitude);//Default to Source Position
                var mapspan = MapSpan.FromCenterAndRadius(position, Distance.FromMiles(3));
                mapView.MoveToRegion(mapspan);
                mapView.MapCenter = position;
            }
            catch (Exception ex)
            {
                logger.Error(ex);

            }
        }

    }
}
