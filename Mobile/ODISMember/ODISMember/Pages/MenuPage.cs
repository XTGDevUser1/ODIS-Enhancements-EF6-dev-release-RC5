using System;
using Xamarin.Forms;
using ODISMember.Model;
using System.Collections.Generic;
using ODISMember.Helpers.UIHelpers;
using System.Linq;
using ODISMember.Classes;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using System.IO;

namespace ODISMember.Pages
{
    public class MenuPage : ContentPage
    {
        public MenuListView TopMenu { get; set; }
        public List<CustomMenuItem> TopMenuData { get; set; }
        MenuProfile menuLabel;

        public MenuPage()
        {
            Title = "Menu";
            Icon = ImagePathResources.DrawerMenuIcon;
            this.BackgroundColor = ColorResources.MenuBackGroundColor;
            TopMenu = new MenuListView();
            TopMenu.ItemsSource = TopMenuData = new MenuListDataTop();
           
            MemberHelper memberHelper = new MemberHelper();
            Member member = memberHelper.GetLocalMember();

            menuLabel = new MenuProfile();

            if (Global.CurrentAssociateMember != null) {
                LoadData(Global.CurrentAssociateMember);
            }

            //TopMenu.SelectedItem = TopMenuData[0];

            var paddingLayout = new StackLayout()
            {
                Padding = new Thickness(3),
                BackgroundColor = Color.Transparent
            };

            var layout = new StackLayout() {
                Spacing=0,
            };
            layout.Children.Add(menuLabel);
            layout.Children.Add(paddingLayout);
            layout.Children.Add(TopMenu);

            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            }

            //if (Device.OS == TargetPlatform.iOS)
            //{
            //    layout.Padding = new Thickness(0, 20, 0, 0);
            //}

            Content = layout;

        }
        protected void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
           
          
            if (e.EventId == AppConstants.Event.REFRESH_CURRENT_MEMBER_DETAILS)
            {
                var associate = sender as Associate;
                if (associate != null)
                {
                    LoadData(associate);
                }
            }
            if (e.EventId == AppConstants.Event.RESET_LEFT_MENU)
            {
                Device.BeginInvokeOnMainThread(() =>
                {
                    TopMenu.SelectedItem = null;
                });
            }

        }
        private void LoadData(Associate associate) {
            menuLabel.Title = associate.FirstName + " " + associate.LastName;
            menuLabel.SubTitle = Constants.USER_NAME; /*"Member # " + associate.MemberNumber;*/ 

            if (associate.Photo != null && associate.Photo.Count()>0)
            {
                menuLabel.ProfileImageSource = ImageSource.FromStream(() =>
                {
                    Stream stream = new MemoryStream(associate.Photo);
                    return stream;
                });
            }
            else
            {
                menuLabel.ProfileImageSource = ImagePathResources.ProfileDeafultImage;
            }
        }
    }
}

