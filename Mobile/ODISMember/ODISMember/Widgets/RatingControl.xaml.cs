using System;
using System.Collections.Generic;

using Xamarin.Forms;

namespace ODISMember.Widgets
{
	public partial class RatingControl  : StackLayout
	{
		public int Rating {
			get{ return int.Parse(RatingCount.Text);}
		}
		public RatingControl ()
		{
			InitializeComponent ();
			this.Orientation = StackOrientation.Vertical;
			this.HeightRequest = 70;
		}
		public bool onValidate(){
			//Validate.Invoke (new object (), EventArgs.Empty);
			//return IsValid;
			if (Rating == 0) {
				lblError.Text = "* Rating is mandatory";
				return false;
			} else {
				lblError.Text = string.Empty;
				return true;
			}
		}
	}
}

