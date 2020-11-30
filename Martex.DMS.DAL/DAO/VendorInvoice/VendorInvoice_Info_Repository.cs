using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorInvoiceRepository
    {
        /// <summary>
        /// Gets the purchase order number.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public string GetPurchaseOrderNumber(int vendorInvoiceID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorInvoice vi = dbContext.VendorInvoices.Where(a => a.ID == vendorInvoiceID).FirstOrDefault();
                if (vi != null)
                {
                    PurchaseOrder po = dbContext.PurchaseOrders.Where(a => a.ID == vi.PurchaseOrderID).FirstOrDefault();
                    return po.PurchaseOrderNumber;
                }
                return string.Empty;
            }
        }

        /// <summary>
        /// Gets the name of the vendor.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public string GetVendorName(int vendorInvoiceID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                VendorInvoice vi = dbContext.VendorInvoices.Where(a => a.ID == vendorInvoiceID).FirstOrDefault();
                if (vi != null)
                {
                    Vendor vendor = dbContext.Vendors.Where(a => a.ID == vi.VendorID).FirstOrDefault();
                    return vendor.Name;
                }
                return string.Empty;
            }
        }

        /// <summary>
        /// Gets the vendor invoice details.
        /// </summary>
        /// <param name="VendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public VendorInvoiceDetails_Result GetVendorInvoiceDetails(int VendorInvoiceID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorInvoiceDetails(VendorInvoiceID).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the vendor invoice PO details.
        /// </summary>
        /// <param name="purchaseOrderNumber">The purchase order number.</param>
        /// <returns></returns>
        public VendorInvoicePODetails_Result GetVendorInvoicePODetails(string purchaseOrderNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorInvoicePODetails(purchaseOrderNumber).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the vendor invoice vendor location details.
        /// </summary>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <returns></returns>
        public VendorInvoiceVendorLocationDetails_Result GetVendorInvoiceVendorLocationDetails(int VendorLocationID)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorInvoiceVendorLocationDetails(VendorLocationID).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the vendor invoice vendor location billing details.
        /// </summary>
        /// <param name="VendorLocationID">The vendor location ID.</param>
        /// <param name="purchaseOrderNumber">The purchase order number.</param>
        /// <returns></returns>
        public VendorInvoiceVendorLocationBillingDetails_Result GetVendorInvoiceVendorLocationBillingDetails(int VendorLocationID, int purchaseOrderNumber)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.GetVendorInvoiceVendorLocationBillingDetails(VendorLocationID, purchaseOrderNumber).FirstOrDefault();
            }
        }


        /// <summary>
        /// Gets the name of the vendor invoice status by.
        /// </summary>
        /// <param name="statusName">Name of the status.</param>
        /// <returns></returns>
        public VendorInvoiceStatu GetVendorInvoiceStatusByName(string statusName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.VendorInvoiceStatus.Where(a => a.Name == statusName).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the name of the source system by.
        /// </summary>
        /// <param name="systemName">Name of the system.</param>
        /// <returns></returns>
        public SourceSystem GetSourceSystemByName(string systemName)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                return dbContext.SourceSystems.Where(a => a.Name == systemName).FirstOrDefault();
            }
        }

        /// <summary>
        /// Gets the vendor invoice current billing information.
        /// </summary>
        /// <param name="POID">The POID.</param>
        /// <returns></returns>
        public VendorInvoiceCurrentBillingInformation_Result GetVendorInvoiceCurrentBillingInformation(int POID)
        {
            using (DMSEntities dbContext=new DMSEntities())
            {
                return dbContext.GetVendorInvoiceCurrentBillingInformation(POID).FirstOrDefault();
            }
        }
    }
}
