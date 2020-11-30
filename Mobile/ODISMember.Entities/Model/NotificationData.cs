using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ODISMember.Entities.Model
{
    public class NotificationData
    {
        public string PONumber { get; set; }
        public string ScriptNum { get; set; }
        public string TollFreeNumber { get; set; }
        public string Category { get; set; }
        public string ServiceRequestID { get; set; }
        public string ContactLogID { get; set; }
    }
}
