using FFImageLoading.Forms;
using ODISMember.Classes;
using ODISMember.Entities.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.Pages.Tabs
{
    public class RoadsideVehicleServiceCell : ViewCell
    {
        #region Properties
        ExtendedLabel VehicleServiceInfo;
        CachedImage ServiceImage;
        #endregion

        public RoadsideVehicleServiceCell()
        {
            Grid grid = new Grid
            {
                BackgroundColor = Color.White,
                Padding = new Thickness(20, 10, 20, 10),
                VerticalOptions = LayoutOptions.FillAndExpand,
                RowDefinitions = {
                    new RowDefinition { Height = new GridLength (1, GridUnitType.Auto) }
            },
                ColumnDefinitions = {
                    new ColumnDefinition { Width = new GridLength (1, GridUnitType.Star) },
                    new ColumnDefinition { Width = new GridLength (40, GridUnitType.Absolute) }
                }
            };
            //StackLayout root = new StackLayout()
            //{
            //    Orientation = StackOrientation.Vertical,
            //    Spacing = 0,
            //    VerticalOptions = LayoutOptions.Fill,
            //    BackgroundColor = ColorResources.RoadsideVehicleLayoutBackground,
            //    Padding = new Thickness(5, 5, 5, 5)
            //};

            //StackLayout outlineLayout = new StackLayout()
            //{
            //    Orientation = StackOrientation.Vertical,
            //    Spacing = 0,
            //    VerticalOptions = LayoutOptions.Fill,
            //    BackgroundColor = ColorResources.RoadsideVehicleLayoutCardBackOutLine,
            //    Padding = new Thickness(0, 0, 1, 1)
            //};


            VehicleServiceInfo = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["SubHeaderBoldLabelStyle"],
                HorizontalTextAlignment = TextAlignment.Start,
                VerticalTextAlignment = TextAlignment.Center
            };
            VehicleServiceInfo.SetBinding(ExtendedLabel.TextProperty, "ProgramServiceDescription");

            ServiceImage = new CachedImage()
            {
                HorizontalOptions = LayoutOptions.EndAndExpand,
                VerticalOptions = LayoutOptions.CenterAndExpand,
                HeightRequest = 40,
                WidthRequest = 40
            };
            StackLayout MainLayout = new StackLayout()
            {
                Padding = new Thickness(0, 2, 0, 0),
                BackgroundColor = ColorResources.VehiclesListBackgroundColor
            };

            //outlineLayout.Children.Add(grid);
            grid.Children.Add(VehicleServiceInfo, 0, 1, 0, 1);
            grid.Children.Add(ServiceImage, 1, 2, 0, 1);
            MainLayout.Children.Add(grid);

            View = MainLayout;
        }

        protected override void OnBindingContextChanged()
        {
            VehicleServices vehicleServices = (VehicleServices)BindingContext;
            if (vehicleServices != null && !string.IsNullOrEmpty(vehicleServices.ProgramService))
            {
                if (vehicleServices.ProgramService.ToLower() == "tow")
                {
                    ServiceImage.Source = ImagePathResources.TowService;
                }
                else if (vehicleServices.ProgramService.ToLower() == "tire")
                {
                    ServiceImage.Source = ImagePathResources.TireService;
                }
                else if (vehicleServices.ProgramService.ToLower() == "lockout")
                {
                    ServiceImage.Source = ImagePathResources.LockoutService;
                }
                else if (vehicleServices.ProgramService.ToLower() == "fluid")
                {
                    ServiceImage.Source = ImagePathResources.FluidService;
                }
                else if (vehicleServices.ProgramService.ToLower() == "jump")
                {
                    ServiceImage.Source = ImagePathResources.JumpService;
                }
                else if (vehicleServices.ProgramService.ToLower() == "winch")
                {
                    ServiceImage.Source = ImagePathResources.WinchService;
                }
            }

            base.OnBindingContextChanged();
        }
    }
}
