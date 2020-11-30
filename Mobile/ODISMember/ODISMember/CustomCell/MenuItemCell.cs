using System;
using Xamarin.Forms;
using XLabs.Forms.Controls;
using ODISMember.Classes;
using ODISMember.Common;

namespace ODISMember
{
	public class MenuItemCell: CustomMenuViewCell
    {
		public Image imgMenu;
		public ExtendedLabel lblMenu;

		public MenuItemCell ()
		{
			imgMenu = new Image () {
				HeightRequest = 30,
				WidthRequest = 30,
                VerticalOptions=LayoutOptions.CenterAndExpand
			};
            lblMenu = new ExtendedLabel() {
                Style = (Style)Application.Current.Resources["LeftMenuLabelStyle"],
                VerticalTextAlignment = TextAlignment.Center,
                FontSize = FontResources.MenuItemFontSize
			};
			imgMenu.SetBinding (Image.SourceProperty, "IconSource");
			lblMenu.SetBinding(Label.TextProperty, "Title");
			lblMenu.SetBinding(Label.TextColorProperty, "TextColor");

			StackLayout horizontalLayout = new StackLayout (){
				Orientation = StackOrientation.Horizontal,
				HorizontalOptions = LayoutOptions.Start,
				VerticalOptions = LayoutOptions.Center,
				Padding = new Thickness(10),
                Spacing = 10
			};
			horizontalLayout.Children.Add (imgMenu);
			horizontalLayout.Children.Add (lblMenu);
			View = horizontalLayout;
		}
	}
}

