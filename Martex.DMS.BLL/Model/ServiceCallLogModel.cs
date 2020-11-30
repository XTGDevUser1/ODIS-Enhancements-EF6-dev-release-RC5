using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    public class ServiceCallLogModel
    {
        public Vendor Vendor { get; set; }
        public VendorLocation VendorLocation { get; set; }
        public string PhoneNumber { get; set; }
        public string PhoneType { get; set; }
    }
}
