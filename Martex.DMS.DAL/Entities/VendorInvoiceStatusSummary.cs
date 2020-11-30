using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class VendorInvoiceStatusSummary
    {
        public int ReadyForPayment { get; set; }
        public decimal ReadyForPaymentAmount { get; set; }
        
        public int ReadyForPaymentInFuture { get; set; }
        public decimal ReadyForPaymentInFutureAmount { get; set; }

        public int Received { get; set; }
        public decimal ReceivedAmount { get; set; }

        public int Cancelled { get; set; }
        public decimal CancelledAmount { get; set; }
        
        public int Paid { get; set; }
        public decimal PaidAmount { get; set; }
        
        public int Exceptions { get; set; }
        public decimal ExceptionsAmount { get; set; }

        public List<int> invoicesWithExceptions = new List<int>();
        public List<int> InvoicesWithExceptions
        {
            get
            {
                return invoicesWithExceptions;
            }
        }

        public List<int> invoicesReadyForPayment = new List<int>();
        public List<int> InvoicesReadyForPayment
        {
            get
            {
                return invoicesReadyForPayment;
            }
        }

    }
}
