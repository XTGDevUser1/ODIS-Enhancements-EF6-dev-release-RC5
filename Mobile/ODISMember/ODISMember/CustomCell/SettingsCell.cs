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

namespace ODISMember
{
    public class SettingsCell : ViewCell
    {
        ExtendedLabel FirstLine;
        Image Tick;
        public SettingsCell()
        {
            FirstLine = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["SubHeaderLabelStyle"],
                VerticalTextAlignment = TextAlignment.Center,
                HorizontalOptions = LayoutOptions.StartAndExpand
            };

            Tick = new Image
            {
                Source = FileImageSource.FromFile("ic_keyboard_arrow_right_black_18dp"),
                HorizontalOptions = LayoutOptions.End
            };


            var layout = new StackLayout
            {
                Padding = new Thickness(20, 0, 20, 0),
                Orientation = StackOrientation.Horizontal,
                HorizontalOptions = LayoutOptions.FillAndExpand,
                Children = { FirstLine, Tick }
            };
            View = layout;

        }
        protected override void OnBindingContextChanged()
        {
            SettingsModel bindingItem = BindingContext as SettingsModel;

            if (bindingItem != null)
            {
                FirstLine.Text = bindingItem.Text;
            }

            base.OnBindingContextChanged();
        }
    }
}
