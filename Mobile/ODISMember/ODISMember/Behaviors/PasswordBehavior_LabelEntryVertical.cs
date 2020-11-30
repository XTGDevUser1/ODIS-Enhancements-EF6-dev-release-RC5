using ODISMember.Widgets;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Behaviors
{
    public class PasswordBehavior_LabelEntryVertical : Behavior<LabelEntryVertical>
    {
        const string passwordRegex = @"^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9]).{8,}$";
        public LabelEntryVertical CurrentWidget
        {
            get;
            set;
        }
        [DefaultValue(null)]
        public bool? IsValid
        {
            get;
            set;
        }
        [DefaultValue(false)]
        public bool IsRequired
        {
            get;
            set;
        }
        protected override void OnAttachedTo(LabelEntryVertical bindable)
        {
            CurrentWidget = bindable;
            CurrentWidget.EntryValue.TextChanged += HandleTextChanged;
            CurrentWidget.Validate += on_Validate;
        }
        private void on_Validate(object sender, EventArgs e)
        {
            check_Validation(CurrentWidget.EntryValue.Text);
        }
        private void HandleTextChanged(object sender, TextChangedEventArgs e)
        {
            check_Validation(e.NewTextValue);
            //e.NewTextValue
        }
        private void check_Validation(string text){

			if (IsRequired && string.IsNullOrEmpty (text)) {
				IsValid = false;
				CurrentWidget.IsValid = false;
				CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
				CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");

			} else if (!string.IsNullOrEmpty (text)) {
                bool temp = (Regex.IsMatch(text, passwordRegex));
				IsValid = temp;
				CurrentWidget.IsValid = temp;
				
				CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
				CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Password must be at least 8 characters long, have 1 uppercase letter, 1 lowercase letter and 1 number");
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
