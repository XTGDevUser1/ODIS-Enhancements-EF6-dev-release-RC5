using System;

using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls.CardLayout
{
	public class IconLabelView : ContentView
	{
		public IconLabelView (int? statuId, string statusMessage)
		{
			BackgroundColor = StyleKit.CardFooterBackgroundColor;
            HorizontalOptions = LayoutOptions.FillAndExpand;
			var label = new ExtendedLabel() {
				Text = statusMessage,
                Style = (Style)Application.Current.Resources["SubHeaderBoldLabelStyle"],
                FontSize = 9,
				FontAttributes = FontAttributes.Bold,
				TextColor = StyleKit.LightTextColor
			};
            FileImageSource source = StyleKit.Icons.Resume;
            if (statuId.HasValue)
            {
                switch (statuId)
                {
                    case CardStatus.Other:
                        source = StyleKit.Icons.Alert;
                        break;
                    case CardStatus.Complete:
                        source = StyleKit.Icons.Completed;
                        break;
                    case CardStatus.Entry:
                        source = StyleKit.Icons.Alert;
                        break;
                    case CardStatus.Cancelled:
                        source = StyleKit.Icons.Unresolved;
                        break;
                    default:
                        source = StyleKit.Icons.Unresolved;
                        break;
                }
            }

            if (statusMessage.Trim().ToLower() == "entry") {
                statusMessage = "In Progress";
            }

            var stack = new StackLayout () {
				Padding = new Thickness (5),
				Orientation = StackOrientation.Horizontal,
				HorizontalOptions = LayoutOptions.StartAndExpand,
				VerticalOptions = LayoutOptions.Center,
				Children = {
					new Image () { 
						Source = source, 
						HeightRequest = 10, 
						WidthRequest = 10 
					},
					label
				}
			};

			Content = stack;
		}
	}
}