using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorInvoiceFacade
    {
        /// <summary>
        /// Gets the PO.
        /// </summary>
        /// <param name="PONumber">The PO number.</param>
        /// <returns></returns>
        public PurchaseOrder GetPO(string PONumber)
        {
            PORepository poRepository = new PORepository();
            return poRepository.GetPOByNumber(PONumber);
        }

        /// <summary>
        /// Gets the PO status.
        /// </summary>
        /// <param name="poID">The po ID.</param>
        /// <returns></returns>
        public PurchaseOrderStatu GetPOStatus(int poStatusID)
        {
            return repository.getPOStatus(poStatusID);
        }

        /// <summary>
        /// Gets the vendor invoice listfor PO.
        /// </summary>
        /// <param name="poID">The po ID.</param>
        /// <returns></returns>
        public List<VendorInvoice> GetVendorInvoiceListforPO(int poID)
        {
            return repository.GetVendorInvoiceListforPO(poID);
        }
    }
}
