using ODISMember.Classes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls
{
    public class CustomActionBar : RelativeLayout
    {
        public event EventHandler OnCloseClick = null;
        public event EventHandler OnDoneClick = null;
        public Button BtnDone;
        public Button BtnClose;
        public Label Title;

        public CustomActionBar(string title = null)
        {
            HeightRequest = 60; // default height
            VerticalOptions = LayoutOptions.CenterAndExpand;
            HorizontalOptions = LayoutOptions.FillAndExpand;
            if (Device.OS == TargetPlatform.Android)
            {
                Padding = new Thickness(0);
            }
            else
            {
                Padding = new Thickness(5, 20, 5, 0);
            }
            BtnClose = new Button()
            {
                Text = "Cancel",
                HorizontalOptions = LayoutOptions.StartAndExpand,
                FontSize = 13,
                FontAttributes = FontAttributes.Bold,
               // Style = (Style)Application.Current.Resources["ToolbarLabledButtonStyle"],
                TextColor = Color.Black,// ColorResources.ToolbarMenuColor,
                VerticalOptions = LayoutOptions.CenterAndExpand,
                BackgroundColor = Color.Transparent
            };
            BtnClose.Clicked += BtnClose_Clicked;

            BtnDone = new Button()
            {
                Text = "Done",
                HorizontalOptions = LayoutOptions.EndAndExpand,
                FontAttributes = FontAttributes.Bold,
                FontSize = 13,
                // Style = (Style)Application.Current.Resources["ToolbarLabledButtonStyle"],
                TextColor = Color.Black, // ColorResources.ToolbarMenuColor,
                VerticalOptions = LayoutOptions.CenterAndExpand,
                BackgroundColor=Color.Transparent
            };
            BtnDone.Clicked += BtnDone_Clicked;
            if (!string.IsNullOrEmpty(title))
            {
                Title = new Label()
                {
                    Text = title,
                    FontAttributes = FontAttributes.Bold,
                    FontSize = 18,
                    TextColor = Color.Black,
                    // Style = (Style)Application.Current.Resources["ToolbarHeaderLabelStyle"],
                    HorizontalTextAlignment = TextAlignment.Center,
                    VerticalTextAlignment = TextAlignment.Center,
                    VerticalOptions = LayoutOptions.CenterAndExpand
                };
            }
            FFImageLoading.Forms.CachedImage cardBackground = new FFImageLoading.Forms.CachedImage()
            {
                Source = ImagePathResources.CardShadowBackground,
                Aspect = Aspect.Fill,
                CacheDuration = TimeSpan.FromDays(30),
                DownsampleToViewSize = true,
                RetryCount = 0,
                RetryDelay = 250,
                TransparencyEnabled = false
            };
            Grid menuGrid = new Grid()
            {
               Padding = new Thickness(0),
               VerticalOptions = LayoutOptions.CenterAndExpand
            };
            menuGrid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            if (!string.IsNullOrEmpty(title))
            {
                menuGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(2, GridUnitType.Star) });
                menuGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(3, GridUnitType.Star) });
                menuGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(2, GridUnitType.Star) });

                menuGrid.Children.Add(BtnClose, 0, 0);
                menuGrid.Children.Add(Title, 1, 0);
                menuGrid.Children.Add(BtnDone, 2, 0);
            }
            else
            {
                menuGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
                menuGrid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });

                menuGrid.Children.Add(BtnClose, 0, 0);
                menuGrid.Children.Add(BtnDone, 1, 0);
            }
            this.Children.Add(cardBackground,

                Constraint.RelativeToParent((parent) =>
                {
                    return parent.X - 10;
                }),
                  Constraint.RelativeToParent((parent) =>
                  {
                      return parent.Y;
                  }),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.WidthRequest == -1) ? parent.Width + 20 : parent.WidthRequest + 20);
                }),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.HeightRequest == -1) ? parent.Height : parent.HeightRequest);
                }));
            this.Children.Add(menuGrid,
                Constraint.RelativeToParent((parent) =>
                {
                    return parent.X;
                }),
                  Constraint.RelativeToParent((parent) =>
                  {
                      return parent.Y;
                  }),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.WidthRequest == -1) ? parent.Width : parent.WidthRequest);
                }),
                Constraint.RelativeToParent((parent) =>
                {
                    return ((parent.HeightRequest == -1) ? parent.Height : parent.HeightRequest);
                }));
        }

        private void BtnDone_Clicked(object sender, EventArgs e)
        {
            if (OnDoneClick != null)
            {
                OnDoneClick.Invoke(sender, e);
            }
        }

        private void BtnClose_Clicked(object sender, EventArgs e)
        {
            if (OnCloseClick != null)
            {
                OnCloseClick.Invoke(sender, e);
            }
        }
    }
}
