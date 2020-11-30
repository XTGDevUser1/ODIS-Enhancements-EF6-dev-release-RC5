using ODISMember.Widgets;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;

namespace ODISMember.Behaviors
{
   public class ConfirmPasswordBehavior_LabelEntryVertical: Behavior<LabelEntryVertical>
    {
        public ConfirmPasswordBehavior_LabelEntryVertical(LabelEntryVertical supportingWidget) {
            SupportingWidget = supportingWidget;
        }
        public LabelEntryVertical CurrentWidget
        {
            get;
            set;
        }
        public LabelEntryVertical SupportingWidget
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
        private void check_Validation(string text)
        {

            if (IsRequired && string.IsNullOrEmpty(text))
            {
                IsValid = false;
                CurrentWidget.IsValid = false;
                CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
                CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");

            }
            else if (!string.IsNullOrEmpty(text))
            {
                bool temp = (CurrentWidget.EntryText == SupportingWidget.EntryText);
                IsValid = temp;
                CurrentWidget.IsValid = temp;
                CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
                CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Passwords do not match");
            }
            else
            {
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
