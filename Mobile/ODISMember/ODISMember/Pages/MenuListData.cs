using System;
using System.Collections.Generic;
using ODISMember.Model;
using ODISMember.Classes;
using ODISMember.Pages.Tabs;

namespace ODISMember.Pages
{
    public class MenuListDataTop : List<CustomMenuItem>
    {
        public MenuListDataTop()
        {
            this.Add(new CustomMenuItem()
            {
                Id = 1,
                Title = "VEHICLES",
                IconSource = ImagePathResources.VehicleIcon,
                TargetType = typeof(Index),
                TextColor = ColorResources.DrawerTextColor,
                Position = 1,
                EventId = AppConstants.Event.OPEN_VEHICLES


            });
            this.Add(new CustomMenuItem()
            {
                Id = 2,
                Title = "HISTORY",
                IconSource = ImagePathResources.HistoryIcon,
                TargetType = typeof(Index),
                TextColor = ColorResources.DrawerTextColor,
                Position = 1,
                EventId = AppConstants.Event.OPEN_HISTORY
            });
            this.Add(new CustomMenuItem()
            {
                Id = 3,
                Title = "ACCOUNT",
                IconSource = ImagePathResources.AccountIcon,
                TargetType = typeof(Index),
                TextColor = ColorResources.DrawerTextColor,
                Position = 1,
                //IsBottomMenu = true,
                EventId = AppConstants.Event.OPEN_ACCOUNT


            });
            this.Add(new CustomMenuItem()
            {
                Id=4,
                Title="PROFILE",
                IconSource=ImagePathResources.ProfileIcon,
                TargetType=typeof(Index),
                TextColor=ColorResources.DrawerTextColor,
                Position=1,
                EventId=AppConstants.Event.OPEN_PROFILE
            });
            this.Add(new CustomMenuItem()
            {
                Id = 5,
                Title = "SETTINGS",
                IconSource = ImagePathResources.SettingsIcon,
                TargetType = typeof(Index),
                TextColor = ColorResources.DrawerTextColor,
                Position = 1,
                EventId = AppConstants.Event.OPEN_SETTINGS
            });
            this.Add(new CustomMenuItem()
            {
                Id = 6,
                Title = "HELP",
                IconSource = ImagePathResources.HelpIcon,
                TargetType = typeof(Index),
                TextColor = ColorResources.DrawerTextColor,
                Position = 1,
                EventId = AppConstants.Event.OPEN_HELP
            });
            this.Add(new CustomMenuItem()
            {
                Id = 7,
                Title = "LOGOUT",
                IconSource = ImagePathResources.LogoutIcon,
                TargetType = typeof(Index),
                TextColor = ColorResources.DrawerTextColor,
                Position = 1,
                EventId = AppConstants.Event.OPEN_LOGOUT
            });
        }
    }
    public class MenuListDataBottom : List<CustomMenuItem>
    {
        public MenuListDataBottom()
        {
            this.Add(new CustomMenuItem()
            {
                Title = "HELP",
                IconSource = ImagePathResources.HelpIcon,
                TargetType = typeof(Help),
                TextColor = ColorResources.DrawerTextColor,
                Position = 1
                //IsBottomMenu = false,
                //NavigationId = AppConstants.Event.OPEN_HELP
            });
            this.Add(new CustomMenuItem()
            {
                Title = "LOGOUT",
                IconSource = ImagePathResources.LogoutIcon,
                TargetType = typeof(Index),
                TextColor = ColorResources.DrawerTextColor,
                Position = 1
                //IsBottomMenu = false,
                //NavigationId = AppConstants.Event.OPEN_LOGOUT
            });
        }
    }
}

