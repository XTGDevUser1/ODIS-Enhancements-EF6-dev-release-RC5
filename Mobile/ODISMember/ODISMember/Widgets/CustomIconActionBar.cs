using System;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Classes;
using XLabs.Enums;
using ODISMember.CustomControls;
using FFImageLoading.Forms;

namespace ODISMember.Widgets
{
	public class CustomIconActionBar : AbsoluteLayout
    {
		public CachedImage BtnImage;
		public ExtendedLabel ActionBarTitle;
		public CustomIconActionBar ()
		{
			//this.Orientation = StackOrientation.Horizontal;
			//this.HorizontalOptions = LayoutOptions.FillAndExpand;
			this.VerticalOptions=LayoutOptions.Start;

            if (Device.OS == TargetPlatform.iOS) {
                this.Padding = new Thickness(0, 5, 0, 0);
            }

			BtnImage = new CachedImage() {
				Source = ImagePathResources.PageBackIcon,
				HorizontalOptions = LayoutOptions.Start,
				VerticalOptions = LayoutOptions.CenterAndExpand,
				HeightRequest = 50,
				WidthRequest = 50
            };
          

            ActionBarTitle = new ExtendedLabel () {
				Style = (Style)Application.Current.Resources ["ActionBarHeaderLabelStyle"],
                YAlign = TextAlignment.Center,
                XAlign = TextAlignment.Center
                //HorizontalOptions = LayoutOptions.CenterAndExpand,
                //VerticalOptions = LayoutOptions.CenterAndExpand,

            };

            this.Children.Add(
                BtnImage,
                // Adds the Button on the top left corner, with 10% of the navbar's width and 100% height
                new Rectangle(0, 0, 0.1, 1),
                // The proportional flags tell the layout to scale the value using [0, 1] -> [0%, 100%]
                AbsoluteLayoutFlags.HeightProportional | AbsoluteLayoutFlags.WidthProportional
            );

            this.Children.Add(
                ActionBarTitle,
                // Using 0.5 will center it and the layout takes the size of the element into account
                // 0.5 will center, 1 will right align
                // Adds in the center, with 90% of the navbar's width and 100% of height
                new Rectangle(0.5, 0.5, 0.8, 1),
                AbsoluteLayoutFlags.All
            );

          //  this.Children.Add (BtnImage);
			//this.Children.Add (ActionBarTitle);
		}

		public static BindableProperty TitleProperty = 
			BindableProperty.Create<CustomIconActionBar, string>(ctrl => ctrl.Title,
				defaultValue: string.Empty,
				defaultBindingMode: BindingMode.TwoWay,
				propertyChanging: (bindable, oldValue, newValue) => {
					var ctrl = (CustomIconActionBar)bindable;
					ctrl.Title = newValue;
				});

		public string Title {
			get { return (string)GetValue(TitleProperty); }
			set { 
				SetValue (TitleProperty, value);
				ActionBarTitle.Text = value;
			}
		}


	}
}

