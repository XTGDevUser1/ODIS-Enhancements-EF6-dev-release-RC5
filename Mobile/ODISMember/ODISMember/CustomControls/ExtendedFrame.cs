using System;
using Xamarin.Forms;
using XLabs.Forms.Controls;

namespace ODISMember.CustomControls
{
	public class ExtendedFrame:Frame
	{
		public ExtendedFrame (string imgSource,string labelText)
		{
			
			Opacity = 0.7;
			BackgroundColor = Color.Black;
			Padding = new Thickness (0);
			StackLayout stackDistance = new StackLayout () {
				BackgroundColor = Color.Transparent,
				Orientation = StackOrientation.Horizontal,
				VerticalOptions = LayoutOptions.Center,
				HorizontalOptions = LayoutOptions.StartAndExpand,
				Padding = new Thickness (5),
				Children= {
					new Image(){
						Source=imgSource,
						HeightRequest=20,
						WidthRequest=20
					},
					new ExtendedLabel(){
						FontName="OpenSans-Semibold.ttf",
						FontSize= 14,
						TextColor=Color.White,
						Text=labelText
					}
				}
			};

			Content = stackDistance;
		}
	}
}

