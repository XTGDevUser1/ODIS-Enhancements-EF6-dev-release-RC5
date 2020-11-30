using System;
using XLabs.Forms.Controls;
using Android.Widget;
using Xamarin.Forms;
using ODISMember.Droid;
using ODISMember;
using Xamarin.Forms.Platform.Android;

[assembly: ExportRenderer(typeof(DateEntry), typeof(DateEntryRenderer))]
namespace ODISMember.Droid
{
	public class DateEntryRenderer : ExtendedEntryRenderer
	{
		protected override void OnElementChanged(ElementChangedEventArgs<Entry> e)
		{
			base.OnElementChanged (e);
			if (Control != null) {
				Control.Enabled = false;
				Android.Graphics.Color adColor = Element.TextColor.ToAndroid ();
				Control.SetTextColor (adColor);
				const int ID = Resource.Drawable.entry_border;
				var drawable = this.Context.Resources.GetDrawable(ID);
				Control.SetBackgroundDrawable (drawable);
			}

		}
		protected override void OnElementPropertyChanged (object sender, System.ComponentModel.PropertyChangedEventArgs e)
		{
			base.OnElementPropertyChanged (sender, e);
			if (this.Control != null) {
				Control.Enabled = false;
				Android.Graphics.Color adColor = Element.TextColor.ToAndroid ();
				Control.SetTextColor (adColor);
			}

		}
	}
}

