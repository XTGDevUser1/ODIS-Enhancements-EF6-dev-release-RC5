using System;
using Xamarin.Forms;

namespace ODISMember.CustomControls.CardLayout
{
    public class CardStatusView : ContentView
    {
        public CardStatusView(int status)
        {
            var statusBoxView = new BoxView
            {
                VerticalOptions = LayoutOptions.Fill,
                HorizontalOptions = LayoutOptions.Fill
            };

            switch (status)
            {
                case CardStatus.Other:
                    statusBoxView.BackgroundColor = StyleKit.Status.InProgressColor;
                    break;
                case CardStatus.Entry:
                    statusBoxView.BackgroundColor = StyleKit.Status.InProgressColor;
                    break;
                case CardStatus.Complete:
                    statusBoxView.BackgroundColor = StyleKit.Status.CompletedColor;
                    break;
                case CardStatus.Cancelled:
                    statusBoxView.BackgroundColor = StyleKit.Status.CanceledColor;
                    break;
                default:
                    statusBoxView.BackgroundColor = StyleKit.Status.InProgressColor;
                    break;
            }


            Content = statusBoxView;
        }
    }
}