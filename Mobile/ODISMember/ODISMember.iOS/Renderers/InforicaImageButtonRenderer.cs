using Xamarin.Forms;
using System;
using ODISMember.iOS.Renderer;
using FFImageLoading.Forms.Touch;
using FFImageLoading.Forms;
using Xamarin.Forms.Platform.iOS;
using Foundation;
using UIKit;
using ODISMember.CustomControls;

[assembly: ExportRenderer (typeof(InforicaImageButton), typeof(InforicaImageButtonRenderer))]
namespace ODISMember.iOS.Renderer
{
	public class InforicaImageButtonRenderer:CachedImageRenderer
	{
		private InforicaImageButton _formsControl = null;

		protected override void OnElementChanged (ElementChangedEventArgs<CachedImage> e)
		{
			base.OnElementChanged (e);
            if (e.NewElement != null) {
                //this.Control.ExclusiveTouch = true;
                var imageField = (UIImageView)Control;
                
                _formsControl = e.NewElement as InforicaImageButton;
			}            
		}

        public override void TouchesBegan(NSSet touches, UIEvent evt)
        {
            if (_formsControl != null)
            {
                _formsControl.RaiseClicked(_formsControl,null);
                
            }
            base.TouchesBegan(touches, evt);
        }
       

    }
}

