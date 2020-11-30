namespace ODISMember.Pages.Registration
{
    using Entities;
    using Helpers.UIHelpers;
    using Shared;
    using System;
    using Xamarin.Forms;
    /// <summary>
    /// It will show the terms and conditions
    /// </summary>
    /// <seealso cref="Xamarin.Forms.ContentPage" />
    public partial class TermsAndConditions : ContentPage
    {
        HUD hud = null;
        LoggerHelper logger = new LoggerHelper();
        public TermsAndConditions()
        {
            InitializeComponent();
            Title = "Terms & Conditions";
            if (Global.ApplicationSettings != null && Global.ApplicationSettings.Count > 0)
            {
                logger.Trace("TermsAndConditions: starts at:" + DateTime.Now.ToString()+" Url:"+ Global.ApplicationSettings[ApplicationSettings.TERMS]);
                webStatus.Source = Global.ApplicationSettings[ApplicationSettings.TERMS];
                hud = new HUD("Loading...");
            }
            webStatus.Navigated += WebStatus_Navigated;
        }
        private void WebStatus_Navigated(object sender, WebNavigatedEventArgs e)
        {
            if (hud != null)
            {
                hud.Dismiss();
                logger.Trace("TermsAndConditions: Ends at:" + DateTime.Now.ToString() + " Url:" + Global.ApplicationSettings[ApplicationSettings.TERMS]);
            }
        }
    }
}
