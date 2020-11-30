using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using ODISMember.Widgets;
using System.ComponentModel;
using XLabs.Forms.Controls;

namespace ODISMember.Behaviors
{
	public class PickerBehavior : Behavior<LabelPickerVertical>
	{
		public LabelPickerVertical CurrentWidget {
			get;
			set;
		}

		[DefaultValue (null)]
		public bool? IsValid {
			get;
			set;
		}

		[DefaultValue (false)]
		public bool IsRequired {
			get;
			set;
		}

		protected override void OnAttachedTo (LabelPickerVertical bindable)
		{
			CurrentWidget = bindable;
			CurrentWidget.Picker.SelectedIndexChanged += bindable_SelectedIndexChanged;
			CurrentWidget.Validate += on_Validate;
		}

		private void on_Validate (object sender, EventArgs e)
		{
			check_Validation (CurrentWidget.Picker);
		}

		private void bindable_SelectedIndexChanged (object sender, EventArgs e)
		{
			check_Validation ((Picker)sender);
		}

		private void check_Validation (Picker picker)
		{

			if (picker.Items.Count > 0) {
				if (IsRequired) {
					if (string.IsNullOrEmpty (CurrentWidget.PickerHint)) {
						IsValid = (picker.SelectedIndex >= 0);
					} else {
						IsValid = (picker.SelectedIndex >= 1);
					}
					CurrentWidget.IsValid = IsValid.Value;
                    //KB: TFS: 1118
                    //CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
                    CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");

				} else {
					IsValid = true;
					CurrentWidget.IsValid = true;
                    //KB: TFS: 1118
                    //CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
                    CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");
				}
			}

		}

		protected override void OnDetachingFrom (LabelPickerVertical bindable)
		{
			CurrentWidget.Picker.SelectedIndexChanged -= bindable_SelectedIndexChanged;
		}
	}
}
