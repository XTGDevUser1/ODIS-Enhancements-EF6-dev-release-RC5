using ODISMember.Common;
using ODISMember.Entities;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Shared;
using System;
using System.Collections.Generic;

using Xamarin.Forms;

namespace ODISMember.Pages.Tabs
{
	public partial class Help : ContentView, ITabView
    {
        BaseContentPage Parent;
        HUD hud=null;
        public Help (BaseContentPage parent)
		{
            Parent = parent;
            InitializeComponent ();
            webHelp.Navigated += WebHelp_Navigated;

            if (!EventDispatcher.IsDelegateExists(new EventHandler<RefreshEventArgs>(EventDispatcher_OnRefresh)))
            {
                EventDispatcher.OnRefresh += EventDispatcher_OnRefresh;
            }
        }

        private void WebHelp_Navigated(object sender, WebNavigatedEventArgs e)
        {
            hud.Dismiss();
        }

        private void EventDispatcher_OnRefresh(object sender, RefreshEventArgs e)
        {
            if (e.EventId == AppConstants.Event.REFRESH_HELP) {
                webHelp.Source = new UrlWebViewSource() { Url = Global.ApplicationSettings[ApplicationSettings.HELP] };
                hud = new HUD("Loading...");
            }
        }

        public string Title
        {
            get
            {
                return "Help";
            }
        }

        public void InitializeToolbar()
        {
            //throw new NotImplementedException();
        }

        public void ResetToolbar()
        {
            CommonMenu.ResetToolbar(Parent);
        }
    }
}

