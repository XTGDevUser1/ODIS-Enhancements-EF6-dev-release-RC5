using ODISMember.Classes;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using Plugin.Permissions;
using Plugin.Permissions.Abstractions;
using System;
using System.Collections.Generic;
using System.Linq;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.Pages.Walkthrough
{
    public class IntraductionPage : ContentPage
    {
        private StackLayout helpScreenLayout;
        private IntraductionView locationHelpScreen;
        private IntraductionView notificationHelpScreen;
        private StackLayout stackLayout;
        private SwitcherPageViewModel viewModel;
        public IntraductionPage()
        {
            viewModel = new SwitcherPageViewModel();
            notificationHelpScreen = new IntraductionView
            {
                BindingContext = viewModel.Pages.ToList()[0],
                VerticalOptions = LayoutOptions.CenterAndExpand
            };
            locationHelpScreen = new IntraductionView
            {
                BindingContext = viewModel.Pages.ToList()[1],
                VerticalOptions = LayoutOptions.CenterAndExpand
            };
            helpScreenLayout = new StackLayout
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                VerticalOptions = LayoutOptions.CenterAndExpand,
                BackgroundColor = ColorResources.PageBackgroundColor
            };
            stackLayout = new StackLayout
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                VerticalOptions = LayoutOptions.FillAndExpand,
                BackgroundColor = ColorResources.PageBackgroundColor,
                Padding = new Thickness(10, 0, 10, 10)
            };

            var btnSkip = new ExtendedButton()
            {
                VerticalOptions = LayoutOptions.End,
                TextColor = Color.White,
                BackgroundColor = ColorResources.WalkthroughButtonBackgroundColor,
                Text = "NOTIFY ME"
            };

            var dots = CreatePagerIndicators();
            dots.VerticalOptions = LayoutOptions.End;
            btnSkip.Clicked +=async (object sender, EventArgs e) =>
            {
                if (btnSkip.Text == "NOTIFY ME")
                {
                    var pushNotifiation = DependencyService.Get<Interfaces.IPushNotification>();
                    pushNotifiation.Register(Constants.USER_NAME);
                    btnSkip.Text = "OK, GOT IT";
                    helpScreenLayout.Children.Remove(notificationHelpScreen);
                    helpScreenLayout.Children.Add(locationHelpScreen);
                    dots.SetActiveDot(1);
                }
                else if (btnSkip.Text == "OK, GOT IT")
                {
                    Dictionary<Permission, PermissionStatus> permissions = await CrossPermissions.Current.RequestPermissionsAsync(new[] { Permission.Location});
                    MemberHelper helper = new MemberHelper();
                    helper.UpdateSettingsWalkthroughDisable(true);
                    App.Current.MainPage = new RootPage(true);
                }
            };
            helpScreenLayout.Children.Add(notificationHelpScreen);
            stackLayout.Children.Add(helpScreenLayout);
            stackLayout.Children.Add(dots);
            stackLayout.Children.Add(btnSkip);

            Content = stackLayout;
        }

        protected override void OnAppearing()
        {
            NavigationPage.SetHasNavigationBar(this, false);
            base.OnAppearing();
        }

        private View CreatePagerIndicatorContainer()
        {
            return new StackLayout
            {
                Children = { CreatePagerIndicators() }
            };
        }

        private PagerIndicatorDots CreatePagerIndicators()
        {
            var pagerIndicator = new PagerIndicatorDots() { DotSize = 10, DotColor = Color.Black, DotSelectedColor = ColorResources.WalkthroughButtonBackgroundColor, NoOfDots = 2 }; //ColorResources.WalkthroughButtonBackgroundColor
            pagerIndicator.AddDots();
            pagerIndicator.SetActiveDot(0);
            return pagerIndicator;
        }

        private CarouselLayout CreatePagesCarousel()
        {
            var carousel = new CarouselLayout
            {
                HorizontalOptions = LayoutOptions.FillAndExpand,
                VerticalOptions = LayoutOptions.FillAndExpand,
                ItemTemplate = new DataTemplate(typeof(IntraductionView))
            };
            carousel.SetBinding(CarouselLayout.ItemsSourceProperty, "Pages");
            carousel.SetBinding(CarouselLayout.SelectedItemProperty, "CurrentPage", BindingMode.TwoWay);

            return carousel;
        }
    }

    public class SpacingConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            var items = value as IEnumerable<IntraductionViewModel>;

            var collection = new ColumnDefinitionCollection();
            foreach (var item in items)
            {
                collection.Add(new ColumnDefinition() { Width = new GridLength(1, GridUnitType.Star) });
            }
            return collection;
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            return new object();
        }
    }
}