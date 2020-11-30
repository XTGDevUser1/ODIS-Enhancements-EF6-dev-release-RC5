namespace ODISMember.Pages.Registration
{
    using Shared;
    using Xamarin.Forms;
    /// <summary>
    /// used for creating a new membership functionality 
    /// </summary>
    /// <seealso cref="Xamarin.Forms.ContentPage" />
    public partial class JoinNow : ContentPage
    {
        HUD hud = null;
        public JoinNow()
        {
            InitializeComponent();
            Title = "Join";
            webStatus.Source = "https://www.pinnaclemotorclub.com/pmcmobile/";// "https://mynmcps.com/pmcmobile/default.aspx";
            webStatus.Navigated += WebStatus_Navigated;
            hud = new HUD("Loading...");
        }

        private void WebStatus_Navigated(object sender, WebNavigatedEventArgs e)
        {
            if (hud != null)
                hud.Dismiss();
        }
    }
}
