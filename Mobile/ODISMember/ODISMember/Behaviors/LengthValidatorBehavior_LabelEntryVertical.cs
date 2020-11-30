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
	public class LengthValidatorBehavior_LabelEntryVertical : Behavior<LabelEntryVertical> 
    {
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
        [DefaultValue(0)]
        public int Length
        {
            get;
            set;
        }
		protected override void OnAttachedTo(LabelEntryVertical bindable)
        {
			CurrentWidget = bindable;
			CurrentWidget.EntryValue.TextChanged += bindable_TextChanged;
			CurrentWidget.Validate += on_Validate;
        }
		private void on_Validate(object sender, EventArgs e){
			check_Validation (CurrentWidget.EntryValue.Text);
		}
        private void bindable_TextChanged(object sender, TextChangedEventArgs e)
        {
			check_Validation (e.NewTextValue);
        }
		private void check_Validation(string text){

            if (IsRequired)
            {
                if (string.IsNullOrEmpty(text))
                {
                    IsValid = false;
                    CurrentWidget.IsValid = false;
                    CurrentWidget.EntryErrorMessage = "* This field is required";
                    return;
                }
                else {
                    bool temp1 = (text.Length == Length);
                    IsValid = temp1;
                    CurrentWidget.IsValid = temp1;
                    CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Value should be " + Length + " characters in length ");
                    return;
                }
            }
            else {
                if (!string.IsNullOrEmpty(text))
                {
                    bool temp1 = (text.Length == Length);
                    IsValid = temp1;
                    CurrentWidget.IsValid = temp1;
                    CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Value should be " + Length + " characters in length ");
                    return;
                }
                else {
                    IsValid = true;
                    CurrentWidget.IsValid = true;
                    CurrentWidget.EntryErrorMessage = "";
                    return;
                }
            }


			//if (IsRequired && string.IsNullOrEmpty (text)) {
			//	IsValid = false;
			//	CurrentWidget.IsValid = false;
   //             CurrentWidget.EntryErrorMessage = "* This field is required";
   //             return;
			//}
   //         if (!IsRequired && string.IsNullOrEmpty(text)) {
   //             IsValid = true;
   //             CurrentWidget.IsValid = true;
   //             CurrentWidget.EntryErrorMessage = "";
   //             return;
   //         }
   //          if (IsRequired && !string.IsNullOrEmpty(text) && Length != 0)
   //         {
   //             bool temp1 = (text.Length == Length);
   //             IsValid = temp1;
   //             CurrentWidget.IsValid = temp1;
   //             CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Value should be " + Length + " characters in length ");
   //             return;
   //         }
            
		}
		protected override void OnDetachingFrom(LabelEntryVertical bindable)
        {
			CurrentWidget.EntryValue.TextChanged -= bindable_TextChanged;
			CurrentWidget.Validate -= on_Validate;

        }
    }
}
