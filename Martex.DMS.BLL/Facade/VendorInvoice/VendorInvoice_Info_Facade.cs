using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.Entities;
using Martex.DMS.DAL.Common;
using Martex.DMS.DAL;
using Martex.DMS.BLL.Model;
using Martex.DMS.DAL.DMSBaseException;
using Martex.DMS.DAL.DAO;

namespace Martex.DMS.BLL.Facade
{
    public partial class VendorInvoiceFacade
    {
        /// <summary>
        /// Gets the purchase order number.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public string GetPurchaseOrderNumber(int vendorInvoiceID)
        {
            return repository.GetPurchaseOrderNumber(vendorInvoiceID);
        }

        /// <summary>
        /// Gets the name of the vendor.
        /// </summary>
        /// <param name="vendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public string GetVendorName(int vendorInvoiceID)
        {
            return repository.GetVendorName(vendorInvoiceID);
        }

        /// <summary>
        /// Gets the vendor invoice details.
        /// </summary>
        /// <param name="VendorInvoiceID">The vendor invoice ID.</param>
        /// <returns></returns>
        public VendorInvoiceInfoCommonModel GetVendorInvoiceDetails(int VendorInvoiceID)
        {
            VendorInvoiceInfoCommonModel invoiceDetails = new VendorInvoiceInfoCommonModel();
            DocumentRepository docRepository = new DocumentRepository();
            invoiceDetails.VendorInvoiceDetails = repository.GetVendorInvoiceDetails(VendorInvoiceID);
            string purchaseOrderNumber = invoiceDetails.VendorInvoiceDetails.PurchaseOrderNumber;

            invoiceDetails.VendorInvoicePODetails = repository.GetVendorInvoicePODetails(purchaseOrderNumber);
            if (invoiceDetails.VendorInvoicePODetails != null)
            {
                int vendorLocationID = invoiceDetails.VendorInvoicePODetails.VendorLocationID.GetValueOrDefault();
                int purchaseOrderID = invoiceDetails.VendorInvoicePODetails.ID;
                invoiceDetails.VendorInvoiceVendorLocationDetails = repository.GetVendorInvoiceVendorLocationDetails(vendorLocationID);
                invoiceDetails.VendorInvoiceVendorLocationBillingDetails = repository.GetVendorInvoiceVendorLocationBillingDetails(vendorLocationID, purchaseOrderID);
                invoiceDetails.VendorInvoiceCurrentBillingInformation = repository.GetVendorInvoiceCurrentBillingInformation(purchaseOrderID);
                invoiceDetails.CopyOfVendorInvoice = docRepository.GetDocumentsForEntity(EntityNames.VENDOR_INVOICE, VendorInvoiceID).ToList();
            }
            else
            {
                throw new DMSException("No Vendor Invoice PO Details present in System for selected Invoice");
            }
            return invoiceDetails;
        }
        public VendorInvoiceInfoCommonModel GetVendorInvoiceProcessingDetails(int VendorInvoiceID)
        {
            VendorInvoiceInfoCommonModel invoiceDetails = new VendorInvoiceInfoCommonModel();

            invoiceDetails.VendorInvoiceDetails = repository.GetVendorInvoiceDetails(VendorInvoiceID);
            return invoiceDetails;
        }
        /// <summary>
        /// Gets the position details.
        /// </summary>
        /// <param name="purchaseOrderNumber">The purchase order number.</param>
        /// <returns></returns>
        public VendorInvoicePODetails_Result GetPODetails(string purchaseOrderNumber)
        {
            var result = repository.GetVendorInvoicePODetails(purchaseOrderNumber);

            return result;
        }


        /// <summary>
        /// Gets the vendor location details.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location unique identifier.</param>
        /// <returns></returns>
        public VendorInvoiceVendorLocationDetails_Result GetVendorLocationDetails(int vendorLocationID)
        {
            return repository.GetVendorInvoiceVendorLocationDetails(vendorLocationID);            
        }

        /// <summary>
        /// Gets the vendor location billing details.
        /// </summary>
        /// <param name="vendorLocationID">The vendor location unique identifier.</param>
        /// <param name="purchaseOrderID">The purchase order unique identifier.</param>
        /// <returns></returns>
        public VendorInvoiceVendorLocationBillingDetails_Result GetVendorLocationBillingDetails(int vendorLocationID, int purchaseOrderID)
        {
            return repository.GetVendorInvoiceVendorLocationBillingDetails(vendorLocationID, purchaseOrderID);
        }

        public VendorInvoiceCurrentBillingInformation_Result GetVendorInvoiceCurrentBillingInformation(int POID)
        {
            return repository.GetVendorInvoiceCurrentBillingInformation(POID);
        }
    }
}
