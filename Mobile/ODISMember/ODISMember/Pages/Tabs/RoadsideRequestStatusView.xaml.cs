using ODISMember.Common;
using ODISMember.CustomControls;
using ODISMember.Helpers.UIHelpers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class RoadsideRequestStatusView : ContentView, ITabView
    {
        BaseContentPage Parent;
        public RoadsideRequestStatusView(BaseContentPage parent, string trackerId)
        {
            InitializeComponent();
            Parent = parent;
            StatusMap statusMap = new StatusMap(parent, trackerId);
            this.Content = statusMap;
        }
       
        public string Title
        {
            get
            {
                return "Status";
            }
        }

        public void InitializeToolbar()
        {
            //throw new NotImplementedException();
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
            //throw new NotImplementedException();
        }
    }
}
