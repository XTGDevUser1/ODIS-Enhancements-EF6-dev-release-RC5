using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using ODISMember.Widgets;
using System.ComponentModel;

namespace ODISMember.Behaviors
{
	public class RequireValidatorBehavior_LabelDateVertical : Behavior<LabelDateVertical>
	{
		public LabelDateVertical CurrentWidget {
			get;
			set;
		}

		[DefaultValue (null)]
		public bool? IsValid {
			get;
			set;
		}

		protected override void OnAttachedTo (LabelDateVertical bindable)
		{
			CurrentWidget = bindable;
			CurrentWidget.DatePicker.DateEntry.TextChanged += bindable_TextChanged;
			CurrentWidget.Validate += on_Validate;
		}

		private void on_Validate (object sender, EventArgs e)
		{
			check_Validation ();
		}

		private void bindable_TextChanged (object sender, TextChangedEventArgs e)
		{
			check_Validation ();
			//e.NewTextValue
		}

		private void check_Validation ()
		{
			string selectedDate = CurrentWidget.SelectedDate ();
			IsValid = !string.IsNullOrEmpty (selectedDate);
			CurrentWidget.IsValid = IsValid.Value;
			//CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
			CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");
		}

		protected override void OnDetachingFrom (LabelDateVertical bindable)
		{
			CurrentWidget.DatePicker.DateEntry.TextChanged -= bindable_TextChanged;
			CurrentWidget.Validate -= on_Validate;

		}
	}
}
