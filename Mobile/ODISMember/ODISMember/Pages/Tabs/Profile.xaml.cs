using ODISMember.Common;
using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class Profile : ContentView, ITabView
    {
        BaseContentPage Parent;
        Associate mAssociate;
        public Profile(BaseContentPage parent, Associate associate)
        {
            InitializeComponent();
            Parent = parent;
            mAssociate = associate;
            scrollMain.Content = new ProfileLayout(Parent,associate);
        }
        public string Title
        {
            get
            {
                return "Profile";
            }
        }

        public void InitializeToolbar()
        {
            Menu menu = new Menu();
            menu.Priority = 0;
            menu.Name = "Edit";
            menu.ToolbarItemOrder = 0;
            menu.ActionOnClick += openMemberEdit;
            CommonMenu.CreateMenu(Parent, menu);
        }

        private void openMemberEdit()
        {
            Navigation.PushAsync(new EditProfile(mAssociate));
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }
    }
}
