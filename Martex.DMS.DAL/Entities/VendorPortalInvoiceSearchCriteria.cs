using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class VendorPortalInvoiceSearchCriteria
    {
        public string PONumber { get; set; }
        public DateTime? DateSectionFromDate { get; set; }
        public DateTime? DateSectionToDate { get; set; }
        public int? DateSectionPreset { get; set; }
        public string DateSectionPresetValue { get; set; }

    }
}
