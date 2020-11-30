using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model
{
    /// <summary>
    /// RejectVendorModel
    /// </summary>
    public class RejectVendorModel
    {
        public int VendorID { get; set; }
        public int VendorLocationID { get; set; }
        public string VendorName { get; set; }
        public string Source { get; set; }
        
        public string TalkedTo { get; set; }
        public bool? PossibleRetry { get; set; }
        public string RejectComments { get; set; }
        public int ContactAction { get; set; }

        public string PhoneNumber { get; set; }
        public string PhoneType { get; set; }

    }
}
