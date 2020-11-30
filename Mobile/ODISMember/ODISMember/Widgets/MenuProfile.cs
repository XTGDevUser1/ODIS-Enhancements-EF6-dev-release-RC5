using System;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Classes;
using FFImageLoading.Forms;
using FFImageLoading.Work;
using FFImageLoading.Transformations;

namespace ODISMember
{
    public class MenuProfile : StackLayout
    {
        public CachedImage imgProfile;
        public ExtendedLabel lblTitle;
        public ExtendedLabel lblSubTitle;

        public MenuProfile()
        {
            this.Orientation = StackOrientation.Horizontal;
            this.VerticalOptions = LayoutOptions.Start;
            this.BackgroundColor = ColorResources.ProfileBackgroundColor;
            this.Padding = new Thickness(10, 10, 0, 10);
            imgProfile = new CachedImage()
            {
                HeightRequest = Entities.Constants.FFIMAGE_VEHICLE_HEIGHT,
                WidthRequest = Entities.Constants.FFIMAGE_VEHICLE_WIDTH,
                Aspect = Aspect.Fill,
                Transformations = new System.Collections.Generic.List<ITransformation>() {
                    new CircleTransformation()
                }
            };
            lblTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["HeaderLabelStyle"],
                TextColor = ColorResources.DrawerTextColor,
                FontSize=FontResources.MenuProfileNameFontSize,
                LineBreakMode=LineBreakMode.TailTruncation
            };
            lblSubTitle = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["BaseLabelStyle"],
                TextColor = ColorResources.DrawerTextColor,
                FontSize=FontResources.MenuUserNameFontSize,
                LineBreakMode = LineBreakMode.TailTruncation
            };

            StackLayout verticalStack = new StackLayout()
            {
                Orientation = StackOrientation.Vertical,
                VerticalOptions = LayoutOptions.Center
            };
            verticalStack.Children.Add(lblTitle);
            verticalStack.Children.Add(lblSubTitle);
            this.Children.Add(imgProfile);
            this.Children.Add(verticalStack);
        }



        public static BindableProperty ProfileImageSourceProperty =
            BindableProperty.Create<MenuProfile, Xamarin.Forms.ImageSource>(ctrl => ctrl.ProfileImageSource,
                defaultValue: ImagePathResources.ProfileDeafultImage,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (MenuProfile)bindable;
                    ctrl.ProfileImageSource = newValue;
                });

        //The property that handles getting and setting our label/property.
        public Xamarin.Forms.ImageSource ProfileImageSource
        {
            get { return (string)GetValue(ProfileImageSourceProperty); }
            set
            {
                SetValue(ProfileImageSourceProperty, value);
                //here we update the left title label
                imgProfile.Source = value;
            }
        }

        public static BindableProperty TitleProperty =
            BindableProperty.Create<MenuProfile, string>(ctrl => ctrl.Title,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (MenuProfile)bindable;
                    ctrl.Title = newValue;
                });

        //The property that handles getting and setting our label/property.
        public string Title
        {
            get { return (string)GetValue(TitleProperty); }
            set
            {
                SetValue(TitleProperty, value);
                //here we update the left title label
                lblTitle.Text = value;
            }
        }

        public static BindableProperty SubTitleProperty =
            BindableProperty.Create<MenuProfile, string>(ctrl => ctrl.SubTitle,
                defaultValue: string.Empty,
                defaultBindingMode: BindingMode.TwoWay,
                propertyChanging: (bindable, oldValue, newValue) =>
                {
                    var ctrl = (MenuProfile)bindable;
                    ctrl.SubTitle = newValue;
                });

        //The property that handles getting and setting our label/property.
        public string SubTitle
        {
            get { return (string)GetValue(SubTitleProperty); }
            set
            {
                SetValue(SubTitleProperty, value);
                //here we update the left title label
                lblSubTitle.Text = value;
            }
        }
    }
}

