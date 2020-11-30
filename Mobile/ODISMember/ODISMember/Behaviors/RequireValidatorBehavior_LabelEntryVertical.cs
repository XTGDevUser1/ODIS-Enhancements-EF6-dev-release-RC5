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
	public class RequireValidatorBehavior_LabelEntryVertical : Behavior<LabelEntryVertical>
	{
		public LabelEntryVertical CurrentWidget {
			get;
			set;
		}

		[DefaultValue (null)]
		public bool? IsValid {
			get;
			set;
		}

		protected override void OnAttachedTo (LabelEntryVertical bindable)
		{
			CurrentWidget = bindable;
			CurrentWidget.EntryValue.TextChanged += bindable_TextChanged;
			CurrentWidget.Validate += on_Validate;
		}

		private void on_Validate (object sender, EventArgs e)
		{
			check_Validation (CurrentWidget.EntryValue.Text);
		}

		private void bindable_TextChanged (object sender, TextChangedEventArgs e)
		{
			check_Validation (e.NewTextValue);
			//e.NewTextValue
		}

		private void check_Validation (string text)
		{
			IsValid = !string.IsNullOrEmpty (text);
			CurrentWidget.IsValid = IsValid.Value;
            //KB: TFS: 1118
			//CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
			CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");
		}

		protected override void OnDetachingFrom (LabelEntryVertical bindable)
		{
			CurrentWidget.EntryValue.TextChanged -= bindable_TextChanged;
			CurrentWidget.Validate -= on_Validate;

		}
	}
}
