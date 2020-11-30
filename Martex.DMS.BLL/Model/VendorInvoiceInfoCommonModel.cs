using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// Vendor Invoice Info Common Model
    /// </summary>
    public class VendorInvoiceInfoCommonModel
    {
        public VendorInvoiceDetails_Result VendorInvoiceDetails { get; set; }
        public VendorInvoicePODetails_Result VendorInvoicePODetails { get; set; }
        public VendorInvoiceVendorLocationDetails_Result VendorInvoiceVendorLocationDetails { get; set; }
        public VendorInvoiceVendorLocationBillingDetails_Result VendorInvoiceVendorLocationBillingDetails { get; set; }
        public VendorInvoiceCurrentBillingInformation_Result VendorInvoiceCurrentBillingInformation { get; set; }
        public List<Document> CopyOfVendorInvoice { get; set; }
        public bool AllowLapsedPOs { get; set; }
        public bool AllowLowerPOAmount { get; set; }
    }
}
