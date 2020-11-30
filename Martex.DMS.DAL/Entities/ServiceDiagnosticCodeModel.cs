using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Martex.DMS.BLL.Model
{
    public class ServiceDiagnosticCodeModel
    {
        public string CategoryName { get; set; }
        public bool IsPrimary { get; set; }
        public string Code { get; set; }
        public string CodeName { get; set; }
        public bool IsSelectedForServiceRequest { get; set; }
        public int ID { get; set; }
    }
}
