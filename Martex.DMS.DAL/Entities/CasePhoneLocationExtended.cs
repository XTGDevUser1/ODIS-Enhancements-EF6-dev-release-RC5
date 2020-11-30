using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL
{
    public partial class CasePhoneLocation
    {
        public override string ToString()
        {
            StringBuilder sb = new StringBuilder();
            sb.Append(this.CivicStreet);
            sb.Append(",");
            sb.Append(this.CivicCity);
            sb.Append(",");
            sb.Append(this.CivicState);
            sb.Append(",");
            sb.Append(this.CivicZip);
            return sb.ToString();
            
        }
    }
}
