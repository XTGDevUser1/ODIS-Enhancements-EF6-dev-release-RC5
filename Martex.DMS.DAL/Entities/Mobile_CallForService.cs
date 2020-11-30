using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL
{
    public partial class Mobile_CallForService
    {
        public decimal LocationLatitudeDecimal
        {
            get
            {
                decimal val = 0;
                decimal.TryParse(locationLatitude, out val);
                return val;
            }
        }
        public decimal LocationLongitudeDecimal
        {
            get
            {
                decimal val = 0;
                decimal.TryParse(locationLongtitude, out val);
                return val;
            }
        }

    }
}
