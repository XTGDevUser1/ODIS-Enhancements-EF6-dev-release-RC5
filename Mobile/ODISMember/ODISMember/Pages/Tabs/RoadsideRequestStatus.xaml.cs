using ODISMember.Contract;
using ODISMember.CustomControls;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
    public partial class RoadsideRequestStatus : ContentPage
    {
        HUD hud = null;
        public RoadsideRequestStatus(string trackerId)
        {
            InitializeComponent();
            Title = "Status";
            StatusMap statusMap = new StatusMap(this, trackerId);
            this.Content = statusMap;
        }
    }
}
