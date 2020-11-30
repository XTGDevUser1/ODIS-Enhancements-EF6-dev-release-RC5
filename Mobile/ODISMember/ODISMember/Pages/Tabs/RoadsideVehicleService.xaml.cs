using Newtonsoft.Json;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class RoadsideVehicleService : ContentPage
    {
        public bool isItemSelected = false;

        ServiceRequestModel serviceRequestModel;

        public List<RoadsideServiceQuestions> roadsideServiceQuestionsList;
        public RangeEnabledObservableCollection<VehicleServices> VehicleServiceList
        {
            get;
            set;
        }
        public VehicleModel mVehicle;
        public VehicleServices mVehicleService;
        public RoadsideVehicleService(VehicleModel vehicle, ServiceRequestModel serviceRequestModel)
        {
            InitializeComponent();
            this.serviceRequestModel = serviceRequestModel;
            Title = "Service";
            mVehicle = vehicle;
            roadsideServiceQuestionsList = new List<RoadsideServiceQuestions>();
            VehicleServiceList = new RangeEnabledObservableCollection<VehicleServices>();
            listVehicleServices.ItemsSource = VehicleServiceList;
            listVehicleServices.ItemTemplate = new DataTemplate(typeof(RoadsideVehicleServiceCell));
            listVehicleServices.ItemSelected += ListVehicleServices_ItemSelected;
            listVehicleServices.SeparatorVisibility = SeparatorVisibility.None;
            Global.AddPage(this);
            LoadData();
        }

        private void ListVehicleServices_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem != null)
            {
                if (!isItemSelected)
                {
                    isItemSelected = true;
                    mVehicleService = (VehicleServices)e.SelectedItem;
                    serviceRequestModel.ServiceType = mVehicleService.ProgramService;

                    LoadServiceQuestionsData();
                }
            }
        }
        private async void LoadServiceQuestionsData()
        {
            MemberHelper memberHelper = new MemberHelper();
            using (new HUD("Loading..."))
            {
                OperationResult operationResult = await memberHelper.GetVehicleServiceQuestions(mVehicleService.ProgramService, mVehicle.VehicleCategory, mVehicle.VehicleType);

                isItemSelected = false;
                listVehicleServices.SelectedItem = null;

                if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
                {
                    roadsideServiceQuestionsList.Clear();
                    roadsideServiceQuestionsList = JsonConvert.DeserializeObject<List<RoadsideServiceQuestions>>(operationResult.Data.ToString());


                    if (roadsideServiceQuestionsList != null && roadsideServiceQuestionsList.Count > 0 && roadsideServiceQuestionsList[0].Questions.Count > 0)
                    {
                        await Navigation.PushAsync(new RoadsideVehicleServiceQuestions(roadsideServiceQuestionsList, serviceRequestModel));
                    }
                    else
                    {
                        if (serviceRequestModel.ServiceType.ToLower() == "tow")
                        {
                            await Navigation.PushAsync(new RoadsideRequestDestination(serviceRequestModel));
                        }
                        else
                        {
                            await Navigation.PushAsync(new ServiceQuestionsSubmit(serviceRequestModel));
                        }
                    }
                }
                else
                {
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
        }
        private void LoadData()
        {
            HUD load = new HUD("Loading...");
            MemberHelper memberHelper = new MemberHelper();


            var result = memberHelper.GetVehicleServices();
            result.ContinueWith(a =>
            {
                if (a.IsCompleted && !a.IsFaulted)
                {
                    VehicleServiceList.Clear();
                    OperationResult operationResult = a.Result;
                    if (operationResult != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
                    {
                        List<VehicleServices> vehicleSerives = JsonConvert.DeserializeObject<List<VehicleServices>>(operationResult.Data.ToString());
                        VehicleServiceList.InsertRange(vehicleSerives);
                    }
                    else
                    {
                        ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                    }
                    Device.BeginInvokeOnMainThread(() =>
                    {

                        if (VehicleServiceList.Count == 0)
                        {
                            lblNoRecords.IsVisible = true;
                            load.Dismiss();
                        }
                        else
                        {
                            lblNoRecords.IsVisible = false;
                            load.Dismiss();
                        }
                    });
                }
                else {
                    load.Dismiss();
                }

            });
        }
    }
}
