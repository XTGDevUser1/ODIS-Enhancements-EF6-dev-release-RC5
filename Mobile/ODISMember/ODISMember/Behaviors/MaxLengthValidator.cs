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
	public class MaxLengthValidator : Behavior<LabelEntryVertical>
    {
		public int MaxLength{
			get;
			set;
		}
		public LabelEntryVertical CurrentWidget{
			get;
			set;
		}
		[DefaultValue(null)]
		public bool? IsValid {
			get;
			set;
		}
		[DefaultValue(false)]
		public bool IsRequired {
			get;
			set;
		}
		protected override void OnAttachedTo(LabelEntryVertical bindable)
        {
			CurrentWidget = bindable;
			CurrentWidget.EntryValue.TextChanged += HandleTextChanged;
			CurrentWidget.Validate += on_Validate;
        }
		private void on_Validate(object sender, EventArgs e){
			check_Validation (CurrentWidget.EntryValue.Text);
		}
		private void HandleTextChanged(object sender, TextChangedEventArgs e)
		{
			check_Validation (e.NewTextValue);
			//e.NewTextValue
		}

		private void check_Validation(string text){

			if (IsRequired && string.IsNullOrEmpty(text)) {
				IsValid = false;
				CurrentWidget.IsValid = false;
				CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
				CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");
			} else {

				bool temp = (!string.IsNullOrEmpty(text) && text.Length > MaxLength);

				if (IsValid==null || IsValid != temp) {
					IsValid = temp;
					CurrentWidget.IsValid = temp;
					CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
					CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : string.Format("* Please enter max {0} characters",MaxLength.ToString()));
				} 
				if(!IsRequired && string.IsNullOrEmpty(text)){
					CurrentWidget.LabelError.Text = ""; 
					CurrentWidget.ImageValidate.Source = "";
					CurrentWidget.EntryErrorMessage = string.Empty;
					IsValid = null;
					CurrentWidget.IsValid = true;
				}
			}
		}

		protected override void OnDetachingFrom(LabelEntryVertical bindable)
        {
			CurrentWidget.EntryValue.TextChanged -= HandleTextChanged;
			CurrentWidget.Validate -= on_Validate;
        }
    }
}
