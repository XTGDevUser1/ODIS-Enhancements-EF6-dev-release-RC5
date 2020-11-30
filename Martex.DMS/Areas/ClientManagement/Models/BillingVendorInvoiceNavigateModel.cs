using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace Martex.DMS.Areas.ClientManagement.Models
{
    public class BillingVendorInvoiceNavigateModel
    {
        public int? BillingDefinitionInvoiceID { get; set; }
        public int? BillingDefinitionInvoiceLineID { get; set; }
        public int? BillingInvoiceLineID { get; set; }
        public string InvoiceDescription { get; set; }
        public string InvoiceLineDescription { get; set; }
    }
}