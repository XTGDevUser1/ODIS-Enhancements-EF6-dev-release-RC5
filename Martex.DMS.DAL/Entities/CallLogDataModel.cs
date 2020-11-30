
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class CallLogDataModel
    {
        public string PhoneType { get; set; }
        public string PhoneNumber { get; set; }
        public string BusinessName { get; set; }
        public int? VendorLocationID { get; set; }
    }
}
