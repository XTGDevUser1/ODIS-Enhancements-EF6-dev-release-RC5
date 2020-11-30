using com.google.i18n.phonenumbers;
using ODISMember.Shared;
using ODISMember.Widgets;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using static com.google.i18n.phonenumbers.Phonenumber;

namespace ODISMember.Common
{

    /// <summary>
    /// To validate the phone number
    /// </summary>
    public static class PhoneNumberValidator
    {
        #region Fields
        //get static instance for phone number util
        private static PhoneNumberUtil phoneNumberUtil = PhoneNumberUtil.getInstance();
        #endregion

        #region Validate Methods        
        /// <summary>
        /// Validates the phone number.
        /// </summary>
        /// <param name="widget">The widget.</param>
        public static bool ValidatePhoneNumber(LabelDropdownEntryHorizontal widget)
        {
            //building phone number object
            var phoneNumber = new PhoneNumber();
            int telephoneCode = 0;
            var isCountryCodeParsed = int.TryParse(widget.Value.Trim(), out telephoneCode);
            //If combo box bind with country code instead of telephone code, isCountryCodeParsed will return false.
            //if isCountryCodeParsed is false we will fetch telephone code form local database by sending the country code two digits value
            if (!isCountryCodeParsed)
            {
                MemberHelper memberHelper = new MemberHelper();
                var code = memberHelper.GetTelephoneCodeByCountryCode(widget.Value.Trim());
                if (code.HasValue)
                {
                    telephoneCode = code.Value;
                }
            }

            phoneNumber.setCountryCode(Convert.ToInt32(telephoneCode));
            string input = Regex.Replace(widget.EntryValue.Text, "[^0-9]+", string.Empty);
            phoneNumber.setNationalNumber(Convert.ToInt64(input));
            //validating phone number
            if (!phoneNumberUtil.isValidNumber(phoneNumber))
            {
                widget.IsValid = false;
                //showing invalid phone number message on the screen
                widget.EntryErrorMessage = (widget.IsValid ? "" : "Invalid phone number");
            }
            return widget.IsValid;
        }
        #endregion
    }
}
