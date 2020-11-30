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
	public class RequireValidatorBehavior_LabelEntryDropdownVertical : Behavior<LabelEntryDropdownVertical> 
    {
        public LabelEntryDropdownVertical CurrentWidget
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

        protected override void OnAttachedTo(LabelEntryDropdownVertical bindable)
        {
            CurrentWidget = bindable;
            CurrentWidget.EntryValue.TextChanged += bindable_TextChanged;
            CurrentWidget.Validate += on_Validate;
        }

        private void on_Validate(object sender, EventArgs e)
        {
            check_Validation(CurrentWidget.EntryValue.Text);
        }

        private void bindable_TextChanged(object sender, TextChangedEventArgs e)
        {
            check_Validation(e.NewTextValue);
        }

        private void check_Validation(string text)
        {
            IsValid = !string.IsNullOrEmpty(text);
            CurrentWidget.IsValid = IsValid.Value;
            //KB: TFS: 1118
            //CurrentWidget.ImageValidate.Source = (IsValid.Value ? "success.png" : "error.png");
            CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* This field is required");
        }

        protected override void OnDetachingFrom(LabelEntryDropdownVertical bindable)
        {
            CurrentWidget.EntryValue.TextChanged -= bindable_TextChanged;
            CurrentWidget.Validate -= on_Validate;

        }
    }
}
