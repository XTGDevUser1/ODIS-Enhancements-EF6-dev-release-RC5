﻿using System;
using Xamarin.UITest;

namespace ODISMember.UITests
{
	public class AppInitializer
	{
		public static IApp StartApp(Platform platform)
		{
			if(platform == Platform.Android)
			{
				return ConfigureApp.Android.EnableLocalScreenshots().StartApp();
			}

			return ConfigureApp.iOS.EnableLocalScreenshots().StartApp();
		}
	}
}

