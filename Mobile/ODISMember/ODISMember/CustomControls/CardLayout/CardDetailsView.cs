using System;

using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls.CardLayout
{
	public class CardDetailsView : ContentView
	{
		public CardDetailsView (Card card)
		{
			BackgroundColor = Color.White;

            ExtendedLabel TitleText = new ExtendedLabel() {
				Text = card.Title,
                Style = (Style)Application.Current.Resources["HeaderLabelStyle"],//SubHeaderBoldLabelStyle"],
                FontSize = 18,
				TextColor = StyleKit.LightTextColor
			};

            ExtendedLabel DescriptionText = new ExtendedLabel() {
				Text = card.Description,
                Style = (Style)Application.Current.Resources["SubHeaderLabelStyle"],
                FontSize = 16,
				TextColor = StyleKit.LightTextColor
			};

			var stack = new StackLayout () {
				Spacing = 0,
				Padding = new Thickness (10, 5, 0, 0),
				VerticalOptions = LayoutOptions.CenterAndExpand,
				Children = {
					TitleText,
					DescriptionText,
					new DateTimeView (card)
				}
			};

			Content = stack;
		}
	}
}