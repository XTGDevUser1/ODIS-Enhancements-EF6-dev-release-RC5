using Newtonsoft.Json;
using ODISMember.Contract;
using ODISMember.Entities;
using ODISMember.Entities.Model;
using ODISMember.Helpers.UIHelpers;
using ODISMember.Shared;
using System;
using System.Collections.Generic;
using System.Linq;
using Xamarin.Forms;

namespace ODISMember.CustomControls
{
    public class StatusMap : StackLayout
    {
        private ContentPage CurrentPage = null;
        private HUD hudLoading = null;
        private WebView statusMap = null;
        private string TrackingId;

        public StatusMap(ContentPage page, string trackerId = null)
        {
            VerticalOptions = LayoutOptions.FillAndExpand;
            hudLoading = new HUD("Loading...");
            CurrentPage = page;
            statusMap = new WebView()
            {
                VerticalOptions = LayoutOptions.FillAndExpand,
                HorizontalOptions = LayoutOptions.FillAndExpand
            };
            statusMap.Navigating += StatusMap_Navigating;
            statusMap.Navigated += StatusMap_Navigated;
            this.Children.Add(statusMap);

            if (string.IsNullOrEmpty(trackerId))
            {
                loadActiveRequest();
            }
            else
            {
                statusMap.Source = new UrlWebViewSource() { Url = string.Format("https://dispatch.pinnacleproviders.com/TrackSR/{0}", trackerId) };
            }
        }

        public async void loadActiveRequest()
        {
            MemberHelper memberHelper = new MemberHelper();
            Member member = memberHelper.GetLocalMember();

            OperationResult operationResult = await memberHelper.GetActiveRequest(member.MembershipNumber);
            if (operationResult != null && operationResult.Data != null && operationResult.Status == OperationStatus.SUCCESS && operationResult.Data != null)
            {
                var serviceRequest = JsonConvert.DeserializeObject<ServiceRequest>(operationResult.Data.ToString());
                if (serviceRequest != null)
                {
                    TrackingId = serviceRequest.RequestNumber.ToString();//TrackerID
                    statusMap.Source = new UrlWebViewSource() { Url = string.Format("https://dispatch.pinnacleproviders.com/TrackSR/{0}", TrackingId) };
                }
                else
                {
                    hudLoading.Dismiss();
                }
            }
            else
            {
                hudLoading.Dismiss();
            }
        }
        
        private async void StatusMap_Navigated(object sender, WebNavigatedEventArgs e)
        {
            if (Device.OS == TargetPlatform.Android)
            {
                if (!string.IsNullOrEmpty(e.Url) && e.Url.Contains("call="))
                {
                    List<string> urlStrings = e.Url.Split(new string[] { "call=" }, StringSplitOptions.None).ToList();
                    if (urlStrings.Count > 1)
                    {
                        Dictionary<Plugin.Permissions.Abstractions.Permission, Plugin.Permissions.Abstractions.PermissionStatus> permissions = await Plugin.Permissions.CrossPermissions.Current.RequestPermissionsAsync(new[] { Plugin.Permissions.Abstractions.Permission.Phone });
                        if (permissions[Plugin.Permissions.Abstractions.Permission.Phone] == Plugin.Permissions.Abstractions.PermissionStatus.Granted)
                        {
                            DependencyService.Get<IPhoneCall>().MakeQuickCall(urlStrings[1]);
                        }
                        else
                        {
                            bool result = await CurrentPage.DisplayAlert("", "Turn on call phone permissions in the Settings to allow Roadside to make a call", "Go To Settings", "Cancel");
                            if (result)
                            {
                                DependencyService.Get<Interfaces.IOpenSettings>().Opensettings();
                            }
                        }
                    }
                }
            }
            hudLoading.Dismiss();
        }

        private void StatusMap_Navigating(object sender, WebNavigatingEventArgs e)
        {
            if (Device.OS == TargetPlatform.iOS)
            {
                if (!string.IsNullOrEmpty(e.Url) && e.Url.Contains("call="))
                {
                    List<string> urlStrings = e.Url.Split(new string[] { "call=" }, StringSplitOptions.None).ToList();
                    if (urlStrings.Count > 1)
                    {
                        DependencyService.Get<IPhoneCall>().MakeQuickCall(urlStrings[1]); //Entities.Constants.DISPATCH_PHONE_NUMBER
                    }
                }
            }
        }
    }
}