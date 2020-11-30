using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorInvoiceRepository
    {
        /// <summary>
        /// Gets the vendor invoice batch list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<VendorInvoiceBatchList_Result> GetVendorInvoiceBatchList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorInvoiceBatchList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<VendorInvoiceBatchList_Result>();
            }
        }

        /// <summary>
        /// Gets the batch payment runs list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="BatchID">The batch ID.</param>
        /// <returns></returns>
        public List<BatchPaymentRunsList_Result> GetBatchPaymentRunsList(PageCriteria pc, int BatchID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetBatchPaymentRunsList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, BatchID).ToList<BatchPaymentRunsList_Result>();
            }
        }

        /// <summary>
        /// Gets the vendor invoice status.
        /// </summary>
        /// <param name="name">The name.</param>
        /// <returns></returns>
        public VendorInvoiceStatu GetVendorInvoiceStatus(string name)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorInvoiceStatus.Where(a => a.Name == name).FirstOrDefault();
            }
        }

        public int GetVendorInvoiceCountForSR(int serviceRequestID)
        {
            int count = 0;
            using (DMSEntities dbContext = new DMSEntities())
            {
                var vendorInvoiceList = (from vi in dbContext.VendorInvoices
                                         join po in dbContext.PurchaseOrders on vi.PurchaseOrderID equals po.ID
                                         where po.ServiceRequestID == serviceRequestID
                                         select new
                                         {
                                             ID = vi.ID
                                         }).ToList();
                count = vendorInvoiceList.Count;
            }
            return count;
        }
    }
}
