using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class EstimateApprovalModel
    {
        public int? ContactActionID { get; set; }
        public string TalkedToForApproval { get; set; }
        public string PhoneNumberCalled { get; set; }
        public string PhoneType { get; set; }
        public string Comments { get; set; }
        public bool IsApproved { get; set; }
        public int? PhoneTypeID { get; set; }
    }
}
