using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.DAO;
using Martex.DMS.DAL.DMSBaseException;
using System.Transactions;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorInvoiceFacade
    {
        /// <summary>
        /// Gets the vendor invoice batch list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <returns></returns>
        public List<VendorInvoiceBatchList_Result> GetVendorInvoiceBatchList(PageCriteria pc)
        {
            return repository.GetVendorInvoiceBatchList(pc);
        }

        /// <summary>
        /// Gets the batch payment runs list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="BatchID">The batch ID.</param>
        /// <returns></returns>
        public List<BatchPaymentRunsList_Result> GetBatchPaymentRunsList(PageCriteria pc, int BatchID)
        {
            return repository.GetBatchPaymentRunsList(pc, BatchID);
        }
    }
}
