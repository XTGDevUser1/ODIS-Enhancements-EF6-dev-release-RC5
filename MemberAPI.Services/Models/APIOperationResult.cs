using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MemberAPI.Services.Models
{
    public class APIOperationResult
    {
        public string OperationType { get; set; }
        public string Status { get; set; }

        public string TabNavigation { get; set; }
      
        public string ErrorMessage { get; set; }
        public string ErrorDetail { get; set; }
        // Custom data to be returned in the case of success
        public object Data { get; set; }
    }
}
