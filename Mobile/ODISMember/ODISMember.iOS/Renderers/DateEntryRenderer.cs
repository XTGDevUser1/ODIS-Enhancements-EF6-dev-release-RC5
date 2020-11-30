using System;
using XLabs.Forms.Controls;
using Xamarin.Forms;
using ODISMember;
using ODISMember.iOS.Renderers;
using Xamarin.Forms.Platform.iOS;
using UIKit;

[assembly: ExportRenderer(typeof(DateEntry), typeof(DateEntryRenderer))]
namespace ODISMember.iOS.Renderers
{
    public class DateEntryRenderer : ExtendedEntryRenderer
    {
        protected override void OnElementChanged(ElementChangedEventArgs<Entry> e)
        {
            base.OnElementChanged(e);
            if (Control != null)
            {
                Control.Enabled = false;
            }

        }
        protected override void OnElementPropertyChanged(object sender, System.ComponentModel.PropertyChangedEventArgs e)
        {
            base.OnElementPropertyChanged(sender, e);
            if (this.Control != null)
            {
                Control.Enabled = false;
            }

        }
    }
}

