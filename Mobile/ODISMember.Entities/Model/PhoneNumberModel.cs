using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class PhoneNumberModel
    {
        public string AreaCode { get; set; }
        public string Extension { get; set; }
        public string Number { get; set; }
        public ODISMember.Entities.Constants.enumPhoneType PhoneNumberType { get; set; }
        public long SystemIdentifier { get; set; }
        public string CountryCode { get; set; }


        //Additional properties
        public string PhoneString
        {
            get
            {
                if (!string.IsNullOrEmpty(this.AreaCode) && !string.IsNullOrEmpty(this.Number))
                {
                    return String.Format("{0:(###) ###-####}", double.Parse(this.AreaCode.Trim() + this.Number.Trim()));
                }
                else
                {
                    return string.Empty;
                }
            }
        }
        public string FormatedPhoneNumber
        {
            get
            {
                if (!string.IsNullOrEmpty(this.AreaCode) && !string.IsNullOrEmpty(this.Number))
                {
                    return this.AreaCode.Trim() + this.Number.Trim();
                }
                else
                {
                    return string.Empty;
                }
            }
        }
    }

}
