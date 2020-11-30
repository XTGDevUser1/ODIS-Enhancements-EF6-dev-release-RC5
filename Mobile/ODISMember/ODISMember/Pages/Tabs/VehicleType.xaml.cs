using Newtonsoft.Json;
using ODISMember.Behaviors;
using ODISMember.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class VehicleType : ContentPage
    {
        MemberHelper memberHelper = new MemberHelper();
        public VehicleType()
        {
            InitializeComponent();
            Title = "Select Vehicle Type";
            btnContinue.Clicked += BtnContinue_Clicked;
            widgetVehicleType.Behaviors.Add(new RequireValidatorBehavior_LabelEntryDropdownVertical());
            widgetVehicleType.ItemSource = LoadVehicleTypes();
        }

        private void BtnContinue_Clicked(object sender, EventArgs e)
        {
            widgetVehicleType.onValidate();
            if (widgetVehicleType.IsValid) {
                Navigation.PushAsync(new AddVehicle()); //widgetVehicleType.Value, widgetVehicleType.Key));
            }
        }
        public Dictionary<string, string> LoadVehicleTypes()
        {
            Dictionary<string, string> vehicleType = new Dictionary<string, string>();
            OperationResult operationResult = Task.Run(() => memberHelper.GetVehicleTypes(Constants.MEMBER_PROGRAM_ID)).Result;
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                List<KeyValuePair<string, string>> vehicleTypeList = JsonConvert.DeserializeObject<List<KeyValuePair<string, string>>>(operationResult.Data.ToString());
                if (vehicleTypeList.Count > 0)
                {
                    vehicleType = vehicleTypeList.ToDictionary(pair => pair.Key, pair => pair.Value.ToString());
                }
            }
            else
            {
                if (operationResult != null && operationResult.ErrorMessage != null)
                {
                    ToastHelper.ShowErrorToast("Error", operationResult.ErrorMessage);
                }
            }
            return vehicleType;
        }
    }
}
