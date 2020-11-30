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
        /// Gets the vendor invoice list.
        /// </summary>
        /// <returns></returns>
        public List<VendorInvoicesList_Result> GetVendorInvoiceList(PageCriteria pc)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                List<VendorInvoicesList_Result> list = dbContext.GetVendorInvoicesList(pc.WhereClause, pc.StartInd, pc.EndInd, pc.PageSize, pc.SortColumn, pc.SortDirection).ToList<VendorInvoicesList_Result>();
                return list;
            }

        }

        /// <summary>
        /// Deletes the vendor invoice.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        public void DeleteVendorInvoice(int vendorInvoiceID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                VendorInvoice vi = dbContext.VendorInvoices.Where(a => a.ID == vendorInvoiceID).FirstOrDefault();
                vi.IsActive = false;
                dbContext.Entry(vi).State = EntityState.Modified;
                dbContext.SaveChanges();
            }
        }
    }
}
