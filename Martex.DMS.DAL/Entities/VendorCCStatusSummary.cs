using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class VendorCCStatusSummary

    {
        public int Matched { get; set; }
        public decimal MatchedAmount { get; set; }

        public int Cancelled { get; set; }
        public decimal CancelledAmount { get; set; }

        public int Exception { get; set; }
        public decimal ExceptionAmount { get; set; }

        public int Posted { get; set; }
        public decimal PostedAmount { get; set; }
                

        protected List<int> vendorccWithExceptions = new List<int>();
        public List<int> VendorccWithExceptions
        {
            get
            {
                return vendorccWithExceptions;
            }
        }

        public List<int> vendorccPosted = new List<int>();
        public List<int> VendorccPosted
        {
            get
            {
                return vendorccPosted;
            }
        }

    }
   
}
