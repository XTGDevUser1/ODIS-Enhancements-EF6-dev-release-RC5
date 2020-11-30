using FFImageLoading.Forms;
using ODISMember.Classes;
using ODISMember.Entities;
using System;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls.CardLayout
{
    public class DateTimeView : ContentView
    {
        public DateTimeView(Card card)
        {


            var labelStyle = new Style(typeof(ExtendedLabel))
            {
                Setters = {
                    new Setter {Property = ExtendedLabel.FontFamilyProperty, Value = FontResources.SubHeaderBoldLabelFontFamily},
                        new Setter {Property = ExtendedLabel.FontSizeProperty, Value = 8},
                        new Setter {Property = ExtendedLabel.TextColorProperty, Value = StyleKit.MediumGrey},
                        new Setter {Property =Image.VerticalOptionsProperty, Value = LayoutOptions.Center}
                            }
            };
            var iconStyle = new Style(typeof(CachedImage))
            {
                Setters = {
                        new Setter {Property = CachedImage.HeightRequestProperty, Value =10},
                        new Setter {Property = CachedImage.WidthRequestProperty, Value = 10},
                        new Setter {Property =Image.VerticalOptionsProperty, Value = LayoutOptions.Center}
                            }
            };

            var stack = new StackLayout()
            {
                VerticalOptions = LayoutOptions.Center,
                HeightRequest = 20,
                Padding = new Thickness(0),
                Orientation = StackOrientation.Horizontal,
                Children = {
                    new Image () {
                        Style = iconStyle,
                        Source = StyleKit.Icons.SmallCalendar,
                    },
                    new Label () {
                        Text = card.Date.ToString (Constants.DateFormat),
                        Style = labelStyle,
                    },
                    new BoxView () { Color = Color.Transparent, WidthRequest = 20 },
                    new Image () {
                        Style = iconStyle,
                        Source = StyleKit.Icons.ManSilhouette,
                    },
                    new Label () {
                        Text = card.PersonName,
                        Style = labelStyle,
                    }
                }
            };

            Content = stack;
        }
    }
}