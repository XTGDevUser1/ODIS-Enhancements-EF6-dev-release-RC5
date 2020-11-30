using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    /// <summary>
    /// Vendor Invoice Repository
    /// </summary>
    public partial class VendorInvoiceRepository
    {
        /// <summary>
        /// Gets the vendor portal invoice list.
        /// </summary>
        /// <param name="pc">The pc.</param>
        /// <param name="VendorID">The vendor ID.</param>
        /// <returns></returns>
        public List<VendorPortalInvoiceList_Result> GetVendorPortalInvoiceList(PageCriteria pc, int VendorID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetVendorPortalInvoiceList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection, VendorID).ToList<VendorPortalInvoiceList_Result>();
            }
        }
    }
}
