﻿using System;

using Xamarin.Forms;

namespace ODISMember.CustomControls.CardLayout
{
	public class ConfigIconView : ContentView
	{
		public ConfigIconView ()
		{
			BackgroundColor = StyleKit.CardFooterBackgroundColor;

			Content = new Image () {
				VerticalOptions = LayoutOptions.Center,
				HorizontalOptions = LayoutOptions.Center,
				HeightRequest = 10,
				WidthRequest = 10,
				Source = StyleKit.Icons.Cog
			};
		}
	}
}