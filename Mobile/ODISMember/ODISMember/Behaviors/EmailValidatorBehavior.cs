using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Xamarin.Forms;
using ODISMember.Widgets;
using System.ComponentModel;

namespace ODISMember.Behaviors
{
	public class EmailValidatorBehavior : Behavior<LabelEntryVertical>
    {
        const string emailRegex = @"^(?("")("".+?(?<!\\)""@)|(([0-9a-z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-z])@))" +
            @"(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-z][-\w]*[0-9a-z]*\.)+[a-z0-9][\-a-z0-9]{0,22}[a-z0-9]))$";
		
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

			if (IsRequired && string.IsNullOrEmpty (text)) {
				IsValid = false;
				CurrentWidget.IsValid = false;
				CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
				CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");

			} else if (!string.IsNullOrEmpty (text)) {
				bool temp = (Regex.IsMatch(text, emailRegex, RegexOptions.IgnoreCase, TimeSpan.FromMilliseconds(250)));
				IsValid = temp;
				CurrentWidget.IsValid = temp;
				
				CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
				CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Please enter valid email");
			} else {
				IsValid = true;
				CurrentWidget.IsValid = true;
				CurrentWidget.ImageValidate.Source = null;
				CurrentWidget.EntryErrorMessage = string.Empty;
			}
		}

		protected override void OnDetachingFrom(LabelEntryVertical bindable)
        {
			CurrentWidget.EntryValue.TextChanged -= HandleTextChanged;
			CurrentWidget.Validate -= on_Validate;
        }

    }
}
