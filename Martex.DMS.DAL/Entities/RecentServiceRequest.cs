using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.DAL.Entities
{
    public class RecentServiceRequest
    {
        public int ServiceRequestID { get; set; }
        public string Status { get; set; }
        public DateTime? Date { get; set; }
        public string Service { get; set; }
        public string Year { get; set; }
        public string Make { get; set; }
        public string Model { get; set; }
        public string Vehicle { get { return this.Year + " " + this.Make + " " + this.Model;  } }
        public string MemberName { get; set; }
        public int? MemberID { get; set; }

        // New fields added for member mobile
        public string SourceSystemName { get; set; }
        public string ContactPhoneNumber { get; set; }
        public string ContactFirstName { get; set; }
        public string ContactLastName { get; set; }
        public DateTime? CreateDate { get; set; }

        public string MembershipNumber { get; set; }
    }
}
