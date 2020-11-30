using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model.Claims
{
    public class ClaimInput
    {
        public int ClaimTypeID { get; set; }
        public string ClaimTypeText { get; set; }
        public int? PurchaseOrderID { get; set; }
        public string PurchaseOrderNumber { get; set; }
        public string MembershipNumber { get; set; }
        public int? MembershipID { get; set; }
        public int MemberID { get; set; }
        public int ProgramID { get; set; }
        public int? VendorID { get; set; }
        public string PayeeType { get; set; }
        public int? VehicleID { get; set; }
    }
}
