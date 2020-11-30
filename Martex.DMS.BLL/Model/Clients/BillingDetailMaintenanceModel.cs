using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Martex.DMS.DAL;

namespace Martex.DMS.BLL.Model.Clients
{
    public class BillingDetailMaintenanceModel
    {
        public ClientBillableEventProcessingDetails_Result BillingInvoiceDetails { get; set; }
        public List<ClientBillableEventProcessingExceptions_Result> Exceptions { get; set; }
        public string DisplayMode { get; set; }
        public string ParentTabName { get; set; }
        public string ParentGridName { get; set; }
    }
}
