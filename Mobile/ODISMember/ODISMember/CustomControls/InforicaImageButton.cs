using System;
using FFImageLoading.Forms;
using Xamarin.Forms;

namespace ODISMember.CustomControls
{
	public delegate void ImageClickedHandler(object s, EventArgs e);

	public class InforicaImageButton : CachedImage
	{
		public event ImageClickedHandler ImageClicked;

		public void RaiseClicked(object s,EventArgs e){
			if (ImageClicked != null) {
				ImageClicked (s,e);
			}
		}
	}
}

