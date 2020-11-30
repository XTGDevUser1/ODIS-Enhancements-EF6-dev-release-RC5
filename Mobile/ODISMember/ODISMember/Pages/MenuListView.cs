using System;
using Xamarin.Forms;
using System.Collections.Generic;
using ODISMember.Model;
using ODISMember.Classes;

namespace ODISMember.Pages
{
	public class MenuListView:ListView
	{
		public MenuListView ()
		{
            BackgroundColor = ColorResources.MenuBackGroundColor;
            SeparatorVisibility = SeparatorVisibility.None;
            HasUnevenRows = true;
            ItemTemplate = new DataTemplate (typeof(MenuItemCell));
		}
	}
}

