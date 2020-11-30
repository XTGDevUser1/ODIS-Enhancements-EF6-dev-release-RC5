using System;
using Xamarin.Forms;
using ODISMember.Widgets;
using XLabs.Forms.Controls;
using FFImageLoading.Forms;
using ODISMember.Entities.Model;
using System.IO;
using ODISMember.Classes;
using FFImageLoading.Work;
using FFImageLoading.Transformations;

namespace ODISMember
{
    public class VehicleCell : ViewCell
    {
        ExtendedLabel FirstLine, SecondLine;
        CachedImage Photo,ArrowImage;
        public VehicleCell()
        {
            Grid grid = new Grid
            {
                BackgroundColor = Color.White,
                VerticalOptions = LayoutOptions.FillAndExpand,
                RowDefinitions =
                {
                    new RowDefinition { Height = GridLength.Auto }
                },
                ColumnDefinitions =
                {
                     new ColumnDefinition { Width = new GridLength(60) },
                    new ColumnDefinition { Width = new GridLength(1,GridUnitType.Star) },
                    new ColumnDefinition { Width = new GridLength(60) }
                }
            };

            
            StackLayout infoLayout = new StackLayout() {
                HorizontalOptions = LayoutOptions.StartAndExpand,
                VerticalOptions = LayoutOptions.CenterAndExpand
            };
            FirstLine = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["VehicleListFirstLineStyle"],
                HorizontalTextAlignment = TextAlignment.Start,
                HorizontalOptions = LayoutOptions.StartAndExpand
            };
            SecondLine = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["VehicleListSecondLineStyle"],
                HorizontalTextAlignment = TextAlignment.Start,
                HorizontalOptions = LayoutOptions.StartAndExpand
            };

            StackLayout imageStackLayout = new StackLayout()
            {
                Padding = new Thickness(5)
            };

            Photo = new CachedImage()
            {
                Aspect = Aspect.AspectFit,
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                VerticalOptions = LayoutOptions.CenterAndExpand,
                HeightRequest = Entities.Constants.FFIMAGE_VEHICLE_HEIGHT,
                WidthRequest = Entities.Constants.FFIMAGE_VEHICLE_WIDTH,
                Transformations = new System.Collections.Generic.List<ITransformation>() {
                    new CircleTransformation(),
                }
        };
            imageStackLayout.Children.Add(Photo);

            ArrowImage = new CachedImage()
            {
                Aspect = Aspect.Fill,
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                VerticalOptions = LayoutOptions.CenterAndExpand,
                Source = ImagePathResources.ArrowSymbol,
            LoadingPlaceholder = ImagePathResources.ArrowSymbol,
            ErrorPlaceholder = ImagePathResources.ArrowSymbol
        };

            infoLayout.Children.Add(FirstLine);
            infoLayout.Children.Add(SecondLine);

            grid.Children.Add(imageStackLayout,0,0);
            grid.Children.Add(infoLayout,1,0);
            grid.Children.Add(ArrowImage,2,0);

            StackLayout MainLayout = new StackLayout()
            {
                Padding = new Thickness(0, 2, 0, 0),
                BackgroundColor = ColorResources.VehiclesListBackgroundColor
            };
            MainLayout.Children.Add(grid);
            View = MainLayout;

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
                else {
                    make = vehicle.Make;
                }
                if (!string.IsNullOrEmpty(vehicle.Model) && vehicle.Model.ToLower() == "other")
                {
                    model = vehicle.ModelOther;
                }
                else {
                    model = vehicle.Model;
                }
                FirstLine.Text = vehicle.Year + " " + make + " " + model;

                SecondLine.Text ="LIC: "+ (string.IsNullOrEmpty(vehicle.LicenseState) ? string.Empty : vehicle.LicenseState+" ") + (string.IsNullOrEmpty(vehicle.LicenseNumber)?string.Empty:vehicle.LicenseNumber);

                //if (vehicle.Photo != null && vehicle.Photo.Length > 0)
                //{
                //    //Photo.Source = ImageSource.FromStream(() => new MemoryStream(vehicle.Photo));
                   
                //    Photo.Source = Xamarin.Forms.ImageSource.FromStream(() =>
                //    {
                //        Stream stream = new MemoryStream(vehicle.Photo);
                //        return stream;
                //    });
                //}
                //else if(vehicle.Photo==null)
                //{
                    if (vehicle.VehicleType == "RV")
                    {
                        Photo.Source = ImagePathResources.VehicleRv;
                        Photo.LoadingPlaceholder = ImagePathResources.VehicleRv;
                        Photo.ErrorPlaceholder = ImagePathResources.VehicleRv;

                    }
                    else if (vehicle.VehicleType == "Auto")
                    {
                        Photo.Source = ImagePathResources.VehicleCar;
                        Photo.LoadingPlaceholder = ImagePathResources.VehicleCar;
                        Photo.ErrorPlaceholder = ImagePathResources.VehicleCar;
                    }
                    else if(vehicle.VehicleType== "Motorcycle")
                    {
                        Photo.Source = ImagePathResources.VehicleMotorCycle;
                        Photo.LoadingPlaceholder = ImagePathResources.VehicleMotorCycle;
                        Photo.ErrorPlaceholder = ImagePathResources.VehicleMotorCycle;
                    }
                //}
            }
            base.OnBindingContextChanged();
        }
    }
}

