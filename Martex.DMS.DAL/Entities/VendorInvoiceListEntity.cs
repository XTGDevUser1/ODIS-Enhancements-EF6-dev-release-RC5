using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class VendorInvoiceListEntity
    {
        public int VendorInvoiceID { get; set; }
        public bool VendorInvoiceStatus { get; set; }
        public string VendorInvoiceNumber { get; set; }
    }
}
