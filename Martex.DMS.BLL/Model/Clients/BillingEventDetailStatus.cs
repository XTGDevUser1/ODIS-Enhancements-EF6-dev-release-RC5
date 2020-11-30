using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.Clients
{
    public class BillingEventDetailStatus
    {
        public string selectedPendingEvents { get; set; }
        public int pendingCount { get; set; }

        public string selectedReadyEvents { get; set; }
        public int readyCount { get; set; }

        public string selectedPostedEvents { get; set; }
        public int postedCount { get; set; }

        public string selectedOnholdEvents { get; set; }
        public int onholdCount { get; set; }

        public string selectedExceptionEvents { get; set; }
        public int exceptionCount { get; set; }

        public string selectedDeletedEvents { get; set; }
        public int deletedCount { get; set; }

        public string selectedExcludedEvents { get; set; }
        public int excludedCount { get; set; }

        public int billingInvoiceLineID { get; set; }
    }

    public class BillingEventDetailDisposition
    {
        public string selectedRefreshEvents { get; set; }
        public int refreshCount { get; set; }

        public string selectedLockedEvents { get; set; }
        public int lockedCount { get; set; }

        public int billingInvoiceLineID { get; set; }
    }
}
