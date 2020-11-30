using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using System.Data.Entity;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorInvoiceRepository
    {
        /// <summary>
        /// Gets the PO.
        /// </summary>
        /// <param name="PONumber">The PO number.</param>
        /// <returns></returns>
        public PurchaseOrder getPO(string PONumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PurchaseOrders.Where(a => a.PurchaseOrderNumber == PONumber).Include(p=>p.PurchaseOrderStatu).Include(p=>p.VendorLocation).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the PO status.
        /// </summary>
        /// <param name="poStatusID">The po status ID.</param>
        /// <returns></returns>
        public PurchaseOrderStatu getPOStatus(int poStatusID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.PurchaseOrderStatus.Where(a => a.ID == poStatusID).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the vendor invoice list for PO.
        /// </summary>
        /// <param name="poID">The po ID.</param>
        /// <returns></returns>
        public List<VendorInvoice> GetVendorInvoiceListforPO(int poID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorInvoices.Where(a => a.PurchaseOrderID == poID && a.IsActive == true).ToList<VendorInvoice>();
            }
        }
    }
}
