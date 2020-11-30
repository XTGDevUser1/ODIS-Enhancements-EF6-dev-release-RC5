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
using System.IO;

namespace Martex.DMS.BLL.Facade
{
    /// <summary>
    /// Vendor Invoice Facade
    /// </summary>
    public partial class VendorInvoiceFacade
    {
        /// <summary>
        /// Gets the vendor Portal invoice list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorPortalInvoiceList_Result> GetVendorPOrtalInvoiceList(PageCriteria pc, int VendorID)
        {
            var list = repository.GetVendorPortalInvoiceList(pc, VendorID);
            if (list.Count() > 0)
            {
                list.ForEach(x =>
                {
                    x.DocumentType = x.DocumentName != null ? Path.GetExtension(x.DocumentName).Replace(".", "") : "";
                });
            }
            return list;
        }
    }
}
