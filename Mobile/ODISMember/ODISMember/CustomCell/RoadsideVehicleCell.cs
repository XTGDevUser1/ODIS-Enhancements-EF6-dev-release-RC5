using ODISMember.Classes;
using ODISMember.Entities.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember
{
    public class RoadsideVehicleCell : ViewCell
    {
        #region Properties
        ExtendedLabel VehicleInfo;
        #endregion

        public RoadsideVehicleCell()
        {
            StackLayout root = new StackLayout()
            {
                Orientation = StackOrientation.Vertical,
                Spacing = 0,
                VerticalOptions = LayoutOptions.Fill,
                BackgroundColor = ColorResources.RoadsideVehicleLayoutBackground,
                Padding = new Thickness(5, 5, 5, 5)
            };

            StackLayout outlineLayout = new StackLayout()
            {
                Orientation = StackOrientation.Vertical,
                Spacing = 0,
                VerticalOptions = LayoutOptions.Fill,
                BackgroundColor = ColorResources.RoadsideVehicleLayoutCardBackOutLine,
                Padding = new Thickness(0, 0, 1, 1)
            };

            StackLayout infoLayout = new StackLayout()
            {
                Orientation = StackOrientation.Horizontal,
                Spacing = 20,
                BackgroundColor = Color.White,
                Padding = new Thickness(20)
            };

            VehicleInfo = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["SubHeaderBoldLabelStyle"],
                HorizontalTextAlignment = TextAlignment.Start,
                FontSize = 12,
                VerticalOptions = LayoutOptions.Center
            };

            outlineLayout.Children.Add(infoLayout);
            infoLayout.Children.Add(VehicleInfo);

            root.Children.Add(outlineLayout);

            View = root;
        }

        protected override void OnBindingContextChanged()
        {
            VehicleModel vehicle = (VehicleModel)BindingContext;
            if (vehicle != null)
            {
                string make, model;
                if (!string.IsNullOrEmpty(vehicle.Make) && vehicle.Make.ToLower() == "other")
                {
                    make = vehicle.MakeOther;
                }
                else
                {
                    make = vehicle.Make;
                }
                if (!string.IsNullOrEmpty(vehicle.Model) && vehicle.Model.ToLower() == "other")
                {
                    model = vehicle.ModelOther;
                }
                else
                {
                    model = vehicle.Model;
                }
                VehicleInfo.Text = vehicle.Year + " " + make + " " + model;
            }

            base.OnBindingContextChanged();
        }
    }
}
