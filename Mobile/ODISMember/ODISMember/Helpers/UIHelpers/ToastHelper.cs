using System;
using Plugin.Toasts;
using ODISMember.Entities;
using Xamarin.Forms;

namespace ODISMember
{
    public static class ToastHelper
    {
        public static void ShowSuccessToast(string title, string Message = "")
        {
            if (Message == null)
            {
                Message = "";
            }
            Device.BeginInvokeOnMainThread(() =>
            {
                IToastNotificator Notificator = DependencyService.Get<IToastNotificator>();
                Notificator.Notify(ToastNotificationType.Success, title, Message, TimeSpan.FromSeconds(Constants.ToastTimeSpan));
            });
        }
        public static void ShowErrorToast(string title, string Message = "")
        {
            if (Message == null)
            {
                Message = "";
            }
            Device.BeginInvokeOnMainThread(() =>
            {
                IToastNotificator Notificator = DependencyService.Get<IToastNotificator>();
                Notificator.Notify(ToastNotificationType.Error, title, Message, TimeSpan.FromSeconds(Constants.ToastTimeSpan));
            });
        }
        public static void ShowWarningToast(string title, string Message = "")
        {
            if (Message == null)
            {
                Message = "";
            }
            Device.BeginInvokeOnMainThread(() =>
            {
                IToastNotificator Notificator = DependencyService.Get<IToastNotificator>();
                Notificator.Notify(ToastNotificationType.Warning, title, Message, TimeSpan.FromSeconds(Constants.ToastTimeSpan));
            });
        }
        public static void ShowInfoToast(string title, string Message = "")
        {
            if (Message == null)
            {
                Message = "";
            }
            Device.BeginInvokeOnMainThread(() =>
            {
                IToastNotificator Notificator = DependencyService.Get<IToastNotificator>();
                Notificator.Notify(ToastNotificationType.Info, title, Message, TimeSpan.FromSeconds(Constants.ToastTimeSpan));
            });
        }
    }
}

