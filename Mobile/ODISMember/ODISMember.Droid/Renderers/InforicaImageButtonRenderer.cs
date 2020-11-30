using Xamarin.Forms.Platform.Android;
using Xamarin.Forms;
using RakPages;
using Android.Views;
using System;
using RakPages.Droid;
using FFImageLoading.Forms;
using FFImageLoading.Forms.Droid;
using ODISMember.CustomControls;

[assembly: ExportRenderer (typeof(InforicaImageButton), typeof(InforicaImageButtonRenderer))]
namespace RakPages.Droid
{
	public class InforicaImageButtonRenderer : CachedImageRenderer
	{
		private InforicaImageButton _formsControl = null;

		protected override void OnElementChanged (ElementChangedEventArgs<CachedImage> e)
		{
			base.OnElementChanged (e);

			if (e.NewElement == null) {
				this.Touch -= HandleTouch;
			} else {
				_formsControl = e.NewElement as InforicaImageButton;
			}

			if (e.OldElement == null) {
				this.Touch += HandleTouch;
			}
		}

		void HandleTouch (object sender, TouchEventArgs e)
		{
			if (e.Event.Action == MotionEventActions.Up) {
				//Console.WriteLine ("OnTouch happened");
				_formsControl.RaiseClicked (sender,e);//ButtonClick.Invoke (sender, e);
			}
		}
	}
}

