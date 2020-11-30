using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace ClientPortal.Areas.Application.Models
{
    public class POSearchCriteria
    {
        public string PONumber { get; set; }
        public string UserName { get; set; }
        public string VendorNumber { get; set; }
        public string Time { get; set; }        
    }
}