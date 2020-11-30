using System;
using Xamarin.Forms;
using System.Collections.Generic;

namespace ODISMember.Helpers.UIHelpers
{
	public class Menu
	{
		public string Name {
			get;
			set;
		}
		public string Icon {
			get;
			set;
		}
		public Action ActionOnClick {
			get;
			set;
		}
		public ToolbarItemOrder ToolbarItemOrder {
			get;
			set;
		}
		public int Priority{
			get;
			set;
		}
		/*public Menu(string name, Action actionOnClick)
		{
			Name = name;
			Icon = string.Empty;
			ActionOnClick = actionOnClick;
			ToolbarItemOrder = ToolbarItemOrder.Default;
			Priority = 0;
		}*/
	}
	public static class CommonMenu
	{
		public static List<MenuItem> PreviousMenus{ set; get;}
		public static void CreateBackButton(ContentPage currentPage){
			ToolbarItem tbi = null;
			if (Device.OS == TargetPlatform.iOS)
			{
				tbi = new ToolbarItem("Back", "back.png", () =>
					{
						currentPage.Navigation.PopAsync();
					}, 0, 0);
			}
			if (Device.OS == TargetPlatform.Android) { // BUG: Android doesn't support the icon being null
                tbi = new ToolbarItem("Back", "back.png", () =>
					{
						currentPage.Navigation.PopAsync();
					}, ToolbarItemOrder.Primary, 0);
			}
			if (Device.OS == TargetPlatform.WinPhone)
			{
                tbi = new ToolbarItem("Back", "back.png", () =>
					{
						//OpenCouponsPage();
					}, 0, 0);
			}

			currentPage.ToolbarItems.Add (tbi);
		}

		public static void CreateFilterButton(ContentPage currentPage, Action onActive)
		{
			
			ToolbarItem tbi = null;
			if (Device.OS == TargetPlatform.iOS)
			{
                tbi = new ToolbarItem("Filter", "filter.png", onActive, 0, 0);
			}
			if (Device.OS == TargetPlatform.Android) { // BUG: Android doesn't support the icon being null
                tbi = new ToolbarItem("Filter", "filter.png", onActive, ToolbarItemOrder.Primary, 0);
			}
			if (Device.OS == TargetPlatform.WinPhone)
			{
                tbi = new ToolbarItem("Filter", "filter.png", onActive, 0, 0);
			}

			currentPage.ToolbarItems.Add (tbi);
		
		}
		public static void CreateAddButton(ContentPage currentPage, Action onActive)
		{

			ToolbarItem tbi = null;
			if (Device.OS == TargetPlatform.iOS)
			{
                tbi = new ToolbarItem("Add Post", "add_white.png", onActive, 0, 0);
			}
			if (Device.OS == TargetPlatform.Android) { // BUG: Android doesn't support the icon being null
                tbi = new ToolbarItem("Add Post", "add_white.png", onActive, ToolbarItemOrder.Primary, 0);
			}
			if (Device.OS == TargetPlatform.WinPhone)
			{
                tbi = new ToolbarItem("Add Post", "add_white.png", onActive, 0, 0);
			}

			currentPage.ToolbarItems.Add (tbi);

		}
		public static void CreateRefreshButton(ContentPage currentPage, Action onActive)
		{

			ToolbarItem tbi = null;
			if (Device.OS == TargetPlatform.iOS)
			{
                tbi = new ToolbarItem("Refresh", "refresh.png", onActive, 0, 0);
			}
			if (Device.OS == TargetPlatform.Android) { // BUG: Android doesn't support the icon being null
                tbi = new ToolbarItem("Refresh", "refresh.png", onActive, ToolbarItemOrder.Primary, 0);
			}
			if (Device.OS == TargetPlatform.WinPhone)
			{
                tbi = new ToolbarItem("Refresh", "refresh.png", onActive, 0, 0);
			}

			currentPage.ToolbarItems.Add (tbi);

		}

		public static void CreateMenu(ContentPage contentPage, Menu menu)
		{
			ToolbarItem tbi = null;
			tbi = new ToolbarItem(menu.Name, menu.Icon, menu.ActionOnClick, menu.ToolbarItemOrder, menu.Priority);
			contentPage.ToolbarItems.Add (tbi);
		}

		public static void ResetToolbar(ContentPage contentPage){
			contentPage.ToolbarItems.Clear ();
		}
	}
}

