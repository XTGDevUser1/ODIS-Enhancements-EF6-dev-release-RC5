using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL.DMSBaseException;
using log4net;

namespace Martex.DMS.DAL.DAO
{
    public partial class VendorInvoiceRepository
    {
        protected static ILog logger = LogManager.GetLogger(typeof(VendorInvoiceRepository));
        /// <summary>
        /// Adds the specified invoice.
        /// </summary>
        /// <param name="invoice">The invoice.</param>
        public void Add(VendorInvoice invoice, string status, string sourceSystem, string contactMethod)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var invoiceStatus = dbContext.VendorInvoiceStatus.Where(x => x.Name.Equals(status, StringComparison.InvariantCultureIgnoreCase)).FirstOrDefault();
                if (invoiceStatus == null)
                {
                    throw new DMSException(string.Format("Invoice status {0} is not set up in the system", status));
                }
                invoice.VendorInvoiceStatusID = invoiceStatus.ID;

                var source = dbContext.SourceSystems.Where(s => s.Name.Equals(sourceSystem, StringComparison.InvariantCultureIgnoreCase)).FirstOrDefault();
                if (source == null)
                {
                    throw new DMSException(string.Format("Source System {0} is not set up in the system", sourceSystem));
                }

                invoice.SourceSystemID = source.ID;

                var cm = dbContext.ContactMethods.Where(c => c.Name.Equals(contactMethod, StringComparison.InvariantCultureIgnoreCase)).FirstOrDefault();
                if (cm == null)
                {
                    throw new DMSException(string.Format("Contact Method {0} is not set up in the system", contactMethod));
                }

                invoice.ReceiveContactMethodID = cm.ID;

                dbContext.VendorInvoices.Add(invoice);
                dbContext.SaveChanges();
            }
        }

        /// <summary>
        /// Updates the specified invoice.
        /// </summary>
        /// <param name="invoice">The invoice.</param>
        /// <param name="status">The status.</param>
        /// <param name="sourceSystem">The source system.</param>
        /// <param name="contactMethod">The contact method.</param>
        /// <exception cref="DMSException">
        /// Invalid Invoice ID        
        /// </exception>
        public void UpdateInvoice(VendorInvoice invoice, string status, string sourceSystem, string contactMethod)
        {
            using (DMSEntities dbContext = new DMSEntities())
            {
                var existingInvoice = dbContext.VendorInvoices.Where(v => v.ID == invoice.ID).FirstOrDefault();
                if (existingInvoice == null)
                {
                    throw new DMSException("Invalid Invoice ID");
                }
                var invoiceStatus = dbContext.VendorInvoiceStatus.Where(x => x.Name.Equals(status, StringComparison.InvariantCultureIgnoreCase)).FirstOrDefault();
                if (invoiceStatus == null)
                {
                    throw new DMSException(string.Format("Invoice status {0} is not set up in the system", status));
                }
                existingInvoice.VendorInvoiceStatusID = invoiceStatus.ID;

                var source = dbContext.SourceSystems.Where(s => s.Name.Equals(sourceSystem, StringComparison.InvariantCultureIgnoreCase)).FirstOrDefault();
                if (source == null)
                {
                    throw new DMSException(string.Format("Source System {0} is not set up in the system", sourceSystem));
                }

                existingInvoice.SourceSystemID = source.ID;

                var cm = dbContext.ContactMethods.Where(c => c.Name.Equals(contactMethod, StringComparison.InvariantCultureIgnoreCase)).FirstOrDefault();
                if (cm == null)
                {
                    throw new DMSException(string.Format("Contact Method {0} is not set up in the system", contactMethod));
                }

                existingInvoice.ReceiveContactMethodID = cm.ID;
                existingInvoice.InvoiceNumber = invoice.InvoiceNumber;
                existingInvoice.ReceivedDate = invoice.ReceivedDate;
                existingInvoice.ToBePaidDate = invoice.ToBePaidDate;
                existingInvoice.InvoiceDate = invoice.InvoiceDate;
                existingInvoice.InvoiceAmount = invoice.InvoiceAmount;
                existingInvoice.ActualETAMinutes = invoice.ActualETAMinutes;
                existingInvoice.Last8OfVIN = invoice.Last8OfVIN;
                existingInvoice.VehicleMileage = invoice.VehicleMileage;
                existingInvoice.PaymentAmount = invoice.PaymentAmount;
                existingInvoice.ModifyBy = invoice.ModifyBy;
                existingInvoice.ModifyDate = invoice.ModifyDate;
                existingInvoice.VendorInvoicePaymentDifferenceReasonCodeID = invoice.VendorInvoicePaymentDifferenceReasonCodeID;


                dbContext.SaveChanges();
            }
        }
    }
}
