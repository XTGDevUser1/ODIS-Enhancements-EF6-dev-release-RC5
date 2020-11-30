using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
//using Xamarin.Forms;

namespace Xamarin.Forms
{
    public abstract class BaseContentPage : ContentPage
    {
        public int CurrentActiveTab = 0;
        public AbsoluteLayout IndicatorLayout;
       public void CreateLoadingIndicator()
        {
            IndicatorLayout = new AbsoluteLayout();
            IndicatorLayout.BackgroundColor = Color.FromRgba(0, 0, 0, 0.3);
            ActivityIndicator indicator = new ActivityIndicator()
            {
                VerticalOptions = LayoutOptions.CenterAndExpand,
                HorizontalOptions = LayoutOptions.CenterAndExpand,
                Color = Color.Red
            };
            AbsoluteLayout.SetLayoutFlags(indicator, AbsoluteLayoutFlags.PositionProportional);
            AbsoluteLayout.SetLayoutBounds(indicator, new Rectangle(0.5, 0.5, AbsoluteLayout.AutoSize, AbsoluteLayout.AutoSize));
            indicator.IsRunning = true;
            IndicatorLayout.Children.Add(indicator);
            IndicatorLayout.IsVisible = false;
        }
       public RelativeLayout CreateLoadingIndicatorRelativeLayout(RelativeLayout content)
        {
            CreateLoadingIndicator();
            content.Children.Add(IndicatorLayout,
           Constraint.RelativeToParent((parent) =>
           {
               return parent.X;
           }),
           Constraint.RelativeToParent((parent) =>
           {
               return parent.Y;
           }),
           Constraint.RelativeToParent((parent) =>
           {
               return parent.Width;
           }),
           Constraint.RelativeToParent((parent) =>
           {
               return parent.Height;
           }));
            return content;
        }
        public void IsLoading(bool isShowIndicator)
        {
            IndicatorLayout.IsVisible = isShowIndicator;
        }
    }
}
