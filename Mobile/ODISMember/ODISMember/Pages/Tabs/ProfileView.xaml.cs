using ODISMember.CustomControls;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class ProfileView : ContentPage
    {
        Associate mAssociate;
        public ProfileView(Associate associate)
        {
            InitializeComponent();
            mAssociate = associate;
            this.Title = "Profile";
            
            scrollMain.Content = new ProfileLayout(this,associate);

            if (Constants.IS_MASTER_MEMBER || Constants.MEMBER_NUMBER == associate.MemberNumber)
            {
                Menu menu = new Menu();
                menu.Priority = 0;
                menu.Name = "Edit";
                menu.ToolbarItemOrder = 0;
                menu.ActionOnClick += openMemberEdit;
                CommonMenu.CreateMenu(this, menu);
            }
        }

        private void openMemberEdit()
        {
            Navigation.PushAsync(new EditProfile(mAssociate));
        }
    }
}
