using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model
{
    public class MemberShipDetails
    {
        public int MembershipID { get; set; }
        public string MemberShipNumber { get; set; }
        public string Name { get; set; }
        public bool IsActive { get; set; }
    }
}
