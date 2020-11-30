using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorInvoiceFacade
    {
        /// <summary>
        /// Gets the vendor invoice list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<VendorInvoicesList_Result> GetVendorInvoiceList(PageCriteria pc)
        {
            return repository.GetVendorInvoiceList(pc);
        }

        /// <summary>
        /// Deletes the vendor invoice.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        public void DeleteVendorInvoice(int vendorInvoiceID)
        {
            repository.DeleteVendorInvoice(vendorInvoiceID);
        }
    }
}
