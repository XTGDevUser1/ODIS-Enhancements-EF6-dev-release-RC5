using FFImageLoading.Forms;
using FFImageLoading.Transformations;
using FFImageLoading.Work;
using ODISMember.Classes;
using ODISMember.Entities;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls
{
    public class MemberCellLayout : ViewCell
    {
        ExtendedLabel FullName;
        CachedImage Photo, ArrowImage;
        public MemberCellLayout()
        {
            Grid grid = new Grid();

            grid.BackgroundColor = Color.White;
            grid.RowDefinitions.Add(new RowDefinition { Height = GridLength.Auto });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(60) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            grid.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(60) });

            FullName = new ExtendedLabel()
            {
                Style = (Style)Application.Current.Resources["VehicleListFirstLineStyle"],
                HorizontalTextAlignment = TextAlignment.Start,
                HorizontalOptions = LayoutOptions.StartAndExpand,

                VerticalTextAlignment = TextAlignment.Center
            };

            StackLayout imageStackLayout = new StackLayout()
            {
                Padding = new Thickness(5)
            };

            Photo = new CachedImage()
            {
                Aspect = Aspect.Fill,
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                Source = ImagePathResources.ProfileMenuDeafultImage,
                VerticalOptions = LayoutOptions.CenterAndExpand,
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
            Button MemberTransprentButton = new Button()
            {
                BackgroundColor = Color.Transparent,
            };

            MemberTransprentButton.Clicked += (sender, e) =>
            {
               
            };
            grid.Children.Add(imageStackLayout, 0, 0);
            grid.Children.Add(FullName, 1, 0);
            grid.Children.Add(ArrowImage, 2, 0);

            View = grid;
           
        }
        protected override void OnBindingContextChanged()
        {
            Associate memberAssociats = (Associate)BindingContext;
            if (memberAssociats != null)
            {
                FullName.Text = memberAssociats.FullName;
            }

            base.OnBindingContextChanged();

        }
    }


}
