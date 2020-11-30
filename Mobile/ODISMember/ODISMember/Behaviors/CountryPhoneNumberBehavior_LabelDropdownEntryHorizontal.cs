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
    public class CountryPhoneNumberBehavior_LabelDropdownEntryHorizontal : Behavior<LabelDropdownEntryHorizontal>
    {
        public LabelDropdownEntryHorizontal CurrentWidget
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
        [DefaultValue(0)]
        public int Length
        {
            get;
            set;
        }
        protected override void OnAttachedTo(LabelDropdownEntryHorizontal bindable)
        {
            CurrentWidget = bindable;
            CurrentWidget.EntryValue.TextChanged += EntryValue_TextChanged;
            CurrentWidget.EntryValueDropdown.TextChanged += EntryValueDropdown_TextChanged;
            CurrentWidget.Validate += on_Validate;
        }

        private void EntryValue_TextChanged(object sender, TextChangedEventArgs e)
        {
            check_Validation();
        }

        private void EntryValueDropdown_TextChanged(object sender, TextChangedEventArgs e)
        {
            check_Validation();
        }

        private void on_Validate(object sender, EventArgs e)
        {   
            check_Validation();            
        }

        private void check_Validation()
        {
            string dropdownValue = CurrentWidget.EntryValueDropdown.Text;
            string entryText = string.Empty;
            if (!string.IsNullOrEmpty(CurrentWidget.EntryValue.Text))
            {
                entryText = Regex.Replace(CurrentWidget.EntryValue.Text, "[^0-9]+", string.Empty);
            }
            if (IsRequired)
            {
                //Checking required validation
                if (string.IsNullOrEmpty(dropdownValue) && string.IsNullOrEmpty(entryText))
                {
                    IsValid = false;
                    CurrentWidget.IsValid = false;
                    CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Country field is required \n * Phone number field is required");
                }
                else if (string.IsNullOrEmpty(dropdownValue))
                {
                    IsValid = false;
                    CurrentWidget.IsValid = false;
                    CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Country field is required");
                }
                else if (string.IsNullOrEmpty(entryText))
                {
                    IsValid = false;
                    CurrentWidget.IsValid = false;
                    CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Phone number field is required");
                }
                else
                {
                    IsValid = true;
                    CurrentWidget.IsValid = true;
                    CurrentWidget.EntryErrorMessage = string.Empty;

                    if (!string.IsNullOrEmpty(entryText))
                    {
                        double result;
                        bool temp = double.TryParse(entryText, out result);
                        if (!temp)
                        {
                            IsValid = temp;
                            CurrentWidget.IsValid = temp;
                            CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Please enter valid phone number");
                            return;
                        }
                        if (Length != 0)
                        {
                            bool temp1 = (entryText.Length == Length);
                            IsValid = temp1;
                            CurrentWidget.IsValid = temp1;
                            CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Phone number should be " + Length + " digits");
                        }
                    }
                }
            }
            else
            {
                IsValid = true;
                CurrentWidget.IsValid = true;
                CurrentWidget.EntryErrorMessage = string.Empty;
                if (!string.IsNullOrEmpty(entryText))
                {
                    double result;
                    bool temp = double.TryParse(entryText, out result);
                    if (!temp)
                    {
                        IsValid = temp;
                        CurrentWidget.IsValid = temp;
                        CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Please enter valid phone number");
                        return;
                    }
                    if (Length != 0)
                    {
                        bool temp1 = (entryText.Length == Length);
                        IsValid = temp1;
                        CurrentWidget.IsValid = temp1;
                        CurrentWidget.EntryErrorMessage = (IsValid.Value ? "" : "* Phone number should be " + Length + " digits");
                    }
                }
            }
        }

        protected override void OnDetachingFrom(LabelDropdownEntryHorizontal bindable)
        {
            CurrentWidget.EntryValue.TextChanged -= EntryValue_TextChanged;
            CurrentWidget.Validate -= on_Validate;
        }

    }
}
