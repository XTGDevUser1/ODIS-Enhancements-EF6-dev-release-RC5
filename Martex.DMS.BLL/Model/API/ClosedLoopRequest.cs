using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Martex.DMS.BLL.Model.API
{
    public class ClosedLoopRequest
    {
        public string CallStatus { get; set; }
        public string ServiceStatus { get; set; }
        public string ContactLogID { get; set; }
    }
}
